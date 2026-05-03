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
    catalog.nix            # mkCatalogType / resolveEnabled / mergeField
  hosts/
    desktop.nix            # arch + KDE + CUDA workstation
    work-macbook.nix       # aarch64-darwin + metal
  modules/
    system.nix             # my.* identity options surface
    apps/
      default.nix          # dispatcher + flatpak/program-specific wiring
      catalog.nix          # bundleNames + entries (data only)
    ai/
      default.nix          # AI dispatcher
      catalog.nix          # bundleNames + entries
      {claude,llama,shared}.nix
    <tool>.nix             # config for larger tools (git, mise, ssh, …)
    common.nix             # universal HM infrastructure
    secrets.nix            # agenix wiring, filtered by my.identities / my.secrets
  secrets/                 # age-encrypted, identity registry in meta.nix
```

## How to add a tool

1. **Trivial** (just a flatpak id, just a package, just `programs.X.enable`):
   add an entry to `modules/apps/catalog.nix`. Tag it with the right
   bundle (`cli`, `dev`, `security`, `fonts`, `communication`, `cloud`).
2. **Substantial config** (extensions, services, identity wiring): write
   a dedicated module `modules/<tool>.nix`, add it to `sharedModules`.
3. **Joins a domain** (AI, future "k8s" or similar): add to that
   domain's catalog, or sibling file inside the domain directory.

The lifecycle rule is complexity-based, not source-mechanism-based.
Lookup is by tool name; mechanism is a one-field edit (`flatpak` →
`package` → `program`).

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

## Identity model

`secrets/meta.nix` lists every identity (personal, sprung, …) with its
SSH key, GPG config, git email, and remote URL patterns. A host opts in
to identities via `my.identities = [ ... ]`. Modules `secrets`, `gpg`,
`ssh`, `git` filter to that list — a host that lists no identities
decrypts none.

See `secrets/README.md` for more details.

## Validation

- `just build <host>` — eval-and-build without activating.
- `just diff <host>` — closure diff vs. current activation. Useful to
  check that a refactor is behavior-preserving.
- `nix flake check` — schema sanity.
