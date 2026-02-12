---
layout: default
title: "Claude Code Hooks - Complete Guide to 14 Hook Events"
description: "Configure Claude Code hooks for PreToolUse, PostToolUse, and 12 more events. Command, prompt, and agent hook types. Async hooks. Decision control patterns."
---

# Chapter 13: Claude Code Hooks

Claude Code hooks are customizable scripts that run at specific points in the AI workflow, enabling automation, validation, and context injection. This guide covers all 14 hook events, 3 hook types, async execution, and production-tested patterns.

**Purpose**: Automate workflows with event-driven hooks
**Source**: Anthropic blog "How to Configure Hooks"
**Evidence**: 14 hooks in production, 96% test validation
**Updated**: Feb 10, 2026 — All 14 hook events documented

---

## Hook Events (14 Available)

| Hook                   | Trigger                       | Use For                                |
| ---------------------- | ----------------------------- | -------------------------------------- |
| **SessionStart**       | Session begins                | Inject git status, context, env vars   |
| **UserPromptSubmit**   | User sends message            | Skill matching, prompt preprocessing   |
| **PreToolUse**         | Before tool executes          | Block dangerous operations, validation |
| **PostToolUse**        | After tool runs               | Auto-format, logging, monitoring       |
| **PreCompact**         | Before context compaction     | Backup transcripts, save state         |
| **PermissionRequest**  | Permission dialog appears     | Auto-approve safe commands             |
| **Notification**       | Claude sends a notification   | Custom alerts, logging, integrations   |
| **Stop**               | Response ends                 | Suggest skill creation, cleanup        |
| **SessionEnd**         | Session closes                | Save summaries, final checkpoint       |
| **PostToolUseFailure** | Tool call fails               | Log errors, track failure patterns     |
| **SubagentStart**      | Subagent spawns               | Monitor agent lifecycle, logging       |
| **SubagentStop**       | Subagent completes            | Log results, track agent activity      |
| **TeammateIdle**       | Teammate agent becomes idle   | Pause teammates, reassign work         |
| **TaskCompleted**      | A task finishes (Agent Teams) | Reassign work, trigger follow-ups      |

### Hook Categories

**Session Lifecycle**: SessionStart → UserPromptSubmit → ... → Stop → SessionEnd

**Tool Lifecycle**: PreToolUse → (tool runs) → PostToolUse / PostToolUseFailure

**Agent Lifecycle**: SubagentStart → (agent works) → SubagentStop

**Agent Teams**: TeammateIdle (idle detection), TaskCompleted (task completion)

**Other**: PreCompact (context management), PermissionRequest (security), Notification (alerts)

---

## Quick Config

