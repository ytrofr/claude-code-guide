---
layout: default
title: "Claude Code 2.1.84-2.1.86 — New Features & Improvements"
parent: Guide
nav_order: 64
---

# Claude Code 2.1.84-2.1.86 — New Features & Improvements

*Released: March 2026*

## Overview

Claude Code 2.1.84-2.1.86 brings conditional hook execution, skill description caps, automatic token savings on file reads, YAML list support for path-scoped rules, system-prompt caching with ToolSearch, code intelligence plugins, and multiple stability fixes. These releases focus on context efficiency and hook precision.

---

## Conditional `if` Field for Hooks (2.1.85)

The most impactful addition for hook-heavy setups. The `if` field uses **permission rule syntax** to filter when individual hook handlers run, preventing unnecessary process spawning.

### How it Works

The `if` field is evaluated **before** the hook spawns. If the pattern doesn't match, the hook process is never created -- zero overhead.

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/observation.sh",
            "async": true,
            "if": "Bash(git *)"
          }
        ]
      }
    ]
  }
}
```

This hook only spawns `observation.sh` for git commands. All other Bash calls (`ls`, `cat`, `grep`, `curl`) are filtered out before spawning.

### Syntax

The `if` field uses the same syntax as permission rules:

| Pattern | Matches |
|---------|---------|
| `Bash(git *)` | Any git command |
| `Edit(*.ts)` | TypeScript file edits |
| `Write(src/**)` | Writes under src/ |
| `Bash(npm test*)` | npm test commands |

### Where `if` is Supported

Only on **tool event** hooks:
- `PreToolUse`
- `PostToolUse`
- `PostToolUseFailure`
- `PermissionRequest`

On other event types (`SessionStart`, `Stop`, etc.), the `if` field is ignored.

### Two-Level Filtering

`matcher` and `if` work together:
1. **`matcher`** filters by tool name (e.g., `Bash`, `Edit|Write`)
2. **`if`** filters by tool name + arguments (e.g., `Bash(git *)`, `Edit(*.ts)`)

This enables precise targeting without internal script filtering.

### Real-World Example: Observation Hook

**Before** (spawns on every Bash call, script filters internally):
```json
{
  "matcher": "Write|Edit|Bash",
  "hooks": [{ "command": "observation.sh", "async": true }]
}
```

**After** (two matchers, `if` prevents wasted spawns):
```json
{
  "matcher": "Write|Edit",
  "hooks": [{ "command": "observation.sh", "async": true }]
},
{
  "matcher": "Bash",
  "hooks": [{ "command": "observation.sh", "async": true, "if": "Bash(git *)" }]
}
```

**Impact**: Eliminates ~90% of wasted process spawns in a typical session (50-100 `ls`/`cat`/`grep` calls that previously triggered the hook only to exit immediately).

---

## Skill Description Cap: 250 Characters (2.1.86)

Skill descriptions in the `/skills` listing are now capped at **250 characters**. Descriptions longer than 250 chars are silently truncated, which can cut off trigger phrases that help Claude decide when to use the skill.

### Why This Matters

Skill descriptions serve two purposes:
1. **Matching**: Claude reads descriptions to decide which skills are relevant
2. **Context budget**: All descriptions consume context (~2% of window, ~20K chars for 1M)

Truncation can remove critical "Use when..." trigger phrases, reducing skill activation accuracy.

### How to Check Your Skills

```bash
for d in ~/.claude/skills/*/; do
  f="$d/SKILL.md"
  [ -f "$f" ] || continue
  desc=$(sed -n 's/^description: *//p' "$f" | head -1)
  desc="${desc#\"}"
  desc="${desc%\"}"
  len=${#desc}
  [ "$len" -gt 250 ] && echo "OVER ($len): $(basename "$d")"
done
```

### Trimming Strategy

When trimming, preserve trigger keywords and cut filler:

| Cut This | Keep This |
|----------|-----------|
| "following Anthropic best practices for" | "with" |
| "to appropriate X based on Y category" | "X by Y type" |
| "Verified: 2025-12-14." | (remove -- non-functional) |
| "and Core Web Vitals standards for frontend UI work" | "Core Web Vitals for frontend UI" |

**Rule**: Every word in a 250-char description must earn its place. Attribution, dates, and filler phrases are first to go. "Use when" trigger phrases are last.

### Budget Monitoring

The skill description budget is **2% of your context window** (~20K chars for 1M). Run `/context` to check usage. At 44 skills averaging 180 chars each, you're at ~38% -- healthy headroom.

---

## Read Tool Compact Format (2.1.86)

The Read tool now uses a **compact line-number format** and **deduplicates unchanged re-reads**, automatically reducing token usage.

- **Before**: Each re-read of the same unchanged file consumed full tokens
- **After**: Duplicate reads return a compact reference, saving tokens

No configuration needed -- this is automatic. Long sessions with heavy file reading benefit most.

---

## `@`-Mention Token Reduction (2.1.86)

Raw string content when mentioning files with `@` is **no longer JSON-escaped**. This reduces token overhead for `@file` references, especially for files with special characters.

---

## Rules & Skills `paths:` Now Accept YAML Lists (2.1.84)

The `paths:` frontmatter field now accepts a **YAML list of globs** in addition to comma-separated strings. This is the recommended format:

```yaml
---
paths:
  - "**/*.sh"
  - "**/hooks/*"
---
```

### Why Use `paths:` on Rules

Domain-specific rules loaded globally waste context when working on unrelated files. Adding `paths:` makes the rule load only when Claude is working with matching files.

**Example**: A bash filename iteration rule has no relevance when editing TypeScript:

```yaml
---
paths:
  - "**/*.sh"
---

# Bash Filename Iteration — Use Arrays, Not Glob Expansion
...
```

### Recommended `paths:` Patterns by Rule Type

| Rule Domain | Paths Pattern |
|-------------|---------------|
| Shell/Bash rules | `**/*.sh` |
| Frontend rules | `**/*.{tsx,jsx,ts,js}` |
| Python rules | `**/*.py` |
| Claude Config rules | `**/.claude/**/*.md` |
| CLAUDE.md rules | `**/CLAUDE.md` |
| Test rules | `**/test*/**/*`, `**/*test*.{js,ts,py}` |
| Infrastructure rules | `**/*.env*`, `**/docker-compose*` |
| Build/scripts rules | `**/package.json`, `**/scripts/**/*` |

### Impact

In a setup with 48 rules, adding `paths:` to 10 domain-specific rules saves ~1,443 tokens per session (~481 lines of rules not loaded when irrelevant).

---

## Idle-Return Prompt (2.1.84)

When returning to a session after **75+ minutes idle**, Claude nudges you to `/clear` to reclaim context. Stale sessions waste tokens re-caching old context that's no longer relevant.

**Best practice**: Follow the nudge. A clean session with a focused prompt outperforms a stale session with accumulated irrelevant context.

---

## System-Prompt Caching with ToolSearch (2.1.84)

Global system-prompt caching now works when **ToolSearch is enabled**, including for users with MCP tools configured. Previously, having ToolSearch active broke prompt caching, increasing costs.

Enable ToolSearch in your settings:
```json
{
  "env": {
    "ENABLE_TOOL_SEARCH": "true"
  }
}
```

---

## MCP Tool Description Cap: 2KB (2.1.84)

MCP tool descriptions and server instructions are now capped at **2KB**. This prevents OpenAPI-generated MCP servers from bloating context with massive tool descriptions.

---

## Code Intelligence Plugins (2.1.84+)

Claude Code now includes **12 LSP-based code intelligence plugins** in the marketplace. These provide go-to-definition, find-references, and auto-diagnostics for typed languages.

### Available Plugins

| Plugin | Language | Install |
|--------|----------|---------|
| `typescript-lsp` | TypeScript/JavaScript | `npm install -g typescript-language-server typescript` |
| `pyright-lsp` | Python | `npm install -g pyright` |
| `gopls-lsp` | Go | `go install golang.org/x/tools/gopls@latest` |
| `rust-analyzer-lsp` | Rust | `rustup component add rust-analyzer` |
| `clangd-lsp` | C/C++ | Platform-specific |
| `ruby-lsp` | Ruby | `gem install ruby-lsp` |

### Enabling

After installing the language server globally, enable the plugin:
```json
{
  "enabledPlugins": {
    "typescript-lsp@claude-plugins-official": true
  }
}
```

**No conflicts** with existing plugins. LSP plugins don't install hooks or modify system state.

### Benefits

- **Precise symbol navigation**: Claude can jump to definitions instead of grep-scanning
- **Auto-diagnostics**: Type errors detected immediately after edits
- **Context efficiency**: Type information from LSP is more precise than reading entire files

---

## Verification Hook Pattern

A recommended hook pattern for closing the "trust-then-verify" gap -- where Claude claims success without running verification.

### The Problem

Rules like validation-workflow.md say "verify before claiming done," but nothing enforces it. In production use, this leads to inflated claims (~21 events per 165 sessions in real-world data).

### The Solution: Advisory PreToolUse Hook on TaskUpdate

```bash
#!/bin/bash
# PreToolUse hook: Advisory reminder when marking tasks completed
# Matches: TaskUpdate
# Mode: Advisory (exit 0) -- reminds, doesn't block

JSON_INPUT=$(timeout 2 cat 2>/dev/null || echo '{}')

NEW_STATUS=$(echo "$JSON_INPUT" | jq -r '.tool_input.status // empty' 2>/dev/null)

# Only remind on status change to "completed"
[ "$NEW_STATUS" != "completed" ] && exit 0

echo ""
echo "--- VERIFICATION REMINDER ---"
echo "Before marking complete, confirm you have:"
echo "  - Run the relevant test/curl/check (not just assumed it works)"
echo "  - Verified actual output matches expected output"
echo "  - Checked for side effects or regressions"
echo "-----------------------------"
echo ""

exit 0
```

Register in settings.json:
```json
{
  "matcher": "TaskUpdate",
  "hooks": [{
    "type": "command",
    "command": "~/.claude/hooks/task-verification-gate.sh",
    "statusMessage": "Verification reminder..."
  }]
}
```

**Design choice**: Advisory (`exit 0`) not blocking (`exit 2`). Creates healthy friction without stopping legitimate fast-paced work. Upgrade to blocking later if needed.

This mirrors the proven `plan-sections-gate.sh` pattern (blocks ExitPlanMode if sections are missing).

---

## `/compact` Fix for Very Large Sessions (2.1.85)

Previously, `/compact` could fail with "context exceeded" when the conversation was too large for the compact request itself to fit. Now fixed -- compaction works reliably regardless of session size.

---

## Plugin Permission Fix (2.1.86)

Official marketplace plugin scripts were failing with "Permission denied" on macOS/Linux since v2.1.83. Fixed in 2.1.86. If you enabled plugins between v2.1.83 and v2.1.86, verify they're working with `/plugin list`.

---

## Additional Improvements

### 2.1.84
- **TaskCreated hook**: New hook event that fires when a task is created via TaskCreate
- **Timestamp markers**: Transcripts now show timestamps when `/loop` and `CronCreate` tasks fire
- **Token display**: Counts 1M+ now show as "1.5m" instead of "1512.6k"
- **Startup improvement**: ~30ms faster interactive startup
- **Background bash notification**: Stuck interactive prompts surface a notification after ~45 seconds

### 2.1.85
- **MCP server env vars**: `CLAUDE_CODE_MCP_SERVER_NAME` and `CLAUDE_CODE_MCP_SERVER_URL` available in MCP headers
- **PreToolUse satisfies AskUserQuestion**: Hooks can now return `updatedInput` alongside `permissionDecision: "allow"` for headless integrations
- **Plugins blocked by org policy**: `managed-settings.json` can block plugin installation

### 2.1.86
- **Session-Id header**: `X-Claude-Code-Session-Id` added to API requests for proxy session aggregation
- **VCS exclusions**: `.jj` and `.sl` added to exclusion lists (Jujutsu and Sapling VCS support)
- **Memory filenames clickable**: In "Saved N memories" notices, filenames highlight on hover and open on click
- **`/skills` sorted alphabetically**: Easier scanning in the skills menu
- **Memory growth fix**: Long sessions no longer leak memory from markdown/highlight render caches
- **MCP connector startup**: Reduced event-loop stalls with many claude.ai MCP connectors (macOS keychain cache extended)

---

## Migration Checklist

1. **Check skill descriptions**: Run the bash loop above to find descriptions over 250 chars. Trim to preserve trigger phrases.
2. **Add `paths:` to domain-specific rules**: Rules that apply only to certain file types should have path-scoped frontmatter.
3. **Add `if` to noisy hooks**: Any PostToolUse hook on `Bash` that filters internally should use `if` to prevent wasted spawns.
4. **Consider verification hook**: If you use TaskCreate/TaskUpdate, the advisory verification pattern catches inflated claims.
5. **Install code intelligence**: `typescript-lsp` or `pyright-lsp` if you work in typed languages.
6. **Enable ToolSearch**: If not already enabled, add `ENABLE_TOOL_SEARCH: true` for better prompt caching.
7. **Review `/compact` usage**: No longer fails on very large sessions -- safe to rely on.

---

*Previous: [Chapter 63 -- Plugin Marketplace](63-plugin-marketplace)*

*Updated: 2026-03-28*
