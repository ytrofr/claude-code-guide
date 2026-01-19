# Chapter 23: Session Documentation Skill

**Status**: Production-Validated (Jan 2, 2026)
**Difficulty**: Beginner
**Time**: 10 minutes
**ROI**: 67% faster documentation (30 min → 10 min)

---

## Problem

Documenting session work requires updating **3 files manually**:

1. **Entry file** (`memory-bank/learned/entry-XXX-topic.md`)
2. **Roadmap** (`CURRENT/{branch}/{branch}-ROADMAP.md`)
3. **system-status.json** (`memory-bank/always/system-status.json`)

**Pain Points**:
- Easy to forget one of the 3 files
- Roadmap task status gets stale
- Entry numbers must be tracked manually
- 30+ minutes per session to document properly

---

## Solution: Session Documentation Skill

A single `/document` command that:
1. ✅ Creates Entry with next available number
2. ✅ Updates roadmap (moves completed tasks)
3. ✅ Updates system-status.json
4. ✅ Creates single commit with all changes

---

## Advanced: Pattern Analysis Engine 🆕

For **automatic suggestions** about creating skills/rules/blueprints:

→ **See [Chapter 32: Document Automation](32-document-automation.md)** for:
- 13-step workflow with pattern analysis
- 5-type suggestion engine (Skill, Rule, Blueprint, CORE-PATTERNS, Memory)
- Decision matrix (when to create what)

This chapter covers the **basic** /document workflow. Chapter 32 covers the **advanced** pattern analysis.

---

## Setup (10 min)

### Step 1: Create Skill Directory

```bash
mkdir -p ~/.claude/skills/session-documentation-skill
```

### Step 2: Create SKILL.md

```markdown
---
name: session-documentation-skill
description: |
  Automates complete session documentation workflow: Entry creation + roadmap update + 
  system-status.json update. Use when ending a session, documenting completed work, or
  when user says "/document". Saves 67% time (30 min → 10 min).
---

## When to Use

- Session ending with completed work
- User says "/document" or "document this session"
- Major feature/fix completed
- Before creating PR

## Workflow (9 Steps)

### Phase 1: Context Gathering
1. **Git Context**: Run `git status` and `git log --oneline -5`
2. **Analyze Work**: Identify what was accomplished this session

### Phase 2: Documentation (Interactive)
3. **Entry Creation**: Create `memory-bank/learned/entry-XXX-topic.md`
   - Auto-increment entry number
   - Include: Problem, Solution, Evidence, Time savings

4. **Roadmap Update**: Update `CURRENT/{branch}/{branch}-ROADMAP.md`
   - Move completed tasks from "Current" to "Completed"
   - Add Entry reference
   - Show diff to user

5. **Status Update**: Update `memory-bank/always/system-status.json`
   - Add feature to `features` array
   - Update `recent_fixes` array
   - Update `latest_entries`

### Phase 3: Commit
6. **Single Commit**: All 3 files in one commit
   - Message: "docs: Entry #XXX - [topic]"

### Phase 4: Persistence
7. **Memory MCP**: Store session summary
   - `mcp__basic-memory__write_note(folder="sessions")`

## Entry Template

```markdown
# Entry #XXX: [Title]

**Date**: YYYY-MM-DD
**Branch**: {current_branch}
**Status**: ✅ Complete

## Problem
[What issue was being solved]

## Solution
[How it was solved]

## Evidence
- Before: [metrics]
- After: [metrics]
- Improvement: [percentage]

## Files Changed
- file1.js
- file2.md

## Time Savings
- Manual: X minutes
- With skill: Y minutes
- ROI: Z%
```

## Roadmap Update Pattern

```diff
## ✅ COMPLETED (This Session)
+ | Task description | ✅ COMPLETE | Entry #XXX |

## 🎯 Current Sprint
- - [ ] Task description
```
```

### Step 3: Add Trigger

In `AUTOMATIC-TOOL-TRIGGERS.md`, add:

```yaml
document work/create entry/update roadmap/mark task complete/session documentation:
  → session-documentation-skill
  → Evidence: "Jan 2, 2026 - Automates Entry + roadmap + status updates (67% faster)"
  NEVER: Manual 3-file updates (use /document)
```

### Step 4: Test

Start fresh session and say:
```
/document
```

**Expected**:
- ✅ Skill activates
- ✅ Prompts for Entry topic
- ✅ Creates Entry file
- ✅ Shows roadmap diff
- ✅ Updates status JSON
- ✅ Creates commit

---

## Usage Examples

### End of Session

```
User: /document

Claude: I'll use session-documentation-skill.

Step 1: Git Context
- Branch: dev-Knowledge
- Recent commits: [...]

Step 2: Analyzing work...
- Completed: Pre-prompt optimization
- Evidence: 28k→9k chars (68% reduction)

Step 3: Creating Entry #228...
[Shows Entry content]

Step 4: Updating roadmap...
[Shows diff]

Step 5: Updating system-status.json...
[Shows changes]

Step 6: Creating commit...
docs: Entry #228 - Pre-prompt optimization

✅ Documentation complete!
```

### Mid-Session Checkpoint

```
User: Document what we've done so far

Claude: I'll use session-documentation-skill.
[Same workflow but marks task as "in progress"]
```

---

## Benefits

### Time Savings

| Task | Manual | With Skill | Savings |
|------|--------|------------|--------|
| Entry creation | 10 min | 3 min | 70% |
| Roadmap update | 10 min | 2 min | 80% |
| Status update | 5 min | 2 min | 60% |
| Git commit | 5 min | 3 min | 40% |
| **Total** | **30 min** | **10 min** | **67%** |

### Quality Improvements

- ✅ Never forget to update roadmap
- ✅ Entry numbers auto-increment
- ✅ Consistent Entry format
- ✅ All changes in single commit
- ✅ Session history in Memory MCP

---

## Integration with SESSION-PROTOCOL.md

Update `memory-bank/always/SESSION-PROTOCOL.md`:

```markdown
## 🏁 SESSION END PROTOCOL

**Before Ending Any Session**:

1. Use `/document` command (activates session-documentation-skill)
2. Review Entry, roadmap diff, and status changes
3. Confirm commit
4. Never stop mid-feature - complete or create checkpoint
```

---

## Troubleshooting

### Issue: Skill not activating

**Check trigger**:
```bash
grep -i "document" memory-bank/always/AUTOMATIC-TOOL-TRIGGERS.md
```

**Add if missing**:
```yaml
document work/create entry/update roadmap:
  → session-documentation-skill
```

### Issue: Entry number wrong

**Find latest Entry**:
```bash
ls memory-bank/learned/entry-*.md | tail -1
# Or:
grep -r "Entry #" memory-bank/learned/ | grep -oE "Entry #[0-9]+" | sort -t# -k2 -n | tail -1
```

### Issue: Roadmap not updating

**Check roadmap path**:
```bash
ls CURRENT/$(git branch --show-current)/*ROADMAP*.md
```

---

## Related Chapters

- **Chapter 4**: Task Tracking System (roadmap basics)
- **Chapter 12**: Memory Bank Hierarchy (Entry organization)
- **Chapter 13**: Claude Code Hooks (automation)
- **Chapter 31**: Branch-Aware Development (ROADMAP templates) 🆕
- **Chapter 32**: Document Automation (pattern analysis) 🆕

---

**Implementation Time**: 10 minutes
**Evidence**: LimorAI production (Entry #228, #229 created with skill)
**Last Updated**: 2026-01-19