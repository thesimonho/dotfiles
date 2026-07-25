---
agent:
  instruction: Update this codemap when Neovim utility APIs or consumers change.
  on-change: "nvim/lua/utils/**"
---

# Neovim Utilities

Small reusable Lua modules that keep filesystem, Git, OS, UI, and color operations out of plugin specifications.

## Files

| File | Description |
| --- | --- |
| `color.lua` | Gradient generation and conversion of Neovim highlight colors to hex |
| `fs.lua` | Path, project-root, and filesystem helpers used by pickers and language tools |
| `general.lua` | Cross-feature editor helpers and shared actions |
| `git.lua` | Repository status and Git-related buffer context helpers |
| `os.lua` | Platform detection and executable/environment selection |
| `compose_service.lua` | Asynchronous Docker Compose lifecycle, readiness polling, progress notifications, transition-safe desired-state reconciliation, and optional per-Neovim session leases |
| `ui.lua` | UI composition and display helpers used by dashboard and pickers |

## Key exports

| Symbol group | File | Description |
| --- | --- | --- |
| `create_gradient()`, `color_num_to_hex()`, `nvim_get_hl_hex()` | `color.lua` | Color calculation and highlight conversion |
| `ComposeService.new()` | `compose_service.lua` | Creates a reusable controller for one container-backed integration, optionally stopping it after the final Neovim session exits |
| Module tables | Other files | Domain-specific helpers imported as `utils.<domain>` |

## Relationships

- **Used by**: `nvim/lua/config/` and feature/language modules under `nvim/lua/plugins/`.
- **Depends on**: Neovim's Lua API, the local repository state for Git helpers, and `nvim/scripts/compose-service-release.sh` for detached final-session container shutdown.

## Entry point

Open the utility matching the data or side effect involved; use reference search before changing an exported function signature.
