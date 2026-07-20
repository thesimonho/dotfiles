---
agent:
  instruction: Update this codemap when reusable Nix helper interfaces change.
  on-change: "nix/lib/**"
---

# Nix Library

Reusable Nix functions for declarative catalogs, evaluation checks, and normalized host/platform context.

## Files

| File | Description |
| --- | --- |
| `catalog.nix` | Defines catalog option types and resolves enabled bundle or explicitly selected entries |
| `checks.nix` | Builds flake checks that validate host/module configuration invariants |
| `host-context.nix` | Normalizes system, OS, architecture, and host facts used by conditional modules |

## Key exports

| Symbol | File | Description |
| --- | --- | --- |
| `mkCatalogType` / `resolveEnabled` | `catalog.nix` | Declares catalog schemas and computes the selected entries |
| Host context attribute set | `host-context.nix` | Shared predicates and identifiers for platform-aware configuration |

## Relationships

- **Used by**: `nix/modules/apps/catalog.nix`, `nix/modules/ai/catalog.nix`, host definitions, and `nix/flake.nix` checks.

## Entry point

Start with `catalog.nix` for selection behavior or `host-context.nix` for platform conditionals.
