# Agent reliability hooks

This directory is a deterministic enforcement layer for agent instructions. It exists because standing instructions (the fragments in `AI/instructions/fragments/`) decay across a long context: they are injected once, weighted low, and lose out to the immediate task tens of thousands of tokens later. Prose alone cannot fix that — so the rules that are _event-shaped_ live here as hooks that fire at the exact moment they are relevant, for free and deterministically.

A rule states itself in exactly one place. When a hook enforces the whole rule, the prose fragment drops the line and the hook's docstring carries it — duplicating it in both only gives the two copies a chance to drift apart. Prose keeps the rules a hook cannot express, and the detail a one-line nudge has no room for (what `rtk` is and why, the LSP call surface, the plan-document structure). Claude and Codex keep native wiring in `AI/settings/claude/settings.json` and `AI/settings/codex/hooks.json`, then enter the shared system through their respective runners under `AI/lib/hooks/runners/`. The runners load the same policy modules from this directory in-process, so each rule has one implementation and each CLI retains its documented configuration surface.

## How a hook works

A hook policy exports `evaluate(payload)` and returns one of three agent-neutral results:

- **Block** — `block(reason, details)` stops a pending tool use. The host runner writes the native blocking response.
- **Nudge** — `addContext(text)` writes model-visible additional context without blocking.
- **Silent** — `doNothing()` produces no output and lets the CLI continue normally.

Shared helpers live in `../lib/hooks/`: `policy-result.js` defines policy results, `host-response.js` encodes them for each CLI, `run-policy.js` loads policies, `session-state.js` stores per-session scratch state keyed by `session_id` (overridable via `AGENT_HOOK_STATE_DIR`), and `nudge-throttle.js` builds on that state to stop a nudge repeating within a time window (an hour by default). Host configuration invokes a runner with the policy name, for example `node ~/dotfiles/AI/lib/hooks/runners/codex.js block-force-push`.

The native config owns discovery, event registration, matchers, trust, timeouts, and command invocation. The shared layer owns only policy evaluation, shared state, and response encoding. Add host-specific behavior to the runner/response boundary instead of teaching policy modules about a CLI.

## The hooks

| Hook                        | Event       | Effect | Enforces                                                               |
| --------------------------- | ----------- | ------ | ---------------------------------------------------------------------- |
| `block-doc-files`           | PreToolUse  | block  | keep arbitrary root Markdown and all `.txt` files out of the repository |
| `block-build-dirs`          | PreToolUse  | block  | don't edit build output                                                |
| `block-plan-references`     | PreToolUse  | block  | no plan-file references in code/docs                                   |
| `block-force-push`          | PreToolUse  | block  | never force-push                                                       |
| `check-conventional-commit` | PreToolUse  | block  | conventional subject, max 70 chars                                     |
| `verify-gate`               | PreToolUse  | nudge  | verify reminder on merge/PR when code changed                          |
| `branch-guard`              | PreToolUse  | block  | no code edits on the default branch                                    |
| `block-debug-logging`       | PreToolUse  | block  | no leftover debug logging in a commit                                  |
| `scan-secrets`              | PreToolUse  | block  | gitleaks scan of the commit diff (regex fallback)                      |
| `check-plan-filename`       | PreToolUse  | block  | plan files start with a `YYYYMMDD` stamp                               |
| `memory-redirect`           | PreToolUse  | nudge  | prefer a hook over a memory for enforceable rules                      |
| `commit-format-nudge`       | PreToolUse  | nudge  | format changed files before committing (avoid churn)                   |
| `simplify-nudge`            | PreToolUse  | block  | current review decision before opening a PR; reasoned skips allowed    |
| `rtk-nudge`                 | PreToolUse  | nudge  | prefix rtk-compressible commands (tools.md, hourly)                    |
| `lsp-nudge`                 | PreToolUse  | nudge  | prefer LSP over text search for symbols (tools.md, hourly)             |
| `justfile-nudge`            | PreToolUse  | nudge  | check the justfile before custom build/test (hourly)                   |
| `surface-file-header`       | PostToolUse | nudge  | re-surface a file's own `agent.instruction`                            |
| `coupling-surface`          | PostToolUse | nudge  | reminder for a doc's `agent.on-change` area, per coupling (hourly)     |
| `verify-track`              | PostToolUse | state  | record code edits + verify runs for verify-gate                        |
| `lint-config-files`         | PostToolUse | nudge  | run the matching linter after a config edit                            |
| `check-file-size`           | PostToolUse | nudge  | flag a source file over 800 lines                                      |
| `no-hard-linebreaks`        | PostToolUse | nudge  | flag hard-wrapped markdown                                             |
| `delete-branch-nudge`       | PostToolUse | nudge  | delete the local branch after a merge                                  |

