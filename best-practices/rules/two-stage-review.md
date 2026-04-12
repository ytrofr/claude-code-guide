# Three-Stage Review — MANDATORY After Implementation

**Scope**: ALL projects
**Authority**: Catches spec drift before code polish, then challenges design assumptions
**Source**: Superpowers framework (obra/superpowers) + codex-plugin-cc adversarial pattern

---

## Core Rule

**After implementation, review in THREE ordered stages. Order matters — spec first, then quality, then adversarial.**

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

### Stage 3: Adversarial Challenge (RECOMMENDED before shipping)

Does the design hold up under scrutiny?

| Check | Question |
|-------|----------|
| Assumptions | What does this design assume? Are those assumptions documented? |
| Failure modes | What happens under stress, partial failure, or bad input? |
| Overengineering | Could this be simpler? Is the abstraction level justified? |
| Rollback | Can this change be safely rolled back? |
| Dependencies | What hidden dependencies exist? What breaks if they change? |

**Trigger**: Before PRs to main, before production deploys.
**Skip if**: Trivial changes (<20 lines), documentation-only, config tweaks.

---

## When to Apply

- After implementing ANY plan with 2+ tasks
- After subagent returns implementation results
- Before marking a task as completed

## Anti-Pattern

Reviewing code quality while ignoring that half the spec wasn't implemented.
Fix WHAT was built before polishing HOW it was built.
