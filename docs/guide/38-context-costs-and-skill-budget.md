---
layout: default
title: "Claude Code Context Costs & Skill Budget - Measure What Loads When"
description: "Understand what consumes context in Claude Code: CLAUDE.md, skills, agents, MCP tools, and hooks. Optimize your skill description budget and agent overhead with real measurements."
---

# Chapter 38: Context Costs and Skill Budget

Every message you send to Claude Code loads a set of context: your CLAUDE.md, skill descriptions, agent descriptions, and MCP tool definitions. Understanding what loads when -- and what it costs in tokens -- is the difference between a responsive setup and one that silently drops skills or wastes budget on duplicates. This chapter breaks down the context cost of each extension point, explains the skill description budget, and provides real-world measurements from a production project.

**Purpose**: Understand and optimize context consumption across Claude Code extension points
**Source**: Claude Code documentation + production measurements (LIMOR AI: 224 skills, 52 agents, 5 MCP servers)
**Difficulty**: Intermediate
**Time**: 30 minutes to audit, 1-2 hours to optimize

---

## Overview

Claude Code's context window is finite. Every extension point you configure consumes some portion of it. The critical insight is that **most costs are per-message**, not per-session. A bloated CLAUDE.md or excessive skill descriptions eat into your available context on every single turn.

**Key principle**: Minimize always-loaded context. Push details into on-demand loading (full skill content, agent bodies, on-demand files).

---

## Context Cost Table

This table shows what loads when for each Claude Code extension point:

| Extension Point                | When It Loads      | Per-Message Cost                 | Notes                                             |
| ------------------------------ | ------------------ | -------------------------------- | ------------------------------------------------- |
| `CLAUDE.md` + `.claude/rules/` | Every message      | Full content                     | Biggest fixed cost. Keep lean.                    |
| Skill descriptions             | Every message      | Subject to 2% budget             | Only the YAML frontmatter `description` field     |
| Skill full content             | On invocation only | Full `.md` body                  | Loaded when user or model triggers the skill      |
| Agent descriptions             | Every message      | Full `description` field         | From frontmatter of each `.claude/agents/*.md`    |
| Agent full content             | Only when spawned  | Loaded into subagent context     | Via `Task()` tool -- does not affect main context |
| Hooks                          | Zero context cost  | None                             | Shell scripts, run externally, no token impact    |
| MCP tool list                  | Every message      | Tool name + description + schema | Grows with number of MCP servers and tools        |

### What This Means

- **CLAUDE.md** is your largest fixed cost. Every line you add is repeated every message. Ruthlessly prune it.
- **Skill descriptions** are capped by a budget (see next section). Exceeding it means skills get silently excluded.
- **Agent descriptions** have no formal cap but add up. 50 agents with verbose descriptions waste tokens.
- **Hooks** are free. They run as external shell commands and add zero tokens to context. Prefer hooks over CLAUDE.md rules when possible.
- **MCP tools** list their schemas every message. 5 MCP servers with 70 tools is meaningful overhead.

---

## Skill Description Budget

Claude Code enforces a budget on how much total skill description text is loaded per message. Skills that exceed the budget are silently excluded -- no warning, no error, they simply do not appear to the model.

### Default Budget

```
2% of the context window = approximately 16,000 characters
```

This budget covers the combined `description` field from all skill files across all levels (enterprise, personal, project).

### Overriding the Budget

Set the environment variable in your shell profile:

```bash
# In ~/.bashrc or ~/.zshrc
export SLASH_COMMAND_TOOL_CHAR_BUDGET=40000
```

This increases the budget to 40,000 characters. Useful when you have a large skill library, but be aware it steals from your available context for conversation.

### Description Format Best Practices

Each skill's `description` field in its YAML frontmatter should follow this pattern:

```yaml
---
description: "Deploy to GCP Cloud Run staging or production. Use when deploying, checking revisions, or routing traffic."
---
```

**Rules**:

- **Maximum**: 1024 characters per skill description
- **Format**: Action verb + what it does + "Use when X, Y."
- **Goal**: Tell the model WHEN to pick this skill, not HOW it works internally

Good:

```yaml
description: "Validate database schema against Sacred Commandments. Use when checking table structure, column types, or Golden Rule compliance."
```

