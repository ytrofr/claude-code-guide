---
layout: default
title: "Claude Agent SDK"
parent: "Part III — Extension"
nav_order: 3.5
redirect_from:
  - /docs/guide/43-claude-agent-sdk.html
  - /docs/guide/43-claude-agent-sdk/
---

# Claude Agent SDK

**Part III — Extension · Chapter 3b**

The Claude Agent SDK lets you build custom agents programmatically, embedding Claude Code's tool loop, permission system, and context management into your own applications. Available as `@anthropic-ai/claude-agent-sdk` for TypeScript and `claude-agent-sdk` for Python.

**Note on naming**: The SDK was previously called the "Claude Code SDK" (`@anthropic-ai/claude-code-sdk`). It is now the **Claude Agent SDK**. If you're migrating older code, the package name, imports, and some option keys changed. The core model — agent loop, tools, hooks — is the same.

This chapter covers what the SDK is, how it differs from the CLI, the key configuration surfaces, and the patterns that work in production.

---

## SDK vs CLI

| Aspect | CLI agents (`.claude/agents/`) | SDK (`claude-agent-sdk`) |
|---|---|---|
| Definition | Markdown files with frontmatter | Code — TS or Python |
| Execution | Via `Task` inside Claude Code | Via your own application |
| Configuration | YAML frontmatter | Programmatic options object |
| Tool control | `tools:` field | `allowedTools` / `disallowedTools` |
| Context | Inherits from parent session | Fully configurable |
| Use case | Extend Claude Code workflows | Build standalone AI apps, CI/CD |

**Use the SDK** when you're building your own application, wiring agents into CI/CD, or running custom workflows outside Claude Code. **Use CLI agents** when you're extending Claude Code's interactive workflow.

Many teams use both: CLI for daily development, SDK for production automation. Patterns translate directly.

---

## Installation

```bash
# TypeScript
npm install @anthropic-ai/claude-agent-sdk

# Python
pip install claude-agent-sdk
```

The TypeScript SDK bundles a native Claude Code binary for your platform as an optional dependency, so you don't need to install Claude Code separately.

### Authentication

```bash
export ANTHROPIC_API_KEY=your-api-key
```

The SDK also supports third-party API providers:

- **Amazon Bedrock**: `CLAUDE_CODE_USE_BEDROCK=1`
- **Google Vertex AI**: `CLAUDE_CODE_USE_VERTEX=1`
- **Microsoft Azure**: `CLAUDE_CODE_USE_FOUNDRY=1`

Configure the platform credentials separately per their own auth flows.

---

## Quick Start

The canonical entry point is `query()` — an async iterator that streams messages as the agent works.

**Python:**

```python
import asyncio
from claude_agent_sdk import query, ClaudeAgentOptions


async def main():
    async for message in query(
        prompt="Find and fix the bug in auth.py",
        options=ClaudeAgentOptions(allowed_tools=["Read", "Edit", "Bash"]),
    ):
        print(message)


asyncio.run(main())
```

**TypeScript:**

```typescript
import { query } from "@anthropic-ai/claude-agent-sdk";

for await (const message of query({
  prompt: "Find and fix the bug in auth.ts",
  options: { allowedTools: ["Read", "Edit", "Bash"] }
})) {
  console.log(message);
}
```

The SDK handles the tool loop internally — Claude reads files, runs commands, and edits code without you implementing tool dispatch. Messages stream as Claude works: tool calls, tool results, intermediate reasoning, and the final result.

---

## Stateless vs Stateful Agents

### Stateless (default)

Each `query()` invocation starts fresh. No memory of previous calls. Fastest, cheapest, and easiest to reason about.

**Use for**: one-off tasks, CI/CD steps, isolated operations, anything where each invocation should be independent.

### Stateful via sessions

Capture the `session_id` from the first query and resume to continue with full context:

```typescript
import { query } from "@anthropic-ai/claude-agent-sdk";

let sessionId: string | undefined;

// First query — capture session ID from the init message
for await (const message of query({
  prompt: "Read the authentication module",
  options: { allowedTools: ["Read", "Glob"] }
})) {
  if (message.type === "system" && message.subtype === "init") {
    sessionId = message.session_id;
  }
}

// Resume with full prior context
for await (const message of query({
  prompt: "Now find all places that call it",
  options: { resume: sessionId }
})) {
  if ("result" in message) console.log(message.result);
}
```

