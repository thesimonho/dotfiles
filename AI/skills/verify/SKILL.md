---
name: verify
description: A checklist of post-work verification steps. Use before merging or creating a PR; when you want to ensure quality gates pass, or after refactoring. Do NOT run for documentation-only changes.
---

# Verification

Verify correctness in proportion to the risk and scope of the change.

During implementation:

- Run the smallest targeted test or check that gives useful feedback.
- Do not repeatedly run the full verification suite after every edit.
- Do not rerun a passing check unless relevant code or configuration changed.

Before completing a ticket:

- Add one real-runtime smoke test only when runtime behaviour is part of the
  ticket's acceptance criteria or cannot be proven adequately by automated
  checks.
- Verify only the affected platforms unless shared cross-platform behaviour
  changed.
- Treat failed verification methods as evidence about the method, not automatic
  justification for unlimited retries.

## Worktrees

Verification claims must name the environment actually tested. Testing a canonical checkout does not verify worktree discovery, ignored configuration resolution, per-worktree ports, or cache isolation. When the feature is intended for agents in worktrees, run the final smoke test from a real worktree with the final code state.

## Tasks

Read applicable repository instructions and acceptance criteria before selecting checks. They take precedence over this checklist, including restrictions on tests. Determine which checks below are relevant. Batch independent, non-mutating checks in a single call; run formatters separately and inspect their changes before final review. Pass routine checks to a subagent using the smallest/lightest available model.

You have permission to spawn subagents for this.

### 1. Build Check

- Run the platform build command for this project

### 2. Type Check

- Run type checker
- Report all errors with `file:line`

### 3. Lint Check

- Run linter
- Report all errors with `file:line`

### 4. Formatter

- Run formatter

### 5. Test Suite

- Run the relevant tests only when repository instructions permit them
- Report pass/fail count and coverage when measured; do not invent missing coverage

### 6. Usage Test

Do not downgrade the subagent model for this check.

- Run the actual app in a real-world scenario (e.g. use the CLI, emulator, agent browser skill to interact with the app)
- Test the feature to confirm it works and no issues are found
- Report blockers, UX issues, unexpected side effects, and bugs

Read the `gui.md` reference file first for supporting information about tools.

### 7. Standards Review

After the final edits and relevant checks, call the `standards-reviewer` agent for every verification run. This review is independent of build, lint, test, and usage results.

Create a fresh reviewer for each distinct change or delivery stage. Give it a focused handoff without inheriting the main chat's full history; use `fork_turns: none` where supported. Reuse it only for corrections and missing evidence within that same bounded review. Do not carry it into another feature, integration review, release investigation, or later verification run merely because the main chat continues.

Supply:

- The repository/worktree root and exact diff or revision, including task-owned untracked files.
- The user's constraints and the authoritative delivery record or acceptance criteria.
- Relevant project guidance paths, including design/style rules and directory READMEs. The reviewer must also inspect applicable instructions itself.
- Check results and runtime or visual evidence, with the code state and environment actually checked.
- The delivery stage being assessed, so future hosted or deployment checks are not treated as already due.

Use the agent's configured lightweight model. If the named role is unavailable in the current session, use a subagent with the full instructions from `AI/agents/standards-reviewer.md` in the dotfiles repository. Keep reviewed files unchanged and permit only task-owned evidence writes under `/tmp`; preserve the announced packet path for continuation after compaction. If the definition, required temporary-file access, or delegation is unavailable, report that the required review was not performed; do not substitute an unreported self-review.

The review must cover applicable written rules, consistency with equivalent operations, and existing alternatives to new local implementations. Supply any known peers or reusable candidates, but the reviewer must inspect the evidence itself.

Resolve confirmed violations and demonstrated consistency or reuse issues before reporting verification as complete. If a finding requires a decision that changes approved scope, return that decision to the user. Obtain required missing evidence, or state the specific blocker without claiming readiness. After corrections, rerun only affected checks and ask the reviewer to reassess the affected findings on the final diff. A standards PASS does not replace runtime checks or authorize external delivery actions.

Once the final assessment is accepted, or the review is handed back with unresolved blockers, retain its essential findings and evidence references in the caller's delivery record or handoff. Confirm temporary evidence cleanup, then close or release the reviewer with the host's agent lifecycle tool when available. If the host cannot remove agents, mark this reviewer finished and do not message or resume it for later work; spawn a fresh reviewer instead. Do not treat interruption as erasing an agent's context. The caller owns retirement; the reviewer cannot close itself.
