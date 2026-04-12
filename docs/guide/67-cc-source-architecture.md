---
layout: default
title: "Claude Code Internal Architecture — Source Analysis"
parent: Guide
nav_order: 67
---

# Claude Code Internal Architecture — Source Analysis

*Based on Claude Code v2.1.88 source exploration*

## Overview

We explored the Claude Code v2.1.88 source across 1,884 TypeScript files spanning 6 architectural domains: tool system, hook system, skill system, context and memory management, task/agent system, and auto-mode classification. This chapter documents the internal patterns, design decisions, and surprising architectural choices that power the CLI.

This analysis is useful for three purposes: understanding why Claude Code behaves the way it does, learning production-grade TypeScript patterns from a real 1,884-file codebase, and knowing which behaviors are configurable vs hardcoded.

---

## 1. Tool System

The tool system is the execution backbone of Claude Code. Every action -- reading files, running bash commands, editing code, searching -- goes through a unified tool pipeline.

### buildTool() Pattern

All tools are constructed via `buildTool()` (Tool.ts, lines ~757-792), which enforces fail-closed defaults:

```typescript
buildTool({
  name: "Read",
  description: "...",
  inputSchema: { ... },
  isReadOnly: true,       // Fail-closed: defaults to false (write)
  isBackground: false,
  needsPermission: true,  // Fail-closed: defaults to true
  execute: async (input, context) => { ... },
})
```

**Fail-closed philosophy**: Every tool defaults to requiring permission. A tool must explicitly opt out of permission checks (`needsPermission: false`). This means a new tool added without careful configuration will be blocked in auto mode rather than silently executing -- the safe default.

### Tool Count and Categories

Claude Code ships with 150+ tools across these categories:

| Category | Examples | Read-Only |
|----------|----------|-----------|
| File reading | Read, Glob, Grep | Yes |
| File writing | Edit, Write | No |
| Execution | Bash | No |
| Search | WebSearch, WebFetch | Yes |
| Agent | Task, TodoRead, TodoWrite | Mixed |
| MCP | Dynamic (from connected servers) | Varies |

### Streaming Executor

Tool execution uses a streaming model. Results are emitted as partial chunks rather than buffered to completion. This is what allows you to see Bash output line-by-line and Read results incrementally. The executor wraps each tool call in an abort-aware context so that Ctrl+C cleanly cancels in-flight operations.

### Partitioned Concurrency

Tool execution is not uniformly parallel. The system uses **partitioned concurrency**:

| Partition | Concurrency | Tools |
|-----------|-------------|-------|
| Read operations | Parallel, max 10 | Read, Glob, Grep, WebFetch |
| Write operations | Serial (1 at a time) | Edit, Write, Bash |
| Background | Parallel, max 5 | Task (subagents) |

This prevents write conflicts (two Edits to the same file) while allowing read operations to saturate I/O. The max-10 read limit prevents file descriptor exhaustion on systems with low `ulimit` defaults.

---

## 2. Hook System

Hooks allow external scripts to execute at specific lifecycle points. The hook system is more sophisticated than it appears from the user-facing docs.

### All 27 Hook Events

The source defines these hook events:

| Category | Events |
|----------|--------|
| **Session lifecycle** | `PreToolUse`, `PostToolUse`, `PreCompact`, `PostCompact`, `SessionStart`, `SessionEnd` |
| **Tool-specific** | `PreBash`, `PostBash`, `PreEdit`, `PostEdit`, `PreWrite`, `PostWrite`, `PreRead`, `PostRead` |
| **Agent lifecycle** | `PreTask`, `PostTask`, `TaskUpdate`, `TaskOutput` (deprecated) |
| **Permission** | `PermissionDenied`, `PermissionGranted` |
| **Environment** | `CwdChanged`, `FileChanged` |
| **Failures** | `StopFailure`, `RateLimitError` |
| **UI** | `Notification` |
| **Context** | `ContextTruncated` |
| **Model** | `PreModelCall`, `PostModelCall` |

### Source-Priority Matchers

When multiple hooks match the same event, they execute in priority order:

