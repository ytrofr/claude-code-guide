---
layout: default
title: "Test-Driven Development"
parent: "Part II — Workflow"
nav_order: 2
---

# Test-Driven Development

Test-Driven Development is the discipline of writing the test before the code. It is not a testing strategy. It is a **design** strategy that happens to produce tests as a side effect. Used with Claude Code, TDD is the single strongest lever you have to stop the model from confidently shipping half-done features.

The loop is three words: **RED, GREEN, REFACTOR**. Write a failing test. Write the smallest code that makes it pass. Clean up without changing behavior. Repeat. Anything else that calls itself TDD is not TDD.

**Purpose**: Replace "my tests pass, therefore the feature works" with "this test failed, then my change made it pass"
**Difficulty**: Beginner cycle, expert discipline
**Applies to**: New features, bug fixes, behavior-changing refactors

---

## The Cycle

```
RED        → Write one failing test for one behavior. Run it. Confirm it fails for the right reason.
GREEN      → Write the minimum code to pass. No extras, no "while I'm here" improvements.
REFACTOR   → Clean up duplication, names, structure. Tests stay green. No new behavior.
```

Each cycle covers **one** testable behavior. If the test name contains the word "and", split it. If the GREEN step takes more than 20 lines, your RED test is too ambitious.

### The Iron Law

> **No production code without a failing test first.**

Write code before the test? Delete it. Start over. No exceptions, no "just this once," no keeping it "as reference."

This sounds harsh until you watch what happens without it. You write the code, then "write the test," and the test is shaped by what you already built. It passes because the code exists, not because it works. Regressions creep in silently because the test never proved anything in the first place.

---

## Step 0: Confirm the Spec

Before you write the RED test, confirm you know what "passing" means. TDD can't help you if the acceptance criteria are fuzzy.

A spec is anything with **unambiguous expected behavior**:

- A plan (from `/plan-checklist`) with testable requirements
- A GitHub issue with acceptance criteria
- A bug report with reproduction steps and expected outcome
- An explicit instruction: "it should return X when Y"

**If there's no spec**: ask one question at a time to extract inputs, outputs, and edge cases. Write the answers as three to five inline bullets before proceeding. Do not start RED against a vague ask — you will write a test that passes, a feature that ships, and a bug the user finds later.

**Skip Step 0 only for**: trivial fixes (<5 lines) with obvious behavior, or when the user explicitly says "skip spec."

---

## 1. RED — Write One Failing Test

Pick one behavior from the spec. Write one test.

**Python (pytest):**

```python
def test_normalize_phone_strips_country_code():
    assert normalize_phone("+972-50-123-4567") == "0501234567"
```

**JavaScript (jest/vitest):**

```javascript
test('normalizePhone strips country code', () => {
  expect(normalizePhone('+972-50-123-4567')).toBe('0501234567');
});
```

Run the test. It **must fail**. Run it with your project's real runner — `pytest`, `npm test`, `vitest`, `cargo test`. Not a dry run, not a type check.

**Two failure modes to rule out**:

1. **Test passed on first run**: you're testing existing behavior. Either the feature already exists (delete the test), or the assertion is wrong (fix the test).
2. **Test failed for the wrong reason**: `NameError`, `SyntaxError`, typo, import failure. Fix the test until it fails because the **feature is missing**, not because the file doesn't parse.

Only then proceed.

---

## 2. GREEN — Minimum Code to Pass

Write the **simplest code that makes the test pass**. YAGNI — You Aren't Gonna Need It.

```python
# GREEN: simplest possible implementation
def normalize_phone(raw: str) -> str:
    return raw.replace("+972-", "0").replace("-", "")
```

That's it. No validation for non-Israeli numbers. No handling of international formats. No "while I'm here, let me also add a is_mobile check." The test says what this function does. Anything else is speculation.

**Run the test and the full suite. Both must pass.** No warnings, no errors, no skipped tests you didn't skip on purpose.

If the test still fails, fix the **production code**, not the test. If other tests break, fix them now — you caused the regression.

### The discipline

"Minimum code to pass" feels wrong at first. You can *see* the better abstraction. You want to extract the helper, handle the edge case, add the type hint.

Don't. Those are separate cycles, each driven by their own failing test. If you don't have a test for the edge case yet, you don't know it matters. Add it to the spec, write the next RED, and let the code grow from the tests.

---

## 3. REFACTOR — Clean Up, Tests Stay Green

Only after GREEN: remove duplication, rename for clarity, extract helpers, improve structure. Run the tests after every change. All must stay green.

**What counts as refactoring:**

- Extracting a repeated pattern into a helper
- Renaming a variable or function for clarity
- Splitting a long function into smaller ones
- Moving code to a better module

**What does NOT count as refactoring:**

- Adding a new branch ("but what about null?") — that's a new behavior, write a new RED test
- Handling an edge case you didn't have a test for
- "Improving" error messages based on assumption
- Performance tweaks without a benchmark proving the problem

If you catch yourself adding behavior during REFACTOR, stop. That's a new RED cycle.

---

## 4. FORMAT-LINT-TEST-COMMIT

After each green-and-clean cycle:

```bash
# Python
ruff format . && ruff check . && pytest

# Node
npm run format && npm run lint && npm test
```

