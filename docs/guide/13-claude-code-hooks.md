---
layout: default
title: "Claude Code Hooks - Complete Guide to 18 Hook Events"
description: "Configure Claude Code hooks for PreToolUse, PostToolUse, and 16 more events. Command, prompt, and agent hook types. Async hooks. Decision control patterns."
---

# Chapter 13: Claude Code Hooks

Claude Code hooks are customizable scripts that run at specific points in the AI workflow, enabling automation, validation, and context injection. This guide covers all 18 hook events, 3 hook types, async execution, and production-tested patterns.

**Purpose**: Automate workflows with event-driven hooks
**Source**: Anthropic blog "How to Configure Hooks"
**Evidence**: 18 hooks in production, 96% test validation
**Updated**: Feb 24, 2026 — Added 4 new hook events (Setup, ConfigChange, WorktreeCreate, WorktreeRemove) and Advanced Hook Capabilities section (prompt/agent hooks, additionalContext, frontmatter hooks, last_assistant_message)

---

## Hook Events (18 Available)

| Hook                   | Trigger                         | Use For                                |
| ---------------------- | ------------------------------- | -------------------------------------- |
| **SessionStart**       | Session begins                  | Inject git status, context, env vars   |
| **UserPromptSubmit**   | User sends message              | Skill matching, prompt preprocessing   |
| **PreToolUse**         | Before tool executes            | Block dangerous operations, validation |
| **PostToolUse**        | After tool runs                 | Auto-format, logging, monitoring       |
| **PreCompact**         | Before context compaction       | Backup transcripts, save state         |
| **PermissionRequest**  | Permission dialog appears       | Auto-approve safe commands             |
| **Notification**       | Claude sends a notification     | Custom alerts, logging, integrations   |
| **Stop**               | Response ends                   | Suggest skill creation, cleanup        |
| **SessionEnd**         | Session closes                  | Save summaries, final checkpoint       |
| **PostToolUseFailure** | Tool call fails                 | Log errors, track failure patterns     |
| **SubagentStart**      | Subagent spawns                 | Monitor agent lifecycle, logging       |
| **SubagentStop**       | Subagent completes              | Log results, track agent activity      |
| **TeammateIdle**       | Teammate agent becomes idle     | Pause teammates, reassign work         |
| **TaskCompleted**      | A task finishes (Agent Teams)   | Reassign work, trigger follow-ups      |
| **Setup**              | `--init` / `--maintenance`      | Install deps, configure environments   |
| **ConfigChange**       | Config file changes mid-session | Security auditing, live reloading      |
| **WorktreeCreate**     | Agent worktree is created       | Custom VCS setup (SVN, Perforce, Hg)   |
| **WorktreeRemove**     | Agent worktree is removed       | Cleanup after agent completion         |

### Hook Categories

**Session Lifecycle**: SessionStart → UserPromptSubmit → ... → Stop → SessionEnd

**Tool Lifecycle**: PreToolUse → (tool runs) → PostToolUse / PostToolUseFailure

**Agent Lifecycle**: SubagentStart → (agent works) → SubagentStop

**Agent Teams**: TeammateIdle (idle detection), TaskCompleted (task completion)

**Worktree Lifecycle**: WorktreeCreate → (agent works in isolation) → WorktreeRemove

**Other**: PreCompact (context management), PermissionRequest (security), Notification (alerts), Setup (initialization), ConfigChange (config monitoring)

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
| Setup              | Ignored (cannot block)                 |
| ConfigChange       | Blocks config change (except policy)   |
| WorktreeCreate     | Fails worktree creation                |
| WorktreeRemove     | Ignored (cannot block)                 |

**Rule of thumb**: Exit code 2 only matters for "Pre" events (where blocking makes sense), agent team events (where pausing/reassignment makes sense), ConfigChange (security enforcement), and WorktreeCreate (VCS setup validation).

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

### Setup (v2.1.10)

Fires when Claude Code is invoked with `--init`, `--init-only`, or `--maintenance` flags. Use for first-time project setup tasks like installing dependencies or configuring environments.

```json
{
  "hooks": {
    "Setup": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/project-setup.sh"
          }
        ]
      }
    ]
  }
}
```

**Example script** (`.claude/hooks/project-setup.sh`):

