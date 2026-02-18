---
layout: default
title: "Plan Mode Quality Checklist - Enforcing 11 Mandatory Sections"
description: "Automatically enforce comprehensive plan quality with an 11-section checklist covering requirements clarification, existing code search, over-engineering prevention, best practices, modular architecture, documentation, E2E testing, observability, file change summary, TL;DR, and modularity enforcement. Includes plan file metadata for discoverability."
---

# Chapter 45: Plan Mode Quality Checklist

Claude Code's plan mode is powerful for designing implementations before writing code. But plans often miss critical sections -- testing strategy, documentation, debugging. This chapter shows how to enforce a mandatory checklist that every plan must include, using rules files and skills.

**Purpose**: Ensure every plan covers 11 quality dimensions automatically
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

There's no built-in plan template in Claude Code. No hook event fires on plan mode entry. But we can solve this with two complementary approaches.

---

## The Limitation: No Plan Mode Hook

Claude Code supports 14 hook events, but **none for plan mode**:

```
SessionStart, UserPromptSubmit, PreToolUse, PermissionRequest,
PostToolUse, PostToolUseFailure, Notification, SubagentStart,
SubagentStop, Stop, TeammateIdle, TaskCompleted, PreCompact, SessionEnd
```

The `permission_mode` field in hook input JSON will show `"plan"` when plan mode is active, but no dedicated event fires on plan mode entry or exit. This rules out hook-based enforcement.

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

---

## Solution: Two Complementary Approaches

### Approach A: Rules File (Passive, Always in Context)

Create a rules file that's auto-loaded every message. When Claude enters plan mode, the 11-section template is already in context.

**File**: `~/.claude/rules/planning/plan-checklist.md`

```markdown
# Plan Mode Checklist - MANDATORY for Every Plan

**Scope**: ALL plans in ALL projects
**Enforcement**: Every plan MUST include ALL 11 sections below

---

## 11 Mandatory Plan Sections (Sections 0-10)

### Section 0: Requirements Clarification

Ask clarifying questions BEFORE planning. Don't assume -- confirm scope,
constraints, and expected behavior. Skip only if instructions are unambiguous.

### Section 1: Existing Code Check

Before proposing ANY new code, search for existing implementations.

### Section 2: Over-Engineering Prevention

Compare proposed approach with simpler alternatives. Table format.

### Section 3: Best Practices Compliance

KISS/DRY/SOLID/YAGNI/Security checklist.

### Section 4: Modular Architecture

Which routes, controllers, services are affected. No logic in entry files.

### Section 5: Documentation Plan

Run /document after implementation. Update status files.

### Section 6: E2E Testing Plan

Unit tests, integration tests, E2E tests, baseline regression, manual verification.

### Section 7: Debugging and Observability

What to log, error handling, health checks, monitoring, rollback plan.

### Section 8: File Change Summary

List every file that will be created, modified, or deleted with a 1-line description.

### Section 9: Plan Summary (TL;DR)

3-5 bullet points summarizing the entire plan. Reader should understand it in <10 seconds.

### Section 10: Modularity Enforcement (BLOCKING GATE)

File Size Gate, Layer Separation Gate, Extraction Gate, God File Prevention.
Plan is REJECTED if any check fails. Equal weight to Over-Engineering check.
```

**Cost**: ~1,200 tokens per message (loaded even outside plan mode)
**Benefit**: Zero manual effort -- the template is always available

### Approach B: User-Invocable Skill (Active, On-Demand)

Create a `/plan-checklist` skill with the full detailed template, anti-patterns, and examples. Loaded only when invoked.

**File**: `~/.claude/skills/plan-checklist-skill/SKILL.md`

```yaml
---
name: plan-checklist-skill
description: "Generate an 11-section plan checklist with requirements clarification, existing code check, over-engineering prevention, best practices, modular architecture, documentation plan, E2E testing, debugging strategy, file change summary, TL;DR, and modularity enforcement. Use when entering plan mode, creating implementation plans, or when user mentions '/plan-checklist', 'plan checklist', or 'planning'."
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

| Scenario                      | What Fires                                             |
| ----------------------------- | ------------------------------------------------------ |
| Enter plan mode normally      | **Rules file** -- 11 sections guide the plan structure |
| Type `/plan-checklist`        | **Skill** -- full template with examples loads         |
| Say "let's plan this feature" | **Both** -- rules always there, skill may auto-match   |

The rules file is the safety net (always present). The skill is the power tool (detailed guidance when needed).

---

## The 11 Mandatory Sections

### 0. Requirements Clarification

```markdown
## 0. Requirements Clarification

