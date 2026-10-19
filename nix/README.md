---
agent:
  instruction: Update this README when Nix catalog or host workflows change.
  on-change: ["nix/lib/**", "nix/modules/**", "nix/scripts/native-packages.py", "nix/justfile"]
---

# nix config

Cross-platform Home Manager flake.

## Layout

```
nix/
  flake.nix                # sharedModules + per-host wiring + cudaCapabilities map
  bootstrap.sh             # 1-click install: prereqs → clone → HM switch → post-setup
  post-setup.sh            # root-owned config and WSL/APT fallback
  justfile                 # switch/build/clean; switch --dry-run covers Home Manager and native packages
  scripts/native-packages.py # Native package reconciliation and ownership receipt
  lib/
    catalog.nix            # typed catalog selection, applicability, and realization
    host-context.nix       # shared host vocabulary for modules and catalogs
    checks.nix             # host evaluations + catalog behavior checks
  hosts/
    desktop.nix            # arch + KDE + CUDA workstation
    work-macbook.nix       # aarch64-darwin + metal
  modules/
    system.nix             # my.* identity options surface
    apps/
      default.nix          # catalog engine invocation + Flatpak adapter
      catalog.nix          # bundles, requirements, and contributions
    ai/
      default.nix          # catalog engine invocation
      catalog.nix          # AI packages and module-backed applications
      {claude,llama,shared}.nix
    <tool>.nix             # config for larger tools (git, mise, ssh, …)
    common.nix             # universal HM infrastructure
    secrets.nix            # agenix wiring, filtered by my.identities / my.secrets
  secrets/                 # age-encrypted, identity registry in meta.nix
```

## How to add a tool

1. **Trivial** (just a Flatpak ID, package, or Home Manager program): add an entry to `modules/apps/catalog.nix`. Tag it with the right bundle (`cli`, `desktop`, `dev`, `security`, `fonts`, `communication`, `cloud`) and place its Home Manager values under `contributions`.
2. **Substantial config** (extensions, services, identity wiring): write
   a dedicated module `modules/<tool>.nix`, add it to `sharedModules`, and let
   the catalog contribute the typed option that activates it.
3. **Joins a domain** (AI, future "k8s" or similar): add to that
   domain's catalog, or sibling file inside the domain directory.

The lifecycle rule is complexity-based, not source-mechanism-based.
Domain `default.nix` files select applicable entries and invoke the shared
realizer; they do not branch on application names.

Each domain keeps one `catalog.nix` with sibling `applications` and `support` sections. Put tools used directly in `applications`; put libraries, fonts, integration plugins, keyring services, dialog helpers, and protocol adapters in `support`. Both sections use the same entry shape and merge into one selection namespace, so bundles and explicit `enabled`/`disabled` lists work with either section. Entry names must be unique across both sections. This organization does not change package ownership or installation behavior.

Graphical desktop presence is `my.hasDesktop`, separate from `my.desktop` (the desktop environment). It defaults to whether a desktop environment is declared. A Mac can therefore use `desktop = "none"` and `hasDesktop = true`; a headless or WSL host can keep it false.

Every catalog entry has three shared sections:

- `bundles` selects the entry through host bundle policy.
- `requirements` constrains Nix system, operating system, desktop presence,
  desktop environment, or GPU backend using values from `lib/host-context.nix`.
- `contributions` adds packages, programs, user services, files, session
  variables, aliases, or activation entries through Home Manager.

Native package contributions use the shared catalog contract:

```nix
vscode = {
  bundles = [ "dev" ];
  contributions.nativePackages = {
    arch.aur = [ "visual-studio-code-bin" ];
    darwin.homebrew.casks = [ "visual-studio-code" ];
    fedora.dnf = {
      packages = [ "code" ];
      repositories.vscode = {
        baseurl = "https://packages.microsoft.com/yumrepos/vscode";
        gpgkey = "https://packages.microsoft.com/keys/microsoft.asc";
      };
    };
  };
};
```

Use exact package names, not groups, virtual providers, repository prefixes,
or version selectors. Supported mapping fields are `arch.pacman`, `arch.aur`,
`darwin.homebrew.formulae`, `darwin.homebrew.casks`, and `fedora.dnf`.
Application `requirements` describe real application constraints; package
names and package-source requirements belong in the platform mapping.

