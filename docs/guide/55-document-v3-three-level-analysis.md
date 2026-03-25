# Chapter 55: /document v3 — Three-Level Pattern Analysis

**Evidence**: Production Entry #064 — 15 mobile bugs caught, 6 artifacts suggested across 3 levels
**Difficulty**: Beginner (just run `/document`)
**Time**: 5-10 minutes per session
**ROI**: Prevents knowledge loss between sessions + catches stale artifacts

---

## Problem

The original `/document` (Chapter 32) had three issues:

1. **No mandatory pause** — model rushed through pattern analysis without asking the user
2. **Single-level thinking** — only suggested project-level artifacts, missing machine-wide and branch-specific ones
3. **588 lines** — too long, burned context before reaching the analytical steps

---

## Solution: 3-Phase, 3-Level /document

### Architecture

```
Phase 1: GATHER + DOCUMENT (automatic — creates Entry, updates context, saves to MCP)
Phase 2: ANALYZE + SUGGEST (6 checks × 3 levels — STOPS for user input)
Phase 3: CREATE SELECTED (only creates what user approves)
```

### The 3 Levels

| Level | Scope | Location | Example |
|-------|-------|----------|---------|
| **Machine** | All projects on this computer | `~/.claude/rules/`, `~/.claude/skills/` | "Never kill all node processes" |
| **Project** | All branches of this repo | `.claude/rules/`, `.claude/skills/` | "Generation uses 3-layer fix priority" |
| **Branch** | Current branch only | Roadmap, branch rules, branch context | "Phase 12 issues M1-M15" |

### The 6 Checks

| # | Check | What it catches |
|---|-------|----------------|
| 1 | **Rules** | NEVER/ALWAYS lessons, file-scoped patterns |
| 2 | **Skills** | Reusable workflows + **stale existing skills** |
| 3 | **Blueprints** | Architecture docs that need updating |
| 4 | **Roadmap** | Completed tasks, new issues, phase status |
| 5 | **Project Root** | CLAUDE.md, system-status.json, decisions |
| 6 | **Memory** | Auto-memory entries, Basic Memory MCP, stale entries |

---

## Setup

### Global command (works for any project):

**File**: `~/.claude/commands/document.md`

```yaml
---
description: "Document session work + 6-check pattern analysis at 3 levels"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, mcp__basic-memory__write_note, mcp__basic-memory__search_notes
argument-hint: [topic-name]
---
```

The global command **discovers project structure at runtime** using:
- `ls memory-bank/learned/` — does project use Entry files?
- `ls CHANGELOG.md` — does project use a changelog?
- `cat CLAUDE.md | head -20` — what does the project configure?

### Project-level override (optional):

**File**: `{project}/.claude/commands/document.md`

Adds a **path map** specific to that project. For example, OGAS has:
- `memory-bank/learned/` for entries
- `docs/memory/hot/ACTIVE.md` for active context
- `docs/memory/websites/WEBSITES-BLUEPRINT.md` for blueprints

LimorAI might have:
- `CHANGELOG.md` for entries
- Different blueprint locations
- Different branch structure

The global command adapts. The project override makes it precise.

---

## How It Works: Phase 2 Example Output

After running `/document my-feature`, Phase 2 presents:

```
## PATTERN ANALYSIS — 5 suggestions

MACHINE-LEVEL (all projects):
  (none this session)

PROJECT-LEVEL (all branches):
  1. UPDATE SKILL — websites-agent-development: missing new architecture docs
  2. UPDATE CONTEXT — system-status.json: no generation quality entry
  3. UPDATE BLUEPRINT — WEBSITES-BLUEPRINT.md: GQI now 10 categories (was 8)

BRANCH-LEVEL (dev-websites):
  4. UPDATE ROADMAP — Phase 12 complete, update status
  5. UPDATE BRANCH RULE — websites-agent.md: generation rules outdated

Select (1-5 / all / none):
```

The user picks which to create. Phase 3 only creates selected items.

---

## Key Design Decisions

### Why mandatory pause at Phase 2?

Without it, the model creates all artifacts in one shot — no user review. This led to:
- Skills created that overlap with existing ones
- Rules at wrong scope level (machine vs project)
- Context updates the user didn't want

### Why 3 levels instead of 1?

A session might produce:
- A **machine-level** lesson ("never use `flex-wrap: wrap` on keep-row" — applies everywhere)
- A **project-level** rule (scoped to `html_generation/` files)
- A **branch-level** roadmap update (Phase 12 issues M1-M15)

Single-level thinking misses 2 out of 3.

### Why 6 checks instead of 4?

The original had: rules, skills, context, overlap-check.
Missing: blueprints (architectural docs), roadmap (branch tracking), and stale-artifact detection.
These 3 gaps caused `/document` to miss suggestions that the user had to manually request.

### Why runtime discovery?

Hardcoded paths like `memory-bank/learned/` only work for OGAS. Other projects use `CHANGELOG.md`, `docs/`, or nothing. The global command runs `ls` to discover what exists, then adapts.

---

## Comparison: v1 vs v2 vs v3

| Feature | v1 (Ch.23) | v2 (Ch.32) | v3 (Ch.55) |
|---------|-----------|-----------|-----------|
| Entry creation | Yes | Yes | Yes |
| Pattern analysis | No | Yes (passive) | Yes (6 checks) |
| Mandatory pause | No | No | **Yes** |
| Multi-level | No | No | **3 levels** |
| Stale detection | No | No | **Yes** |
| Blueprint check | No | Bundled | **Own check** |
| Roadmap check | No | No | **Own check** |
| Cross-project | No | No | **Runtime discovery** |
| Lines | ~100 | 588 | **~100** |

---

## References

- Chapter 23: Original `/document` (Entry creation only)
- Chapter 32: Enhanced with smart discovery, 3-level rule classification, and draft format
- Chapter 26: Rules system (auto-classification, deduplication)
- Chapter 16: Skills activation
- Chapter 29: Branch context system
- Chapter 31b: Per-branch rules (branch-level rule loading)
