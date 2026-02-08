---
name: session-start-protocol-skill
description: "Initialize Claude Code session following Anthropic best practices for multi-session continuity. Use when: (1) starting any new Claude Code session, (2) resuming work after context compaction, (3) uncertain about current project state. Source: Anthropic Claude 4 Best Practices."
---

# Session Start Protocol

**Purpose**: Multi-session continuity and progress tracking
**Source**: Anthropic's Claude 4 Best Practices + Agent Harness patterns
**Success**: Enables unlimited context through automatic summarization

---

## Usage Scenarios

**(1) When starting any new Claude Code session**
- Every morning
- After breaks
- When switching between projects

**(2) When resuming work after context compaction**
- Claude Code automatically compacts context when approaching limits
- You can continue working indefinitely
- Use this protocol to orient yourself

**(3) When uncertain about current project state**
- What was I working on?
- What's completed vs in-progress?
- What are the priorities?

---

## Failed Attempts

| Attempt | Why It Failed | Lesson Learned |
|---------|---------------|----------------|
| Relying on memory alone | Context gets compacted, lose progress | Always check git status |
| Starting random tasks | Forgot what was incomplete | Check system-status.json first |
| Skipping session initialization | Missed important updates, duplicated work | 2-min protocol saves hours |

---

## Quick Start (< 2 min)

```bash
# Step 1: Check current state (30 sec)
git status && git branch --show-current
git log --oneline -5

# Step 2: Check feature status (30 sec)
cat memory-bank/always/system-status.json | jq '.features[] | {name, status, passes}'

# Step 3: Find incomplete work (30 sec)
cat memory-bank/always/system-status.json | jq '.features[] | select(.passes == false)'

# Step 4: Review recent activity (30 sec)
git log --oneline -10
cat memory-bank/always/system-status.json | jq '.recent_fixes[-3:]'
```

**Output**: List of incomplete features, recent commits, current priority

---

## Complete Protocol

### On Every New Session

**1. Check Git State**
```bash
# What branch am I on?
git status
git branch --show-current

# What changed recently?
git log --oneline -5
git diff HEAD~1  # See last commit changes
```

**2. Read System Status**
```bash
# What features are incomplete?
cat memory-bank/always/system-status.json | jq '.features[] | select(.passes == false) | .name'

# What's the current priority?
cat memory-bank/always/system-status.json | jq '.current_sprint'

# Any blockers?
cat memory-bank/always/system-status.json | jq '.active_blockers'
```

**3. Select Next Task**
- Focus on ONE incomplete feature (passes: false)
- Check if there are active blockers
- Read relevant Entry #X from memory-bank/learned/
- Understand context before starting

**4. Set Session Goal**
- Pick specific, achievable goal
- "Complete Feature X" or "Fix Issue Y"
- NOT "Work on everything" (violates Anthropic incremental progress principle)

---

## When Context is Fresh (After Compaction)

**Don't Panic**: Context compaction is normal and expected

**Discovery Protocol**:
1. **Filesystem Discovery** (more reliable than compaction summary):
   ```bash
   git status              # Current changes
   git log --oneline -10   # Recent work
   cat memory-bank/always/system-status.json  # Feature status
   ```

2. **Re-read Critical Files**:
   - memory-bank/always/CORE-PATTERNS.md
   - Relevant Entry from memory-bank/learned/
   - Feature-specific files if needed

3. **Trust the System**:
   - Git history is complete
   - system-status.json is up-to-date
   - Compaction summaries provide context

---

## Evidence

**Source**: Anthropic's Claude 4 Engineering Blog + Best Practices
**Used In**: production (162+ entries, multi-month project)
**Success**: Multi-session continuity maintained across 100+ sessions
**Time Cost**: 2 min per session start
**Time Saved**: 10-30 min per session (vs getting oriented randomly)

**Key Insight from Anthropic**:
> "Focus on incremental progress—making steady advances on a few things at a time rather than attempting everything at once."

---

## Integration

**Used With**:
- `system-status.json` - Feature tracking
- `/session-end` protocol - Checkpointing before closing
- memory-bank/learned/ - Entry references
- Git commits - Progress tracking

**Complements**:
- session-end-checkpoint-skill (if you create it)
- troubleshooting-decision-tree-skill
- Project patterns from CORE-PATTERNS.md

---

## Success Criteria

**You've mastered this protocol when**:
- [x] Can start any session in < 2 min
- [x] Always know what you were working on
- [x] Never duplicate completed work
- [x] Can resume after context compaction without confusion
- [x] Focus on ONE task at a time (incremental progress)

---

## Example Session Start

```
$ git status
On branch feature/new-auth
Changes not staged for commit:
  modified:   src/auth/controller.js

$ cat memory-bank/always/system-status.json | jq '.features[] | select(.passes == false)'
{
  "name": "Authentication_System",
  "status": "implementing",
  "passes": false,
  "entry": 15
}

$ git log --oneline -3
abc1234 feat: Add JWT token validation
def5678 feat: Create auth middleware
ghi9012 feat: Setup auth routes

👉 Goal for this session: Complete JWT token refresh logic
👉 Reference: Entry #15 in memory-bank/learned/
👉 Expected: Mark Authentication_System passes: true by end of session
```

---

## Quick Reference

```bash
# Quick session start
git status && \
cat memory-bank/always/system-status.json | jq '.features[] | select(.passes == false)' && \
git log --oneline -5

# If you have a /session-start command configured:
/session-start
```
