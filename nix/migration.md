# Nix config refactor — migration plan

A self-contained plan: target architecture, ordered implementation phases, validation, and the decision rationale that produced them.

## Goals

- One coherent way to add a new machine: a single host file that opts in to features.
- Modules are inert until enabled; the flake imports all of them unconditionally.
- No impure eval (`builtins.pathExists /etc/arch-release`), no scattered `lib.mkForce` chains, no per-host conditional imports.
- Removing a feature (an app, an AI tool, an identity) means deleting one entry, not chasing references across files.

---

## Target architecture

### Namespace

All user-defined options live under `my.*`.

### Directory structure

```
nix/
  flake.nix
  bootstrap.sh
  post-setup.sh
  lib/
    catalog.nix          # mkCatalogType helper
  hosts/
    desktop.nix          # renamed from home.nix
    work-macbook.nix         # renamed from work.nix
    <future hosts>.nix
  modules/
    system.nix           # NEW. Identity options surface (my.os, my.desktop, my.gpu, ...)
    common.nix           # Slim universal infrastructure (~40 lines)
    secrets.nix          # Identity-driven, filtered per host
    apps.nix             # NEW. Unified app catalog (replaces flatpaks + dev)
    ai/                  # NEW directory (replaces AI.nix). Domain module.
      default.nix        # Imports siblings + declares my.ai.* options
      catalog.nix        # AI tool catalog (data + dispatch)
      shared.nix         # Cross-tool infra: AGENTS.md generation, skill rebuild scripts
      claude.nix         # Claude link tree (.claude/agents, hooks, rules, skills, settings.json)
      llama.nix          # llama-cpp override + llama-swap service + mmproj download
    git.nix              # NEW. Extracted from common.nix.
    mise.nix             # NEW. Extracted from common.nix.
    yazi.nix             # NEW. Extracted from common.nix for cleanliness.
    nvim.nix             # NEW. neovim + ninja + luarocks + mason PATH + config symlink.
    gpg.nix              # Identity-driven; pinentry per (my.os, my.desktop).
    ssh.nix              # Identity-driven.
    kde.nix              # Gated on my.desktop = "kde".
    zsh.nix              # Universal shell config.
  secrets/               # Unchanged.
```

### Module shapes

| Shape                           | Examples                                                                                  | What it owns                                                                            |
| ------------------------------- | ----------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| **App module**                  | `git.nix`, `mise.nix`, `gpg.nix`, `ssh.nix`, `kde.nix`, `zsh.nix`, `nvim.nix`, `yazi.nix` | One tool's full setup (install + config).                                               |
| **App catalog** (one)           | `apps.nix`                                                                                | Typed catalog of trivial-to-medium apps across all installation mechanisms.             |
| **Domain module** (one for now) | `ai/`                                                                                     | Catalog _plus_ shared cross-tool infrastructure scoped to a domain. Always a directory. |
| **Infrastructure**              | `system.nix`, `common.nix`, `secrets.nix`                                                 | Identity options, universal baseline, secrets wiring.                                   |

**Lifecycle rule** — complexity, not source mechanism, decides where a tool lives:

- Trivial install (just a flatpak id, just a package, just `programs.X.enable`) → entry in `apps.nix`.
- Grows substantial config (extensions, identity wiring, services) → graduates to its own app module.
- Joins a coherent domain with shared cross-tool infra → entry in that domain module's catalog.

### Catalog schema (`lib/catalog.nix`)

Shared base with per-domain extensions:

```nix
mkCatalogType = { bundleNames, extraOptions ? {} }:
  types.attrsOf (types.submodule {
    options = {
      package          = mkOption { type = types.nullOr types.package; default = null; };
      bundles          = mkOption { type = types.listOf (types.enum bundleNames); default = []; };
      sessionVariables = mkOption { type = types.attrsOf types.str; default = {}; };
      files            = mkOption { type = types.attrs; default = {}; };
      services         = mkOption { type = types.attrs; default = {}; };
      activation       = mkOption { type = types.attrs; default = {}; };
    } // extraOptions;
  });
```

Module-specific extras:

- `apps.nix`: `flatpak = nullOr { id; overrides; }`, `program = nullOr { name; settings; }`. Bundle names: `baseline`, `security-tools`, `fonts`, `communication`, `gaming`, `mobile-dev`, `creative` (final list during impl).
- `ai/catalog.nix`: `needsGpu = bool`. Bundle names: `cli-agents`, `local-models`, `tooling`.

Plus an assertion per `apps.nix` entry: at least one of `flatpak`/`package`/`program` must be set.

