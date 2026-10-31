---
agent:
  instruction: Preserve host task ordering and dry-run boundaries when editing these tasks.
  on-change: ["nix/mise-tasks/**", "nix/mise.toml"]
---

# Host tasks

Executable mise tasks hold the longer host-management shell workflows. Short commands live in `nix/mise.toml`. Run `mise tasks` from `nix/` to list them. Tasks always run from `nix/`, including when invoked from a child directory.

`switch` previews Home Manager and native packages without activation when `--dry-run` is present. Normal switching generates documentation, activates Home Manager, applies native packages, then cleans generations. Keep that sequence. `clean` retains the macOS Tahoe/MDM garbage-collection workaround and Linux's `--no-gcroots` behavior.
