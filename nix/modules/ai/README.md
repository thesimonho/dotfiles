# AI

## Agent client configuration

`modules/ai/clients.nix` merges tracked settings into writable client files during activation. Tracked values win; unrelated local state remains. State files under the XDG state directory record ownership so removing a tracked setting removes its previously managed value. Avoid concurrent client writes while applying changes.

- **Codex:** `AI/settings/codex/config.toml` is recursively merged into `~/.codex/config.toml`, shared by CLI and Desktop. Project trust and other local-only state are preserved. Run `mise run codex-config-apply` from `nix/` to apply without a full switch.
- **Claude:** `AI/settings/claude/mcp.json` owns managed MCP entries in each client's `${CLAUDE_CONFIG_DIR}/.claude.json`. Run `<client>-mcp-apply` to reconcile them. `settings.json` is linked separately.

Client UI changes remain local unless deliberately added to the tracked baseline.
