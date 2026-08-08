---
name: verify
description: A checklist of post-work verification steps. Use after completing a feature or significant code change; before creating a PR; when you want to ensure quality gates pass or after refactoring. Do NOT run for documentation-only changes.
---

# Verification Skill

Determine which of the following verification checks are relevant for the code changes you just made. Construct a batched compound command to run the simpler checks in a single call. Pass the task to a subagent to run - the subagent should use the smallest/lightest model possible (e.g. haiku, Codex-Spark).

You have permission to spawn subagents for this.

## 1. Build Check

- Run the platform build command for this project

## 2. Type Check

- Run type checker
- Report all errors with `file:line`

## 3. Lint Check

- Run linter
- Report all errors with `file:line`

## 4. Formatter

- Run formatter

## 5. Test Suite

- Check that tests are still passing
- Report pass/fail count
- Report coverage percentage

## 6. Usage Test

Do not downgrade the subagent model for this check.

- Run the actual app in a real-world scenario (e.g. use the CLI, emulator, agent browser skill to interact with the app)
- Test the feature to confirm it works and no issues are found
- Report blockers, UX issues, unexpected side effects, and bugs
