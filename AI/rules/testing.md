# Testing Requirements

## Core Principle

Don't just write smoke tests.

Test intended behaviour, not implementation details. At every level, assert that the right thing _happened_ — not just that the right type came back or the right dependency was called.

- **Unit**: verify the returned value is correct for the input and that meaningful state changed.
- **Integration**: verify the combined flow produces the right data transformation or side effect, not just that services connect.
- **E2E**: verify user-visible outcomes (content, redirects, confirmations), not internal state.

## Test-Driven Development

If a testing framework has been set up, always use TDD. Do not set up a new testing framework unprompted.

Use **tdd-workflow** skill to help you.

1. Write test first (RED) — run it, confirm it fails
2. Write minimal implementation (GREEN) — run it, confirm it passes
3. Refactor (IMPROVE) — verify coverage (80%+)

## Coverage

Minimum: 80%.

- **Unit tests** — individual functions, utilities, components
- **Integration tests** — API endpoints, database operations (if applicable)
- **E2E tests** — critical user flows (if applicable)

## E2E Test Guidelines

E2E tests verify a user can complete a real workflow start-to-finish, interacting through the UI, CLI, or public API surface.

**Should verify:**

- A user can complete a flow end-to-end (e.g. sign up → create resource → see it listed)
- Visible outcomes: page content, redirects, emails, downloaded files
- Multiple systems working together in a real scenario
- Error states a user would encounter (404s, validation messages, permission denied)

**Should not verify:**

- Response shapes or data structures (integration/contract test)
- Arguments passed to internal functions (unit test with spies)
- Database state, internal method calls, or intermediate transformations
- API field values unless directly visible to the user

**Rule of thumb:** if the assertion requires knowledge of the code's internals rather than its observable behaviour, it doesn't belong in an E2E test.

## Troubleshooting Test Failures

1. Check test isolation
2. Verify mocks are correct
3. Fix implementation, not tests (unless the test is wrong)

If you encounter a failing test outside your current scope, inform the orchestrator to create a new worktree. Do not skip it.
