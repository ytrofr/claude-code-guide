---
layout: default
title: Claude Code Guide - Complete Setup & Best Practices
description: Complete guide to Claude Code hooks, skills, agents, MCP integration. 14 hook events. 226+ native skills. Production-tested.
---

# Claude Code Guide

**What is Claude Code?** Claude Code is Anthropic's official CLI for AI-powered coding assistance. It provides an interactive terminal experience where you can collaborate with Claude directly in your development environment.

**What does this guide cover?** Complete setup, skills system, hooks, MCP integration, and 226+ proven patterns from production use.

**How long to set up?** 30 minutes for basic setup, 2-4 hours for full optimization.

---

## Quick Answers

### How do I install Claude Code?

Claude Code is installed via npm: `npm install -g @anthropic-ai/claude-code`. After installation, run `claude` in your terminal to start an interactive session. You'll need an Anthropic API key, which you can get from the [Anthropic Console](https://console.anthropic.com/). See our [Quick Start Guide](quick-start.md) for complete setup instructions.

### What are Claude Code skills?

Skills are reusable Markdown files with YAML frontmatter (`name:` and `description:` with "Use when..." clauses). Claude Code natively discovers all skills from `~/.claude/skills/` and activates them based on your query. No custom hooks needed. Our guide documents 226+ production-tested skills. Learn more in our [Skill Activation System](skill-activation-system.md) documentation.

### What is the pre-prompt hook?

**Deprecated (Feb 2026)**: The pre-prompt hook was a custom `UserPromptSubmit` hook that matched skills to queries before Claude Code added native skill loading. Claude Code now discovers and loads skills automatically from `~/.claude/skills/`, making custom pre-prompt hooks unnecessary. See the [Pre-Prompt Hook Guide](pre-prompt-hook-complete-guide.md) for historical reference.

### What is MCP integration?

MCP (Model Context Protocol) extends Claude Code with external tools like databases, file systems, and APIs. This guide covers integrations with PostgreSQL, GitHub, Perplexity, Basic Memory, and more. See our [MCP Integration Guide](guide/06-mcp-integration.md).

### How do skills work?

Skills are Markdown files with YAML frontmatter (`name:` and `description:` fields). Claude Code natively discovers all skills in `~/.claude/skills/` and matches them to your queries using the `description:` field. The key to good activation is writing clear "Use when..." clauses in your descriptions. 226+ skills documented in this guide.

### What is the memory bank?

The memory bank is a hierarchical knowledge system that stores project context, patterns, and decisions. It uses a 4-tier structure (always → learned → ondemand → reference) to optimize token usage while maintaining full context access. See [Memory Bank Hierarchy](guide/12-memory-bank-hierarchy.md).

### What are Claude Code hooks?

Claude Code hooks are customizable scripts that run at specific points in the AI workflow. There are 14 hook events (PreToolUse, PostToolUse, UserPromptSubmit, SessionStart, SessionEnd, and more) and 3 hook types (command, prompt, agent). Hooks can validate inputs, block dangerous operations, inject context, and run background analytics. See our [Complete Hooks Guide](guide/13-claude-code-hooks.md).

### What are Claude Code agents?

Agents (subagents) are specialized Claude Code workers spawned via the Task tool. Each agent gets its own context window, can use a specific model (sonnet, opus, haiku), has persistent memory, and can be configured with restricted tool access. They enable parallel execution and domain expertise. See our [Agents Guide](guide/36-agents-and-subagents.md).

### How do Claude Code agent teams work?

