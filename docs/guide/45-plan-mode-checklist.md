---
layout: default
title: "Plan Mode Quality Checklist - Enforcing 14 Mandatory Sections"
description: "Automatically enforce comprehensive plan quality with a 14-section checklist covering pre-validation probe, requirements, existing code search, over-engineering prevention, best practices, modular architecture, visual diagrams, documentation, E2E testing, observability, file change summary, modularity enforcement, TL;DR with KPI Dashboard tables, and post-validation. Includes plan file metadata, per-fix BEFORE/AFTER requirements, and data validation gates."
---

# Chapter 45: Plan Mode Quality Checklist

Claude Code's plan mode is powerful for designing implementations before writing code. But plans often miss critical sections -- testing strategy, documentation, debugging, and verifying assumptions. This chapter shows how to enforce a mandatory checklist that every plan must include, using rules files and skills.

**Purpose**: Ensure every plan covers 14 quality dimensions automatically
**Difficulty**: Beginner
**Time**: 15 minutes to set up

---

## The Problem

Plans created in plan mode tend to focus on "what to build" but skip:

- Clarifying requirements (assuming instead of asking)
- Checking if code already exists (rebuilding what's there)
- Over-engineering assessment (building too much)
- Testing strategy (vague "add tests later")
- Documentation plan (forgotten entirely)
- Observability (no logging or debugging strategy)
- Listing affected files (scope unclear until implementation)
- Summarizing the plan concisely (reader can't scan quickly)
- Verifying assumptions before building (plans built on wrong assumptions fail)

There's no built-in plan template in Claude Code. No hook event fires on plan mode entry. But we can solve this with two complementary approaches.

---

## Enforcement: PreToolUse Hook on ExitPlanMode

While there's no hook event for plan mode _entry_, there **is** one for plan _submission_. The `ExitPlanMode` tool fires when Claude tries to submit a plan for user approval. A `PreToolUse` hook on this tool can block submission if mandatory sections are missing.

**File**: `~/.claude/hooks/plan-sections-gate.sh`

The hook script:

1. Finds the most recently modified `.md` file in `~/.claude/plans/`
2. Checks for 11 mandatory sections using flexible keyword matching
3. Validates quality: KPI table presence, per-fix BEFORE/AFTER markers
4. If any sections are missing, prints which ones and exits with code 2 (blocks ExitPlanMode)
5. If quality warnings exist but all sections present, prints warnings and exits 0
6. If all present with no warnings, exits 0 (allows submission)

**Register in** `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "ExitPlanMode",
        "hooks": [
          {
            "type": "command",
            "command": "/home/user/.claude/hooks/plan-sections-gate.sh",
            "statusMessage": "Validating plan sections..."
          }
        ]
      }
    ]
  }
}
```

**Section detection** uses flexible patterns -- not exact header matches:

| Section              | Grep Pattern (any match = pass)                                |
| -------------------- | -------------------------------------------------------------- |
| 1: Existing Code     | `existing code\|reuse check\|searched.*found`                  |
| 2: Over-Engineering  | `over.engineering\|simplif.*alternative\|complexity`           |
| 3: Best Practices    | `best practice\|KISS\|DRY\|SOLID\|YAGNI`                       |
| 4: Architecture      | `architecture\|routes.*controllers\|layer.*separation`         |
| 5: Documentation     | `documentation plan\|/document\|entry file`                    |
| 6: Testing           | `testing\|test plan\|verification\|e2e\|unit test`             |
| 7: Debugging         | `debug\|logging\|observability\|monitor\|health check`         |
| 8: Files Affected    | `files affected\|file change\|files changed`                   |
| 9: TL;DR             | `tl;dr\|problem.*before\|solution.*after`                      |
| 10: Modularity       | `modularity\|file size.*gate\|god file\|single responsibility` |
| 11: Post-Validation  | `post.validation\|post.implementation.*validation\|## 13`      |

The hook also performs **quality checks** (non-blocking warnings):

| Quality Check         | What It Validates                                                  |
| --------------------- | ------------------------------------------------------------------ |
| KPI Table             | KPI Dashboard exists as a pipe-delimited table with proper columns |
| Per-Fix BEFORE/AFTER  | Each `### Fix N` heading has `**BEFORE**:` and `**AFTER**:` lines  |

**Bypass**: Add `<!-- skip-plan-sections -->` anywhere in the plan file to skip validation. Useful for non-standard plans or quick prototyping.

**Install**:

```bash
# Copy the hook
cp template/.claude/hooks/plan-sections-gate.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/plan-sections-gate.sh

# Add the PreToolUse entry to ~/.claude/settings.json (see JSON above)
```

---

## Plan File Metadata

Plan files get random names like `wild-tickling-pretzel.md`. Without metadata, you can't tell what a plan is about, which branch it targets, or when it was created.

**File**: `~/.claude/rules/planning/plan-link.md`

Every plan file must include this metadata header immediately after the title:

```markdown
# Plan: Fix Authentication Bug

> **Plan file**: /home/user/.claude/plans/wild-tickling-pretzel.md
> **Branch**: dev-Auth | **Created**: 2026-02-16 14:30 UTC
> **Topic**: Fix session expiry bug causing logout loops on mobile
> **Keywords**: auth, session, logout, mobile, cookie
```

| Field     | Purpose                                 | Format                    |
| --------- | --------------------------------------- | ------------------------- |
| Plan file | Clickable path in VS Code terminal      | Full absolute path        |
| Branch    | Which branch this plan targets          | Git branch name           |
| Created   | When the plan was written               | ISO 8601 with time + UTC  |
| Topic     | 1-sentence summary of the plan's goal   | Plain text, max ~80 chars |
| Keywords  | Searchable terms for finding plan later | 3-6 comma-separated terms |

This makes plans searchable:

```bash
grep -rl "auth" ~/.claude/plans/         # Find by keyword
grep -rl "dev-Auth" ~/.claude/plans/     # Find by branch
grep -rl "2026-02" ~/.claude/plans/      # Find by date
```

### Plan Directory Configuration

Customize where plan files are stored:

```json
// .claude/settings.json
{
  "plansDirectory": ".claude/plans"
}
```

Default: `.claude/plans/` in the project root.

---

## Solution: Two Complementary Approaches

### Approach A: Rules File (Passive, Always in Context)

Create a rules file that's auto-loaded every message. When Claude enters plan mode, the 14-section template is already in context.

**File**: `~/.claude/rules/planning/plan-checklist.md`

```markdown
# Plan Mode Checklist - MANDATORY for Every Plan

**Scope**: ALL plans in ALL projects
**Enforcement**: Every plan MUST include ALL 14 sections below

---

## 14 Mandatory Plan Sections (0.1, 1-11, 12, 13)

### Section 0.1: Pre-Validation Probe (BLOCKING GATE)

Verify assumptions with real evidence BEFORE plan approval.
All KPIs must be MEASURED after the probe (no UNKNOWN/ESTIMATED).

### Section 1: Requirements Clarification

Ask clarifying questions BEFORE planning. Don't assume -- confirm scope,
constraints, and expected behavior. Skip only if instructions are unambiguous.

### Section 2: Existing Code Check

Before proposing ANY new code, search for existing implementations.

### Section 3: Over-Engineering Prevention

Compare proposed approach with simpler alternatives. Table format.

### Section 4: Best Practices Compliance

KISS/DRY/SOLID/YAGNI/Security checklist.

### Section 5: Modular Architecture

Which routes, controllers, services are affected. No logic in entry files.

### Section 6: Visual Diagram (when 3+ components)

### Section 7: Documentation Plan

Run /document after implementation. Update status files.

### Section 8: E2E Testing Plan

Unit tests, integration tests, E2E tests, baseline regression, manual verification.

### Section 9: Debugging and Observability

What to log, error handling, health checks, monitoring, rollback plan.

### Section 10: File Change Summary

Columns: File, Action, Before, After, Why. Each row is a mini-story.

### Section 11: Modularity Enforcement (BLOCKING GATE)

File Size Gate, Layer Separation Gate, Extraction Gate, God File Prevention.
Plan is REJECTED if any check fails.

### Per-Fix BEFORE/AFTER (in implementation details)

Every fix MUST start with:
**BEFORE**: One sentence — current broken behavior.
**AFTER**: One sentence — fixed behavior.

### Section 12: TL;DR + KPIs (WRITE LAST — ALWAYS the final content section)

Problem (Before) table + Solution (After) table + KPI Dashboard table.
KPI Dashboard MUST be a pipe-delimited table. Never prose.

### Section 13: Post-Validation (template at plan time, filled after implementation)

Re-measures the SAME KPIs from Section 12 after implementation.
```

**Cost**: ~1,400 tokens per message (loaded even outside plan mode)
**Benefit**: Zero manual effort -- the template is always available

### Approach B: User-Invocable Skill (Active, On-Demand)

Create a `/plan-checklist` skill with the full detailed template, anti-patterns, and examples. Loaded only when invoked.

**File**: `~/.claude/skills/plan-checklist-skill/SKILL.md`

```yaml
---
name: plan-checklist-skill
description: "Generate a 14-section plan checklist with pre-validation probe, requirements, existing code, over-engineering, best practices, architecture, diagrams, docs, testing, observability, files, modularity, TL;DR with KPI tables, and post-validation. Use when entering plan mode, creating plans, or '/plan-checklist'."
user-invocable: true
argument-hint: "[feature-description]"
---
```

The skill body contains the full plan template with:

- Step-by-step workflow (search existing code, then write plan, then validate)
- Detailed section templates with placeholder syntax
- Anti-patterns table (what NOT to do)
- Success criteria checklist

**Cost**: Zero tokens until invoked (only description counts toward budget)
**Benefit**: Full detailed template with examples when you need it

---

## How They Work Together

| Scenario                      | What Fires                                              |
| ----------------------------- | ------------------------------------------------------- |
| Enter plan mode normally      | **Rules file** -- 14 sections guide the plan structure  |
| Type `/plan-checklist`        | **Skill** -- full template with examples loads          |
| Say "let's plan this feature" | **Both** -- rules always there, skill may auto-match    |

The rules file is the safety net (always present). The skill is the power tool (detailed guidance when needed).

---

## The 14 Mandatory Sections

### 0.1. Pre-Validation Probe (Blocking Gate)

```markdown
## 0.1 Pre-Validation Probe

**Status**: PASSED / FAILED / PARTIAL
**Run at**: YYYY-MM-DD HH:MM UTC

### Assumptions Tested

| #   | Assumption                 | Test              | Result           | Verdict               |
| --- | -------------------------- | ----------------- | ---------------- | --------------------- |
| 1   | [what you assumed is true] | [how you checked] | [what you found] | CONFIRMED / DISPROVED |

### Feasibility (if approach is unproven)

| Check          | Result     | Go/No-Go   |
| -------------- | ---------- | ---------- |
| [can we do X?] | [evidence] | GO / NO-GO |

### Probe Verdict

- [ ] All critical assumptions confirmed (or plan adjusted)
- [ ] No feasibility blockers
- **VERDICT**: GO / NO-GO
```

**Why**: Plans fail when they are built on wrong assumptions about reality. Before approving a plan, verify its assumptions with real evidence -- file reads, grep, curl, test runs, log analysis, whatever proves the current state. A 2-minute probe catches what hours of coding cannot fix retroactively.

**When to include**: Include this section when the plan assumes a problem exists, assumes current behavior X, or depends on a technical fact that can be verified right now. Skip it for trivial changes (under 10 lines, single file) or when all assumptions are already confirmed.

**When a probe fails**: If an assumption is disproved, adjust the plan before proceeding. If more than half the assumptions are wrong, reject the plan entirely and re-plan. If a feasibility check returns NO-GO, stop and redesign the approach.

For a full standalone guide on the Pre-Validation Probe pattern, see [Chapter 53: Pre-Validation Probe](53-pre-validation-probe.md).

### 1. Requirements Clarification

```markdown
## 1. Requirements Clarification

- **Clarified with user**: [yes -- summary / skipped -- instructions unambiguous]
- **Scope**: [what's included and excluded]
- **Constraints**: [performance, compatibility, deadlines]
- **Expected behavior**: [input -> output, edge cases]
```

**Why**: A 30-second clarifying question prevents hours of wrong-direction work.

### 2. Existing Code Check

```markdown
## 2. Existing Code Check

- **Searched**: [grep patterns, glob patterns, skills checked]
- **Found**: [existing code that can be reused]
- **Reuse plan**: [how existing code will be leveraged]
- **New code needed**: [only what doesn't exist yet]
```

**Why**: Prevents rebuilding what already exists. In practice, checking first saves 1-3 hours per task.

### 3. Over-Engineering Prevention

```markdown
## 3. Over-Engineering Check

| Aspect | Proposed | Simpler Alternative | Decision |
| ------ | -------- | ------------------- | -------- |
| Code   | X lines  | Y lines             | [why]    |
| Files  | X new    | Y new               | [why]    |
| Deps   | X new    | 0                   | [why]    |

- Can this be solved with <50 lines? [yes/no + justification]
- Zero new dependencies? [yes/no + justification for each]
```

**Why**: Real evidence -- a cron migration went from 150 lines to 30 lines (80% reduction, 77% cheaper) after applying this check.

### 4. Best Practices

```markdown
## 4. Best Practices

- [ ] KISS: Simplest solution that works
- [ ] DRY: No duplicated logic
- [ ] SOLID: Single responsibility per module
- [ ] YAGNI: No speculative features
- [ ] Security: No injection risks (OWASP top 10)
```

### 5. Modular Architecture

```markdown
## 5. Architecture

- Routes: [files affected, delegation only]
- Controllers: [files affected]
- Services: [files affected, core logic]
- Each file < 500 lines, single responsibility
```

### 6. Visual Diagram

Include when 3+ components interact, architecture changes, or state transitions exist. N/A for simple changes.

### 7. Documentation Plan

```markdown
## 7. Documentation

After implementation:

- [ ] Create entry/documentation for the work done
- [ ] Update project status
- [ ] Create skill if pattern repeats frequently
```

### 8. E2E Testing Plan

```markdown
## 8. Testing

- Unit tests: [what to test, expected count]
- Integration tests: [API endpoints to verify]
- E2E tests: [user flows to validate]
- Manual verification: [commands to run]
```

**Why**: Vague "add tests" plans produce no tests. Specific test plans with expected counts actually get implemented.

### 9. Debugging & Observability

```markdown
## 9. Debugging & Observability

- Logging: [what to log, at what level]
- Error handling: [how errors are caught]
- Health checks: [endpoints to verify]
- Monitoring: [what to watch post-deploy]
```

### Per-Fix BEFORE/AFTER (in implementation details)

Every fix in the plan's implementation details must start with a one-sentence BEFORE and AFTER:

```markdown
### Fix 1: Session cleanup on logout
**BEFORE**: Logout endpoint returns 200 but session token remains valid -- user stays logged in.
**AFTER**: Logout endpoint invalidates session token in Redis -- user is fully logged out.
```

**Why**: Makes the transformation crystal clear at the individual fix level. Reviewers instantly see what's broken and what the fix achieves without reading the full implementation.

### 10. File Change Summary

```markdown
## 10. Files Affected

| File                              | Action | Before                  | After                        | Why                     |
| --------------------------------- | ------ | ----------------------- | ---------------------------- | ----------------------- |
| `src/routes/auth.js`              | MODIFY | No logout endpoint      | Add POST /logout             | Session cleanup         |
| `src/services/session.service.js` | NEW    | N/A                     | Session invalidation service | Token cleanup logic     |
```

**Why**: The Before/After/Why columns make each row a mini-story. The reviewer sees the transformation at a glance, not just a list of files.

### 11. Modularity Enforcement (BLOCKING GATE)

```markdown
## 10. Modularity Enforcement

### File Size Gate

- [ ] No file exceeds 500 lines after changes (if it will, identify split points)
- [ ] No function/method exceeds 50 lines (if it will, extract to named function)
- [ ] Every NEW file has ONE clear responsibility (state it in 1 sentence per file)

### Layer Separation Gate

- [ ] Routes: ONLY routing + middleware wiring (zero business logic)
- [ ] Controllers: ONLY request parsing + response formatting (delegate to services)
- [ ] Services: ALL business logic lives here
- [ ] No database queries outside services/database layer
- [ ] No HTTP response formatting inside services

### Extraction Gate

- [ ] Repeated logic (2+ occurrences) extracted to shared module
- [ ] Complex conditionals (>3 branches) extracted to named function
- [ ] Configuration/constants extracted to config files (not inline)

### God File Prevention

- [ ] Entry file stays under 500 lines (delegation only)
- [ ] No single service file handles more than 1 domain
- [ ] Will ANY existing file exceed 500 lines after these changes? [yes/no]
  - If yes: MUST include split plan (before/after line counts)
```

**Why**: Unlike the other sections, this one is a **blocking gate** -- the plan is rejected if any check fails. It prevents the most common modularity violations: god files, logic in the wrong layer, and missing extractions. A modular plan that's slightly more complex is always preferred over a monolithic plan that's slightly simpler.

**Violation response**: If any check fails, stop and redesign. Show before/after: "File X will be 620 lines -> split into X.js (320) + Y-helper.js (300)".

### 12. TL;DR + KPIs (WRITE LAST -- ALWAYS the final content section)

Section 12 is written last but is always the final content section in the plan. It has three mandatory sub-sections:

**Problem (Before) / Solution (After) tables** -- one row per fix:

```markdown
## 12. TL;DR + KPIs

### Problem (Before)

| # | What's broken                      | Impact                        |
|---|------------------------------------|-------------------------------|
| 1 | Logout doesn't invalidate session  | Users stay logged in          |
| 2 | No session cleanup on token expiry | Stale sessions pile up in DB  |

### Solution (After)

| # | Fix                                | Result                        |
|---|------------------------------------|----- -------------------------|
| 1 | Add session invalidation on logout | User fully logged out         |
| 2 | Add TTL-based cleanup cron         | Stale sessions auto-cleaned   |

### Scope

~45 lines across 3 files. 1 new service, no new deps.

### KPI Dashboard

| Status | KPI               | Before    | After (Target) | Source      | Confidence | Green | Yellow | Red   |
|--------|--------------------|-----------|----------------|-------------|------------|-------|--------|-------|
| 🔴     | Sessions cleaned   | 0/day     | 100%/day       | DB query    | MEASURED   | 100%  | >90%   | <50%  |
| 🔴     | Logout invalidates | NO        | YES            | curl test   | MEASURED   | YES   | --     | NO    |
```

**KPI Rules**:
- **Status**: emoji only (🟢 🟡 🔴 ⬜), never text
- **2-5 KPIs** per plan, all need Green/Yellow/Red thresholds
- **Source**: WHERE the Before number came from (DB query, test run, log grep)
- **Confidence**: Must be `MEASURED` (with cited source) after Section 0.1 probe. No UNKNOWN or ESTIMATED allowed at plan approval time.
- **After (Target)**: What the KPI should become after implementation -- makes the delta obvious
- **Always a pipe-delimited table** -- never prose, never bullet points

**Why**: A reader should understand the full plan from this section alone in under 10 seconds. The Problem/Solution tables show the transformation at a glance. The KPI Dashboard grounds every claim in measurable data.

### 13. Post-Validation (template at plan time, filled after implementation)

Section 13 is a template included in the plan but filled after implementation. It re-measures the same KPIs from Section 12.

```markdown
## 13. Post-Validation

**Status**: PASSED / PARTIAL / FAILED
**Run at**: YYYY-MM-DD HH:MM UTC

### KPI Re-Measurement

| KPI               | Before (Measured) | After (Actual) | Target | Verdict |
|--------------------|-------------------|----------------|--------|---------|
| Sessions cleaned   | 0/day             | 100%/day       | 100%   | PASS    |
| Logout invalidates | NO                | YES            | YES    | PASS    |

### Regression Check

| Check                 | Result         |
|-----------------------|----------------|
| Existing tests pass   | YES (142/142)  |
| No new warnings       | YES            |

### Post-Validation Verdict

- **VERDICT**: PASS / PARTIAL (list what's left) / FAIL (stop, re-plan)
```

**Why**: Without post-validation, success is claimed without re-measuring. The same KPIs that justified the plan must be re-measured after implementation. This closes the loop: Section 0.1 (pre-validation) grounds the plan in data; Section 13 (post-validation) confirms the data changed as expected.

---

## Validation: Does It Work?

After setting up both files, test by entering plan mode for any task. The plan output should contain all 14 sections with real content -- not placeholders.

**Quick validation**:

1. Enter plan mode (`Shift+Tab` or `--permission-mode plan`)
2. Give a simple task
3. Check the plan file -- all sections should appear (Section 0.1 is optional for trivial changes)
4. Each section should have real content from actual codebase exploration
5. Verify the plan file has the metadata header (branch, timestamp, topic, keywords)
6. Verify Section 11 (Modularity) has all 4 sub-gates filled with real assessments
7. Verify Section 12 (TL;DR) has Problem/Solution tables AND a KPI Dashboard table
8. Verify each fix has `**BEFORE**:` and `**AFTER**:` one-liners
9. Verify Section 13 (Post-Validation) template is present with KPI rows matching Section 12
10. For plans with verifiable assumptions, confirm Section 0.1 (Pre-Validation Probe) is present and shows CONFIRMED/DISPROVED verdicts

---

## Design Decisions

**Why rules file instead of CLAUDE.md?**
Rules files in `~/.claude/rules/` are auto-discovered and keep CLAUDE.md lean. They also apply across all projects.

**Why ~1,400 tokens is acceptable**:
The rules file costs ~1,400 tokens per message. With a 200k context window, that's 0.7%. The value of preventing missed testing/documentation in every plan far outweighs the cost.

**Why a PreToolUse hook on ExitPlanMode?**
A `PreToolUse` hook with `exit 2` actually blocks the tool call. Unlike `UserPromptSubmit` hooks (informational only), this prevents plan submission until all sections are present. The rules file guides plan _creation_; the hook enforces plan _completeness_.

**Why both approaches?**
The rules file is a lightweight always-on reminder. The skill provides the full detailed template when you want comprehensive guidance. Different situations call for different levels of detail.

**Why is TL;DR always the last section?**
Section 12 (TL;DR) is written last and positioned last because it must reflect everything above it. The Problem/Solution tables and KPI Dashboard can only be accurate after all detail sections are complete. This also ensures consistent placement -- the reader always knows where to find the summary.

**Why per-fix BEFORE/AFTER?**
A plan that says "fix the session bug" tells you nothing about the transformation. "BEFORE: logout returns 200 but session stays valid. AFTER: logout invalidates the token in Redis" tells you everything in two lines.

**Why a Post-Validation section?**
Section 0.1 grounds the plan in data before approval. Section 13 closes the loop after implementation. Without it, success is claimed without re-measuring the same KPIs. The pattern: measure before, implement, measure after, compare.

**Why is Section 11 a blocking gate?**
Sections 1-10 are quality checks -- they improve the plan but don't reject it. Section 11 is different: if a file will exceed 500 lines or business logic lives in a route, the plan must be redesigned before proceeding. This matches the real-world cost of modularity violations (hours of refactoring later) vs the cost of redesigning now (minutes).

---

## Key Takeaways

1. **PreToolUse hook on ExitPlanMode enforces completeness** -- blocks plan submission until all 11 mandatory sections are present, warns on quality issues (missing KPI table, missing BEFORE/AFTER)
2. **Rules files are always in context** -- ~1,400 tokens, automatic, guides plan structure
3. **Skills load on demand** -- zero cost until invoked, full template available
4. **14 sections prevent common plan gaps** -- requirements, testing, docs, observability, file scope, summary, modularity, data validation, and post-validation
5. **Plan metadata makes files findable** -- branch, timestamp, topic, and keywords solve the random-name problem
6. **File change summary with Before/After/Why** -- each row is a mini-story showing the transformation
7. **TL;DR with Problem/Solution tables + KPI Dashboard** -- the reader understands the full plan in <10 seconds
8. **Per-fix BEFORE/AFTER** -- every fix starts with one sentence showing what's broken and what the fix achieves
9. **KPI Dashboard is always a table** -- pipe-delimited with Status, Before, After (Target), Source, Confidence, thresholds
10. **Modularity enforcement is a blocking gate** -- prevents god files, wrong-layer logic, and missing extractions before they happen
11. **Pre-Validation Probe grounds plans in data** -- measures KPI baselines, tests assumptions, blocks on NO-GO (see [Chapter 53](53-pre-validation-probe.md))
12. **Post-Validation closes the loop** -- re-measures the same KPIs after implementation, compares to targets
13. **Bypass with `<!-- skip-plan-sections -->`** -- escape hatch for non-standard plans