When complexity exceeds what `services`/`activation`/`files` can express, it lives in the **module body** (e.g. `ai/claude.nix`, `ai/llama.nix`), not in catalog entries. There is no `extra` escape hatch.

### Host opt-in semantics

Include lists only. The set of installed entries for a host = (entries in any enabled bundle) ∪ (individually enabled entries):

```nix
my.apps.bundles = [ "baseline" "communication" "security-tools" ];
my.apps.enabled = [ "android-tools" "stripe-cli" ];
```

Same shape for `my.ai.bundles` / `my.ai.enabled`. **No exclude list.** New catalog entries never propagate silently. If a bundle is wrong for a host, split it or don't enable it.

### Identity model

`secrets/meta.nix` is the source of truth for identities and non-identity secrets. Hosts list which subset they want:

```nix
my.identities = [ "personal" "work" ];
my.secrets    = [ "some-token" ];
```

Modules `secrets.nix`, `gpg.nix`, `ssh.nix`, and `git.nix` filter `meta.identities` / `meta.secrets` by these lists. A host that lists no identities decrypts none. No back-compat default.

### Identity options

Declared in `system.nix`:

```nix
options.my = {
  os         = mkOption { type = types.enum [ "arch" "darwin" "fedora" ]; };
  desktop    = mkOption { type = types.enum [ "kde" "none" ]; default = "none"; };
  gpu = {
    backend            = mkOption { type = types.enum [ "none" "cuda" "rocm" "vulkan" "metal" ]; default = "none"; };
    cuda.capabilities  = mkOption { type = types.listOf types.str; default = []; example = [ "8.6" ]; };
  };
  dotfilesPath       = mkOption { type = types.path; default = "${config.home.homeDirectory}/dotfiles"; };
  identities         = mkOption { type = types.listOf types.str; default = []; };
  secrets            = mkOption { type = types.listOf types.str; default = []; };
  browser.executable = mkOption { type = types.nullOr types.str; default = null; };
};
```

`darwin` hosts always set `my.desktop = "none"` (Aqua isn't switchable and isn't modeled).

### Override mechanics

- All `lib.mkForce` from host files removed (host is the source of truth).
- All `pkgs.stdenv.isLinux`/`isDarwin` checks rewritten against `my.os`/`my.desktop`. KDE-flavored bits (e.g. `pinentry-qt`) check `my.desktop`, not `my.os` — KDE on Fedora must get the same treatment as KDE on Arch.
- `lib.optional`/`lib.optionals` (functional list construction) are not override mechanics; left untouched.
- `lib.mkDefault`/`lib.mkForce` elsewhere reviewed case-by-case during migration.

### `bootstrap.sh` and `post-setup.sh`

- `bootstrap.sh` stays a 1-click installer. Slimmed by deleting `ensure_kde`. New flow: prereqs (git/flatpak/nix) → clone repo → `home-manager switch` → run `post-setup.sh` → mise install → chsh.
- `post-setup.sh` dispatches on OS via release-file detection (Arch + Fedora). Owns all system packages, including KDE userland (Dolphin plugins, ksshaskpass, partitionmanager, flatpak-kcm) — these stay system-installed because KDE plugin discovery doesn't participate in nix profile paths.

### Cross-module imports

- ❌ Modules don't `imports = [ ./other.nix ]` each other. The flake is the sole place that enumerates modules.
- ✅ Intra-module imports (e.g. `ai/default.nix` importing its siblings) are fine — same module, just split across files.
- ✅ Host-local imports (a host file importing a sibling helper) are fine — host scope only.

Modules can still depend on each other's _options_ (`git.nix` reading `config.my.identities` set elsewhere). That's normal nix module composition, not an import.

---

## Implementation phases

Each phase is a logical commit boundary. Every phase must produce a buildable flake and a passing `home-manager build` for every host. **Don't move to the next phase until the current one builds clean.**

### Phase 0 — justfile helpers (optional, recommended)

**Goal:** make per-phase validation a one-liner.

Add `build` and `diff` recipes to `nix/justfile` so the validation strategy below is just `just build desktop && just diff desktop`. Add docstring comments to existing recipes so `just --list` is self-documenting. Pure quality-of-life; doesn't change any nix behavior, but the rest of the plan assumes these recipes exist.

```just
# Build a host configuration without activating it: `just build desktop`
build host:
    {{ _nix }} build --no-link "{{ FLAKE_DIR }}#homeConfigurations.{{ host }}.activationPackage"

# Closure diff between current activation and a fresh build: `just diff desktop`
diff host:
    {{ _nix }} store diff-closures \
      "$HOME/.local/state/home-manager/gcroots/current-home" \
      "$({{ _nix }} build --no-link --print-out-paths "{{ FLAKE_DIR }}#homeConfigurations.{{ host }}.activationPackage")"
```

