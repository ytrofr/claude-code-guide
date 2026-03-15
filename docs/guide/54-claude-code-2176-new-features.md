---
layout: default
title: "Claude Code 2.1.73-2.1.76 — PostCompact Hook, Worktree Sparse Paths, MCP Elicitation & More"
description: "Key features from Claude Code releases 2.1.73 through 2.1.76 (March 11-14, 2026): PostCompact hook, /effort command, session naming, worktree sparse checkout, MCP elicitation, 1M context for Opus 4.6, configurable SessionEnd timeout, autoMemoryDirectory, and /context improvements."
---

# Chapter 54: Claude Code 2.1.73-2.1.76 New Features

Four releases in four days (March 11-14, 2026) landed a cluster of features that change how sessions manage context, how worktrees handle large repos, and how MCP servers interact with users. This chapter covers each feature with practical configuration examples.

---

## 1. PostCompact Hook (2.1.76)

Context compaction discards old messages to free up space. The problem: compaction can drop critical instructions that were loaded at session start. The new `PostCompact` hook fires immediately after compaction completes, giving you a chance to reload anything important.

### The Problem It Solves

```
Session start: CLAUDE.md loaded, rules loaded, context full of instructions
    ...100 messages later...
Compaction: old messages removed, including those initial instructions
Result: Claude forgets project conventions mid-session
```

### Configuration

Add to `.claude/settings.json` (project) or `~/.claude/settings.json` (global):

```json
{
  "hooks": {
    "PostCompact": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/home/you/.claude/hooks/post-compact-reload.sh"
          }
        ]
      }
    ]
  }
}
```

### Example Hook Script

Create `~/.claude/hooks/post-compact-reload.sh`:

```bash
#!/bin/bash
# PostCompact Hook — Reload critical context after compaction

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
RELOAD_FILES=""

# Reload project instructions
[ -f "$PROJECT_ROOT/CLAUDE.md" ] && RELOAD_FILES="$RELOAD_FILES $PROJECT_ROOT/CLAUDE.md"

# Reload critical rules
for rule in "$PROJECT_ROOT/.claude/rules/"*.md; do
    [ -f "$rule" ] && RELOAD_FILES="$RELOAD_FILES $rule"
done

if [ -n "$RELOAD_FILES" ]; then
    echo "Reloaded context files after compaction:$RELOAD_FILES"
fi

exit 0
```

```bash
chmod +x ~/.claude/hooks/post-compact-reload.sh
```

### Relationship to PreCompact

| Hook          | Fires                  | Use Case                                    |
| ------------- | ---------------------- | ------------------------------------------- |
| `PreCompact`  | Before compaction runs | Save state, warn about important context    |
| `PostCompact` | After compaction ends  | Reload critical files, re-inject rules      |

Use both together for a complete compaction lifecycle: save before, restore after.

---

## 2. /effort Slash Command (2.1.76)

Set the model's reasoning effort level within a running session.

```
/effort high     # Maximum reasoning depth
/effort medium   # Balanced (default)
/effort low      # Fast responses, less reasoning
```

Like `/model`, this command works while Claude is actively responding -- you do not need to wait for the current response to finish. The change takes effect on the next message.

### When to Use Each Level

| Level    | Best For                                              |
| -------- | ----------------------------------------------------- |
| `high`   | Architecture decisions, complex debugging, code review |
| `medium` | General development, feature implementation           |
| `low`    | Simple lookups, formatting, file renaming             |

---

## 3. Session Naming with --name / -n (2.1.76)

Set a display name for the session at startup:

```bash
claude --name "feature/auth-refactor"
claude -n "hotfix-prod-db"
```

The name appears on the prompt bar. You can change it mid-session with `/rename`.

### Practical Use: Multi-Branch Workflows

When working across multiple branches in separate terminals, session names prevent confusion:

```bash
# Terminal 1
cd ~/project && git checkout main
claude -n "main"

# Terminal 2
cd ~/project && git checkout feature/new-api
claude -n "feature/new-api"

# Terminal 3
cd ~/project && git checkout hotfix/auth-bug
claude -n "hotfix/auth-bug"
```

Each terminal's prompt bar shows which branch context it belongs to.

---

## 4. worktree.sparsePaths Setting (2.1.76)

