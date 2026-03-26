---
layout: default
title: "Plugin Marketplace Guide"
parent: Guide
nav_order: 63
---

# Plugin Marketplace Guide

*How to discover, evaluate, install, and manage Claude Code plugins*

Claude Code has an official plugin marketplace with 90+ plugins covering code review, security, documentation, LSP integration, and workflow automation. This chapter covers how to use it effectively without bloating your setup.

## Quick Start

```bash
# Browse plugins interactively
/plugin

# Add the official Anthropic marketplace (auto-available, but ensure it's registered)
/plugin marketplace add anthropics/claude-plugins-official

# Install a plugin
/plugin install pr-review-toolkit@claude-plugins-official

# List installed
/plugin marketplace list

# After changes
/reload-plugins
```

## Marketplace Architecture

Plugins can contain any combination of: **skills**, **agents**, **hooks**, **MCP servers**, and **LSP servers**. Skills from plugins are namespaced (`/plugin-name:skill-name`) to avoid conflicts with your custom skills.

### Sources

| Source Type | Example | Use Case |
|------------|---------|----------|
| GitHub shorthand | `anthropics/claude-plugins-official` | Most common |
| Git URL | `https://gitlab.com/company/plugins.git` | Private Git hosts |
| Local path | `./my-local-marketplace` | Development/testing |
| JSON URL | `https://example.com/marketplace.json` | Custom registries |

### Scope

Plugins install at **user** scope (`~/.claude/plugins/`) by default. Use `--scope project` for project-local installs.

## Evaluating Plugins

Before installing any plugin, evaluate against these criteria:

### 1. Overlap Check

Does this plugin duplicate something you already have?

```bash
# Check if you already have similar skills
ls ~/.claude/skills/ | grep -i "keyword"

# Check if hooks already cover the same event
grep -A2 "PreToolUse\|PostToolUse\|SessionStart" ~/.claude/settings.json
```

### 2. Quality Signals

| Signal | Good | Concerning |
|--------|------|-----------|
| Install count | >10K | <100 |
| Publisher | Anthropic, known org | Unknown individual |
| License | MIT, Apache-2.0 | No license, proprietary |
| Permissions | Scoped `allowed-tools` | `Bash(*)` or no restrictions |

### 3. Security Check

After installing, scan the plugin:

```bash
npx ecc-agentshield scan ~/.claude/plugins/cache/
```

## Recommended Plugins

Based on a March 2026 evaluation of a mature setup (47 rules, 42 skills, 16 hooks):

### Tier 1: High Value (Enable)

| Plugin | Installs | Why Enable |
|--------|----------|-----------|
| **pr-review-toolkit** | 58K | 6 specialized review agents including silent-failure-hunter and type-design-analyzer. Complements existing review rules. |
| **skill-creator** | 77K | Eval framework with benchmarks and improvement loops. Fills the measurement gap — your skills have no eval system. |
| **context7** | 189K | Version-specific library docs via MCP. Prevents hallucinated API usage for Remotion, ADK, Express, etc. |
| **commit-commands** | 94K | `/commit`, `/commit-push-pr`, `/clean-gone`. Already installed and proven. |

### Tier 2: Evaluate

| Plugin | Installs | When to Enable |
|--------|----------|---------------|
| **security-guidance** | 87K | If AgentShield is insufficient. Update marketplace first to sync full content. |
| **hookify** | 29K | If you need regex-based conditional warnings (e.g., block `.env` edits). |
| **typescript-lsp** | 106K | If TypeScript type errors are a recurring issue in your projects. |

### Tier 3: Skip

| Plugin | Reason to Skip |
|--------|---------------|
| **feature-dev** (131K) | Conflicts with existing plan-checklist + validation-workflow |
| **claude-md-management** (92K) | Your CLAUDE.md + 47 rules system is more mature |
| **claude-code-setup** (55K) | Designed for greenfield setups; your stack is at 85%+ maturity |
| **code-simplifier** (140K) | Already included in pr-review-toolkit |
| **ralph-loop** (110K) | Risky for token burn (while-true loop) |

## Managing Plugins

```bash
# Enable/disable without uninstalling
/plugin enable plugin-name@marketplace
/plugin disable plugin-name@marketplace

# Uninstall completely
/plugin uninstall plugin-name@marketplace

# Update marketplace catalogs
/plugin marketplace update marketplace-name

# Validate your own plugin (for plugin authors)
/plugin validate .
```

### Cleanup Stale Plugins

```bash
# Check for plugins from dead marketplaces
cat ~/.claude/plugins/installed_plugins.json | grep -o '"[^"]*@[^"]*"'
# Cross-reference with known_marketplaces.json
```

If a plugin references a marketplace that no longer exists in `known_marketplaces.json`, uninstall it.

## Enterprise Restrictions

Organizations can lock down which marketplaces are allowed:

```json
// managed-settings.d/security.json
{
  "strictKnownMarketplaces": true,
  "blockedPlugins": ["risky-plugin@some-marketplace"]
}
```

## Anti-Patterns

| Anti-Pattern | Why It's Bad | Fix |
|-------------|-------------|-----|
| Installing everything popular | Context bloat, conflicting workflows | Evaluate overlap first |
| Ignoring plugin permissions | Security risk from broad `Bash(*)` skills | Scan with AgentShield |
| Never updating marketplace | Miss security patches and new features | Monthly `marketplace update` |
| Mixing plugin + custom skills for same task | Confusing precedence, duplicated context | Choose one, disable the other |
| Using `@latest` in plugin MCP servers | Supply chain risk | Pin to specific versions |

---

*Previous: [Chapter 62 — Security Scanning for Claude Code Configurations](62-security-scanning)*
