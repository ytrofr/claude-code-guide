# Session Protocol - Anthropic Best Practice

**Source**: Anthropic's Claude Best Practices + Agent Harness patterns
**Version**: Updated for Claude Code 2.1.88

---

## Quick Summary

**Start**: `git status` -> check status -> select ONE incomplete task
**End**: Update status -> checkpoint commit -> never stop mid-feature
**Compaction**: On fresh context, discover state from filesystem

---

## Session Start Protocol

Run at beginning of EVERY session:

```bash
# Use slash command (preferred)
/session-start

# Or manual:
git status && git log --oneline -5
```

**Steps**:

1. `git status` -> Check current branch and changes
2. Check project status -> Find incomplete work
3. Select ONE incomplete task
4. Focus on incremental progress

---

## Session End Protocol

Run before ending ANY session:

```bash
# Use slash command (preferred)
/session-end

# Or manual:
git status --short
git add -A && git commit -m "checkpoint: [work description]"
```

**Checklist**:

- [ ] All work committed or checkpointed
- [ ] Status updated with progress
- [ ] No features left in unknown state

---

## Key Principles

- **Incremental Progress**: One feature at a time
- **Verify Before Complete**: Test before marking done
- **Compaction Awareness**: Discover state from filesystem on fresh context
- **Never Stop Mid-Feature**: Complete or create checkpoint
- **75% Context Rule**: Stop at 75% context usage, commit, start fresh session

---

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `CLAUDE_CODE_NO_FLICKER=1` | Flicker-free terminal rendering (reduces visual noise during output) |
| `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS=5000` | Extend SessionEnd hook timeout from default 1.5s |
| `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1` | Strip API credentials from subprocesses (Bash, hooks, MCP stdio) |

---

## Settings

| Setting | Default | Purpose |
|---------|---------|---------|
| `showThinkingSummaries` | OFF (since 2.1.88) | Show/hide model thinking summaries in output |

---

## Hook Events (2.1.88)

If using hooks in `settings.json`, these lifecycle events are available:

| Event | When |
|-------|------|
| `PreToolUse` / `PostToolUse` | Before/after tool execution |
| `Notification` | On notifications |
| `Stop` | When agent stops |
| `SubagentStop` | When a subagent stops |
| `PostCompact` | After context compaction (reload critical files here) |
| `CwdChanged` / `FileChanged` | Reactive environment management |
| `PermissionDenied` | When a tool call is denied by the user |

Hooks support conditional `if` fields using permission rule syntax to filter before spawning.
