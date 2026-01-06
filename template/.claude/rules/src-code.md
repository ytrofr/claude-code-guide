---
path_patterns:
  - "src/**/*.js"
  - "src/**/*.ts"
  - "lib/**/*"
---

# Source Code Rules

**Scope**: All source code files
**Authority**: Project coding standards

---

## Modular Architecture

```yaml
Structure:
  Routes: src/routes/           # API endpoint definitions
  Controllers: src/controllers/ # Request handling logic
  Services: src/services/       # Business logic
  Utils: src/utils/             # Shared utilities
  Types: src/types/             # Type definitions
```

**Rule**: Never add business logic directly to route files.

---

## Code Standards

### JavaScript/TypeScript

```javascript
// ✅ DO: Use async/await
async function getData() {
  const result = await fetchData();
  return result;
}

// ❌ DON'T: Use callbacks
function getData(callback) {
  fetchData().then(result => callback(result));
}
```

### Variable Declarations

```javascript
// ✅ Prefer const
const config = loadConfig();

// ⚠️ Use let only when reassignment needed
let counter = 0;
counter++;

// ❌ Never use var
var oldStyle = 'deprecated';
```

---

## Documentation

```javascript
/**
 * Brief description of function purpose.
 * @param {string} input - Description of parameter
 * @returns {Promise<Object>} Description of return value
 */
async function processData(input) {
  // Implementation
}
```

---

## Error Handling

```javascript
// ✅ DO: Specific error handling
try {
  await riskyOperation();
} catch (error) {
  logger.error('Operation failed:', error.message);
  throw new CustomError('Operation failed', { cause: error });
}

// ❌ DON'T: Swallow errors silently
try {
  await riskyOperation();
} catch (error) {
  // Silent failure - BAD!
}
```

---

**Related**: See `tests.md` for testing standards
