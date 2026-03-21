---
layout: default
title: "Claude Code Skills Cookbook — Official Patterns for Building, Optimizing, and Distributing Skills"
description: "Practical patterns from Anthropic's official cookbooks: skill design, effort frontmatter, context isolation, agent patterns (ReAct, Orchestrator-Workers, Research Subagent), plugin development, and session memory compaction."
---

# Chapter 58: Claude Code Skills Cookbook — Official Patterns

Anthropic published a series of cookbooks and documentation covering skill design, agent orchestration patterns, and plugin development. This chapter distills the practical patterns most relevant to Claude Code power users. Sources: claude-cookbooks-docs, claude-code-docs, and Anthropic engineering blog (March 2026).

---

## 1. Skill Design Patterns

### 1.1 Effort Frontmatter (New in 2.1.80)

Skills and slash commands can now override the session's effort level:

```yaml
---
name: my-skill
description: When to invoke this skill
effort: low    # low | medium | high
---
```

**Guidelines:**
- `low`: Quick lookups, reference checks, status queries (~1-2 tool calls)
- `medium`: Standard workflows, file modifications, moderate analysis (~3-10 tool calls)
- `high`: Complex analysis, multi-file changes, architectural decisions (~10+ tool calls)

### 1.2 Context Isolation with `context: fork`

Heavy skills should run in a fresh subagent to avoid polluting the main conversation context:

```yaml
---
name: deep-analysis
description: Run comprehensive code analysis
context: fork    # Runs in isolated subagent
effort: high
allowed-tools: Read, Grep, Glob, Bash
---
```

**When to use `context: fork`:**
- Skills that read many files (analysis, audits)
- Skills that produce verbose output (reports, summaries)
- Skills where intermediate work shouldn't consume main context

