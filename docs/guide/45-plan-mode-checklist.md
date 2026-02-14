---
layout: default
title: "Plan Mode Quality Checklist - Enforcing 8 Mandatory Sections"
description: "Automatically enforce comprehensive plan quality with an 8-section checklist covering requirements clarification, existing code search, over-engineering prevention, best practices, modular architecture, documentation, E2E testing, and observability."
---

# Chapter 45: Plan Mode Quality Checklist

Claude Code's plan mode is powerful for designing implementations before writing code. But plans often miss critical sections -- testing strategy, documentation, debugging. This chapter shows how to enforce a mandatory checklist that every plan must include, using rules files and skills.

**Purpose**: Ensure every plan covers 8 quality dimensions automatically
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

## Solution: Two Complementary Approaches

### Approach A: Rules File (Passive, Always in Context)

Create a rules file that's auto-loaded every message. When Claude enters plan mode, the 8-section template is already in context.

**File**: `~/.claude/rules/planning/plan-checklist.md`

```markdown
# Plan Mode Checklist - MANDATORY for Every Plan

**Scope**: ALL plans in ALL projects
**Enforcement**: Every plan MUST include ALL 8 sections below

---

## 8 Mandatory Plan Sections

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
```

**Cost**: ~800 tokens per message (loaded even outside plan mode)
**Benefit**: Zero manual effort -- the template is always available

### Approach B: User-Invocable Skill (Active, On-Demand)

Create a `/plan-checklist` skill with the full detailed template, anti-patterns, and examples. Loaded only when invoked.

**File**: `~/.claude/skills/plan-checklist-skill/SKILL.md`

```yaml
---
name: plan-checklist-skill
description: "Generate an 8-section plan checklist with requirements clarification, existing code check, over-engineering prevention, best practices, modular architecture, documentation plan, E2E testing, and debugging strategy. Use when entering plan mode, creating implementation plans, or when user mentions 'plan checklist'."
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

| Scenario                      | What Fires                                            |
| ----------------------------- | ----------------------------------------------------- |
| Enter plan mode normally      | **Rules file** -- 8 sections guide the plan structure |
| Type `/plan-checklist`        | **Skill** -- full template with examples loads        |
| Say "let's plan this feature" | **Both** -- rules always there, skill may auto-match  |

The rules file is the safety net (always present). The skill is the power tool (detailed guidance when needed).

---

## The 8 Mandatory Sections

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

---

## Validation: Does It Work?

After setting up both files, test by entering plan mode for any task. The plan output should contain all 8 numbered sections with real content -- not placeholders.

**Quick validation**:

1. Enter plan mode (`Shift+Tab` or `--permission-mode plan`)
2. Give a simple task
3. Check the plan file -- all 8 sections should appear
4. Each section should have real content from actual codebase exploration

---

## Design Decisions

**Why rules file instead of CLAUDE.md?**
Rules files in `~/.claude/rules/` are auto-discovered and keep CLAUDE.md lean. They also apply across all projects.

**Why ~800 tokens is acceptable**:
The rules file costs ~800 tokens per message. With a 200k context window, that's 0.4%. The value of preventing missed testing/documentation in every plan far outweighs the cost.

**Why not a UserPromptSubmit hook?**
Hooks print to stderr (informational only). They can remind but can't enforce. The rules file is in Claude's actual context, so it directly influences plan structure.

**Why both approaches?**
The rules file is a lightweight always-on reminder. The skill provides the full detailed template when you want comprehensive guidance. Different situations call for different levels of detail.

---

## Key Takeaways

1. **No plan mode hook exists** -- use rules files and skills instead
2. **Rules files are always in context** -- ~800 tokens, automatic, no manual step
3. **Skills load on demand** -- zero cost until invoked, full template available
4. **8 sections prevent common plan gaps** -- requirements clarification, testing, docs, and observability are most often missed
5. **Real content required** -- the checklist enforces actual codebase searches, not placeholder text
