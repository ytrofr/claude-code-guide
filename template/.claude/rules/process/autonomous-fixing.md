# Autonomous Fixing Protocol

**Scope**: ALL projects
**Authority**: When to fix independently vs. ask user
**Created**: 2026-02-23

---

## Core Rule

**When given a bug or error: fix it. Don't ask for hand-holding.**

Read the error → find root cause → check memory for prior fixes → fix → verify → report.

---

## Fix Autonomously (No Permission Needed)

- Failing tests from your own changes
- Lint, format, or type errors
- Import/require issues
- Obvious logic bugs (null checks, off-by-one, typos)
- CI failures caused by your changes
- Missing files referenced in your changes
- Broken builds after your edits

## Ask Before Fixing

- Architectural changes (moving files, changing patterns)
- Data mutations (DB writes, API calls to prod/staging)
- Deleting code you didn't write (>10 lines)
- Changes affecting >5 files beyond original scope
- Performance trade-offs with unclear impact
- Reverting someone else's work

---

## Workflow

1. Read the error/log/test output
2. Search for root cause (Grep, Read)
3. Check memory for prior fixes (search knowledge base for similar error patterns)
4. Fix it
5. Verify (run test, curl endpoint, check output)
6. Report: what broke, why, what you fixed

---

**Anti-pattern**: Asking "should I fix this failing test?" when YOU broke it.
**Correct**: Fix it, verify, report what happened.
