---
layout: default
title: "Lean Orchestrator Pattern - Defeating Context Rot in Multi-Task Plans"
description: "Keep the main context lean by delegating plan tasks to fresh subagents. Prevent quality degradation during long implementation sessions. Includes delegation decision matrix and parallel execution patterns."
---

# Chapter 48: Lean Orchestrator Pattern

When you execute a plan with many tasks, quality degrades as your context window fills up. By task 4 or 5, Claude has accumulated so much intermediate state that responses become less focused and errors creep in. This chapter shows how to keep the main context lean by delegating each task to a fresh subagent -- giving every task a full, clean context window.

**Purpose**: Prevent context rot during multi-task plan execution
**Source**: GSD project analysis (gsd-build/get-shit-done) + Anthropic Orchestrator-Workers pattern
**Difficulty**: Intermediate
**Prerequisite**: [Chapter 40: Agent Orchestration Patterns](40-agent-orchestration-patterns.md)

---

## The Problem: Context Rot

Context rot happens when the context window fills with accumulated state from previous tasks. Each completed task leaves behind:

- File contents that were read
- Code that was written
- Tool call results
- Reasoning and decision traces

By the time you reach task 5 in a 8-task plan, your context is 60-70% full of completed work that's no longer relevant. The model has less room to think about the current task, and quality drops.

```
Task 1: Fresh context, high quality    ████░░░░░░░░░░░░ 25%
Task 2: Some prior state               ████████░░░░░░░░ 40%
Task 3: More accumulated context        ████████████░░░░ 55%
Task 4: Context getting crowded         ████████████████ 70% ← Quality starts dropping
Task 5: Degraded quality                ████████████████████ 85% ← Errors creep in
```

The traditional fix is the "75% rule" -- stop at 75% context, commit, and start a fresh session. This works but forces you to break your flow and restart.

---

## The Solution: Lean Orchestrator

Instead of executing all tasks in the main context, treat the main context as a **thin orchestrator** that only reads the plan and delegates work. Each task runs in a fresh subagent with its own full context window.

```
Main Context (Orchestrator) ── stays at ~15-20%
    │
    ├── Task() → Subagent 1 (fresh 200k) → Task 1 done
    ├── Task() → Subagent 2 (fresh 200k) → Task 2 done
    ├── Task() → Subagent 3 (fresh 200k) → Task 3 done
    ├── Task() → Subagent 4 (fresh 200k) → Task 4 done
    └── verify results on filesystem
```

The orchestrator never reads source files, never writes code, and never accumulates task outputs. It stays lean. Each subagent gets a full fresh window for its task.

---

## Decision Matrix: When to Delegate

Not every plan benefits from delegation. Use this matrix:

### Delegate (Spawn Subagent)

| Condition                                     | Why                          |
| --------------------------------------------- | ---------------------------- |
| Plan has 3+ tasks touching different files    | Each task gets fresh context |
| Tasks touch different domains (DB + API + UI) | Domain expertise per agent   |
| Single task involves >100 lines of changes    | Needs room to think          |
| Context already at 40%+ when plan starts      | Prevent overflow             |

### Stay Inline (No Subagent)

| Condition                           | Why                        |
| ----------------------------------- | -------------------------- |
| Plan has 1-2 small tasks            | Overhead exceeds benefit   |
| Tasks modify the same file          | Subagents would conflict   |
| Each task is <50 lines              | Simple enough inline       |
| Tasks form a tight sequential chain | Each needs previous result |
| Iterative debugging                 | Need accumulated context   |

The key factor is **file independence**. If tasks touch different files, they're good candidates for delegation (and potentially parallelization). If they share files, keep them inline.

---

## Implementation

### Basic Pattern: Sequential Delegation

