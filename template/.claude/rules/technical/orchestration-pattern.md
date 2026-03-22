# Orchestration Pattern — Command vs Agent vs Skill vs MCP

**Scope**: ALL projects
**Authority**: Unified routing decision tree
**Source**: DeerFlow (bytedance/deer-flow) + claude-code-best-practice — validated pattern

---

## Core Rule

**Use the right abstraction level. Don't use agents when a tool call suffices. Don't use commands when a skill fits.**

## Decision Tree

```
User request arrives
    ↓
Is it a recurring workflow the user triggers by name?
    → YES: Command (/slash)
    → NO ↓
Does it need isolated context or domain-specific work?
    → YES: Agent (Task())
    → NO ↓
Is it a composable, reusable capability?
    → YES: Skill (SKILL.md)
    → NO ↓
Is it an atomic operation?
    → YES: MCP Tool (direct call)
```

## Abstraction Levels

| Level | What | When | Example |
|-------|------|------|---------|
| **Command** (`/slash`) | Entry point, user-initiated | Recurring workflows, session lifecycle | `/session-start`, `/verify`, `/document` |
| **Agent** (`Task()`) | Isolated context, domain work | Multi-file changes, parallel research, heavy lifting | Backend agent, database agent, explore agent |
| **Skill** (`SKILL.md`) | Composable capability | Reusable patterns, domain knowledge | `adk-development`, `video-production-methods` |
| **MCP Tool** | Atomic operation | Direct tool call, single action | `mcp__playwright__browser_navigate`, `mcp__github__search_code` |

## Coordination Flow

```
Command (orchestrates)
  → dispatches Agent(s) (each with isolated context)
    → Agent loads Skill(s) (domain knowledge)
      → Skill calls MCP Tool(s) (atomic operations)
```

## Anti-Patterns

- Using an Agent for a single file read (use Read tool directly)
- Using a Command for one-off work (just do it inline)
- Calling MCP tools when a Skill already wraps the workflow
- Spawning Agents without checking if existing Skills cover the task

---

**See also**: `mcp/agent-routing.md` (agent selection), `planning/delegation-rule.md` (when to delegate)
