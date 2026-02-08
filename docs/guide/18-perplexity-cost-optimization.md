# Chapter 18: Perplexity Cost Optimization

**Purpose**: Reduce Perplexity MCP costs by 80%+ using cache-first pattern
**Prerequisites**: Perplexity MCP configured, Basic Memory MCP installed
**Time to Implement**: 15 minutes
**ROI**: $0.005 per cached query (80%+ budget savings on repeat topics)

---

## The Problem

Perplexity MCP charges $0.005 per query (~$5/month budget). Without caching:
- Same research topics are searched repeatedly
- Budget depletes quickly on common queries
- No institutional memory of research results

## The Solution: Cache-First Pattern

**Before ANY Perplexity search**:
1. Check Memory MCP cache first (`mcp__basic-memory__search_notes("topic")`)
2. If found → Use cached result (FREE!)
3. If not found → Use Perplexity, then IMMEDIATELY cache results

---

## Setup

### 1. Configure Both MCPs

**In `.mcp.json` or `.claude/mcp_servers.json`**:

```json
{
  "mcpServers": {
    "perplexity": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "perplexity-mcp"],
      "env": {
        "PERPLEXITY_API_KEY": "${PERPLEXITY_API_KEY}"
      }
    },
    "basic-memory": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@anthropics/mcp-server-basic-memory"],
      "env": {
        "MEMORY_PATH": "~/basic-memory"
      }
    }
  }
}
```

### 2. Create Research Cache Folder

The cache should be global (available across all projects):

```bash
mkdir -p ~/basic-memory/research-cache
```

### 3. Add Cache-First Rule to CLAUDE.md

Add this to your project's `CLAUDE.md` Critical Rules section:

```yaml
### Perplexity Cache-First Rule
PATTERN: "ALWAYS check Memory MCP before Perplexity"
BEFORE_SEARCH: "mcp__basic-memory__search_notes('topic')"
IF_FOUND: "Use cached result (FREE!)"
IF_NOT_FOUND: "Use Perplexity, then cache with mcp__basic-memory__write_note(folder='research-cache')"
ROI: "$0.005 per cached query, 80%+ savings"
```

---

## The Workflow

### Step 1: Check Cache First

```python
# Before any Perplexity search
mcp__basic-memory__search_notes("topic keywords")
```

If results found → **STOP! Use the cached result.**

### Step 2: Only Then Use Perplexity

```python
# Only if cache miss
mcp__perplexity__search(query="your research question")
```

### Step 3: Immediately Cache Results

```python
# RIGHT AFTER every Perplexity search
mcp__basic-memory__write_note(
    title="Topic Keywords Summary",
    content="""# Research: [Topic]
**Source**: Perplexity search
**Date**: [Today's date]
**Query**: [What you searched for]

## Key Findings
- Finding 1
- Finding 2
- Finding 3

## Sources
- [List sources from Perplexity response]
""",
    folder="research-cache"
)
```

---

## Naming Convention for Cache Notes

Use descriptive, searchable titles:

| Topic | Cache Title |
|-------|------------|
| React 19 features | `react-19-features-2025` |
| Claude Code hooks | `claude-code-hooks-guide` |
| PostgreSQL optimization | `postgresql-query-optimization` |
| Node.js best practices | `nodejs-best-practices-2025` |

---

## Cost Analysis

### Without Caching
| Searches/Month | Cost |
|----------------|------|
| 100 | $0.50 |
| 500 | $2.50 |
| 1000 | $5.00 |

### With Cache-First (80% hit rate)
| Searches/Month | Actual Queries | Cost |
|----------------|----------------|------|
| 100 | 20 | $0.10 |
| 500 | 100 | $0.50 |
| 1000 | 200 | $1.00 |

**Savings**: 80% cost reduction

---

## Example: Research Cache in Action

**Scenario**: You need to look up "Claude Code hooks" for the 5th time this month.

**Without caching** (old way):
```
User: "How do Claude Code hooks work?"
Claude: [Uses Perplexity] → $0.005
...(next week)...
User: "What hook types are available?"
Claude: [Uses Perplexity again] → $0.005
```
*Cost: $0.01+ and growing*

**With caching** (new way):
```
User: "How do Claude Code hooks work?"
Claude: [Checks cache] → Found 'claude-code-hooks-guide' → FREE!
...(next week)...
User: "What hook types are available?"
Claude: [Checks same cache] → Same note → FREE!
```
*Cost: $0.005 (one-time) + $0.00 (all future)*

---

## Validation Checklist

- [ ] Perplexity MCP configured and working
- [ ] Basic Memory MCP configured and working
- [ ] `research-cache/` folder created
- [ ] Cache-first rule added to CLAUDE.md
- [ ] Test: Cache miss → Perplexity → Cache write
- [ ] Test: Cache hit → No Perplexity call

---

## Related Resources

- [MCP Integration Guide](06-mcp-integration.md) - Setting up MCPs
- [Memory Bank Hierarchy](12-memory-bank-hierarchy.md) - Knowledge organization
- [perplexity-cache-skill](../../skills-library/workflows/perplexity-cache-skill/SKILL.md) - Executable workflow

---

## Evidence

**Source Project**: Production production system
**Validation**: `research-cache/` folder with 10+ cached results
**Pattern**: Documented in CLAUDE.md as mandatory rule
**Enforcement**: PostToolUse hook reminder after every Perplexity call

---

**Cost Optimization Authority**: Proven pattern for 80%+ Perplexity cost reduction
**Usage**: Implement on any project using Perplexity MCP
**Created**: December 2025
