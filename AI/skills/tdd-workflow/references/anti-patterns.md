## Common Testing Mistakes to Avoid (Anti-Patterns)

### ❌ WRONG: Testing Implementation Details

```typescript
// Don't test internal state
expect(component.state.count).toBe(5);
```

### ✅ CORRECT: Test User-Visible Behavior

```typescript
// Test what users see
expect(screen.getByText("Count: 5")).toBeInTheDocument();
```

### ❌ WRONG: Brittle Selectors

```typescript
// Breaks easily
await page.click(".css-class-xyz");
```

### ✅ CORRECT: Semantic Selectors

```typescript
// Resilient to changes
await page.click('button:has-text("Submit")');
await page.click('[data-testid="submit-button"]');
```

### ❌ WRONG: No Test Isolation

```typescript
// Tests depend on each other
test("creates user", () => {
  /* ... */
});
test("updates same user", () => {
  /* depends on previous test */
});
```

### ✅ CORRECT: Independent Tests

```typescript
// Each test sets up its own data
test("creates user", () => {
  const user = createTestUser();
  // Test logic
});

test("updates user", () => {
  const user = createTestUser();
  // Update logic
});
```