File: `.claude/settings.json`

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/session-start.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/prettier-format.sh",
            "statusMessage": "✨ Formatting file..."
          }
        ]
      }
    ]
  }
}
```

---

## Hook Types (3 Available)

Claude Code supports three distinct hook types. Each serves a different purpose and complexity level.

### Command Hooks (`type: "command"`)

Shell script execution. The hook receives JSON via stdin and can return JSON on stdout. This is the most common type and what all examples in this guide use by default.

```json
{
  "hooks": [
    {
      "type": "command",
      "command": ".claude/hooks/my-hook.sh"
    }
  ]
}
```

- Receives event data as JSON on stdin
- Returns structured JSON on stdout (optional)
- Exit code 0 = success, exit code 2 = block/deny (event-dependent)
- Full control over logic via any scripting language

### Prompt Hooks (`type: "prompt"`)

Single-turn LLM evaluation. Instead of running a shell script, the hook sends a prompt to an LLM which evaluates the situation and returns a decision. No tools are available to the LLM -- it makes its decision based solely on the prompt and the event context provided.

```json
{
  "PreToolUse": [
    {
      "matcher": { "tool_name": "Bash" },
      "hooks": [
        {
          "type": "prompt",
          "prompt": "Evaluate if this bash command is safe to run. Block any destructive commands like rm -rf, git push --force, or DROP TABLE. Return ALLOW for safe commands, DENY for dangerous ones."
        }
      ]
    }
  ]
}
```

**When to use prompt hooks**:

- Quick safety evaluations that don't need file system access
- Style or convention checks based on content alone
- Simple allow/deny decisions based on pattern recognition

**Tradeoffs**:

- Simpler to set up than command hooks (no script file needed)
- Adds LLM inference latency to every matched event
- Cannot run external tools, read files, or execute commands
- Decision quality depends on prompt clarity

### Agent Hooks (`type: "agent"`)

Multi-turn hook with full tool access. The hook prompt is given to an agent that can use tools (Read, Bash, Grep, etc.) to investigate the situation before making a decision. This is the most powerful but also the most expensive hook type.

```json
{
  "PreToolUse": [
    {
      "matcher": { "tool_name": "Write" },
      "hooks": [
        {
          "type": "agent",
          "prompt": "Review the file being written. Check if it follows project conventions by reading similar files in the same directory. Block if it violates established patterns."
        }
      ]
    }
  ]
}
```

**When to use agent hooks**:

- Complex validations requiring file system inspection
- Checks that need to compare against existing code patterns
- Reviews that require reading multiple files for context

**Tradeoffs**:

- Most powerful: can read files, run commands, search code
- Most expensive: multiple LLM calls + tool execution per hook invocation
- Slowest: adds significant latency (seconds to minutes)
- Use sparingly on high-frequency events like PostToolUse

### Hook Type Comparison

| Aspect       | `command`         | `prompt`            | `agent`                |
| ------------ | ----------------- | ------------------- | ---------------------- |
| Execution    | Shell script      | Single LLM turn     | Multi-turn LLM + tools |
| Latency      | Milliseconds      | 1-3 seconds         | 5-30+ seconds          |
| Cost         | Free (local)      | 1 LLM call          | Multiple LLM calls     |
| Tool access  | External commands | None                | Full Claude tools      |
| Setup effort | Script file       | Inline prompt       | Inline prompt          |
| Best for     | Automation, CI    | Quick safety checks | Deep code review       |

---

## Async Hooks

Any hook can be made asynchronous by adding `"async": true`. Async hooks run in the background without blocking Claude's workflow.

```json
{
  "PostToolUse": [
    {
      "hooks": [
        {
          "type": "command",
          "command": ".claude/hooks/log-analytics.sh",
          "async": true
        }
      ]
    }
  ]
}
```

**Key behaviors**:

- The hook runs in the background; Claude does not wait for it to finish
- Cannot influence Claude's behavior (no blocking, no modifying output)
- Ideal for logging, analytics, notifications, and telemetry
- If the hook fails, Claude is not affected

**When to use async**:

- Sending notifications to Slack/Discord/email
- Logging tool usage to an external analytics service
- Writing audit trails that don't need to block execution
- Any "fire and forget" side effect

---

## Hook Locations (6 Scopes)

Hooks can be defined in multiple locations. They are loaded and merged in this order (later scopes add to, but don't override, earlier ones):

| Priority | Location                      | Scope                      | Use Case                         |
| -------- | ----------------------------- | -------------------------- | -------------------------------- |
| 1        | `~/.claude/settings.json`     | User (all projects)        | Personal workflow automation     |
| 2        | `.claude/settings.json`       | Project (committed)        | Team-shared hooks                |
| 3        | `.claude/settings.local.json` | Local (not committed)      | Personal overrides for a project |
| 4        | Managed policy                | Enterprise (admin-managed) | Organization-wide enforcement    |
| 5        | Plugin hooks                  | Installed plugins          | Plugin-provided automation       |
| 6        | Skill/agent frontmatter       | YAML `hooks:` field        | Skill-specific hooks             |

**How merging works**: Hooks from all scopes are combined. If the same event has hooks in multiple scopes, all hooks run (they don't replace each other). This means a user-level SessionStart hook and a project-level SessionStart hook both execute.

**Skill frontmatter hooks** support a `once` field to limit execution:

```yaml
hooks:
  PreToolUse:
    - matcher: { tool_name: "Bash" }
      hooks:
        - type: command
          command: "./check.sh"
      once: true # Only runs once per session, not on every match
