# Pre-Validation Probe - Before Approving Plans

**Scope**: ALL plans with verifiable assumptions
**Enforcement**: Run DURING plan mode, BEFORE approving

---

## Core Rule

**Every plan rests on assumptions about reality. Before approving any plan, verify those assumptions with real evidence -- file reads, grep, curl, test runs, whatever proves the current state. Only then approve.**

The probe happens DURING planning, NOT after implementation starts.

---

## When to Run

| Condition                         | Required | Why                                          |
| --------------------------------- | -------- | -------------------------------------------- |
| Plan assumes a problem exists     | YES      | Confirm the problem is real before fixing it |
| Plan assumes current behavior X   | YES      | Verify X is actually what happens today      |
| Plan depends on a technical fact  | YES      | Confirm the fact before building on it       |
| All assumptions already confirmed | SKIP     | Probe adds no value                          |
| Trivial change (<10 lines)        | SKIP     | Overhead exceeds value                       |

**The question**: "What does this plan ASSUME is true, and can I check it right now?"

---

## Probe Contents

### 1. Assumption Tests

Verify the claims your plan is built on. Any tool counts -- file reads, grep, curl, shell commands, DB queries, test runs, log analysis.

```
PROBE_ASSUMPTIONS:
  - Assumption: "[what you believe is true]"
    Test: "[command/check that verifies it]"
    Result: "[fill after running]"
    Verdict: "CONFIRMED / DISPROVED"
```

**Examples:**

| Project Type | Assumption                            | How to Test                                |
| ------------ | ------------------------------------- | ------------------------------------------ |
| Frontend     | "Button doesn't debounce"             | Read the component file, grep for debounce |
| Backend API  | "Endpoint returns 500 on empty input" | `curl -X POST .../endpoint -d '{}'`        |
| Refactoring  | "Function X is called from 12 files"  | `grep -r "functionX(" src/ \| wc -l`       |
| Bug fix      | "Error on unicode input"              | Reproduce with test case                   |
| CI/CD        | "Build takes >8 minutes"              | Check last 5 CI runs                       |

### 2. Feasibility Check

If the approach rests on an unproven assumption, test it with the smallest possible experiment.

```
PROBE_FEASIBILITY:
  - Question: "[can we do X?]"
    Test: "[smallest snippet that proves X works]"
    Result: "[fill after running]"
    Go/No-Go: "GO / NO-GO"
```

---

## Probe Size (Keep It Small)

| Plan Complexity      | Probe Size | Time Budget |
| -------------------- | ---------- | ----------- |
| Simple (1-3 files)   | 1-3 checks | <2 min      |
| Standard (3-7 files) | 3-5 checks | <5 min      |
| Complex (7+ files)   | 5-8 checks | <10 min     |

The probe is NOT a full test suite. It is the minimum set of checks that would catch a fundamentally wrong plan.

---

## When Probe Fails

| Failure Type               | Action                           |
| -------------------------- | -------------------------------- |
| Assumption DISPROVED       | Adjust plan to match reality     |
| Feasibility NO-GO          | STOP and redesign approach       |
| >50% assumptions disproved | REJECT plan entirely and re-plan |

---

## Anti-Patterns

- "I'll measure the baseline after implementing" -- TOO LATE, no before/after comparison
- "The baseline is probably ~96%" -- ESTIMATED is not verified, run the check
- "Skip probe, plan is obvious" -- Even obvious plans have wrong assumptions
- "Probe found the problem doesn't exist, but let's implement anyway" -- STOP

---

**The principle**: A 2-minute probe catches what hours of coding cannot fix retroactively.
