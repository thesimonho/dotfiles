---
agent:
  instruction: Update this codemap when shared hook runtime modules change.
  on-change: "AI/lib/hooks/**"
---

# AI Hook Library

Host-neutral infrastructure shared by policy evaluators and runtime adapters. It normalizes policy results, parses agent frontmatter, discovers path couplings, tracks per-session state, and dispatches policies.

## Files

| File | Description |
| --- | --- |
| `policy-result.js` | Constructors for no-op, block, and add-context decisions |
| `frontmatter.js` | Minimal parser for `agent.instruction` and `agent.on-change` Markdown frontmatter |
| `coupling.js` | Scans Markdown files, compiles glob patterns, and finds valid path couplings |
| `session-state.js` | Persists debounces and verification state across hook invocations |
| `normalize-payload.js` | Converts host-specific request shapes into the common policy payload |
| `host-response.js` | Renders neutral policy decisions into host-specific hook responses |
| `run-policy.js` | Loads a named policy, evaluates it, and writes the adapted response |
| `run-codex-mcp-helper-reaper.js` | Cleans up orphaned Codex MCP helper processes |
| `runners/` | Claude and Codex command-line adapters; see [runners](./hooks/runners.md) |

## Key exports

| Symbol | File | Description |
| --- | --- | --- |
| `block()` / `addContext()` / `doNothing()` | `policy-result.js` | Creates the common policy result variants |
| `parseAgentFrontmatter()` | `frontmatter.js` | Extracts supported agent directives without a YAML dependency |
| `discoverCouplings()` / `globToRegExp()` | `coupling.js` | Finds docs whose directives apply to a touched path |
| `runPolicy()` | `run-policy.js` | Central policy execution and response pipeline |

## Relationships

- **Used by**: all files in `AI/hooks/` and both runner adapters.
- **Reads**: repository Markdown frontmatter and tool payloads; session state is stored outside tracked source.

## Entry point

Start with `run-policy.js` for the execution flow and `policy-result.js` for the contract policies must return.