For large monorepos using `--worktree`, the new `worktree.sparsePaths` setting limits which directories get checked out. This uses git sparse-checkout under the hood, avoiding the cost of cloning an entire monorepo into each worktree.

### Configuration

Add to `.claude/settings.json`:

```json
{
  "worktree": {
    "sparsePaths": [
      "packages/my-service/",
      "packages/shared-lib/",
      "configs/",
      "package.json",
      "tsconfig.json"
    ]
  }
}
```

### How It Works

1. You run `claude --worktree` (or use `EnterWorktree`)
2. Claude creates a new git worktree from your branch
3. Instead of checking out the full repo, only paths listed in `sparsePaths` are materialized
4. The worktree is lighter, faster to create, and uses less disk space

### When to Use It

| Repo Size      | Use sparsePaths? | Why                                         |
| -------------- | ----------------- | ------------------------------------------- |
| < 1 GB         | No                | Full checkout is fast enough                |
| 1-10 GB        | Optional          | Helps if you only touch a few packages      |
| > 10 GB        | Yes               | Avoids multi-minute checkout and disk bloat |

### Example: Node.js Monorepo

```json
{
  "worktree": {
    "sparsePaths": [
      "packages/api/",
      "packages/shared/",
      "packages/types/",
      "package.json",
      "pnpm-lock.yaml",
      "tsconfig.base.json",
      ".eslintrc.js"
    ]
  }
}
```

This checks out three packages plus root config files, skipping `packages/web/`, `packages/mobile/`, and any other large directories you do not need.

---

## 5. MCP Elicitation Support (2.1.76)

MCP servers can now request structured input from the user mid-task. Previously, MCP tools could only receive input at invocation time. With elicitation, a tool can pause execution, ask the user a question, and resume with the answer.

### New Hook Events

| Hook                | Fires                                      | Use Case                            |
| ------------------- | ------------------------------------------ | ----------------------------------- |
| `Elicitation`       | When an MCP server requests user input     | Log, filter, or auto-respond        |
| `ElicitationResult` | After the user responds to the elicitation | Log responses, audit input patterns |

### Configuration

```json
{
  "hooks": {
    "Elicitation": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "echo 'MCP elicitation requested' >> /tmp/mcp-elicitation.log"
          }
        ]
      }
    ]
  }
}
```

### What This Enables

- A database MCP server can ask "Which schema?" before running a migration
- A deployment MCP server can ask "Production or staging?" before deploying
- An authentication MCP server can request credentials when a token expires

The elicitation appears as a prompt in the Claude Code interface. The user responds, and the MCP server receives the answer to continue its operation.

---

## 6. 1M Context Window for Opus 4.6 (2.1.75)

Claude Opus 4.6 now defaults to a 1,000,000-token context window on Max, Team, and Enterprise plans. Previously, the 1M window required enabling extended thinking or extra usage allocation.

### What Changes

| Plan       | Opus 4.6 Context | Before 2.1.75 |
| ---------- | ----------------- | ------------- |
| Max        | 1M (default)      | 200K default  |
| Team       | 1M (default)      | 200K default  |
| Enterprise | 1M (default)      | 200K default  |
| Pro        | 200K              | 200K          |

### Practical Impact

- Longer sessions before compaction triggers
- More files readable in a single context window
- Larger codebases navigable without aggressive summarization
- The `/context` command shows capacity based on the 1M limit

No configuration change is needed. The larger window activates automatically when using Opus 4.6 on a supported plan.

---

## 7. Configurable SessionEnd Hook Timeout (2.1.74)

SessionEnd hooks previously had a hard-coded 1.5-second timeout. If your hook needed to write a session summary, sync to a remote service, or process observation logs, 1.5 seconds was often not enough.

### Configuration

Set the timeout via environment variable (in milliseconds):

```bash
# In ~/.bashrc or ~/.zshrc
export CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS=10000  # 10 seconds
```

### Recommended Values

| Hook Complexity                    | Timeout     |
| ---------------------------------- | ----------- |
| Simple logging                     | 2000 (2s)   |
| Git-based session summary          | 5000 (5s)   |
| Remote sync (Basic Memory, API)    | 10000 (10s) |
| Heavy processing (AI compression)  | 15000 (15s) |

### Example: Session Summary With Enough Time

If you use the auto-session-summary pattern from [Chapter 51](51-persistent-memory-patterns.md), increase the timeout to give git operations time to complete:

```bash
export CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS=8000
```

