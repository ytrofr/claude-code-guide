---
layout: default
title: "Claude Code 2.1.89-2.1.92 — New Features & Improvements"
parent: Guide
nav_order: 70
---

# Claude Code 2.1.89-2.1.92 — New Features & Improvements

*Released: March-April 2026*

## Overview

Claude Code 2.1.89-2.1.92 delivers autocompact safety guards, interactive learning via `/powerup`, per-model cost breakdowns, MCP result size overrides, Edit tool optimizations, Linux sandbox improvements, and multiple new settings for enterprise policy control. These releases focus on resilience, observability, and developer experience.

---

## Autocompact Thrash Guard (2.1.89) -- HIGH IMPACT

Detects when context refills immediately after compacting 3 times in a row. Instead of burning API calls in an infinite compact-refill loop, Claude Code **stops with an actionable error**.

### The Problem

In sessions with very large context (many files read, heavy tool use), compaction would free space, but the next turn would immediately refill it. This could loop indefinitely, consuming API quota with no progress.

### How it Works

After 3 consecutive compact-refill cycles, Claude Code halts and suggests:
- Starting a fresh session (`/clear`)
- Reducing context load (fewer files, smaller scope)
- Using subagents to offload work

### When You'll See It

- Long sessions with heavy parallel tool use
- Sessions that read many large files without subagent delegation
- Workloads that exceed the effective context budget after compaction

---

## Hook Output Disk Cap (2.1.89)

Hook stdout/stderr over **50K characters** is now saved to disk instead of injected into context.

### Before

Large hook outputs (verbose linters, test runners, build logs) were injected directly into the conversation context, silently consuming thousands of tokens.

### After

```
Hook output saved to: /home/user/.claude/hook-output-abc123.txt
Preview (first 2KB):
[first 2KB of output shown inline]
```

The full output is accessible via `Read` tool. Only a file path and preview appear in context.

### Impact

- **Context savings**: Prevents hooks from consuming disproportionate context
- **No behavior change**: Hook scripts run identically -- only the output handling differs
- **Threshold**: 50K characters (approximately 12,500 tokens)

---

## Edit Tool Reads sed/cat Files (2.1.89)

The Edit tool now works on files previously viewed via Bash commands (`cat`, `sed`, `head`, `tail`) **without requiring a separate Read call first**.

### Before

```
# This would fail:
Bash: cat src/index.ts
Edit: src/index.ts  # Error: must Read file first
```

### After

```
# This now works:
Bash: cat src/index.ts
Edit: src/index.ts  # Succeeds -- Edit recognizes the Bash view
```

This removes a common friction point when switching between Bash exploration and file editing.

---

## Hook `defer` Permission (2.1.89)

PreToolUse hooks can now return `"defer"` to **pause execution in headless `-p` sessions**. The session saves state and can be resumed later with `-p --resume`.

### Use Case

Headless CI/scripted sessions that need human approval for certain actions:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "check-if-destructive.sh",
            "if": "Bash(rm *)"
          }
        ]
      }
    ]
  }
}
```

The hook script outputs `{"defer": true}` to pause. Resume with:

```bash
claude -p --resume <session-id>
```

The model re-evaluates the deferred tool call on resume.

---

## `/powerup` Interactive Lessons (2.1.90)

A new command that teaches Claude Code features through **interactive lessons with animated demos**.

```
/powerup
```

Displays a menu of feature tutorials covering hooks, skills, agents, context management, and more. Each lesson includes animated terminal demos showing the feature in action.

### Best For

- New Claude Code users learning the tool
- Discovering features you haven't tried yet
- Quick refreshers on advanced capabilities

---

## Auto Mode Boundary Respect (2.1.90)

Auto mode now respects explicit user boundaries like **"don't push"**, **"wait for X"**, and **"only edit these files"**.

### Before

Auto mode would sometimes push commits, modify out-of-scope files, or proceed past explicit stop points when the classifier allowed the action.

### After

Natural language boundaries in the conversation are treated as constraints. If you say "fix the tests but don't commit," auto mode will not attempt `git commit` even if the classifier would normally allow it.

---

## Format-on-Save Hook Fix (2.1.90)

Fixed Edit and Write tools **failing when a PostToolUse hook reformats the file**.

### The Problem

Setups with format-on-save hooks (Prettier, Black, rustfmt) that run as PostToolUse handlers could cause the next Edit to fail. The formatter changed the file content between the Write and the verification step, causing a mismatch.

### Resolution

Edit/Write now account for PostToolUse modifications during verification. No changes needed to hook configuration.

---

## `--resume` Prompt Cache Fix (2.1.90)

Fixed a **full prompt-cache miss on the first request** after resuming a session with `--resume`.

### Impact

Previously, resuming a session caused the entire system prompt to be re-cached on the first turn, adding latency and cost. Now the prompt cache is restored correctly on resume.

---

## MCP `_meta` Result Size Override (2.1.91)

MCP tool results can now be up to **500K characters** (up from the default limit) via the `_meta` field.

### Configuration

MCP servers can specify in their tool result:

```json
{
  "_meta": {
    "anthropic/maxResultSizeChars": 500000
  }
}
```

### Use Case

MCP servers that return large payloads (documentation fetchers, code search results, database dumps) can now return full results without truncation. The server controls the limit per-result, not globally.

---

## Edit Tool Shorter Anchors (2.1.91)

The Edit tool now uses **shorter context anchors** in its output diffs, reducing output tokens.

### Impact

- **Token savings**: Fewer output tokens per Edit call
- **Faster edits**: Less data transmitted for each file modification
- **No behavior change**: Edit accuracy and matching are unchanged

This is an automatic optimization -- no configuration needed.

---

## Plugin `bin/` Executables (2.1.91)

Plugins can now **ship and invoke executables** from a `bin/` directory within the plugin package.

### What This Enables

- Plugins that include compiled tools (linters, formatters, analyzers)
- Binary dependencies bundled with the plugin instead of requiring separate installation
- Cross-platform executable distribution through the plugin marketplace

### For Plugin Users

No action needed. If a plugin includes executables, they're available automatically when the plugin is enabled.

---

## `disableSkillShellExecution` Setting (2.1.91)

A new setting that **disables inline shell execution in skills, commands, and plugins**.

```json
{
  "disableSkillShellExecution": true
}
```

### Use Case

Enterprise environments that want skills to provide guidance and templates but not execute arbitrary shell commands. When enabled, skills can still be invoked and return instructions, but any inline `Bash` calls within skill execution are blocked.

---

## `/cost` Per-Model Breakdown (2.1.92)

The `/cost` command now shows **per-model and cache-hit breakdowns** for subscription users.

### Output

```
Session costs:
  claude-opus-4-6:    $2.14  (82% cache hit)
  claude-sonnet-4-6:  $0.31  (91% cache hit)
  claude-haiku-4-5:   $0.02  (95% cache hit)
  Total:              $2.47
