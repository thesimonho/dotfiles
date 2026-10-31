# Modules

## How to add a tool

1. **Trivial** (just a Flatpak ID, package, or Home Manager program): add an entry to `modules/apps/catalog.nix`. Tag it with the right bundle (`cli`, `desktop`, `dev`, `security`, `fonts`, `communication`, `cloud`, `gamedev`) and place its Home Manager values under `contributions`.
2. **Substantial config** (extensions, services, identity wiring): write
   a dedicated module `modules/<tool>.nix`, add it to `sharedModules`, and let
   the catalog contribute the typed option that activates it.
3. **Joins a domain** (AI, future "k8s" or similar): add to that
   domain's catalog, or sibling file inside the domain directory.

The lifecycle rule is complexity-based, not source-mechanism-based.
Domain `default.nix` files select applicable entries and invoke the shared
realizer; they do not branch on application names.

Each domain keeps one `catalog.nix` with sibling `applications` and `support` sections. Put tools used directly in `applications`; put libraries, fonts, integration plugins, keyring services, dialog helpers, and protocol adapters in `support`. Both sections use the same entry shape and merge into one selection namespace, so bundles and explicit `enabled`/`disabled` lists work with either section. Entry names must be unique across both sections. This organization does not change package ownership or installation behavior.

Graphical desktop presence is `my.hasDesktop`, separate from `my.desktop` (the desktop environment). It defaults to whether a desktop environment is declared. A Mac can therefore use `desktop = "none"` and `hasDesktop = true`; a headless host can keep it false.

Catalog entries share these sections:

- `bundles` selects the entry through host bundle policy.
- `requirements` constrains Nix system, operating system, desktop presence,
  desktop environment, or GPU backend using values from `lib/host-context.nix`.
- `contributions` adds packages, programs, user services, files, session
  variables, aliases, or activation entries through Home Manager.

## Native catalog declarations

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
or version selectors. Supported mapping fields are `arch.pacman`, `arch.aur`, `arch.aurBuilds`,
`darwin.homebrew.formulae`, `darwin.homebrew.casks`, and `fedora.dnf`.
Application `requirements` describe real application constraints; package
names and package-source requirements belong in the platform mapping.

Both app and AI domains aggregate selected native declarations. A package stays desired until its last declaration disappears. Missing or empty host mappings fail evaluation with the domain/application name. Conflicting repository definitions also fail rather than choosing one silently.

Hosts can subtract bundle members through `my.apps.disabled` and
`my.ai.disabled`. Native package platforms default to the host OS.
LazyGit stays on Nix on all hosts.

If the host model cannot express an applicability rule, extend
`lib/host-context.nix` and the corresponding `my.*` option instead of adding a
hostname check or arbitrary predicate to a catalog entry.

## Native packages

Home Manager writes `~/.config/native-packages/manifest.json` and installs the `native-packages` command. The manifest includes the explicit host key, OS, architecture, native platform, selected backend package lists, repositories, and custom AUR build commands. Custom commands must name declared AUR packages and point into the Nix store. The receipt records successfully applied command paths; an initial custom build also rebuilds an existing package without implicitly adopting it. The reconciler is outside activation: `mise run switch <host>` first activates Home Manager, then applies its manifest. These are separate transactions.

A custom AUR build executable receives the selected helper (`paru` or `yay`) as its only argument during apply. It must build/install the exact declared package as the normal user, using sudo only through the native package tools. It also accepts `--check`: exit 0 means the installed package has the requested configuration, 1 schedules a rebuild, and other exit codes stop reconciliation. The check must not change the host. A failed build is not recorded as successfully configured, so the next apply retries it.

On Arch, apply marks every declared installed package explicitly installed before removing old packages. This protects declared packages even when they originally arrived as dependencies, without adopting pre-existing packages. Owned packages whose last declaration disappears are removed with `pacman -Rs`, including dependencies that pacman finds unneeded. The dry-run resolves this transaction using a temporary copy of pacman’s local database with declared packages protected; it does not change real install reasons. Apply installs wanted packages first and resolves removals again immediately before execution. Pacman displays its final transaction and keeps its normal confirmation.

A native failure leaves Home Manager activated and stops the recipe before generation cleanup. Retry with `native-packages apply --host <host>`. The first bootstrap switch also reconciles after activation. Both paths require reconciliation to succeed; a missing manifest is an error, not a reason to skip it.

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
