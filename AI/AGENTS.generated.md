# Coding Style

## General

Adopt a "sentence readable" approach:

- Code should read like a sentence
- Prefer descriptive names over short names
- Long names are perfectly acceptable
- Use `isX` and `hasX` naming conventions for boolean checks
- Declare more variables to avoid nested or long expressions

## File Organization

MANY SMALL FILES > FEW LARGE FILES:

- High cohesion, low coupling
- 200-400 lines typical, 800 max
- Extract utilities from large components
- Organize by feature/domain, not by type

## Comments

- Write docstrings. Conventions: typescript/tsx (TSDoc), python (google docstrings), go (GoDoc)
- Comments explain why, not what - provide enough context for someone to write tests against intended behaviour

## Code Quality Checklist

Before marking work complete:

- [ ] Code is readable and well-named
- [ ] Functions are small (<30 lines)
- [ ] Functions have docstrings
- [ ] Files are focused (<800 lines)
- [ ] Use early returns
- [ ] No deep nesting (>4 levels)
- [ ] Proper error handling
- [ ] No console.log statements
- [ ] No hardcoded values
- [ ] No mutation (immutable patterns used)

# Git Workflow

## Branch Workflow

Always start your work in a new branch created from the currently checked out branch

Naming convention: `<type>/<description>`, where type is one of the conventional commit types:

- feat: new feature
- fix: bug fix
- refactor: refactoring
- docs: documentation
- test: adding missing tests
- chore: maintenance
- perf: performance improvement
- ci: CI related changes

## Committing

### Conventional commits

Every commit message follows the conventional commit format:

```
<type>: <short description>
```

Types: `feat`, `fix`, `refactor`, `test`, `chore`, `docs`, `perf`, `ci`

Keep the subject line under 70 characters. Add a body only when the "why" isn't obvious from the subject.

### Small, logical commits

Commit in small, focused chunks — each commit should be one logical change that is easy to review and revert.

- Commit at each green phase of TDD (test + implementation together)
- Don't bundle unrelated changes in a single commit
- Don't commit half-finished work that breaks the build

### Never Commit

- Secrets, API keys, passwords, or tokens
- `.env` files (these belong in `.gitignore`)
- Large binary files without good reason

## Pull Request/Merge Workflow

When pushing, merging or creating PRs:

1. All changes are committed
2. The branch is up to date with main (rebase if needed)
3. Verification has passed (lint, type-check, tests, build)
4. Analyze full commit history of the branch (not just latest commit)
5. Use `git diff [base-branch]...HEAD` to see all changes
6. Use a fast-forward merge strategy if possible

Once you have merged your branch, make sure you delete the local branch

# Security Guidelines

## Mandatory Security Checks

Before ANY commit:

- [ ] No hardcoded secrets (API keys, passwords, tokens)
- [ ] All user inputs validated
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention (sanitized HTML)
- [ ] CSRF protection enabled
- [ ] Authentication/authorization verified
- [ ] Rate limiting on endpoints
- [ ] Error messages don't leak sensitive data

## Secret Management

```typescript
// NEVER: Hardcoded secrets
const apiKey = "sk-proj-xxxxx";

// ALWAYS: Private environment variables
const apiKey = process.env.OPENAI_API_KEY;

if (!apiKey) {
  throw new Error("OPENAI_API_KEY not configured");
}
```

## Security Response Protocol

If security issue found:

1. STOP immediately
2. Tell the user
3. Use **security-reviewer** agent
4. Fix CRITICAL issues before continuing
5. Review entire codebase for similar issues

# Shell Command Hygiene

Run each shell command as a **separate, simple Bash call**. Do not chain commands with `&&`, `||`, `;`, or pipes when each part is an independently meaningful operation.

This is critical — the permissions system matches against the beginning of each Bash call. Compound commands will be blocked.

This applies to all shell commands, including `git`, `npm`, `go`, etc.

## Rules

- **One operation per Bash call:** `git add`, `git commit`, `git push`, `npm run test`, etc. — each is its own tool call
- **Do not chain:** `git add . && git commit -m "msg"` will be blocked. Use two separate calls.
- **Do not wrap:** No subshells, inline scripts, or heredocs around git commands
- **Pipelines are fine** when the pipe is integral to the command (e.g., `git log --oneline | head -20`)

## Examples

```bash
# CORRECT — separate calls
git add .
# (separate Bash call)
git commit -m "feat: add user avatar"

# WRONG — chained
git add . && git commit -m "feat: add user avatar"

# WRONG — subshell
sh -c 'git add . && git commit -m "feat: add user avatar"'
```

# Testing Requirements

## Minimum Test Coverage: 80%

Test Types:

1. **Unit Tests** - Individual functions, utilities, components
2. **Integration Tests** - API endpoints, database operations (if applicable)
3. **E2E Tests** - Critical user flows (if applicable)

## Test-Driven Development

If a testing framework has been set up, you must _always_ use test-driven development. But do not set up a new testing framework unprompted.

Use **tdd-workflow** skill to help you.

Workflow:

1. Write test first (RED)
1. Run test - it should FAIL
1. Write minimal implementation (GREEN)
1. Run test - it should PASS
1. Refactor (IMPROVE)
1. Verify coverage (80%+)

## Troubleshooting Test Failures

1. Check test isolation
2. Verify mocks are correct
3. Fix implementation, not tests (unless tests are wrong)

Important: if you come across a test failure that isn't within your current scope of work, you must inform the orchestrator to create a new worktree to fix the issue. Do not just pass over it.

# Workflow

## Documentation

- Create README.md files for subdirectories/submodules when nuance and detail is needed for that section.
- When working with subdirectories, make sure to first check if it has an associated README.md that provides more specific information.
- Keep repo/subdirectory README.md and project AGENTS.md/CLAUDE.md files up to date when making significant changes.
- You MUST reference the docs/codemaps/ directory when trying to explore code or find a specific piece of code. They will quickly tell you where things are located. As a result, it is also important to keep these up to date.

## Planning

Always create a plan first. Have the plan and spec reviewed before proceeding with implementation.

## When Uncertain

- Always ask before proceeding
- One decision at a time - don't present branching decisions that require multiple follow-ups. Instead, make a note and should circle back when needed.
- When presenting alternatives: pros, cons, and a recommendation given the context

## When Exploring and Reviewing

- Question my approach if you see issues
- Focus on: bugs, security, performance, architectural concerns
- Minor stylistic nitpicks can be noted as an aside
- Stop and ask before making significant changes

## When debugging

- Run unit tests to help keep you on track
- Use logging freely to identify root cause, but make sure to remove logging before committing
- When fixing frontend issues, make sure you proactively use the agent browser skill in headed mode

## Code Intelligence

Prefer LSP over Grep/Glob/Read for code navigation:

- `goToDefinition` / `goToImplementation` to jump to source
- `findReferences` to see all usages across the codebase
- `workspaceSymbol` to find where something is defined
- `documentSymbol` to list all symbols in a file
- `hover` for type info without reading the file
- `incomingCalls` / `outgoingCalls` for call hierarchy

Before renaming or changing a function signature, use
`findReferences` to find all call sites first.

Use Grep/Glob only for text/pattern searches (comments,
strings, config values) where LSP doesn't help.

After writing or editing code, check LSP diagnostics before
moving on. Fix any type errors or missing imports immediately.

