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
