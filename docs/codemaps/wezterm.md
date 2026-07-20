---
agent:
  instruction: Update this codemap when WezTerm Lua modules change.
  on-change: "wezterm/**"
---

# WezTerm

Modular WezTerm configuration covering appearance, key tables, workspace plugins, and dynamic DevPod/Distrobox/SSH container targets.

## Files

| File | Description |
| --- | --- |
| `wezterm.lua` | Main entrypoint; registers startup behavior and returns the built configuration |
| `config.lua` | Creates the base configuration including fonts, colors, tabs, rendering, domains, and keys |
| `keybinds.lua` | Exports basic bindings and modal key tables |
| `plugins.lua` | Installs event handlers and optional workspace/navigation plugin behavior |
| `containers.lua` | Discovers containers and DevPods, maps ports, and constructs SSH domains and launch choices |
| `utils.lua` | Platform detection, string helpers, pane movement, and readiness polling |
| `colors/` | Local color schemes and tabline theme modules |

## Key exports

| Symbol | File | Description |
| --- | --- | --- |
| Configuration table | `config.lua` | Complete base WezTerm configuration returned to the main entrypoint |
| `basic_binds`, `key_tables` | `keybinds.lua` | Default and modal keyboard behavior |
| `create_ssh_domains()`, `create_container_choices()` | `containers.lua` | Dynamic remote-domain and launcher configuration |
| `is_dark()`, `move_or_split()`, `poll_until_ready()` | `utils.lua` | Shared runtime helpers |

## Relationships

- **Entry flow**: `wezterm.lua` loads `config.lua`; configuration and plugins import keybinds, containers, and utilities.
- **External integrations**: WezTerm APIs, SSH, DevPod, Distrobox, and local color scheme files.

## Entry point

Start with `wezterm.lua`, then `config.lua`; use `plugins.lua` for event-driven behavior and `containers.lua` for remote workspace discovery.