Both app and AI domains aggregate selected native declarations. A package stays desired until its last declaration disappears. Missing or empty host mappings fail evaluation with the domain/application name. Conflicting repository definitions also fail rather than choosing one silently.

Hosts can subtract bundle members through `my.apps.disabled` and
`my.ai.disabled`. The WSL host disables VS Code because it runs on Windows.
WSL defaults to no native platform; set `my.nativePackages.platform` to the
actual supported Linux distro before selecting native packages inside WSL.
This separates WSL session behavior from the distro package manager.
LazyGit stays on Nix on all hosts.

The desktop host explicitly selects native Android tools, `android-udev` support, Wayland clipboard tools, and Google Chrome. Android tools map to pacman/DNF `android-tools` or the Homebrew `android-platform-tools` cask; udev support is separate because macOS does not use udev. Chrome uses AUR on Arch, Homebrew on macOS, and Google’s signed RPM repository on Fedora. Existing Chrome and Android installations remain unowned unless adopted. Firefox is also explicitly selected on desktop, using pacman/DNF `firefox` or the Homebrew `firefox` cask. Vivaldi remains in the `communication` bundle and uses pacman `vivaldi`, the Homebrew `vivaldi` cask, or `vivaldi-stable` from Vivaldi’s signed Fedora repository. Its former Flatpak declaration is removed; the next Home Manager activation removes that unmanaged Flatpak installation under the existing Flatpak cleanup policy.

Claude Desktop uses AUR `claude-desktop-extra` on Arch, built and installed through the configured `paru` or `yay` helper. Its recipe repackages the project's release archive. It conflicts with the former `claude-desktop` package; the native transaction must replace that package. Cowork dependencies such as QEMU, virtiofsd, and OVMF are optional in the Extra package and must remain installed separately when Cowork is needed. ChatGPT desktop uses AUR `codex-desktop-git`, which builds ilysenko/codex-desktop-linux and repackages the official upstream Linux app as ChatGPT Community. The native provider delegates its build and installation to `paru` or `yay`. The next native apply removes the former `chatgpt-desktop-bin` package if the ownership receipt lists it; only an unowned, pre-existing installation needs separate removal. Do not run the official and community apps concurrently, because both share the upstream Codex user profile. Update the Git package through the AUR helper, including its development-package update option when needed. macOS uses Homebrew casks `claude` and `chatgpt`. Desktop presence requirements still apply: the Mac explicitly sets `my.hasDesktop = true` and selects both casks, while WSL omits these desktop apps. Fedora mappings for the AI desktop apps and Android udev support are not declared; selecting them there fails explicitly until a source is chosen.

