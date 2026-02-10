# 34. Basic Memory MCP Integration

**Evidence**: Entry #283 (Production), 36/36 tests passing, 30-50h/year ROI
**Created**: January 20, 2026
**Source**: Phase 9-10.5 Basic Memory optimization

---

## Overview

Basic Memory MCP provides persistent knowledge storage with semantic observations and relations. This guide covers how to maximize its value through:

1. **Semantic observation format** - Structured note-taking
2. **Relations** - Knowledge graph connections
3. **Session-start integration** - Automatic context loading
4. **Proactive triggers** - Rules and skills for consistent usage
5. **Folder organization** - Efficient structure

**ROI**: ~2 hours setup → 30-50 hours/year saved (no manual context searching)

---

## Problem Solved

Without proper integration, Basic Memory becomes a graveyard of notes that are never queried:

| Issue                                 | Impact                          |
| ------------------------------------- | ------------------------------- |
| Flat notes without semantic structure | AI can't extract patterns       |
| No proactive triggers                 | Memory never used               |
| Scattered folders                     | Hard to find relevant notes     |
| No session context                    | Start each session from scratch |

---

## Semantic Observation Format

### Observation Types

```markdown
## Observations

- [decision] Use Cloud Scheduler not in-process crons #deployment #sacred-xiii
- [technique] Natural key ON CONFLICT for upserts #database #sync
- [issue] Context lost between conversation turns #ai-quality #bug
- [requirement] 100% API-Database parity mandatory #sacred-xii #critical
- [lesson] Check existing before building (1+ hour saved) #best-practice
```

**Format**: `- [type] Description #category1 #category2`

### When to Use Each Type

| Type            | Use For                 | Example                               |
| --------------- | ----------------------- | ------------------------------------- |
| `[decision]`    | Choices made, rationale | "Use employee_id not record.id"       |
| `[technique]`   | Methods, patterns       | "SELECT current_database() first"     |
| `[issue]`       | Problems identified     | "ID confusion causes 0 employees bug" |
| `[requirement]` | Must-have specs         | "100% parity mandatory"               |
| `[lesson]`      | Learnings               | "Test locally before staging"         |

---

## Relations Format

### WikiLink Syntax

```markdown
## Relations

- implements [[Sacred Commandment XIV]]
- requires [[api-first-validation-skill]]
- extends [[gap-detection-and-sync-skill]]
- part_of [[P0 Stabilization]]
- pairs_with [[database-patterns-skill]]
```

**Format**: `- relation_type [[Note Title]]`

### Relation Types

| Relation     | Meaning                           | Use For          |
| ------------ | --------------------------------- | ---------------- |
| `implements` | This note implements that concept | Patterns → Rules |
| `requires`   | Must use this first               | Prerequisites    |
| `extends`    | Builds upon that pattern          | Enhancements     |
| `part_of`    | Belongs to larger system          | Hierarchy        |
| `pairs_with` | Works together with               | Companions       |
| `relates_to` | General connection                | Loose coupling   |

---

## Note Template

```markdown
---
title: '[Pattern/Decision Name]'
type: note
permalink: [folder]/[kebab-case-name]
tags:
- tag1
- tag2
---

# [Title]

**Source**: [Entry #X or origin]
**Date**: YYYY-MM-DD

## Summary

[1-2 sentence description]

## Observations

- [decision] [Key choice made] #category
- [technique] [Method used] #category
- [issue] [Problem identified] #category

## Relations

- implements [[Related Pattern]]
- requires [[Prerequisite Skill]]
- pairs_with [[Companion Pattern]]

## Details

[Main content here]

## Evidence

- Date: YYYY-MM-DD
- Result: [Concrete outcome]
```

---

## Session-Start Hook Integration

Add this section to `.claude/hooks/session-start.sh`:

