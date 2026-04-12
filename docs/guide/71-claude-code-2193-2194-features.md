---
layout: default
title: "Claude Code 2.1.93-2.1.94 — New Features & Improvements"
description: "Mantle on Bedrock, default effort level change, plugin skill YAML hooks, Slack MCP improvements, and interactive setup wizards."
parent: Guide
nav_order: 71
---

# Claude Code 2.1.93-2.1.94 — New Features & Improvements

These releases landed between April 7-9, 2026 and include platform provider improvements, effort level defaults, and plugin infrastructure fixes.

---

## Default Effort Level Changed to High

**Version**: 2.1.94

The default effort level changed from `medium` to `high` for:
- API-key users
- Bedrock / Vertex / Foundry users
- Team and Enterprise plan users

This means Claude will spend more compute on each response by default. To control this per-session:

```
/effort low     # Routine tasks, quick lookups
/effort medium  # Standard work
/effort high    # Complex reasoning (now the default)
/effort max     # Maximum quality
```

**Impact**: Better default response quality but slightly higher token usage per turn.

---

## Amazon Bedrock Mantle Support

**Version**: 2.1.94

Set `CLAUDE_CODE_USE_MANTLE=1` to route Bedrock requests through Mantle. This is relevant for organizations using Amazon's managed inference layer.

---

## Plugin Skill YAML Hooks Fix

**Version**: 2.1.94

Plugin skills that define hooks in their YAML frontmatter were previously silently ignored. This fix means plugin-provided hooks now fire correctly. If you maintain custom plugins with hook definitions, verify they behave as expected after upgrading.

---

## Slack MCP Improvements

**Version**: 2.1.94

When Claude sends a message via the Slack MCP `send-message` tool, the transcript now shows a compact `#channel` header with a clickable channel link instead of raw JSON. This is a UI-only improvement — no behavior change.

---

## Plugin Output Styles

**Version**: 2.1.94

New `keep-coding-instructions` frontmatter field for plugin output styles. This lets plugins control whether their formatting instructions persist across coding turns.

---

## Interactive Bedrock Setup Wizard

**Version**: 2.1.98 (backdated here for reference)

An interactive setup wizard for Amazon Bedrock is now accessible from the login screen when selecting "3rd-party platform". It guides through AWS authentication, region configuration, credential verification, and model pinning.

A similar wizard for Google Vertex AI was added in 2.1.98.

---

## Bug Fixes

- **2.1.96**: Fixed Bedrock requests failing with 403 when using `AWS_BEARER_TOKEN_BEDROCK` or `CLAUDE_CODE_SKIP_BEDROCK_AUTH` (regression in 2.1.94)
- **2.1.94**: Fixed agents appearing stuck after a 429 rate-limit response with a long `Retry-After` header
- **2.1.94**: Fixed Console login on macOS silently failing when the login keychain is locked
- **2.1.94**: Fixed plugin hooks failing with "No such file or directory" when `CLAUDE_PLUGIN_ROOT` was not set

---

*See also: [Chapter 72 — 2.1.95-2.1.97 Features](72-claude-code-2195-2197-features.md) | [Chapter 73 — 2.1.98-2.1.99 Features](73-claude-code-2198-2199-features.md)*
