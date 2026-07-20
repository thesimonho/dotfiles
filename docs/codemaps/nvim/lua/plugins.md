---
agent:
  instruction: Update this codemap when Neovim plugin files are added, removed, or change responsibility.
  on-change:
    - "nvim/lua/plugins/*.lua"
    - "nvim/lua/plugins/colourschemes/**"
---

# Neovim Plugins

Lazy.nvim plugin specifications organized primarily by user-facing feature. Files return one or more plugin specs and keep configuration close to the integration they customize.

## Files

| File group | Description |
| --- | --- |
| `AI.lua` | Embedded agent terminals, selection forwarding, and AI-related keymaps |
| `lsp.lua`, `format-lint.lua`, `treesitter.lua`, `neotest.lua`, `debug.lua` | Language intelligence, formatting, syntax, testing, and debugging foundations |
| `blink.lua`, `nvim-autopairs.lua`, `dial.lua`, `yanky.lua` | Completion and editing behavior |
| `explorer.lua`, `buffers.lua`, `terminal.lua`, `snacks.lua` | Navigation, buffers, terminals, pickers, and utility UI |
| `dashboard.lua`, `lualine.lua`, `status.lua`, `noice.lua`, `scrollbar.lua` | Dashboard, status, notifications, and visual feedback |
| `colors.lua`, `colourschemes/`, `indent.lua`, `rainbow-delimiters.lua` | Color and structural display customization |
| `git.lua`, `todo.lua` | Source-control and annotation integrations |
| `flash.lua`, `nvim-spider.lua`, `which-key.lua`, `hardtime.lua` | Navigation and key-discovery behavior |
| `languages/` | Per-language tooling; see [language plugins](./plugins/languages.md) |
| `init.lua` | Miscellaneous shared plugin specifications |

## Relationships

- **Loaded by**: Lazy.nvim setup in `nvim/lua/config/lazy.lua`.
- **Imports from**: `nvim/lua/config/constants.lua` and `nvim/lua/utils/`.
- **Extends**: LazyVim plugin defaults through mergeable specification tables.

## Entry point

Open the feature-named file first. Use `languages/` when behavior is specific to a filetype or toolchain.