**Validation:** `just --list` shows all recipes with descriptions; `just build home` and `just build work` (current host names) succeed.

### Phase 1 — Scaffolding

**Goal:** new infrastructure exists; no behavior change.

- Create `lib/catalog.nix` with `mkCatalogType`.
- Create `modules/system.nix` declaring all `my.*` identity options with neutral defaults (`my.os` is the only required one — has no default; everything else defaults to "off"/empty).
- Add `system.nix` to the flake's module list for both hosts.
- Hosts gain `my.os = "..."` (and `my.desktop`, `my.gpu`, `my.dotfilesPath`, `my.identities`, `my.secrets`, `my.browser.executable`) matching their current implicit values. No options consumed yet — purely declarative.

**Validation:** `home-manager build` produces an identical-or-empty diff for each host's closure.

### Phase 2 — Apply identity filter to secrets/SSH/GPG

**Goal:** identity options actually drive behavior; introduces credential-hygiene change.

- `secrets.nix`, `gpg.nix`, `ssh.nix` filter `meta.identities` / `meta.secrets` by `my.identities` / `my.secrets`.
- Each host's `my.identities` / `my.secrets` lists must enumerate exactly what that host should have. **This is the first behavior change.** Confirm post-build that each host's `~/.ssh` / `~/.secrets` content matches expectations.

**Validation:** `nix-store -q --references` on each host's activation script lists only the expected identity files.

### Phase 3 — AI domain rewrite (`AI.nix` → `ai/`)

**Goal:** AI is a directory, options renamed under `my.ai.*` / `my.gpu.*`.

- Move `AI.nix` to `ai/default.nix`. Split into `catalog.nix`, `shared.nix`, `claude.nix`, `llama.nix` per the architecture.
- Rename options: `ai.gpuBackend` → `my.gpu.backend` (read from `system.nix`); `ai.claudeTargetDir` → `my.ai.claude.targetDir`.
- Convert installed packages to `mkCatalogType`-typed catalog with bundles `cli-agents` / `local-models` / `tooling`.
- Hosts switch to `my.ai.bundles = [...]` + `my.ai.enabled = [...]` and set `my.ai.claude.targetDir` directly (no `mkForce`).
- **Move `cudaCapabilities` from `flake.nix` to per-host `my.gpu.cuda.capabilities`.** This requires reading per-host config at flake-eval time. Verify this works cleanly via a small experiment first; if it doesn't, fall back to keeping `cudaCapabilities` in `flake.nix` as a host-name-keyed map and document the limitation.
- Drop all `lib.mkForce` from hosts (now unnecessary).

**Validation:** package list per host matches pre-migration; llama-swap service still starts on the desktop; Claude link tree still resolves.

### Phase 4 — Apps catalog (`apps.nix`)

**Goal:** the big migration. Flatpaks, plain packages, and trivial `programs.X.enable` lines all consolidated into one catalog.

- Create `modules/apps.nix` using `mkCatalogType`. Define bundle vocabulary (`baseline`, `security-tools`, `fonts`, `communication`, `gaming`, `mobile-dev`, `creative`).
- Migrate every flatpak from current `hosts/home.nix` + `hosts/work.nix` into the catalog (`flatpak`-typed entries).
- Migrate every nix package from `common.nix:sharedPackages` + `linuxPackages` + `darwinPackages` into the catalog (`package`-typed entries). The `ffmpeg-full` override moves as `package = (pkgs.ffmpeg-full.override { withUnfree = true; }).overrideAttrs (_: { doCheck = false; });`.
- Migrate every trivial `programs.X.enable = true` from `common.nix` into the catalog (`program`-typed entries). The eza settings block becomes `program = { name = "eza"; settings = { ... }; }`.
- Move flatpak environment (`xdg.systemDirs.data`, `environment.d/20-flatpak.conf`) into `apps.nix`, gated on at least one flatpak entry being enabled.
- Hosts switch to `my.apps.bundles = [...]` + `my.apps.enabled = [...]`.
- `common.nix` shrinks to its target ~40 lines (env, xdg, fonts, `programs.home-manager.enable`).

**Validation:** for each host, the realized package list (`home-manager packages` or closure traversal) is unchanged from pre-migration. Each flatpak overrides block produces identical xdg portal config.

### Phase 5 — Extract substantial app modules