```bash
#!/bin/bash
set -euo pipefail
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Install dependencies if package.json exists
if [ -f "$PROJECT_DIR/package.json" ]; then
  cd "$PROJECT_DIR" && npm install --silent 2>/dev/null || true
fi

# Set up git hooks
if [ -d "$PROJECT_DIR/.git" ] && [ -f "$PROJECT_DIR/.husky/pre-commit" ]; then
  cd "$PROJECT_DIR" && npx husky install 2>/dev/null || true
fi

exit 0
```

**Key behaviors**:

- Cannot block (exit code 2 is ignored)
- Runs once during initialization, not during normal sessions
- Ideal for `npm install`, `pip install -r requirements.txt`, environment validation

### ConfigChange (v2.1.49)

Fires when a configuration file changes mid-session. The `matcher` field filters by config type: `user_settings`, `project_settings`, `local_settings`, `policy_settings`, or `skills`.

```json
{
  "hooks": {
    "ConfigChange": [
      {
        "matcher": "user_settings|project_settings|local_settings",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/config-audit.sh"
          }
        ]
      }
    ]
  }
}
```

**Example script** (`.claude/hooks/config-audit.sh`):

```bash
#!/bin/bash
set -euo pipefail
INPUT=$(timeout 2 cat 2>/dev/null || echo '{}')
CONFIG_TYPE=$(echo "$INPUT" | jq -r '.config_type // "unknown"' 2>/dev/null || echo "unknown")
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
LOG_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/logs/config-changes.log"
mkdir -p "$(dirname "$LOG_FILE")"
echo "[$TIMESTAMP] Config changed: $CONFIG_TYPE" >> "$LOG_FILE"
exit 0
```

**Key behaviors**:

- Exit code 2 blocks the config change, **except** for `policy_settings` (enterprise policies cannot be blocked)
- Useful for enterprise security auditing and compliance logging
- Matchers: `user_settings`, `project_settings`, `local_settings`, `policy_settings`, `skills`

### WorktreeCreate (v2.1.50)

Fires when an agent worktree is created for agents configured with `isolation: worktree`. This enables custom VCS setup for projects using non-git version control (SVN, Perforce, Mercurial).

```json
{
  "hooks": {
    "WorktreeCreate": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/worktree-init.sh"
          }
        ]
      }
    ]
  }
}
```

**Example script** (`.claude/hooks/worktree-init.sh`):

```bash
#!/bin/bash
set -euo pipefail
INPUT=$(timeout 2 cat 2>/dev/null || echo '{}')
WORKTREE_PATH=$(echo "$INPUT" | jq -r '.worktree_path // empty' 2>/dev/null)

if [ -n "$WORKTREE_PATH" ]; then
  # Example: Initialize Perforce workspace in worktree
  # p4 client -o | sed "s|Root:.*|Root: $WORKTREE_PATH|" | p4 client -i
  echo "Worktree initialized at: $WORKTREE_PATH"
fi

exit 0
```

**Key behaviors**:

- Non-zero exit code **fails** the worktree creation (the agent will not spawn)
- Only fires for agents with `isolation: worktree` in their configuration
- Use for setting up VCS checkouts, symlinks, or environment files in the worktree

### WorktreeRemove (v2.1.50)

Fires when an agent worktree is removed after the agent completes its work. Use for cleanup tasks.

```json
{
  "hooks": {
    "WorktreeRemove": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/worktree-cleanup.sh"
          }
        ]
      }
    ]
  }
}
```

**Example script** (`.claude/hooks/worktree-cleanup.sh`):

```bash
#!/bin/bash
set -euo pipefail
INPUT=$(timeout 2 cat 2>/dev/null || echo '{}')
WORKTREE_PATH=$(echo "$INPUT" | jq -r '.worktree_path // empty' 2>/dev/null)

if [ -n "$WORKTREE_PATH" ]; then
  # Clean up VCS artifacts, temp files, etc.
  rm -rf "$WORKTREE_PATH/.p4config" 2>/dev/null || true
  echo "Worktree cleaned up: $WORKTREE_PATH"
fi

exit 0
```

**Key behaviors**:

- Cannot block (exit code 2 is ignored; the worktree is already being removed)
- Use for cleaning up VCS lock files, temporary caches, or external registrations
- Pairs with WorktreeCreate for full worktree lifecycle management

---