Sessions preserve files read, prior analysis, and conversation history. They can also be **forked** to explore alternative approaches without losing the baseline.

**Use for**: long-running workflows, interactive assistants, multi-step pipelines where later steps need earlier context.

---

## Tool Permissions

The SDK has three tool permission mechanisms. They differ meaningfully from CLI agent frontmatter, and mixing them up is the most common SDK configuration bug.

### `allowedTools` — auto-approve

Tools in this list run **without asking for permission**. Other tools remain available but will prompt (or be denied, depending on `permissionMode`).

```typescript
options: { allowedTools: ["Read", "Grep", "Glob"] }
```

### `disallowedTools` — remove entirely

Tools in this list are **removed from the agent's context**. Claude can't see or use them at all. Security-critical agents use this to ensure commands or file writes are literally impossible.

```typescript
options: { disallowedTools: ["Bash", "Write"] }
```

### Key CLI vs SDK distinction

In CLI frontmatter, `tools: [...]` **restricts** to the listed tools — everything else is unavailable. In the SDK, `allowedTools` **auto-approves** but does NOT restrict — other tools remain available. To truly restrict in the SDK, use `disallowedTools` for the tools you want to block.

| Mechanism | Tools visible? | User prompt? | Use for |
|---|---|---|---|
| `allowedTools` | All | No (listed) | Auto-approve safe tools |
| `disallowedTools` | All minus list | N/A | Remove dangerous tools |
| `permissionMode: "bypassPermissions"` | All | No (any) | Fully trusted automation |

---

## Permission Mode

Control how the agent handles permission requests.

```typescript
options: { permissionMode: "acceptEdits" }
```

| Mode | Behavior | Use case |
|---|---|---|
| `default` | Prompts for dangerous operations | Interactive use |
| `acceptEdits` | Auto-accepts file edits, prompts others | Code-writing agents |
| `plan` | Read-only explore, writes a plan file for approval | Pre-flight review |
| `bypassPermissions` | Auto-approves everything | Trusted environments only |

For background agents that can't prompt a human, either pre-approve via `allowedTools` or accept specific categories via `acceptEdits`. Avoid `bypassPermissions` for anything touching external systems — no recovery from mistakes.

---

## Setting Sources

By default the SDK loads Claude Code's filesystem config from `.claude/` in your working directory and `~/.claude/`. This includes CLAUDE.md, rules, skills, slash commands, and agent definitions — the SDK agent gets the same context as a CLI session.

To restrict which sources load:

**Python:**

```python
options = ClaudeAgentOptions(
    setting_sources=["project", "user"],   # exclude enterprise
)
```

**TypeScript:**

```typescript
options: {
  settingSources: ["project", "user"]
}
```

### Priority order

When the same setting exists at multiple levels, higher priority wins:

1. **Enterprise** (highest) — organization-managed
2. **Project** — `.claude/` in the working directory
3. **User** (lowest) — `~/.claude/`

Matches CLI behavior where project rules override user rules.

### Claude Code features available in the SDK

| Feature | Location | Description |
|---|---|---|
| Skills | `.claude/skills/*/SKILL.md` | Specialized capabilities in markdown |
| Slash commands | `.claude/commands/*.md` | Custom commands for common tasks |
| Memory | `CLAUDE.md` or `.claude/CLAUDE.md` | Project context |
| Plugins | Programmatic via `plugins` option | Bundles of commands, agents, MCP servers |

---

## MCP Integration

SDK agents connect to MCP servers the same way CLI sessions do — pass an `mcpServers` map in options.

```typescript
import { query } from "@anthropic-ai/claude-agent-sdk";

for await (const message of query({
  prompt: "Open example.com and describe what you see",
  options: {
    mcpServers: {
      playwright: { command: "npx", args: ["@playwright/mcp@latest"] }
    }
  }
})) {
  console.log(message);
}
```

