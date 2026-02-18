# Chapter 18: MCP Cost Control — Perplexity Cache-First with Hook Enforcement

**Purpose**: Reduce Perplexity MCP costs by 80%+ using cache-first pattern enforced by hooks
**Prerequisites**: Perplexity MCP configured, Basic Memory MCP installed
**Time to Implement**: 15 minutes
**ROI**: $0.005 per cached query (80%+ budget savings on repeat topics)
**Updated**: February 2026 — Added PreToolUse/PostToolUse hook enforcement

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

| Topic                   | Cache Title                     |
| ----------------------- | ------------------------------- |
| React 19 features       | `react-19-features-2025`        |
| Claude Code hooks       | `claude-code-hooks-guide`       |
| PostgreSQL optimization | `postgresql-query-optimization` |
| Node.js best practices  | `nodejs-best-practices-2025`    |

---

## Cost Analysis

### Without Caching

| Searches/Month | Cost  |
| -------------- | ----- |
| 100            | $0.50 |
| 500            | $2.50 |
| 1000           | $5.00 |

### With Cache-First (80% hit rate)

| Searches/Month | Actual Queries | Cost  |
| -------------- | -------------- | ----- |
| 100            | 20             | $0.10 |
| 500            | 100            | $0.50 |
| 1000           | 200            | $1.00 |

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

_Cost: $0.01+ and growing_

**With caching** (new way):

```
User: "How do Claude Code hooks work?"
Claude: [Checks cache] → Found 'claude-code-hooks-guide' → FREE!
...(next week)...
User: "What hook types are available?"
Claude: [Checks same cache] → Same note → FREE!
```

_Cost: $0.005 (one-time) + $0.00 (all future)_

---

## Hook Enforcement: The Two-Hook Sandwich

Rules in CLAUDE.md are soft — Claude may ignore them under context pressure. Hooks are hard enforcement that fires automatically. The pattern uses two hooks to wrap every Perplexity call:

```
PreToolUse  → "Check cache first!"  → fires BEFORE Perplexity
                    ↓
            Perplexity executes
                    ↓
PostToolUse → "Cache this result!"  → fires AFTER Perplexity
```

### PreToolUse Hook: Cache Check Reminder

Create `~/.claude/hooks/perplexity-cache-check.sh`:

```bash
#!/bin/bash
# PreToolUse hook: Enforce cache-first before Perplexity calls

JSON_INPUT=$(timeout 2 cat 2>/dev/null || true)

QUERY=$(echo "$JSON_INPUT" | jq -r \
  '.tool_input.query // .tool_input.prompt // .tool_input.topic // "unknown topic"' \
  2>/dev/null || echo "unknown topic")

echo ""
echo "======================================================================="
echo "PERPLEXITY CACHE-FIRST CHECK"
echo "======================================================================="
echo ""
echo "Before calling Perplexity, you MUST check Basic Memory cache:"
echo ""
echo "  mcp__basic-memory__search_notes(query=\"$QUERY\")"
echo ""
echo "If cached result found -> Use it (FREE) and SKIP this Perplexity call."
echo "If not found -> Proceed with Perplexity, then cache the result after."
echo ""
echo "Cost: Each Perplexity call = \$0.005-\$0.02"
echo "Budget: \$5/month (~1000 searches max)"
echo "======================================================================="

exit 0
```

Key details:

