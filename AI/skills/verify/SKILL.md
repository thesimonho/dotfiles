---
name: verify
description: A checklist of post-work verification steps. Use proactively after completing a feature or significant code change; before creating a PR; when you want to ensure quality gates pass or after refactoring
---

# Verification Skill

Start by running the /simplify skill over your changes.

## Verification Phases

### 1. Build Check

- Run the build command for this project
- If it fails, report errors and STOP

---

Then spawn the following as **parallel background tasks**:

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

- Run the actual app in a real-world scenario (use the CLI, use agent browser to interact with the app, etc.)
- One example of this is the `/dogfood` skill
- Test the feature to confirm it works and no issues are found
- Report blockers, UX issues, unexpected side effects, and bugs

## Output Format

After running all phases, produce a verification report:

```
VERIFICATION REPORT
==================

Build:     [PASS/FAIL]
Types:     [PASS/FAIL] (X errors)
Lint:      [PASS/FAIL] (X warnings)
Tests:     [PASS/FAIL] (X/Y passed, Z% coverage)
Security:  [PASS/FAIL] (X issues)
Diff:      [X files changed]

Overall:   [READY/NOT READY] for PR

Issues to Fix:
1. ...
2. ...
```