```bash
# ═══════════════════════════════════════════════════════════════════
# BASIC MEMORY INTEGRATION
# Purpose: Surface recent observations and patterns for context
# ═══════════════════════════════════════════════════════════════════
echo ""
echo "═══ BASIC MEMORY CONTEXT ═══"

MEMORY_PATH="$HOME/basic-memory"

if [ -d "$MEMORY_PATH" ]; then
    # Count total notes and observations
    TOTAL_NOTES=$(find "$MEMORY_PATH" -name "*.md" -type f 2>/dev/null | wc -l)
    TOTAL_OBS=$(grep -r "^\- \[decision\]\|^\- \[technique\]\|^\- \[issue\]" "$MEMORY_PATH" 2>/dev/null | wc -l)
    TOTAL_REL=$(grep -r "implements \[\[\|requires \[\[\|extends \[\[" "$MEMORY_PATH" 2>/dev/null | wc -l)

    echo "📊 Notes: $TOTAL_NOTES | Observations: $TOTAL_OBS | Relations: $TOTAL_REL"

    # Recent activity (last 7 days)
    RECENT_NOTES=$(find "$MEMORY_PATH" -name "*.md" -type f -mtime -7 2>/dev/null | wc -l)
    echo "📅 Recent (7d): $RECENT_NOTES notes modified"

    # Show 5 most recently modified notes
    echo ""
    echo "📝 Recently modified:"
    find "$MEMORY_PATH" -name "*.md" -type f -mtime -7 -printf "%T@ %p\n" 2>/dev/null | \
        sort -rn | head -5 | cut -d' ' -f2- | \
        sed 's|.*/basic-memory/||' | sed 's|\.md$||' | sed 's|^|   • |'

    # Reminder for Claude to use build_context
    echo ""
    echo "💡 Use: mcp__basic-memory__build_context(url=\"memory://folder/*\")"
else
    echo "⚠️  Basic Memory not found at $MEMORY_PATH"
fi
```

### Output Example

```
═══ BASIC MEMORY CONTEXT ═══
📊 Notes: 459 | Observations: 44 | Relations: 35
📅 Recent (7d): 76 notes modified

📝 Recently modified:
   • roadmaps/Basic Memory 90%+ Roadmap - Phase 10 Plan
   • session-summaries/Session Summary - Phase 9
   • patterns/SQL Validator Enhancement Patterns
   • patterns/3-Module Validation Architecture Pattern
   • fixes/Gap Detection False Positive Fix

💡 Use: mcp__basic-memory__build_context(url="memory://folder/*")
```

---

## Proactive Memory Rules

Create `.claude/rules/mcp/memory-usage.md`:

```markdown
# Basic Memory Usage Rules

**Authority**: Proactive knowledge retrieval patterns
**Enforcement**: ALWAYS use for past decisions, fixes, patterns

---

## Proactive Memory Triggers

**MUST use Basic Memory MCP when these patterns detected:**

| Pattern        | Trigger                            | Action                                          |
| -------------- | ---------------------------------- | ----------------------------------------------- |
| Past Decisions | "what did we decide", "why did we" | `search_notes(query="topic decision")`          |
| Past Fixes     | "how did we fix", "similar bug"    | `build_context(url="memory://fixes/*")`         |
| Patterns       | "pattern for", "best practice"     | `build_context(url="memory://patterns/*")`      |
| Recent Context | new session, complex task          | `recent_activity(timeframe="7d")`               |
| Research       | "documentation for"                | `search_notes(query="topic")` BEFORE Perplexity |

---

## Post-Work Documentation

**SHOULD document after completing work:**

| After     | Format                                   | Folder     |
| --------- | ---------------------------------------- | ---------- |
| Decisions | `[decision] What was decided #category`  | decisions/ |
| Fixes     | `[technique] How it was fixed #category` | fixes/     |
| Bugs      | `[issue] What the problem was #category` | fixes/     |
| Learning  | `[lesson] What was learned #category`    | patterns/  |

---

## Key Memory Folders

