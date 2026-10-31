---
agent:
  instruction: Update this README when Nix catalog or host workflows change.
  on-change:
    [
      "nix/lib/**",
      "nix/identities.nix",
      "nix/modules/**",
      "nix/scripts/native-packages.py",
      "nix/mise.toml",
      "nix/mise-tasks/**",
    ]
---

# nix config

Cross-platform Home Manager flake.

## Layout

```
nix/
  flake.nix                # sharedModules + per-host wiring + cudaCapabilities map
  bootstrap.sh             # 1-click install: prereqs → clone → HM switch → post-setup
  post-setup.sh            # root-owned config and APT fallback
  mise.toml                # switch/build/clean; switch --dry-run covers Home Manager and native packages
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
    onepassword.nix        # native 1Password paths and with-secrets launcher
  identities.nix           # public Git/SSH identity registry
```

## Bootstrap prerequisites

Bootstrap runs as your normal user with sudo available. Linux needs apt-get, dnf, or pacman. It refreshes APT metadata, accepts DNF’s “updates available” result without hiding actual errors, and runs a full `pacman -Syu` on Arch before installing prerequisites. Update failures stop bootstrap. Linux installer prerequisites include curl, CA certificates, tar and xz, plus Fedora’s existing awk/development-tools setup. macOS requires Xcode Command Line Tools to finish installing before bootstrap continues.

After Nix setup and repository sync, bootstrap evaluates the requested host and runs its packaged `native-packages check` before Home Manager activation. Existing Homebrew installations are discovered in `/opt/homebrew/bin` or `/usr/local/bin` if needed. Missing Homebrew, an AUR helper, or other backend tools must be installed before retrying; bootstrap does not install new package managers automatically. Native reconciliation uses the packaged command directly, so a fresh shell does not need its newly activated profile on PATH yet.

## Authentication

1Password holds active SSH keys and local API credentials. Git uses the native SSH signer and signs commits and tags automatically. Public identity selection lives in `identities.nix`; private keys and account credentials never enter Nix output.

After installation:

1. Sign in to 1Password and enable its own **start at login** setting.
2. Enable the **SSH agent** and **CLI integration** under Developer settings, and desktop integration in the browser extension. Configure system authentication if desired.
3. From `nix/`, run `mise run onepassword-check`. It checks native CLI/MCP integration and attempts authentication without printing vault contents. See `scripts/README.md` for package-upgrade troubleshooting.

SSH approvals and CLI approvals are separate. CLI authorization is terminal-session scoped; new sessions and MCP server restarts can prompt again. Vault locking can interrupt both. Already-running processes retain injected credentials until they exit. See the [CLI authorization model](https://www.1password.dev/cli/app-integration-security) and [SSH agent settings](https://www.1password.dev/ssh/agent/security).

Arch SSH authentication, signing and runtime injection have been checked live. macOS is configured but runtime-unverified. The diagnostic does not establish offline access, recovery, or unattended approval handling; check those workflows before relying on them.

## Runtime secrets

Native `1password` selection installs `with-secrets` from `modules/onepassword.nix`:

```sh
with-secrets ENVIRONMENT_ID hf download organisation/model
```

The helper runs the native `op run --environment` command. It passes every variable in the selected Environment to the command and its descendants, preserving arguments and exit status. Discover Environment IDs and variable names through the 1Password MCP; keep values in 1Password and out of configuration, command arguments and logs. Use a separate Environment when a consumer needs a narrower set of credentials.

For a local MCP server, set its launch command to `with-secrets` and its arguments to `ENVIRONMENT_ID`, the server executable, and any server arguments. The server must read credentials from its environment. Both executables must be on the client's PATH; use absolute paths when needed. Allow startup time for interactive approval and keep stdout reserved for the MCP protocol. Remote HTTP servers use the client's authentication support, such as OAuth.

Interactive Zsh loads 1Password's generated `plugins.sh` when present, respecting `OP_CONFIG_DIR`. Initialize supported commands with `op plugin init <command>` and select an existing vault item and credential scope. Defaults and item references stay in 1Password's local configuration. Non-interactive agent commands use `op plugin run -- <command> ...` explicitly. For Hugging Face, initialize `hf` once the installed CLI lists it in `op plugin list`; the legacy `huggingface-cli` plugin does not support the current executable.

Editors receive no automatic secret injection. Mise manages runtimes, shims and project `.env` loading. Project mounts and CI credential delivery belong to their respective projects.

## Identity model

Each entry in `identities` in `identities.nix` defines `name`, `email`, `sshPublicKey`, a unique `sshHost` alias, its real `sshProxyHost`/`sshPort`, and `remotePatterns`. Select available entries with the host's `my.identities`. Set `my.git.defaultIdentity` to one of those names for unmatched or new repositories. With no default, Git requires a matching rule or an explicit local identity.

For example, a work identity can use `sshHost = "work-github.com"`, `sshProxyHost = "ssh.github.com"`, and `sshPort = 443`. Its patterns would include `git@work-github.com:*/**` and `ssh://git@work-github.com/**`. A remote such as `git@work-github.com:company/project.git` then selects the work name, email and signing key; SSH connects to GitHub using the work public key. The private key must already be available in the selected agent. Keep personal rules scoped to `github.com`. HTTPS rules can select commit metadata but do not use SSH host aliases or the SSH authentication key.

These rules inspect remote **URLs**, not labels such as `origin` or `upstream`. Git reads every configured remote URL. If one repository matches more than one identity, include order can decide which wins; it does not follow the last fetch or push. Set `git config --local user.name`, `user.email`, and `user.signingKey` explicitly in that repository. Local settings also override the fallback and remote rules. Inspect the result with `git config --show-origin --get-regexp '^user\.'` and inspect SSH routing with `ssh -G work-github.com`.
