# Claude Code Guide

> **The complete guide to Claude Code setup, skills, hooks, and MCP integration.**

[![GitHub stars](https://img.shields.io/github/stars/ytrofr/claude-code-guide?style=social)](https://github.com/ytrofr/claude-code-guide)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Documentation](https://img.shields.io/badge/docs-GitHub%20Pages-blue)](https://ytrofr.github.io/claude-code-guide)

Production-tested Claude Code patterns. 226+ documented patterns, 100+ hours saved per year.

---

## Why This Guide?

| Metric            | Result                    |
| ----------------- | ------------------------- |
| Time Saved        | **100+ hours/year**       |
| Hooks             | **14 events automated**   |
| Skills            | **226+ native loading**   |
| Token Savings     | **47-70% per branch**     |
| Production Skills | **226+ documented**       |
| MCP Integrations  | **13 servers, 70+ tools** |

**Source**: 14+ months of production use with 97 components validated.

---

## Quick Start (30 minutes)

```bash
# 1. Clone the template
cp -r template/ ~/my-project/.claude
cd ~/my-project

# 2. Validate structure
./scripts/validate-setup.sh

# 3. Add skills (Claude Code discovers them automatically)
cp -r template/.claude/skills/ ~/.claude/skills/

# 4. Configure MCP servers
cp .claude/mcp_servers.json.template .claude/mcp_servers.json
# Add your GitHub token

# 5. Start Claude Code
claude
```

**Detailed walkthrough**: [Quick Start Guide](docs/quick-start.md) | [Skills System](docs/skill-activation-system.md)

---

## Frequently Asked Questions

### What is Claude Code?

Claude Code is Anthropic's official CLI for AI-powered coding assistance. It provides an interactive terminal experience where Claude can read files, write code, run commands, and help with development tasks. Claude Code understands your project context through CLAUDE.md files and can be extended with hooks, skills, and MCP servers.

### How do I set up Claude Code?

Install via npm: `npm install -g @anthropic-ai/claude-code`. Create a `CLAUDE.md` file in your project root with project-specific instructions. Optionally add hooks in `.claude/hooks/` for automation, skills in `~/.claude/skills/` for reusable workflows, and MCP servers for database/API access. Our template provides all these pre-configured.

### What are Claude Code hooks?

Hooks are shell scripts that run automatically at specific points in the Claude Code lifecycle. There are 14 hook events (PreToolUse, PostToolUse, SessionStart, SessionEnd, etc.) that can validate inputs, block dangerous operations, auto-format code, and run background analytics. See our [Complete Hooks Guide](docs/guide/13-claude-code-hooks.md).

### What is MCP integration?

MCP (Model Context Protocol) extends Claude Code with external tools. Connect to PostgreSQL databases, GitHub repositories, memory systems, and APIs. This guide covers 13 MCP servers with 70+ tools including PostgreSQL, GitHub, Perplexity, Playwright, and Basic Memory for persistent knowledge storage.

### How do Claude Code skills work?

Skills are Markdown files with YAML frontmatter (`name:` and `description:` with "Use when..." clause). Claude Code natively discovers all skills from `~/.claude/skills/` and matches them to queries using the description field. No custom hooks needed -- skills are built into Claude Code. Our system runs **226+ production skills** with native activation.

### What is the memory bank?

The memory bank is a hierarchical knowledge system using a 4-tier structure: always (auto-loaded), learned (patterns), ondemand (blueprints), and reference (archives). It stores project context, decisions, and patterns for efficient token usage. Properly configured, it provides **34-62% token reduction** while maintaining full context access.

### How much time does this save?

Based on production metrics: **100+ hours per year** in developer time. Key achievements include 370x hook optimization (38s→103ms), 47-70% token savings per branch, 88.2% skill activation accuracy, and 80%+ research cost savings with Perplexity caching. ROI scales with project complexity.

---

## Core Documentation

### Getting Started

- [Quick Start Guide](docs/quick-start.md) - 30-minute basic setup
- [Minimal Setup](docs/guide/02-minimal-setup.md) - Essential configuration
- [Interactive Checklist](web/index.html) - Track your progress

### Claude Code Hooks

- [Claude Code Hooks](docs/guide/13-claude-code-hooks.md) - 14 hook events
- [Git vs Claude Hooks](docs/guide/14-git-vs-claude-hooks-distinction.md) - Clear distinction
- [Pre-Prompt Hook Guide](docs/pre-prompt-hook-complete-guide.md) - Historical reference (deprecated Feb 2026)

### Skills System

- [Skill Activation System](docs/skill-activation-system.md) - 162+ production skills
- [Skill Detection Enhancement](docs/guide/17-skill-detection-enhancement.md) - 100% accuracy
- [Skills Filtering Optimization](docs/guide/20-skills-filtering-optimization.md) - 93% noise reduction
- [Skill Keyword Enhancement](docs/guide/24-skill-keyword-enhancement-methodology.md) - 20+ patterns

### MCP Integration

- [MCP Integration Guide](docs/guide/06-mcp-integration.md) - PostgreSQL, GitHub, Memory
- [Basic Memory MCP](docs/guide/34-basic-memory-mcp-integration.md) - Semantic knowledge
- [Perplexity Cost Optimization](docs/guide/18-perplexity-cost-optimization.md) - 80%+ savings
- [Playwright E2E Testing](docs/guide/19-playwright-e2e-testing.md) - Browser automation

### Context Optimization

- [Memory Bank Hierarchy](docs/guide/12-memory-bank-hierarchy.md) - 4-tier structure
- [Branch Context System](docs/guide/29-branch-context-system.md) - **47-70% token savings**
- [Branch-Specific Skills](docs/guide/33-branch-specific-skill-curation.md) - Two-tier display
- [Pre-Prompt Optimization](docs/guide/21-pre-prompt-optimization.md) - Historical (deprecated)

### Best Practices

- [Claude Code Rules System](docs/guide/26-claude-code-rules-system.md) - `.claude/rules/`
- [Best Practices Reference](docs/guide/25-best-practices-reference.md) - 33 Anthropic articles
- [Skill Optimization Patterns](docs/guide/28-skill-optimization-patterns.md) - Advanced patterns
- [Skill Optimization Maintenance](docs/guide/35-skill-optimization-maintenance.md) - 6-step workflow

### Agents & Teams

- [Agents and Subagents](docs/guide/36-agents-and-subagents.md) - Create and configure custom agents
- [Agent Teams](docs/guide/37-agent-teams.md) - Coordinate parallel agent teammates (experimental)

---

## Repository Structure

```
claude-code-guide/
├── docs/                    # Complete documentation
│   ├── quick-start.md      # 30-minute setup
│   ├── pre-prompt-hook-complete-guide.md  # Historical (deprecated)
│   ├── skill-activation-system.md
│   └── guide/              # 37+ detailed guides
├── template/                # Clone-and-go starter
│   ├── .claude/            # Pre-configured setup
│   │   ├── CLAUDE.md       # Project context
│   │   ├── hooks/          # 4 automation scripts
│   │   ├── rules/          # Path-specific rules
│   │   └── skills/         # Starter skills
│   └── memory-bank/        # Knowledge hierarchy
├── skills-library/          # 20+ proven workflows
├── mcp-configs/             # MCP server configs
├── scripts/                 # Setup & validation
├── examples/                # Real-world examples
└── web/                     # Interactive checklist
```

---

## Phased Implementation

### Phase 0: Minimal (30 min)

- CLAUDE.md + core patterns
- 3 starter skills
- GitHub MCP only
- **Value**: Consistent responses, safe operations

### Phase 1: Essential (Week 1)

- Skills library (native activation)
- Memory Bank MCP
- 5 troubleshooting skills
- Perplexity with caching
- **Value**: 3x faster debugging, 80%+ research savings

### Phase 2: Productive (Week 2-3)

- PostgreSQL MCP (database visibility)
- Playwright MCP (E2E testing)
- Branch context system
- 8 workflow skills
- **Value**: 47-70% token savings, full automation

### Phase 3: Advanced (Month 2+)

- Custom MCP servers
- 20-30 skill library
- Complete memory bank
- Monthly maintenance
- **Value**: 100+ hours/year saved

---

## Key Features

- **Claude Code Setup**: Complete project configuration with templates
- **Claude Code Hooks**: 14 hook events for workflow automation
- **Claude Code Skills**: 226+ production-tested patterns (native loading)
- **Claude Code MCP**: 13 servers, 70+ tools integrated
- **Context Optimization**: 47-70% token savings per branch
- **Best Practices**: Anthropic-aligned patterns from production

---

## Related Projects

- **[AI Intelligence Hub](https://github.com/ytrofr/ai-intelligence-hub)** — Track 12 AI sources (GitHub, HuggingFace, MCP, Claude Code) with full-text search. Port 4444.

---

## What Makes This Different

| Aspect                | This Guide                       |
| --------------------- | -------------------------------- |
| **Production-Tested** | 226+ patterns from real systems  |
| **Evidence-Based**    | Every claim backed by metrics    |
| **Team-Ready**        | Shared vs personal configuration |
| **Phased Approach**   | Value in 30 minutes              |
| **Validation-First**  | Scripts catch 90% of mistakes    |

---

## Credits

**Source Project**: Production system (97 components)
**Research**: Anthropic Claude 4 Best Practices + Sionic AI Skills Framework
**Marketplace**: [wshobson/agents](https://github.com/wshobson/agents) - 273 components
**Official Docs**: [code.claude.com/docs](https://code.claude.com/docs/en/memory)
**Created**: December 2024
**Updated**: February 2026

---

## License

MIT License - See [LICENSE](LICENSE)

---

## Quick Links

**Getting Started**

- [Quick Start Guide](docs/quick-start.md)
- [Skills System](docs/skill-activation-system.md)
- [Template Repository](template/)

**Core Systems**

- [Skills Library](skills-library/)
- [MCP Configs](mcp-configs/)
- [Interactive Checklist](web/index.html)

**Advanced Topics**

- [Branch Context System](docs/guide/29-branch-context-system.md)
- [Rules System](docs/guide/26-claude-code-rules-system.md)
- [Complete Guide Index](docs/guide/)

---

_Built with lessons from 14+ months of production Claude Code usage._
