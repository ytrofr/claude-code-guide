---
layout: default
title: "Claude Code 2.1.87-2.1.88 — New Features & Improvements"
parent: Guide
nav_order: 66
---

# Claude Code 2.1.87-2.1.88 — New Features & Improvements

*Released: March 2026*

## Overview

Claude Code 2.1.87-2.1.88 delivers flicker-free alt-screen rendering, a new PermissionDenied hook event, named subagent typeahead, and a large batch of high-impact bug fixes targeting prompt cache efficiency, nested CLAUDE.md re-injection, hook reliability, LSP stability, and memory leaks. Version 2.1.88 is a significant stability release with platform-specific fixes for Windows, macOS, and terminal emulators.

---

## 2.1.87: Cowork Dispatch Fix

Fixed messages in Cowork Dispatch not getting delivered. No configuration changes needed -- this is an automatic fix for users of the Cowork feature.

---

## Flicker-Free Alt-Screen Rendering (2.1.88)

A new environment variable eliminates terminal flickering during parallel tool calls and streaming output.

### How it Works

```bash
export CLAUDE_CODE_NO_FLICKER=1
```

Setting this opts into **alt-screen rendering with virtualized scrollback** -- the same rendering mode used by `vim`, `less`, and `htop`. The terminal switches to an alternate screen buffer where updates are drawn without visible flicker.

### Tradeoff

Alt-screen content **disappears from terminal scrollback on exit**. When you quit Claude Code (or the session ends), the alternate screen buffer is discarded -- you cannot scroll up to see prior output. This is standard alt-screen behavior, identical to exiting `vim` or `less`.

### When to Use

- **WSL2 terminals**: Especially beneficial -- WSL2 terminal rendering is prone to flicker during heavy parallel output
- **Heavy parallel tool use**: Sessions with many concurrent Bash/Read/Grep calls
- **Streaming-heavy sessions**: Long responses with rapid token output

### Adding to Shell Profile

```bash
# ~/.bashrc or ~/.zshrc
export CLAUDE_CODE_NO_FLICKER=1
```

---

## PermissionDenied Hook (2.1.88)

A new hook event that fires **after auto mode classifier denials**. This enables logging, custom retry logic, and observability for permission-denied actions.

### Hook Configuration

```json
{
  "hooks": {
    "PermissionDenied": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "echo \"[PermissionDenied] $(date -Iseconds)\" >> ~/.claude/logs/permission-denials.log",
            "async": true
          }
        ]
      }
    ]
  }
}
```

### Return Values

| Return | Effect |
|--------|--------|
| `{retry: true}` | Tells the model it can retry the denied action |
| No return / empty | Default behavior -- denial logged, no retry |

### Visibility Improvements

Auto mode denied commands now:
- Show a **notification** in the UI when a command is denied
- Appear in `/permissions` under the **Recent** tab

### Use Cases

- **Observability**: Log all denials to a file for post-session review
- **Custom retry logic**: Conditionally allow retries based on command pattern
- **Audit trail**: Track which commands auto mode blocks most frequently

---

## Named Subagents in @ Mention (2.1.88)

Named subagents now appear in **@ mention typeahead suggestions**. When you type `@` in the input, running named agents appear as completion options alongside files and symbols.

This makes it easier to reference and interact with running agents without remembering exact names or switching context.

---

## Nested CLAUDE.md Re-injection Fix (2.1.88) -- HIGH IMPACT

Fixed nested CLAUDE.md files being **re-injected dozens of times** in long sessions that read many files.

### The Problem

In setups with global (`~/.claude/CLAUDE.md`) and per-project (`.claude/CLAUDE.md`) files, each file read could trigger re-injection of nested CLAUDE.md content. Over a long session with many file reads, the same CLAUDE.md content would be injected 20-50+ times, silently consuming context window capacity.

### Impact

