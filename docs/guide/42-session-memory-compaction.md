---
layout: default
title: "Session Memory & Compaction - Preserve Context Across Long Sessions"
description: "Handle Claude Code context compaction with structured memory prompts. Preserve critical information during auto-compaction and manual /clear. Recovery patterns for fresh context."
---

# Chapter 42: Session Memory and Compaction

Claude Code sessions have finite context. When you approach the limit, context gets compacted -- earlier messages are summarized to make room. If you're not prepared, you lose critical details. This chapter covers how compaction works, how to structure information for preservation, and how to recover after compaction.

**Purpose**: Preserve critical session context through compaction events
**Source**: Anthropic session_memory_compaction.ipynb + production patterns
**Difficulty**: Intermediate
**Time**: 15 minutes to set up, ongoing awareness

---

## How Compaction Works

Claude Code automatically compacts context when usage approaches capacity (default: ~95%). During compaction, earlier messages are summarized into a shorter form.

**What gets preserved**: Recent messages, active tool calls, system instructions (CLAUDE.md, rules).
**What gets lost**: Exact error messages, specific file paths from early in the session, nuanced corrections you made, debugging context.

### The Problem

Without preparation, compaction loses the details that matter most:

```
Before compaction: "The bug was in line 47 of src/auth/middleware.js --
  the token validation used === instead of jwt.verify().
  We tried 3 approaches before finding this."

After compaction: "Fixed an authentication bug."
```

The specific line number, file path, root cause, and failed attempts are gone.

---

## SESSION_MEMORY_PROMPT Structure

Structure your working context so the most important information survives compaction. This template defines preservation priority:

### Priority Order (Highest to Lowest)

1. **Errors & Corrections** -- Direct quotes of what went wrong and what fixed it
2. **Active Work** -- Where work left off, current state
3. **Completed Work** -- Exact identifiers, specific values, file paths
4. **Pending Tasks** -- What hasn't started yet
5. **Key References** -- IDs, paths, URLs, API keys

### Template

```markdown
## Session Memory (Compaction-Safe)

### 1. Errors & Corrections (HIGHEST PRIORITY)

- [Exact error message and fix, verbatim]
- [User corrections -- represent learned preferences]

### 2. Active Work

- Currently working on: [specific task]
- File being modified: [exact path]
- State: [what's done, what's next]

### 3. Completed Work

- [Feature]: [exact file paths, line numbers, specific values]
- [Fix]: [what was wrong, what was changed, evidence it works]

### 4. Pending Tasks

- [ ] [Task with specific details]
- [ ] [Task with specific details]

### 5. Key References

- Entry: #NNN
- Branch: dev-XXX
- PR: #NNN
- API key: [reference, not value]
```

### Why This Order

**Corrections are #1** because they represent learned preferences. If the user corrected you from using `id` to `employee_id`, losing that correction means you'll repeat the mistake. Corrections are the highest-signal, lowest-volume information in a session.

**Active work is #2** because it's what you need to continue immediately after compaction. Knowing "I was editing line 47 of auth.js" is more actionable than knowing "I finished the database migration."

---

## PreCompact Hook

Use a `PreCompact` hook to output structured memory guidance before compaction occurs:

```json
{
  "hooks": {
    "PreCompact": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/pre-compact.sh"
          }
        ]
      }
    ]
  }
}
```

**Example hook** (`.claude/hooks/pre-compact.sh`):

```bash
#!/bin/bash
# Output compaction guidance as structured message

cat << 'COMPACTION_GUIDANCE'
=== COMPACTION GUIDANCE ===
When summarizing this conversation, preserve in this EXACT order:

1. ERRORS & CORRECTIONS (verbatim - these are learned preferences)
2. ACTIVE WORK (current file, current task, current state)
3. COMPLETED WORK (exact paths, exact values, exact line numbers)
4. PENDING TASKS (not yet started)
5. KEY REFERENCES (entry numbers, branch names, PR numbers)

CRITICAL: Keep direct user quotes for corrections.
These represent preferences that must not be lost.
=== END GUIDANCE ===
COMPACTION_GUIDANCE

exit 0
```

This message appears in the context just before compaction, guiding the summarization to preserve the right details.

---

## /clear vs Compaction

Two ways context resets -- they need different recovery strategies:

| Aspect         | Auto-Compaction               | Manual `/clear`            |
| -------------- | ----------------------------- | -------------------------- |
| When           | ~95% context usage            | User types `/clear`        |
| What happens   | Early messages summarized     | ALL messages removed       |
| CLAUDE.md      | Preserved                     | Preserved                  |
| Recent context | Preserved (most recent turns) | Gone                       |
| Recovery       | Usually seamless              | Need to re-establish state |

### When to Use /clear

- **Between unrelated tasks**: Don't carry context from Task A into Task B
- **After 2 failed correction attempts**: If Claude keeps making the same mistake, fresh context helps more than more corrections
- **At 75% context**: Anthropic research shows code quality degrades after 75%. Checkpoint and start fresh.

### When NOT to Use /clear

- **Mid-feature**: You'll lose all the context about what you're building
- **After complex debugging**: You'll lose the debugging trail
- **When corrections were made**: Those corrections guide the rest of the session

---

## Recovery After Compaction

When you notice context has been compacted (or after `/clear`), recover state from the filesystem:

### Quick Recovery Script

```bash
# Run after compaction to re-establish context
git log --oneline -10           # What was recently committed
git status                      # What's currently changed
git diff HEAD~1 --stat          # What the last commit changed
```

### CLAUDE.md Recovery Section

Add a recovery section to your CLAUDE.md that loads automatically:

```markdown
## Recovery (After Compaction)

If this is a fresh context, discover state:

1. `git log --oneline -5` -- recent commits
2. `git status` -- current changes
3. Read `system-status.json` -- feature status
4. Check plan file if referenced above
```

This ensures recovery instructions survive compaction (CLAUDE.md is always loaded).

---

## The 75% Rule

Anthropic's research shows that code quality degrades as context fills past 75%. This has practical implications:

1. **At 75%**: Checkpoint your work (`git commit -m "checkpoint: [description]"`)
2. **Start fresh**: New session with clean context
3. **Recover**: Use git log + status to re-establish state

**Why 75%, not 95%?**: By the time auto-compaction kicks in at 95%, you've already been producing lower-quality code for 20% of the session. Proactive checkpointing at 75% keeps quality high throughout.

### Checkpoint Pattern

```bash
# Before hitting 75%:
git add -A && git commit -m "checkpoint: implemented auth middleware, tests passing"

# In new session:
git log --oneline -3  # See where you left off
git diff HEAD~1       # See what the checkpoint contains
# Continue from there
```

---

## Monitoring Context Usage

Check your context usage to know when to checkpoint:

- **In Claude Code**: Type `/context` or press `c` in the status bar
- **Custom statusline**: Configure in `~/.claude/settings.json` to show context percentage
- **Heuristic**: If you've been working for 30+ minutes with lots of file reads, you're likely past 50%

---

## Best Practices Summary

1. **Structure session memory** with the priority template (errors > active > completed > pending > references)
2. **Use PreCompact hook** to guide compaction summarization
3. **Checkpoint at 75%** -- don't wait for auto-compaction
4. **Use /clear between tasks** -- don't carry stale context
5. **Add recovery instructions to CLAUDE.md** -- they survive compaction
6. **After correction, note it explicitly** -- "Remember: use employee_id not id" survives better than implicit correction

---

**Previous**: [41: Evaluation Patterns](41-evaluation-patterns.md)
**Next**: [43: Claude Agent SDK](43-claude-agent-sdk.md)