## Complete settings.json Example (All 18 Events)

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
    ],
    "Setup": [
      {
        "hooks": [
          { "type": "command", "command": ".claude/hooks/project-setup.sh" }
        ]
      }
    ],
    "ConfigChange": [
      {
        "matcher": "user_settings|project_settings|local_settings",
        "hooks": [
          { "type": "command", "command": ".claude/hooks/config-audit.sh" }
        ]
      }
    ],
    "WorktreeCreate": [
      {
        "hooks": [
          { "type": "command", "command": ".claude/hooks/worktree-init.sh" }
        ]
      }
    ],
    "WorktreeRemove": [
      {
        "hooks": [
          { "type": "command", "command": ".claude/hooks/worktree-cleanup.sh" }
        ]
      }
    ]
  }
}
```

**Note**: `PermissionRequest` is configured separately per permission type.

---

## Advanced Hook Capabilities

### Prompt-Based Hooks (v2.1.0)

Instead of writing a shell script, you can define a hook as a prompt that gets evaluated by an LLM. The LLM receives the event context and returns an allow/deny decision. No tools are available -- the decision is based solely on the prompt text and event data.

```json
{
  "PreToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [
        {
          "type": "prompt",
          "prompt": "Check if this change follows coding standards. Verify naming conventions, file organization, and that no secrets or credentials are being written. Return ALLOW if safe, DENY with reason if not."
        }
      ]
    }
  ]
}
```

**When to use**: Quick safety evaluations, style checks, or convention enforcement that can be decided from the event context alone without reading other files.

**Tradeoff**: Adds 1-3 seconds of LLM inference latency per matched event. Use command hooks for latency-sensitive paths.

### Agent-Based Hooks (v2.1.0)

Agent hooks spawn a subagent with tool access for multi-turn verification. The agent can read files, search code, and run commands before making a decision. This is the most powerful but also the most expensive hook type.

```json
{
  "PreToolUse": [
    {
      "matcher": "Bash",
      "hooks": [
        {
          "type": "agent",
          "prompt": "Verify this command is safe to run. Check if it modifies any protected files by reading .gitignore and .claude/settings.json. Verify it does not delete files outside the project directory.",
          "tools": ["Read", "Grep", "Glob"]
        }
      ]
    }
  ]
}
```

**When to use**: Complex validations that require file system inspection, comparison against existing patterns, or multi-step reasoning.

**Tradeoff**: Multiple LLM calls + tool execution per invocation. Can add 5-30+ seconds of latency. Use sparingly on high-frequency events.

### PreToolUse additionalContext (v2.1.9)

PreToolUse hooks can return `additionalContext` in their JSON output to inject context that the model sees alongside the tool result. This lets hooks guide Claude's behavior without blocking the tool call.

```json
{
  "additionalContext": "Remember: this project uses tabs not spaces. All new files must include the copyright header from .claude/templates/header.txt"
}
```

**Example hook script**:

```bash
#!/bin/bash
JSON_INPUT=$(timeout 2 cat 2>/dev/null || echo '{}')
FILE_PATH=$(echo "$JSON_INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

# Inject project-specific reminders for certain file types
case "$FILE_PATH" in
  *.sql)
    echo '{"additionalContext": "All SQL must use parameterized queries. Never concatenate user input."}'
    ;;
  *.test.*)
    echo '{"additionalContext": "Test files must include cleanup in afterEach. No test pollution."}'
    ;;
esac

exit 0
```

**Key behavior**: The `additionalContext` string is shown to the model alongside the tool result. It does not block the tool -- it adds guidance for the model's next response.

### Hooks in Skill/Agent Frontmatter (v2.1.0)

Hooks can be defined directly in skill or agent YAML frontmatter, scoped to the component's lifecycle. These hooks only fire while the skill or agent is active.

```yaml
---
name: my-deployment-skill
description: Deployment workflow with safety hooks
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: "command"
          command: ".claude/hooks/block-production-commands.sh"
  PostToolUse:
    - matcher: "Write"
      hooks:
        - type: "command"
          command: ".claude/hooks/validate-deployment-config.sh"
---
```

**Key behaviors**:

- Hooks are scoped to the skill/agent -- they do not fire outside its context
- Supports the `once: true` field to limit execution to once per session
- Merged with project and user hooks (they add to, not replace, other hooks)

### last_assistant_message in Stop/SubagentStop (v2.1.47)

The `Stop` and `SubagentStop` hooks now receive Claude's final response text in the input JSON via the `last_assistant_message` field. This eliminates the need to parse transcripts to access the model's last output.

```json
{
  "session_id": "abc123",
  "last_assistant_message": "I've completed the refactoring. Here's a summary of changes..."
}
```

**Example use case**: Extract action items, summaries, or structured data from Claude's final response for logging or follow-up workflows.

```bash
#!/bin/bash
INPUT=$(timeout 2 cat 2>/dev/null || echo '{}')
LAST_MSG=$(echo "$INPUT" | jq -r '.last_assistant_message // empty' 2>/dev/null)

