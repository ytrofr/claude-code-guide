---
layout: default
title: "Plan Mode and Plan Checklist"
parent: "Part II — Workflow"
nav_order: 1
redirect_from:
  - /docs/guide/45-plan-mode-checklist.html
  - /docs/guide/45-plan-mode-checklist/
  - /docs/guide/53-pre-validation-probe.html
  - /docs/guide/53-pre-validation-probe/
---

# Plan Mode and Plan Checklist

Plan mode is Claude Code's design-before-implementation primitive. The model produces a written plan -- no edits, no commits -- and waits for you to approve it before touching any files. Used well, it catches wrong assumptions, missing requirements, and over-engineering before a single line of code is written. Used poorly, it produces verbose essays that still miss the parts that matter: testing, observability, file scope, and measured KPIs.

This chapter defines **what a complete plan looks like**: the 14 mandatory sections, the pre-validation probe that grounds plans in data, the TL;DR with an explicit KPI dashboard, and the post-validation template that closes the loop after implementation.

**Purpose**: One reference for every plan in every project
**Difficulty**: Beginner (to read) / Intermediate (to enforce)
**Applies to**: `EnterPlanMode`, the `/plan` permission mode, any pre-implementation design document

---

## When to Enter Plan Mode

Enter plan mode when **at least one** of these is true:

- The task is non-trivial (3+ files, 2+ independent steps, or crosses a module boundary)
- You're uncertain about the root cause or the right approach
- The change is destructive or hard to reverse (DB migration, schema change, feature flip)
- Multiple valid approaches exist and you want to pick one before committing
- The user asked you to plan first

Skip plan mode for trivial single-file edits, doc typos, or fixes where the root cause is already traced and the edit is under ~10 lines.

**How to enter**: press `Shift+Tab` to cycle modes, pass `--permission-mode plan` on startup, use the `EnterPlanMode` tool, or invoke a `/plan`-prefixed skill. When plan mode is active, the model can read files and search but cannot write or edit. The plan itself is output text that you review and either accept (exits plan mode to implementation) or reject (returns to planning).

---

## The 14 Mandatory Sections

Every plan contains these sections, in this order, with no placeholders. Section 0.1 runs first because everything else depends on what it discovers. Section 12 (TL;DR) is written **last** but always appears as the final content section, immediately before Section 13.

| # | Section | Purpose | Blocking? |
|---|---------|---------|-----------|
| 0.1 | Pre-Validation Probe | Verify assumptions with real evidence | YES |
| 1 | Requirements Clarification | Confirm scope and expected behavior | NO |
| 2 | Existing Code Check | Don't rebuild what's already there | NO |
| 3 | Over-Engineering Prevention | Compare with simpler alternatives | NO |
| 4 | Best Practices Compliance | KISS / DRY / SOLID / YAGNI / Security | NO |
| 5 | Modular Architecture | Routes / controllers / services touched | NO |
| 6 | Visual Diagram (if 3+ components) | Show relationships at a glance | NO |
| 7 | Documentation Plan | Entries, skills, status files | NO |
| 8 | E2E Testing Plan | Unit / integration / E2E / manual | NO |
| 9 | Debugging and Observability | Logging, health checks, monitoring | NO |
| 10 | File Change Summary | File / Action / Before / After / Why | NO |
| 11 | Modularity Enforcement | File < 500L, function < 50L, layer separation | YES |
| 12 | TL;DR with KPI Dashboard | Confidence + Before/After + Scope + KPIs | NO |
| 13 | Post-Validation | Template filled after implementation | NO |

Two sections are **blocking gates**: 0.1 and 11. If the pre-validation probe shows >50% of assumptions disproved, reject the plan and re-plan. If the modularity check shows a file will exceed 500 lines or business logic leaks into a route, redesign before proceeding.

---

## Section 0.1 — Pre-Validation Probe