- Uses `$(timeout 2 cat)` to safely read stdin (prevents infinite hang)
- Extracts the query text from the tool input JSON for a targeted reminder
- Always exits 0 (reminds, doesn't block)
- Uses `jq` with fallback chain (`query // prompt // topic`) to handle all Perplexity tools

### PostToolUse Hook: Cache Reminder

Create `~/.claude/hooks/perplexity-cache-reminder.sh`:

```bash
#!/bin/bash
# PostToolUse hook: Remind to cache Perplexity research in Memory MCP

timeout 2 cat > /dev/null 2>&1 || true

echo ""
echo "======================================================================="
echo "PERPLEXITY CACHE REMINDER"
echo "======================================================================="
echo ""
echo "You just used Perplexity (cost: \$0.005+). CACHE THIS RESEARCH!"
echo ""
echo "  mcp__basic-memory__write_note("
echo "    title: \"[Topic] - Research Summary\","
echo "    folder: \"research-cache\","
echo "    content: \"[Key findings + sources]\""
echo "  )"
echo "======================================================================="

exit 0
```

### Register in settings.json

Add to `~/.claude/settings.json` (user-level = applies to ALL projects):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "mcp__perplexity__search|mcp__perplexity__reason|mcp__perplexity__deep_research|mcp__perplexity__perplexity_search|mcp__perplexity__perplexity_reason|mcp__perplexity__perplexity_research|mcp__perplexity__perplexity_ask",
        "hooks": [
          {
            "type": "command",
            "command": "/home/you/.claude/hooks/perplexity-cache-check.sh",
            "statusMessage": "Checking research cache..."
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "mcp__perplexity__search|mcp__perplexity__reason|mcp__perplexity__deep_research|mcp__perplexity__perplexity_search|mcp__perplexity__perplexity_reason|mcp__perplexity__perplexity_research|mcp__perplexity__perplexity_ask",
        "hooks": [
          {
            "type": "command",
            "command": "/home/you/.claude/hooks/perplexity-cache-reminder.sh",
            "statusMessage": "Perplexity cache reminder..."
          }
        ]
      }
    ]
  }
}
```

**Why user-level, not project-level?** Perplexity costs apply across ALL your projects. Placing hooks in `~/.claude/settings.json` means every project gets the cache-first enforcement without needing per-project configuration.

> **Gotcha: MCP tool names vary by package.** Different Perplexity MCP packages expose different tool names. For example, one package uses `mcp__perplexity__search` while another uses `mcp__perplexity__perplexity_search`. The matcher must cover **all variants** across your projects. Run `/context` in each project to see the actual tool names, then include all of them in the matcher pipe (`|`) list.

### The MCP Cost Control Pattern (Generalizable)

This two-hook sandwich works for any paid MCP tool:

| MCP Tool          | PreToolUse        | PostToolUse        |
| ----------------- | ----------------- | ------------------ |
| Perplexity        | Check cache first | Cache the result   |
| Any paid API      | Rate limit check  | Log usage/cost     |
| External services | Validate need     | Record for billing |

The pattern: **PreToolUse = gate, PostToolUse = capture**.

---

## Validation Checklist

- [ ] Perplexity MCP configured and working
- [ ] Basic Memory MCP configured and working
- [ ] `research-cache/` folder created
- [ ] Cache-first rule added to CLAUDE.md
- [ ] PreToolUse hook script created and executable (`chmod +x`)
- [ ] PostToolUse hook script created and executable (`chmod +x`)
- [ ] Both hooks registered in `~/.claude/settings.json`
- [ ] Test: Cache miss → Perplexity → Cache write
- [ ] Test: Cache hit → No Perplexity call

---

## Related Resources

- [Claude Code Hooks](13-claude-code-hooks.md) - Hook event reference and configuration
- [MCP Integration Guide](06-mcp-integration.md) - Setting up MCPs
- [Memory Bank Hierarchy](12-memory-bank-hierarchy.md) - Knowledge organization
- [Context Costs and Skill Budget](38-context-costs-and-skill-budget.md) - Understanding context economics

---

## Evidence

**Source Project**: Production system with 640+ cached research notes
**Validation**: `research-cache/` folder with cached results, zero duplicate Perplexity calls
**Pattern**: CLAUDE.md rule + hook enforcement (3-layer: rule, PreToolUse gate, PostToolUse capture)
**Enforcement**: Two-hook sandwich — PreToolUse reminds to check cache, PostToolUse reminds to write cache

---

**Cost Optimization Authority**: Proven pattern for 80%+ Perplexity cost reduction
**Usage**: Implement on any project using Perplexity MCP. Place hooks in `~/.claude/settings.json` for global enforcement.
**Created**: December 2025
**Updated**: February 2026 — Hook enforcement added