Native wiring includes only hooks for which a CLI exposes the corresponding event and matcher. Codex runs the shared edit and Bash policies through its `apply_patch` aliases and `Bash` matcher. Both hosts now wire the same policy set: `lsp-nudge` reads the shell command rather than a Grep tool call, which is the only search path Codex has and the one Claude uses in practice.

## Pre-PR review decision

Before creating a pull request, assess whether the branch needs `/simplify`. Run it for substantial code changes; skip it for small, bounded, mechanical, or docs-only changes when a review would add little value. Repository instructions can also require a skip. The hook enforces a current decision, not mandatory review.

After a review and any resulting fixes are committed, record the decision from the source checkout:

```bash
rtk node ~/dotfiles/AI/lib/hooks/review-checkpoint-cli.js reviewed
```

For a skip, give a brief reason:

```bash
rtk node ~/dotfiles/AI/lib/hooks/review-checkpoint-cli.js skip --reason "Small bounded fix with focused verification"
```

The helper stores the repository, branch, commit, working-state fingerprint, outcome, and reason in the existing local hook state directory. Tracked and untracked changes invalidate the decision; ignored files do not. Decisions are local and shared across sessions for that checkout and branch, with the existing stale-state pruning. They attest the agent's judgment; they do not prove that a review was executed.

The existing `PreToolUse` wiring invokes `simplify-nudge`, which blocks PR creation when the decision is absent or stale. This is an internal workflow checkpoint, not a request for user approval. Record the decision after other work finishes, then retry PR creation separately. A push may precede creation in the same command; commands that can change the reviewed state must finish first. Use the checked-out source branch and repository. The matcher recognizes direct `gh`, `glab`, and `tea` creation commands, including common global options and `rtk` wrappers, without matching quoted argument examples. It is not a complete shell parser; aliases and indirect scripts remain outside its coverage.

## The `agent:` frontmatter convention

A doc can carry directives for the agent in optional `agent:` frontmatter (parsed by `../lib/hooks/frontmatter.js`). Both fields are optional; a doc without it behaves normally. This is general-purpose — a roadmap tracking `src/**`, or a vision doc tracking `docs/plans/**` purely to get re-read, are equally valid pairings. The example below is the common case, a directory's own README:

```yaml
---
agent:
  instruction: Update this README when the module's structure or conventions change.
  on-change:
    - "src/features/**"
---
```

- `instruction` — `surface-file-header` re-emits it whenever the agent reads or edits the file, so the file's contract lands at the decision point instead of decaying up-context.
- `on-change` (a glob or list of globs) — `coupling-surface` fires when a file matching the glob is read/edited/written, surfacing the coupling's instruction before the area gets worked blind. Throttled to once per coupling per hour, not on every touch. Dormant until a doc opts in.

There used to be a companion commit-time "you forgot to update this doc" gate. It was removed: it couldn't tell a doc-worthy change from an irrelevant one, so every fix for its false positives added state without fixing the underlying unreliability. Surfacing the doc early is the reliable half — it's always a true statement, and an agent that's seen the doc is already positioned to update it as part of the work.

## Known papercut

Content-scanning hooks (`block-plan-references`, and `scan-secrets`' regex fallback) can trip on documentation that _describes_ the patterns they match; write such docs with abstract descriptions or via a non-matched tool. A few PreToolUse nudges spawn a Node process per Bash/edit call; trim the broad matchers if latency becomes noticeable.
