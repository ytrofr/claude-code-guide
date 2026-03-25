# No Band-Aid Fixes — Trace Before Fixing

**Scope**: ALL projects
**Authority**: MANDATORY — overrides urgency pressure
**Evidence**: Production incident — 6 failed band-aid attempts on a query bug. Root cause was user_id filtering in repository layer, not LLM instruction issues.

---

## Core Rule

**When a fix doesn't work on first attempt, STOP fixing and START tracing.**

---

## Mandatory Fix Workflow

```
1. TRACE   — Read actual logs/data. "What was called? What args? What returned?"
2. ISOLATE — Reproduce with smallest test. Call the function directly.
3. PINPOINT — Identify the EXACT line producing wrong output.
4. FIX     — Change that line. One fix, one root cause.
5. VERIFY  — Run the same trace. Confirm data flow is correct.
```

## Band-Aid Detection (FORBIDDEN patterns)

If the fix involves any of these, it's a band-aid — STOP and trace instead:

- "Tell the LLM to do X" (adding instruction text)
- "Reorder tools hoping the LLM picks differently"
- "Add optional param the LLM may or may not use"
- "Clear session/cache" (masks the bug, doesn't fix it)
- "Try same approach with different wording"

**The test**: Does this fix guarantee the correct result regardless of LLM behavior?
If NO → it's a band-aid. Go back to step 1.

## Escalation Gate

**2 failed attempts on the same bug → MANDATORY STOP.**

1. Build a diagnostic tracer or curl the actual API
2. Read the actual data flow (not theory)
3. Present root cause to user before writing more code

## Why This Matters

LLM instruction tweaks have ~50% reliability. Code-level fixes have ~99%.
Band-aids compound: each failed attempt poisons session history, making the next attempt harder.

---

**Last Updated**: 2025-03-25