Bad:

```yaml
description: "This skill helps with database work. It has patterns for employees, shifts, orders, and more. It covers Sacred Commandments I, IV, VIII, XII, and XIV with detailed examples and SQL queries."
```

The bad example wastes budget on details that belong in the skill body, not the description.

### Budget Monitoring: When You're Near the Limit

At high utilization (>90%), adding a single skill can silently drop others. Monitor and enforce:

```bash
# Measure current budget usage
total=0
for f in $(find ~/.claude/skills -name "SKILL.md") $(find .claude/skills -name "SKILL.md"); do
  desc=$(grep "^description:" "$f" | sed 's/^description: *//;s/^"//;s/"$//')
  total=$((total + ${#desc}))
done
echo "Budget: $total / ${SLASH_COMMAND_TOOL_CHAR_BUDGET:-16000} chars"
```

**What to do when budget is tight**:

1. **Move unused skills** to `~/.claude/skills-disabled/` (not loaded, but recoverable)
2. **Trim verbose descriptions** — target 80-150 chars, not 300+
3. **Use `disable-model-invocation: true`** for user-only skills (removes from budget)
4. **Move project-specific skills** from `~/.claude/skills/` (global) to `.claude/skills/` (per-project) so they only load where needed

**Real example**: A project hit 98.7% budget (39,480/40,000 chars). Four skills unrelated to the active project were moved to `skills-disabled/`, bringing usage to 93.4% with 2,639 chars headroom.

### Skills Outside the Budget

Two mechanisms remove skills from the description budget entirely:

**1. `disable-model-invocation: true`**

```yaml
---
name: my-manual-skill
description: "Generate weekly report for Slack."
disable-model-invocation: true
---
```

This makes the skill a user-only slash command. The model cannot invoke it autonomously, and it does **not** count against the description budget. Use this for skills that should only run when the user explicitly types `/my-manual-skill`.

**2. `context: fork`**

```yaml
---
name: heavy-analysis
description: "Run deep code analysis across the entire repository."
context: fork
---
```

This runs the skill in an isolated subagent context, separate from the main conversation. The skill's full content loads into the fork, not the main context window. The description still counts against the budget, but the body content is isolated.

### Keeping Skills Under Size

- Keep the main `SKILL.md` file under 500 lines
- Move large reference data into supporting files that the skill reads on invocation:

```
~/.claude/skills/
  deploy-workflow-skill.md          # Under 500 lines
  deploy-workflow-skill/
    checklist.md                    # Supporting file
    cloud-run-commands.md           # Supporting file
```

The supporting files have zero context cost until the skill reads them during execution.

---

## Agent Optimization

Agents (`.claude/agents/*.md`) have their descriptions loaded every message. Unlike skills, there is no formal character budget -- but the cost is real.

### Priority and Deduplication

Agent loading follows a priority order. When two agents share the same name, only the higher-priority one loads:

```
Priority (highest to lowest):
1. Managed agents (Anthropic-provided)
2. CLI flag agents (--agent flag)
3. Project-level agents (.claude/agents/ in repo)
4. User-level agents (~/.claude/agents/)
5. Plugin agents
```

**Common waste**: Defining an agent at both user-level (`~/.claude/agents/deploy-agent.md`) and project-level (`.claude/agents/deploy-agent.md`). The project-level agent wins, but both descriptions may load depending on implementation. Keep agents at one level only.

### Description Length Guidelines

Keep agent descriptions short and action-focused:

```yaml
# Good: 85 characters
description: "Deploy to GCP Cloud Run. Use for staging/production deployments and traffic routing."

# Bad: 240 characters
description: "This agent is a deployment specialist that handles all aspects of deploying to Google Cloud Platform Cloud Run including staging deployments, production deployments, traffic routing, health checks, timeout configuration, and rollback procedures."
```

The model needs to know WHEN to spawn the agent, not everything it can do.

### Meta-Enforcement Agents

Avoid agents whose job is to optimize or enforce rules on other agents. These "meta-agents" add description overhead to every message while providing marginal value. Put enforcement rules in `.claude/rules/` instead (zero ongoing cost after initial load via CLAUDE.md).

---

## Practical Measurements

