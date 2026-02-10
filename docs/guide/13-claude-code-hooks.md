# Chapter 13: Claude Code Hooks

**Purpose**: Automate workflows with event-driven hooks
**Source**: Anthropic blog "How to Configure Hooks"
**Evidence**: 11 hooks in production, 96% test validation
**Updated**: Feb 10, 2026 — All 11 hook events documented

---

## Hook Events (11 Available)

| Hook                   | Trigger                   | Use For                                |
| ---------------------- | ------------------------- | -------------------------------------- |
| **SessionStart**       | Session begins            | Inject git status, context, env vars   |
| **UserPromptSubmit**   | User sends message        | Skill matching, prompt preprocessing   |
| **PreToolUse**         | Before tool executes      | Block dangerous operations, validation |
| **PostToolUse**        | After tool runs           | Auto-format, logging, monitoring       |
| **PreCompact**         | Before context compaction | Backup transcripts, save state         |
| **PermissionRequest**  | Permission dialog appears | Auto-approve safe commands             |
| **Stop**               | Response ends             | Suggest skill creation, cleanup        |
| **SessionEnd**         | Session closes            | Save summaries, final checkpoint       |
| **PostToolUseFailure** | Tool call fails           | Log errors, track failure patterns     |
| **SubagentStart**      | Subagent spawns           | Monitor agent lifecycle, logging       |
| **SubagentStop**       | Subagent completes        | Log results, track agent activity      |

### Hook Categories

**Session Lifecycle**: SessionStart → UserPromptSubmit → ... → Stop → SessionEnd

**Tool Lifecycle**: PreToolUse → (tool runs) → PostToolUse / PostToolUseFailure

**Agent Lifecycle**: SubagentStart → (agent works) → SubagentStop

**Other**: PreCompact (context management), PermissionRequest (security)

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

---

## Complete settings.json Example (All 11 Events)

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
    ]
  }
}
```

**Note**: `PermissionRequest` is configured separately per permission type.

---

## Real Example

**Production**: 11 hooks, 6-8 hours/year ROI

See: `examples/production-claude-hooks/`

**Full guide**: Templates in `template/.claude/hooks/`

---

**Previous**: [12: Memory Bank](12-memory-bank-hierarchy.md)
**Next**: [14: Git vs Claude Hooks](14-git-vs-claude-hooks-distinction.md)