```
User (~/.claude/settings.json)
  > Project (.claude/settings.json)
    > Plugin (plugin hooks)
```

User-level hooks run first and can override or block project-level hooks. This is the same precedence used for permissions and settings.

### The `if` Condition System

Hook handlers support an `if` field that uses **permission rule syntax** -- the same syntax used for allow/deny rules:

```json
{
  "hooks": {
    "PreToolUse": [{
      "if": "Bash(git *)",
      "command": "~/.claude/hooks/git-guard.sh"
    }]
  }
}
```

The `if` condition is evaluated against the tool name and arguments. In 2.1.88, this was fixed to correctly match compound commands (`ls && git push`) and commands with environment variable prefixes (`FOO=bar git push`). The matcher decomposes the command and checks each sub-command against the pattern.

### Workspace Trust Verification

Before executing project-level hooks, Claude Code performs workspace trust verification. A project's hooks only run if the workspace is trusted (the user has previously accepted the project's CLAUDE.md). This prevents a cloned malicious repository from executing arbitrary hooks on first open.

---

## 3. Skill System

Skills are the primary extension mechanism for adding domain knowledge and workflows to Claude Code.

### Frontmatter Parsing

Each skill's `SKILL.md` file begins with YAML frontmatter that controls activation, tool access, and context loading:

```yaml
---
description: "Short description (max 250 chars)"
user-invocable: true
allowed-tools: Read, Bash, Grep
paths: src/agents/**
skills: shared-adk-development
---
```

The parser extracts these fields and registers the skill in a write-once registry. Key fields:

| Field | Purpose | Default |
|-------|---------|---------|
| `description` | Shown in `/skills` listing, truncated at 250 chars | Required |
| `user-invocable` | Whether `/skill-name` works | `true` |
| `disable-model-invocation` | Prevents Claude from auto-invoking | `false` |
| `allowed-tools` | Comma-separated tool whitelist | All tools |
| `paths` | Glob patterns for conditional activation | Always active |
| `skills` | Other skills to load as dependencies | None |

### Conditional Activation via `paths`

When a skill has a `paths` field, it is only loaded into the active context when files matching those glob patterns are part of the current working set. This reduces token usage -- a skill about ADK agents does not consume context budget when you are editing a React component.

The matching is evaluated on session start and after `CwdChanged` events. Skills are re-evaluated when the working directory changes.

### Token Budget Estimation

Skills consume context window budget. The system estimates each skill's token cost from its frontmatter and content length. The total skill budget is capped at approximately 2% of the context window (~20K characters for a 1M context window). The `/skills` command shows current budget consumption.

### Dedup via Realpath

Skills are deduplicated by their resolved filesystem path (`realpath`). If the same skill is referenced from multiple locations (e.g., a symlink in `~/.claude/skills/` pointing to a project skill), it is loaded only once. This prevents double-counting in the token budget.

### Write-Once Registry Pattern

The skill registry uses a write-once pattern to avoid import cycle issues. Skills are registered on first discovery and cannot be overwritten. This is a common pattern in the codebase for managing singletons across module boundaries:

```typescript
// Simplified pattern
const registry = new Map<string, Skill>();

function registerSkill(skill: Skill): void {
  if (registry.has(skill.name)) return; // Write-once: first registration wins
  registry.set(skill.name, skill);
}
```

This pattern appears in tool registration, hook registration, and MCP server registration as well.

---

## 4. Context and Memory Management

Context management is arguably the most critical system in Claude Code. It determines what the model sees, what it forgets, and how much each API call costs.

### Static/Dynamic Prompt Boundary

The system prompt is split into a **static** portion and a **dynamic** portion, optimized for Anthropic's API prompt caching:

| Portion | Contents | Cache Behavior |
|---------|----------|----------------|
| Static | System instructions, tool schemas, CLAUDE.md | Cached across turns (cache hit) |
| Dynamic | Skills, recent files, memory, conversation | Rebuilt each turn |