```

---

## Decision Control Patterns

Different hook events handle decisions differently. Understanding these patterns is essential for writing hooks that correctly block, allow, or modify behavior.

### PreToolUse Decision Output

PreToolUse hooks use `hookSpecificOutput` to communicate decisions:

```json
{
  "hookSpecificOutput": {
    "decision": "allow"
  }
}
```

Valid decisions for PreToolUse:

- `"allow"` -- permit the tool call to proceed
- `"deny"` -- block the tool call (Claude sees the denial)
- `"ask_user"` -- pause and ask the user for confirmation

Example deny with reason:

```json
{
  "hookSpecificOutput": {
    "decision": "deny",
    "reason": "Cannot write files to project root. Use src/ or memory-bank/ instead."
  }
}
```

### Other Events Decision Output

Events other than PreToolUse use a top-level `decision` field:

```json
{
  "decision": "block",
  "reason": "Explanation shown to the user"
}
```

### Exit Code 2 Behavior

Exit code 2 has **different effects** depending on the hook event:

| Event              | Exit Code 2 Effect                     |
| ------------------ | -------------------------------------- |
| PreToolUse         | Blocks the tool call                   |
| PostToolUse        | Ignored (tool already ran)             |
| UserPromptSubmit   | Blocks the prompt from being processed |
| Notification       | Ignored                                |
| Stop               | Ignored                                |
| SessionEnd         | Ignored                                |
| PostToolUseFailure | Ignored                                |
| TeammateIdle       | Pauses the idle teammate               |
| TaskCompleted      | Can reassign the completed task        |
| SubagentStart      | Ignored                                |
| SubagentStop       | Ignored                                |

**Rule of thumb**: Exit code 2 only matters for "Pre" events (where blocking makes sense) and agent team events (where pausing/reassignment makes sense).

---

## MCP Tool Matching

When matching MCP (Model Context Protocol) tool calls in `PreToolUse` or `PostToolUse`, use the `mcp__<server>__<tool>` naming pattern:

```json
{
  "PreToolUse": [
    {
      "matcher": {
        "tool_name": "mcp__postgres__query"
      },
      "hooks": [
        {
          "type": "command",
          "command": ".claude/hooks/validate-sql-query.sh"
        }
      ]
    }
  ]
}
```

More examples:

```json
{
  "PreToolUse": [
    {
      "matcher": { "tool_name": "mcp__slack__post_message" },
      "hooks": [
        {
          "type": "command",
          "command": ".claude/hooks/review-slack-message.sh"
        }
      ]
    },
    {
      "matcher": { "tool_name": "mcp__github__create_pull_request" },
      "hooks": [
        { "type": "command", "command": ".claude/hooks/validate-pr.sh" }
      ]
    }
  ]
}
```

**Pattern**: The tool name follows the format `mcp__<server-name>__<tool-name>`, where the server name comes from your MCP configuration and the tool name is defined by the MCP server.

---

## 🚨 CRITICAL: Accessing Tool Input Data (Feb 7, 2026)

**Claude Code passes data via stdin as JSON, NOT via environment variables!**

### Available Environment Variables (ONLY these exist!)

| Variable              | Description                   | Available In      |
| --------------------- | ----------------------------- | ----------------- |
| `$CLAUDE_PROJECT_DIR` | Absolute path to project root | All hooks         |
| `$CLAUDE_CODE_REMOTE` | "true" in web, not set in CLI | All hooks         |
| `$CLAUDE_ENV_FILE`    | Path to persist env vars      | SessionStart only |

### ❌ WRONG Pattern (Causes Infinite Hang!)

```json
{
  "command": "npx prettier --write \"$CLAUDE_TOOL_INPUT_FILE_PATH\" 2>/dev/null || true"
}
```

**Why it fails**: `$CLAUDE_TOOL_INPUT_FILE_PATH` doesn't exist! It evaluates to empty string, so `npx prettier --write ""` formats ALL files in the project and hangs forever.

### ✅ CORRECT Pattern (Use Shell Script)

Create `.claude/hooks/prettier-format.sh`:

```bash
#!/bin/bash
# Read JSON from stdin with timeout (prevents hang)
JSON_INPUT=$(timeout 2 cat)

# Extract file path from JSON (the CORRECT way!)
FILE_PATH=$(echo "$JSON_INPUT" | jq -r '.tool_input.file_path // empty')

# Validate and format
if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
    case "$FILE_PATH" in
        *.js|*.ts|*.json|*.css|*.html|*.md|*.yaml)
            timeout 10 npx prettier --write "$FILE_PATH" 2>/dev/null || true
            ;;
    esac
