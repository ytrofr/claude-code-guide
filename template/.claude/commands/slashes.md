---
description: Complete overview of all slash commands with usage examples
---

# Complete Slash Commands Reference

**TOTAL COMMANDS**: 7 (Minimalist - agent-first workflow)

---

## Session Management (3)

- `/session-start` - Initialize session with git status + feature discovery
- `/session-end` - End session with checkpoint validation
- `/retrospective` - Create skill from session learnings (GUIDED mode)

## Documentation (2)

- `/document` - Full documentation workflow (Entry + Skill + Blueprint analysis)
- `/blueprint [feature]` - Generate comprehensive feature documentation

## Productivity (2)

- `/advise` - Search skills registry before starting new work
- `/slashes` - This command overview

---

## When to Use Each

| Situation                     | Command             |
| ----------------------------- | ------------------- |
| Starting work                 | `/session-start`    |
| Before building anything      | `/advise`           |
| After solving a hard problem  | `/retrospective`    |
| After completing work         | `/document`         |
| Documenting a complex feature | `/blueprint [name]` |
| Ending your session           | `/session-end`      |
| Forgot what commands exist    | `/slashes`          |

---

## Philosophy

**Agent-First Workflow**: Use Task tool and agents directly for most work.
Commands exist only for workflows that genuinely automate multiple steps.

**Everything else**: Use native Claude Code tools (Task, Read, Grep, Bash).
