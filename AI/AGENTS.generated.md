# Coding Style

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
- [ ] Functions are small (<50 lines)
- [ ] Functions have docstrings
- [ ] Files are focused (<800 lines)
- [ ] Use early returns
- [ ] No deep nesting (>4 levels)
- [ ] Proper error handling
- [ ] No console.log statements
- [ ] No hardcoded values
- [ ] No mutation (immutable patterns used)

# Git Workflow

## Pre Commit

Run the /verification skill before committing.

## Commit Message Format

```
<type>: <description>

<optional body>
```

Types: feat, fix, refactor, docs, test, chore, perf, ci

## Pull Request Workflow

When creating PRs:

1. Analyze full commit history of the branch (not just latest commit)
2. Use `git diff [base-branch]...HEAD` to see all changes
3. Draft comprehensive PR summary

# Security Guidelines

## Mandatory Security Checks

Before ANY commit:

- [ ] No hardcoded secrets (API keys, passwords, tokens)
- [ ] All user inputs validated
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention (sanitized HTML)
- [ ] CSRF protection enabled
- [ ] Authentication/authorization verified
- [ ] Rate limiting on all endpoints
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

# Testing Requirements

## Minimum Test Coverage: 80%

Test Types:

1. **Unit Tests** - Individual functions, utilities, components
2. **Integration Tests** - API endpoints, database operations (if applicable)
3. **E2E Tests** - Critical user flows (if applicable)

## Test-Driven Development

Only applies when a testing framework is already configured - do not set up testing infrastructure unprompted.

Use **tdd-workflow** skill

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

## Agent Support

- **playwright-runner** - Playwright E2E testing specialist

# Workflow

## Documentation

- Create README.md files for subdirectories/submodules when nuance and detail is needed for that section.
- When working with subdirectories, make sure to first check if it has an associated README.md that provides more specific information.
- Keep repo/subdirectory README.md and project AGENTS.md/CLAUDE.md files up to date when making significant changes.

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

