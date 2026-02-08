---
title: Perplexity Cache-First Workflow
category: workflows
triggers:
  - "perplexity"
  - "search research"
  - "web search"
  - "look up"
  - "research cache"
  - "cost optimization"
activation_rate: 84%
time_savings: "80%+ cost reduction"
---

# Perplexity Cache-First Skill

**Purpose**: Always check Memory MCP cache before using Perplexity to save costs
**Trigger**: Any Perplexity search request
**ROI**: $0.005 per cached query, 80%+ budget savings

---

## Quick Reference

```yaml
BEFORE_PERPLEXITY:
  1. Check cache: mcp__basic-memory__search_notes("topic")
  2. If found: USE CACHED RESULT (FREE!)
  3. If not found: Continue to Perplexity

AFTER_PERPLEXITY:
  IMMEDIATELY cache: mcp__basic-memory__write_note(
    title: "topic-summary",
    folder: "research-cache",
    content: [Perplexity results + sources]
  )
```

---

## The Workflow

### Step 1: Check Cache First (MANDATORY)

```python
# Always do this BEFORE any Perplexity search
result = mcp__basic-memory__search_notes("your search topic")
```

**If found**: STOP! Use the cached result. No Perplexity needed.

### Step 2: Use Perplexity (only on cache miss)

```python
# Only if Step 1 returned no results
perplexity_result = mcp__perplexity__search(query="your detailed question")
```

### Step 3: Cache Results (MANDATORY)

```python
# Immediately after Perplexity search
mcp__basic-memory__write_note(
    title="descriptive-topic-name",
    folder="research-cache",
    content="""
# Research: [Topic]
**Searched**: [Date]
**Query**: [Your query]

## Summary
[Key findings from Perplexity]

## Sources
[URLs from response]
"""
)
```

---

## Common Mistakes

| ❌ Wrong | ✅ Correct |
|----------|------------|
| Skip cache check, go straight to Perplexity | Always check cache first |
| Forget to cache results after search | Cache IMMEDIATELY after every search |
| Use vague cache titles | Use descriptive, searchable titles |
| Cache in project folder | Cache in global `research-cache/` |

---

## Cache Title Examples

| Topic | Good Title |
|-------|------------|
| React 19 | `react-19-features-2025` |
| Claude hooks | `claude-code-hooks-setup` |
| PostgreSQL | `postgresql-performance-tips` |
| Node.js | `nodejs-async-patterns` |

---

## Validation

**Test Cache Miss**:
1. Search for topic not in cache
2. Perplexity should be used
3. Results should be cached

**Test Cache Hit**:
1. Search for same topic
2. Cache should be found
3. Perplexity should NOT be called

---

## Cost Impact

| Scenario | Cost |
|----------|------|
| Direct Perplexity (no caching) | $0.005/query |
| Cached query | $0.00 |
| Expected savings | 80%+ |

---

## Related

- [Chapter 18: Perplexity Cost Optimization](../../../docs/guide/18-perplexity-cost-optimization.md)
- [MCP Integration](../../../docs/guide/06-mcp-integration.md)

---

**Skill Authority**: Mandatory workflow for Perplexity cost optimization
**Activation**: Before any web search / research request
**Evidence**: Production research-cache with 10+ validated cached results
