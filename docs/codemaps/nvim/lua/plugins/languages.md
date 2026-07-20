---
agent:
  instruction: Update this codemap when language-specific Neovim tooling changes.
  on-change: "nvim/lua/plugins/languages/**"
---

# Neovim Language Plugins

Per-language Lazy.nvim specifications for parsers, LSP servers, formatters, linters, debuggers, and filetype-specific keymaps.

## Files

| File | Description |
| --- | --- |
| `csv.lua` | CSV viewing and editing support |
| `go.lua` | Go LSP, testing, formatting, and platform-sensitive tooling |
| `htmlcss.lua` | HTML and CSS language services |
| `lua.lua` | Lua and Neovim-specific language support |
| `markdown.lua` | Markdown rendering, lint configuration, and prose tooling |
| `nix.lua` | Nix language server and formatting support |
| `python.lua` | Python LSP, Ruff lint/format integration, and debugging/testing support |
| `terraform.lua` | Terraform/HCL filetypes and tooling |
| `typescript.lua` | TypeScript language tooling |
| `web.lua` | Browser-oriented JavaScript debugging and web project helpers |
| `.markdownlint.yaml` | Rules consumed by the Markdown lint integration |

## Relationships

- **Loaded by**: Lazy.nvim through `nvim/lua/config/lazy.lua`.
- **Imports from**: `nvim/lua/utils/os.lua` for platform-specific executables and `utils/fs.lua` for project discovery.
- **Builds on**: shared LSP, formatting, debugging, and testing specs in the parent plugin directory.

## Entry point

Start with the file named for the target language; inspect shared plugin foundations only when behavior spans languages.
