# Task Tracking Conventions

**Scope**: ALL projects
**Authority**: When and how to use TaskCreate/TaskUpdate
**Created**: 2026-02-23
**Updated**: 2026-03-16 (Added auto-creation rule)

---

## Auto-Creation Rule (MANDATORY)

**Claude MUST proactively create a task list using TaskCreate BEFORE starting work** when ANY of these conditions are met — without the user asking:

- Task has 2+ distinct implementation steps
- User provides a list of work items (numbered or bulleted)
- Multi-file changes are needed
- Work will span significant context (risk of losing track)
- User describes a feature, bug fix, or refactor that involves multiple changes

**Workflow**: Understand scope → Create all tasks upfront → Start working through them in order.

**Do NOT wait for the user to say "create tasks"** — if the work qualifies, create them automatically.

## When NOT to Use Tasks

- Single-file fix or trivial change (truly 1 step)
- Pure research/exploration
- Answering a question

---

## Task Hygiene

1. **Create upfront**: After understanding scope, create all tasks before starting
2. **Mark in_progress**: BEFORE starting work on a task (not after)
3. **Mark completed**: ONLY after verification passes (tests, curl, visual check)
4. **Never mark complete if**: Tests fail, errors exist, implementation is partial
5. **Add follow-ups**: Discovered subtasks get added as new tasks, not ignored
6. **Work in order**: Prefer lowest ID first unless dependencies say otherwise

---

## Task Quality

- **subject**: Imperative form ("Fix auth bug", not "Auth bug")
- **activeForm**: Present continuous ("Fixing auth bug")
- **description**: Enough detail for another agent to understand and execute

---

**Anti-pattern**: Creating a task, doing the work, marking complete without testing.
**Correct**: Create → in_progress → implement → verify → completed.
