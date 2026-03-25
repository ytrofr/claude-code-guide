---
layout: default
title: "Claude Code 2.1.82-2.1.83 — New Features & Improvements"
parent: Guide
nav_order: 60
---

# Claude Code 2.1.82-2.1.83 — New Features & Improvements

*Released: March 2026*

## Overview

Claude Code 2.1.82-2.1.83 brings reactive hook events, background agent stability, auto-memory management, transcript navigation, and security hardening. These releases focus on reliability and developer experience polish.

---

## New Hook Events

### CwdChanged (2.1.83)

Fires when the working directory changes. Enables reactive environment management:

```json
{
  "hooks": {
    "CwdChanged": [{
      "type": "command",
      "command": "direnv allow 2>/dev/null || true"
    }]
  }
}
```

Use cases:
- Auto-load environment variables with direnv
- Switch project-specific configurations
- Update shell state when navigating between repos

### FileChanged (2.1.83)

Fires when files change on disk. Enables hot-reload patterns:

```json
{
  "hooks": {
    "FileChanged": [{
      "type": "command",
      "command": "echo 'File changed: $CLAUDE_FILE_PATH'"
    }]
  }
}
```

---

## Background Agent Stability Fix (2.1.83)

**Before**: Background agents became invisible after context compaction, causing duplicate spawns and orphaned work.

**After**: Background agents now survive compaction correctly. Their status is preserved and they report completion as expected.

**Impact**: Safe to use `run_in_background: true` with Agent tool without worrying about lost agents.

---

## TaskOutput Deprecation (2.1.83)

The `TaskOutput` tool is deprecated. Instead, use the `Read` tool on the task's output file path:

```
# Before (deprecated)
TaskOutput(taskId: "abc123")

# After (recommended)
Read(file_path: "/path/from/task/output")
```

The task's output file path is returned when the task completes.

---

## MEMORY.md Auto-Cap (2.1.83)

Auto-memory files (`MEMORY.md`) are now automatically capped at:
- **25KB** file size
- **200 lines** maximum

Lines beyond 200 are truncated. This prevents memory bloat from degrading context quality.

**Best practice**: Keep memory entries concise. One line per entry in the index. Store detail in separate files referenced by the index.

---

## Transcript Search (2.1.83)

Navigate conversation history with built-in search:

1. Press **Ctrl+O** to enter transcript mode
2. Press **/** to start searching
3. Type your search pattern
4. Press **n** to jump to next match, **N** for previous
5. Press **Escape** to exit search

---

## UI Recovery: Ctrl+L (2.1.83)

Full screen clear and redraw. Use when the terminal UI goes blank or corrupted -- replaces the need to restart the session.

---

## Security & Environment Hardening

### CLAUDE_CODE_SUBPROCESS_ENV_SCRUB (2.1.83)

```bash
export CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1
```

Strips API credentials from all subprocesses (Bash commands, hooks, MCP stdio servers). Prevents accidental credential leakage through subprocess environment inheritance.

### SessionEnd Hook Timeout (2.1.83)

```bash
export CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS=5000
```

Extends the SessionEnd hook timeout from the default 1.5 seconds to 5 seconds. Useful for hooks that need to save state, push metrics, or clean up resources.

---

## Settings & Configuration

### sandbox.failIfUnavailable (2.1.83)

```json
{
  "sandbox": {
    "failIfUnavailable": true
  }
}
```

Exit with error when the sandbox can't start, instead of silently running unsandboxed. Recommended for CI/CD environments where sandboxing is a security requirement.

### managed-settings.d/ (2.1.83)

Drop-in directory for modular policy fragments. Files are merged alphabetically, enabling:
- Team-wide base settings
- Project-specific overrides
- Per-developer customizations

```
.claude/
  managed-settings.d/
    00-team-base.json
    10-project-overrides.json
    20-personal.json
```

### disableDeepLinkRegistration (2.1.83)

Prevents `claude-cli://` protocol handler registration. Useful in headless or CI environments.

---

## Agent Improvements

### initialPrompt Frontmatter (2.1.83)

Agents can declare an initial prompt in their frontmatter to auto-submit the first turn:

```yaml
---
description: Run daily health checks
initialPrompt: "Run the health check suite and report results"
---
```

This enables fully autonomous agent workflows triggered by hooks or cron jobs.

### Worktree Name Fix (2.1.83)

Worktree names containing forward slashes (`/`) caused hangs in previous versions. This is now fixed -- but avoid slashes in worktree names for backward compatibility.

---

## Environment Variables Reference

| Variable | Purpose | Default |
|----------|---------|---------|
| `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS` | SessionEnd hook timeout | 1500ms |
| `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` | Strip credentials from subprocesses | off |
| `CLAUDE_CODE_DISABLE_NONSTREAMING_FALLBACK` | Disable non-streaming fallback | off |

---

## Migration Notes

1. **Replace TaskOutput calls**: Search for `TaskOutput` usage and switch to `Read` on the task output path
2. **Review MEMORY.md size**: If over 200 lines, consolidate entries before the auto-cap truncates them
3. **Consider env scrub**: Add `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1` to `.bashrc` for security
4. **Update SessionEnd hooks**: If hooks need >1.5s, set the timeout environment variable

---

*Previous: [Chapter 59 — Community Repo Research Patterns](59-community-repo-research-patterns)*
*Next: [Chapter 61 — Stack Audit & Maintenance Patterns](61-stack-audit-maintenance)*