The `desktop` bundle selects native desktop utilities: Shelly on graphical Arch hosts, Dolphin plugins and Google Drive integration on KDE Arch/Fedora hosts, the platform-specific partition manager on those KDE hosts, and Flatpak KCM on Arch KDE. The desktop host opts into this bundle. The `security` bundle contributes native libsecret and Zenity on Arch/Fedora, plus GNOME keyring (including Fedora's PAM package) only on non-KDE hosts. These use declared host requirements rather than the bootstrap shell's desktop environment variables.

Packages previously installed by post-setup remain pre-existing and unmanaged until explicitly adopted. Adding the declarations does not silently grant removal ownership. The Arch KDE graphics/system metapackages are declared in `support` through the `desktop` bundle as ordinary native packages. The WSL bootstrap fallback still installs them directly. PAM edits and WSL configuration stay in that script. Debian/Ubuntu package installation and the existing Arch/Fedora WSL fallbacks remain there too, because the WSL host has no native distro selected and the adapter has no APT backend.

Flatpak remains an apps-only adapter because no other catalog domain needs it.
If the host model cannot express an applicability rule, extend
`lib/host-context.nix` and the corresponding `my.*` option instead of adding a
hostname check or arbitrary predicate to a catalog entry.

## Native packages

Ghostty belongs to the `desktop` bundle, selected by the Arch desktop and Mac hosts. It requires a graphical desktop and uses the native `ghostty` Pacman package on Arch or Homebrew cask on macOS. WSL does not select the bundle. `modules/common.nix` keeps its configuration linked to `ghostty/` in the dotfiles checkout. Fedora has no Ghostty package mapping yet.

Home Manager writes `~/.config/native-packages/manifest.json` and installs the `native-packages` command. The manifest includes the explicit host key, OS, architecture, native platform, selected backend package lists and repositories. The reconciler is outside activation: `just switch <host>` first activates Home Manager, then applies its manifest. These are separate transactions.

On Arch, apply marks every declared installed package explicitly installed before removing old packages. This protects declared packages even when they originally arrived as dependencies, without adopting pre-existing packages. Owned packages whose last declaration disappears are removed with `pacman -Rs`, including dependencies that pacman finds unneeded. The dry-run resolves this transaction using a temporary copy of pacman’s local database with declared packages protected; it does not change real install reasons. Apply installs wanted packages first and resolves removals again immediately before execution. Pacman displays its final transaction and keeps its normal confirmation.

A native failure leaves Home Manager activated and stops the recipe before generation cleanup. Retry with `native-packages apply --host <host>`. The first bootstrap switch also reconciles after activation. Both paths require reconciliation to succeed; a missing manifest is an error, not a reason to skip it.

From `nix/`:

- `just switch desktop --dry-run` runs Home Manager's `nh home switch --dry`, then evaluates current declarations and previews native package additions/removals. It skips activation, package changes, receipt writes, documentation generation, and generation cleanup. Nix may populate its cache and build the Home Manager configuration and reconciler. The Home Manager portion uses `nh`'s own dry-run output; the native portion lists the package transactions.
- `just switch desktop` activates and reconciles normally, with confirmation.
- `native-packages apply --host desktop` retries the **activated** manifest.
- `native-packages apply --host desktop --adopt visual-studio-code-bin` explicitly takes ownership of those already installed, declared packages.
- `native-packages plan --host desktop` previews the activated manifest directly.
- `native-packages check --host desktop` checks native backend prerequisites without reading or writing ownership state. Arch needs pacman and sudo, plus paru or yay when AUR packages are declared; macOS needs Homebrew; Fedora needs rpm, dnf and sudo. A WSL host with no native platform needs none of those tools.

Apply displays the plan and asks for confirmation when it changes packages or
ownership or repository configuration. `--yes` accepts that plan; package
manager prompts remain active. The platform's native tools must already exist:

- Arch uses pacman and an existing `paru` or `yay` for AUR.
- macOS uses an existing Homebrew, with formula and cask inventories kept
  separate. Automatic updates and dependency pruning are disabled for adapter
  transactions. It does not overwrite manually installed applications.
- Fedora installs through DNF and removes exact targets through `rpm -e`,
  which refuses reverse-dependency breakage instead of cascading into unmanaged
  packages. Repository files use an adapter-specific name under
  `/etc/yum.repos.d`, require HTTPS sources and package signature checks,
  and refuse to overwrite unmanaged changes.

Fedora repository updates use an atomic rename and a separate recovery journal.
Repositories are shared package sources and remain after their last application
is removed so other packages retain access to updates. Existing matching
repository files remain unmanaged; existing modified files are never adopted
implicitly. DNF keeps its normal signing-key import confirmation.

The adapter does not bootstrap package managers or update the system. Continue
ordinary native package upgrades separately. VS Code mappings follow
[Microsoft's Linux instructions](https://code.visualstudio.com/docs/setup/linux)
and the [Homebrew cask](https://formulae.brew.sh/cask/visual-studio-code).

The receipt is `~/.local/state/native-packages/receipt.json` (respects
`XDG_STATE_HOME`). It binds one host configuration to one machine ID and uses a
lock plus an atomic receipt and pending-install journal. Re-running after a
failure queries the real package database and recovers completed operations.
Do not delete the receipt or use a new state directory to change host identity:
that loses ownership history. Keep one managing user and state directory per
machine; separate users or unrelated package tools do not share ownership.

Apply migrates older receipts to version 3, preserving owned targets and pending install recovery while discarding the retired retention policy. Older adapters reject the new receipt. Manifest version 4 removes retention declarations; activate the current Home Manager configuration before using the updated adapter with an older retention manifest.

Pre-existing packages are preserved unless explicitly adopted. Only declared targets installed by the adapter become owned. Arch recursive removal can remove their unneeded dependencies, but preserves explicitly installed packages and dependencies required by other installed packages. It does not sweep unrelated orphans, cascade into reverse dependencies, bypass dependency checks, or purge application data. Dependencies and AUR build tools are not directly owned. Homebrew and Fedora retain their existing removal behavior. Packages used by custom scripts or otherwise outside package dependency metadata must remain declared or explicitly installed. The remaining `post-setup.sh` bootstrap packages and privileged host setup stay separate.

## Codex user configuration

`AI/settings/codex/config.toml` is the declarative baseline for personal Codex
settings. Codex CLI and Desktop share `~/.codex/config.toml` and both need to
write machine-local state there, so Home Manager keeps that file writable
instead of linking it into the repository.

During activation, the Codex client adapter recursively merges the tracked
baseline into the writable file. Tracked values win conflicts, while local-only
values such as project trust, generated MCP helpers, marketplace metadata, and
cache paths remain untouched. The adapter records the previously managed key
paths under the XDG state directory so removing a tracked setting also removes
its old local value.

Run `just codex-config-apply` from `nix/` to apply tracked changes immediately
without switching the full Home Manager profile. Settings changed through
Codex remain local unless they are deliberately added to the tracked baseline.

## Bootstrap prerequisites

Bootstrap runs as your normal user with sudo available. Linux needs apt-get, dnf, or pacman. It refreshes APT metadata, accepts DNF’s “updates available” result without hiding actual errors, and runs a full `pacman -Syu` on Arch before installing prerequisites. Update failures stop bootstrap. Linux installer prerequisites include curl, CA certificates, tar and xz, plus Fedora’s existing awk/development-tools setup. macOS requires Xcode Command Line Tools to finish installing before bootstrap continues.

After Nix setup and repository sync, bootstrap evaluates the requested host and runs its packaged `native-packages check` before Home Manager activation. It also checks for the age identity when the host selects secrets or identities. Existing Homebrew installations are discovered in `/opt/homebrew/bin` or `/usr/local/bin` if needed. Missing Homebrew, an AUR helper, or other backend tools must be installed before retrying; bootstrap does not install new package managers automatically. Native reconciliation uses the packaged command directly, so a fresh shell does not need its newly activated profile on PATH yet.

## How to add a host

1. Create `hosts/<name>.nix` declaring `my.os`, `my.desktop`, `my.hasDesktop` when needed,
   `my.gpu.*`, `my.identities`, `my.secrets`, `my.apps.bundles`,
   `my.ai.bundles`, etc.
2. Add a `homeConfigurations."<name>"` entry to `flake.nix` pointing at
   the right system + the new host file.
3. If the host runs CUDA, add its compute capability under
   `hostCudaCapabilities`.
4. Run `just build <name>` to verify, then
   `just switch <name>` to activate and reconcile native packages.

For a **WSL host** (`my.os = "wsl"`), the only step nix can't do is the
Windows-side prerequisite — on a fresh machine run `wsl --install` in
PowerShell first (installs the distro + reboots), then bootstrap inside it.
Everything after that (browser bridge, WezTerm-config mirror to Windows) is
owned by `modules/wsl.nix`; set `my.wsl.windowsUser` so the mirror knows the
`C:\Users\<name>` target. Root-owned `/etc/wsl.conf` tweaks stay in
`post-setup.sh`.

## Identity model

`secrets/meta.nix` lists every identity (personal, sprung, …) with its
SSH key, GPG config, git email, and remote URL patterns. A host opts in
to identities via `my.identities = [ ... ]`. Modules `secrets`, `gpg`,
`ssh`, `git` filter to that list — a host that lists no identities
decrypts none.

On Linux, both SSH key and GPG signing passphrases persist in libsecret
(KWallet/gnome-keyring) and are re-injected into their agents at login —
SSH via `ssh-add-keys` (`ssh.nix`), GPG via `gpg-preset-passphrases`
(`gpg.nix`) — so neither re-prompts after a reboot. macOS uses Keychain
instead.

See `secrets/README.md` for more details.

## Validation

- `just build <host>` — eval-and-build without activating.
- `just diff <host>` — closure diff vs. current activation. Useful to
  check that a refactor is behavior-preserving.
- `nix flake check` — schema sanity.