if [ -n "$LAST_MSG" ]; then
  # Log the final response for session history
  echo "$LAST_MSG" >> "${CLAUDE_PROJECT_DIR:-.}/.claude/logs/session-responses.log"
fi

exit 0
```

---

## Real-World Production Example: Sacred Pattern Validation Hook

This example shows a prompt-based hook used in production to enforce code quality patterns on every file write:

```json
{
  "matcher": "Write|Edit",
  "hooks": [
    {
      "type": "prompt",
      "prompt": "Check if this code change to a src/**/*.js file follows Sacred patterns: (1) Uses employee_id not id for employee lookups, (2) No hardcoded business data like employee counts or revenue amounts, (3) Hebrew strings use UTF-8 encoding. If the file is NOT in src/ or is not a .js file, always allow. Output JSON: {\"decision\":\"allow\"} or {\"decision\":\"block\",\"reason\":\"Sacred violation: ...\"}"
    }
  ]
}
```

**Key patterns demonstrated**:

- **Scoped validation**: The prompt itself filters by file path (`src/**/*.js`), allowing non-matching files through
- **Multiple checks in one hook**: Validates 3 different patterns in a single prompt
- **Structured output**: Returns JSON for programmatic decision-making
- **Non-blocking for irrelevant files**: Files outside `src/` are auto-allowed

### Combining Prompt Hooks with Async Background Hooks

For non-critical monitoring, use `async: true` to avoid blocking:

```json
{
  "SubagentStart": [
    {
      "hooks": [
        {
          "type": "command",
          "command": ".claude/hooks/subagent-monitor.sh",
          "async": true
        }
      ]
    }
  ],
  "PostToolUseFailure": [
    {
      "hooks": [
        {
          "type": "command",
          "command": ".claude/hooks/tool-failure-logger.sh",
          "async": true
        }
      ]
    }
  ]
}
```

**Rule of thumb**: Use `async: true` for logging/monitoring hooks. Keep synchronous for validation/blocking hooks.

---

## Hook Best Practices

### Always Exit 0

Hooks **must** exit with code 0 unless they intentionally want to block an action (PreToolUse exit code 2). A non-zero exit from a non-blocking hook causes Claude Code to display an error and can disrupt the workflow.

```bash
#!/bin/bash
# CORRECT: Always exit 0 in non-blocking hooks
JSON_INPUT=$(timeout 2 cat 2>/dev/null || echo '{}')
# ... process input ...

# Ensure exit 0 even if processing fails
exit 0
```

**Pattern**: Use `|| true` or explicit `exit 0` at the end of every hook script. Even if earlier commands fail, the hook should not block Claude.

```bash
#!/bin/bash
# Safe pattern: trap ensures exit 0 on any failure
trap 'exit 0' ERR
set -euo pipefail

# ... your hook logic ...

exit 0
```

**Source**: Anthropic Chief of Staff agent cookbook pattern. In production, 100% of hooks should exit 0 (except intentional PreToolUse blockers).

### Python Hooks

For complex JSON processing or logic that's cumbersome in bash, use Python hook scripts instead:

```json
{
  "PostToolUse": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "python3 .claude/hooks/report-tracker.py"
        }
      ]
    }
  ]
}
```

**Example** (`.claude/hooks/report-tracker.py`):

```python
#!/usr/bin/env python3
import sys, json

try:
    data = json.loads(sys.stdin.read())
    tool_name = data.get("tool_name", "unknown")
    # Complex JSON processing is much easier in Python
    if tool_name == "Write":
        file_path = data.get("tool_input", {}).get("file_path", "")
        # Track which files were written during session
        with open(".claude/logs/files-written.log", "a") as f:
            f.write(f"{file_path}\n")
except Exception:
    pass  # Never crash, never block

