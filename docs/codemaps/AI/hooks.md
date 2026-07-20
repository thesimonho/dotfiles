---
agent:
  instruction: Update this codemap when agent policy hooks change.
  on-change: "AI/hooks/**"
---

# AI Hooks

Executable policy evaluators that block unsafe operations or add workflow guidance around agent tool calls. Every policy exports `evaluate(payload)` and returns a host-neutral result from `AI/lib/hooks/policy-result.js`.

## Files

| File group | Description |
| --- | --- |
| `block-*.js` | Prevents build artifacts, debug logging, documentation misuse, force pushes, and plan references in durable files |
| `branch-guard.js` | Blocks code edits on default branches by resolving Git worktree metadata |
| `check-*.js` | Enforces conventional commits, file size limits, and dated plan filenames |
| `*-nudge.js` | Adds contextual reminders for formatting, compaction, branch cleanup, justfiles, LSP, Markdown wrapping, RTK, delegation, and simplification |
| `coupling-surface.js` | Surfaces instructions from Markdown `agent.on-change` frontmatter for touched paths |
| `lint-config-files.js` | Suggests format-specific linters when configuration files are edited |
| `memory-redirect.js` | Redirects direct memory edits to the supported extension mechanism |
| `scan-secrets.js` | Scans Git diffs with gitleaks and built-in secret patterns |
| `surface-file-header.js` | Adds a small target file header to tool context before editing |
| `verify-gate.js` | Requires verification before completion when tooling and code changes are present |
| `verify-track.js` | Tracks code edits and successful verification commands in session state |
| `runners.test.js` | Exercises policies through both Claude and Codex runner adapters |
| `README.md` | Policy runtime contract, configuration examples, and test instructions |

## Key exports

| Symbol | File | Description |
| --- | --- | --- |
| `evaluate(payload)` | Every policy file | Evaluates one normalized hook payload and returns a policy result |

## Relationships

- **Imports from**: `AI/lib/hooks/` for result constructors, session state, frontmatter, and coupling discovery.
- **Used by**: generated Claude and Codex hook configuration under `AI/settings/` and the adapters in `AI/lib/hooks/runners/`.

## Entry point

Start with `README.md` for the lifecycle and contract, then open the policy named by the relevant hook configuration.
