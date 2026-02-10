# Chapter 37: Agent Teams (Experimental)

**Purpose**: Coordinate multiple agents working in parallel on complex tasks
**Source**: Anthropic Claude Code documentation (agent teams research preview)
**Status**: Experimental (requires feature flag)
**Difficulty**: Advanced
**Time**: 1 hour to design first team

---

## Overview

Agent Teams extend the subagent system ([Chapter 36](36-agents-and-subagents.md)) by enabling a **lead agent** to coordinate multiple **teammates** working in parallel with a shared task list and mailbox system.

**Key distinction**:

- **Subagents** (current): Main conversation spawns agents via `Task()`. Agents can't spawn other agents.
- **Agent Teams** (experimental): A lead agent coordinates teammates who work independently with inter-agent communication.

```
Subagents (Current):                   Agent Teams (Experimental):
  Main Conversation                      Lead Agent (main thread)
    ├── Task(agent-a)                      ├── Teammate A (parallel)
    ├── Task(agent-b)                      ├── Teammate B (parallel)
    └── Task(agent-c)                      └── Teammate C (parallel)
                                           Shared: task list + mailbox
```

---

## Enabling Agent Teams

```bash
# Set the environment variable
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1

# Run Claude Code in agent mode
claude --agent
```

**Warning**: This is a research preview feature. Token usage is significantly higher because each teammate receives full context.

---

## How Agent Teams Work

### Lead Agent

The main thread agent acts as coordinator:

- **Default mode**: Lead can use tools AND coordinate teammates
- **Delegate mode**: Lead only coordinates, can't use tools directly

### Teammates

Independent agents that:

- Share a task list (read/write)
- Communicate via mailbox system
- Run in parallel
- Have their own context window

### Communication

Agents coordinate through:

1. **Shared task list**: Create, claim, and complete tasks
2. **Mailbox**: Send messages between agents
3. **Hook events**: `TeammateIdle` and `TaskCompleted` for lifecycle

---

## Team Definition File

Create team definitions in `.claude/agent-teams/`:

```markdown
# Deployment Team

## Lead: deploy-agent

Coordinates the deployment pipeline.

## Teammates

### test-engineer

Runs pre-deployment tests and validates test coverage.

### monitoring-agent

Monitors logs and health checks after deployment.

## Workflow

1. Lead receives deployment request
2. test-engineer runs test suite in parallel
3. Lead deploys after tests pass
4. monitoring-agent watches logs for 10 minutes
5. Lead reports final status
```

---

## Natural Team Groupings

Based on production patterns, these team compositions work well:

| Team               | Lead           | Teammates                         | Use Case                |
| ------------------ | -------------- | --------------------------------- | ----------------------- |
| **Deployment**     | deploy-agent   | test-engineer, monitoring-agent   | Multi-step deployments  |
| **Data Integrity** | database-agent | data-validator, accuracy-checker  | Gap detection + healing |
| **AI Quality**     | ai-agent       | debug-specialist, prompt-engineer | AI pipeline debugging   |
| **Code Review**    | reviewer-lead  | security-agent, style-checker     | Comprehensive PR review |

---

## Hook Events for Teams

Two additional hook events support team coordination:

| Hook            | Trigger                    | Use For            |
| --------------- | -------------------------- | ------------------ |
| `TeammateIdle`  | Teammate finishes its task | Assign new work    |
| `TaskCompleted` | Shared task marked done    | Check dependencies |

```json
{
  "hooks": {
    "TeammateIdle": [
      {
        "hooks": [
          { "type": "command", "command": ".claude/hooks/team-coordinator.sh" }
        ]
      }
    ],
    "TaskCompleted": [
      {
        "hooks": [
          { "type": "command", "command": ".claude/hooks/task-tracker.sh" }
        ]
      }
    ]
  }
}
```

---

## When to Use Teams vs Subagents

| Scenario                             | Use Subagents | Use Teams |
| ------------------------------------ | ------------- | --------- |
| Simple parallel tasks                | Yes           | No        |
| Tasks need inter-agent communication | No            | Yes       |
| Cost-sensitive work                  | Yes           | No        |
| Complex multi-phase workflows        | Maybe         | Yes       |
| Single coordinator needed            | Yes           | Yes       |
| Agents need to share state           | No            | Yes       |

**Rule of thumb**: Start with subagents. Only move to teams when you need agents to communicate with each other.

---

## Token Considerations

Agent teams use significantly more tokens:

- Each teammate gets its own full context window
- Shared task list and mailbox add overhead
- Communication between agents adds turns

**Cost control strategies**:

- Use `haiku` model for simple teammates
- Set `maxTurns` on all team members
- Keep teams small (2-3 teammates)
- Use subagents for independent tasks, teams only for coordinated work

---

## Preparing for Teams (Do Now)

Even without enabling teams, prepare your agent infrastructure:

1. **Standardize agent frontmatter**: Valid models, memory fields, maxTurns
2. **Add monitoring hooks**: SubagentStart/SubagentStop for visibility
3. **Design team groupings**: Document which agents work together
4. **Keep agents focused**: One clear responsibility per agent

This groundwork makes team adoption seamless when the feature stabilizes.

---

**Previous**: [36: Agents and Subagents](36-agents-and-subagents.md)
**Next**: (Future chapters)