The static portion is placed first in the system prompt so that the API's prefix caching can reuse it across turns. This is why tool schema ordering and CLAUDE.md content are stable -- changing them invalidates the cache prefix and increases costs.

In 2.1.88, a bug was fixed where tool schema bytes were subtly changing between turns (due to floating-point serialization), causing cache misses in long sessions. This fix alone reduced API costs for power users.

### MEMORY.md Cap

The auto-memory file (`MEMORY.md`) is hard-capped at **200 lines and 25KB**. When content exceeds this, the system truncates from the top (oldest entries removed first). This cap exists because MEMORY.md is injected into every API call as part of the dynamic prompt -- an uncapped file would linearly increase per-turn costs.

### Auto-Compact Trigger

Context compaction triggers automatically at approximately **87-95% of the context window**. The exact threshold varies slightly based on the model's context size and the current turn's expected output length.

Compaction works by:

1. Summarizing the conversation history using an LLM call (Sonnet, not Opus -- cheaper and faster)
2. Preserving the most recent turns verbatim
3. Replacing older turns with the summary
4. Firing the `PostCompact` hook so external scripts can reload critical context

### Post-Compact File Restoration

After compaction, the system automatically restores up to **5 recently-read files** (capped at ~50K tokens total). These are files that were actively being worked on and are likely needed in the next turn. The selection uses an LLM call (Sonnet) to determine which files are most relevant to the current task.

This is why you sometimes see "Re-reading file..." messages after compaction -- the system is proactively reloading context that was lost in the summary.

### LLM-Powered Memory Relevance Selection

When loading MEMORY.md content and deciding what context to inject, the system uses a **separate Sonnet call** to score memory entries by relevance to the current conversation. This means memory injection is not just keyword matching -- it understands semantic relevance.

---

## 5. Task/Agent System

The Task system enables subagent delegation -- spawning isolated Claude instances for parallel or specialized work.

### 7 Task Types

The system supports these task types internally:

| Type | Description | Isolation |
|------|-------------|-----------|
| `general-purpose` | Standard subagent for any task | Full |
| `code-review` | Specialized for PR review workflows | Full |
| `explore` | Read-only exploration and research | Read-only tools |
| `fork` | Cache-preserving context fork | Shared prefix |
| `background` | Long-running background work | Full |
| `cron` | Scheduled execution | Full + lock |
| `worktree` | Git worktree isolation | Full + filesystem |

### AsyncLocalStorage Isolation

Each task runs in its own `AsyncLocalStorage` context. This is Node.js's mechanism for request-scoped state in async code. It means each subagent has its own:

- Working directory
- Environment variables
- Abort signal
- Tool permissions
- Conversation history

This prevents the classic "shared global state" problem where one subagent's actions leak into another's context.

### Child AbortController Hierarchy

Tasks form an abort hierarchy. When a parent task is cancelled (Ctrl+C, timeout, or explicit abort), all child tasks receive abort signals:

```
Root Session
  ├── Task A (AbortController)
  │   └── Task A.1 (child AbortController)
  └── Task B (AbortController)
```

Aborting the root session cascades to all tasks. Aborting Task A aborts A.1 but leaves Task B running. This hierarchy ensures clean cancellation without orphaned processes.

### Distributed Cron Lock + Jitter

Cron-type tasks use a distributed lock to prevent duplicate execution when multiple Claude Code instances are running (e.g., multiple terminal tabs). The lock is file-based (using `O_EXCL` create) with a configurable TTL.

Jitter is added to cron execution times to prevent thundering herd problems -- if five instances all have a cron scheduled for midnight, they spread execution across a random window.

### Cache-Preserving Fork

The `fork` task type is special: it shares the parent's prompt cache prefix. This means the forked agent starts with the same cached context as the parent, avoiding a cold-start cache miss. This is used for operations like "try approach A in a fork" where you want the agent to have full context but isolated execution.

### Message Capping

The UI caps displayed messages at **50 per task**. Older messages scroll off the display but remain in the conversation history sent to the API. This is a UI performance optimization -- rendering hundreds of tool results would slow the terminal.

### O_NOFOLLOW Security

