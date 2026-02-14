---
layout: default
title: "Claude Code Agents & Subagents - Create Specialized AI Workers"
description: "Create custom Claude Code agents with persistent memory, model selection, and tool restrictions. Domain expert, lightweight scout, and expensive expert patterns."
---

# Chapter 36: Agents and Subagents

Claude Code agents (subagents) are specialized AI workers you create as markdown files in `.claude/agents/`. Each agent gets its own context window, can use a specific model (sonnet, opus, haiku), has persistent memory across conversations, and can be restricted to specific tools. This guide covers 3 proven agent design patterns and production configuration.

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
memory: project            # Optional: project (per-project) or user (cross-project)
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

| Field         | Required | Values                        | Purpose                          |
| ------------- | -------- | ----------------------------- | -------------------------------- |
| `name`        | Yes      | kebab-case identifier         | Agent name for Task() calls      |
| `description` | Yes      | What it does + "Use when..."  | Routing guidance                 |
| `model`       | No       | `sonnet`, `opus`, `haiku`     | Override model (default: parent) |
| `tools`       | No       | Array of tool names           | Restrict available tools         |
| `memory`      | No       | `project`, `user`, or `local` | Persistent memory (see below)    |
| `maxTurns`    | No       | Number (e.g., 15)             | Max API round-trips              |

### Model Selection

| Model    | Use For                      | Cost    |
| -------- | ---------------------------- | ------- |
| `haiku`  | Quick searches, simple tasks | Lowest  |
| `sonnet` | Most tasks (default)         | Medium  |
| `opus`   | Complex reasoning, planning  | Highest |

**Important**: Use valid model IDs only: `sonnet`, `opus`, `haiku`. Values like `sonnet-4`, `claude-sonnet`, etc. are **invalid** and will fail silently. You can also specify full model IDs like `claude-sonnet-4-5-20250929` for version pinning.

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

### `memory: local`

Personal memory, not committed to git. Agent remembers YOUR personal patterns.

```yaml
memory: local
```

**Use for**: Personal workflow agents, experimental agents, developer-specific preferences.
Local memory is stored in `.claude/settings.local.json` and not shared with the team.

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

## Tool Restrictions with Task(agent_type)

You can restrict which sub-agents an agent can spawn by using `Task(agent_type)` syntax in the `tools` field:

```yaml
---
name: api-coordinator
description: "Coordinates API operations with intelligent routing."
tools:
  ["Read", "Write", "Edit", "Bash", "Task(shifts-agent)", "Task(beecom-agent)"]
---
```

This agent can only spawn `shifts-agent` and `beecom-agent` via `Task()`. Attempts to spawn other agent types will be blocked.

**When to use**: Agents that delegate to known specialists (API coordinator -> shifts/beecom, deploy -> gcp, data integrity -> accuracy).

**When NOT to use**: Agents that need flexibility to spawn any agent type (e.g., a branch policy enforcer that may need any specialist).

### Examples

```yaml
# Deploy agent can only delegate to GCP infrastructure agent
tools: ['Read', 'Write', 'Edit', 'Bash', 'Task(gcp-agent)']

# Data integrity agent can only delegate to accuracy specialist
tools: ['Read', 'Edit', 'Bash', 'Task(accuracy-agent)']

# Context orchestrator can only delegate to context agent
tools: ['Read', 'Task(context-agent)']
```

**Benefits**: Prevents wrong routing (an API coordinator accidentally spawning a deploy agent), reduces token waste from misrouted sub-agent calls, and makes agent responsibilities explicit.

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

## Tool Permission Models

Claude Code has two distinct tool permission mechanisms. Understanding the difference prevents common configuration mistakes.

### `allowed-tools` (Frontmatter / Settings)

Used in skill or agent frontmatter. **Restricts** the agent to ONLY the listed tools -- all other tools are unavailable.

```yaml
---
name: read-only-agent
tools: ["Read", "Grep", "Glob"] # Can ONLY use these 3 tools
---
```

### `allowed_tools` (Claude Agent SDK)

Used in the Claude Agent SDK (`claude-sdk`). **Auto-approves** the listed tools (no user permission prompt), but does NOT restrict access. All other tools remain available -- they just require user approval.

```python
# SDK: These tools run without permission prompts, but all tools are still AVAILABLE
agent = Agent(allowed_tools=["Read", "Grep", "Glob"])
```

### `disallowed_tools` (Claude Agent SDK)

Used in the Claude Agent SDK only. **Removes** tools from the agent's context entirely -- the agent cannot use them at all, not even with user permission.

```python
# SDK: These tools are completely invisible to the agent
agent = Agent(disallowed_tools=["Bash", "Write"])
```

### Quick Reference

| Mechanism          | Where Used        | Effect                                           |
| ------------------ | ----------------- | ------------------------------------------------ |
| `tools` (list)     | Agent frontmatter | Agent can ONLY use listed tools                  |
| `allowed_tools`    | Claude SDK        | Auto-approve (no prompt), others still available |
| `disallowed_tools` | Claude SDK        | Tools removed entirely from agent                |

**Key insight**: In frontmatter, `tools: [...]` restricts. In SDK, `allowed_tools` auto-approves but does NOT restrict. They are different behaviors despite similar names.

---

## Query Classification for Agent Routing

When deciding how many agents to spawn and how to coordinate them, classify the incoming query:

### Depth-First

**When**: Multiple perspectives needed on the same topic.

```
"Investigate slow AI queries"
  → database-agent (check query plans)
  → ai-agent (check prompt size)
  → monitoring-agent (check latency metrics)
  = 3 agents exploring DIFFERENT ANGLES of ONE problem
```

### Breadth-First

**When**: Multiple independent sub-questions.

```
"Check all environments are healthy"
  → staging-agent (check staging)
  → production-agent (check production)
  → localhost-agent (check local)
  = 1 agent PER QUESTION, running in parallel
```

### Straightforward

**When**: Focused lookup or single-domain task.

```
"Check employee count in database"
  → database-agent only
  = SINGLE agent, <5 tool calls
```

### Subagent Budget Guidelines

| Complexity   | Agents | Tool Calls Each | Total Budget |
| ------------ | ------ | --------------- | ------------ |
| Simple       | 1      | <5              | ~5 calls     |
| Standard     | 2-3    | ~5              | ~15 calls    |
| Complex      | 3-5    | ~10             | ~50 calls    |
| Very Complex | 5-10   | up to 15        | ~100 calls   |

**Rule**: More subagents = more overhead. Only add agents when they provide distinct value. A single well-prompted agent often beats 3 poorly-scoped ones.

**Source**: Anthropic research_lead_agent.md, orchestrator_workers.ipynb

---

## "Fresh Eyes" QA Pattern

After generating complex output (multi-file changes, generated artifacts, deployments), spawn a verification subagent. The subagent has fresh context and will catch issues that the generating agent -- which has been staring at the code -- will miss.

```
// After generating code:
Task(
  subagent_type: "Explore",
  prompt: "Verify the changes in src/auth/ are consistent and follow project patterns. Check for typos, missing imports, and logic errors.",
  model: "haiku"  // Cheap verification
)
```

**Why it works**: The generating agent sees what it expects, not what is there. A fresh subagent has no bias from the generation process.

**When to use**:

- After multi-file refactoring
- After generating test suites
- After deployment configuration changes
- After any output that will be hard to review manually

**Source**: Anthropic pptx and doc-coauthoring skills both use this pattern.

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