**Goal:** `git`, `mise`, `yazi`, `nvim` graduate to their own files.

- Create `modules/git.nix`. Move `programs.git.settings`, `gitIdentityFiles`, `gitIncludes` from `common.nix`. Apply `my.identities` filter to per-identity files and includeIf rules. `gh` reference stays via `${pkgs.gh}/bin/gh` (gh comes from `apps.nix` baseline bundle).
- Create `modules/mise.nix`. Move `programs.mise.globalConfig` from `common.nix`. Tool versions (node 24, python 3.14.4, go 1.25, rust 1.92) are universal defaults. Add `my.mise.trustedPaths` option for per-host additions.
- Create `modules/yazi.nix`. Move `programs.yazi` block from `common.nix` verbatim.
- Create `modules/nvim.nix`. Move neovim + ninja + luarocks packages here. Include the mason PATH (`~/.local/share/nvim/mason/bin`) and the `xdg.configFile."nvim"` symlink to `${config.my.dotfilesPath}/nvim`.
- `common.nix` is now down to its final ~40-line shape.

**Validation:** package lists unchanged. Git identity files appear only for hosts' enumerated identities. Yazi config parses identically.

### Phase 6 — Override-mechanics cleanup

**Goal:** all OS/DE gating uses `my.*`; `mkForce` is gone from host code.

- Replace `pkgs.stdenv.isLinux` / `isDarwin` checks across modules:
  - `gpg.nix:pinentry.package` becomes a function of `(my.os, my.desktop)`.
  - `ssh.nix` env-var blocks and systemd service: `mkIf (my.os != "darwin")` (or more specific where appropriate).
  - `common.nix:targets.genericLinux.enable` → `my.os != "darwin"`.
- Audit any remaining `mkForce` / `mkDefault`. Drop where the layered options model makes them redundant; keep where genuinely meaningful.
- Remove `lib.optionalAttrs (system == "x86_64-linux")` for `cudaCapabilities` from `flake.nix` (resolved by Phase 3).

**Validation:** `git grep 'mkForce\|isLinux\|isDarwin'` should return only intentional uses; `nix flake check` clean.

### Phase 7 — `bootstrap.sh` and `post-setup.sh`

**Goal:** installer flow matches the architecture.