sys.exit(0)  # Always exit 0
```

**When to use Python hooks**:

- Complex JSON parsing (nested objects, arrays, conditional logic)
- File tracking, report generation, analytics aggregation
- Any logic that would require `jq` gymnastics in bash

**Source**: Anthropic Chief of Staff agent uses `report-tracker.py` and `script-usage-logger.py` as production hook patterns.

### Hook Configuration with settings.local.json

Use `.claude/settings.local.json` for personal hook overrides that should not be committed to git:

```json
// .claude/settings.local.json (NOT committed)
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/my-personal-formatter.sh"
          }
        ]
      }
    ]
  }
}
```

Local hooks merge with project hooks (they don't replace them). This is useful for:

- Personal formatting preferences
- Debug logging hooks during development
- Experimental hooks before promoting to project-level

---

## Real-World Production Example: File Size / Modularity Enforcement

This example demonstrates using **PreToolUse + PostToolUse together** to enforce a maximum file size rule. The two hooks are complementary: PreToolUse catches new oversized files _before_ they hit disk, while PostToolUse detects existing files _growing_ past the threshold.

**Problem**: In a large codebase (600+ source files), "god files" accumulate over time. A max-500-lines-per-file rule exists, but without enforcement it is regularly violated. Manually checking every write is impractical.

**Solution**: Two non-blocking hooks that show warnings to Claude, so it can self-correct.

### Hook 1: PreToolUse -- Catch New God Files

File: `.claude/hooks/file-size-precheck.sh`

This fires **before** the `Write` tool. It reads the content about to be written from `tool_input.content`, counts lines, and warns if the new file would exceed thresholds.

```bash
#!/bin/bash
# PreToolUse hook: Check Write content size BEFORE file is created
JSON_INPUT=$(timeout 2 cat 2>/dev/null || true)
FILE_PATH=$(echo "$JSON_INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

[ -z "$FILE_PATH" ] && exit 0

# Only check source code files
case "$FILE_PATH" in
  *.js|*.jsx|*.ts|*.tsx|*.py|*.sh) ;; # Check these
  *) exit 0 ;; # Skip non-source files
esac

