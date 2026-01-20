# Basic Memory Usage Rules

**Authority**: Proactive knowledge retrieval patterns
**Guide**: [Guide 34 - Basic Memory MCP Integration](../../../docs/guide/34-basic-memory-mcp-integration.md)
**Enforcement**: ALWAYS use for past decisions, fixes, patterns

---

## Proactive Memory Triggers

**MUST use Basic Memory MCP when these patterns detected:**

```yaml
QUERY_PATTERNS:
  Past_Decisions:
    Trigger: "what did we decide", "why did we", "previous decision"
    Action: mcp__basic-memory__search_notes(query="topic decision")

  Past_Fixes:
    Trigger: "how did we fix", "similar bug", "seen this before"
    Action: mcp__basic-memory__build_context(url="memory://fixes/*")

  Patterns:
    Trigger: "pattern for", "best practice", "how to implement"
    Action: mcp__basic-memory__build_context(url="memory://patterns/*")

  Recent_Context:
    Trigger: new session, complex task, "what were we working on"
    Action: mcp__basic-memory__recent_activity(timeframe="7d")

  Research:
    Trigger: "documentation for", "how does X work"
    Action: mcp__basic-memory__search_notes(query="topic") BEFORE Perplexity
```

---

## Post-Work Documentation

**SHOULD document after completing work:**

```yaml
AFTER_DECISIONS:
  Format: '[decision] What was decided #category'
  Folder: decisions/ or relevant domain folder
  Example: '[decision] Use Cloud Scheduler not in-process crons #deployment'

AFTER_FIXES:
  Format: '[technique] How it was fixed #category'
  Folder: fixes/ or production-fixes/
  Example: '[technique] Add ::date cast for timezone-safe SQL #database'

AFTER_BUGS:
  Format: '[issue] What the problem was #category'
  Folder: fixes/ or bugs/
  Example: '[issue] ID confusion causes 0 employees bug #sacred-i'

AFTER_LEARNING:
  Format: '[lesson] What was learned #category'
  Folder: patterns/ or learned/
  Example: '[lesson] Check existing before building - saves 1h+ #best-practice'
```

---

## Key Memory Folders

| Folder               | Purpose                     | When to Query          |
| -------------------- | --------------------------- | ---------------------- |
| `fixes/`             | Production fixes            | Bug investigation      |
| `patterns/`          | Reusable patterns           | Implementation         |
| `decisions/`         | Architecture decisions      | Design questions       |
| `research-cache/`    | Perplexity results          | Before external search |
| `session-summaries/` | Session history             | Context recovery       |

---

## Quick Commands

```bash
# Search for past decisions
mcp__basic-memory__search_notes(query="decision topic")

# Get recent patterns
mcp__basic-memory__build_context(url="memory://patterns/*", timeframe="30d")

# Check recent activity
mcp__basic-memory__recent_activity(timeframe="7d")

# Read specific note
mcp__basic-memory__read_note(identifier="Note Title")
```

---

**Related**: basic-memory-semantic-patterns-skill
