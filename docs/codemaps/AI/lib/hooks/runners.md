---
agent:
  instruction: Update this codemap when Claude or Codex hook adapter behavior changes.
  on-change: "AI/lib/hooks/runners/**"
---

# AI Hook Runners

Thin runtime adapters that map Claude Code and Codex hook input/output conventions onto the shared policy pipeline.

## Files

| File | Description |
| --- | --- |
| `claude.js` | Reads Claude hook JSON, normalizes it, runs the selected policy, and emits Claude-compatible output |
| `codex.js` | Serves Codex hook calls through the MCP protocol and maps them to shared policies |

## Key exports

| Symbol | File | Description |
| --- | --- | --- |
| Runner entrypoint | `claude.js` | One-shot stdin/stdout adapter for Claude hooks |
| MCP server entrypoint | `codex.js` | Long-lived adapter exposing policies as Codex MCP tools |

## Relationships

- **Imports from**: `AI/lib/hooks/run-policy.js`, payload normalization, and host response helpers.
- **Used by**: hook configuration generated under `AI/settings/claude/` and `AI/settings/codex/`.

## Entry point

Open the adapter for the affected host; policy behavior itself belongs in `AI/hooks/`.