- Delete `ensure_kde` from `bootstrap.sh`. Bootstrap's main loop becomes: prereqs → clone → HM switch → run `post-setup.sh` → mise install → chsh.
- `post-setup.sh` gains Fedora dispatch and KDE userland install (moved from bootstrap's `ensure_kde`). Keep its runtime `XDG_CURRENT_DESKTOP`/`DESKTOP_SESSION` detection for KDE.
- During this phase, **verify the "node before HM" assumption** is no longer relevant (it appears stale based on AI activation scripts using only nix-built tools). If something genuinely needs system node/python before HM, lift it into nix; don't reorder bootstrap.

**Validation:** bootstrap.sh on a fresh VM (or a dry-run script) completes without manual intervention.

### Phase 8 — Host renaming

**Goal:** `home` → `desktop`, `work` → `work-macbook`.

- Rename `hosts/home.nix` → `hosts/desktop.nix`, `hosts/work.nix` → `hosts/work-macbook.nix`.
- Update `flake.nix` `homeConfigurations` keys.
- Update `bootstrap.sh` `--host` examples / docs.
- Update any local muscle-memory aliases / shell history references the user keeps.

**Validation:** `home-manager switch --flake .#desktop` and `home-manager switch --flake .#work-macbook` both succeed.

### Phase 9 — Final cleanup

- Delete `nix/migration.md`.
- Update or create `nix/README.md` describing the structure: hosts, modules, catalogs, bundles, the lifecycle rule, where to add a new tool. (Brief; the architecture in this file is the source.)

---

## Validation strategy

After every phase:

1. `nix flake check` — schema/eval clean.
2. `home-manager build --flake .#desktop` — desktop host builds.
3. `home-manager build --flake .#work-macbook` — work mac builds.
4. **Closure diff vs. pre-phase:** the migration is "behavior-preserving except where explicitly redefined." For any phase that's supposed to be behavior-preserving (Phase 1, parts of Phase 4, Phase 5, Phase 6), use `nix store diff-closures` between the previous activation result and the new build to confirm no accidental package additions/removals.
5. **Activation smoke test** (optional, when in doubt): `home-manager switch` on the desktop and confirm:
   - `~/.ssh` contains exactly the keys for `my.identities`.
   - `~/.claude/agents` (etc.) symlinks resolve.
   - `systemctl --user status llama-swap` is active (when GPU+local-models enabled).
   - Flatpak overrides show in `flatpak override --user --show com.discordapp.Discord` for enabled apps.

If a phase produces an unexpected diff, stop and investigate before moving on.

---

## Decisions log

D1–D18 capture the decisions and their rationale. The architecture above is the result; this section is the audit trail. Brief here — see git history of `migration.md` for the deliberation if needed.

- **D1** — `my.os : enum [ "arch" "darwin" "fedora" ]`. Fedora reserved for an upcoming machine.
- **D1b** — `my.desktop : enum [ "kde" "none" ]`. KDE is the only Linux DE Simon runs consistently. Add to enum when a new DE becomes a daily driver.
- **D2** — `my.gpu` is structured: `{ backend; cuda.capabilities; }`. Backend-specific config nested under sub-attrs matching backend name. Implementation note: confirm capabilities can be read at flake-eval time during Phase 3; otherwise keep `cudaCapabilities` in `flake.nix` as a host-name-keyed map.
- **D3** — Personal/work composition: hosts opt into "work-flavored" toggles directly. No `modules/work.nix` umbrella. `hosts/work.nix` dissolves into `hosts/work-macbook.nix` (a peer host, not a layer imported into desktop).
- **D4** — Module inventory per the architecture above. Three module shapes (app modules, app catalog, domain modules) plus infrastructure.
- **D4b** — Organizing principle: lifecycle-by-complexity, not by source mechanism. Lookup is by tool name, never by mechanism. Unified `apps.nix` schema is a typed union (`flatpak | package | program` + shared extras) so source can be swapped with a one-field edit.
- **D4c** — Subdirectory inside `modules/` ⇔ domain module. App modules and infrastructure stay flat.
- **D4d** — Host opt-in via include lists only (`bundles` ∪ `enabled`). No exclude list.
- **D5** — AI domain takes recommended defaults: catalog with `cli-agents`/`local-models`/`tooling` bundles; `claudeTargetDir` → `my.ai.claude.targetDir`; mmproj list internal to `ai/llama.nix`. **Flagged for revisit:** the AI domain is messy (substantial activation scripts, GPU-conditional behavior, agent skill pipeline). Expect a deeper rethink after the rest of the migration lands.
- **D6** — Dissolved into D4b. No `dev.nix`; android-tools/stripe-cli/awscli2 become `package`-typed entries in `apps.nix`.
- **D7** — `post-setup.sh` stays hand-written, OS-dispatching via release-file detection. No nix integration; package list is small enough that lifting it would create OS→pkg-name mapping tables without removing complexity.
- **D8** — Override-mechanics audit. Drop all `mkForce` from hosts. Replace `isLinux`/`isDarwin` with `my.os`/`my.desktop`. Keep `lib.optional`/`lib.optionals` (list construction). Review remaining `mkDefault`/`mkForce` case-by-case.
- **D9** — Per-host filter for both identities and non-identity secrets. No back-compat default.
- **D10** — `bootstrap.sh` stays 1-click. `ensure_kde` moves into `post-setup.sh` (KDE userland stays system-installed). Bootstrap explicitly runs `post-setup.sh` after HM activation.
- **D11** — Catalog entries are typed data via `mkCatalogType { bundleNames, extraOptions }`. Shared base + per-domain extras. No `extra` escape hatch.
- **D12** — AI catalog/shared-infra split per D4c + D11. `claudeTargetDir` is a top-level option on the AI domain module, not a catalog field.
- **D13** — `common.nix` is pure infrastructure (~40 lines). All "install a tool" content moves to `apps.nix`.
- **D14** — Targeted extracts from `common.nix`: flatpak env → `apps.nix`; identity-aware git → `git.nix`; npm prefix → host-local; `CHROME_EXECUTABLE` → `my.browser.executable`; mise tool versions → universal in `mise.nix`; mise trusted paths → per-host; yazi → `yazi.nix`; config-file symlinks stay in `common.nix` referencing `config.my.dotfilesPath`.
- **D15** — Flake imports all modules; hosts set options only. Cross-module imports dropped. Intra-module and host-local imports fine.
- **D16** — Tool grouping: security tools and fonts become bundles in `apps.nix`; ffmpeg-full is a catalog entry; nvim graduates to `nvim.nix` (multi-concern).
- **D17** — `my.dotfilesPath` declared in `system.nix`. All dotfile-symlink modules reference it instead of hardcoding.
- **D18** — Host renaming: `home` → `desktop`, `work` → `work-macbook`. Touches `flake.nix` keys, `hosts/*.nix` filenames, `bootstrap.sh` invocations.