**When NOT to use it:**
- Skills that need to modify files (edits don't propagate back from fork)
- Simple reference lookups
- Skills that need conversation history

### 1.3 Disable Model Invocation for Side Effects

Skills that perform irreversible actions (deploy, send messages, delete data) should require manual invocation:

```yaml
---
name: production-deploy
description: Deploy to production
disable-model-invocation: true  # MUST be /deploy, never auto-triggered
effort: medium
---
```

### 1.4 Supporting Files Pattern

Keep SKILL.md under 500 lines. Move detailed reference material to companion files:

```
~/.claude/skills/my-skill/
├── SKILL.md          # <500 lines — instructions + key info
├── reference.md      # Detailed docs (loaded on-demand by Claude)
├── examples.md       # Usage examples
└── scripts/          # Helper scripts
```

Claude reads SKILL.md when the skill triggers. It reads reference.md/examples.md only if it needs more detail — this is lazy loading by design.

---

## 2. Agent Orchestration Patterns (from Anthropic Cookbooks)

### 2.1 ReAct Pattern (Reasoning + Acting)

The agent reasons about its next step, takes an action, observes the result, and repeats:

```
Think → Act → Observe → Think → Act → Observe → ... → Answer
```

**Claude Code implementation:** This is the default behavior. Claude naturally follows ReAct when given tools. Optimize by:
- Providing clear tool descriptions
- Limiting available tools to reduce decision space
- Using `maxTurns` to prevent runaway loops

### 2.2 Orchestrator-Workers Pattern

A lead agent delegates subtasks to specialized workers:

```
Orchestrator (main context)
  ├── Worker 1: Database analysis (subagent)
  ├── Worker 2: API investigation (subagent)
  └── Worker 3: Frontend check (subagent)
```

**Claude Code implementation:** Use the Agent/Task tool with specialized subagents:

```yaml
# In orchestrator prompt:
# 1. Read the plan
# 2. Delegate each task via Task() with file paths
# 3. Collect results and verify
# 4. Never accumulate worker outputs in orchestrator context
```

**Key rule:** Orchestrator stays lean (<20% context). Each worker gets a fresh window.

### 2.3 Research Subagent Pattern

A dedicated research agent explores broadly, then reports findings:

```yaml
---
name: research-agent
description: Deep codebase research with comprehensive findings
model: sonnet
tools: Read, Grep, Glob, WebFetch
effort: high
maxTurns: 20
disallowedTools: [Write, Edit]  # Read-only research
---
```

The research agent can explore freely without risking accidental modifications.

### 2.4 Using Haiku as a Sub-Agent

For fast, cheap operations (classification, routing, simple lookups):

```yaml
---
name: classifier
description: Quick intent classification
model: haiku
effort: low
maxTurns: 5
---
```

**Best for:** Triage, categorization, yes/no decisions, data extraction from structured sources.

---

## 3. Plugin Development Patterns (from claude-code-docs)

### 3.1 Plugin Structure

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json          # Manifest (required)
├── skills/
│   └── my-skill/SKILL.md   # Skills (NOT inside .claude-plugin/)
├── agents/
│   └── my-agent.md         # Agents
├── hooks/
│   └── hooks.json          # Hook definitions
├── .mcp.json               # MCP server configs
└── settings.json           # Default settings
```

**Critical:** Skills, agents, and hooks go at the plugin root — NOT inside `.claude-plugin/`.

### 3.2 Plugin Persistent State (New in 2.1.78)

```yaml
# Use ${CLAUDE_PLUGIN_DATA} for state that survives plugin updates
# /plugin uninstall prompts before deleting it
```

### 3.3 Settings-Based Plugins (New in 2.1.80)

Declare plugins inline in settings.json instead of external repos:

```json
{
  "enabledPlugins": {
    "my-plugin@source": true
  }
}
```

---

## 4. Session Memory Compaction

### 4.1 What Happens During Compaction

When context fills (~95%), Claude compresses the conversation:
1. Summarizes conversation history (high-fidelity compression)
2. Discards redundant tool outputs
3. Preserves architectural decisions and unresolved issues
4. Fires `PostCompact` hook for context re-injection

### 4.2 PostCompact Hook Pattern

Re-inject critical context that may be lost during compaction:

```json
{
  "hooks": {
    "PostCompact": [{
      "hooks": [{
        "type": "command",
        "command": "echo 'Key context: [project-specific reminders here]'"
      }]
    }]
  }
}
```

### 4.3 Compaction Instructions in CLAUDE.md

```markdown
When compacting, preserve:
- Full list of all modified files
- Summary of architecture decisions made
- Test commands that passed/failed
- Current task progress and next steps
```

---

## 5. Prompt Caching and Cost Optimization

### 5.1 Speculative Prompt Caching

Pre-warm the cache with context you'll use repeatedly:
- System prompts are cached automatically
- CLAUDE.md content benefits from caching (loaded every turn)
- Keep CLAUDE.md stable (frequent changes invalidate cache)

### 5.2 Context Budget Guidelines (1M Window)

| Category | Budget | Notes |
|----------|--------|-------|
| System prompt | ~7K | Fixed, cached |
| CLAUDE.md + rules | <20K | Keep under 200 lines each |
| Auto memory | <5K | First 200 lines of MEMORY.md |
| Skill descriptions | ~2% | Loaded for routing decisions |
| MCP tool descriptions | Variable | Use tool search for large registries |
| Working context | Remaining | Conversation + file reads |

**75% rule:** Checkpoint at 75% context usage — quality degrades past this point.

---

## 6. Key Takeaways

1. **Skills are lazy-loaded** — only descriptions load at startup; full content loads on-demand
2. **Use `effort:` frontmatter** — reduces token usage for simple skills (new in 2.1.80)
3. **Use `context: fork`** for heavy analysis skills — keeps main context clean
4. **Use `disable-model-invocation: true`** for side-effect skills (deploy, send, delete)
5. **Keep SKILL.md under 500 lines** — split to reference.md for detailed docs
6. **Orchestrator stays lean** — delegate to subagents, don't accumulate their outputs
7. **Use Haiku for cheap operations** — classification, routing, simple lookups
8. **PostCompact hooks** — re-inject critical context after compaction on every project
9. **CLAUDE.md stability** — frequent changes invalidate prompt cache
10. **Plugin structure** — skills/agents/hooks at root, NOT inside .claude-plugin/

---

## See Also

- [Chapter 57: Claude Code 2.1.77-2.1.81 Features](57-claude-code-2177-2181-features.md)
- [Chapter 54: Claude Code 2.1.73-2.1.76 Features](54-claude-code-2176-new-features.md)
- [Chapter 44: Skill Design Principles](44-skill-design-principles.md)
- [Chapter 48: Lean Orchestrator Pattern](48-lean-orchestrator-pattern.md)
- [Chapter 56: Context Optimization for Mature Projects](56-context-optimization-mature-projects.md)
- [Anthropic: Building Effective Agents](https://docs.anthropic.com/en/docs/build-with-claude/agents)
- [Anthropic: Effective Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
