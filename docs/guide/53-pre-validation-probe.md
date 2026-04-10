---
layout: default
title: "Pre-Validation Probe — Verify Assumptions Before Approving Plans"
description: "A 2-minute practice that catches fundamentally wrong plans before implementation begins. Test assumptions with grep, curl, file reads, and test runs during plan mode — not after you've already built the wrong thing."
---

# Chapter 53: Pre-Validation Probe

Plans fail for one reason more than any other: they are built on wrong assumptions about reality. The developer assumes a bug exists, but it was already fixed. The plan assumes an endpoint returns 500 on empty input, but it returns 400. The refactoring plan assumes a function is called from 12 files, but grep shows 3.

The Pre-Validation Probe is a lightweight practice that catches these mistakes. Before approving any plan, you list its assumptions, test them with whatever tools are available, and only proceed if the assumptions hold. It takes 2-10 minutes and prevents hours of wasted implementation.

**Purpose**: Catch plans built on wrong assumptions before implementation starts
**Difficulty**: Beginner
**Time**: 2-10 minutes per plan
**Prerequisites**: [Chapter 45: Plan Mode Quality Checklist](45-plan-mode-checklist.md)

---

## The Problem: Plans Built on Air

Without a probe, the planning workflow looks like this:

```
Observe symptom → Assume root cause → Design fix → Implement → Discover assumption was wrong
```

This is expensive. If the assumption was wrong, you have already:

1. Written a multi-section plan (20-60 minutes)
2. Implemented the fix (1-4 hours)
3. Tested and debugged the fix (30-60 minutes)
4. Discovered the fix does not solve the problem (because the problem was different)
5. Started over with a new plan

With a probe, the workflow becomes:

```
Observe symptom → Assume root cause → Verify assumption (2 min) → Design fix → Implement
```

The probe is the cheapest possible check. It uses tools already available in every Claude Code session: `grep`, `curl`, file reads, shell commands, test runs. No special infrastructure required.

---

## When to Run a Probe

Run the probe when the plan **depends on any claim about the current state that can be verified right now**.

| Condition                                   | Required | Why                                          |
| ------------------------------------------- | -------- | -------------------------------------------- |
| Plan assumes a problem exists               | YES      | Confirm the problem is real before fixing it |
| Plan assumes current behavior X             | YES      | Verify X is actually what happens today      |
| Plan's approach depends on a technical fact | YES      | Confirm the fact before building on it       |
| All assumptions already confirmed           | SKIP     | Probe adds no value                          |
| Trivial change (<10 lines, single file)     | SKIP     | Overhead exceeds value                       |

**The question is simple: "What does this plan ASSUME is true, and can I check it right now?"**

---

## What the Probe Contains

A probe has two parts: assumption tests and feasibility checks. Most probes only need the first part.

### Part 1: Assumption Tests

List what the plan assumes, then verify each assumption with real evidence.

```markdown
## 0.1 Pre-Validation Probe

**Status**: PASSED / FAILED / PARTIAL

### Assumptions Tested

| #   | Assumption                          | Test                                           | Result                            | Verdict   |
| --- | ----------------------------------- | ---------------------------------------------- | --------------------------------- | --------- |
| 1   | Endpoint returns 500 on empty input | `curl -X POST localhost:8080/api/auth -d '{}'` | Returns 400 with validation error | DISPROVED |
| 2   | Function is called from 12+ files   | `grep -r "processQuery(" src/ \| wc -l`        | 3 files                           | DISPROVED |
| 3   | Cache TTL is set to 24h             | `grep "TTL" src/services/cache.js`             | TTL = 3600 (1 hour)               | CONFIRMED |

### Probe Verdict

- **VERDICT**: NO-GO (2/3 assumptions disproved, plan needs redesign)
```

**Any tool available to you counts** -- file reads, grep, curl, shell commands, database queries, browser checks, test runs, log analysis.

### Part 2: Feasibility Checks (When Needed)

If the plan's approach rests on an unproven technical assumption, test it with the smallest possible experiment.