- **Context window**: Previously wasted significant context on duplicate CLAUDE.md content
- **Session length**: Sessions hit context limits earlier than expected
- **No symptoms**: No visible error -- just shorter effective sessions

### Resolution

No action needed -- this is an automatic fix. Long sessions with multi-level CLAUDE.md setups will see improved context efficiency immediately.

---

## Prompt Cache Fix (2.1.88) -- HIGH IMPACT

Fixed prompt cache misses in long sessions caused by **tool schema bytes changing mid-session**.

### The Problem

When MCP servers, plugins, or deferred tools update their schema mid-session, the prompt cache key changed, invalidating cached prompts. This forced re-caching of the entire system prompt on every turn.

### Impact

- **API costs**: Higher costs in long sessions due to cache misses
- **Latency**: Each cache miss adds latency as the full prompt is re-sent
- **Especially affected**: Setups with many MCP servers, plugins, and deferred tools

### Resolution

No action needed -- automatic fix. Sessions with complex tool configurations will see reduced API costs.

---

## Hook `if` Compound Command Fix (2.1.88)

Fixed hooks `if` condition filtering **not matching compound commands** or commands with environment variable prefixes.

### What Changed

| Command | Before (2.1.85-2.1.87) | After (2.1.88) |
|---------|------------------------|-----------------|
| `ls && git push` | `if: "Bash(git *)"` did NOT match | Matches correctly |
| `FOO=bar git push` | `if: "Bash(git *)"` did NOT match | Matches correctly |
| `npm test && git commit` | `if: "Bash(git *)"` did NOT match | Matches correctly |

### Behavior Change

Hooks with `if` conditions may now fire **more frequently** than before. This is correct behavior -- the previous implementation was silently skipping legitimate matches. Review your hook scripts if they assume a lower invocation rate.

---

## PreToolUse/PostToolUse Absolute `file_path` (2.1.88)

Fixed PreToolUse/PostToolUse hooks **not providing `file_path` as an absolute path** for Write, Edit, and Read tools.

### Before

Hook scripts received `file_path` from `tool_input` JSON as a relative path (e.g., `src/index.ts`), requiring manual resolution.

### After

`file_path` is always an absolute path (e.g., `/home/user/project/src/index.ts`). Hook scripts that parse `file_path` from the tool input JSON now work correctly without path resolution logic.

---

## LSP Server Auto-Restart (2.1.88)

Fixed LSP server **zombie state after crash**. Previously, if a language server (e.g., `typescript-lsp`, `pyright-lsp`) crashed mid-session, it remained in a dead state until the entire Claude Code session was restarted.

Now the LSP server **restarts automatically on the next request**. This benefits all code intelligence plugins.

---

## Memory Leak Fix (2.1.88)

Fixed memory leak where **large JSON inputs were retained as LRU cache keys** in long-running sessions.

### Who Was Affected

Sessions with heavy hook usage that passes JSON via stdin. The JSON payloads (which can be large for tools like Edit with full file content) were kept as cache keys indefinitely, growing memory usage over time.

### Resolution

Automatic fix. Long-running sessions with many hook invocations will maintain stable memory usage.

---

## Additional Bug Fixes (2.1.88)

### Stability Fixes

- **StructuredOutput schema cache bug**: Fixed ~50% failure rate in workflows with multiple schemas
- **Edit tool OOM**: Fixed potential out-of-memory crash when Edit tool was used on very large files (>1 GiB)
- **Large session file crash**: Fixed crash when removing a message from very large session files (over 50MB)
- **`--resume` crash**: Fixed crash when transcript contains a tool result from an older CLI version or interrupted write
- **Rate limit message**: Fixed misleading "Rate limit reached" message -- now shows actual entitlement error with actionable hints

### Data Integrity Fixes

- **CJK/emoji prompt history**: Fixed prompt history entries containing CJK or emoji being silently dropped at 4KB boundary
- **`/stats` historical data**: Fixed `/stats` losing historical data beyond 30 days when cache format changes
- **`/stats` token counting**: Fixed `/stats` undercounting tokens by excluding subagent/fork usage
- **Devanagari text**: Fixed Devanagari and other combining-mark text being truncated

