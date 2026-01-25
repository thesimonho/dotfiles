# Testing Requirements

## Minimum Test Coverage: 80%

Test Types:

1. **Unit Tests** - Individual functions, utilities, components
2. **Integration Tests** - API endpoints, database operations (if applicable)
3. **E2E Tests** - Critical user flows (if applicable)

## Test-Driven Development

Only applies when a testing framework is already configured - do not set up testing infrastructure unprompted.

Workflow:

1. Write test first (RED)
2. Run test - it should FAIL
3. Write minimal implementation (GREEN)
4. Run test - it should PASS
5. Refactor (IMPROVE)
6. Verify coverage (80%+)

## Troubleshooting Test Failures

1. Use **tdd-guide** agent/skill
2. Check test isolation
3. Verify mocks are correct
4. Fix implementation, not tests (unless tests are wrong)

## Agent Support

- **tdd-guide** - Use PROACTIVELY for new features, enforces write-tests-first
- **e2e-runner** - Playwright E2E testing specialist