fi
exit 0
```

### JSON Input Structure for PostToolUse

```json
{
  "session_id": "abc123",
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/absolute/path/to/file.txt",
    "content": "file content here"
  },
  "tool_response": { "success": true }
}
```

**Evidence**: Feb 7, 2026 — Production branch stuck on "✨ Formatting file..." during AI Training System implementation. Root cause: `$CLAUDE_TOOL_INPUT_FILE_PATH` was empty → prettier scanned 99+ files. Fix: stdin JSON parsing with jq.

---

## Hook Safety: stdin Timeout (Critical)

Hooks that read JSON from stdin **must** use `timeout` to prevent infinite hangs.

**The problem**: Claude Code pipes JSON to hook scripts via stdin. Occasionally — especially under high context load or rapid sequential tool calls — the stdin pipe doesn't close properly. If your hook uses `$(cat)` to read stdin, it blocks forever waiting for EOF, causing Claude Code to appear "stuck."

**The fix**: Always use `timeout` when reading stdin in hooks:

```bash
# WRONG — can hang forever if stdin pipe not closed
JSON_INPUT=$(cat)

# CORRECT — exits after 2 seconds max, hook continues safely
JSON_INPUT=$(timeout 2 cat)
```

**Affected hook types**: Any hook that reads stdin — `PostToolUse`, `PreCompact`, `Stop`, `UserPromptSubmit`. The `SessionStart` hook typically doesn't read stdin so is unaffected.

**How to test**:

```bash
# Simulate a never-closing stdin pipe
mkfifo /tmp/test-fifo
(sleep 100 > /tmp/test-fifo) &
BG=$!

# Should complete in ~2s (not hang forever)
time bash .claude/hooks/your-hook.sh < /tmp/test-fifo

kill $BG; rm /tmp/test-fifo
```

**Evidence**: Feb 2026 — Production. `PostToolUse:Read` hook hung during multi-file implementation session. Root cause: `$(cat)` in `skill-access-monitor.sh`. Fix: `$(timeout 2 cat)`. Verified: 2016ms completion vs infinite hang.

---

## Hook Safety: Command Timeouts

Hooks that run external commands (like `git fetch`) should also use `timeout` to prevent hangs from network or I/O failures.

**The problem**: A `SessionStart` hook running `git fetch origin` hangs if the network is down or the remote is unresponsive. The hook's 600-second timeout budget is generous, but users see Claude Code as frozen.

**The fix**: Wrap external commands with `timeout`:

```bash
# WRONG — hangs if network is down
git fetch origin --quiet 2>/dev/null

# CORRECT — fails fast after 5 seconds
timeout 5 git fetch origin --quiet 2>/dev/null
```

**When to use**: Any hook calling network services (`git fetch`, `curl`, API calls). The timeout should be short (2-5 seconds) since hooks should not block the user experience.

**Evidence**: Feb 2026 — Intermittent `SessionStart` hook errors traced to `git fetch` network failures. Adding `timeout 5` eliminated the issue. Hook runs reliably at ~700ms average.

---

## Hook Event Details

### UserPromptSubmit

Fires when the user sends a message, before Claude processes it. Use for skill matching, input preprocessing, or injecting context.

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/pre-prompt.sh"
          }
        ]
      }
    ]
  }
}
```

**stdin JSON**: `{"session_id": "...", "prompt": "user's message text"}`

**Production use**: Pre-prompt skill matching — reads user query, searches skill index, injects top 3 matching skills into context.

### PreToolUse

Fires before a tool executes. Return non-zero exit code to **block** the tool call.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/block-root-file-creation.sh"
          }
        ]
      }
    ]
  }
}
```

**stdin JSON**: `{"session_id": "...", "tool_name": "Write", "tool_input": {"file_path": "/path/file.txt", "content": "..."}}`

**Production use**: Block file creation in project root directory (enforce organized file structure).

### SessionEnd

Fires when the session closes (user exits or session times out).

```json
{
  "hooks": {
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/session-end.sh"
          }
        ]
      }
    ]
  }
}
```

**stdin JSON**: `{"session_id": "..."}`

**Production use**: Save session summary, suggest creating a skill from patterns observed during the session.

### PostToolUseFailure

Fires when a tool call fails (non-zero exit, timeout, error). Useful for monitoring and debugging.

```json
{
  "hooks": {
    "PostToolUseFailure": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/tool-failure-logger.sh"
          }
        ]
      }
    ]
  }
}
```

**Example script** (`.claude/hooks/tool-failure-logger.sh`):

```bash
#!/bin/bash
set -euo pipefail
INPUT=$(timeout 2 cat 2>/dev/null || echo '{}')
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null || echo "unknown")
ERROR=$(echo "$INPUT" | jq -r '.error // "no error"' 2>/dev/null || echo "no error")
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
LOG_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/logs/tool-failures.log"
mkdir -p "$(dirname "$LOG_FILE")"
echo "[$TIMESTAMP] FAIL: $TOOL_NAME - $ERROR" >> "$LOG_FILE"
# Rotate log at 100 lines
if [ "$(wc -l < "$LOG_FILE")" -gt 100 ]; then
  tail -100 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