Plans fail more often from wrong assumptions than from bad code. The probe is a 2-10 minute smoke test of the plan's assumptions using whatever tools produce verifiable evidence: `grep`, `curl`, file reads, test runs, SQL queries, log analysis.

The question it answers: **"What does this plan ASSUME is true, and can I check it right now?"**

### Probe template

```markdown
## 0.1 Pre-Validation Probe

**Status**: PASSED / FAILED / PARTIAL
**Run at**: YYYY-MM-DD HH:MM UTC

### Assumptions Tested

| # | Assumption | Test | Result | Verdict | Confidence |
|---|------------|------|--------|---------|------------|
| 1 | Endpoint returns 500 on empty input | curl -X POST .../api -d '{}' | Returns 400 | DISPROVED | HIGH |
| 2 | Function called from 12+ files | grep -r "fn(" src/ | wc -l | 3 files | DISPROVED | HIGH |
| 3 | Cache TTL is 24h | grep TTL src/services/cache | TTL = 3600 | CONFIRMED | HIGH |

### Feasibility (if approach is unproven)

| Check | Result | Go/No-Go |
|-------|--------|----------|
| CSS grid handles RTL layout | 3 RTL components already use grid | GO |
| New API v3 endpoint exists | curl returns 404 | NO-GO |

### Probe Verdict

- All critical assumptions confirmed OR plan adjusted: YES / NO
- No feasibility blockers: YES / NO
- **VERDICT**: GO / NO-GO
```

### Probe size

Keep it proportional. 1-3 checks for simple plans (1-3 files), 3-5 for standard plans (3-7 files), 5-8 for complex plans (7+ files). The probe is a smoke test, not a full test suite.

### When the probe fails

| Failure | Action |
|---------|--------|
| Assumption DISPROVED | Adjust the plan to match reality |
| Feasibility NO-GO | Stop. Redesign the approach. |
| >50% disproved | Reject the plan entirely; re-plan with corrected understanding |
| Baseline better than expected | Recalibrate targets; the fix may not be worth the effort |

A disproved assumption is not a failure -- it's the probe working correctly. Discovering the truth in 2 minutes is 10-100x cheaper than discovering it after 4 hours of implementation.

### Skip rule

Section 0.1 is **required by default**. Skip only when all three hold: (a) the change is trivial (<10 lines, single file), (b) all KPIs in Section 12 are already MEASURED with cited sources, (c) no unverified assumptions remain.

---

## Sections 1-11 — Design Detail

Each section below is one line in the plan. Full templates and examples are in the `plan-checklist` skill -- invoke it during plan mode for copy-pasteable scaffolding.

### 1. Requirements Clarification

Confirm scope, constraints, expected behavior. Skip only if instructions are truly unambiguous. A 30-second clarifying question prevents hours of wrong-direction work.

### 2. Existing Code Check

Search for what already exists before proposing new code. List what you searched, what you found, what can be reused, and what genuinely needs to be new.

### 3. Over-Engineering Prevention

Table format: proposed approach vs simpler alternative. Lines of code, files touched, new dependencies. Can this be solved with under 50 lines? Zero new deps?

### 4. Best Practices Compliance

KISS, DRY, SOLID, YAGNI, OWASP top 10 security. A checklist, not an essay.

### 5. Modular Architecture

Which routes, controllers, services are affected. Every file under 500 lines. Every module single-responsibility. No business logic in entry files or route handlers.

### 6. Visual Diagram

Include when 3+ components interact, architecture changes, or state transitions exist. Skip for simple changes. ASCII or Mermaid is fine -- the goal is comprehension, not aesthetics.

### 7. Documentation Plan

What gets documented after implementation: entry file, updated status file, new skill if the pattern repeats, rule if the lesson is enforceable.

### 8. E2E Testing Plan

Unit tests (count and scope), integration tests (endpoints), E2E tests (user flows), manual verification commands. Vague "add tests" plans produce no tests.

### 9. Debugging and Observability

