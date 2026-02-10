# Chapter 36: Agents and Subagents

**Purpose**: Create, configure, and use custom agents for specialized tasks
**Source**: Anthropic Claude Code documentation + production patterns
**Difficulty**: Intermediate
**Time**: 30 minutes to set up first agent

---

## Overview

Agents (subagents) are specialized Claude Code workers you spawn via the `Task()` tool. Each agent gets its own context window, can have a specific model, tools, and persistent memory.

**When to use agents**:

- Complex multi-step tasks that benefit from isolation
- Parallel execution of independent work
- Domain expertise (database, deployment, testing, etc.)
- Protecting your main context window from large outputs

**When NOT to use agents**:

- Simple file reads or searches (use Glob/Grep/Read directly)
- Tasks that need the full conversation context
- Quick one-off operations

---

## Agent File Structure

Agents live in `.claude/agents/` as markdown files:

```
.claude/agents/
  deploy-agent.md
  database-agent.md
  test-engineer.md
  debug-specialist.md
```

Each file has YAML frontmatter + markdown body.

---

## Agent Frontmatter (All Fields)

```yaml
---
name: deploy-agent
description: "Deployment specialist for GCP Cloud Run. Use when deploying to staging or production."
model: sonnet              # Optional: sonnet, opus, haiku (inherits from parent if omitted)
tools: ['Read', 'Write', 'Edit', 'Bash', 'Grep', 'Glob']  # Optional: restrict available tools
memory: project            # Optional: persistent memory across conversations
maxTurns: 15               # Optional: limit API round-trips (cost control)
---

# Deploy Agent

You are a deployment specialist...

## Your Responsibilities
- Deploy to GCP Cloud Run
- Verify traffic routing
- Run health checks

## Key Patterns
- Always route traffic after deployment
- Check health endpoint after deploy
...
```

### Field Reference

| Field         | Required | Values                       | Purpose                          |
| ------------- | -------- | ---------------------------- | -------------------------------- |
| `name`        | Yes      | kebab-case identifier        | Agent name for Task() calls      |
| `description` | Yes      | What it does + "Use when..." | Routing guidance                 |
| `model`       | No       | `sonnet`, `opus`, `haiku`    | Override model (default: parent) |
| `tools`       | No       | Array of tool names          | Restrict available tools         |
| `memory`      | No       | `project` or `user`          | Persistent memory (see below)    |
| `maxTurns`    | No       | Number (e.g., 15)            | Max API round-trips              |

### Model Selection

| Model    | Use For                      | Cost    |
| -------- | ---------------------------- | ------- |
| `haiku`  | Quick searches, simple tasks | Lowest  |
| `sonnet` | Most tasks (default)         | Medium  |
| `opus`   | Complex reasoning, planning  | Highest |

**Important**: Use valid model IDs only. `sonnet-4`, `claude-sonnet`, etc. are **invalid** and will fail silently.

---

## Memory Persistence

The `memory` field enables agents to learn across conversations.

### `memory: project`

Scoped to the current project. Agent remembers project-specific patterns.

```yaml
memory: project
```

**Use for**: Most agents (deploy, database, testing, debugging).
The agent builds knowledge about YOUR project's patterns, common issues, and solutions.

### `memory: user`

Cross-project memory. Agent remembers patterns across ALL your projects.

```yaml
memory: user
```

**Use for**: Architecture agents, coding style agents — anything where cross-project knowledge is valuable.

### No memory field

Agent starts fresh every conversation. No persistence.

**Use for**: Simple utility agents, one-off tasks.

---

## Cost Control with maxTurns

Expensive agents (opus model, complex tasks) should have turn limits:

```yaml
model: opus
maxTurns: 15 # Stops after 15 API round-trips
```

**Guidelines**:

- Simple search agents: 5-10 turns
- Standard work agents: 10-15 turns
- Complex deployment agents: 15-25 turns
- No limit: omit the field (runs until task complete)

---

## Spawning Agents

Use the `Task()` tool to spawn agents:

```
Task(
  subagent_type: "deploy-agent",
  description: "Deploy to staging",
  prompt: "Deploy the current branch to staging and verify health",
  model: "sonnet"  // Optional override
)
```

### Parallel Execution

Spawn multiple independent agents simultaneously:

```
// In a single message, call multiple Task() tools:
Task(subagent_type: "test-engineer", prompt: "Run all tests")
Task(subagent_type: "database-agent", prompt: "Check schema consistency")
Task(subagent_type: "deploy-agent", prompt: "Verify staging health")
```

All three run in parallel and return results independently.

### Background Agents

For long-running tasks:

```
Task(
  subagent_type: "database-agent",
  prompt: "Run comprehensive data validation",
  run_in_background: true
)
```

Check later with `TaskOutput(task_id: "...")` or `Read` the output file.

---

## Creating Your First Agent

### Step 1: Create the file

```bash
mkdir -p .claude/agents
```

### Step 2: Write the agent

```markdown
---
name: code-reviewer
description: "Reviews code for bugs, security issues, and best practices. Use when reviewing PRs or checking code quality."
model: sonnet
tools: ["Read", "Grep", "Glob"]
memory: project
---

# Code Reviewer

You are a code review specialist.

## Review Checklist

- Security vulnerabilities (OWASP top 10)
- Error handling completeness
- Edge cases
- Performance issues
- Code style consistency

## Output Format

For each issue found:

1. File and line number
2. Severity (critical/warning/info)
3. Description
4. Suggested fix
```

### Step 3: Use it

```
Task(
  subagent_type: "code-reviewer",
  prompt: "Review the changes in src/auth/ for security issues"
)
```

---

## Agent Design Patterns

### 1. Domain Expert Pattern

Agent knows one domain deeply:

```yaml
name: database-agent
description: "Database operations specialist. Use when working with schemas, migrations, queries, or data integrity."
tools: ["Read", "Bash", "Grep"]
memory: project
```

### 2. Lightweight Scout Pattern

Quick exploration agent with minimal cost:

```yaml
name: codebase-explorer
description: "Fast codebase exploration. Use when searching for files, patterns, or understanding structure."
model: haiku
tools: ["Read", "Grep", "Glob"]
maxTurns: 10
```

### 3. Expensive Expert Pattern

High-quality reasoning for critical tasks:

```yaml
name: architecture-agent
description: "System architecture decisions. Use when planning major refactors or new features."
model: opus
memory: user # Cross-project architectural knowledge
maxTurns: 15
```

---

## Monitoring Agents

Use hooks to track agent lifecycle:

```json
{
  "SubagentStart": [
    {
      "hooks": [
        { "type": "command", "command": ".claude/hooks/subagent-monitor.sh" }
      ]
    }
  ],
  "SubagentStop": [
    {
      "hooks": [
        { "type": "command", "command": ".claude/hooks/subagent-monitor.sh" }
      ]
    }
  ]
}
```

See [Chapter 13: Hooks](13-claude-code-hooks.md) for the monitor script implementation.

---

## Tips

- **Keep agent prompts focused**: One clear responsibility per agent
- **Use `memory: project`** for agents you use repeatedly — they get better over time
- **Don't over-agent**: Simple tasks (reading a file, running a command) don't need agents
- **Monitor costs**: Add `maxTurns` to expensive agents, use `haiku` for simple searches
- **Test agents**: Spawn them with a test prompt before relying on them in workflows

---

**Previous**: [35: Skill Optimization](35-skill-optimization-maintenance.md)
**Next**: [37: Agent Teams](37-agent-teams.md)