```

### What's New

- **Per-model attribution**: See which model consumes most of your budget
- **Cache hit rate**: Understand how effectively prompts are being cached
- **Subscription users**: Available on Pro, Max, Team, and Enterprise plans

---

## `/release-notes` Interactive Picker (2.1.92)

The `/release-notes` command now presents an **interactive version picker** instead of showing the latest release notes directly.

Select any recent version to view its changelog. Useful for reviewing what changed across multiple updates.

---

## Linux Sandbox Seccomp (2.1.92)

An `apply-seccomp` helper now ships in both **npm and native builds** for Linux.

### What This Means

- Linux sandbox uses seccomp-BPF for syscall filtering (same approach as Chromium)
- Ships as a pre-built binary -- no compilation needed
- Works in WSL2 environments with bubblewrap installed

### For WSL2 Users

If you have bubblewrap (`bwrap`) and socat installed, the sandbox now uses the bundled seccomp helper automatically.

---

## Removed Commands (2.1.92)

### `/tag` -- Removed

The `/tag` command has been removed entirely.

### `/vim` -- Removed

The `/vim` command has been removed. Editor mode selection is now available through `/config`.

---

## New Settings (2.1.89-2.1.92)

| Setting | Version | Purpose |
|---------|---------|---------|
| `sandbox.failIfUnavailable` | 2.1.89 | Exit with error when sandbox can't start (instead of running unsandboxed) |
| `managed-settings.d/` | 2.1.89 | Drop-in directory for modular policy fragments (merged alphabetically) |
| `disableDeepLinkRegistration` | 2.1.89 | Prevent `claude-cli://` protocol handler registration |
| `showThinkingSummaries` | 2.1.89 | Thinking summaries OFF by default; set `true` to restore |
| `disableSkillShellExecution` | 2.1.91 | Block inline shell execution in skills/commands/plugins |
| `forceRemoteSettingsRefresh` | 2.1.92 | Block startup until remote managed settings are fetched; fail-closed |
| `cleanupPeriodDays` | 2.1.92 | Must be >0; value 0 now rejected with validation error |

---

## New Environment Variables (2.1.89-2.1.92)

| Variable | Version | Purpose |
|----------|---------|---------|
| `MCP_CONNECTION_NONBLOCKING=true` | 2.1.89 | Skip MCP connection wait in headless `-p` mode |
| `CLAUDE_CODE_PLUGIN_KEEP_MARKETPLACE_ON_FAILURE` | 2.1.90 | Keep marketplace cache when git pull fails (offline environments) |

---

## Migration Checklist

1. **Review autocompact behavior** -- if you were hitting infinite compact loops, they now halt with guidance (2.1.89)
2. **Check hook output sizes** -- hooks producing >50K chars now save to disk; scripts that parse hook context output should handle the file path format (2.1.89)
3. **Try `/powerup`** -- discover features you may have missed (2.1.90)
4. **Check `/cost`** -- see per-model breakdown and cache hit rates (2.1.92)
5. **Update `/vim` references** -- now `/config` for editor mode (2.1.92)
6. **Enterprise: evaluate new settings** -- `sandbox.failIfUnavailable`, `managed-settings.d/`, `forceRemoteSettingsRefresh`, `disableSkillShellExecution` provide granular policy control
7. **MCP server authors**: use `_meta.anthropic/maxResultSizeChars` for large results (2.1.91)
8. **No action needed** for: Edit shorter anchors, format-on-save fix, `--resume` cache fix, Linux seccomp (all automatic)

---

*Previous: [Chapter 69 -- Knowledge Harvest Adoption](69-knowledge-harvest-adoption)*

*Updated: 2026-04-05*
