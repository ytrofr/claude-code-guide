# Claude Code Guide

> **The complete guide to Claude Code setup, skills, hooks, and MCP integration.**

[![GitHub stars](https://img.shields.io/github/stars/ytrofr/claude-code-guide?style=social)](https://github.com/ytrofr/claude-code-guide)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Documentation](https://img.shields.io/badge/docs-GitHub%20Pages-blue)](https://ytrofr.github.io/claude-code-guide)

Production-tested Claude Code patterns in 6 topical Parts (~43 chapters). Three install tiers. **CC 2.1.121+ compatible.**

**Models**: Opus 4.7 | Opus 4.6 | Sonnet 4.6 | Haiku 4.5 -- **1M token context window** -- **27 hook events** -- **Agent teams & task management**

---

## Install (Any Project)

Three install tiers driven by `best-practices/manifest.json`:

```bash
# Core (newcomer): 8 rules, 3 skills, 1 hook
curl -sL https://raw.githubusercontent.com/ytrofr/claude-code-guide/master/install.sh | bash

# Recommended (working developer): 30 rules, 16 skills, 7 hooks
git clone https://github.com/ytrofr/claude-code-guide.git
cd claude-code-guide
./install.sh --recommended /path/to/your-project

# Full (power user): 64 rules, 44 skills, 12 hooks + 4 governance scripts
./install.sh --full /path/to/your-project

# Install globally (~/.claude)
./install.sh --recommended --global

# Dry-run (see what would install)
./install.sh --dry-run --full

# Update
./install.sh --update

# Uninstall (manifest-aware)
./install.sh --uninstall
```

### Tier contents

| Tier | Flag | Rules | Skills | Hooks | Extras |
|---|---|---|---|---|---|
| Core | (default) | 8 | 3 | 1 | CLAUDE.md + BEST-PRACTICES.md |
| Recommended | `--recommended` | 30 | 16 | 7 | + Basic Memory MCP template |
| Full | `--full` | 64 | 44 | 12 | + 4 governance scripts, baseline tag, AI DNA rules |

See [`best-practices/manifest.json`](best-practices/manifest.json) for the authoritative tier definitions. Remote one-liner (`curl | bash`) installs Core only; Recommended/Full require cloning the repo.

---

## What's inside

The guide is organized into six topical Parts. Each Part has its own index page with a reading order and a table of chapters.

| Part | Focus | Chapters |
|---|---|---|
| [I — Foundation](docs/guide/part1-foundation/) | Install, CLAUDE.md, project structure, first session | 5 |
| [II — Workflow](docs/guide/part2-workflow/) | Plan mode, TDD, brainstorming, verify, commit/PR | 6 |
| [III — Extension](docs/guide/part3-extension/) | Hooks, MCP, agents, skills authoring, plugins, slash commands, Cloud Run | 9 |
| [IV — Context Engineering](docs/guide/part4-context-engineering/) | Memory bank, rules, Basic Memory, budget, governance, skill lifecycle | 7 |
| [V — Advanced](docs/guide/part5-advanced/) | AI DNA, inter-agent bus, self-telemetry, Monitor, statusline, defrag | 7 |
| [VI — Reference](docs/guide/part6-reference/) | CC version history, CLI flags + env, hook catalog, skill catalog, MCP catalog | 6 |

Roadmap and release phases: [`ROADMAP-v5.md`](ROADMAP-v5.md).

---

## Quick Start

```bash
# 1. Install into an existing project
git clone https://github.com/ytrofr/claude-code-guide.git
cd claude-code-guide
./install.sh --recommended /path/to/your-project

# 2. Open the project in Claude Code
cd /path/to/your-project
claude
```

Then start with [Part I chapter 01 — Installation](docs/guide/part1-foundation/01-installation.md) and [Part I chapter 04 — First session](docs/guide/part1-foundation/04-first-session.md).

---

## Frequently Asked Questions

### What is Claude Code?

Claude Code is Anthropic's official CLI for AI-powered coding assistance, powered by Opus 4.7, Opus 4.6, Sonnet 4.6, and Haiku 4.5 with a 1M token context window. It provides an interactive terminal experience where Claude can read files, write code, run commands, manage tasks, and coordinate agent teams. Claude Code understands your project context through CLAUDE.md files and can be extended with hooks, skills, and MCP servers.

### How do I set up Claude Code?

Install via the official installer: `curl -fsSL https://claude.ai/install.sh | sh` (or `claude update` if already installed). Create a `CLAUDE.md` file in your project root with project-specific instructions. Optionally add hooks in `.claude/hooks/` for automation, skills in `~/.claude/skills/` for reusable workflows, and MCP servers for database/API access. Our installer tiers provide these pre-configured — see [Part I — Foundation](docs/guide/part1-foundation/).

### What are Claude Code hooks?

Hooks are shell scripts that run automatically at specific points in the Claude Code lifecycle. There are 27 hook events (PreToolUse, PostToolUse, SessionStart, SessionEnd, UserPromptSubmit, and many more) that can validate inputs, block dangerous operations, auto-format code, and run background analytics. See [Part III chapter 01 — Hooks](docs/guide/part3-extension/01-hooks.md) and [Part VI chapter 03 — Hook event catalog](docs/guide/part6-reference/03-hook-event-catalog.md).

### What is MCP integration?

MCP (Model Context Protocol) extends Claude Code with external tools. Connect to PostgreSQL databases, GitHub repositories, memory systems, and APIs. See [Part III chapter 02 — MCP integration](docs/guide/part3-extension/02-mcp-integration.md) and [Part VI chapter 05 — MCP server catalog](docs/guide/part6-reference/05-mcp-server-catalog.md). Note: MCP servers register via `claude mcp add` (stored in `~/.claude.json`) — the `settings.json mcpServers` block is silently ignored.

### How do Claude Code skills work?

Skills are Markdown files with YAML frontmatter (`name:` and `description:` with an explicit trigger clause). Claude Code natively discovers all skills from `~/.claude/skills/` and `.claude/skills/` and matches them to queries using the description field. No custom hooks needed — skills are built into Claude Code since v2.1.76. See [Part III chapter 04 — Skills authoring](docs/guide/part3-extension/04-skills-authoring.md).

### What is the memory bank?

The memory bank is a hierarchical knowledge system: always-loaded files, learned patterns, on-demand blueprints, and reference archives. It stores project context, decisions, and patterns for efficient token usage. See [Part IV chapter 01 — Memory bank](docs/guide/part4-context-engineering/01-memory-bank.md) and [Part IV chapter 04 — Context budget](docs/guide/part4-context-engineering/04-context-budget.md).

---

## Core Documentation

### Part I — Foundation

- [01 Installation](docs/guide/part1-foundation/01-installation.md)
- [02 CLAUDE.md primer](docs/guide/part1-foundation/02-claude-md-primer.md)
- [03 Project structure](docs/guide/part1-foundation/03-project-structure.md)
- [04 First session](docs/guide/part1-foundation/04-first-session.md)
- [05 Setup troubleshooting](docs/guide/part1-foundation/05-setup-troubleshooting.md)

### Part II — Workflow

- [01 Plan mode](docs/guide/part2-workflow/01-plan-mode.md)
- [02 TDD](docs/guide/part2-workflow/02-tdd.md)
- [03 Brainstorming](docs/guide/part2-workflow/03-brainstorming.md)
- [04 Verify & canary](docs/guide/part2-workflow/04-verify-canary.md)
- [05 Session lifecycle](docs/guide/part2-workflow/05-session-lifecycle.md)
- [06 Commit and PR](docs/guide/part2-workflow/06-commit-and-pr.md)

### Part III — Extension

- [01 Hooks](docs/guide/part3-extension/01-hooks.md)
- [02 MCP integration](docs/guide/part3-extension/02-mcp-integration.md)
- [03 Agents and subagents](docs/guide/part3-extension/03-agents-and-subagents.md)
- [03b Claude Agent SDK](docs/guide/part3-extension/03b-claude-agent-sdk.md)
- [04 Skills authoring](docs/guide/part3-extension/04-skills-authoring.md)
- [05 Skills maintenance](docs/guide/part3-extension/05-skills-maintenance.md)
- [06 Plugins and marketplace](docs/guide/part3-extension/06-plugins-and-marketplace.md)
- [07 Slash commands](docs/guide/part3-extension/07-slash-commands.md)
- [08 Cloud Run deploy patterns](docs/guide/part3-extension/08-cloud-run-deploy-patterns.md)

### Part IV — Context Engineering

- [01 Memory bank](docs/guide/part4-context-engineering/01-memory-bank.md)
- [02 Rules system](docs/guide/part4-context-engineering/02-rules-system.md)
- [03 Basic Memory MCP](docs/guide/part4-context-engineering/03-basic-memory-mcp.md)
- [04 Context budget](docs/guide/part4-context-engineering/04-context-budget.md)
- [05 Progressive disclosure](docs/guide/part4-context-engineering/05-progressive-disclosure.md)
- [06 Context governance](docs/guide/part4-context-engineering/06-context-governance.md)
- [07 Skill lifecycle](docs/guide/part4-context-engineering/07-skill-lifecycle.md)

### Part V — Advanced

- [01 AI DNA shared layer](docs/guide/part5-advanced/01-ai-dna-shared-layer.md)
- [02 Inter-agent bus](docs/guide/part5-advanced/02-inter-agent-bus.md)
- [03 Self-telemetry](docs/guide/part5-advanced/03-self-telemetry.md)
- [04 Monitor tool](docs/guide/part5-advanced/04-monitor-tool.md)
- [05 Statusline patterns](docs/guide/part5-advanced/05-statusline-patterns.md)
- [06 Cross-project knowledge](docs/guide/part5-advanced/06-cross-project-knowledge.md)
- [07 Session end and defrag](docs/guide/part5-advanced/07-session-end-and-defrag.md)

### Part VI — Reference

- [01 CC version history](docs/guide/part6-reference/01-cc-version-history.md)
- [02 CLI flags and env](docs/guide/part6-reference/02-cli-flags-and-env.md)
- [03 Hook event catalog](docs/guide/part6-reference/03-hook-event-catalog.md)
- [04 Skill catalog](docs/guide/part6-reference/04-skill-catalog.md)
- [05 MCP server catalog](docs/guide/part6-reference/05-mcp-server-catalog.md)
- [06 Security checklist](docs/guide/part6-reference/06-security-checklist.md)

---

## Repository Structure

```
claude-code-guide/
├── install.sh                   # Manifest-driven installer (Core/Recommended/Full)
├── best-practices/              # Installable best practices package
│   ├── BEST-PRACTICES.md       # Universal best practices document
│   ├── manifest.json           # Authoritative tier definitions
│   ├── rules/                  # Rule files referenced by the manifest
│   ├── skills/                 # Skill files referenced by the manifest
│   ├── hooks/                  # Hook scripts referenced by the manifest
│   ├── scripts/                # Governance scripts (Full tier only)
│   ├── test-manifest-resolve.sh
│   └── VERSION                 # 5.0.0
├── docs/
│   ├── index.md                # Landing page
│   └── guide/
│       ├── part1-foundation/
│       ├── part2-workflow/
│       ├── part3-extension/
│       ├── part4-context-engineering/
│       ├── part5-advanced/
│       ├── part6-reference/
│       └── _redirect-plan.md   # Internal redirect map (nav-excluded)
├── ROADMAP-v5.md                # Public roadmap
├── CHANGELOG.md                 # Release notes
├── CITATION.cff                 # Citation metadata
└── README.md
```

---

## Release phases

v5.0 shipped across phases B2-B7. See [`ROADMAP-v5.md`](ROADMAP-v5.md) for the phase tracker and known gaps.

---

## Key Features

- **Claude Code Setup**: Manifest-driven install with three tiers (Core/Recommended/Full)
- **Claude Code Hooks**: 27 hook events documented with examples
- **Claude Code Skills**: Native loading since v2.1.76 — authoring, maintenance, and lifecycle chapters
- **Claude Code MCP**: Full server catalog + integration patterns
- **Context Engineering**: Memory bank, rules system, governance, skill lifecycle
- **Best Practices**: Anthropic-aligned patterns, debugged against production

---

## Related Projects

- **[AI Intelligence Hub](https://github.com/ytrofr/ai-intelligence-hub)** — Track 12 AI sources (GitHub, HuggingFace, MCP, Claude Code) with full-text search.

---

## What Makes This Different

| Aspect                | This Guide                                              |
| --------------------- | ------------------------------------------------------- |
| **Production-Tested** | Patterns extracted from real systems, not hypothetical  |
| **Evidence-Based**    | Claims cite CC version, file paths, and settings keys   |
| **Modular Install**   | Three tiers match three user profiles                   |
| **Current**           | CC 2.1.111+ compatible, updated through April 2026      |
| **Validation-First**  | Installer has `--dry-run`; manifest has self-test       |

---

## Credits

**Research**: Anthropic Claude Code documentation + production use across multiple projects
**Marketplace**: [wshobson/agents](https://github.com/wshobson/agents)
**Official Docs**: [code.claude.com/docs](https://code.claude.com/docs/en/memory)
**Created**: December 2024
**Updated**: April 2026
**Version**: 5.0.0

---

## License

MIT License — see [LICENSE](LICENSE)

---

## Quick Links

**Getting Started**

- [Part I — Foundation index](docs/guide/part1-foundation/)
- [Installation chapter](docs/guide/part1-foundation/01-installation.md)
- [First session walkthrough](docs/guide/part1-foundation/04-first-session.md)

**Core Systems**

- [Hooks (Part III/01)](docs/guide/part3-extension/01-hooks.md)
- [MCP integration (Part III/02)](docs/guide/part3-extension/02-mcp-integration.md)
- [Skills authoring (Part III/04)](docs/guide/part3-extension/04-skills-authoring.md)

**Reference**

- [CC version history (Part VI/01)](docs/guide/part6-reference/01-cc-version-history.md)
- [Hook event catalog (Part VI/03)](docs/guide/part6-reference/03-hook-event-catalog.md)
- [Roadmap](ROADMAP-v5.md)

---

_Built from production Claude Code usage across multiple projects, refreshed for CC 2.1.111+._
