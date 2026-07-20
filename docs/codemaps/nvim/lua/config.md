---
agent:
  instruction: Update this codemap when Neovim bootstrap or core configuration files change.
  on-change: "nvim/lua/config/**"
---

# Neovim Core Configuration

Bootstraps Lazy.nvim and defines editor-wide options, events, keymaps, and shared display constants.

## Files

| File | Description |
| --- | --- |
| `lazy.lua` | Installs and initializes Lazy.nvim with the plugin module tree |
| `options.lua` | Sets leaders, UI behavior, search, folds, sessions, and platform-sensitive options |
| `autocmds.lua` | Defines window placement, root selection, cursor, terminal, and filetype events |
| `keymaps.lua` | Removes conflicting defaults and registers global navigation/action mappings |
| `constants.lua` | Exports icons, borders, progress frames, and TODO keywords used by plugins |
| `headers.lua` | Exports dashboard header artwork |
| `quotes.lua` | Exports dashboard quote content |

## Key exports

| Symbol | File | Description |
| --- | --- | --- |
| Constants table | `constants.lua` | Shared visual tokens consumed throughout plugin specs |
| Header and quote tables | `headers.lua`, `quotes.lua` | Dashboard content collections |

## Relationships

- **Loaded by**: `nvim/init.lua` and LazyVim conventions.
- **Imports from**: `nvim/lua/utils/`; `constants.lua` is imported broadly by `nvim/lua/plugins/`.

## Entry point

Start with `lazy.lua` for startup composition or the file matching the core behavior being changed.
