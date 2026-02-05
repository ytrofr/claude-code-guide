# Chapter 13: Claude Code Hooks

**Purpose**: Automate workflows with event-driven hooks
**Source**: Anthropic blog "How to Configure Hooks"
**Evidence**: LIMOR AI 6 hooks, 96% test validation

---

## Hook Types (8 Available)

| Hook | Trigger | Use For |
|------|---------|---------|
| **SessionStart** | Session begins | Inject git status, context |
| **PostToolUse** | After tool runs | Auto-format, logging |
| **PreCompact** | Before compaction | Backup transcripts |
| **PermissionRequest** | Permission dialog | Auto-approve safe commands |
| **Stop** | Response ends | Suggest skill creation |

---

## Quick Config

File: `.claude/settings.json`

```json
{
  "hooks": {
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": ".claude/hooks/session-start.sh"
      }]
    }],
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{
        "type": "command",
        "command": "npx prettier --write \"$CLAUDE_TOOL_INPUT_FILE_PATH\" 2>/dev/null || true"
      }]
    }]
  }
}
```

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

**Evidence**: Feb 2026 — LIMOR AI production. `PostToolUse:Read` hook hung during multi-file implementation session. Root cause: `$(cat)` in `skill-access-monitor.sh`. Fix: `$(timeout 2 cat)`. Verified: 2016ms completion vs infinite hang.

---

## Real Example

**LIMOR AI production**: 6 hooks, 6-8 hours/year ROI

See: `examples/limor-ai-claude-hooks/`

**Full guide**: Templates in `template/.claude/hooks/`

---

**Previous**: [12: Memory Bank](12-memory-bank-hierarchy.md)
**Next**: [14: Git vs Claude Hooks](14-git-vs-claude-hooks-distinction.md)
