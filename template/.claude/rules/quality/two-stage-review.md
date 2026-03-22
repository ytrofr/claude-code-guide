# Two-Stage Review — MANDATORY After Implementation

**Scope**: ALL projects
**Authority**: Catches spec drift before code polish
**Source**: Superpowers framework (obra/superpowers) — validated pattern

---

## Core Rule

**After implementation, review in TWO ordered stages. Order matters — spec first.**

### Stage 1: Spec Compliance (FIRST)

Does the code match what was planned?

| Check | Question |
|-------|----------|
| Requirements | Are ALL planned requirements implemented? |
| Architecture | Does the implementation match the designed approach? |
| Scope | Did implementation drift beyond what was planned? |
| Missing | Are there planned items that were skipped or deferred? |

**If Stage 1 fails**: Fix spec drift BEFORE polishing code quality.

### Stage 2: Code Quality (SECOND)

Is the code clean and maintainable?

| Check | Question |
|-------|----------|
| SOLID/DRY/KISS | Does it follow principles? |
| Security | OWASP top 10 considered? |
| Performance | Acceptable for the use case? |
| Patterns | Matches existing codebase conventions? |

---

## When to Apply

- After implementing ANY plan with 2+ tasks
- After subagent returns implementation results
- Before marking a task as completed

## Anti-Pattern

Reviewing code quality while ignoring that half the spec wasn't implemented.
Fix WHAT was built before polishing HOW it was built.