| Folder               | Purpose                | When to Query          |
| -------------------- | ---------------------- | ---------------------- |
| `fixes/`             | Production fixes       | Bug investigation      |
| `patterns/`          | Reusable patterns      | Implementation         |
| `decisions/`         | Architecture decisions | Design questions       |
| `research-cache/`    | Perplexity results     | Before external search |
| `session-summaries/` | Session history        | Context recovery       |
```

---

## Skill for Memory Usage

Create `~/.claude/skills/basic-memory-semantic-patterns-skill/SKILL.md`:

```yaml
---
name: basic-memory-semantic-patterns-skill
description: "Write Basic Memory notes with semantic observations and relations. Use when creating notes, querying past decisions, finding how we fixed bugs, or loading pattern context."
Triggers: semantic observations, basic memory format, write note properly, relations format, memory url, what did we decide, how did we fix, past decision, similar bug, seen this before, pattern for, show patterns, document this, check memory, search memory
user-invocable: false
---
```

### Trigger Activation

| Query                             | Activates Skill |
| --------------------------------- | --------------- |
| "what did we decide about X"      | ✅              |
| "show patterns for database"      | ✅              |
| "document this fix"               | ✅              |
| "similar bug seen before"         | ✅              |
| "check memory for past decisions" | ✅              |

---

## Folder Organization

### Recommended Structure (23 folders)

```
~/basic-memory/
├── patterns/           # Reusable implementation patterns
├── sacred-patterns/    # Commandment implementations (if applicable)
├── fixes/              # Bug solutions, techniques
├── decisions/          # Architecture/design decisions
├── deployment/         # Release patterns
├── research-cache/     # Perplexity search results (FREE!)
├── session-summaries/  # Context history
├── quick-reference/    # Fast lookup notes
├── guides/             # How-to documentation
├── learned/            # Entry summaries
└── [domain-specific]/  # Your project domains
```

### Consolidation Rules

| If You Have                 | Merge Into                |
| --------------------------- | ------------------------- |
| Multiple 1-file folders     | Appropriate parent folder |
| `bugs/`, `troubleshooting/` | `fixes/`                  |
| `research/`                 | `research-cache/`         |
| `plans/`, `planning/`       | `planning/`               |
| Empty folders               | Delete                    |

---

## MCP Commands Reference

### Search Notes

```javascript
mcp__basic - memory__search_notes((query = "deployment decision"));
// Returns notes matching query
```

### Build Context

```javascript
mcp__basic -
  memory__build_context(
    (url = "memory://fixes/*"),
    (timeframe = "30d"),
    (max_related = 5),
  );
// Returns notes with observations and relations
```

### Write Note

```javascript
mcp__basic -
  memory__write_note(
    (title = "Fix Name"),
    (folder = "fixes"),
    (content = "# Fix\n\n## Observations\n\n- [technique] ..."),
    (tags = ["fix", "database"]),
  );
```

### Recent Activity

```javascript
mcp__basic - memory__recent_activity((timeframe = "7d"));
// Returns recently modified notes
```

---

## CLAUDE.md Integration

Add this section to your project's CLAUDE.md:

```markdown
**🧠 BASIC MEMORY USAGE**: 📚 **PROACTIVE KNOWLEDGE RETRIEVAL** 📚

- **PROACTIVE TRIGGERS** - Use Basic Memory MCP automatically when:
  - "What did we decide about X?" → `search_notes(query="X decision")`
  - "How did we fix Y before?" → `build_context(url="memory://fixes/*")`
  - "Show patterns for Z" → `build_context(url="memory://patterns/*")`
  - Complex task starting → `recent_activity(timeframe="7d")`

- **AFTER WORK** - Document learnings with semantic format:
  - After decisions: Create note with `[decision]` observation
  - After fixes: Create note with `[technique]` observation
  - After bugs found: Create note with `[issue]` observation