```
// Orchestrator reads the plan file
Read("plan.md")

// Delegate Task 1
Task(subagent_type: "general-purpose",
  prompt: "Execute this task:
    - Edit src/routes/auth.routes.js: add logout endpoint
    - The endpoint should call AuthService.logout(sessionId)
    - Add input validation for sessionId parameter
    - Do NOT commit -- I'll commit all tasks together")

// Delegate Task 2
Task(subagent_type: "general-purpose",
  prompt: "Execute this task:
    - Create src/services/auth.service.js with logout() method
    - It should invalidate the session in the sessions table
    - Follow existing service patterns in src/services/
    - Do NOT commit")

// Orchestrator verifies and commits
Bash("git diff --stat")  // Check what changed
Bash("git add src/routes/auth.routes.js src/services/auth.service.js")
Bash("git commit -m 'feat: add logout endpoint with session cleanup'")
```

**Key details**:

- Pass **file paths and intent**, not file contents (subagent reads them fresh)
- Tell subagents NOT to commit (orchestrator commits once at the end)
- Verify on the filesystem before committing

### Advanced Pattern: Parallel Delegation

When tasks are independent (no shared files), launch them in a **single message** so Claude Code runs them concurrently:

```
// Both tasks in ONE response -- Claude Code runs them in parallel:

Task(subagent_type: "database-agent",
  prompt: "Add a GIN trigram index on employees.name_hebrew for fast ILIKE searches.
    File: Create a migration in src/database/migrations/
    Verify: EXPLAIN ANALYZE shows index scan")

Task(subagent_type: "general-purpose",
  prompt: "Update the employee search endpoint to use ILIKE instead of exact match.
    File: src/routes/employees.routes.js
    Test: curl localhost:8080/api/employees?search=יוסי returns results")
```

**Rule for parallel tasks**: They must not modify the same files. If Plan A and Plan B both touch `index.js`, run them sequentially.

### Verification Pattern

After all subagents complete, the orchestrator verifies via the filesystem -- not by trusting return values alone:

```
// Verify Task 1 result
Bash("test -f src/services/auth.service.js && echo 'EXISTS' || echo 'MISSING'")

// Verify Task 2 result
Grep(pattern: "logout", path: "src/routes/auth.routes.js")

// Check nothing unexpected changed
Bash("git diff --stat")

// Run tests
Bash("npm test")
```

The filesystem is the source of truth. A subagent might report success while having silently failed (known Claude Code edge case). Always verify.

---

## Context Budget

| Role          | Target     | What it does                             |
| ------------- | ---------- | ---------------------------------------- |
| Orchestrator  | <20%       | Reads plan, delegates, verifies, commits |
| Each subagent | Fresh 200k | Full capacity for its specific task      |

The orchestrator's context grows only by the size of subagent result summaries (typically a few hundred tokens each). Even with 10 tasks, the orchestrator stays under 30%.

Compare to inline execution where the orchestrator does everything:

| Approach             | After 5 tasks | After 10 tasks     |
| -------------------- | ------------- | ------------------ |
| Inline (traditional) | ~65% context  | ~90% (degraded)    |
| Lean orchestrator    | ~18% context  | ~25% (still fresh) |

---

## What the Orchestrator Should and Should Not Do

### Orchestrator Should:

- Read the plan file
- Decide task ordering and parallelization
- Write clear task prompts with file paths
- Verify results on the filesystem
- Run tests after all tasks complete
- Make the final commit

### Orchestrator Should NOT:

- Read source files (subagents do this)
- Write or edit code (subagents do this)
- Accumulate subagent outputs in its reasoning (check filesystem instead)
- Debug failures inline (spawn a debug subagent instead)

---

## Common Mistakes

### 1. Passing File Contents Instead of Paths

```
// WRONG -- bloats orchestrator context
contents = Read("src/services/big-file.js")
Task(prompt: "Edit this file: {contents}")

// RIGHT -- subagent reads it fresh
Task(prompt: "Edit src/services/big-file.js: add the logout method after line 50")
```

### 2. Parallel Tasks That Share Files

