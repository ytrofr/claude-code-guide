---
layout: default
title: "Claude Code 2.1.77-2.1.81 — Bare Mode, Channels, StopFailure Hook, Plugin Ecosystem & Performance"
description: "Key features from Claude Code releases 2.1.77 through 2.1.81 (March 15-21, 2026): --bare flag for scripting, --channels permission relay, StopFailure hook, plugin persistent state, effort frontmatter, 64k default output for Opus 4.6, /branch command, and significant performance improvements."
---

# Chapter 57: Claude Code 2.1.77-2.1.81 New Features

Five releases over one week (March 15-21, 2026) brought scripting improvements, a new hook event, plugin ecosystem maturation, and continued performance gains. This chapter covers each version with practical details.

---

## Version 2.1.81

### --bare Flag for Scripted Calls

The `--bare` flag strips Claude Code down to its essentials for scripted `-p` (prompt) calls. It skips hooks, LSP initialization, plugin sync, and skill directory walks -- everything that adds latency but provides no value in non-interactive pipelines.

```bash
# Fast scripted call — no hooks, no plugins, no skill walks
claude -p "Summarize this file" --bare < input.txt
```

**Requirements and constraints**:

- Requires `ANTHROPIC_API_KEY` environment variable (no OAuth)
- Auto-memory is disabled (no reads or writes to CLAUDE.md)
- Hooks do not fire (PreToolUse, PostToolUse, SessionEnd -- all skipped)
- Plugin sync is skipped entirely

**When to use**: CI pipelines, shell scripts, batch processing, any non-interactive automation where startup speed matters more than IDE integration.

### --channels Permission Relay

MCP servers can now forward tool approval prompts to your phone via the `--channels` flag. When Claude needs permission to run a tool and you are away from your terminal, the approval request routes to a mobile notification channel.

```bash
claude --channels
```

This feature graduated from research preview (introduced in 2.1.80) to general availability.

### Concurrent Session OAuth Fix

Fixed an issue where multiple concurrent Claude Code sessions would trigger redundant OAuth re-authentication flows. Sessions now share authentication state correctly.

### Voice Mode Fixes

- Retry logic for voice transcription failures
- WebSocket connection recovery after network interruptions

### MCP Tool Call Collapse

MCP tool calls now collapse into a single "Queried {server}" line in the conversation display instead of showing each individual tool invocation. This reduces visual noise when MCP servers make multiple internal calls.

### Windows/WSL Streaming

Line-by-line response streaming is disabled on Windows and WSL due to terminal rendering issues. Responses appear in blocks instead. This is a temporary measure while terminal compatibility is investigated.

---

## Version 2.1.80

### rate_limits in Statusline Scripts

Statusline scripts now receive a `rate_limits` field containing usage data for the 5-hour and 7-day billing windows. This lets custom statusline displays show remaining capacity.

```json
{
  "rate_limits": {
    "5h": { "used": 42, "limit": 100 },
    "7d": { "used": 310, "limit": 1000 }
  }
}
```

### effort Frontmatter for Skills and Slash Commands

Skills and slash commands can now declare an `effort` level in their YAML frontmatter. When a skill is invoked, Claude automatically adjusts its reasoning effort to match.

```yaml
---
name: quick-check
effort: low
---
```

| Effort | Use Case |
| ------ | -------- |
| `low` | Simple lookups, formatting tasks |
| `medium` | Standard development work |
| `high` | Architecture decisions, complex debugging |

### source: 'settings' Plugin Marketplace

Plugins can now declare `source: 'settings'` to indicate they come from a curated marketplace rather than a local directory. This is groundwork for the plugin discovery ecosystem.

### --resume Parallel Tool Results Fix

Fixed a bug where `--resume` would drop results from tools that ran in parallel. Previously, resuming a session that had concurrent tool calls could lose some of their outputs.

### --channels Research Preview

Initial research preview of the `--channels` permission relay (see 2.1.81 for GA release).

---

## Version 2.1.79

### claude auth login --console

A new authentication flow for environments where browser-based OAuth is not available. The `--console` flag prints a URL and waits for you to paste an authorization code back into the terminal.

```bash
claude auth login --console
```

This is particularly useful for remote servers, Docker containers, and CI environments where opening a browser is not possible. Uses API billing rather than interactive billing.

### Show Turn Duration Toggle

A new toggle in `/config` displays how long each turn (user message to complete response) took. Useful for identifying slow turns caused by large tool outputs or complex reasoning.

```
/config → Show turn duration → On
```

### /remote-control for VS Code

Enables remote control of Claude Code from VS Code's command palette. VS Code extensions can send prompts and receive responses programmatically.

### AI-Generated Session Titles in VS Code

VS Code now shows AI-generated titles for Claude Code sessions in the sidebar instead of generic "Session 1, Session 2" labels. Titles are based on the first substantive exchange.

---

## Version 2.1.78

### StopFailure Hook Event

A new hook event that fires when Claude Code stops due to an API error (rate limit, network failure, authentication error). This complements the existing `Stop` event which fires on normal completion.

```json
{
  "hooks": {
    "StopFailure": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "echo \"$(date): API failure\" >> /tmp/claude-failures.log"
          }
        ]
      }
    ]
  }
}
```

**Hook event comparison**:

| Event | Fires When | Use Case |
| ----- | ---------- | -------- |
| `Stop` | Normal completion | Session summaries, cleanup |
| `StopFailure` | API error or crash | Error logging, alerting, retry scripts |
| `SessionEnd` | Session closes | Final cleanup regardless of cause |

