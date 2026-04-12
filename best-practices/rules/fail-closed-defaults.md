# Fail-Closed Defaults — Factory Safety

**Scope**: ALL projects with configuration objects or factory functions
**Authority**: MANDATORY for security-sensitive defaults

---

## Core Rule

**Factory functions and config builders must spread fail-closed defaults first, then override with user values.**

```javascript
// CORRECT — safe defaults applied first
function createConfig(overrides = {}) {
  return {
    allowPublicAccess: false,    // fail-closed
    requireAuth: true,           // fail-closed
    maxRetries: 3,               // safe default
    ...overrides                 // user overrides win
  };
}

// WRONG — missing fields default to undefined (fail-open)
function createConfig(overrides = {}) {
  return { ...overrides };
}
```

## Why This Matters

When a config field is missing:
- `undefined` is falsy -- `if (config.requireAuth)` silently skips auth
- Missing boolean fields default to `false` -- the permissive choice
- Spreading defaults first ensures every security-relevant field has a safe value

## When to Apply

- Factory functions that create configuration objects
- Builder patterns with optional security fields
- Any constructor where missing fields have security implications
