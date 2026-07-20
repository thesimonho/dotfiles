---
agent:
  instruction: Update this codemap when top-level Home Manager modules change.
  on-change:
    - "nix/modules/*.nix"
    - "nix/modules/apps/**"
---

# Nix Modules

Shared Home Manager modules for shell, editor, credentials, desktop integration, and platform-specific behavior.

## Files

| File | Description |
| --- | --- |
| `common.nix` | Baseline packages, environment variables, and shared dotfile links |
| `system.nix` | System-level defaults shared across supported hosts |
| `apps/` | Declarative application catalog and bundle selection |
| `ai/` | AI client and tool configuration; see [AI modules](./modules/ai.md) |
| `git.nix` / `gpg.nix` / `ssh.nix` / `secrets.nix` | Source-control identity, signing, keys, and secret material integration |
| `nvim.nix` / `zsh.nix` / `yazi.nix` / `mise.nix` | Developer shell and editor tooling |
| `kde.nix` | KDE desktop preferences and integration |
| `wsl.nix` | Windows Subsystem for Linux behavior |

## Relationships

- **Imports from**: `nix/lib/` for catalogs and host context.
- **Used by**: host configurations in `nix/hosts/`.
- **Links to**: application directories at the repository root through Home Manager-managed dotfiles.

## Entry point

Start with `common.nix` for repository-wide defaults, then the feature module matching the affected tool.
