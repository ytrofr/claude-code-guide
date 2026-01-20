# Basic Memory Semantic Patterns Skill

**Category**: Workflows
**Guide**: [Guide 34 - Basic Memory MCP Integration](../../../docs/guide/34-basic-memory-mcp-integration.md)

## Overview

This skill provides consistent patterns for using the Basic Memory MCP server with semantic observations and relations. It enables:

- Writing notes with structured observations (`[decision]`, `[technique]`, `[issue]`, `[lesson]`)
- Creating semantic relations between notes (`implements`, `requires`, `extends`)
- Querying past decisions and fixes efficiently
- Building context from memory URLs

## ROI

- **Time Savings**: 30-50 hours/year in knowledge retrieval
- **Knowledge Retention**: 90%+ pattern recall rate
- **Context Recovery**: Instant access to past decisions

## Prerequisites

- Basic Memory MCP server configured in `~/.claude/settings.json`
- `~/basic-memory/` directory created

## Installation

1. Copy `SKILL.md` to `~/.claude/skills/basic-memory-semantic-patterns-skill/`
2. Copy rules file to `.claude/rules/mcp/memory-usage.md`
3. Rebuild cache: `rm ~/.claude/cache/skill-index-hybrid.txt`

## Usage

The skill activates automatically when you:
- Ask about past decisions ("what did we decide about...")
- Search for previous fixes ("how did we fix...")
- Request pattern information ("show patterns for...")
- Want to document work ("document this fix")

## Files Included

- `SKILL.md` - Main skill file with all patterns
- Rules template at `template/.claude/rules/mcp/memory-usage.md`

## Related

- [Guide 34 - Basic Memory MCP Integration](../../../docs/guide/34-basic-memory-mcp-integration.md)
- [perplexity-cache-skill](../perplexity-cache-skill/) - Works with memory caching
