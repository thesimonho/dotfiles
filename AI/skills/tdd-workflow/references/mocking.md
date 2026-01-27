## Mocking External Services

### Supabase Mock

```typescript
jest.mock("@/lib/supabase", () => ({
  supabase: {
    from: jest.fn(() => ({
      select: jest.fn(() => ({
        eq: jest.fn(() =>
          Promise.resolve({
            data: [{ id: 1, name: "Test Market" }],
            error: null,
          }),
        ),
      })),
    })),
  },
}));
```

### Redis Mock

```typescript
jest.mock("@/lib/redis", () => ({
  searchMarketsByVector: jest.fn(() =>
    Promise.resolve([{ slug: "test-market", similarity_score: 0.95 }]),
  ),
  checkRedisHealth: jest.fn(() => Promise.resolve({ connected: true })),
}));
```

### OpenAI Mock

```typescript
jest.mock("@/lib/openai", () => ({
  generateEmbedding: jest.fn(() =>
    Promise.resolve(
      new Array(1536).fill(0.1), // Mock 1536-dim embedding
    ),
  ),
}));
```