What to log, at what level, what errors are caught, which health checks exist, what to watch post-deploy, rollback plan.

### 10. File Change Summary

Pipe-delimited table: File | Action | Before | After | Why. Each row is a mini-story. The reviewer sees the transformation at a glance, not just a list of files.

### 11. Modularity Enforcement (blocking gate)

Four sub-checks:

- **File Size Gate**: No file exceeds 500 lines after changes. No function exceeds 50 lines.
- **Layer Separation Gate**: Routes stay routing-only. Controllers stay request/response formatting. Services hold business logic.
- **Extraction Gate**: Repeated logic (2+ occurrences) extracted. Complex conditionals (3+ branches) extracted. Configuration externalized.
- **God File Prevention**: Entry files under 500 lines. No single service handles 2+ domains.

If any check fails, stop and redesign. Show before/after: "File X will be 620 lines → split into X.js (320) + Y-helper.js (300)".

### Per-Fix BEFORE/AFTER

Every fix inside the implementation detail section starts with two one-liners:

```markdown
### Fix 1: Session cleanup on logout
**BEFORE**: Logout endpoint returns 200 but session token remains valid — user stays logged in.
**AFTER**: Logout endpoint invalidates session token in Redis — user is fully logged out.
```

The reviewer instantly sees what's broken and what the fix achieves without reading the full implementation.

---

## Section 12 — TL;DR with KPI Dashboard

Section 12 is written **last** and always appears as the final content section, immediately before Section 13. It has four mandatory sub-sections:

### 12a. Overall Plan Confidence

One line: **HIGH / MEDIUM / LOW**, one-line rationale, and the biggest risk.

Honest confidence rules:

- `HIGH` is forbidden if any row in Section 0.1 or Section 10 is rated `LOW`
- `HIGH` is forbidden if any KPI in the dashboard is `UNKNOWN`
- Anything below `HIGH` must cite a one-line rationale

### 12b. Problem (Before) / Solution (After) tables

One row per fix. The transformation shown as two tables side-by-side:

```markdown
### Problem (Before)

| # | What's broken                      | Impact                        |
|---|------------------------------------|-------------------------------|
| 1 | Logout doesn't invalidate session  | Users stay logged in          |
| 2 | No cleanup on token expiry         | Stale sessions pile up in DB  |

### Solution (After)

| # | Fix                                | Result                        |
|---|------------------------------------|-------------------------------|
| 1 | Invalidate session on logout       | User fully logged out         |
| 2 | TTL-based cleanup cron             | Stale sessions auto-cleaned   |
```

### 12c. Scope

One sentence: approximate lines, files, new services, new dependencies. For example: *~45 lines across 3 files. 1 new service, no new deps.*

### 12d. KPI Dashboard (pipe-delimited table, never prose)

```markdown
| Status | KPI                | Before    | After (Target) | Source      | Confidence | Green | Yellow | Red   |
|--------|--------------------|-----------|----------------|-------------|------------|-------|--------|-------|
| 🔴     | Sessions cleaned   | 0/day     | 100%/day       | DB query    | MEASURED   | 100%  | >90%   | <50%  |
| 🔴     | Logout invalidates | NO        | YES            | curl test   | MEASURED   | YES   | --     | NO    |
```

KPI rules:

- **Status**: emoji only (🟢 🟡 🔴 ⬜), never text
- **2-5 KPIs** per plan, all with green/yellow/red thresholds
- **Source**: where the Before number came from (DB query, test run, log grep)
- **Confidence**: `MEASURED` after the Section 0.1 probe. `UNKNOWN` and `ESTIMATED` are forbidden at plan approval time.
- **Always a pipe-delimited table**, never prose, never bullets

A reader should understand the full plan from Section 12 alone in under 10 seconds.

---

## Section 13 — Post-Validation Template

Section 13 is a template at plan time. It gets filled in **after** implementation. The same KPIs from Section 12 are re-measured and compared.

