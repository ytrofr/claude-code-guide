---
layout: default
title: "Workflow Resilience Patterns - Autonomous Fixing, Correction Capture, Task Tracking, and Sideways Detection"
description: "Four production-tested patterns that make Claude Code sessions more resilient: knowing when to fix vs ask, capturing corrections as permanent memory, tracking multi-step work with TaskCreate, and detecting when a plan has gone sideways."
---

# Chapter 49: Workflow Resilience Patterns

Most Claude Code guidance focuses on the happy path -- how to set up skills, write plans, and deploy code. But real sessions are messy. Tests fail from your own changes. The user corrects your approach. Multi-step plans lose track of where you are. A plan that looked solid falls apart during execution. This chapter covers four patterns that handle these situations, turning each failure mode into a systematic response.

**Purpose**: Make Claude Code sessions resilient to common failure modes
**Source**: Production patterns from LIMOR AI project (400+ entries) + Anthropic best practices
**Difficulty**: Beginner to Intermediate
**Prerequisite**: [Chapter 02: Minimal Setup](02-minimal-setup.md)

---

## Pattern 1: Autonomous Fixing

The most common session slowdown is unnecessary back-and-forth. Claude encounters an error, asks the user what to do, waits for a response, then fixes it. For errors Claude caused, this wastes everyone's time.

### The Rule

**When you break something, fix it. Don't ask for permission to clean up your own mess.**

The workflow is: read the error, find the root cause, fix it, verify the fix, report what happened. No hand-holding.

### Fix Autonomously (No Permission Needed)

These are all cases where Claude caused the problem or the fix is obvious:

- Failing tests from your own changes
- Lint, format, or type errors you introduced
- Import/require issues from files you moved
- Obvious logic bugs (null checks, off-by-one, typos)
- CI failures caused by your changes
- Missing files referenced in code you wrote
- Broken builds after your edits

### Ask Before Fixing

These are cases where the fix involves decisions the user should make:

- Architectural changes (moving files, changing established patterns)
- Data mutations (database writes, API calls to production)
- Deleting code you didn't write (more than 10 lines)
- Changes affecting more than 5 files beyond the original scope
- Performance trade-offs with unclear impact
- Reverting someone else's work

### Workflow

```
1. Read the error / log / test output
2. Search for root cause (Grep, Read — don't guess)
3. Check memory for prior fixes (if using Basic Memory MCP)
4. Fix it
5. Verify (run the test, curl the endpoint, check the output)
6. Report: what broke, why, what you fixed
```

### Rule Template

Add this to `.claude/rules/process/autonomous-fixing.md`:

```markdown
# Autonomous Fixing Protocol

When given a bug or error: fix it. Don't ask for hand-holding.

## Fix Autonomously

- Failing tests from your own changes
- Lint, format, or type errors
- Import/require issues
- Obvious logic bugs
- CI failures you caused

## Ask Before Fixing

- Architectural changes
- Data mutations (DB writes, API calls to prod)
- Deleting code you didn't write (>10 lines)
- Changes beyond original scope (>5 files)
- Reverting someone else's work
```

---

## Pattern 2: Correction Capture

When a user corrects Claude's approach, that correction is the highest-signal learning available. Most sessions waste it -- the correction is applied, and forgotten by the next session. This pattern captures corrections as permanent memory.

### Why Corrections Are High-Value

[Chapter 42: Session Memory & Compaction](42-session-memory-compaction.md) already establishes that corrections are the #1 priority during context compaction. This pattern extends that idea: don't just preserve corrections during compaction -- actively capture them when they happen.

### The Trigger

Any time the user corrects your approach, output, or understanding:

- "No, use X instead of Y"
- "That's not how we do it here"
- "The pattern is actually..."
- "Wrong file / wrong approach / wrong assumption"

### The Response

