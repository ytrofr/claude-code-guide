---
paths:
  - "**/package.json"
  - "**/pyproject.toml"
  - "**/scripts/**/*"
---

# Doctor Command Pattern — Self-Diagnosing Health Check

**Scope**: ALL projects with >5 config knobs, env vars, or external dependencies
**Authority**: Proactive misconfiguration detection
**Source**: OpenClaw `openclaw doctor` pattern (2026-03)

---

## Core Rule

**Every non-trivial project SHOULD have a `doctor` script that checks for common misconfigurations.**

The doctor command replaces "the dev remembers to check" with "the machine checks automatically."

---

## When to Create a Doctor Script

- Project has 5+ environment variables or feature flags
- Project connects to external services (DB, APIs, AI providers)
- Project has toggleable features that interact (caching, routing, feature flags)
- Past bugs were caused by misconfiguration (not code bugs)

## Doctor Script Requirements

| Requirement     | Detail                                                                   |
| --------------- | ------------------------------------------------------------------------ |
| Exit code       | `0` = healthy, `1` = problems found                                      |
| Output          | Human-readable pass/fail per check                                       |
| Speed           | <10 seconds (no heavy operations)                                        |
| No side effects | Read-only — NEVER fix things automatically                               |
| Categories      | Group checks: env vars, connectivity, data integrity, config consistency |

## Standard Convention

```json
// package.json
{ "scripts": { "doctor": "node scripts/doctor.js" } }
```

## Check Categories

1. **Environment**: Required env vars present and valid
2. **Connectivity**: DB, Redis, external APIs reachable
3. **Data Integrity**: Referential consistency, no orphans
4. **Config Consistency**: Feature flags don't contradict each other
5. **Lifecycle**: No stale data from disabled features

---

**Last Updated**: 2026-03-20
