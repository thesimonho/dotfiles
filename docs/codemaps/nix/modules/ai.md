---
agent:
  instruction: Update this codemap when AI Home Manager modules or catalog responsibilities change.
  on-change: "nix/modules/ai/**"
---

# Nix AI Modules

Home Manager modules that install AI clients and generate their shared instructions, agent definitions, skills, and model-service configuration.

## Files

| File | Description |
| --- | --- |
| `default.nix` | Composes the AI submodules and exposes their shared options |
| `catalog.nix` | Declares available AI applications and bundles |
| `clients.nix` | Installs and configures supported agent clients |
| `instructions.nix` | Assembles reusable Markdown fragments into client-specific instruction files |
| `agents.nix` | Generates portable subagent definitions from common sources |
| `skills.nix` | Resolves and links skill sources into each client runtime |
| `llama.nix` | Configures local llama-swap model serving |
| `scripts/merge-codex-config.py` | Merges generated Codex configuration without discarding unmanaged user keys |

## Relationships

- **Imports from**: `nix/lib/catalog.nix` and source material under `AI/`.
- **Used by**: host configurations through `default.nix`.
- **Produces**: runtime configuration in client-specific locations for Claude, Codex, Pi, and related tools.

## Entry point

Start with `default.nix` for composition, then `clients.nix` for installation or the content-specific generator for instructions, agents, or skills.
