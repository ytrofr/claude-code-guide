---
layout: default
title: "Claude Code 2.1.95-2.1.97 — New Features & Improvements"
description: "Focus view toggle, statusline enhancements, Accept Edits auto-approve, live agent indicators, and multiple stability fixes."
parent: Guide
nav_order: 72
---

# Claude Code 2.1.95-2.1.97 — New Features & Improvements

These releases (April 8, 2026) introduced focus view, statusline enhancements, and significant stability fixes for NO_FLICKER mode.

---

## Focus View Toggle (Ctrl+O)

**Version**: 2.1.97

In `CLAUDE_CODE_NO_FLICKER=1` mode, pressing **Ctrl+O** toggles focus view — a clean presentation showing:
1. Your prompt
2. One-line tool summary with edit diffstats
3. Claude's final response

This is ideal for reviewing work without scrolling through verbose tool call details.

```bash
# Enable NO_FLICKER mode to use focus view
export CLAUDE_CODE_NO_FLICKER=1
# Then in a CC session, press Ctrl+O to toggle
```

---

## Statusline Enhancements

**Version**: 2.1.97-2.1.98

Two new capabilities make dynamic statuslines practical:

### `refreshInterval` Setting

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/scripts/statusline.sh",
    "refreshInterval": 5
  }
}
```

The statusline script re-runs every N seconds, enabling live indicators (context usage, circuit breaker state, build status).

### `workspace.git_worktree` JSON Field

The statusline script receives a JSON object on stdin that now includes `workspace.git_worktree` — the path to the active git worktree. This is especially useful for multi-worktree setups (e.g., 7 LimorAI worktrees) where knowing which worktree you're in is critical.

See [Chapter 75 — Statusline Patterns](75-claude-code-statusline-patterns.md) for example scripts.

---

## Accept Edits Mode: Safe Env-Prefix Auto-Approve

**Version**: 2.1.97

In Accept Edits mode, commands prefixed with known-safe environment variables are now auto-approved:

```bash
LANG=C rm foo          # Auto-approved (LANG is safe)
timeout 5 mkdir out    # Auto-approved (timeout is safe wrapper)
NO_COLOR=1 npm test    # Auto-approved (NO_COLOR is safe)
```

This reduces unnecessary permission prompts for commands that simply set locale, timing, or display variables.

---

## Live Agent Indicators

**Version**: 2.1.97

The `/agents` view now shows `● N running` next to agent types that have live subagent instances. This provides at-a-glance visibility into what's executing without opening each agent's output.

---

## NO_FLICKER Mode Fixes

Multiple stability improvements for `CLAUDE_CODE_NO_FLICKER=1`:

- Fixed copying wrapped URLs inserting spaces at line breaks
- Fixed crash when hovering over MCP tool results
- Fixed scroll rendering artifacts in zellij
- Fixed slow mouse-wheel scrolling on Windows Terminal
- Fixed custom statusline not displaying on terminals shorter than 24 rows
- Fixed Shift+Enter and Alt/Cmd+arrow shortcuts in Warp
- Fixed Korean/Japanese/Unicode text garbled when copied on Windows
- Fixed memory leak where API retries left stale streaming state

---

## Other Notable Fixes

- Fixed MCP HTTP/SSE connections accumulating ~50 MB/hr of unreleased buffers on reconnect
- Fixed MCP OAuth `authServerMetadataUrl` not honored on token refresh (affecting ADFS)
- Fixed 429 retries burning all attempts in ~13s — exponential backoff now applies as minimum
- Fixed file-edit diffs disappearing on `--resume` when the edited file was larger than 10KB
- Fixed several `/resume` picker issues: stale cross-project entries, search state wiped on reload
- Fixed subagents with worktree isolation leaking their cwd back to the parent session

---

*See also: [Chapter 71 — 2.1.93-2.1.94 Features](71-claude-code-2193-2194-features.md) | [Chapter 73 — 2.1.98-2.1.99 Features](73-claude-code-2198-2199-features.md)*