These measurements come from LIMOR AI, a production project with 224 skills, 52 agents, and 5 MCP servers. They illustrate real-world budget pressure.

### Before Optimization

| Component                         | Count | Total Description Chars | Approx Tokens |
| --------------------------------- | ----- | ----------------------- | ------------- |
| Skills                            | 224   | 42,165                  | ~10,541       |
| Agents                            | 52    | 9,476                   | ~2,369        |
| Duplicate agents (user + project) | 11    | ~2,400                  | ~600          |
| MCP tools                         | 70    | ~14,000                 | ~3,500        |
| **Total per-message overhead**    |       | **~68,041**             | **~17,010**   |

**Problem**: 42,165 skill description characters exceeded even the overridden 40,000 character budget. Some skills were silently excluded from model awareness.

### After Optimization

| Action                                                        | Savings                                        |
| ------------------------------------------------------------- | ---------------------------------------------- |
| Trimmed skill descriptions (removed verbose explanations)     | 42,165 -> 37,800 chars (-10%)                  |
| Removed 18 low-value agents                                   | 52 -> 34 agents (-35%)                         |
| Eliminated 11 duplicate agents                                | ~2,400 chars freed                             |
| Added `disable-model-invocation: true` to 15 user-only skills | ~3,800 chars removed from budget               |
| **Result**                                                    | Skills under 38k budget, agents under 7k chars |

### How to Measure Your Own Setup

```bash
# Count total skill description characters
find ~/.claude/skills/ .claude/skills/ -name "*.md" 2>/dev/null | \
  xargs grep -A1 "^description:" | grep -v "^--$" | wc -c

# Count agents and their description lengths
find ~/.claude/agents/ .claude/agents/ -name "*.md" 2>/dev/null | \
  while read f; do
    desc=$(grep "^description:" "$f" | head -1)
    echo "$(basename "$f"): ${#desc} chars"
  done

# Find duplicate agent names across user and project levels
comm -12 \
  <(ls ~/.claude/agents/*.md 2>/dev/null | xargs -I{} basename {} | sort) \
  <(ls .claude/agents/*.md 2>/dev/null | xargs -I{} basename {} | sort)
```

---

## Priority Order Reference

### Skills Priority

When multiple skills share the same name, the highest-priority level wins:

```
1. Enterprise skills (organization-managed)
2. Personal skills (~/.claude/skills/)
3. Project skills (.claude/skills/)
```

### Agent Priority

When multiple agents share the same name:

```
1. Managed agents (Anthropic-provided)
2. CLI flag agents (--agent)
3. Project-level agents (.claude/agents/)
4. User-level agents (~/.claude/agents/)
5. Plugin agents
```

---

## Optimization Checklist

Use this checklist to audit your Claude Code context costs:

- [ ] **CLAUDE.md**: Under 200 lines? Move details to `.claude/rules/` or on-demand files
- [ ] **Skill descriptions**: Total under budget? (default 16k chars, or your `SLASH_COMMAND_TOOL_CHAR_BUDGET`)
- [ ] **Skill descriptions**: Each under 1024 chars? Action-verb format?
- [ ] **User-only skills**: Marked with `disable-model-invocation: true`?
- [ ] **Heavy skills**: Using `context: fork` for isolation?
- [ ] **Skill bodies**: Under 500 lines? Large data in supporting files?
- [ ] **Agent descriptions**: Short and action-focused?
- [ ] **Duplicate agents**: No same-name agents at user + project level?
- [ ] **Meta-agents**: Enforcement via `.claude/rules/` instead of agents?
- [ ] **MCP servers**: Only servers you actively use connected?

---

## Key Takeaways

1. **CLAUDE.md and rules load every message**. This is your largest fixed cost. Keep it lean.
2. **Skill descriptions have a hard budget** (2% of context, ~16k chars default). Exceeding it silently drops skills.
3. **Agent descriptions have no cap** but add real overhead. Keep them short.
4. **Hooks are free**. Zero context cost. Prefer hooks for enforcement rules.
5. **Full skill/agent content loads only on invocation/spawn**. The per-message cost is only the description.
6. **Measure before optimizing**. Count your actual character usage, then trim strategically.

---

**Previous**: [37: Agent Teams](37-agent-teams.md)
