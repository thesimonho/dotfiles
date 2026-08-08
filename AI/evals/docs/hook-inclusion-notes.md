---
status: snapshot, true as of 2026-08-08
---

# Hook inclusion verification notes (2026-08-07, reset 2026-08-08)

Snapshot of the evidence gathered when evaluated profiles became hook-inclusive, and of the tracking-store reset that followed. The living behaviour description is in the README and `assessment-design.md`; this records what was verified and why no run predating the reset survives.

## Why profiles became hook-inclusive

Instruction-only profiles measured prose that never runs alone: live sessions pair fragments with PreToolUse/PostToolUse hooks that nudge or enforce the same behaviours. Hook-free eval scores therefore flagged problems that do not exist in day-to-day use — the opus/low instruction-only run recorded near-zero rtk usage in seven of nine cases while the rtk-nudge hook keeps live compliance high.

## Verification performed

- Claude: hooks are not rendered as events in headless stream-json output, so context-injection hooks look invisible from outside. A blocking hook is observable: `block-force-push` denied its command from inside a prepared temporary profile (`--setting-sources user`, copied hooks-only `settings.json`), proving hooks load and fire without any trust gating.
- Claude judge path: judges run with empty setting sources and use no tools; every hook is wired to tool events, so hooks structurally cannot fire on verdicts.
- Codex: `codex exec --dangerously-bypass-hook-trust` acknowledged enabled hooks from the copied `hooks.json` ("Enabled hooks may run without review for this invocation"). End-to-end firing was confirmed on 2026-08-08 from inside a harness-prepared profile: `SessionStart` ran, and a `PreToolUse` hook denied a file write with "Command blocked by PreToolUse hook". Both agent profiles therefore load and execute hooks under their temporary configuration root.
- A measurement artifact surfaced immediately: branch-guard blocks the first code edit on main, the agent branches and proceeds correctly, and event-ordering scorers counted the blocked attempt as a pre-branch change. Scorers now ignore failed file-change events.

## Tracking store reset (2026-08-08)

Every run described above has been deleted. The MLflow container data was wiped and rebuilt once the configuration reached its intended state, because the stored history measured instruction-only profiles that no longer resemble the live setup, and reading a baseline against them invited changes to behaviours that hooks already handle. The pre-reset database is not retained in the repository.

The rebuilt store therefore starts at `agent-harness--claude--manifest` version 1, and every component registers at v1. That is deliberate: the registry's origin point is the current configuration rather than a version history describing configurations that are no longer run. Manifest diffs in run summaries now describe real drift from the intended setup instead of catch-up noise.

The first run in the rebuilt store is claude fable/low, extended suite, run `4474cd62`.

## Profile-scoped hook wiring

The first codex run registered `hook/_wiring` at version 2 on a store where every other component sat at version 1. That component's content is the only one that differs by agent profile — claude reads the `hooks` block of `settings.json`, codex reads `hooks.json` — but its registry name was derived from the component ID alone, so both profiles wrote into one shared version line and each overwrote the other.

The consequence was false drift rather than lost data: alternating profiles bumped the version every run, and the next claude run would have reported `hook/_wiring` as modified without any configuration change. The registry name is now scoped by profile, so each profile owns its own version line while the component keeps one ID across manifests.

Runs before this fix reference the shared registry entry. It is left in place so their manifests stay resolvable; the entry is not written again.

## Measurement variance

Two runs of the same configuration scored the ELI5 judge metric at 25% and 67%, and the subagent compute-selection metric at 50 and 0. Both metrics rest on nine or fewer observations per run, so a single run cannot separate a configuration effect from ordinary variation.

Judge-scored and low-count metrics need repeated runs per arm before a difference means anything. Deterministic scoring does not make a metric stable: the measurement is exact, but the behaviour it measures still varies between runs.

## Retired practice: manual assessment overrides

The opus compute-selection value was once overridden by hand from 50 to 100, then reverted when the Fable band entered the compute ladder and demoted the same evidence back to an equal-tier selection. Both the run and the override chain are gone with the reset.

Manual overrides age against scorer changes. Prefer fixing the scorer, and when an override is unavoidable, expect to revisit it whenever the rule behind it moves.