Tools from MCP servers become available to the agent alongside the built-ins. Full MCP coverage is in chapter 2 of this Part — the SDK integration is mostly about passing the same server config programmatically instead of through settings.json.

---

## Plan Mode

Use plan mode for complex tasks where you want to review the approach before execution.

```typescript
options: { permissionMode: "plan" }
```

In plan mode the agent:

1. Explores the codebase using read-only tools
2. Writes a plan to a plan file
3. Presents the plan for approval
4. Executes only after approval

**When to use**: multi-file changes, architectural decisions, anything where a wrong turn costs more than the plan review.

---

## Subagents in the SDK

The SDK supports subagent dispatch via an `Agent` tool. Define custom subagents in the options object and include `"Agent"` in `allowedTools` so the parent can invoke them.

```typescript
import { query } from "@anthropic-ai/claude-agent-sdk";

for await (const message of query({
  prompt: "Use the code-reviewer agent to review this codebase",
  options: {
    allowedTools: ["Read", "Glob", "Grep", "Agent"],
    agents: {
      "code-reviewer": {
        description: "Expert code reviewer for quality and security reviews.",
        prompt: "Analyze code quality and suggest improvements.",
        tools: ["Read", "Glob", "Grep"]
      }
    }
  }
})) {
  console.log(message);
}
```

Messages from within a subagent's context carry a `parent_tool_use_id` field so you can attribute each message to the right subagent execution. Useful for per-subagent cost tracking and trace spans.

See chapter 3 for the broader subagent design guidance (descriptions as routing, file-boundary discipline, result offloading). Same principles apply in the SDK — just configured in code instead of frontmatter.

---

## Hooks in the SDK

The SDK supports the same hook events as the CLI, passed as callback functions instead of shell commands. All the event types (`PreToolUse`, `PostToolUse`, `SessionStart`, `SessionEnd`, `UserPromptSubmit`, `Stop`, etc.) behave identically — this just gives you a richer in-process hook surface.

**Python:**

```python
from datetime import datetime
from claude_agent_sdk import query, ClaudeAgentOptions, HookMatcher


async def log_file_change(input_data, tool_use_id, context):
    file_path = input_data.get("tool_input", {}).get("file_path", "unknown")
    with open("./audit.log", "a") as f:
        f.write(f"{datetime.now()}: modified {file_path}\n")
    return {}


async for message in query(
    prompt="Refactor utils.py",
    options=ClaudeAgentOptions(
        permission_mode="acceptEdits",
        hooks={
            "PostToolUse": [HookMatcher(matcher="Edit|Write", hooks=[log_file_change])]
        },
    ),
):
    print(message)
```

**TypeScript:**

```typescript
import { query, HookCallback } from "@anthropic-ai/claude-agent-sdk";
import { appendFile } from "fs/promises";

const logFileChange: HookCallback = async (input) => {
  const filePath = (input as any).tool_input?.file_path ?? "unknown";
  await appendFile("./audit.log",
    `${new Date().toISOString()}: modified ${filePath}\n`);
  return {};
};

for await (const message of query({
  prompt: "Refactor utils.ts",
  options: {
    permissionMode: "acceptEdits",
    hooks: {
      PostToolUse: [{ matcher: "Edit|Write", hooks: [logFileChange] }]
    }
  }
})) {
  console.log(message);
}
```

Same stdin JSON payload format as CLI hooks — just delivered as a function argument instead of over stdin.

---

## Observability

Streaming messages from `query()` give you a natural observability surface. Wire them into your logging/tracing stack.

### Per-message logging

Every yielded message carries a type. Typical types include:

- `system` (init, shutdown) — session metadata, including `session_id`
- `tool_use` — the agent is calling a tool
- `tool_result` — result came back
- `assistant` — Claude's text output
- `result` — final response

```typescript
for await (const message of query({ prompt, options })) {
  log.info({
    kind: message.type,
    subtype: (message as any).subtype,
    session_id: (message as any).session_id,
    ts: Date.now(),
  });
}
```

### Cost tracking

`result` messages carry usage and cost fields. Aggregate per session for cost dashboards. Tag by application context (user ID, feature flag, environment) to slice costs.

