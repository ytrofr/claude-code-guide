# Plan Delegation Rule - Orchestrator Stays Lean

**Authority**: Context freshness during multi-task plan execution
**Scope**: ALL plans with 3+ implementation tasks

---

## Core Rule

**When executing a plan with 3+ tasks that touch different files or domains, delegate each task to a fresh subagent via `Task()`. Keep the main context as a lean orchestrator.**

The orchestrator should:

1. Read the plan
2. Delegate each task via `Task()` with file paths (not contents)
3. Collect results and verify on filesystem (git log, file existence)
4. Move to the next task

The orchestrator should NOT:

- Read source files itself
- Write code directly
- Accumulate task outputs in its context

---

## When to Delegate (Spawn Subagent)

| Condition                                     | Action                   |
| --------------------------------------------- | ------------------------ |
| Plan has 3+ tasks touching different files    | Delegate each task       |
| Tasks touch different domains (DB + API + UI) | Delegate per domain      |
| Single task is >100 lines of changes          | Delegate that task       |
| Accumulated context approaching 50%           | Delegate remaining tasks |

## When to Stay Inline (No Subagent)

| Condition                           | Action                                 |
| ----------------------------------- | -------------------------------------- |
| Plan has 1-2 small tasks            | Work inline                            |
| Tasks share the same file           | Work inline (avoid conflicts)          |
| Each task is <50 lines              | Work inline                            |
| Tasks form a tight dependency chain | Work inline sequentially               |
| Debugging / iterative exploration   | Work inline (need accumulated context) |

---

## Delegation Pattern

```
# Orchestrator reads plan, delegates each task:

Task(subagent_type: "general-purpose",
  prompt: "Execute Task 1 from the plan:
    - Edit src/services/auth.service.js: add session cleanup logic
    - Verify: grep for the new function in the file
    - Do NOT commit (orchestrator will commit all tasks together)")

Task(subagent_type: "general-purpose",
  prompt: "Execute Task 2 from the plan:
    - Edit src/routes/auth.routes.js: add logout endpoint
    - Verify: grep for the new route
    - Do NOT commit")

# After all tasks complete, orchestrator verifies and commits
```

---

## Parallel Delegation (Independent Tasks)

When tasks within a plan are independent (touch different files, no shared state), launch them in a **single message** so Claude Code runs them concurrently:

```
# Both tasks in ONE message = parallel execution:

Task(subagent_type: "database-agent",
  prompt: "Add index to users.email column")

Task(subagent_type: "general-purpose",
  prompt: "Update auth middleware with rate limiting")
```

**Prerequisite for parallel**: Tasks must not modify the same files.

---

## Context Budget Target

| Role                | Context Usage                                  |
| ------------------- | ---------------------------------------------- |
| Orchestrator (main) | <20% -- plan reading, delegation, verification |
| Each subagent       | Fresh window -- full capacity for its task     |

---

## Why This Works

- Each subagent gets a **fresh context window** -- no degradation from prior tasks
- Orchestrator stays lean -- can handle 10+ task plans without quality loss
- Filesystem is the source of truth -- verify via git and file checks, not context
- Matches Anthropic's Orchestrator-Workers pattern