# Skip test files, node_modules, dist
case "$FILE_PATH" in
  */node_modules/*|*/dist/*|*package-lock*|*/tests/*|*/scripts/baselines/*) exit 0 ;;
esac

# Count lines in the content being written
CONTENT_LINES=$(echo "$JSON_INPUT" | jq -r '.tool_input.content // empty' 2>/dev/null | wc -l)

[ "$CONTENT_LINES" -le 300 ] && exit 0

BASENAME=$(basename "$FILE_PATH")
[ ! -f "$FILE_PATH" ] && FILE_STATUS="NEW file" || FILE_STATUS="overwriting existing"

if [ "$CONTENT_LINES" -gt 500 ]; then
  echo ""
  echo "======================================================================="
  echo "FILE SIZE: $BASENAME will be $CONTENT_LINES lines ($FILE_STATUS)"
  echo "======================================================================="
  echo "This file exceeds the 500-line limit. Consider splitting into:"
  echo "  - Main module: core logic (<400 lines)"
  echo "  - Helper module: extracted functions"
  echo "Allowing write -- but please split this file next."
  echo "======================================================================="
elif [ "$CONTENT_LINES" -gt 400 ]; then
  echo ""
  echo "-----------------------------------------------------------------------"
  echo "WARNING: $BASENAME will be $CONTENT_LINES lines ($FILE_STATUS)"
  echo "-----------------------------------------------------------------------"
  echo "Approaching 500-line limit. Plan extraction now."
  echo "-----------------------------------------------------------------------"
fi

exit 0
```

### Hook 2: PostToolUse -- Detect Growth in Existing Files

File: `.claude/hooks/file-size-warning.sh`

This fires **after** `Write|Edit`. It checks the actual file on disk and uses a `/tmp` cache to track growth between edits. Only warns on files >500 lines if they **grew by 20+ lines** in this edit (avoids noise on existing large files).

```bash
#!/bin/bash
# PostToolUse hook: Warn when edited files GROW past thresholds
JSON_INPUT=$(timeout 2 cat 2>/dev/null || true)
FILE_PATH=$(echo "$JSON_INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

[ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ] && exit 0

# Only check source code files
case "$FILE_PATH" in
  *.js|*.jsx|*.ts|*.tsx|*.py|*.sh) ;;
  *) exit 0 ;;
esac

case "$FILE_PATH" in
  */node_modules/*|*/dist/*|*package-lock*|*/tests/*|*/scripts/baselines/*) exit 0 ;;
esac

LINE_COUNT=$(wc -l < "$FILE_PATH" 2>/dev/null || echo "0")
BASENAME=$(basename "$FILE_PATH")

# Growth detection via file size cache
CACHE_DIR="/tmp/.claude-file-sizes"
mkdir -p "$CACHE_DIR" 2>/dev/null
CACHE_KEY=$(echo "$FILE_PATH" | md5sum | cut -d' ' -f1)
CACHE_FILE="$CACHE_DIR/$CACHE_KEY"

PREV_SIZE=0
[ -f "$CACHE_FILE" ] && PREV_SIZE=$(cat "$CACHE_FILE" 2>/dev/null || echo "0")
echo "$LINE_COUNT" > "$CACHE_FILE"

GROWTH=$((LINE_COUNT - PREV_SIZE))

if [ "$LINE_COUNT" -gt 500 ]; then
  # Only warn if it GREW significantly (20+ lines)
  if [ "$GROWTH" -ge 20 ] && [ "$PREV_SIZE" -gt 0 ]; then
    echo ""
    echo "-----------------------------------------------------------------------"
    echo "GROWING: $BASENAME grew +${GROWTH} lines -> now $LINE_COUNT lines"
    echo "-----------------------------------------------------------------------"
    echo "Consider extracting the new code into a separate module."
    echo "-----------------------------------------------------------------------"
  fi
elif [ "$LINE_COUNT" -gt 400 ]; then
  echo ""
  echo "WARNING: $BASENAME is $LINE_COUNT lines (approaching 500 limit)"
elif [ "$LINE_COUNT" -gt 300 ] && [ "$PREV_SIZE" -le 300 ] && [ "$PREV_SIZE" -gt 0 ]; then
  echo "NOTE: $BASENAME crossed 300 lines ($PREV_SIZE -> $LINE_COUNT). Monitor growth."
fi

exit 0
```

### Configuration

Add both hooks to `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/file-size-precheck.sh"
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
            "command": ".claude/hooks/file-size-warning.sh"
          }
        ]
      }
    ]
  }
}
```

### Design Decisions

| Decision                                | Rationale                                                                                                                                                                                                 |
| --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Non-blocking** (exit 0 always)        | Writes proceed; Claude sees the warning and self-corrects. Blocking writes mid-session causes more disruption than value.                                                                                 |
| **PreToolUse on Write only** (not Edit) | The Write tool creates/overwrites entire files. Edit makes small changes -- the PostToolUse hook handles growth detection for edits.                                                                      |
| **Growth detection via md5sum cache**   | In a codebase with 250+ existing files over 500 lines, warning on every edit to those files is pure noise. The cache tracks file sizes between edits, and only warns if a large file _grew_ by 20+ lines. |
| **Source files only**                   | Only checks `.js`, `.ts`, `.py`, `.sh` (and variants). Skips docs, configs, test files, generated files, and `node_modules`.                                                                              |
| **Three thresholds** (300 / 400 / 500)  | 300 = informational note (only on first crossing), 400 = warning, 500 = strong alert with split suggestions. Progressive awareness, not a cliff.                                                          |

### How It Works in Practice

```
Claude writes a 620-line service file:
  -> PreToolUse fires: "FILE SIZE: service.js will be 620 lines (NEW file)"
  -> Claude sees the warning, splits into service.js (380L) + service-helpers.js (240L)

Claude edits an existing 510-line file, adding 25 lines:
  -> PostToolUse fires: "GROWING: service.js grew +25 lines -> now 535 lines"
  -> Claude extracts the new code into a helper module instead

Claude edits an existing 520-line file, changing 3 lines:
  -> PostToolUse: SILENT (no growth, avoids noise on legacy files)
```

**Testing**: Create a test file and pipe mock JSON to validate both hooks:

```bash
# Test PreToolUse with a 600-line file
CONTENT=$(python3 -c "print('\n'.join(['line ' + str(i) for i in range(600)]))")
echo "{\"tool_input\":{\"file_path\":\"/tmp/test.js\",\"content\":\"$CONTENT\"}}" | \
  bash .claude/hooks/file-size-precheck.sh
```

---

## Real Example

**Production**: 18 hooks, 6-8 hours/year ROI

See: `examples/production-claude-hooks/`

**Full guide**: Templates in `template/.claude/hooks/`

---

**Previous**: [12: Memory Bank](12-memory-bank-hierarchy.md)
**Next**: [14: Git vs Claude Hooks](14-git-vs-claude-hooks-distinction.md)
