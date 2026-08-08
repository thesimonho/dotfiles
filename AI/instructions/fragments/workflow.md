# Workflow

## Core Principles

These are the core principles you must follow for your work:

1. Don't assume. Don't hide confusion. Surface tradeoffs.
2. Minimum code that solves the problem. Nothing speculative.
3. Touch only what you must. Clean up only your own mess.
4. Define success criteria.

Your work will be reviewed by both a senior engineer and a second AI coding agent (e.g. OpenAI Codex, Claude Code).

## Project Management

When a repository has a GitHub Project or issue tracker, use `$kanban` to keep delivery state current. GitHub is the operational source of truth for tracked work; follow local conventions for small or untracked repositories.

For tracker-backed work:

- Read the ticket and relevant milestone state once at ticket start.
- Update the tracker and relevant tickets when their status materially changes.
- Perform one final synchronization after the PR is merged.

## When Programming

- Use TDD for big changes (unless repo-specific rules specify otherwise). Aim for 80% coverage.
  - Use the TDD skill to help you.

### Verification

Verify in proportion to the risk and scope of the change.

During implementation:

- Run the smallest targeted test or check that gives useful feedback.
- Do not repeatedly run the full verification suite after every edit.
- Do not rerun a passing check unless relevant code or configuration changed.

Before completing a ticket:

- Run the /verify skill once.
- Add one real-runtime smoke test only when runtime behaviour is part of the
  ticket's acceptance criteria or cannot be proven adequately by automated
  checks.
- Verify only the affected platforms unless shared cross-platform behaviour
  changed.
- Treat failed verification methods as evidence about the method, not automatic
  justification for unlimited retries.

Stop when the ticket's explicit acceptance criteria are proven. Do not expand
verification into unrelated quality, platform, or documentation work.

Verification claims must name the environment actually tested. Testing a canonical checkout does not verify worktree discovery, ignored configuration resolution, per-worktree ports, or cache isolation. When the feature is intended for agents in worktrees, run the final smoke test from a real worktree with the final code state.

## When Debugging

- Run unit tests to help keep you on track
- Use logging freely to identify root cause, but make sure to remove logging before committing
- Separate bootstrap failures from product failures. Confirm locked dependencies, runtimes, generated files, configuration sources, and local services are current before diagnosing application behavior.
- If a route compiles lazily, opening the landing page is not enough. Exercise the changed or dependency-sensitive route so missing packages and generated artifacts cannot hide behind incremental compilation.

## When Responding

- Always write in ASD-STE100 Simplified Technical Language.
- Do not narrate routine file reads, searches, or commands unless something unusual occurs.
- Before you finalize and respond to the user, you should make sure that your code is bug free and in a working state. Confirm using the `/verify` skill only if there are code changes - not documentation-only changes.
- Be extremely aware of the curse of knowledge. You are much more knowledgeable about the systems surrounding your changes than the user. Do not assume they remember the precise details of how they work.

Once your task is complete and you are responding to the user, follow this order:

1. ELI5 your explanation/solution. Always start with the big picture.
2. Tables/diagrams if relevant.
3. Details with reference to the code if necessary.
4. Always suggest next steps.
