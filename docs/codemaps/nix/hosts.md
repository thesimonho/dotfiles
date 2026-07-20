---
agent:
  instruction: Update this codemap when hosts or their module composition changes.
  on-change: "nix/hosts/**"
---

# Nix Hosts

Per-machine Home Manager entry points. Each host supplies platform context and selects shared modules or host-specific overrides.

## Files

| File | Description |
| --- | --- |
| `desktop.nix` | Linux desktop configuration and machine-specific application choices |
| `work-macbook.nix` | macOS work-machine configuration |
| `work-wsl.nix` | WSL work environment and Windows interoperability settings |

## Relationships

- **Imports from**: `nix/modules/` for shared features and `nix/lib/host-context.nix` for normalized platform facts.
- **Used by**: Home Manager configurations declared in `nix/flake.nix`.

## Entry point

Start with the file named for the target machine, then follow its imported shared modules.