Then commit — small, focused commits, one per behavior. See the [Commit and PR Workflow chapter](/docs/guide/part2-workflow/06-commit-and-pr/) for scoping and message conventions.

---

## When to Use TDD

**Always:**

- New features and new functions
- Bug fixes — the failing test reproduces the bug first, then you fix it
- Behavior changes
- Refactors that change observable behavior (add characterization tests first)

**Ask the user before skipping:**

- Throwaway prototypes and spikes where the goal is to learn, not to ship
- Generated code (migrations, configs, schemas)
- Pure configuration changes

**Don't use TDD for:**

- Exploratory research ("what does this API return?")
- Documentation and prose
- One-off scripts you will run once and delete

The rule of thumb: if the code will be read or run more than twice, write the test first.

---

## Bug Fix Protocol

Never fix a bug without a failing test first. The test does two jobs: it proves the fix works, and it prevents the regression when someone "improves" the code six months later.

```
1. Write a test that reproduces the bug (RED)
2. Run it. Confirm it fails with the bug's symptom
3. Fix the bug (GREEN) — minimum code, full suite passes
4. Refactor if needed, tests stay green
5. Commit: "fix: <symptom> — <cause in one line>"
```

If you fix the bug and then "add a test," you wrote a test that passes because the code is already correct. You did not prove the test catches the bug. It probably doesn't.

---

## Plan-Mode Integration

Every plan should include a testing section. In the plan checklist (see [Chapter 01](/docs/guide/part2-workflow/01-plan-mode/)), **Section 8** is where you declare the testing strategy. Two acceptable answers:

1. **TDD-first**: list the behaviors, declare "RED-GREEN-REFACTOR for each." Default for features and bug fixes.
2. **Justified skip**: name the reason (spike, config-only, generated code) and what replaces TDD (manual smoke, type check, canary). Default must be TDD; skipping requires a sentence of justification.

A plan that says "we'll add tests after" is not a plan. It is a wish. Reviewers should reject it.

---

## Anti-Patterns

### Writing tests after the code

The test was shaped by the implementation. It passes because the code exists, not because the behavior is correct. You have no evidence the test would have caught a bug. This is the single most common TDD violation.

### Skipping REFACTOR

GREEN works, so you move to the next feature. Duplication accumulates, names drift, and by cycle 20 the codebase is a mess that's technically "tested." The REFACTOR step is not optional — it's how TDD produces clean code, not just passing code.

### Testing implementation details

```python
# BAD — asserts on internal state
def test_cache_uses_dict():
    svc = Service()
    assert isinstance(svc._cache, dict)

# GOOD — asserts on behavior
def test_cache_returns_same_result_twice():
    svc = Service()
    first = svc.lookup("x")
    second = svc.lookup("x")
    assert first == second
```

If the test breaks when you refactor internals that don't change behavior, the test was wrong. Tests should pin behavior, not structure.

### Over-mocking

If your test mocks everything the code touches, the test doesn't exercise real code paths. It exercises your mocks. Use real collaborators where possible; reach for mocks only when the real thing is slow, external, or non-deterministic.

### "Just this once"

"This change is too small to need a test." "This one is obviously correct." "I'll add the test after the demo." Every one of these is how regressions land. TDD is a discipline, not a suggestion. If you catch yourself rationalizing, delete the code and start with RED.

---

## Good Tests

| Quality | Good | Bad |
|---|---|---|
| **Focused** | Tests one behavior | "and" in the name — split it |
| **Named** | Describes expected behavior | `test1`, `it works` |
| **Real** | Uses real code paths | Tests mock behavior instead of real code |
| **Minimal** | Smallest setup possible | 50 lines of setup for one assertion |
| **Deterministic** | Same input → same result | Depends on wall clock, random, network |

---

## Stuck?

| Problem | Solution |
|---|---|
| Don't know how to test it | Write the API you wish existed. Start with the assertion, work backward. |
| Test is too complicated | The design is too complicated. Simplify the interface first. |
| Must mock everything | Code is too coupled. Use dependency injection. |
| Test setup is huge | Extract test helpers. Still complex? Simplify the design. |

If the test is hard to write, the code is hard to use. Fix the design.

---

## Verification Checklist

Before marking TDD work complete:

- [ ] Every new function has a test
- [ ] You watched each test fail before implementing
- [ ] Each test failed for the expected reason (missing feature, not typo)
- [ ] You wrote minimum code to pass each test
- [ ] All tests pass — full suite, not just new ones
- [ ] Output is clean — no errors, no warnings
- [ ] Tests use real code (mocks only when unavoidable)
- [ ] Edge cases and error paths are covered
- [ ] Format + lint + test all pass

Cannot check all boxes? You skipped TDD. Start over with RED.

---

## See Also

- [Chapter 01 — Plan Mode](/docs/guide/part2-workflow/01-plan-mode/) — Section 8 TDD gate
- [Chapter 03 — Brainstorming](/docs/guide/part2-workflow/03-brainstorming/) — design before tests
- [Chapter 04 — Verify and Canary](/docs/guide/part2-workflow/04-verify-canary/) — what runs after TDD ships
- `/tdd` skill — one-command entry into the RED-GREEN-REFACTOR loop
