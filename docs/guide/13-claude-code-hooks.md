# Chapter 13: Claude Code Hooks

**Purpose**: Automate workflows with event-driven hooks
**Source**: Anthropic blog "How to Configure Hooks"
**Evidence**: 6 hooks in production, 96% test validation
**Updated**: Feb 7, 2026 — Critical fix for PostToolUse hooks

---

## Hook Types (8 Available)

| Hook                  | Trigger           | Use For                    |
| --------------------- | ----------------- | -------------------------- |
| **SessionStart**      | Session begins    | Inject git status, context |
| **PostToolUse**       | After tool runs   | Auto-format, logging       |
| **PreCompact**        | Before compaction | Backup transcripts         |
| **PermissionRequest** | Permission dialog | Auto-approve safe commands |
| **Stop**              | Response ends     | Suggest skill creation     |

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

## Real Example

**Production**: 6 hooks, 6-8 hours/year ROI

See: `examples/production-claude-hooks/`

**Full guide**: Templates in `template/.claude/hooks/`

---

**Previous**: [12: Memory Bank](12-memory-bank-hierarchy.md)
**Next**: [14: Git vs Claude Hooks](14-git-vs-claude-hooks-distinction.md)
