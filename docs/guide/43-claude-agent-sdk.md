---
layout: default
title: "Claude Agent SDK - Build Custom AI Agents Programmatically"
description: "Build custom Claude agents with the Claude Agent SDK. Covers stateless vs stateful agents, tool permissions, MCP integration, plan mode, and setting sources."
---

# Chapter 43: Claude Agent SDK

The Claude Agent SDK (`@anthropic-ai/claude-code-sdk`) lets you build custom agents programmatically, embedding Claude Code's capabilities into your own applications. This chapter covers the SDK's architecture, key configuration options, and how it differs from the CLI-based agent system.

**Purpose**: Build programmatic agents using the Claude Agent SDK
**Source**: Anthropic claude-cookbooks (observability_agent.ipynb, SDK documentation)
**Difficulty**: Advanced
**Time**: 2-4 hours for first agent

---

## SDK vs CLI Agents

| Aspect        | CLI Agents (`.claude/agents/`)   | SDK Agents (`claude-code-sdk`)       |
| ------------- | -------------------------------- | ------------------------------------ |
| Definition    | Markdown files with frontmatter  | JavaScript/TypeScript code           |
| Execution     | Via `Task()` tool in Claude Code | Via your own application             |
| Configuration | YAML frontmatter                 | Programmatic API                     |
| Tool control  | `tools:` field                   | `allowed_tools` + `disallowed_tools` |
| Context       | Inherits from parent session     | Fully configurable                   |
| Use case      | Extend Claude Code workflows     | Build standalone AI apps             |

**When to use the SDK**: Building your own AI application, CI/CD integration, custom workflows outside Claude Code. **When to use CLI agents**: Extending Claude Code's capabilities for interactive development.

---

## Quick Start

```javascript
import { Agent } from "@anthropic-ai/claude-code-sdk";

const agent = new Agent({
  model: "claude-sonnet-4-5-20250929",
  systemPrompt: "You are a code review specialist.",
  tools: ["Read", "Grep", "Glob"],
  maxTurns: 10,
});

const result = await agent.run("Review src/auth/ for security issues");
console.log(result.response);
```

---

## Tool Permissions (Critical Distinction)

The SDK has three tool permission mechanisms that behave differently from CLI agent frontmatter:

### `tools` (Available Tools)

Defines which tools the agent can use. Similar to CLI `tools:` field.

```javascript
const agent = new Agent({
  tools: ["Read", "Grep", "Glob", "Bash"],
});
```

### `allowed_tools` (Auto-Approve)

Tools in this list run **without asking the user for permission**. Other tools are still available but require approval.

```javascript
const agent = new Agent({
  allowed_tools: ["Read", "Grep"], // These run silently
  // Write, Edit, Bash still available but prompt for permission
});
```

**Key difference from CLI**: In CLI frontmatter, `tools: [...]` RESTRICTS to those tools only. In SDK, `allowed_tools` AUTO-APPROVES without restricting.

### `disallowed_tools` (Removed Entirely)

Tools in this list are **removed from the agent's context**. The agent cannot see or use them at all.

```javascript
const agent = new Agent({
  disallowed_tools: ["Bash", "Write"], // Completely invisible to agent
});
```

**When to use**: Security-sensitive agents that should never execute commands or modify files. The agent won't even know these tools exist.

### Permission Summary

| Mechanism          | Tools visible? | User prompt? | Use case                 |
| ------------------ | -------------- | ------------ | ------------------------ |
| `tools`            | Listed only    | Yes          | Restrict available tools |
| `allowed_tools`    | All            | No (listed)  | Auto-approve safe tools  |
| `disallowed_tools` | All minus list | N/A          | Remove dangerous tools   |

---

## Stateless vs Stateful Agents

### Stateless (Default)

Each invocation starts fresh. No memory of previous calls.

```javascript
const agent = new Agent({ model: "claude-sonnet-4-5-20250929" });

// Each call is independent:
await agent.run("Check database schema"); // Fresh context
await agent.run("Deploy to staging"); // Fresh context, no memory of schema check
```

**Use for**: One-off tasks, CI/CD steps, isolated operations.

### Stateful (With Memory)

Agent remembers across invocations using setting sources.