File operations in the task system use `O_NOFOLLOW` flags where available. This prevents symlink-following attacks where a malicious project could symlink a file path to `/etc/passwd` or other sensitive locations. The tool would fail rather than follow the symlink.

---

## 6. Auto-Mode Classifier

Auto mode (the default mode where Claude decides which tools need permission) uses a **separate Sonnet call** to classify each tool invocation. This is distinct from the main Opus/Sonnet conversation model.

### How It Works

1. Claude (main model) decides to call a tool (e.g., `Bash("rm -rf node_modules")`)
2. Before execution, the classifier (Sonnet) evaluates: "Given the allow/deny rules and the conversation context, should this tool call be permitted?"
3. If denied, the `PermissionDenied` hook fires and the user is prompted

The classifier sees the tool name, arguments, the allow/deny rules, and a summary of recent conversation context. It does NOT re-evaluate the full conversation -- that would be too expensive.

### Why a Separate Model Call

Using a separate, cheaper model (Sonnet) for classification keeps auto-mode overhead low. Each classification is a small, focused prompt (~500 tokens) rather than sending the full conversation context through a second model call.

### Concurrent Execution Is Opt-In

A common misconception is that Claude Code always runs tools in parallel. In fact, **concurrent tool execution is opt-in, not the default**. The model must explicitly request parallel execution by returning multiple tool calls in a single response. The executor then runs them according to the partitioned concurrency rules (reads parallel, writes serial).

---

## 7. Key Metrics

How Claude Code's codebase compares to typical projects:

| Metric | Claude Code | Typical Project |
|--------|-------------|-----------------|
| TypeScript files | 1,884 | 50-200 |
| Tool definitions | 150+ | 5-20 |
| Hook events | 27 | 3-5 |
| Skill frontmatter fields | 8+ | N/A |
| Context management strategies | 4 (static/dynamic split, auto-compact, post-compact restore, LLM relevance) | 1 (truncate) |
| Task types | 7 | 1-2 |
| Concurrency partitions | 3 (read/write/background) | 1 (global) |
| Lines in largest file | 1,758 (state.ts) | ~500 |

---

## 8. Surprising Discoveries

These findings were unexpected based on the public documentation alone.

### God Files Exist

Despite Claude Code's generally modular architecture, some files are notably large:

| File | Lines | Purpose |
|------|-------|---------|
| `state.ts` | 1,758 | Global application state management |
| `Tool.ts` | ~900 | Tool system core with buildTool() |
| `hooks.ts` | ~700 | Hook system with priority resolution |

The `state.ts` file manages conversation state, tool state, permission state, UI state, and session state in a single module. This is a pragmatic choice -- splitting it would create circular dependency issues given how many modules need to read/write state.

### Auto-Mode Classifier Is a Separate Sonnet Call

This is not documented in user-facing materials but has significant implications. Each tool call in auto mode incurs an additional API call for classification. For sessions with hundreds of tool calls, this adds up. This is why auto mode with aggressive allow rules (reducing classifier invocations) can meaningfully reduce API costs.

### Concurrent Execution Is Opt-In, Not Default

The model must explicitly return multiple tool calls in a single response for parallel execution to occur. If the model returns tools one at a time (which it does for most sequential workflows), execution is serial regardless of the concurrency partition settings.

### The Write-Once Registry Is Everywhere

The pattern of "first registration wins, no overwrite" appears in at least 4 subsystems: tools, skills, hooks, and MCP servers. This is a deliberate architectural choice to avoid the complexity of registration ordering and override semantics.

### Post-Compact Restoration Uses LLM Selection

The system does not blindly restore the 5 most recently read files after compaction. It makes a Sonnet call to determine which files are most relevant to the current task. This means the restoration is context-aware -- if you were debugging a test file, the test file and its subject are more likely to be restored than an unrelated config file you glanced at earlier.

### MEMORY.md Is Injected Every Turn

The 200-line cap on MEMORY.md exists because its contents are included in every single API call. An unbounded MEMORY.md would linearly increase costs. At 200 lines, the cost is predictable and bounded.

