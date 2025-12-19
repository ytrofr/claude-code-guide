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

## Real Example

**LIMOR AI production**: 6 hooks, 6-8 hours/year ROI

See: `examples/limor-ai-claude-hooks/`

**Full guide**: Templates in `template/.claude/hooks/`

---

**Previous**: [12: Memory Bank](12-memory-bank-hierarchy.md)
**Next**: [14: Git vs Claude Hooks](14-git-vs-claude-hooks-distinction.md)