Agent teams are an experimental feature where a lead agent coordinates multiple teammate agents working in parallel. Enabled via `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, teams share a task list and mailbox for coordination. The lead can operate in delegate mode (coordination only) or default mode (can also use tools). See our [Agent Teams Guide](guide/37-agent-teams.md).

### How much time does this save?

Based on production metrics: **100+ hours per year** in developer time. Key achievements include 370x hook optimization, 47-70% token savings per branch, and 88.2% skill activation accuracy.

---

## Documentation Structure

### Getting Started

- [Quick Start Guide](quick-start.md) - 30-minute basic setup
- [Minimal Setup](guide/02-minimal-setup.md) - Essential configuration
- [Task Tracking System](guide/04-task-tracking-system.md) - Organize work with task lists
- [Developer Mode & UI Feedback](guide/05-developer-mode-ui-feedback-system.md) - Visual debugging tools

### Core Systems

- [MCP Integration](guide/06-mcp-integration.md) - External tool connections (PostgreSQL, GitHub, Playwright)
- [Memory Bank Hierarchy](guide/12-memory-bank-hierarchy.md) - 4-tier context management
- [Claude Code Hooks](guide/13-claude-code-hooks.md) - 14 hook events, 3 hook types
- [Git vs Claude Hooks](guide/14-git-vs-claude-hooks-distinction.md) - When to use which
- [Progressive Disclosure](guide/15-progressive-disclosure.md) - Token-efficient context loading
- [Pre-Prompt Hook Guide](pre-prompt-hook-complete-guide.md) - Historical (deprecated Feb 2026)

### Skills System

- [Skill Activation System](skill-activation-system.md) - 226+ production skills (native loading)
- [Skills Activation Breakthrough](guide/16-skills-activation-breakthrough.md) - How activation works
- [Skill Detection Enhancement](guide/17-skill-detection-enhancement.md) - Improving match rates
- [Skill Keyword Methodology](guide/24-skill-keyword-enhancement-methodology.md) - Trigger optimization
- [Skills Filtering Optimization](guide/20-skills-filtering-optimization.md) - Token reduction
- [Skill Optimization Patterns](guide/28-skill-optimization-patterns.md) - Maintenance workflows
- [Skill Optimization & Maintenance](guide/35-skill-optimization-maintenance.md) - 6-step audit workflow
- [Session Documentation Skill](guide/23-session-documentation-skill.md) - Auto-document sessions
- [Document Automation](guide/32-document-automation.md) - Pattern analysis engine

### Agents & Teams

- [Agents and Subagents](guide/36-agents-and-subagents.md) - Create specialized AI workers
- [Agent Teams](guide/37-agent-teams.md) - Coordinate parallel agents (experimental)

### Testing

- [Playwright E2E Testing](guide/19-playwright-e2e-testing.md) - End-to-end browser testing
- [Playwright MCP Integration](guide/19b-playwright-mcp-integration.md) - MCP-based browser automation
- [Comprehensive Skill Activation Testing](guide/29b-comprehensive-skill-activation-testing.md) - 170-query test suite
- [Test Priority Best Practices](guide/30b-test-priority-best-practices.md) - P0/P1/P2 guidelines

### Branch & Context Management

- [Branch Context System](guide/29-branch-context-system.md) - Multi-branch workflows
- [Blueprint Auto-Loading](guide/30-blueprint-auto-loading.md) - Automatic context injection
- [Branch-Aware Development](guide/31-branch-aware-development.md) - Branch-specific patterns
- [Branch-Specific Skill Curation](guide/33-branch-specific-skill-curation.md) - Per-branch skill sets

### Planning & Quality

- [Plan Mode Quality Checklist](guide/45-plan-mode-checklist.md) - 11 mandatory plan sections with modularity gate
- [Adoptable Rules, Commands & Templates](guide/47-adoptable-rules-and-commands.md) - 15 rules, 7 commands, ready to adopt

### Advanced Topics

- [Advanced Configuration Patterns](guide/46-advanced-configuration-patterns.md) - Path-specific rules, agent memory, scope

- [MCP Cost Control](guide/18-perplexity-cost-optimization.md) - Cache-first research with hook enforcement
- [Pre-Prompt Optimization](guide/21-pre-prompt-optimization.md) - Performance tuning
- [Marketplace Integration](guide/22-wshobson-marketplace-integration.md) - Third-party agent integration
- [Best Practices Reference](guide/25-best-practices-reference.md) - Anthropic-aligned patterns
- [Rules System](guide/26-claude-code-rules-system.md) - Project-level enforcement
- [Fast Cloud Run Deployment](guide/27-fast-cloud-run-deployment.md) - GCP deployment patterns
- [Basic Memory MCP Integration](guide/34-basic-memory-mcp-integration.md) - Persistent knowledge
- [Context Costs & Skill Budget](guide/38-context-costs-and-skill-budget.md) - Token optimization
- [Context Separation](guide/39-context-separation.md) - Isolation patterns
- [Agent Orchestration Patterns](guide/40-agent-orchestration-patterns.md) - 5 workflow architectures
- [Evaluation Patterns](guide/41-evaluation-patterns.md) - Anthropic eval best practices
- [Session Memory & Compaction](guide/42-session-memory-compaction.md) - Context recovery
- [Claude Agent SDK](guide/43-claude-agent-sdk.md) - Building custom agents
- [Skill Design Principles](guide/44-skill-design-principles.md) - Degrees of freedom framework

---

## Key Metrics

| Metric            | Result                     |
| ----------------- | -------------------------- |
| Time Saved        | 100+ hours/year            |
| Hook Optimization | 370x faster                |
| Hook Events       | 14 documented              |
| Hook Types        | 3 (command, prompt, agent) |
| Skill Activation  | 88.2% accuracy             |
| Agent Patterns    | 5 workflow architectures   |
| Token Savings     | 47-70% per branch          |
| Production Skills | 226+ documented            |
| MCP Integrations  | 13 servers, 70+ tools      |
| Chapters          | 47 comprehensive           |

---

## Why This Guide?

This guide is built from 14+ months of production use. Every pattern, optimization, and best practice has been tested in real-world development scenarios. We share what works, what doesn't, and the evidence to prove it.

---

<!-- TechArticle Schema -->
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "TechArticle",
  "headline": "Claude Code Guide - Complete Implementation Guide",
  "description": "Complete guide to Claude Code hooks, skills, agents, and MCP integration. 14 hook events, 3 hook types, 370x optimization. Production-tested patterns.",
  "author": {
    "@type": "Person",
    "name": "ytrofr",
    "url": "https://github.com/ytrofr"
  },
  "datePublished": "2024-12-14",
  "dateModified": "2026-02-18",
  "publisher": {
    "@type": "Organization",
    "name": "Claude Code Guide",
    "url": "https://ytrofr.github.io/claude-code-guide"
  },
  "keywords": "claude code, claude ai, anthropic, mcp, hooks, skills, agents, subagents, agent teams, ai coding assistant, cli, developer tools, pre-prompt hook",
  "articleSection": "Developer Tools",
  "inLanguage": "en-US"
}
</script>

<!-- FAQPage Schema for Answer Engines -->
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "How do I install Claude Code?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Claude Code is installed via npm: npm install -g @anthropic-ai/claude-code. After installation, run 'claude' in your terminal to start an interactive session. You'll need an Anthropic API key from console.anthropic.com."
      }
    },
    {
      "@type": "Question",
      "name": "What are Claude Code skills?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Skills are reusable instructions that activate automatically based on your query. They contain proven patterns, triggers, and workflows that save hours of repetitive work. This guide documents 226+ production-tested skills with 88.2% activation accuracy."
      }
    },
    {
      "@type": "Question",
      "name": "What is the pre-prompt hook in Claude Code?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "The pre-prompt hook was a custom UserPromptSubmit hook for skill matching, now deprecated (Feb 2026). Claude Code natively discovers and loads skills from ~/.claude/skills/ using the description field. No custom hooks needed for skill activation."
      }
    },
    {
      "@type": "Question",
      "name": "What is MCP integration in Claude Code?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "MCP (Model Context Protocol) extends Claude Code with external tools like PostgreSQL databases, GitHub repositories, file systems, and APIs. This guide covers 13 MCP servers with 70+ tools."
      }
    },
    {
      "@type": "Question",
      "name": "How much time does Claude Code save?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Based on production metrics: 100+ hours per year in developer time. Key achievements include 370x hook optimization, 47-70% token savings per branch, and 88.2% skill activation accuracy."
      }
    },
    {
      "@type": "Question",
      "name": "What is the Claude Code memory bank?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "The memory bank is a hierarchical knowledge system that stores project context, patterns, and decisions. It uses a 4-tier structure (always, learned, ondemand, reference) to optimize token usage while maintaining full context access."
      }
    },
    {
      "@type": "Question",
      "name": "What are Claude Code hooks?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Claude Code hooks are customizable scripts that run at specific points in the AI workflow. There are 14 hook events (PreToolUse, PostToolUse, UserPromptSubmit, etc.) and 3 hook types (command, prompt, agent). Hooks can validate inputs, block dangerous operations, inject context, and run background analytics."
      }
    },
    {
      "@type": "Question",
      "name": "What are Claude Code agents and subagents?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Agents (subagents) are specialized Claude Code workers spawned via the Task tool. Each agent gets its own context window, can use a specific model (sonnet, opus, haiku), has persistent memory, and can be configured with restricted tool access. They enable parallel execution and domain expertise."
      }
    },
    {
      "@type": "Question",
      "name": "How do Claude Code agent teams work?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Agent teams are an experimental feature where a lead agent coordinates multiple teammate agents working in parallel. Enabled via CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1, teams share a task list and mailbox for coordination. The lead can operate in delegate mode (coordination only) or default mode (can also use tools)."
      }
    }
  ]
}
</script>

<!-- HowTo Schema for Setup Guide -->
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "HowTo",
  "name": "How to Set Up Claude Code",
  "description": "Complete guide to setting up Claude Code with skills, hooks, and MCP integration in 30 minutes.",
  "totalTime": "PT30M",
  "estimatedCost": {
    "@type": "MonetaryAmount",
    "currency": "USD",
    "value": "0"
  },
  "step": [
    {
      "@type": "HowToStep",
      "position": 1,
      "name": "Install Claude Code",
      "text": "Install Claude Code via npm: npm install -g @anthropic-ai/claude-code"
    },
    {
      "@type": "HowToStep",
      "position": 2,
      "name": "Clone the template",
      "text": "Copy the template directory to your project: cp -r template/.claude ~/my-project/"
    },
    {
      "@type": "HowToStep",
      "position": 3,
      "name": "Configure core patterns",
      "text": "Edit CLAUDE.md and CORE-PATTERNS.md with your project-specific rules"
    },
    {
      "@type": "HowToStep",
      "position": 4,
      "name": "Set up hooks",
      "text": "Configure hooks in .claude/settings.json. Use PostToolUse for auto-formatting, PreToolUse for safety validation, and SessionStart for environment setup. 14 hook events available with 3 hook types (command, prompt, agent). Skills are loaded natively without hooks."
    },
    {
      "@type": "HowToStep",
      "position": 5,
      "name": "Create agents",
      "text": "Create specialized agents in .claude/agents/ as markdown files with YAML frontmatter. Configure model, tools, memory persistence, and maxTurns for cost control."
    },
    {
      "@type": "HowToStep",
      "position": 6,
      "name": "Configure MCP servers",
      "text": "Set up GitHub, PostgreSQL, and other MCP integrations in mcp_servers.json"
    },
    {
      "@type": "HowToStep",
      "position": 7,
      "name": "Validate setup",
      "text": "Run ./scripts/validate-setup.sh to verify configuration. Test hook activation, agent spawning, and MCP connections."
    }
  ]
}
</script>

<!-- SoftwareApplication Schema -->
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  "name": "Claude Code",
  "applicationCategory": "DeveloperApplication",
  "operatingSystem": "macOS, Linux, Windows",
  "offers": {
    "@type": "Offer",
    "price": "0",
    "priceCurrency": "USD"
  },
  "author": {
    "@type": "Organization",
    "name": "Anthropic"
  },
  "description": "Anthropic's official CLI for AI-powered coding assistance"
}
</script>

<!-- BreadcrumbList Schema -->
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  "itemListElement": [
    {
      "@type": "ListItem",
      "position": 1,
      "name": "Home",
      "item": "https://ytrofr.github.io/claude-code-guide/"
    },
    {
      "@type": "ListItem",
      "position": 2,
      "name": "Guide",
      "item": "https://ytrofr.github.io/claude-code-guide/guide/"
    }
  ]
}
</script>