Without this, complex SessionEnd hooks silently fail when they exceed the default timeout.

---

## 8. autoMemoryDirectory Setting (2.1.74)

By default, Claude Code stores auto-memory (the `CLAUDE.md` entries created by `/memory` and automatic observations) alongside your project. The `autoMemoryDirectory` setting lets you redirect this to a custom location.

### Configuration

Add to `~/.claude/settings.json` (global) or `.claude/settings.json` (project):

```json
{
  "autoMemoryDirectory": "/home/you/claude-memory"
}
```

### Use Cases

| Scenario                     | Directory                           | Why                                            |
| ---------------------------- | ----------------------------------- | ---------------------------------------------- |
| Centralized memory           | `~/claude-memory/`                  | All projects write to one searchable location  |
| Synced across machines       | `~/Dropbox/claude-memory/`          | Memory available on multiple workstations      |
| Separated from code          | `~/.claude/auto-memory/`            | Keep memory out of git repos                   |
| Per-project (default)        | (not set)                           | Memory stays in project directory              |

### Interaction With Basic Memory MCP

If you use Basic Memory MCP, you can point `autoMemoryDirectory` to your Basic Memory content folder so auto-observations flow directly into the searchable knowledge base:

```json
{
  "autoMemoryDirectory": "/home/you/basic-memory/auto-observations"
}
```

---

## 9. /context Command Improvements (2.1.74)

The `/context` command now provides actionable diagnostics instead of just showing raw token counts.

### New Output Sections

**Context-Heavy Tools**: Identifies which tools are consuming the most context. If a single Bash output used 50K tokens, `/context` flags it.

**Memory Bloat Detection**: Warns when CLAUDE.md files, rules, or loaded skills are consuming a disproportionate share of the context window.

**Capacity Warnings**: Shows color-coded capacity status:

| Capacity Used | Status   | Action                                    |
| ------------- | -------- | ----------------------------------------- |
| < 50%         | Normal   | No action needed                          |
| 50-75%        | Moderate | Consider compacting soon                  |
| 75-90%        | High     | Compaction recommended                    |
| > 90%         | Critical | Compaction imminent, reduce tool output   |

**Actionable Suggestions**: Instead of just "context is 80% full," the command now suggests specific actions: "Consider adding `head_limit` to Grep calls" or "3 rules files account for 15% of context -- consider path-specific loading."

---

## 10. Key Bug Fixes

### Deferred Tool Schemas Survive Compaction

Previously, if you used `ToolSearch` to fetch a deferred tool's schema, compaction could discard the schema from context. The tool would appear available but fail on invocation. Fixed in 2.1.76 -- deferred tool schemas are now preserved across compaction events.

### RTL Text Rendering

Hebrew, Arabic, and other right-to-left scripts now render correctly in Claude Code's terminal output. Previously, mixed LTR/RTL content could produce garbled display, particularly in code blocks containing RTL string literals.

### Background Agent Partial Results

When a background agent (launched via `TaskCreate`) is killed or times out, its partial results are now preserved and accessible via `TaskGet`. Previously, killing a background agent discarded all accumulated output.

### Stale Worktree Auto-Cleanup

Worktrees created by `--worktree` or `EnterWorktree` are now automatically cleaned up when the associated branch is deleted or the worktree directory becomes stale. Previously, orphaned worktrees accumulated on disk and required manual `git worktree prune`.

---

## Configuration Summary

All settings from this chapter in one reference:

```json
{
  "hooks": {
    "PostCompact": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/home/you/.claude/hooks/post-compact-reload.sh"
          }
        ]
      }
    ]
  },
  "worktree": {
    "sparsePaths": [
      "packages/my-service/",
      "packages/shared-lib/",
      "configs/"
    ]
  },
  "autoMemoryDirectory": "/home/you/claude-memory"
}
```

Environment variables:

```bash
export CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS=8000
```

---

**See Also**:

- [Chapter 13: Claude Code Hooks](13-claude-code-hooks.md)
- [Chapter 42: Session Memory Compaction](42-session-memory-compaction.md)
- [Chapter 46: Advanced Configuration Patterns](46-advanced-configuration-patterns.md)
- [Chapter 48: Lean Orchestrator Pattern](48-lean-orchestrator-pattern.md)
- [Chapter 51: Persistent Memory Patterns](51-persistent-memory-patterns.md)