- **KEY FOLDERS**: fixes/, patterns/, decisions/, research-cache/
- **SKILL**: `basic-memory-semantic-patterns-skill`
```

---

## Test Suite

Create `tests/basic-memory/comprehensive-basic-memory-test.sh`:

### 7 Test Sections (36 tests total)

1. **Skill File Tests** (5) - File exists, YAML, description, size, triggers
2. **Skill Activation Tests** (6) - Query triggers work
3. **Rules File Tests** (4) - File exists, sections, README
4. **CLAUDE.md Integration** (3) - Memory section exists
5. **Session-Start Hook** (6) - Hook executes, shows context
6. **Memory Bank Structure** (9) - Folders, observations, relations
7. **Branch Integration** (3) - Branch variables, roadmap

### Running Tests

```bash
chmod +x tests/basic-memory/comprehensive-basic-memory-test.sh
bash tests/basic-memory/comprehensive-basic-memory-test.sh

# Expected output:
# Total Tests: 36
# Passed: 36
# Pass Rate: 100%
# 🎉 ALL TESTS PASSED!
```

---

## Implementation Checklist

### Phase 1: Skill + Rules (30 min)

- [ ] Create `basic-memory-semantic-patterns-skill`
- [ ] Create `.claude/rules/mcp/memory-usage.md`
- [ ] Add BASIC MEMORY USAGE to CLAUDE.md
- [ ] Rebuild skill cache

### Phase 2: Session Integration (15 min)

- [ ] Add memory section to session-start.sh
- [ ] Test hook execution
- [ ] Verify context displays

### Phase 3: Folder Organization (15 min)

- [ ] Audit existing folders
- [ ] Consolidate 1-file folders
- [ ] Delete empty folders

### Phase 4: Testing (15 min)

- [ ] Create test script
- [ ] Run all tests
- [ ] Fix any failures

---

## Success Metrics

| Metric           | Target              |
| ---------------- | ------------------- |
| Skill activation | 6/6 generic queries |
| Test pass rate   | 36/36 (100%)        |
| Folders          | <30 (consolidated)  |
| Observations     | 30+ across notes    |
| Relations        | 20+ across notes    |
| Session context  | Automatic display   |

---

## Troubleshooting

### Skill Not Activating

```bash
# Rebuild cache
rm ~/.claude/cache/skill-index-hybrid.txt
echo '{"prompt": "test"}' | bash .claude/hooks/pre-prompt.sh

# Test specific query
echo '{"prompt": "what did we decide"}' | bash .claude/hooks/pre-prompt.sh | grep basic-memory
```

### Hook Not Showing Memory

```bash
# Test hook directly
bash .claude/hooks/session-start.sh | grep "BASIC MEMORY"

# Check memory path
ls ~/basic-memory/
```

### Search Returns Empty

```bash
# Check if notes exist
find ~/basic-memory -name "*.md" | wc -l

# Check for observations
grep -r "^\- \[decision\]" ~/basic-memory/
```

---

## Related Documentation

- [Memory Bank Hierarchy](12-memory-bank-hierarchy.md) - 4-tier organization
- [Perplexity Cost Optimization](18-perplexity-cost-optimization.md) - Cache-first pattern
- [Claude Code Hooks](13-claude-code-hooks.md) - Hook system
- [Pre-Prompt Hook Guide](../pre-prompt-hook-complete-guide.md) - Skill activation

---

## Evidence

**Source Project**: Production
**Entry**: #283 (Basic Memory Integration Complete)
**Tests**: 36/36 passing
**ROI**: ~2 hours setup → 30-50 hours/year saved
**Metrics**:

- Memory folders: 51 → 23 (55% reduction)
- Semantic observations: 44
- Relations: 35
- Skill triggers: 26

---

**Previous**: [33: Branch-Specific Skill Curation](33-branch-specific-skill-curation.md)
**Next**: [35: Skill Optimization Maintenance](35-skill-optimization-maintenance.md)