```
// WRONG -- both modify index.js, will conflict
Task(prompt: "Add route A to index.js")
Task(prompt: "Add route B to index.js")  // Race condition

// RIGHT -- sequential for shared files
Task(prompt: "Add route A to index.js")
// Wait for completion
Task(prompt: "Add route B to index.js")
```

### 3. Over-Delegating Small Tasks

```
// WRONG -- overhead exceeds benefit
Task(prompt: "Change line 42 from 'foo' to 'bar' in config.js")

// RIGHT -- just do it inline
Edit(file_path: "config.js", old_string: "foo", new_string: "bar")
```

### 4. Forgetting to Verify

```
// WRONG -- trust subagent blindly
Task(prompt: "Create the migration file")
Bash("git add . && git commit -m 'done'")  // What if subagent failed?

// RIGHT -- verify first
Task(prompt: "Create the migration file")
Bash("ls src/database/migrations/ | tail -1")  // Does it exist?
Bash("npm test")  // Does it work?
Bash("git add src/database/migrations/ && git commit -m 'add migration'")
```

---

## Real-World Example

A plan to add a new dashboard page with API endpoint, database query, and frontend:

```
// Plan has 4 tasks across 3 domains -- good candidate for delegation

// Task 1 + Task 2: Independent (different domains) -- parallel
Task(subagent_type: "database-agent",
  prompt: "Create a new SQL view 'daily_revenue_summary' in src/database/migrations/.
    Columns: date, total_revenue, order_count, avg_order_value.
    Source: beecom_orders table. Group by order_date.")

Task(subagent_type: "general-purpose",
  prompt: "Create src/services/revenue-summary.service.js.
    Export getDailySummary(startDate, endDate) that queries daily_revenue_summary view.
    Follow patterns in src/services/labor-cost.service.js.")

// Wait for both to complete, then:

// Task 3: Depends on Task 1 + 2 -- sequential
Task(subagent_type: "general-purpose",
  prompt: "Create API endpoint GET /api/revenue-summary in src/routes/revenue.routes.js.
    Use RevenueSummaryService.getDailySummary().
    Accept query params: startDate, endDate (default: last 30 days).
    Follow patterns in src/routes/labor-cost.routes.js.")

// Task 4: Depends on Task 3 -- sequential
Task(subagent_type: "general-purpose",
  prompt: "Create public/dashboard/revenue-summary.html.
    Fetch from /api/revenue-summary. Display as a chart + table.
    Follow patterns in public/dashboard/labor-cost.html.
    Use existing chart.js setup from public/js/charts/.")

// Verify all 4 tasks
Bash("npm test")
Bash("curl localhost:8080/api/revenue-summary | head -5")
Bash("git diff --stat")
```

Tasks 1-2 run in parallel (different files, different domains). Tasks 3-4 run sequentially (each depends on the previous). The orchestrator stays under 20% context throughout.

---

## Relationship to Other Patterns

This chapter extends the **Orchestrator-Workers pattern** from [Chapter 40](40-agent-orchestration-patterns.md) with specific guidance for plan execution. The key addition is the **delegation decision matrix** -- knowing when delegation helps and when it hurts.

It also complements [Chapter 39: Context Separation](39-context-separation.md), which handles static context loading. This chapter handles dynamic context growth during execution.

---

## Rule Template

Add this to `.claude/rules/planning/delegation-rule.md` in your project:

```markdown
# Plan Delegation Rule

When executing a plan with 3+ tasks that touch different files or domains,
delegate each task to a fresh subagent via Task(). Keep main context as orchestrator.

## Delegate when:

- 3+ tasks touching different files
- Tasks cross domains (DB + API + UI)
- Single task >100 lines
- Context already at 40%+

## Stay inline when:

- 1-2 small tasks
- Tasks share files
- Each task <50 lines
- Tight sequential dependency
- Debugging
```

---

**Previous**: [47: Adoptable Rules and Commands](47-adoptable-rules-and-commands.md)