```markdown
### Feasibility

| Check                           | Result                                                                       | Go/No-Go |
| ------------------------------- | ---------------------------------------------------------------------------- | -------- |
| CSS grid handles the RTL layout | Inspected existing grid usage in codebase, 3 RTL components already use grid | GO       |
| New API v3 endpoint exists      | `curl https://api.example.com/v3/status` returns 404                         | NO-GO    |
```

A NO-GO feasibility result means the plan's core approach does not work. Stop and redesign.

---

## Examples Across Project Types

The probe adapts to whatever project you are working on. The only requirement is that the check produces verifiable evidence.

| Project Type  | Assumption                                  | How to Test                                             |
| ------------- | ------------------------------------------- | ------------------------------------------------------- |
| Frontend      | "Button click handler doesn't debounce"     | Read the component file, grep for debounce              |
| Backend API   | "Endpoint returns 500 on empty input"       | `curl -X POST .../endpoint -d '{}'`                     |
| Performance   | "Page load is >3s"                          | Lighthouse CLI or browser performance API               |
| Refactoring   | "Function X is called from 12 files"        | `grep -r "functionX(" src/ \| wc -l`                    |
| Bug fix       | "Error happens when input contains unicode" | Reproduce with test case                                |
| Data pipeline | "Table has NULL values in 12% of rows"      | `SELECT COUNT(*) FILTER (WHERE col IS NULL) FROM table` |
| CI/CD         | "Build takes >8 minutes"                    | Check last 5 CI runs                                    |
| Security      | "Endpoint accepts unescaped HTML"           | `curl` with `<script>` payload                          |
| Documentation | "14 pages reference the old API"            | `grep -r "old_endpoint" docs/`                          |
| Config change | "ENV var is set on staging"                 | `printenv \| grep VAR` or check deployment config       |
| CSS/Layout    | "Element overflows at 320px viewport"       | Screenshot or computed style check                      |

---

## Probe Size

Keep the probe proportional to the plan. It is a smoke test for your assumptions, not a full test suite.

| Plan Complexity      | Probe Size | Time Budget |
| -------------------- | ---------- | ----------- |
| Simple (1-3 files)   | 1-3 checks | <2 min      |
| Standard (3-7 files) | 3-5 checks | <5 min      |
| Complex (7+ files)   | 5-8 checks | <10 min     |

---

## When the Probe Fails

The probe's value comes from what you do when it produces bad news.

| Failure Type                       | Action                                                                     |
| ---------------------------------- | -------------------------------------------------------------------------- |
| Assumption DISPROVED               | Adjust the plan to match reality. Update the problem statement.            |
| Feasibility NO-GO                  | Stop. The plan's core approach does not work. Redesign.                    |
| >50% assumptions disproved         | Reject the plan entirely. Re-enter plan mode with corrected understanding. |
| Baseline much better than expected | Recalibrate targets. Maybe the fix is not worth the effort.                |

**Key insight**: A disproved assumption is not a failure -- it is the probe working correctly. Discovering the truth during a 2-minute check is far cheaper than discovering it after 4 hours of implementation.

---

## Integration with Plan Mode

The Pre-Validation Probe is Section 0.1 in the [Plan Mode Quality Checklist](45-plan-mode-checklist.md). It sits before Section 1 (Requirements Clarification).

The probe is **optional for trivial changes** -- skip for <10 lines with no assumptions. But for any plan where the developer said "I think..." or "probably..." about the current state, the probe converts guesswork into evidence.

**v5 enhancement**: After the probe, ALL KPIs in the Section 12 KPI Dashboard must have `Confidence: MEASURED`. No UNKNOWN or ESTIMATED values allowed at plan approval time. The probe's job is to fill the "Before" column with real numbers.

### Post-Validation: Closing the Loop (Section 13)

The Pre-Validation Probe has a counterpart: **Section 13 (Post-Validation)**. After implementation, re-measure the same KPIs from Section 12 and compare:

```markdown
## 13. Post-Validation

| KPI            | Before (Measured) | After (Actual) | Target | Verdict |
|----------------|-------------------|----------------|--------|---------|
| [from Sec 12]  | [from Sec 0.1]    | [re-measured]  | [goal] | PASS    |
```

This closes the loop: Section 0.1 grounds the plan in data before approval; Section 13 confirms the data changed as expected after implementation. Without it, success is claimed without re-measuring.

### Adding to the Rules File

To make the probe part of your planning workflow, add the adoptable rule file:

**File**: `~/.claude/rules/planning/pre-validation.md` (available in the template directory)

This rule file reminds Claude to verify assumptions before approving plans. It is loaded automatically alongside the plan checklist rule.

---

## Adoptable Template

### Rule File

Save to `~/.claude/rules/planning/pre-validation.md`:

```markdown
# Pre-Validation Probe - Before Approving Plans

