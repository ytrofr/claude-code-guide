---
layout: default
title: "Frequently Asked Questions — Claude Code Guide"
description: "Answers to common questions about Claude Code: install, hooks, skills, MCP, agents, and context governance."
permalink: /faq/
nav_order: 99
faq:
  - question: "What is Claude Code?"
    answer: "Claude Code is Anthropic's official CLI for AI-powered coding assistance, powered by Opus 4.7, Opus 4.6, Sonnet 4.6, and Haiku 4.5 with a 1M token context window. It provides an interactive terminal experience where Claude reads files, writes code, runs commands, manages tasks, and coordinates agent teams. Claude Code understands your project through CLAUDE.md files and can be extended with hooks, skills, and MCP servers."
  - question: "How do I install Claude Code Guide?"
    answer: "Three install tiers driven by best-practices/manifest.json. Core (8 rules, 3 skills, 1 hook, newcomer-friendly): curl -sL https://raw.githubusercontent.com/ytrofr/claude-code-guide/master/install.sh | bash. Recommended (30 rules, 16 skills, 7 hooks): clone the repo and run ./install.sh --recommended. Full (64 rules, 44 skills, 12 hooks + governance scaffolding): clone and run ./install.sh --full. Also supports --global, --dry-run, --update, --uninstall."
  - question: "What are Claude Code hooks?"
    answer: "Hooks are shell scripts that run automatically at specific points in the Claude Code lifecycle. Claude Code 2.1.111 supports 27 hook events (SessionStart, UserPromptSubmit, PreToolUse, PostToolUse, PreCompact, Stop, SessionEnd, and more). Hooks receive data via stdin JSON and use $CLAUDE_PROJECT_DIR for portable paths. They can validate inputs, block dangerous operations, auto-format code, and run telemetry. See Part III/01 for authoring and Part VI/03 for the full event catalog."
  - question: "What is MCP integration?"
    answer: "MCP (Model Context Protocol) extends Claude Code with external tools. Register servers via claude mcp add, which stores them in ~/.claude.json (NOT settings.json mcpServers, which is silently ignored). Common servers: PostgreSQL, GitHub, Perplexity, Playwright, Basic Memory (semantic knowledge graph), Context7. See Part III/02 for install walkthrough and Part VI/05 for the full server catalog."
  - question: "How do Claude Code skills work?"
    answer: "Skills are Markdown files with YAML frontmatter (name, description with 'Use when...' trigger clause). Claude Code natively discovers skills from ~/.claude/skills/ (user-level) or .claude/skills/ (project-level) and matches them to queries via the description field. The description budget was raised from 250 to 1536 chars in CC 2.1.105. See Part III/04 for authoring and Part III/05 for lifecycle maintenance."
  - question: "What is the context governance system?"
    answer: "A 7-layer methodology for keeping context budget healthy as setups grow: enforcement (rule-size hooks), measurement (scanners for overlap, broken refs, compliance), optimization (/context-audit + /context-optimization skills), version control (baseline tags), regression testing, statusline monitoring, and methodology documentation (METHODOLOGY.md). Introduced in CC 2.1 era to address context bloat. See Part IV/06 for the full system."
  - question: "What is AI DNA?"
    answer: "A methodology for sharing AI patterns across multiple projects when you run 2+ AI-using projects (LLM agents, RAG, multi-agent pipelines). Universal patterns live in ~/.claude/rules/ai/ + ~/.claude/skills/shared-*/. Patterns promote from project-local to global when proven in 2+ projects for 30+ days. Weekly health check validates freshness. See Part V/01."
  - question: "How do install tiers differ?"
    answer: "Core (default, newcomer kit): 8 universal rules, 3 starter skills (verify, session-start, troubleshooting-decision-tree), 1 hook. Recommended (working developer): adds debugging rules, planning rules, TDD skill, plan-checklist, memory tooling, MCP patterns. Full (power user): adds governance scaffolding (scanners + baseline tag + 4 context-governance skills), AI DNA shared-layer rules, advanced architecture patterns, self-telemetry hooks, inter-agent bus."
  - question: "What's the difference between skills, rules, and hooks?"
    answer: "Rules are always-on invariants loaded into every session (e.g. 'never use mocked data'). Skills are reusable workflows invoked on demand (e.g. /verify, /session-start) — user-invocable or auto-matched by description. Hooks are shell scripts that fire on lifecycle events (e.g. format code on file write, log tool invocations). Use rules for enforcement, skills for workflows, hooks for automation."
  - question: "Where do I find the version history for Claude Code?"
    answer: "Part VI/01 — CC Version History is a single curated reference covering Claude Code 2.1.76 through 2.1.111+. It consolidates the old per-version feature chapters into one page, highlighting only features that still matter in the current release line."
---

# Frequently Asked Questions

{% for item in page.faq %}
## {{ item.question }}

{{ item.answer }}

{% endfor %}

---

Didn't find your question? Check the [full guide index](/docs/guide/) or [open an issue](https://github.com/ytrofr/claude-code-guide/issues).
