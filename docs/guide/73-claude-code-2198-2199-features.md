---
layout: default
title: "Claude Code 2.1.98-2.1.99 — New Features & Security Hardening"
description: "Monitor tool, settings resilience, 6 Bash permission bypass fixes, subagent MCP inheritance, worktree Read/Edit fix, PID namespace sandbox, OTEL tracing, and more."
parent: Guide
nav_order: 73
---

# Claude Code 2.1.98-2.1.99 — New Features & Security Hardening

These releases (April 9-11, 2026) are the most security-significant since 2.1.89. They include a new tool primitive (Monitor), major permission hardening, and critical subagent fixes.

---

## Monitor Tool

**Version**: 2.1.98

A new tool for streaming events from background scripts. Each stdout line from the monitored process becomes a notification event.

**When to use**: Long-running builds, deploy scripts, fetch operations — anywhere you'd otherwise poll with `Read` or sleep-loop.

**When NOT to use**: One-shot short commands (use Bash directly), file watching (Monitor reads stdout, not files), or time-delayed polling (use ScheduleWakeup).

See [Chapter 74 — Monitor Tool](74-claude-code-monitor-tool.md) for patterns and a decision matrix.

---

## Settings Resilience

**Version**: 2.1.99

Previously, an unrecognized hook event name in `settings.json` caused the **entire file to be ignored**. Now only the bad entry is skipped — all other hooks, permissions, and settings continue to work.

**Impact**: If you had a typo in a hook event name (e.g., `"PreTooluse"` instead of `"PreToolUse"`), all your hooks were silently dead. After 2.1.99, only that one bad handler is skipped.

**Action**: Audit your hooks after upgrading. Hooks that were silently dead for months may now start firing.

---

## Bash Permission Hardening (6 Bypass Fixes)

**Version**: 2.1.98-2.1.99

Six separate bypass vectors in the Bash tool permission system were closed:

| # | Bypass | Example | Fix |
|---|--------|---------|-----|
| 1 | **Compound commands** | `echo x && killall node` | Forced prompts now apply to compound commands in auto/bypass modes |
| 2 | **Backslash-escaped flags** | `killall\ node` | No longer auto-allowed as read-only |
| 3 | **`/dev/tcp` redirects** | `cmd > /dev/tcp/host/port` | Now prompts instead of auto-allowing |
| 4 | **`/dev/udp` redirects** | `cmd > /dev/udp/host/port` | Same treatment as `/dev/tcp` |
| 5 | **Env-var prefix** | `LANG=C killall node` | Now prompts unless the var is known-safe (LANG, TZ, NO_COLOR, etc.) |
| 6 | **Whitespace matching** | `killall  node` (double space) | `Bash(cmd:*)` and `Bash(git commit *)` wildcards now match extra spaces/tabs |

### `permissions.deny` Precedence Fix

**Version**: 2.1.99

`permissions.deny` rules now correctly override a PreToolUse hook's `permissionDecision: "ask"`. Previously, a hook could downgrade a deny into a prompt — the deny now takes precedence.

---

## Subagent MCP Tool Inheritance

**Version**: 2.1.99

Subagents now inherit MCP tools from dynamically-injected servers. Previously, if an MCP server was added after session start (via `claude mcp add` or dynamic injection), subagents spawned via Task wouldn't see its tools.

---

## Subagent Worktree Read/Edit Fix

**Version**: 2.1.99

Sub-agents running in isolated worktrees were previously denied Read/Edit access to files **inside their own worktree**. This is now fixed — subagents can freely access files within the worktree they're operating in.

**Impact**: If you use `--worktree` for parallel agent work or have multi-worktree setups (like 7 LimorAI worktrees), subagent delegation now works correctly.

---

## Subprocess Sandboxing

**Version**: 2.1.98

### PID Namespace Isolation

When `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1` is set (recommended), subprocesses on Linux now run in a PID namespace. They can no longer see host PIDs — strengthening process isolation.

### `CLAUDE_CODE_SCRIPT_CAPS`

New environment variable to limit per-session script invocations:

```bash
export CLAUDE_CODE_SCRIPT_CAPS=500  # Max 500 script invocations per session
```

This prevents runaway hook loops or subagent recursion from DoS-ing a session.

---

## OTEL Tracing Enhancements

**Version**: 2.1.98

### TRACEPARENT Auto-Propagation

The Bash tool now automatically injects the W3C `TRACEPARENT` environment variable into subprocesses when OTEL tracing is enabled. Child-process spans correctly parent to Claude Code's trace tree.

### Opt-In Span Attributes

Three new environment variables add detailed data to OTEL spans:

| Env Var | Data |
|---------|------|
| `OTEL_LOG_USER_PROMPTS=1` | Full user message text on turn spans |
| `OTEL_LOG_TOOL_DETAILS=1` | Tool input parameters on tool spans |
| `OTEL_LOG_TOOL_CONTENT=1` | Tool result content on tool spans |

**Privacy note**: These are opt-in and should only be enabled during specific debugging sessions, never in shared configuration.

---

## `/agents` Tabbed Layout

**Version**: 2.1.98

The `/agents` view now has two tabs:
- **Running** — Shows live subagent instances with their status
- **Library** — Lists available agent types with "Run agent" and "View running instance" actions

---

## `/team-onboarding` Command

**Version**: 2.1.99

Generates a teammate ramp-up guide from your local Claude Code usage patterns. Useful for onboarding new team members who will use Claude Code on the same codebase.

---

## OS CA Certificate Trust

**Version**: 2.1.99

Claude Code now trusts the OS certificate store by default, so enterprise TLS proxies work without extra setup. Set `CLAUDE_CODE_CERT_STORE=bundled` to use only bundled CAs if needed.

---

## Other Notable Changes

- **`--resume <name>`** now accepts session titles set via `/rename` or `--name` (2.1.99)
- **`--exclude-dynamic-system-prompt-sections`** flag for print mode enables cross-user prompt caching (2.1.98)
- **Plugin hooks** from plugins force-enabled by managed settings now run when `allowManagedHooksOnly` is set (2.1.99)
- Fixed `--dangerously-skip-permissions` being silently downgraded to accept-edits mode (2.1.99)
- Fixed `permissions.additionalDirectories` changes not applying mid-session (2.1.99)
- Fixed stale subagent worktree cleanup removing worktrees with untracked files (2.1.99)
- Fixed `claude -w <name>` failing after stale worktree directory left behind (2.1.99)
- Fixed command injection vulnerability in POSIX `which` fallback (2.1.99)
- Fixed memory leak where long sessions retained historical message copies in virtual scroller (2.1.99)

---

*See also: [Chapter 71 — 2.1.93-2.1.94 Features](71-claude-code-2193-2194-features.md) | [Chapter 72 — 2.1.95-2.1.97 Features](72-claude-code-2195-2197-features.md)*