**Scope**: ALL plans with verifiable assumptions
**Enforcement**: Run DURING plan mode, BEFORE approving

---

## Core Rule

**Every plan rests on assumptions about reality. Before approving any plan,
verify those assumptions with real evidence -- file reads, grep, curl, test
runs, whatever proves the current state. Only then approve.**

## When to Run

Include when the plan assumes a problem exists, assumes current behavior,
or depends on unverified technical facts. Skip for trivial changes (<10 lines)
or when all assumptions are already confirmed.

## Probe Template

| #   | Assumption         | Test              | Result           | Verdict             |
| --- | ------------------ | ----------------- | ---------------- | ------------------- |
| 1   | [what you assumed] | [how you checked] | [what you found] | CONFIRMED/DISPROVED |

**Decision**: If >50% disproved, reject and re-plan.
If feasibility check returns NO-GO, stop and redesign.
```

---

## Anti-Patterns

These are the most common ways the probe gets skipped or misused:

| Anti-Pattern                                                        | Why It Fails                              | Correct Approach                       |
| ------------------------------------------------------------------- | ----------------------------------------- | -------------------------------------- |
| "I'll measure after implementing"                                   | No before/after comparison possible       | Measure BEFORE implementing            |
| "The baseline is probably ~96%"                                     | Estimates are often wrong                 | Run the actual check                   |
| "Skip probe, plan is obvious"                                       | Even obvious plans have wrong assumptions | 2 minutes is cheap insurance           |
| "Probe found the problem doesn't exist, but let's implement anyway" | Solving a non-problem wastes time         | Stop and re-evaluate                   |
| "Only curl/SQL counts as a probe"                                   | Any verifiable check counts               | grep, file read, test run -- all valid |

---

## Real-World Wins

These examples illustrate the kind of waste the probe prevents:

1. **Planned a debounce fix. Read the component. Debounce already existed.** Plan cancelled in 30 seconds instead of 2 hours of unnecessary refactoring.

2. **Planned a performance fix targeting 3s page load. Ran Lighthouse. Page load was 1.2s.** The reported symptom was caused by a slow network, not the application. Plan redirected to the actual issue.

3. **Planned to refactor a function called from "many files." Ran grep. 3 callers.** The refactoring scope was 80% smaller than assumed. Plan simplified from a multi-day effort to a 30-minute edit.

4. **Planned an API migration to v3. Curl'd the v3 endpoint. 404.** The v3 API did not exist yet. Plan blocked before any code was written.

---

## Design Decisions

**Why is the probe optional, not enforced by the hook?**
A blocking gate for the probe would require every plan to include it -- even trivial 5-line changes with no assumptions to verify. The overhead would lead to developers bypassing it with empty "all confirmed" sections, defeating the purpose. Making it optional but recommended means it gets used when it matters.

**Why during planning, not after implementation?**
The probe's entire value is in catching wrong assumptions before code is written. After implementation, you have already paid the cost. The probe is a pre-flight check, not a post-mortem.

**Why so small (1-8 checks)?**
The probe competes with the urge to "just start coding." If it takes 30 minutes, no one will do it. At 2-5 minutes, the friction is low enough that it becomes a habit. The goal is to catch the one fundamentally wrong assumption, not to verify everything.

**Why any tool counts?**
Restricting the probe to specific tools (only curl, only SQL) would miss the most common checks: reading a file, running grep, checking a config. The probe is tool-agnostic because assumptions come in all shapes.

---

## Key Takeaways

1. **Plans fail because of wrong assumptions, not bad code.** The probe catches the assumptions before you write the code.
2. **Any tool counts.** File reads, grep, curl, test runs, log analysis -- whatever produces verifiable evidence.
3. **Keep it small.** 1-8 checks, 2-10 minutes. The probe is a smoke test, not a full test suite.
4. **A disproved assumption is a win, not a failure.** Discovering the truth during planning is 10-100x cheaper than discovering it during implementation.
5. **The question is simple.** "What does this plan ASSUME is true, and can I check it right now?"

---

**Previous**: [52: UI/UX Best Practices Rules](52-ui-ux-best-practices-rules.md)
