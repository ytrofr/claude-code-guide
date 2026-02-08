# Task Tracking & Roadmap System

**Purpose**: Lightweight task/roadmap tracking that keeps Claude's context focused on ONLY open items  
**Pattern**: Completed items archived so they don't waste tokens  
**Created**: December 2025  
**Source**: Production implementation (Entry #163)

---

## Overview

A simple but effective system for tracking tasks, features, and technical debt across Claude Code sessions:

- **Only open items loaded** into context
- **Completed items archived** (not deleted, just moved)
- **Priority-based organization** (P1/P2/P3)
- **Quick wins highlighted** for momentum
- **Recurring tasks tracked** with due dates
- **Memory MCP backup** for cross-session recall

---

## File Structure

```
memory-bank/
├── always/
│   └── system-status.json           # Summary + reference path (always loaded)
└── ondemand/
    └── reference/
        └── FUTURE-FEATURES.md       # Full task details (ONLY open items)
```

### Why Two Files?

| File                 | Loaded    | Purpose                                  | Size    |
| -------------------- | --------- | ---------------------------------------- | ------- |
| `system-status.json` | Always    | Quick summary, feature flags, references | ~2KB    |
| `FUTURE-FEATURES.md` | On-demand | Detailed task list with context          | ~5-15KB |

---

## Multi-Branch Projects 🆕

For projects with multiple branches, use **per-branch ROADMAPs**:

```
CURRENT/
├── dev-Data/
│   └── dev-Data-ROADMAP.md      # Data-specific tasks
├── dev-UI/
│   └── dev-UI-ROADMAP.md        # UI-specific tasks
└── dev-Knowledge/
    └── dev-Knowledge-ROADMAP.md  # Knowledge-specific tasks
```

→ **See [Chapter 31: Branch-Aware Development](31-branch-aware-development.md)** for:

- ROADMAP template with standard format
- Instructions template per branch
- branch-variables.json for skill weighting

---

## Quick Start (10 minutes)

### Step 1: Create system-status.json

Add to `memory-bank/always/system-status.json`:

```json
{
  "last_updated": "2025-12-18",
  "current_sprint": "Feature Development Sprint 1",
  "branch": "dev",
  "system_health": {
    "production": { "status": "operational", "url": "https://yourapp.com" },
    "staging": { "status": "operational" },
    "localhost": { "status": "operational", "port": 8080 }
  },
  "features": [
    { "name": "User_Auth", "passes": true, "entry": 1 },
    { "name": "Dashboard", "passes": true, "entry": 2 },
    { "name": "API_Cache", "passes": false, "entry": 3 }
  ],
  "recent_fixes": [
    { "issue": "Login timeout bug", "date": "2025-12-17", "entry": 10 }
  ],
  "active_blockers": [],
  "future_features_summary": "5 OPEN items (~4h) - P2: 3 items, P3: 2 items - See FUTURE-FEATURES.md",
  "reference_paths": {
    "future_features": "memory-bank/ondemand/reference/FUTURE-FEATURES.md"
  }
}
```

### Step 2: Create FUTURE-FEATURES.md

Add to `memory-bank/ondemand/reference/FUTURE-FEATURES.md`:

```markdown
# Future Features - Active Roadmap

**Updated**: 2025-12-18
**Purpose**: ONLY remaining tasks (completed archived below)
**Total Open**: 5 items (~4h)

---

## 📋 OPEN TASKS ONLY

### P1 - High Priority (0 items)

| Task   | Time | Details |
| ------ | ---- | ------- |
| (none) | -    | -       |

### P2 - Medium Priority (3 items, ~2.5h)

| Task               | Time   | Details                              |
| ------------------ | ------ | ------------------------------------ |
| **Add_API_Cache**  | 1h     | Redis caching for /api/data endpoint |
| **Fix_Mobile_Nav** | 30 min | Hamburger menu not closing on click  |
| **Update_Docs**    | 1h     | Add deployment section to README     |

### P3 - Low Priority (2 items, ~1.5h)

| Task               | Time   | Details                        |
| ------------------ | ------ | ------------------------------ |
| **Refactor_Utils** | 1h     | Split utils.js into modules    |
| **Add_Dark_Mode**  | 30 min | CSS variables already prepared |

---

## 🎯 QUICK WINS (Do First)

1. **Fix_Mobile_Nav** - 30 min
2. **Add_Dark_Mode** - 30 min

---

## 📅 RECURRING TASKS

| Task          | Frequency | Next Due     |
| ------------- | --------- | ------------ |
| Weekly_Backup | Weekly    | Dec 25, 2025 |
| Monthly_Audit | Monthly   | Jan 1, 2026  |

---

## ✅ COMPLETED (Archived)

| Task        | Completed | Notes                  |
| ----------- | --------- | ---------------------- |
| Setup_CI_CD | Dec 15    | GitHub Actions working |
| Add_Auth    | Dec 10    | JWT implementation     |
```

---

## Workflow

### Adding Tasks

```markdown
1. Add to appropriate priority section in FUTURE-FEATURES.md
2. Update count in system-status.json summary
3. (Optional) Store summary in Memory MCP for cross-session recall
```

### Completing Tasks

```markdown
1. Move from OPEN to COMPLETED section (with date)
2. Update counts in system-status.json
3. If recurring, update next due date instead of completing
```

### Cleanup (YAGNI)

```markdown
1. Identify tasks no longer needed
2. Move to REMOVED section with reason
3. Update counts
4. Don't delete - document why removed for future reference
```

---

## Key Principles

1. **Only Open Items in Context** - Completed items don't waste tokens
2. **Priority-Based Organization** - P1/P2/P3 with time estimates
3. **Quick Wins Highlighted** - Easy tasks surfaced for momentum
4. **Recurring Tasks Tracked** - Weekly/daily checks with due dates
5. **Memory MCP Backup** - Store summary for cross-session recall
6. **YAGNI Cleanup** - Remove unnecessary items, document why

---

## Integration with Claude Code

### Session Start

```bash
# Check current status
cat memory-bank/always/system-status.json | jq '.future_features_summary'

# See full details if needed
cat memory-bank/ondemand/reference/FUTURE-FEATURES.md
```

### After Completing Work

```bash
# Update the files
# 1. Move task to COMPLETED in FUTURE-FEATURES.md
# 2. Update summary in system-status.json
# 3. Commit changes

git add memory-bank/
git commit -m "docs(roadmap): Complete [task name]"
```

### Store in Memory MCP (Optional)

```javascript
// Use mcp__basic-memory__write_note to store summary
{
  "title": "Project Roadmap - Active Tasks",
  "content": "5 OPEN items: P2 (3), P3 (2). Quick wins: Fix_Mobile_Nav, Add_Dark_Mode",
  "folder": "project/planning"
}
```

---

## Best Practices

### DO

- ✅ Keep system-status.json under 100 lines
- ✅ Archive completed items (don't delete)
- ✅ Update counts when moving tasks
- ✅ Use time estimates for planning
- ✅ Mark quick wins for momentum

### DON'T

- ❌ Load full task history into always/ directory
- ❌ Delete completed tasks (archive them)
- ❌ Skip updating the summary field
- ❌ Create separate files per task

---

## Example: Real Usage

### Before Session

```
Claude sees in system-status.json:
"future_features_summary": "5 OPEN items (~4h) - P2: 3, P3: 2"

Knows there's work to do, but doesn't load 50 completed items.
```

### During Session

```
User: "What's left to do?"
Claude: "You have 5 open items. Quick wins: Fix_Mobile_Nav (30 min),
         Add_Dark_Mode (30 min). Want to tackle one?"
```

### After Completing Task

```
Claude updates FUTURE-FEATURES.md:
- Moves Fix_Mobile_Nav to COMPLETED
- Updates summary: "4 OPEN items (~3.5h)"
- Commits changes
```

---

## ROI

- **Token Savings**: ~1-5K tokens per session (no loading completed tasks)
- **Clarity**: Always know exactly what's pending
- **Momentum**: Quick wins highlighted for easy progress
- **History**: Completed items preserved for reference

---

## Related Chapters

- **Chapter 12**: Memory Bank Hierarchy (4-tier structure)
- **Chapter 23**: Session Documentation Skill (automated docs)
- **Chapter 29**: Branch Context System (per-branch loading) 🆕
- **Chapter 31**: Branch-Aware Development (ROADMAP templates) 🆕

---

**Pattern Source**: Production (Entry #163 - claude-code-guide-patterns.md)  
**Status**: Production validated December 2025  
**Last Updated**: 2026-01-19
**License**: MIT
