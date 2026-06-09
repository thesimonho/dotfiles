---
name: verify
description: A checklist of post-work verification steps. Use proactively after completing a feature or significant code change; before creating a PR; when you want to ensure quality gates pass or after refactoring. Do NOT run for documentation-only changes.
---

# Verification Skill

Start by running the /simplify skill over your changes.

## Verification Phases

### 1. Build Check

- Run the build command for this project
- If it fails, report errors and STOP

---

Then spawn the following as **parallel background tasks**. Use lighter models for simpler checks (e.g. haiku, Codex-Spark)

### 2. Type Check

- Run type checker
- Report all errors with `file:line`

### 3. Lint Check

- Run linter
- Report all errors with `file:line`

### 4. Formatter

- Run formatter

### 5. Test Suite

- Run all available tests (unit, integration, e2e)
- Report pass/fail count
- Report coverage percentage

### 6. Usage Test

- Run the actual app in a real-world scenario (use the CLI, use agent browser skill to interact with the app, etc.)
- Test the feature to confirm it works and no issues are found
- Report blockers, UX issues, unexpected side effects, and bugs