1. **Acknowledge** the correction explicitly (don't just silently change course)
2. **Capture** to persistent memory:
   - If Basic Memory MCP is available: `write_note(folder="corrections/", title="[correction] Description #category")`
   - If no MCP: add the correction to a relevant `.claude/rules/` file, or create a new rule
3. **If the pattern repeats 2+ times**: Create a dedicated rule in `.claude/rules/` to prevent future occurrences
4. **If project-specific**: Add to `.claude/rules/` (project-level), not `~/.claude/rules/` (global)

### Example Flow

```
User: "Don't use moment.js, we use date-fns in this project"

Claude:
1. Acknowledge: "Got it -- date-fns, not moment.js"
2. Capture: write_note(folder="corrections/",
     title="[correction] Use date-fns not moment.js #dependencies")
3. If this is the 2nd time: create .claude/rules/technical/date-library.md
```

### Rule Template

Add this section to your existing `.claude/rules/process/session-protocol.md`:

```markdown
## Correction Capture

**Trigger**: User corrects your approach, output, or understanding.

1. Acknowledge the correction explicitly
2. Capture to memory (MCP write_note or .claude/rules/ file)
3. If pattern repeats 2+ times: create a dedicated rule
4. Project-specific corrections go in .claude/rules/ (not ~/.claude/rules/)

Rule: Every correction is a free lesson. Capture it or repeat it.
```

---

## Pattern 3: Task Tracking Conventions

Claude Code has built-in `TaskCreate` and `TaskUpdate` tools for tracking multi-step work. But without conventions, they get used inconsistently -- tasks created but never updated, completed without verification, or skipped entirely when they'd help.

### When to Use Tasks

| Use Tasks                              | Don't Use Tasks           |
| -------------------------------------- | ------------------------- |
| Plan has 3+ implementation steps       | Single-file fix           |
| User provides a numbered list of items | 1-2 step operations       |
| Multi-file changes with dependencies   | Pure research/exploration |
| Work will span significant context     | Trivial changes           |

The threshold is simple: if there's a risk of losing track of where you are, use tasks.

### Task Lifecycle

```
Create (pending) → Mark in_progress → Implement → Verify → Mark completed
     ↑                                    ↓
     └── Discover new subtask → TaskCreate (new task)
```

### Six Hygiene Rules

1. **Create upfront**: After understanding the scope, create all tasks before starting work. This gives the user visibility into what's planned.
2. **Mark in_progress BEFORE starting**: Not after. The user should see which task is active.
3. **Mark completed ONLY after verification**: Tests pass, endpoint responds, output looks right.
4. **Never mark complete if broken**: Tests failing, errors present, implementation partial -- keep it `in_progress`.
5. **Add follow-ups**: Discovered subtasks become new tasks, not ignored TODOs.
6. **Work in order**: Prefer lowest ID first (earlier tasks often set up context for later ones).

### Task Quality

Good tasks are self-contained enough that another agent could pick them up:

```
// GOOD
subject: "Add logout endpoint to auth routes"
activeForm: "Adding logout endpoint"
description: "Create POST /api/auth/logout in src/routes/auth.routes.js.
  Should call AuthService.logout(sessionId). Add input validation.
  Verify: curl -X POST localhost:8080/api/auth/logout returns 200."

// BAD
subject: "Auth stuff"
description: "Fix auth"
```

### Rule Template

Add this to `.claude/rules/process/task-tracking.md`:

```markdown
# Task Tracking Conventions

Use TaskCreate when plan has 3+ steps, user gives numbered list,
or multi-file changes with dependencies.

## Hygiene

1. Create all tasks upfront before starting
2. Mark in_progress BEFORE starting (not after)
3. Mark completed ONLY after verification passes
4. Never mark complete if tests fail or errors exist
5. Discovered subtasks → new tasks, not ignored
6. Work in ID order unless dependencies say otherwise
```

---

## Pattern 4: Sideways Detection

Plans fail. Not dramatically -- they go sideways. The third attempt at the same approach still doesn't work. A discovered requirement doubles the scope. A core assumption turns out to be false. Without a protocol for detecting and responding to these situations, the natural tendency is to push through, wasting context and producing worse results.

### The Triggers

| Trigger               | Signal                                          | Response                 |
| --------------------- | ----------------------------------------------- | ------------------------ |
| **3-strike rule**     | 3+ consecutive failed attempts at same approach | Stop and re-plan         |
| **Scope creep**       | Discovered requirement expands scope >50%       | Stop and re-plan         |
| **Wrong assumptions** | Core plan assumption proven false               | Stop and re-plan         |
| **Blocked**           | External dependency prevents progress           | Re-plan with alternative |

### What "Re-plan" Means

1. **Stop** current implementation work
2. **Document** what was tried and why it failed
3. **Re-enter plan mode** (or present a revised approach to the user)
4. **Include the failure context** -- the new plan should explain what was learned

This is NOT starting over. The failed attempts produced information. The re-plan uses that information to find a better path.

### Example

```
Plan: "Add caching with Redis for AI responses"

Attempt 1: Redis connection fails (wrong config) → fix config
Attempt 2: Redis connection fails (firewall) → adjust firewall
Attempt 3: Redis connection fails (Docker network issue) → ???

SIDEWAYS DETECTED (3 strikes on same approach)

Re-plan: "The Redis integration has infrastructure blockers.
Alternative: Use in-memory LRU cache (no external dependency).
Trade-off: No cross-instance sharing, but works immediately.
User, which approach do you prefer?"
```

### Relationship to Plan Mode

[Chapter 45: Plan Mode Checklist](45-plan-mode-checklist.md) covers how to write good plans. This pattern covers what to do when a good plan stops working. They're complementary:

- Chapter 45: "Here's how to plan well" (prevention)
- This pattern: "Here's what to do when the plan fails" (response)

### Rule Template

Add this to the end of your `.claude/rules/planning/plan-checklist.md`:

```markdown
## Sideways Detection (Mid-Execution Re-Planning)

If implementation goes sideways, STOP and re-plan:

- **3-strike rule**: 3+ failed attempts at same approach → re-plan
- **Scope creep**: Scope expands >50% beyond plan → re-plan
- **Wrong assumptions**: Core assumption proven false → re-plan
- **Blocked**: External dependency prevents progress → re-plan

Action: Stop work, re-enter plan mode, document what failed and why.
Anti-pattern: Pushing through a failing approach hoping it will work.
```

---

## How These Patterns Work Together

The four patterns form a resilience loop:

```
Normal work
    │
    ├── Error from your changes → Pattern 1 (Autonomous Fix)
    │       └── Fix, verify, report, continue
    │
    ├── User corrects you → Pattern 2 (Correction Capture)
    │       └── Acknowledge, capture, create rule if repeated
    │
    ├── Multi-step work → Pattern 3 (Task Tracking)
    │       └── Create tasks, track progress, verify before completing
    │
    └── Plan going sideways → Pattern 4 (Sideways Detection)
            └── Detect trigger, stop, re-plan with failure context
```

Each pattern handles a different failure mode. Together they cover the most common ways sessions go wrong.

---

## Key Takeaways

1. **Fix your own messes autonomously** -- don't ask permission to clean up errors you caused. Ask before making decisions the user should own.
2. **Capture every correction** -- a correction that isn't persisted will be repeated. Use Basic Memory MCP or `.claude/rules/` files.
3. **Use TaskCreate for 3+ step work** -- mark `in_progress` before starting, `completed` only after verification. Never mark complete with failing tests.
4. **Detect sideways early** -- 3 failed attempts, 50% scope expansion, or a false assumption all trigger re-planning. Don't push through a failing approach.
5. **These are rules, not guidelines** -- add them to `.claude/rules/` so they're enforced every session, not just remembered sometimes.

---

**Previous**: [48: Lean Orchestrator Pattern](48-lean-orchestrator-pattern.md)
