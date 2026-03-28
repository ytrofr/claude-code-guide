---
paths:
  - "**/*.{js,ts,jsx,tsx}"
  - "**/*.py"
---

# Rate Limit Retry + Circuit Breaker — External API Safety

**Scope**: ALL projects calling external APIs (REST, GraphQL, LLM providers)
**Authority**: MANDATORY when calling rate-limited APIs

---

## Core Rule

**When an external API returns 429 (rate limited), use exponential backoff with a circuit breaker. Never retry in a tight loop.**

Tight retry loops amplify load on the failing service and cascade failures across your own pipeline.

---

## Exponential Backoff

```
Attempt 1: wait 1s
Attempt 2: wait 2s
Attempt 3: wait 4s
Attempt 4: wait 8s
Max: 3-4 retries, then fail gracefully
```

Add jitter (random 0-500ms) to prevent thundering herd when multiple callers retry simultaneously.

## Circuit Breaker

After the FIRST 429 in a batch operation, stop ALL pending requests to that API — don't fire the remaining 50 calls just to get 50 more 429s.

```
# WRONG — fires all requests, gets 50 failures
for (const item of items) await callApi(item)

# CORRECT — stop on first 429
for (const item of items) {
  const res = await callApi(item)
  if (res.status === 429) { log('circuit open'); break }
}
```

## Rate Limit Ratio Check (Proactive)

When the API provides rate limit headers, check BEFORE making requests:

```
remaining = headers['x-ratelimit-remaining']
limit = headers['x-ratelimit-limit']
if (remaining / limit < 0.05) pause until reset
```

## Anti-Pattern

```
API returns 429 → retry immediately → 429 again → retry → 429 →
all callers retry → cascade → API blocks your IP/key entirely
```

---

**Last Updated**: 2025-03-25
