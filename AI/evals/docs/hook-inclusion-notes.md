---
status: snapshot, true as of 2026-08-07
---

# Hook inclusion verification notes (2026-08-07)

Snapshot of the evidence gathered when evaluated profiles became hook-inclusive. The living behaviour description is in the README and `assessment-design.md`; this records what was verified and which stored runs predate the change.

## Why profiles became hook-inclusive

Instruction-only profiles measured prose that never runs alone: live sessions pair fragments with PreToolUse/PostToolUse hooks that nudge or enforce the same behaviours. Hook-free eval scores therefore flagged problems that do not exist in day-to-day use — the opus/low instruction-only run recorded near-zero rtk usage in seven of nine cases while the rtk-nudge hook keeps live compliance high.

## Verification performed

- Claude: hooks are not rendered as events in headless stream-json output, so context-injection hooks look invisible from outside. A blocking hook is observable: `block-force-push` denied its command from inside a prepared temporary profile (`--setting-sources user`, copied hooks-only `settings.json`), proving hooks load and fire without any trust gating.
- Claude judge path: judges run with empty setting sources and use no tools; every hook is wired to tool events, so hooks structurally cannot fire on verdicts.
- Codex: `codex exec --dangerously-bypass-hook-trust` acknowledged enabled hooks from the copied `hooks.json` ("Enabled hooks may run without review for this invocation"). The end-to-end firing check was cut short by a usage-limit reset window; the first hook-inclusive codex run doubles as that check.
- A measurement artifact surfaced immediately: branch-guard blocks the first code edit on main, the agent branches and proceeds correctly, and event-ordering scorers counted the blocked attempt as a pre-branch change. Scorers now ignore failed file-change events.

## Run vintage

Runs recorded before 2026-08-07 predate hook inclusion and measured instruction-only adherence:

- codex sol/low `f820152d` (2026-07-27)
- claude opus/low `65dec8ae`, sonnet/medium `51e75190`, fable/low `e6998973` (2026-08-07, pre-hooks)

These remain the instructions-without-hooks reference set for the incremental-add experiment.

The opus compute-selection value was recorded as 100 under the pre-Fable compute ladder, where opus held the ceiling band. Adding the Fable band made the same evidence an equal-tier selection, which the ladder scores 50. That manual override has been reverted so recorded values stay consistent with the ladder they are read against: assessment `a-ce7e14f07ece4050b3b09c6525b3478b` now carries 50, and the run and agent-version metrics were corrected to match. The two superseded assessments remain in the override chain as the audit trail.

Manual overrides age against scorer changes. Prefer fixing the scorer, and when an override is unavoidable, expect to revisit it whenever the rule behind it moves.
