---
path_patterns:
  - "tests/**/*"
  - "test/**/*"
  - "**/*.test.js"
  - "**/*.spec.js"
---

# Testing Rules

**Scope**: All test files and testing patterns
**Authority**: Quality assurance standards

---

## Coverage Targets

| Type | Target | Priority |
|------|--------|----------|
| Unit Tests | 80%+ | HIGH |
| Integration Tests | 70%+ | MEDIUM |
| E2E Tests | Critical paths | HIGH |

---

## Test Structure

```javascript
describe('ModuleName', () => {
  describe('functionName', () => {
    it('should [expected behavior] when [condition]', async () => {
      // Arrange
      const input = createTestInput();
      
      // Act
      const result = await functionName(input);
      
      // Assert
      expect(result).toEqual(expected);
    });
  });
});
```

---

## Naming Conventions

```yaml
Files:
  Unit: "*.test.js" or "*.spec.js"
  Integration: "*.integration.test.js"
  E2E: "*.e2e.test.js"

Descriptions:
  Pattern: "should [verb] [expected outcome] when [condition]"
  Examples:
    - "should return 200 when user is authenticated"
    - "should throw error when input is invalid"
```

---

## Test Data

```javascript
// ✅ DO: Use factories or builders
const user = createTestUser({ role: 'admin' });

// ✅ DO: Clear test data state
beforeEach(async () => {
  await clearTestDatabase();
});

// ❌ DON'T: Hardcode test data
const user = { id: 1, name: 'Test', email: 'test@test.com' };
```

---

## Mocking

```javascript
// ✅ DO: Mock external dependencies
jest.mock('./external-api', () => ({
  fetchData: jest.fn().mockResolvedValue({ data: 'mocked' })
}));

// ❌ DON'T: Make real API calls in unit tests
// Real calls slow tests and create flakiness
```

---

## Quick Commands

```bash
# Run all tests
npm test

# Run with coverage
npm run test:coverage

# Run specific test file
npm test -- path/to/test.js

# Watch mode
npm run test:watch
```

---

**Related**: See `src-code.md` for code standards