```markdown
## 13. Post-Validation

**Status**: PASSED / PARTIAL / FAILED
**Run at**: YYYY-MM-DD HH:MM UTC

### KPI Re-Measurement

| KPI                | Before (Measured) | After (Actual) | Target | Verdict |
|--------------------|-------------------|----------------|--------|---------|
| Sessions cleaned   | 0/day             | 100%/day       | 100%   | PASS    |
| Logout invalidates | NO                | YES            | YES    | PASS    |

### Regression Check

| Check               | Result         |
|---------------------|----------------|
| Existing tests pass | YES (142/142)  |
| No new warnings     | YES            |

### Post-Validation Verdict

- **VERDICT**: PASS / PARTIAL (list what's left) / FAIL (stop, re-plan)
```

Without post-validation, success is claimed without re-measuring. Section 0.1 grounds the plan in data; Section 13 confirms the data actually changed as expected.

---

## Skill Integration Gates

Four skills are blocking at specific phases of the lifecycle. The plan must either invoke them or explicitly justify the skip.

| Phase | Skill | When to run |
|-------|-------|-------------|
| Pre-plan | `/brainstorming` | Features or behavior changes — skip only for a bug fix with a traced root cause |
| Pre-impl | `/tdd` | Section 8 specifies TDD-first or justifies the skip |
| Post-impl | `/verify` | Section 13 runs `/verify` or equivalent |
| Post-deploy | `/canary` | Section 13 when the plan includes a deploy |

See the [verify / canary chapter](04-verify-canary.md) for how `/verify` and `/canary` work together as the post-implementation gate.

---

## Modularity Gates

These thresholds apply inside Section 11 (blocking) and should be checked again after implementation:

| Check | Threshold | If violated |
|-------|-----------|-------------|
| File size | < 500 lines | Include split plan with before/after line counts |
| Function size | < 50 lines | Extract to named helper |
| Layer separation | Routes = routing only | Move logic into services |
| Entry file | < 500 lines | Delegation only; move logic out |
| Single file per domain | 1 service = 1 domain | Split by domain |

A modular plan that's slightly more complex is always preferred over a monolithic plan that's slightly simpler. The real-world cost of modularity violations (hours of refactoring later) exceeds the cost of redesigning now (minutes).

---

## Sideways Detection — When to Re-Plan

A plan goes sideways when the underlying assumptions break mid-execution. Watch for these triggers:

| Trigger | Action |
|---------|--------|
| 3+ failed attempts on the same bug | Stop. Build a tracer. Check if the bug is at a different layer. |
| Scope creep > 50% | Re-enter plan mode. The original scope is no longer honest. |
| Core assumption disproved | Re-plan from corrected understanding. |
| Blocked by external dependency | Replan around the block or stop until unblocked. |

The cheapest time to discover a plan is wrong is **during** planning. The next-cheapest is **at the first sideways trigger**. The most expensive is after merging and deploying.

---

## Honest Confidence Ratings

Three places in the plan carry confidence ratings: Section 0.1 rows, Section 10 rows, and the Section 12 Overall line. All three follow the same rule: **anything below HIGH cites a one-line rationale, and HIGH without evidence is forbidden**.

Examples of honest ratings:

- *HIGH — probe confirmed all 3 assumptions; changes are additive to a well-tested module.*
- *MEDIUM — probe confirmed 2/3 assumptions; assumption #3 couldn't be verified without staging access.*
- *LOW — new code path; no integration tests yet; will rely on manual verification and `/canary`.*

The dishonest version: *HIGH* with no rationale, applied reflexively to every plan. That's how plans with unverified assumptions get shipped.

---

## Enforcement: Hook on ExitPlanMode

