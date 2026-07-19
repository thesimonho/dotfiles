# nix config

Cross-platform Home Manager flake.

## Layout

```
nix/
  flake.nix                # sharedModules + per-host wiring + cudaCapabilities map
  bootstrap.sh             # 1-click install: prereqs → clone → HM switch → post-setup
  post-setup.sh            # OS-native packages HM can't manage (KDE userland, docker, …)
  justfile                 # `just switch`, `just build`, `just diff`, `just clean`
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

1. **Trivial** (just a Flatpak ID, package, or Home Manager program): add an
   entry to `modules/apps/catalog.nix`. Tag it with the right bundle (`cli`,
   `dev`, `security`, `fonts`, `communication`, `cloud`) and place its Home
   Manager values under `contributions`.
2. **Substantial config** (extensions, services, identity wiring): write
   a dedicated module `modules/<tool>.nix`, add it to `sharedModules`, and let
   the catalog contribute the typed option that activates it.
3. **Joins a domain** (AI, future "k8s" or similar): add to that
   domain's catalog, or sibling file inside the domain directory.

The lifecycle rule is complexity-based, not source-mechanism-based.
Domain `default.nix` files select applicable entries and invoke the shared
realizer; they do not branch on application names.

Every catalog entry has three shared sections:

- `bundles` selects the entry through host bundle policy.
- `requirements` constrains Nix system, operating system, desktop presence,
  desktop environment, or GPU backend using values from `lib/host-context.nix`.
- `contributions` adds packages, programs, user services, files, session
  variables, aliases, or activation entries through Home Manager.

Flatpak remains an apps-only adapter because no other catalog domain needs it.
If the host model cannot express an applicability rule, extend
`lib/host-context.nix` and the corresponding `my.*` option instead of adding a
hostname check or arbitrary predicate to a catalog entry.

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

## How to add a host

1. Create `hosts/<name>.nix` declaring `my.os`, `my.desktop`,
   `my.gpu.*`, `my.identities`, `my.secrets`, `my.apps.bundles`,
   `my.ai.bundles`, etc.
2. Add a `homeConfigurations."<name>"` entry to `flake.nix` pointing at
   the right system + the new host file.
3. If the host runs CUDA, add its compute capability under
   `hostCudaCapabilities`.
4. Run `just build <name>` to verify, then
   `home-manager switch --flake .#<name>`.

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
