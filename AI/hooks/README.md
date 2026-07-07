# Agent reliability hooks

This directory is a deterministic enforcement layer for agent instructions. It exists because standing instructions (the fragments in `AI/instructions/fragments/`) decay across a long context: they are injected once, weighted low, and lose out to the immediate task tens of thousands of tokens later. Prose alone cannot fix that — so the rules that are _event-shaped_ are mirrored here as hooks that fire at the exact moment they are relevant, for free and deterministically.

The prose fragments remain the shared source of truth (they also feed Codex's `AGENTS.md`). These hooks are additive Claude-side enforcement, not a replacement. Each hook is agent-neutral policy — it parses both Claude and Codex tool shapes — while the wiring is per-agent (`AI/settings/claude/settings.json` for Claude; Codex wiring stays disabled until it stops writing hook trust-state into committed config).

## How a hook works

A hook is a small Node script that reads the tool-call payload as JSON on stdin and either stays silent, soft-nudges, or blocks:

- **Block** — `require("../lib/hooks/hook-response").block(reason, details)` prints to stderr and exits 2. Both Claude and Codex treat exit 2 as "stop this tool use". Used for real policy violations.
- **Nudge** — `addContext(event, text)` writes model-visible context without blocking. Used for reminders where a hard stop would be wrong.
- **Silent** — nothing to say, exit 0.

Shared helpers live in `../lib/hooks/`: `hook-response.js` (block/addContext) and `session-state.js` (per-session scratch state keyed by `session_id`, overridable via `AGENT_HOOK_STATE_DIR`).

## The hooks

| Hook                        | Event       | Effect | Enforces                                               |
| --------------------------- | ----------- | ------ | ------------------------------------------------------ |
| `block-doc-files`           | PreToolUse  | block  | don't create stray `.md`/`.txt`                        |
| `block-build-dirs`          | PreToolUse  | block  | don't edit build output                                |
| `block-plan-references`     | PreToolUse  | block  | no plan-file references in code/docs (planning.md)     |
| `block-force-push`          | PreToolUse  | block  | never force-push (git.md)                              |
| `check-conventional-commit` | PreToolUse  | block  | conventional subject, max 70 chars (git.md)            |
| `verify-gate`               | PreToolUse  | nudge  | verify reminder on `git commit` when code changed      |
| `branch-guard`              | PreToolUse  | block  | no code edits on the default branch (git.md)           |
| `block-debug-logging`       | PreToolUse  | block  | no leftover debug logging in a commit (workflow.md)    |
| `scan-secrets`              | PreToolUse  | block  | gitleaks scan of the commit diff (regex fallback)      |
| `check-plan-filename`       | PreToolUse  | block  | plan files start with a `YYYYMMDD` stamp (planning.md) |
| `memory-redirect`           | PreToolUse  | nudge  | prefer a hook over a memory for enforceable rules      |
| `commit-format-nudge`       | PreToolUse  | nudge  | format changed files before committing (avoid churn)   |
| `simplify-nudge`            | PreToolUse  | nudge  | /simplify reminder on each commit (agent judges)       |
| `rtk-nudge`                 | PreToolUse  | nudge  | prefix rtk-compressible commands (tools.md)            |
| `lsp-nudge`                 | PreToolUse  | nudge  | prefer LSP over Grep/Glob for symbols (tools.md)       |
| `justfile-nudge`            | PreToolUse  | nudge  | check the justfile before custom build/test (tools.md) |
| `surface-file-header`       | PostToolUse | nudge  | re-surface a file's own `agent.instruction`            |
| `verify-track`              | PostToolUse | state  | record edits + verify runs for verify-gate/coupling-gate |
| `lint-config-files`         | PostToolUse | nudge  | run the matching linter after a config edit (tools.md) |
| `check-file-size`           | PostToolUse | nudge  | flag a source file over 800 lines (coding-style.md)    |
| `no-hard-linebreaks`        | PostToolUse | nudge  | flag hard-wrapped markdown (documentation.md)          |
| `delete-branch-nudge`       | PostToolUse | nudge  | delete the local branch after a merge (git.md)         |
| `compaction-nudge`          | PostToolUse | nudge  | `/compact` at a PR/merge/push boundary                 |
| `task-delegation-nudge`     | PostToolUse | nudge  | pick model/agent at TaskCreate (debounced 15m)         |
| `coupling-gate`             | Stop        | nudge  | declared `agent.on-change` doc couplings               |

## The `agent:` frontmatter convention

A doc can carry directives for the agent in optional `agent:` frontmatter (parsed by `../lib/hooks/frontmatter.js`). Both fields are optional; a doc without it behaves normally. This is general-purpose, not codemap-specific — a roadmap tracking `src/**`, or a vision doc tracking `docs/plans/**` purely to get re-read, are equally valid pairings. The example below is just the codemap case:

```yaml
---
agent:
  instruction: Update this codemap when the mapped directory changes.
  on-change:
    - "src/features/**"
---
```

- `instruction` — `surface-file-header` re-emits it whenever the agent reads or edits the file, so the file's contract lands at the decision point instead of decaying up-context.
- `on-change` (a glob or list of globs) — `coupling-gate` scans root-level and `docs/` markdown at turn-end; if a matching file changed this session but the declaring doc did not, it surfaces an advisory reminder (not a block). Dormant until a doc opts in. The reminder can mean "update this doc" or just "re-read it" — whichever fits.

## Known papercut

Content-scanning hooks (`block-plan-references`, and `scan-secrets`' regex fallback) can trip on documentation that _describes_ the patterns they match; write such docs with abstract descriptions or via a non-matched tool. A few PreToolUse nudges spawn a Node process per Bash/edit call; trim the broad matchers if latency becomes noticeable.