```javascript
const agent = new Agent({
  model: "claude-sonnet-4-5-20250929",
  settingSources: {
    project: "/path/to/project",
    user: "~/.claude",
  },
});
```

Setting sources load CLAUDE.md, rules, skills, and agent definitions from the specified locations. This gives the SDK agent the same context as a CLI session.

**Use for**: Long-running workflows, agents that need project context, development assistants.

---

## Setting Sources

Setting sources control what context the SDK agent loads at startup:

```javascript
const agent = new Agent({
  settingSources: {
    // Load project-level context (CLAUDE.md, .claude/rules/, .claude/skills/)
    project: "/home/user/my-project",

    // Load user-level context (~/.claude/CLAUDE.md, ~/.claude/rules/, ~/.claude/skills/)
    user: "/home/user",

    // Load enterprise-level context (organization-managed)
    enterprise: "/etc/claude/enterprise",
  },
});
```

### Priority Order

When the same setting exists at multiple levels, higher priority wins:

```
1. Enterprise (highest)
2. Project
3. User (lowest)
```

This matches the CLI behavior where project rules override user rules.

---

## MCP Integration

SDK agents can connect to MCP servers for external tool access:

```javascript
const agent = new Agent({
  mcpServers: {
    postgres: {
      command: "npx",
      args: [
        "-y",
        "@anthropic-ai/mcp-server-postgres",
        "postgresql://localhost/mydb",
      ],
    },
    memory: {
      command: "npx",
      args: ["-y", "@anthropic-ai/mcp-server-memory"],
    },
  },
});
```

The agent can then use MCP tools like `mcp__postgres__query()` and `mcp__memory__write_note()`.

---

## Plan Mode

SDK agents can use plan mode for complex tasks:

```javascript
const agent = new Agent({
  planMode: true, // Agent plans before executing
});
```

In plan mode, the agent:

1. Explores the codebase (read-only tools)
2. Writes a plan to a plan file
3. Presents the plan for approval
4. Executes after approval

**When to use**: Complex multi-file changes, architectural decisions, anything where you want to review the approach before execution.

---

## Permission Mode

Control how the agent handles permission requests:

```javascript
const agent = new Agent({
  permissionMode: "dontAsk", // Auto-deny all permission prompts
});
```

| Mode        | Behavior                              | Use case             |
| ----------- | ------------------------------------- | -------------------- |
| `default`   | Prompts user for dangerous operations | Interactive use      |
| `dontAsk`   | Auto-denies permission prompts        | Background agents    |
| `yesAlways` | Auto-approves all permissions         | Trusted environments |

**`dontAsk` is essential for background agents** -- they can't prompt a user who isn't watching.

---

## Hooks in SDK Agents

SDK agents support the same hook events as CLI agents:

```javascript
const agent = new Agent({
  hooks: {
    PreToolUse: [
      {
        matcher: { tool_name: "Bash" },
        hooks: [
          {
            type: "command",
            command: "./validate-command.sh",
          },
        ],
      },
    ],
  },
});
```

All 14 hook events are supported. See [Chapter 13: Hooks](13-claude-code-hooks.md) for event details.

---

## Example: CI Code Review Agent

```javascript
import { Agent } from "@anthropic-ai/claude-code-sdk";

async function reviewPR(prNumber) {
  const agent = new Agent({
    model: "claude-sonnet-4-5-20250929",
    tools: ["Read", "Grep", "Glob", "Bash"],
    allowed_tools: ["Read", "Grep", "Glob"], // Auto-approve reads
    disallowed_tools: ["Write", "Edit"], // Cannot modify files
    maxTurns: 15,
    settingSources: {
      project: process.cwd(),
    },
  });

  const result = await agent.run(
    `Review PR #${prNumber}. Check for:
     1. Security vulnerabilities
     2. Missing error handling
     3. Test coverage gaps
     Return findings as a markdown checklist.`,
  );

  return result.response;
}
```

This agent can read and search the codebase but cannot modify files, making it safe for automated CI pipelines.

---

**Previous**: [42: Session Memory and Compaction](42-session-memory-compaction.md)
**Next**: [44: Skill Design Principles](44-skill-design-principles.md)
