# Claude Code Guide

> **The complete guide to Claude Code setup, skills, hooks, and MCP integration.**

[![GitHub stars](https://img.shields.io/github/stars/ytrofr/claude-code-guide?style=social)](https://github.com/ytrofr/claude-code-guide)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE.md)
[![Documentation](https://img.shields.io/badge/docs-GitHub%20Pages-blue)](https://ytrofr.github.io/claude-code-guide)

Production-tested Claude Code patterns. 162+ documented patterns, 100+ hours saved per year.

---

## Why This Guide?

| Metric            | Result                    |
| ----------------- | ------------------------- |
| Time Saved        | **100+ hours/year**       |
| Hook Optimization | **370x faster**           |
| Skill Activation  | **88.2% accuracy**        |
| Token Savings     | **47-70% per branch**     |
| Production Skills | **162+ documented**       |
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

# 3. Set up pre-prompt hook (370x optimization)
cp template/.claude/hooks/pre-prompt.sh .claude/hooks/
chmod +x .claude/hooks/pre-prompt.sh

# 4. Configure MCP servers
cp .claude/mcp_servers.json.template .claude/mcp_servers.json
# Add your GitHub token

# 5. Start Claude Code
claude
```

**Detailed walkthrough**: [Quick Start Guide](docs/quick-start.md) | [Pre-Prompt Hook Guide](docs/pre-prompt-hook-complete-guide.md)

---

## Frequently Asked Questions

### What is Claude Code?

Claude Code is Anthropic's official CLI for AI-powered coding assistance. It provides an interactive terminal experience where Claude can read files, write code, run commands, and help with development tasks. Claude Code understands your project context through CLAUDE.md files and can be extended with hooks, skills, and MCP servers.

### How do I set up Claude Code?

Install via npm: `npm install -g @anthropic-ai/claude-code`. Create a `CLAUDE.md` file in your project root with project-specific instructions. Optionally add hooks in `.claude/hooks/` for automation, skills in `~/.claude/skills/` for reusable workflows, and MCP servers for database/API access. Our template provides all these pre-configured.

### What are Claude Code hooks?

Hooks are shell scripts that run automatically at specific points in the Claude Code lifecycle. The pre-prompt hook runs before every message (skill activation, context injection). Other hooks include session-start, pre-compact, and stop hooks. We achieved **370x performance improvement** with optimized pre-prompt hooks—from 38 seconds to 103ms.

### What is MCP integration?

MCP (Model Context Protocol) extends Claude Code with external tools. Connect to PostgreSQL databases, GitHub repositories, memory systems, and APIs. This guide covers 13 MCP servers with 70+ tools including PostgreSQL, GitHub, Perplexity, Playwright, and Basic Memory for persistent knowledge storage.

### How do Claude Code skills work?

Skills are Markdown files with YAML frontmatter containing triggers, keywords, and instructions. When your query matches skill triggers, the pre-prompt hook injects relevant skills into context. Skills use keyword matching, regex patterns, and semantic detection. Our system achieves **88.2% activation accuracy** with 162+ production skills.

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

- [Pre-Prompt Hook Complete Guide](docs/pre-prompt-hook-complete-guide.md) - **370x optimization**
- [Claude Code Hooks](docs/guide/13-claude-code-hooks.md) - 8 hook types
- [Git vs Claude Hooks](docs/guide/14-git-vs-claude-hooks-distinction.md) - Clear distinction

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
- [Pre-Prompt Optimization](docs/guide/21-pre-prompt-optimization.md) - 68% reduction

### Best Practices

- [Claude Code Rules System](docs/guide/26-claude-code-rules-system.md) - `.claude/rules/`
- [Best Practices Reference](docs/guide/25-best-practices-reference.md) - 33 Anthropic articles
- [Skill Optimization Patterns](docs/guide/28-skill-optimization-patterns.md) - Advanced patterns
- [Skill Optimization Maintenance](docs/guide/35-skill-optimization-maintenance.md) - 6-step workflow

---

## Repository Structure

```
claude-code-guide/
├── docs/                    # Complete documentation
│   ├── quick-start.md      # 30-minute setup
│   ├── pre-prompt-hook-complete-guide.md  # 370x optimization
│   ├── skill-activation-system.md
│   └── guide/              # 35+ detailed guides
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

- Pre-prompt hook (84% activation)
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
- **Claude Code Hooks**: 8 hook types for workflow automation
- **Claude Code Skills**: 162+ production-tested patterns
- **Claude Code MCP**: 13 servers, 70+ tools integrated
- **Context Optimization**: 47-70% token savings per branch
- **Best Practices**: Anthropic-aligned patterns from production

---

## What Makes This Different

| Aspect                | This Guide                       |
| --------------------- | -------------------------------- |
| **Production-Tested** | 162+ patterns from real systems  |
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

MIT License - See [LICENSE.md](LICENSE.md)

---

## Quick Links

**Getting Started**

- [Quick Start Guide](docs/quick-start.md)
- [Pre-Prompt Hook Guide](docs/pre-prompt-hook-complete-guide.md)
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
