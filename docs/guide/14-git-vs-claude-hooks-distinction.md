# Chapter 14: Git Hooks vs Claude Code Hooks

**Purpose**: Understand the difference between two hook systems that work alongside each other
**Critical**: These are separate systems with different triggers, locations, and purposes

---

## Quick Comparison

| Aspect                | Git Hooks                           | Claude Code Hooks                      |
| --------------------- | ----------------------------------- | -------------------------------------- |
| **Location**          | `.git/hooks/` or `.husky/`          | `.claude/settings.json`                |
| **Trigger**           | Git operations (commit, push)       | Claude Code events (tool use, session) |
| **Language**          | Any executable (bash, python, etc.) | Shell commands or scripts              |
| **Purpose**           | Code quality gates                  | AI workflow automation                 |
| **Runs when**         | Developer runs git commands         | Claude Code performs actions           |
| **Blocks on failure** | Can prevent commit/push             | Can block tool execution               |

---

## Git Hooks

Git hooks are scripts that run automatically when specific git events occur. They are configured in `.git/hooks/` (or via tools like Husky in `.husky/`).

### Common Git Hooks

| Hook         | Trigger                         | Typical Use             |
| ------------ | ------------------------------- | ----------------------- |
| `pre-commit` | Before commit is created        | Lint, format, run tests |
| `commit-msg` | After commit message is written | Validate message format |
| `pre-push`   | Before push to remote           | Run full test suite     |
| `post-merge` | After merge completes           | Install dependencies    |

### Example: Pre-commit with Husky

```bash
# .husky/pre-commit
npm run lint
npm run format:check
npm test -- --bail
```

This runs linting, format checking, and tests before every commit. If any step fails, the commit is blocked.

### Key characteristics

- Run on the developer's machine (not in CI)
- Can be bypassed with `--no-verify` (use sparingly)
- Shared via tools like Husky (`.git/hooks/` is not tracked by git)
- Focus on preventing bad code from entering the repository

---

## Claude Code Hooks

Claude Code hooks run when Claude performs specific actions during a session. They are configured in `.claude/settings.json` under the `hooks` key.

### Available Hook Events

| Event                | Trigger                   | Use For                                    |
| -------------------- | ------------------------- | ------------------------------------------ |
| `SessionStart`       | Session begins            | Load context, set up environment           |
| `PreToolUse`         | Before Claude uses a tool | Block dangerous operations, inject context |
| `PostToolUse`        | After Claude uses a tool  | Log activity, format output                |
| `SubagentStart`      | Before a subagent runs    | Monitor agent usage                        |
| `SubagentStop`       | After a subagent finishes | Log agent results                          |
| `PostToolUseFailure` | After a tool call fails   | Log errors                                 |

### Example: settings.json Configuration

```json
{
  "hooks": {
    "SessionStart": [
      {
        "command": "bash .claude/hooks/session-start.sh",
        "description": "Load branch-specific context"
      }
    ],
    "PreToolUse": [
      {
        "command": "bash .claude/hooks/pre-prompt.sh",
        "description": "Inject relevant skills into context",
        "toolNames": ["Read"]
      }
    ],
    "PostToolUse": [
      {
        "command": "bash .claude/hooks/prettier-format.sh",
        "description": "Auto-format written files",
        "toolNames": ["Write", "Edit"]
      }
    ]
  }
}
```

### Key characteristics

- Run during Claude Code sessions (not during manual git operations)
- Receive input via stdin as JSON (tool name, input parameters)
- Can filter by tool name using `toolNames` array
- Focus on controlling and enhancing AI behavior

### Important: stdin handling

Claude Code passes data to hooks via stdin as JSON. Scripts must read it properly:

```bash
# Correct: read stdin with timeout (prevents hanging)
JSON_INPUT=$(timeout 2 cat)
FILE_PATH=$(echo "$JSON_INPUT" | jq -r '.tool_input.file_path // empty')

# Wrong: using environment variables that don't exist
# $CLAUDE_TOOL_INPUT_FILE_PATH is NOT a valid variable
```

---

## When to Use Which

| Scenario                                         | Use                        |
| ------------------------------------------------ | -------------------------- |
| Lint code before committing                      | Git hook (pre-commit)      |
| Block Claude from writing to certain directories | Claude hook (PreToolUse)   |
| Run tests before pushing                         | Git hook (pre-push)        |
| Auto-format files after Claude edits them        | Claude hook (PostToolUse)  |
| Validate commit message format                   | Git hook (commit-msg)      |
| Load branch-specific context at session start    | Claude hook (SessionStart) |
| Inject skill suggestions based on query          | Claude hook (PreToolUse)   |
| Ensure dependencies are installed after merge    | Git hook (post-merge)      |

---

## Using Both Together

The two hook systems complement each other. A typical project might use:

**Git hooks** for code quality gates:

- Pre-commit: lint + format + quick tests
- Pre-push: full test suite

**Claude Code hooks** for AI workflow control:

- SessionStart: load branch context, set up environment
- PreToolUse: inject relevant skills, block risky operations
- PostToolUse: auto-format files, log tool usage

This layered approach means Claude's output passes through formatting hooks during the session, and the final code passes through quality hooks when committed. Both layers work independently and reinforce each other.

---

## Common Pitfalls

**Confusing the two systems**: Git hooks don't affect Claude Code sessions, and Claude hooks don't affect manual git commands. They are entirely separate.

**Hook scripts that hang**: Claude Code hooks must complete quickly. Use `timeout` when reading stdin. Avoid commands that wait for interactive input.

**Forgetting toolNames filter**: Without `toolNames`, a PostToolUse hook runs on every tool call (Read, Write, Bash, etc.). Filter to only the tools you care about.

---

**Previous**: [13: Claude Code Hooks](13-claude-code-hooks.md)
**Next**: [15: Progressive Disclosure](15-progressive-disclosure.md)
