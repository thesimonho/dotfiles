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

Determine which of the following verification checks are relevant for the code changes you just made. Construct a batched compound command to run the simpler checks in a single call. Pass the task to a subagent to run - the subagent should use the smallest/lightest model possible (e.g. haiku, Codex-Spark).

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

- Check that tests are still passing
- Report pass/fail count
- Report coverage percentage

### 6. Usage Test

Do not downgrade the subagent model for this check.

- Run the actual app in a real-world scenario (e.g. use the CLI, emulator, agent browser skill to interact with the app)
- Test the feature to confirm it works and no issues are found
- Report blockers, UX issues, unexpected side effects, and bugs

Read the `gui.md` reference file first for supporting information about tools.
