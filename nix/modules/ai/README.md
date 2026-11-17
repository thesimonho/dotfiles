---
agent:
  instruction: Keep AI package and client configuration guidance current.
  on-change: ["nix/modules/ai/**", "nix/flake.nix"]
---

## Agent client configuration

`modules/ai/clients.nix` merges tracked settings into writable client files during activation. Tracked values win; unrelated local state remains. State files under the XDG state directory record ownership so removing a tracked setting removes its previously managed value. Avoid concurrent client writes while applying changes.

- **Codex:** `AI/settings/codex/config.toml` is recursively merged into `~/.codex/config.toml`, shared by CLI and Desktop. Project trust and other local-only state are preserved. Run `mise run codex-config-apply` from `nix/` to apply without a full switch.
- **Claude:** `AI/settings/claude/mcp.json` owns managed MCP entries in each client's `${CLAUDE_CONFIG_DIR}/.claude.json`. Run `<client>-mcp-apply` to reconcile them. `settings.json` is linked separately.

Client UI changes remain local unless deliberately added to the tracked baseline.

## Secret-enabled desktop launchers

Catalog entries can declare `secrets.provides` and `secrets.requires` and map installed desktop IDs to checked-in `launchers/*.desktop` paths through `contributions.desktopEntries`. The shared catalog adapter wraps main and action commands through the configured `with-secrets` helper on Linux. The adapter preserves file contents except for wrapping each `Exec=` line, including desktop actions. Home Manager installs overrides in the user XDG applications directory with the same IDs, preserving normal menu and pin names. Preserve file/URL field codes, MIME types, startup class, and relevant actions when editing an entry. CLI entries declare an absolute `command`; the shared adapter generates normal-name wrappers. See `AI/README.md` for the provider/group contract. macOS native launch wrapping is not implemented.
