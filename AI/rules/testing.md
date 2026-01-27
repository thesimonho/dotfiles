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

- **e2e-runner** - Playwright E2E testing specialist