### Trace spans

For OpenTelemetry-style tracing, emit a span per `tool_use` + `tool_result` pair, keyed by tool_use_id. Subagent messages carry `parent_tool_use_id` — use it to nest child spans under the parent subagent span.

### Hooks for richer events

Wire `PreToolUse` / `PostToolUse` hooks to emit structured events:

- Tool invocations with arguments
- Tool results with outcomes
- Policy violations (the hook blocks, record why)

This gives you a complete audit log even when Claude's result message is terse. Especially valuable for CI pipelines where the agent might run unattended.

---

## Example: CI Code Review Agent

A read-only review agent, safe for automated CI pipelines — cannot modify files even if Claude tries.

```typescript
import { query } from "@anthropic-ai/claude-agent-sdk";

async function reviewPR(prNumber: number): Promise<string> {
  let output = "";

  for await (const message of query({
    prompt: `Review PR #${prNumber}. Check for:
     1. Security vulnerabilities
     2. Missing error handling
     3. Test coverage gaps
     Return findings as a markdown checklist.`,
    options: {
      allowedTools: ["Read", "Glob", "Grep", "Bash"],
      disallowedTools: ["Write", "Edit"],   // cannot modify files
      permissionMode: "acceptEdits",
      settingSources: ["project"],
    }
  })) {
    if ("result" in message) output = (message as any).result;
  }

  return output;
}
```

Key design choices:

- `disallowedTools` for `Write`/`Edit` — the agent literally cannot modify files
- `allowedTools` auto-approves the read-only tools — no human in the loop
- `settingSources: ["project"]` loads project rules but not user-level config — hermetic CI
- `permissionMode: "acceptEdits"` is safe here because writes are already blocked

---

## Migration from the Old SDK

If you're on the older `@anthropic-ai/claude-code-sdk`:

1. **Install the new package**: `npm install @anthropic-ai/claude-agent-sdk` (or `pip install claude-agent-sdk`)
2. **Rename imports**: `@anthropic-ai/claude-code-sdk` → `@anthropic-ai/claude-agent-sdk`; `claude_code_sdk` → `claude_agent_sdk`
3. **Entry point**: replace `new Agent({...}).run(...)` calls with `query({ prompt, options })` iteration
4. **Option keys**: most map 1:1, but check `allowedTools` vs `allowed_tools` casing per language; `permissionMode` replaces prior flags like `dontAsk`/`yesAlways`
5. **Review hooks**: hook callbacks are unchanged in signature but the registration structure uses `HookMatcher` (Python) / `{ matcher, hooks: [...] }` (TypeScript)

See the official migration guide at `code.claude.com/docs/en/agent-sdk/migration-guide` for exhaustive detail.

---

## Anti-Patterns

1. **Mixing `allowedTools` up with CLI `tools:`** — `allowedTools` auto-approves; it does not restrict. Use `disallowedTools` to actually remove tools.
2. **`bypassPermissions` + external systems** — never. Pre-approve specific tools or accept edits; reserve bypass for hermetic sandboxes.
3. **Not capturing `session_id`** — if you want to resume or fork, you have to read it from the `system` init message. Once the query completes without capture, it's gone.
4. **Ignoring streamed events** — the result message isn't the whole story. Intermediate tool uses carry cost, latency, and failure signals worth logging.
5. **Forgetting `settingSources`** — by default the SDK loads your home `~/.claude/` config. For CI you usually want `["project"]` only so user-level rules don't leak.
6. **Retrying on transient failures without backoff** — rate limits, 529s, and provider blips happen. Wrap the query in an exponential backoff with a circuit breaker; don't hammer.

---

## When to Reach for the SDK vs the CLI

| Use case | Pick |
|---|---|
| Interactive development | CLI |
| CI/CD pipelines | SDK |
| Custom applications | SDK |
| One-off exploratory tasks | CLI |
| Production automation | SDK |
| Agents embedded in user-facing apps | SDK |
| Quick experiments | CLI |

Workflows translate directly between them — an agent you prototype in the CLI can become an SDK-driven automation with minimal translation.
