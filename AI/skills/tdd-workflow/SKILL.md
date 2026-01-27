---
name: tdd-workflow
description: Proactively use this skill when implementing features, fixing bugs, or refactoring code. Enforces test-driven development with 80%+ coverage including unit, integration, and E2E tests.
---

# Test-Driven Development Workflow

This skill ensures all code development follows TDD principles with comprehensive test coverage.

## Core Principles

### 1. Tests BEFORE Code

ALWAYS write tests first, then implement code to make tests pass.

### 2. Coverage Requirements

- Minimum 80% coverage (unit + integration + E2E)
  -- Don't write exhaustive tests for everything. Focus on critical paths.
- Critical edge cases covered
- Error scenarios tested
- Boundary conditions verified

### 3. Test Types

#### Unit Tests

- Individual functions and utilities
- Component logic
- Pure functions
- Helpers and utilities

#### Integration Tests

- API endpoints
- Database operations
- Service interactions
- External API calls

#### E2E Tests

- Critical user flows
- Complete workflows
- Browser automation
- UI interactions

## TDD Workflow Steps

### Step 1: Write User Journeys

```
As a [role], I want to [action], so that [benefit]

Example:
As a user, I want to search for markets semantically,
so that I can find relevant markets even without exact keywords.
```

### Step 2: Write Tests First (RED)

For each user journey, create critical test cases:

```typescript
describe("Semantic Search", () => {
  it("returns relevant markets for query", async () => {
    // Test implementation
  });

  it("handles empty query gracefully", async () => {
    // Test edge case
  });

  it("sorts results by similarity score", async () => {
    // Test sorting logic
  });
});
```

### Step 3: Run Tests (Verify they FAIL)

```bash
npm test
# Tests should fail - we haven't implemented yet
```

### Step 4: Implement Minimal Code (GREEN)

Write minimal code to make tests pass:

```typescript
// Implementation guided by tests
export async function searchMarkets(query: string) {
  // Implementation here
}
```

### Step 5: Run Tests Again (Verify they PASS)

```bash
npm test
# Tests should now pass
```

### Step 6: Refactor

Improve code quality while keeping tests green:

- Remove duplication
- Improve naming
- Optimize performance
- Enhance readability

### Step 7: Verify Coverage

```bash
npm run test:coverage
# Verify 80%+ coverage achieved
```

## Testing Patterns

### Unit Test Pattern (Jest/Vitest)

```typescript
import { render, screen, fireEvent } from '@testing-library/react'
import { Button } from './Button'

describe('Button Component', () => {
  it('renders with correct text', () => {
    render(<Button>Click me</Button>)
    expect(screen.getByText('Click me')).toBeInTheDocument()
  })

  it('calls onClick when clicked', () => {
    const handleClick = jest.fn()
    render(<Button onClick={handleClick}>Click</Button>)

    fireEvent.click(screen.getByRole('button'))

    expect(handleClick).toHaveBeenCalledTimes(1)
  })

  it('is disabled when disabled prop is true', () => {
    render(<Button disabled>Click</Button>)
    expect(screen.getByRole('button')).toBeDisabled()
  })
})
```

### API Integration Test Pattern

```typescript
import { NextRequest } from "next/server";
import { GET } from "./route";

describe("GET /api/markets", () => {
  it("returns markets successfully", async () => {
    const request = new NextRequest("http://localhost/api/markets");
    const response = await GET(request);
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.success).toBe(true);
    expect(Array.isArray(data.data)).toBe(true);
  });

  it("validates query parameters", async () => {
    const request = new NextRequest(
      "http://localhost/api/markets?limit=invalid",
    );
    const response = await GET(request);

    expect(response.status).toBe(400);
  });

  it("handles database errors gracefully", async () => {
    // Mock database failure
    const request = new NextRequest("http://localhost/api/markets");
    // Test error handling
  });
});
```

### E2E Test Pattern (Playwright)

```typescript
import { test, expect } from "@playwright/test";

test("user can search and filter markets", async ({ page }) => {
  // Navigate to markets page
  await page.goto("/");
  await page.click('a[href="/markets"]');

  // Verify page loaded
  await expect(page.locator("h1")).toContainText("Markets");

  // Search for markets
  await page.fill('input[placeholder="Search markets"]', "election");

  // Wait for debounce and results
  await page.waitForTimeout(600);

  // Verify search results displayed
  const results = page.locator('[data-testid="market-card"]');
  await expect(results).toHaveCount(5, { timeout: 5000 });

  // Verify results contain search term
  const firstResult = results.first();
  await expect(firstResult).toContainText("election", { ignoreCase: true });

  // Filter by status
  await page.click('button:has-text("Active")');

  // Verify filtered results
  await expect(results).toHaveCount(3);
});

test("user can create a new market", async ({ page }) => {
  // Login first
  await page.goto("/creator-dashboard");

  // Fill market creation form
  await page.fill('input[name="name"]', "Test Market");
  await page.fill('textarea[name="description"]', "Test description");
  await page.fill('input[name="endDate"]', "2025-12-31");

  // Submit form
  await page.click('button[type="submit"]');

  // Verify success message
  await expect(page.locator("text=Market created successfully")).toBeVisible();

  // Verify redirect to market page
  await expect(page).toHaveURL(/\/markets\/test-market/);
});
```

## Test Coverage Verification

### Run Coverage Report

```bash
npm run test:coverage
```

### Coverage Thresholds

```json
{
  "jest": {
    "coverageThresholds": {
      "global": {
        "branches": 80,
        "functions": 80,
        "lines": 80,
        "statements": 80
      }
    }
  }
}
```

## Edge Cases You MUST Test

1. **Null/Undefined**: What if input is null?
2. **Empty**: What if array/string is empty?
3. **Invalid Types**: What if wrong type passed?
4. **Boundaries**: Min/max values
5. **Errors**: Network failures, database errors
6. **Race Conditions**: Concurrent operations
7. **Large Data**: Performance with 10k+ items
8. **Special Characters**: Unicode, emojis, SQL characters

## Best Practices

1. **Write Tests First** - Always TDD
2. **One Assert Per Test** - Focus on single behavior
3. **Descriptive Test Names** - Explain what's tested
4. **Arrange-Act-Assert** - Clear test structure
5. **Mock External Dependencies** - Isolate unit tests
6. **Test Edge Cases** - Null, undefined, empty, large
7. **Test Error Paths** - Not just happy paths
8. **Keep Tests Fast** - Unit tests < 50ms each
9. **Clean Up After Tests** - No side effects
10. **Review Coverage Reports** - Identify gaps

## Success Metrics

- 80%+ code coverage achieved
- All tests passing (green)
- No skipped or disabled tests
- Fast test execution (< 30s for unit tests)
- E2E tests cover critical user flows
- Tests catch bugs before production
