---
agent:
  instruction: Keep this index synchronized with the codemap files and mapped project directories.
  on-change:
    - "AI/**"
    - "nix/**"
    - "nvim/**"
    - "wezterm/**"
---

# Codemaps — dotfiles

This repository manages a cross-platform development environment with Nix, Neovim, terminal configuration, and shared AI-agent tooling. Configuration is organized by application, while Nix composes host-specific installations and the AI modules generate portable agent policy and runtime settings.

## Architectural patterns

- Nix modules compose shared defaults with host-specific context and declarative application catalogs.
- AI instructions are assembled from reusable fragments and enforced by host-neutral policy evaluators with thin runtime adapters.
- Neovim and WezTerm use small Lua modules that return plugin specifications, configuration tables, or shared helpers.

## Directory Map

| Directory | Description | Codemap |
| --- | --- | --- |
| `AI/hooks/` | Agent workflow policies executed around tool use | [hooks](./AI/hooks.md) |
| `AI/instructions/fragments/` | Reusable source sections for generated agent instructions | [instruction fragments](./AI/instructions/fragments.md) |
| `AI/evals/lib/` | Evaluation harness execution, provenance, MLflow, and scoring modules | [evaluation library](./AI/evals/lib.md) |
| `AI/lib/hooks/` | Shared policy parsing, state, result, and dispatch infrastructure | [hook library](./AI/lib/hooks.md) |
| `AI/lib/hooks/runners/` | Claude and Codex payload adapters | [hook runners](./AI/lib/hooks/runners.md) |
| `nix/hosts/` | Per-machine Home Manager entry points | [hosts](./nix/hosts.md) |
| `nix/lib/` | Catalog, validation, and host-context helpers | [Nix library](./nix/lib.md) |
| `nix/modules/` | Shared Home Manager feature modules | [modules](./nix/modules.md) |
| `nix/modules/ai/` | AI clients, agents, skills, instructions, and model services | [AI modules](./nix/modules/ai.md) |
| `nix/scripts/` | Installation diagnostics and secret/key setup utilities | [scripts](./nix/scripts.md) |
| `nvim/lua/config/` | Neovim bootstrap, options, events, and keymaps | [Neovim config](./nvim/lua/config.md) |
| `nvim/lua/plugins/` | Lazy.nvim plugin specifications and integrations | [Neovim plugins](./nvim/lua/plugins.md) |
| `nvim/lua/plugins/languages/` | Language-specific LSP, formatter, linter, and debugger setup | [language plugins](./nvim/lua/plugins/languages.md) |
| `nvim/lua/utils/` | Shared Neovim filesystem, UI, Git, OS, and color helpers | [Neovim utilities](./nvim/lua/utils.md) |
| `wezterm/` | WezTerm configuration, key tables, plugins, and container integration | [WezTerm](./wezterm.md) |

## How to use these codemaps

Start here and select the module that owns the behavior being changed. Each map identifies the relevant files, important exported symbols, dependencies, consumers, and the best entry point for further inspection.
