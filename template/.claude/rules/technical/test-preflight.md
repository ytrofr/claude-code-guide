---
paths:
  - "**/test*/**/*"
  - "**/*test*.{js,ts,py}"
  - "**/*spec*.{js,ts,py}"
---

# Test Preflight Check — Validate Infrastructure Before Running Tests

**Scope**: ALL projects with integration or E2E tests
**Authority**: MANDATORY before running test suites that depend on external services

---

## Core Rule

**Before running integration/E2E tests, verify infrastructure is up in <30 seconds. Never waste minutes on test failures caused by a down service.**

A 30-second preflight saves 5-10 minutes of confusing test failures + debugging.

---

## Preflight Checklist

Run these checks BEFORE `npm test` / `pytest` / E2E suites:

| Check | How | Fail Action |
|-------|-----|-------------|
| Server running | `curl -sf http://localhost:$PORT/health` | Start server first |
| Database connected | `SELECT 1` via DB client or health endpoint | Start DB / check credentials |
| Required env vars set | Check for empty `$API_KEY`, `$DB_URL` | Warn and abort |
| External APIs reachable | `curl -sf $API_URL` (timeout 5s) | Skip external tests or mock |
| Ports not conflicting | `lsof -i :$PORT` or `ss -tlnp` | Kill stale process or use different port |

## Implementation Pattern

```bash
# preflight.sh — run before test suite
#!/bin/bash
set -e
echo "Preflight check..."

# 1. Server health
curl -sf http://localhost:${PORT:-8080}/health > /dev/null || { echo "FAIL: Server not running"; exit 1; }

# 2. Database
# (project-specific: psql, sqlite3, or health endpoint)

# 3. Required env vars
for var in API_KEY DB_URL; do
  [ -z "${!var}" ] && { echo "FAIL: $var not set"; exit 1; }
done

echo "Preflight passed"
```

## When to Skip Preflight

- Unit tests with no external dependencies
- Linting / formatting / type checking
- Tests that spin up their own infrastructure (Docker Compose in CI)

---

**Last Updated**: 2026-03-24