fi
exit 0
```

### SubagentStart / SubagentStop

Fire when a subagent (via `Task()` tool) spawns and completes. Use for monitoring agent lifecycle.

```json
{
  "hooks": {
    "SubagentStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/subagent-monitor.sh"
          }
        ]
      }
    ],
    "SubagentStop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/subagent-monitor.sh"
          }
        ]
      }
    ]
  }
}
```

**Example script** (`.claude/hooks/subagent-monitor.sh`):

```bash
#!/bin/bash
set -euo pipefail
INPUT=$(timeout 2 cat 2>/dev/null || echo '{}')
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // "unknown"' 2>/dev/null || echo "unknown")
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
LOG_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/logs/subagent-activity.log"
mkdir -p "$(dirname "$LOG_FILE")"
echo "[$TIMESTAMP] ${CLAUDE_HOOK_EVENT:-unknown}: $AGENT_TYPE" >> "$LOG_FILE"
exit 0
```

**Production use**: Track which agents are spawned, how often, and correlate with tool failures.

### Notification

Fires when Claude Code sends a notification (e.g., task completed, waiting for input). Use for custom alert routing or logging.

```json
{
  "hooks": {
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/notification-handler.sh"
          }
        ]
      }
    ]
  }
}
```

**stdin JSON**: `{"message": "Task completed successfully", "title": "Claude Code"}`

**Example use cases**:

- Forward notifications to Slack, Discord, or desktop notification systems
- Log notification history for session analysis
- Trigger external workflows when specific notifications occur

**Exit code 2**: Ignored (notification has already been generated).

### TeammateIdle (Agent Teams)

Fires when a teammate agent becomes idle in an Agent Teams configuration. Use to monitor agent utilization or pause idle agents to conserve resources.

```json
{
  "hooks": {
    "TeammateIdle": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/teammate-idle.sh"
          }
        ]
      }
    ]
  }
}
```

**Exit code 2**: Pauses the idle teammate, preventing it from picking up new work until explicitly resumed.

**Example use cases**:

- Pause agents that have been idle too long to reduce API costs
- Log agent utilization metrics
- Trigger rebalancing of work across teammates

### TaskCompleted (Agent Teams)

Fires when a task is completed in an Agent Teams configuration. Use to trigger follow-up actions or reassign work.

```json
{
  "hooks": {
    "TaskCompleted": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/task-completed.sh"
          }
        ]
      }
    ]
  }
}
```

**Exit code 2**: Can reassign the completed task (e.g., for review by another agent or additional processing).

**Example use cases**:

- Automatically trigger tests after a coding task completes
- Reassign completed work to a review agent
- Update external project tracking systems

---

## Complete settings.json Example (All 14 Events)

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          { "type": "command", "command": ".claude/hooks/session-start.sh" }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          { "type": "command", "command": ".claude/hooks/pre-prompt.sh" }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/block-root-file-creation.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          { "type": "command", "command": ".claude/hooks/prettier-format.sh" }
        ]
      }
    ],
    "PreCompact": [
      {
        "hooks": [
          { "type": "command", "command": ".claude/hooks/pre-compact.sh" }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": ".claude/hooks/stop-hook.sh" }
        ]
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          { "type": "command", "command": ".claude/hooks/session-end.sh" }
        ]
      }
    ],
    "PostToolUseFailure": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/tool-failure-logger.sh"
          }
        ]
      }
    ],
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
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/notification-handler.sh"
          }
        ]
      }
    ],
    "TeammateIdle": [
      {
        "hooks": [
          { "type": "command", "command": ".claude/hooks/teammate-idle.sh" }
        ]
      }
    ],
    "TaskCompleted": [
      {
        "hooks": [
          { "type": "command", "command": ".claude/hooks/task-completed.sh" }
        ]
      }
    ]
  }
}
```

**Note**: `PermissionRequest` is configured separately per permission type.

---

## Real Example

**Production**: 14 hooks, 6-8 hours/year ROI

See: `examples/production-claude-hooks/`

**Full guide**: Templates in `template/.claude/hooks/`

---

**Previous**: [12: Memory Bank](12-memory-bank-hierarchy.md)
**Next**: [14: Git vs Claude Hooks](14-git-vs-claude-hooks-distinction.md)