- **Clarified with user**: [yes -- summary of answers / skipped -- instructions were unambiguous]
- **Scope**: [what's included and excluded]
- **Constraints**: [performance, compatibility, deadlines]
- **Expected behavior**: [input -> output, edge cases]
```

**Why**: A 30-second clarifying question prevents hours of wrong-direction work. Don't assume -- confirm scope, constraints, and expected behavior before planning.

### 1. Existing Code Check

```markdown
## 1. Existing Code Check

- **Searched**: [grep patterns, glob patterns, skills checked]
- **Found**: [existing code that can be reused]
- **Reuse plan**: [how existing code will be leveraged]
- **New code needed**: [only what doesn't exist yet]
```

**Why**: Prevents rebuilding what already exists. In practice, checking first saves 1-3 hours per task.

### 2. Over-Engineering Prevention

```markdown
## 2. Over-Engineering Check

| Aspect | Proposed | Simpler Alternative | Decision |
| ------ | -------- | ------------------- | -------- |
| Code   | X lines  | Y lines             | [why]    |
| Files  | X new    | Y new               | [why]    |
| Deps   | X new    | 0                   | [why]    |

- Can this be solved with <50 lines? [yes/no + justification]
- Zero new dependencies? [yes/no + justification for each]
```

**Why**: Real evidence -- a cron migration went from 150 lines to 30 lines (80% reduction, 77% cheaper) after applying this check.

### 3. Best Practices

```markdown
## 3. Best Practices

- [ ] KISS: Simplest solution that works
- [ ] DRY: No duplicated logic
- [ ] SOLID: Single responsibility per module
- [ ] YAGNI: No speculative features
- [ ] Security: No injection risks (OWASP top 10)
```

### 4. Modular Architecture

```markdown
## 4. Architecture

- Routes: [files affected, delegation only]
- Controllers: [files affected]
- Services: [files affected, core logic]
- Each file < 500 lines, single responsibility
```

### 5. Documentation Plan

```markdown
## 5. Documentation

After implementation:

- [ ] Create entry/documentation for the work done
- [ ] Update project status
- [ ] Create skill if pattern repeats frequently
```

### 6. E2E Testing Plan

```markdown
## 6. Testing

- Unit tests: [what to test, expected count]
- Integration tests: [API endpoints to verify]
- E2E tests: [user flows to validate]
- Manual verification: [commands to run]
```

**Why**: Vague "add tests" plans produce no tests. Specific test plans with expected counts actually get implemented.

### 7. Debugging & Observability

```markdown
## 7. Debugging & Observability

- Logging: [what to log, at what level]
- Error handling: [how errors are caught]
- Health checks: [endpoints to verify]
- Monitoring: [what to watch post-deploy]
```

### 8. File Change Summary

```markdown
## 8. Files Affected

| File                              | Action | What Changes          |
| --------------------------------- | ------ | --------------------- |
| `src/routes/auth.js`              | MODIFY | Add logout endpoint   |
| `src/services/session.service.js` | NEW    | Session cleanup logic |
| `public/dashboard/auth.html`      | MODIFY | Add logout button     |
| `tests/auth.test.js`              | MODIFY | Add logout tests      |
```

**Action values**: `NEW` (create), `MODIFY` (edit existing), `DELETE` (remove)

**Why**: If you can't list the files, the plan isn't concrete enough. This section forces specificity and gives the reviewer immediate scope visibility.

### 9. Plan Summary (TL;DR)

```markdown
## 9. TL;DR

- Add logout endpoint to auth routes with session cleanup
- Create session service for token invalidation
- Update auth dashboard with logout button + confirmation dialog
- Run auth E2E tests + manual verification
```

**Why**: A reader should understand the full plan from this section alone in under 10 seconds. This is what gets scanned first during review.

### 10. Modularity Enforcement (BLOCKING GATE)

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

---

## Validation: Does It Work?

After setting up both files, test by entering plan mode for any task. The plan output should contain all 11 numbered sections with real content -- not placeholders.

**Quick validation**:

1. Enter plan mode (`Shift+Tab` or `--permission-mode plan`)
2. Give a simple task
3. Check the plan file -- all 11 sections should appear
4. Each section should have real content from actual codebase exploration
5. Verify the plan file has the metadata header (branch, timestamp, topic, keywords)
6. Verify Section 10 (Modularity) has all 4 sub-gates filled with real assessments

---

## Design Decisions

**Why rules file instead of CLAUDE.md?**
Rules files in `~/.claude/rules/` are auto-discovered and keep CLAUDE.md lean. They also apply across all projects.

**Why ~1,000 tokens is acceptable**:
The rules file costs ~1,000 tokens per message. With a 200k context window, that's 0.5%. The value of preventing missed testing/documentation in every plan far outweighs the cost.

**Why not a UserPromptSubmit hook?**
Hooks print to stderr (informational only). They can remind but can't enforce. The rules file is in Claude's actual context, so it directly influences plan structure.

**Why both approaches?**
The rules file is a lightweight always-on reminder. The skill provides the full detailed template when you want comprehensive guidance. Different situations call for different levels of detail.

**Why Sections 8 and 9 at the end?**
They serve as a scannable summary of the entire plan. Section 8 (files) shows scope at a glance. Section 9 (TL;DR) gives the executive summary. Reviewers read these first.

**Why is Section 10 a blocking gate?**
Sections 0-9 are quality checks -- they improve the plan but don't reject it. Section 10 is different: if a file will exceed 500 lines or business logic lives in a route, the plan must be redesigned before proceeding. This matches the real-world cost of modularity violations (hours of refactoring later) vs the cost of redesigning now (minutes).

---

## Key Takeaways

1. **No plan mode hook exists** -- use rules files and skills instead
2. **Rules files are always in context** -- ~1,200 tokens, automatic, no manual step
3. **Skills load on demand** -- zero cost until invoked, full template available
4. **11 sections prevent common plan gaps** -- requirements, testing, docs, observability, file scope, summary, and modularity are most often missed
5. **Plan metadata makes files findable** -- branch, timestamp, topic, and keywords solve the random-name problem
6. **File change summary forces specificity** -- if you can't list the files, the plan isn't ready
7. **TL;DR enables quick review** -- the entire plan in 3-5 bullet points
8. **Modularity enforcement is a blocking gate** -- prevents god files, wrong-layer logic, and missing extractions before they happen