### ${CLAUDE_PLUGIN_DATA} Variable

Plugins now have access to a persistent state directory via the `${CLAUDE_PLUGIN_DATA}` environment variable. This directory survives across sessions, giving plugins a place to store configuration, caches, and state.

```bash
# In a plugin hook script
STATE_FILE="${CLAUDE_PLUGIN_DATA}/my-plugin-state.json"
```

### Plugin Agent Frontmatter

Plugin agents can now declare `effort`, `maxTurns`, and `disallowedTools` in their YAML frontmatter:

```yaml
---
name: my-agent
effort: high
maxTurns: 10
disallowedTools:
  - Bash
  - Write
---
```

| Field | Effect |
| ----- | ------ |
| `effort` | Sets reasoning effort level for the agent |
| `maxTurns` | Limits how many turns the agent can take |
| `disallowedTools` | Prevents the agent from using specified tools |

### Line-by-Line Response Streaming

Responses now stream line by line instead of waiting for complete paragraphs. This provides faster visual feedback, especially for long responses. (Note: disabled on Windows/WSL in 2.1.81.)

### Sandbox Git Fixes

Fixed issues where git operations inside the sandbox environment would fail due to missing configuration. The sandbox now properly inherits git user settings.

### Sandbox Security Warning

A visible warning now appears when sandbox dependencies (bubblewrap, socat) are missing. Previously, the sandbox would silently fall back to unsandboxed execution.

---

## Version 2.1.77

### Opus 4.6 Output Increase

The default maximum output for Opus 4.6 increased from 32k to 64k tokens, with an upper bound of 128k tokens. This means longer uninterrupted responses, larger code generations, and fewer truncation events.

| Setting | Before | After |
| ------- | ------ | ----- |
| Default max output | 32k tokens | 64k tokens |
| Upper bound | 64k tokens | 128k tokens |

### allowRead Sandbox Setting

A new sandbox configuration option that permits read access to specific paths while keeping write access restricted:

```json
{
  "sandbox": {
    "allowRead": [
      "/etc/ssl/certs",
      "/usr/share/ca-certificates"
    ]
  }
}
```

This is useful when tools need to read system certificates or shared configuration files but should not modify them.

### /copy N Command

Copy the Nth-latest response to clipboard. `/copy 1` copies the most recent response, `/copy 2` copies the one before that, and so on.

```
/copy 3    # Copies the third-most-recent response
```

### /branch Command

Renamed from `/fork`. Creates a branch point in the conversation -- you can explore a direction and return to the branch point if it does not work out.

```
/branch           # Create a branch point
/branch list      # List available branches
/branch switch 2  # Switch to branch 2
```

### SendMessage Auto-Resume

The `SendMessage` tool (used for inter-agent communication) now automatically resumes stopped agents. Previously, sending a message to a stopped agent would silently fail. The `resume` parameter has been removed from the Agent tool since auto-resume handles this case.

### Performance Improvements

| Metric | Improvement |
| ------ | ----------- |
| macOS startup | ~60ms faster |
| `--resume` speed | 45% faster |
| `--resume` memory | ~100-150MB less |
| Auto-updater | Fixed memory leak |
| "Always Allow" | Fixed for compound bash commands |

---

## Key Themes Across 2.1.77-2.1.81

### Performance

Startup savings on macOS, 45% faster resume with 100-150MB less memory, auto-updater memory leak fix, and the `--bare` flag for scripted calls that skips all non-essential initialization.

### Agent Improvements

Plugin agents gained `effort`, `maxTurns`, and `disallowedTools` frontmatter. Skills and slash commands gained `effort` frontmatter. `SendMessage` now auto-resumes stopped agents, removing a common source of silent failures in multi-agent workflows.

### Plugin Ecosystem

Persistent state via `${CLAUDE_PLUGIN_DATA}`, settings-based plugin sources, and the `--channels` permission relay give plugins more capabilities and better distribution mechanisms.

### Hooks

The `StopFailure` event fills the gap between `Stop` (normal) and `SessionEnd` (always). You can now distinguish between "Claude finished successfully" and "Claude crashed" in your hook scripts.

### Security and Sandbox

The `allowRead` sandbox setting provides granular read permissions. Sandbox git issues are fixed. Missing sandbox dependencies now produce visible warnings instead of silent fallbacks.

---

## Configuration Summary

Key new settings from this chapter:

```json
{
  "hooks": {
    "StopFailure": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "echo \"$(date): failure\" >> /tmp/claude-failures.log"
          }
        ]
      }
    ]
  },
  "sandbox": {
    "allowRead": [
      "/etc/ssl/certs"
    ]
  }
}
```

Plugin agent frontmatter:

```yaml
---
name: my-agent
effort: high
maxTurns: 10
disallowedTools:
  - Bash
---
```

Skill effort frontmatter:

```yaml
---
name: quick-lookup
effort: low
---
```

CLI flags:

```bash
claude -p "prompt" --bare          # Scripted mode, no hooks/plugins/skills
claude --channels                  # Permission relay to mobile
claude auth login --console        # Auth without browser
```

---

**See Also**:

- [Chapter 13: Claude Code Hooks](13-claude-code-hooks.md)
- [Chapter 46: Advanced Configuration Patterns](46-advanced-configuration-patterns.md)
- [Chapter 48: Lean Orchestrator Pattern](48-lean-orchestrator-pattern.md)
- [Chapter 54: Claude Code 2.1.73-2.1.76 Features](54-claude-code-2176-new-features.md)