There is no hook for plan mode *entry*, but there is one for plan *submission*. A `PreToolUse` hook on the `ExitPlanMode` tool can block submission if mandatory sections are missing:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "ExitPlanMode",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/plan-sections-gate.sh"
          }
        ]
      }
    ]
  }
}
```

The hook script:

1. Finds the most recently modified `.md` file in the plan directory
2. Checks for all 14 sections via flexible keyword matching
3. Validates the KPI dashboard is a pipe-delimited table
4. Validates each fix has `**BEFORE**:` and `**AFTER**:` lines
5. If missing or malformed, exits 2 (blocks submission) and prints what's wrong

Section detection uses keyword patterns, not exact header matches, so plans with slightly different headings still pass. A bypass comment `<!-- skip-plan-sections -->` allows plans that intentionally deviate.

### Plan file metadata

Every plan file starts with a metadata header immediately after the title:

```markdown
# Plan: Fix Authentication Bug

> **Plan file**: .claude/plans/wild-tickling-pretzel.md
> **Branch**: dev-Auth | **Created**: 2026-02-16 14:30 UTC
> **Topic**: Fix session expiry bug causing logout loops on mobile
> **Keywords**: auth, session, logout, mobile, cookie
```

Without metadata, plan files with random slug names (`wild-tickling-pretzel.md`) are impossible to triage. With it, plans are searchable by branch, topic, and keyword.

---

## Design Decisions

**Why 14 sections?** Fewer sections miss one of the common failure modes (missing tests, missing observability, missing file scope). More sections become unreadable and get skipped.

**Why is 0.1 blocking?** Plans built on wrong assumptions are the most expensive class of failure. A 2-minute probe catches them before implementation.

**Why is Section 11 blocking?** Modularity violations compound. Fixing a 600-line file after merge costs hours; redesigning during plan mode costs minutes.

**Why write Section 12 last?** The Problem/Solution tables and KPI dashboard can only be accurate after all detail sections are complete. Writing it first produces summaries that don't match the actual plan.

**Why pipe-delimited KPIs, not prose?** Prose KPIs drift over time. Tables force you to commit to Status, Before, After, Source, Confidence, and thresholds — all of which are re-measurable in Section 13.

**Why per-fix BEFORE/AFTER?** A plan that says "fix the session bug" tells you nothing. "BEFORE: logout returns 200 but session stays valid. AFTER: logout invalidates the token in Redis" tells you everything in two lines.

**Why optional brainstorming / TDD gates?** Blocking brainstorming on a traced bug fix is annoying; blocking TDD on a prototype spike is wasteful. The rule: run the skill or justify the skip in the plan. Silent skips are forbidden.

---

## Key Takeaways

1. **14 mandatory sections**: 0.1, 1-11, 12, 13. Section 12 written last but positioned last; Section 13 template present at plan time.
2. **Pre-validation probe is blocking.** Convert all KPIs from UNKNOWN / ESTIMATED to MEASURED before approval.
3. **KPI dashboard is a pipe-delimited table, always.** Emoji status only. 2-5 KPIs, each with green/yellow/red thresholds.
4. **Modularity is blocking.** File < 500L, function < 50L, layer separation. Redesign during planning, not after merge.
5. **Post-validation closes the loop.** Re-measure the same KPIs from Section 12; compare; PASS/PARTIAL/FAIL.
6. **Skill integration.** Brainstorming pre-plan, TDD pre-impl, `/verify` post-impl, `/canary` post-deploy. Run them or justify the skip.
7. **Sideways triggers.** 3+ failed attempts, >50% scope creep, core assumption false, blocked by external dep → re-plan.
8. **Honest confidence.** HIGH requires evidence. Below HIGH cites a one-line rationale. Default to lower confidence when uncertain.
9. **Enforcement via `ExitPlanMode` hook.** Blocks submission when sections are missing or the KPI table is malformed.
10. **Plan file metadata.** Branch, created-at, topic, keywords — so plans with random slug names are searchable.

For the full copy-pasteable templates and section-by-section examples, invoke the `plan-checklist` skill during plan mode.