### O_NOFOLLOW Is a Security Boundary

The use of `O_NOFOLLOW` in file operations means Claude Code treats symlinks as a security boundary. A project cannot trick Claude Code into reading/writing files outside its intended scope via symlinks. This is particularly important for the sandbox mode.

---

## Practical Implications

Understanding these internals helps with practical optimization:

| If You Want To... | Know That... |
|-------------------|-------------|
| Reduce API costs | Stable CLAUDE.md content maximizes prompt cache hits |
| Speed up auto mode | Broader allow rules reduce classifier calls |
| Optimize post-compact recovery | Keep critical files in recent Read history |
| Maximize parallel execution | Structure prompts so the model returns multiple tool calls |
| Control skill budget | Use `paths:` frontmatter to conditionally load skills |
| Prevent hook overhead | Use `if` conditions to filter hook invocations |
| Debug subagent issues | Each task has isolated AsyncLocalStorage -- check the right context |

---

## Community Reimplementation Patterns

The open-source Rust reimplementation [claw-code](https://github.com/ultraworkers/claw-code) (180K+ stars) provides additional architectural insights. While not affiliated with Anthropic, the project's clean-room approach to replicating Claude Code's behavior surfaces patterns worth understanding:

### Recovery Recipes (claw-code `recovery_recipes.rs`)

Instead of ad-hoc retry logic, failure types are enumerated as a typed taxonomy. Each maps to an ordered sequence of recovery steps with a strict invariant: **one automatic recovery attempt, then escalate**.

| Failure Type | Recovery Steps | Escalation |
|---|---|---|
| TrustPromptUnresolved | Auto-resolve from allowlist → send trust text | Alert human |
| PromptMisdelivery | Detect shell error → replay prompt | Log and continue |
| StaleBranch | Check base commit → rebase or warn | Block merge |
| CompileRedCrossCrate | Targeted rebuild → workspace rebuild | Alert human |
| McpHandshakeFailure | Restart server → degraded mode | Log and continue |
| ProviderFailure | Fallback model → circuit breaker | Abort |

**What makes this different from retry loops**: Recovery is modeled as a sequence of distinct typed steps that can partially succeed. The system tracks which steps ran and which remain, enabling structured incident reporting.

### Compaction Boundary Guard (claw-code `compact.rs`)

When compacting session history, the implementation ensures it never splits a tool-use/tool-result pair. A boundary walker scans backwards from the cut point to the nearest complete exchange. Without this, orphaned tool messages cause validation errors on OpenAI-compatible endpoints and confused routing in multi-agent setups.

This is the same class of bug as persisting a state-clearing tool's exchange into an empty history -- any orphaned tool message in conversation history is invalid.

### Context Window Preflight (claw-code `providers/mod.rs`)

Before every API call, input tokens are estimated (JSON byte count / 4) and compared against the model's context window. Requests that would overflow are blocked before sending. This prevents wasted API calls and cryptic provider errors.

### Multi-Provider Model Routing

Model names are resolved through a prefix-based routing chain:
- `claude*` routes to Anthropic
- `grok*` routes to xAI  
- `openai/*` or `gpt-*` routes to OpenAI-compatible
- `qwen/*` routes to DashScope

When authentication fails, the system checks for other provider credentials and suggests the correct model prefix -- e.g., "I see OPENAI_API_KEY is set; if you meant OpenAI-compat, prefix your model with `openai/`."

### Policy Engine (claw-code `policy_engine.rs`)

A declarative rule engine with composable conditions (`And`, `Or`, `GreenAt`, `StaleBranch`, `TimedOut`) mapped to actions (`MergeToDev`, `RecoverOnce`, `Escalate`, `Block`). Priority-sorted evaluation -- all matching rules fire, producing a flat action list. This replaces imperative if-else chains in CI/CD automation with readable, testable policy declarations.

---

*Previous: [Chapter 66 -- Claude Code 2.1.87-2.1.88 Features](66-claude-code-2187-2188-features)*

*Updated: 2026-04-10*
