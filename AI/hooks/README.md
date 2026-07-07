# Agent reliability hooks

This directory is a deterministic enforcement layer for agent instructions. It exists because standing instructions (the fragments in `AI/instructions/fragments/`) decay across a long context: they are injected once, weighted low, and lose out to the immediate task tens of thousands of tokens later. Prose alone cannot fix that — so the rules that are *event-shaped* are mirrored here as hooks that fire at the exact moment they are relevant, for free and deterministically.

The prose fragments remain the shared source of truth (they also feed Codex's `AGENTS.md`). These hooks are additive Claude-side enforcement, not a replacement. Each hook is agent-neutral policy — it parses both Claude and Codex tool shapes — while the wiring is per-agent (`AI/settings/claude/settings.json` for Claude; Codex wiring stays disabled until it stops writing hook trust-state into committed config).

## How a hook works

A hook is a small Node script that reads the tool-call payload as JSON on stdin and either stays silent, soft-nudges, or blocks:

- **Block** — `require("../lib/hooks/hook-response").block(reason, details)` prints to stderr and exits 2. Both Claude and Codex treat exit 2 as "stop this tool use". Used for real policy violations.
- **Nudge** — `addContext(event, text)` writes model-visible context without blocking. Used for reminders where a hard stop would be wrong.
- **Silent** — nothing to say, exit 0.

Shared helpers live in `../lib/hooks/`: `hook-response.js` (block/addContext) and `session-state.js` (per-session scratch state keyed by `session_id`, overridable via `AGENT_HOOK_STATE_DIR`).

## The hooks

| Hook | Event | Effect | Enforces |
|------|-------|--------|----------|
| `block-doc-files` | PreToolUse | block | don't create stray `.md`/`.txt` |
| `block-build-dirs` | PreToolUse | block | don't edit build output |
| `block-plan-references` | PreToolUse | block | no plan-file references in code/docs (planning.md) |
| `block-force-push` | PreToolUse | block | never force-push (git.md) |
| `check-conventional-commit` | PreToolUse | block | conventional subject, max 70 chars (git.md) |
| `branch-guard` | PreToolUse | block | no code edits on the default branch (git.md) |
| `block-debug-logging` | PreToolUse | block | no leftover debug logging in a commit (workflow.md) |
| `scan-secrets` | PreToolUse | block | no hardcoded credentials (security.md) |
| `check-plan-filename` | PreToolUse | block | plan files start with a `YYYYMMDD` stamp (planning.md) |
| `memory-redirect` | PreToolUse | nudge | prefer a hook over a memory for enforceable rules |
| `rtk-nudge` | PreToolUse | nudge | prefix rtk-compressible commands (tools.md) |
| `lsp-nudge` | PreToolUse | nudge | prefer LSP over Grep/Glob for symbols (tools.md) |
| `justfile-nudge` | PreToolUse | nudge | check the justfile before custom build/test (tools.md) |
| `surface-file-header` | PostToolUse | nudge | re-surface a file's own `<INSTRUCTION>` block |
| `verify-track` | PostToolUse | state | record edits + verify runs for the gates |
| `lint-config-files` | PostToolUse | nudge | run the matching linter after a config edit (tools.md) |
| `check-file-size` | PostToolUse | nudge | flag a source file over 800 lines (coding-style.md) |
| `no-hard-linebreaks` | PostToolUse | nudge | flag hard-wrapped markdown (documentation.md) |
| `delete-branch-nudge` | PostToolUse | nudge | delete the local branch after a merge (git.md) |
| `compaction-nudge` | PostToolUse | nudge | `/compact` at a PR/merge/push boundary |
| `verify-gate` | Stop | observe | verify-at-finish (observe-only for now) |
| `coupling-gate` | Stop | block | declared `when-changed` file couplings |

## The `<INSTRUCTION>` convention

Any file can carry directives for the agent inside an `<INSTRUCTION>...</INSTRUCTION>` block. `surface-file-header` re-emits that block whenever the agent reads or edits the file, so the file's contract lands at the decision point instead of decaying up-context. It works in any repo with no per-project config.

An instruction can also declare a coupling: `<INSTRUCTION when-changed="src/**">Clear completed items from the list below.</INSTRUCTION>`. If files matching the glob change in a session but the declaring file does not, `coupling-gate` blocks the turn once and surfaces the instruction — the deterministic answer to "shipped the code, never updated the roadmap". It is dormant until such a declaration exists, so it never fires on a project that has not opted in.

## Testing

Every hook has a `<name>.test.js` beside it that pipes sample payloads through the hook and asserts exit code / output. They use only Node built-ins — no framework. Run them all:

```bash
for t in AI/hooks/*.test.js; do node "$t" || echo "FAIL $t"; done
```

## Phased rollout and arming

- **`verify-gate` is observe-only.** It logs turns that would have been blocked (unverified code changes) to `verify-observe.log` under the state dir, instead of blocking, so the false-positive rate (e.g. stopping to ask a clarifying question) can be measured first. Arm it by having it exit 2 on a would-block once the log looks clean.
- **`post-edit-reminder` is intentionally still wired.** It is the always-fires generic reminder the plan wants retired; retire it only once `verify-gate` is armed, so the verify nudge is never fully absent.
- **Codex hooks stay disabled.** A one-time cloud routine in early September re-checks whether Codex has separated hook trust-state from committed config; re-enable the Codex wiring then.

## Reviewed but intentionally not auto-applied

- **Model tiering.** The default model is left unset (inherits the session choice — deliberately the user's), the planning agent is already pinned to opus, and `outputStyle: explanatory` matches the ELI5 preference. Subagent model selection is governed by `subagents.md`. Nothing here was safe to change without overriding deliberate config.
- **LLM arbitrator (residual judgment).** The plan's fallback for un-gateable, judgment-shaped residue. Deferred: it needs to shell out to a model and be verified live, which is a larger, separately-testable piece than the deterministic hooks.
- **Path-scoped rules for Claude.** Scoping a fragment to `src/**` etc. via rule frontmatter would leak that frontmatter into Codex's concatenated `AGENTS.md`. It needs the generator to strip frontmatter per output first.
- **Eval scorer.** Passive transcript grading (the §09 idea) belongs in the future MLflow/LangSmith-shaped eval suite, not here.

## Known papercut

Several hooks scan written content (`scan-secrets`, `block-plan-references`), so documentation that *describes* those patterns can trip them; write such docs with abstract descriptions or via a non-matched tool. A few PreToolUse nudges spawn a Node process per Bash/edit call; trim the broad matchers if latency becomes noticeable.
