# Diagnostic-First Debugging — MANDATORY

**Scope**: ALL projects — when multiple failures occur simultaneously
**Authority**: MANDATORY — prevents patch-on-patch cycles
**Evidence**: 3 failures diagnosed via tracer, root cause was tool selection not data flow

---

## Core Rule

**When multiple failures occur, build a diagnostic tracer BEFORE fixing anything.**

Patching symptoms leads to patch-on-patch cycles. The tracer reveals the actual root cause.

---

## When to Apply

- 2+ failures from the same pipeline
- User says "nothing works" or "check the root cause"
- You've already applied 2+ patches without success
- Failures span multiple components (agent → pipeline → transport)

## Pattern

1. **Build a tracer script** — runs the pipeline with a test message
2. **Show every event** — type, data fields, key values
3. **Simulate consumers** — replay what downstream services would do with the events
4. **Verify side effects** — check DB, files, published endpoints
5. **Identify the ACTUAL root cause** — often different from symptoms
6. **Fix once, verify once**

## Anti-Pattern

```
Bug reported → patch data flow → still broken → patch transport →
still broken → patch agent → still broken → user frustrated
```

## Correct Pattern

```
Bug reported → build tracer → run → see WHICH TOOL was called →
discover legacy tool selected → remove it → all 3 bugs fixed
```

---

**Last Updated**: 2026-03-19
