---
title: Context Optimization for Mature Projects
description: Reduce memory file token usage in long-running Claude Code projects without losing critical context
---

# Context Optimization for Mature Projects

When a project grows past 50-100 memory files, context bloat becomes a real problem. This guide covers battle-tested patterns for reducing token usage while preserving all critical context.

## When You Need This

- Memory files consume >60k tokens (check with `/context`)
- You see "file exceeds 40k chars" warnings on auto-loaded files
- Project-specific rules pollute the global scope (load in ALL projects)
- Skills list grows past 50 entries with obsolete/duplicate items
- Session startup feels slow due to excessive context loading

## Pattern 1: Path-Scoping Rules with YAML Frontmatter

Rules that only apply when editing specific files should use `paths:` frontmatter. This prevents them from loading in every context.

### Before (always loaded, ~1,300 tokens)

```markdown
# Orchestrator Stability Checklist

**Scope**: ALL changes to agents/orchestrator/
...
```

### After (only loads when editing matching files)

```yaml
---
paths:
  - agents/orchestrator/**
  - agents/**/agent.py
---
```

```markdown
# Orchestrator Stability Checklist
...
```

**Impact**: A set of 9 orchestrator rules (~7k tokens) now only loads when editing orchestrator files. For frontend or docs work, they're invisible.

### When to Path-Scope

| Rule Type | Path-Scope? | Example Paths |
|-----------|------------|---------------|
| Orchestrator/pipeline | Yes | `agents/orchestrator/**` |
| Testing conventions | Yes | `scripts/**`, `tests/**` |
| Frontend patterns | Yes | `web/src/**` |
| Security rules | No (universal) | — |
| Code style | No (universal) | — |
| Git safety | No (universal) | — |

## Pattern 2: Global vs Project Rules Separation

Rules in `~/.claude/rules/` load in **every project**. Rules in `{project}/.claude/rules/` load only in that project.

### Decision Criteria

| Question | If Yes → Global | If No → Project |
|----------|-----------------|-----------------|
| Does this apply to ALL your projects? | Global | — |
| Is this a universal programming pattern? | Global | — |
| Does it reference project-specific tech (Firestore, ADK, WhatsApp)? | — | Project |
| Does it cite project-specific evidence (Entry #294)? | — | Project |

### Example: Moving a Rule

A "SQLite Firestore Compatibility" rule only applies to projects using the Firestore SQLite emulator. It was in `~/.claude/rules/technical/` (global) but belonged in `.claude/rules/` (project).

```bash
# Move and path-scope
mv ~/.claude/rules/technical/sqlite-firestore-compat.md .claude/rules/
# Add frontmatter: paths: ["api/**", "agents/**"]
```

### Preventing Future Pollution

Add a warning header to your global rules index:

```
> **GLOBAL SCOPE**: Rules here load in ALL projects.
> Project-specific rules belong in {project}/.claude/rules/.
```

## Pattern 3: Condensing Large Auto-Loaded Files

When a blueprint or reference file exceeds 40k characters, Claude Code warns you. The fix: condense without losing critical context.

### Safe Condensation Targets

| Target | Strategy | Token Savings |
|--------|----------|---------------|
| Duplicated content (same info in 2+ files) | Delete from one, add pointer | 30-70% of duplicate |
| "How" implementation columns in tables | Remove — code is the source of truth | 10-20% per table |
| Verbose file lists (10+ files) | Condense to directory pointers | 40-60% |
| ASCII art diagrams | Replace with 1-line summary | 80-90% per diagram |
| Reusable infrastructure tables | Delete — discoverable via grep | 100% |

### Example: Blueprint Condensation

A 900-line blueprint was condensed to 700 lines:

| Section | Before | After | Savings |
|---------|--------|-------|---------|
| Generation Stack Policy (73 lines) | Full model tables, env vars, fallback chains | 3-line pointer to existing rule files | ~70 lines |
| Design-to-Code (130 lines) | Full pipeline diagram, 11-file table, frontend table | Summary + DQI table + Phase 0 results | ~80 lines |
| GQI table "How" column | 10 cells of implementation detail | Removed column | ~14 lines |
| Section Architecture (28 lines) | Full post-processing pipeline listing | 3-line summary | ~22 lines |

**Key principle**: If the same information exists in a rule file AND a blueprint, delete it from the blueprint and add a pointer.

## Pattern 4: Skill Lifecycle Management

Skills accumulate over time. Archive obsolete ones to reduce list noise.

### Archive Decision Tree

```
Is it superseded by a built-in Claude Code feature?  → Archive
Does it reference dead/renamed infrastructure?        → Archive
Has it been unused for 90+ days?                      → Consider archiving
Does it contain unique algorithms/patterns?           → Keep (even if rarely used)
```

### Archive Method

Rename the directory with `_archived_` prefix:

```bash
mv .claude/skills/session-continuity .claude/skills/_archived_session-continuity
```

The skill still exists (recoverable) but won't clutter the active skills list.

## Pattern 5: Progressive Disclosure for Memory Search

Don't fetch full notes when searching. Use a 3-layer approach:

1. **Index search** (`search()`) — IDs + titles only (~50 tokens/result)
2. **Preview** (`search_notes()`) — truncated content (~200 tokens/result)
3. **Full read** (`fetch()`) — only after filtering (~500-1000 tokens)

**Token savings**: 10x reduction vs reading everything upfront.

## Measuring Results

Always measure before and after:

```bash
# Before: note the "Memory files" token count
/context

# Make all changes

# After: verify reduction
# Start a fresh session to see accurate counts
claude --new
/context
```

### Target Benchmarks

| Metric | Healthy | Warning | Critical |
|--------|---------|---------|----------|
| Memory file tokens | <50k | 50-65k | >65k |
| Largest auto-loaded file | <35k chars | 35-40k | >40k |
| Global rules (project-specific) | 0-2 | 3-5 | >5 |
| Active skills | <50 | 50-70 | >70 |

## Case Study: OGAS Project Optimization

A mature AI agent platform (900+ lines in one blueprint, 14 project-specific rules in global scope, 70+ skills) was optimized:

| KPI | Before | After | Change |
|-----|--------|-------|--------|
| Blueprint chars | 42.5k | 33.6k | -21% |
| Path-scoped rules | 0/9 | 9/9 | -7k tokens baseline |
| Global→Project rules moved | 0 | 2 | Cleaner global scope |
| Skills archived | 0 | 2 | Reduced noise |

**Total estimated savings**: ~15k tokens per session (depending on which files are edited).