### UI Fixes

- **Scrollback disappearing**: Fixed scrollback disappearing when scrolling up in long sessions
- **Badge duplication**: Fixed collapsed search/read group badges duplicating during heavy parallel tool use
- **Task notifications**: Fixed task notifications being lost when backgrounding with Ctrl+B
- **Rendering artifacts**: Fixed rendering artifacts on main-screen terminals after layout shifts

---

## Platform-Specific Fixes (2.1.88)

### Windows

- **CRLF doubling**: Fixed Edit/Write tools doubling CRLF on Windows and stripping Markdown hard line breaks
- **Shift+Enter**: Fixed Shift+Enter submitting instead of inserting newline on Windows Terminal Preview 1.25
- **PowerShell**: Fixed stderr false failures and improved version-appropriate syntax guidance
- **Voice mode**: Fixed Windows WebSocket issues in voice mode

### macOS

- **Voice mode**: Fixed microphone permission handling and push-to-talk bindings

### Terminal Emulators

- **iTerm2/tmux**: Fixed periodic UI jitter during streaming

---

## UI/UX Improvements (2.1.88)

### Thinking Summaries Default Off

Thinking summaries are **no longer generated by default**. To restore them:

```json
{
  "showThinkingSummaries": true
}
```

This reduces token usage for users who don't need inline reasoning summaries.

### Other UI Changes

- **`/env` for PowerShell**: `/env` now applies to PowerShell tool commands
- **`/usage` cleanup**: Hides redundant "Current week (Sonnet only)" bar for Pro/Enterprise users
- **Collapsed tool summary**: Shows "Listed N directories" for `ls`/`tree`/`du` commands
- **Image paste**: No longer inserts trailing space after pasting an image
- **`!command` paste**: Pasting `!command` enters bash mode, matching typed `!` behavior

---

## Computer Use (2.1.85+ -- macOS Only)

Claude Code gained built-in computer use via a `computer-use` MCP server. This provides screenshot-based desktop control -- opening apps, clicking buttons, and typing text.

### Requirements

- **macOS only** -- not available on Linux, Windows, or WSL
- **Pro and Max subscribers** only (not Team/Enterprise)
- **Permissions**: Requires Accessibility + Screen Recording in macOS System Settings

### Capabilities and Limitations

| Action | Via Computer Use |
|--------|-----------------|
| Open applications | Yes |
| Click UI buttons | Yes |
| Type text into fields | Yes |
| Browser interaction | View-only (no clicking links/buttons) |
| Terminal interaction | Click-only (no typing commands) |

### Fallback Priority

Computer use is the **last resort** in the tool selection hierarchy:

```
MCP Tools > Bash > Chrome/Playwright > Computer Use
```

Claude falls back to computer use only when no better tool exists for the task.

---

## Migration Checklist

1. **Add `CLAUDE_CODE_NO_FLICKER=1`** to your shell profile if terminal flickering is an issue (especially WSL2)
2. **Add `PermissionDenied` hook** if you use auto mode -- log denials for observability
3. **Check `showThinkingSummaries`** -- now OFF by default. Set `true` in settings if you want them back
4. **Verify hook behavior** -- `if` conditions now match compound commands, increasing hook invocations (this is correct behavior)
5. **Review `/stats`** -- now includes subagent/fork usage, historical data preserved across format changes
6. **No action needed** for: nested CLAUDE.md fix, prompt cache fix, LSP auto-restart, memory leak fix (all automatic)

---

*Previous: [Chapter 65 -- Cross-Project AI Knowledge Sharing](65-cross-project-ai-knowledge-sharing)*
*Next: [Chapter 67 -- Claude Code Internal Architecture](67-cc-source-architecture)*

*Updated: 2026-03-31*
