---
name: basic-memory-semantic-patterns-skill
description: "Write Basic Memory notes with semantic observations and relations. Use when creating notes, querying past decisions, finding how we fixed bugs, or loading pattern context."
Triggers: semantic observations, basic memory format, write note properly, relations format, memory url, decision technique issue, implements requires extends, wikilink format, build context memory, what did we decide, how did we fix, past decision, similar bug, seen this before, pattern for, show patterns, recent activity, document this, fix before, bug before, seen before, document fix, write note, fixed before, previous fix, past fix, check memory, query memory, search memory, memory search
---

# Basic Memory Semantic Patterns Skill

**Purpose**: Consistent semantic observation and relation patterns for Basic Memory MCP
**Guide**: [Guide 34 - Basic Memory MCP Integration](../../../docs/guide/34-basic-memory-mcp-integration.md)
**ROI**: 30-50 hours/year knowledge retrieval savings

---

## Quick Start - Writing Notes

```markdown
# Note Title

Content describing the topic.

## Observations

- [decision] What was decided #category
- [technique] How something works #category
- [issue] Problem that was found #category
- [requirement] What must be done #category
- [lesson] What was learned #category

## Relations

- implements [[Other Note]]
- requires [[Dependency Note]]
- extends [[Parent Concept]]
- pairs_with [[Related Note]]
- part_of [[Larger System]]
```

---

## Observation Types

| Type          | When to Use                    | Example                                      |
| ------------- | ------------------------------ | -------------------------------------------- |
| `[decision]`  | Architecture/design choices    | `[decision] Use pgvector for embeddings #ai` |
| `[technique]` | Implementation patterns        | `[technique] Async pool initialization #db`  |
| `[issue]`     | Bugs, problems found           | `[issue] NULL values break ON CONFLICT #sql` |
| `[requirement]` | Must-have constraints        | `[requirement] UTF-8 for Hebrew #i18n`       |
| `[lesson]`    | Learnings, best practices      | `[lesson] Check existing before building`    |

---

## Relation Types

| Relation      | When to Use                    | Example                              |
| ------------- | ------------------------------ | ------------------------------------ |
| `implements`  | Pattern realizes concept       | `implements [[Golden Rule]]`         |
| `requires`    | Dependency relationship        | `requires [[Database Connection]]`   |
| `extends`     | Builds on existing             | `extends [[Base Pattern]]`           |
| `pairs_with`  | Works together                 | `pairs_with [[Error Handling]]`      |
| `part_of`     | Component of larger system     | `part_of [[Authentication System]]`  |

---

## Common MCP Commands

```javascript
// Search for past decisions
mcp__basic-memory__search_notes({ query: "decision database" })

// Load all patterns
mcp__basic-memory__build_context({ url: "memory://patterns/*" })

// Check recent activity
mcp__basic-memory__recent_activity({ timeframe: "7d" })

// Write a new note
mcp__basic-memory__write_note({
  title: "Note Title",
  content: "## Observations\n\n- [decision] ...",
  folder: "patterns"
})

// Read specific note
mcp__basic-memory__read_note({ identifier: "Note Title" })
```

---

## Folder Organization

```
~/basic-memory/
├── patterns/          # Reusable implementation patterns
├── fixes/             # Production fixes and debugging
├── decisions/         # Architecture decisions
├── research-cache/    # Perplexity search results
├── session-summaries/ # End-of-session documentation
└── [domain]/          # Domain-specific patterns
```

---

## When to Document

| Trigger                    | Action                                      |
| -------------------------- | ------------------------------------------- |
| Made architecture decision | Write note with `[decision]` observation    |
| Fixed a bug                | Write note with `[technique]` + `[issue]`   |
| Learned something new      | Write note with `[lesson]` observation      |
| End of complex session     | Write session summary with key observations |
| Found reusable pattern     | Write to patterns/ folder                   |

---

## Memory URLs

```yaml
FORMATS:
  Single_Note: "memory://folder/note-title"
  All_In_Folder: "memory://folder/*"
  Wildcard: "memory://*/pattern-name"

EXAMPLES:
  - "memory://patterns/*"           # All patterns
  - "memory://fixes/*"              # All fixes
  - "memory://decisions/database"   # Specific decision
```

---

## Installation

1. Copy this skill to `~/.claude/skills/basic-memory-semantic-patterns-skill/SKILL.md`
2. Copy the rules file to `.claude/rules/mcp/memory-usage.md`
3. Add Basic Memory section to session-start hook (optional)
4. Rebuild skill cache: `rm ~/.claude/cache/skill-index-hybrid.txt`

---

**Related Skills**: perplexity-memory-enforcement-skill
**Related Rules**: `.claude/rules/mcp/memory-usage.md`
**Guide**: [34-basic-memory-mcp-integration.md](../../../docs/guide/34-basic-memory-mcp-integration.md)
