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
| `fs.lua` | Path normalization, config paths, project roots, and filesystem helpers used across features |
| `general.lua` | Cross-feature editor helpers, shared actions, and small string operations |
| `git.lua` | Repository status and Git-related buffer context helpers |
| `os.lua` | Platform detection, process identity, and executable/environment selection |
| `service_lifecycle.lua` | Backend-independent lifecycle state, readiness polling, progress notifications, optimistic reconciliation, and cross-platform Neovim session leases |
| `compose_service.lua` | Docker Compose backend implementing start, stop, health status, and detached shutdown commands |
| `cursortab.lua` | Pinned compatibility loader that keeps CursorTab preview floats inside their source split |
| `process_service.lua` | Owned foreground-process backend with detached launch, PID identity checks, health commands, logs, and graceful shutdown |
| `ui.lua` | UI composition and display helpers used by dashboard and pickers |

## Key exports

| Symbol group | File | Description |
| --- | --- | --- |
| `create_gradient()`, `color_num_to_hex()`, `nvim_get_hl_hex()` | `color.lua` | Color calculation and highlight conversion |
| `install_ui_patch()` | `cursortab.lua` | Loads CursorTab's UI with the pinned overlay-width compatibility fix before plugin setup |
| `absolute_path()`, `config_path()` | `fs.lua` | Normalizes user paths and resolves files shipped with the Neovim configuration |
| `trim_string()` | `general.lua` | Normalizes leading and trailing command-output whitespace |
| `get_process_start_time()` | `os.lua` | Reads stable process identity data used to guard against PID reuse |
| `ServiceLifecycle.new()` | `service_lifecycle.lua` | Wraps a lifecycle backend in the shared asynchronous controller |
| `new()` | `compose_service.lua`, `process_service.lua` | Creates a Compose-backed or owned-process-backed service with the same consumer API |
| Module tables | Other files | Domain-specific helpers imported as `utils.<domain>` |

## Relationships

- **Used by**: `nvim/lua/config/` and feature/language modules under `nvim/lua/plugins/`.
- **Depends on**: Neovim's Lua API, the local repository state for Git helpers, and the minimal scripts under `nvim/scripts/` that must survive Neovim exit for cross-process coordination and detached shutdown.

## Entry point

Open the utility matching the data or side effect involved; use reference search before changing an exported function signature.
