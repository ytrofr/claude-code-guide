---
layout: default
title: "Session Lifecycle"
parent: "Part II — Workflow"
nav_order: 5
redirect_from:
  - /docs/guide/04-task-tracking-system.html
  - /docs/guide/04-task-tracking-system/
  - /docs/guide/23-session-documentation-skill.html
  - /docs/guide/23-session-documentation-skill/
  - /docs/guide/32-document-automation.html
  - /docs/guide/32-document-automation/
  - /docs/guide/42-session-memory-compaction.html
  - /docs/guide/42-session-memory-compaction/
---

# Session Lifecycle

A Claude Code session has a predictable shape: it starts, it does work, it hits context limits and compacts, and eventually it ends. Most quality loss happens at the seams — starting a session with no context, losing details in compaction, ending without writing anything down so the next session starts from zero again.

This chapter covers the full lifecycle as one continuous workflow: **start → work → mid-session documentation → compaction → end → handoff**. Each seam has a primitive (skill, hook, file) that preserves the details that matter.

**Purpose**: Keep context focused, preserve details across compaction, and make every session's output recoverable
**Difficulty**: Beginner
**Time**: 10 minutes to wire up the primitives; ongoing awareness during work

---

## Lifecycle at a Glance

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Start     │ ──► │    Work     │ ──► │  Compaction │ ──► │     End     │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
      │                    │                    │                   │
      │                    │                    │                   │
  /session-start       Task tracking       PreCompact hook      /session-end
  Memory load          /document           Recovery guidance    /document
  Branch detect        Checkpoints         75% rule             Commit checkpoint
```

Each transition has a primitive. Running all four produces the steady state where every new session starts with full context of the last one, and every session ends with a durable record of what happened.

---

## Session Start

The first thing Claude does when a session opens is orient itself: what branch am I on, what was the last session working on, what's the system state. Done manually every time, this costs 3-5 minutes of "let me check..." turns. Done via `/session-start`, it's sub-second.

### What `/session-start` does

1. **Git context**: `git status`, `git log --oneline -5`, current branch
2. **System state**: reads the project's status file (e.g., `system-status.json`, `MEMORY.md`)
3. **Recent work**: lists entries from the last session or two, relevant plans
4. **Branch rules**: loads branch-specific rules if the project uses per-branch context
5. **Reports**: one-paragraph summary of "where we are"

A minimal `/session-start` skill uses dynamic injection to pre-compute git context (`` !`git status --short` ``, `` !`git log --oneline -5` ``), reads the project status file, lists recent entries, and emits a one-paragraph summary. Full skill template is in the `session-start` skill itself.

### Multi-session continuity

The point of `/session-start` isn't the git info — that's instant anyway. The point is the **handoff**: the last session wrote something, this session reads it. The handoff files are:

| File | Purpose | Written by |
|------|---------|------------|
| Project status file (`system-status.json`, `MEMORY.md`) | Current feature flags, active blockers, recent fixes | `/session-end` or `/document` |
| Entry files (`entry-XXX-topic.md`) | Per-session learnings | `/document` |
| Plan files (`.claude/plans/*.md`) | In-progress plans | Plan mode |
| Roadmap (`CURRENT/{branch}-ROADMAP.md`) | Open tasks per branch | `/document` |

If these files are kept current, every session inherits the last session's state for free.

---

## Task Tracking During Work

Within a session, two tracking mechanisms coexist:

| Mechanism | Scope | Purpose |
|-----------|-------|---------|
| `TaskCreate` / `TaskUpdate` (built-in) | Current session | Within-session work tracking; shows in-progress / completed in the UI |
| Roadmap files (`*-ROADMAP.md`) | Cross-session | Open tasks across sessions, priority-organized, quick wins highlighted |

Both are used. `TaskCreate` is lightweight and ephemeral — perfect for "here are the 4 steps I'm about to do." The roadmap is durable — that's where tasks that outlive this session live.

### When to use TaskCreate

Create a task list **proactively** when any of these are true, without waiting for the user to ask:

- The work has 2+ distinct implementation steps
- The user provided a numbered or bulleted list of items
- Multi-file changes are coming
- The work will span significant context (risk of losing track)
- The user described a feature, bug fix, or refactor with multiple changes

Do **not** use `TaskCreate` for single-file fixes, pure research, or simple Q&A.

### Task hygiene

1. **Create upfront**: after understanding scope, create all tasks before starting
2. **Mark in_progress**: *before* starting work on the task, not after
3. **Mark completed**: *only after* verification passes (tests, curl, visual check)
4. **Never mark complete if** tests fail, errors exist, or implementation is partial
5. **Add follow-ups**: discovered subtasks get added as new tasks, not ignored
6. **Work in order**: lowest ID first unless dependencies say otherwise

### Task quality

- `subject`: imperative ("Fix auth bug"), not noun ("Auth bug")
- `activeForm`: present continuous ("Fixing auth bug")
- `description`: enough detail for another agent to understand and execute

**Anti-pattern**: creating a task, doing the work, marking complete without testing.
**Correct**: create → in_progress → implement → verify → completed.

### The durable roadmap

For cross-session tracking, a per-branch roadmap file works well:

```markdown
# dev-Auth ROADMAP

## Open — P1 (0 items)
(none)

## Open — P2 (3 items, ~2.5h)
| Task            | Time  | Details                          |
|-----------------|-------|----------------------------------|
| Add_API_Cache   | 1h    | Redis caching for /api/data      |
| Fix_Mobile_Nav  | 30m   | Hamburger not closing on click   |
| Update_Docs     | 1h    | Add deployment section to README |

## Open — P3 (2 items, ~1.5h)
| Task           | Time  | Details                       |
|----------------|-------|-------------------------------|
| Refactor_Utils | 1h    | Split utils.js into modules   |
| Add_Dark_Mode  | 30m   | CSS vars already prepared     |

## Quick Wins (do first)
- Fix_Mobile_Nav — 30m
- Add_Dark_Mode — 30m

## Completed (archived)
| Task        | Completed   | Entry    |
|-------------|-------------|----------|
| Setup_CI_CD | 2026-02-15  | #163     |
| Add_Auth    | 2026-02-10  | #158     |
```

Keep only **open** items in the active section. Move completed items to the archive table — don't delete them (future sessions may need the history) and don't load them into context (tokens wasted on tasks that no longer matter).

---

## Mid-Session Documentation — /document

In the middle of a long session, the `/document` skill captures what's been done so far without ending the session. It's the difference between "remember what I did 3 hours ago" and "here's a durable record of what I did 3 hours ago."

### What `/document` does

The skill runs a 13-step workflow across four phases:

**Phase 1 — Context gathering**
1. `git diff`, `git status`, `git log --oneline -5`
2. Analyze what was accomplished

**Phase 2 — Core documentation**
3. Create an entry file with the next available number (`entries/entry-XXX-topic.md`)
4. Update the branch roadmap (move completed tasks to archive)
5. Update the project status file (recent fixes, feature flags)

**Phase 3 — Pattern analysis (the interesting part)**
6. Is this pattern repeatable (20+/year) and saving ≥1h? → suggest a **skill**
7. Is this enforcement-level learning? → suggest a **rule** (and classify its level)
8. Is it quick reference (<5 lines)? → suggest a **core-patterns update**
9. Is it a 3+ file system change? → suggest a **blueprint**

**Phase 4 — Execute and commit**
10. Present suggestions to the user; they pick which to execute
11. Execute selected suggestions
12. Single commit: entry + roadmap + status + any new rules/skills/blueprints
13. Validate cross-references

### The 3-level pattern analysis

When step 7 suggests a rule, it classifies the rule to the right level:

```
Pattern discovered
    │
    ├─ Applies to ANY project on this machine?
    │  (tech-agnostic, universal NEVER/ALWAYS)
    │  YES → MACHINE RULE (~/.claude/rules/{category}/)
    │
    ├─ Applies to ALL branches of THIS project?
    │  (project conventions, tech stack rules)
    │  YES → PROJECT RULE (.claude/rules/)
    │
    ├─ Specific to current sprint/branch/feature?
    │  YES → BRANCH RULE (branch-specific config)
    │
    └─ None of the above → skip; it's not a rule
```

**Classification examples**:

| Pattern | Level | Why |
|---------|-------|-----|
| "Never kill all node processes on WSL" | Machine | OS-specific, all projects |
| "Use barrel exports for 5+ file dirs" | Machine | Universal code organization |
| "Always use pgvector for embeddings" | Project | Project-specific tech choice |
| "Hebrew text must use RTL containers" | Project | Only relevant to this project |
| "Feature X requires flag Y this sprint" | Branch | Temporary, sprint-scoped |

### Duplicate prevention

Before suggesting anything, `/document` scans existing rules/skills at all 3 levels. If a rule for this pattern already exists, it suggests **UPDATE** instead of **NEW**. If the rule exists at the wrong level (project rule that should be machine-level), it suggests **MOVE**.

Without this scan, `/document` would slowly duplicate rules across the hierarchy. With it, the rule set stays clean.

### When to run /document

- End of a non-trivial session (before `/session-end`)
- After finishing a multi-step feature or fix
- Before switching branches or pausing work
- When you've learned something you'll want to remember next week
- **Not** for single-line fixes — there's nothing to document

A typical session has 1-2 `/document` runs: one mid-session if the work naturally breaks into phases, one at session end.

---

## Compaction — The 75% Rule

Claude Code auto-compacts context when usage approaches capacity (~95%). Earlier messages are summarized into a shorter form. What's preserved: recent messages, active tool calls, `CLAUDE.md`, rules files. What's lost: exact error messages, early-session file paths, nuanced corrections, debugging context.

**Before compaction**:
> "The bug was in line 47 of src/auth/middleware.js — the token validation used === instead of jwt.verify(). We tried 3 approaches before finding this."

**After compaction**:
> "Fixed an authentication bug."

The specific line number, root cause, and failed attempts are gone.

### Why 75%, not 95%

Anthropic's research shows code quality degrades as context fills past 75%. By the time auto-compaction kicks in at 95%, Claude has already been producing lower-quality work for 20% of the session. Proactive checkpointing at 75% keeps quality high throughout.

Practically:

1. **At 75% context**: checkpoint with `git commit -m "checkpoint: [description]"`
2. **Start fresh**: new session with clean context
3. **Recover**: use `git log` + `git status` to re-establish state

### Monitoring context

- Type `/context` inside a session to see usage
- Configure a statusline in `~/.claude/settings.json` to show context percentage continuously
- Heuristic: 30+ minutes of active work with heavy file reads usually means you're past 50%

---

## The PreCompact Hook

A `PreCompact` hook runs just before compaction happens. It outputs guidance on what to preserve — the message appears in context right before summarization, so the summarizer reads it and follows it.

### Priority order for compaction

1. **Errors and corrections** — verbatim. User corrections are learned preferences; losing them means repeating mistakes.
2. **Active work** — current file, current task, current state. Needed to continue immediately.
3. **Completed work** — exact file paths, line numbers, specific values.
4. **Pending tasks** — what hasn't started yet.
5. **Key references** — entry numbers, branch names, PR numbers, IDs.

### Example hook

```bash
#!/bin/bash
# .claude/hooks/pre-compact.sh
cat << 'EOF'
=== COMPACTION GUIDANCE ===
When summarizing this conversation, preserve in this EXACT order:

1. ERRORS & CORRECTIONS (verbatim — these are learned preferences)
2. ACTIVE WORK (current file, current task, current state)
3. COMPLETED WORK (exact paths, exact values, exact line numbers)
4. PENDING TASKS (not yet started)
5. KEY REFERENCES (entry numbers, branch names, PR numbers)

CRITICAL: Keep direct user quotes for corrections.
These represent preferences that must not be lost.
=== END GUIDANCE ===
EOF
exit 0
```

Wire it into settings:

```json
{
  "hooks": {
    "PreCompact": [
      {
        "hooks": [
          { "type": "command", "command": "bash .claude/hooks/pre-compact.sh" }
        ]
      }
    ]
  }
}
```

### PostCompact re-injection

After compaction, Claude Code restores recently-relevant files automatically, with strict budgets:

| Parameter | Value |
|-----------|-------|
| Max files restored | 5 |
| Total token budget | 50,000 |
| Per-file token cap | 5,000 |
| Skills token budget | 25,000 |
| Per-skill token cap | 5,000 |

Files exceeding the per-file cap are skipped entirely. This is an internal optimization — not user-configurable — but understanding it explains why Claude sometimes "remembers" files after compaction and sometimes doesn't. For critical small files, list them in `CLAUDE.md` or a rules file; those always reload.

### Compaction boundary guard

One subtle trap: compaction must never split a tool-use / tool-result pair. The internal boundary walker scans backwards from the cut point to the nearest complete exchange. If you build custom compaction (e.g., a PreCompact hook that manually truncates history), always ensure your truncation point doesn't land between paired tool messages. Orphaned tool-use or tool-result messages cause:

- **Gemini/ADK**: confused agent routing — `_find_agent_to_run()` reads the orphaned call as the last-speaking agent
- **OpenAI-compatible endpoints**: 400 validation error rejecting the malformed sequence
- **Claude**: may attempt to re-execute the orphaned tool call

Safe approach: walk backwards from your proposed cut until you find a user message that isn't a tool-result.

---

## /clear vs Compaction

Two ways context resets, with different recovery needs:

| Aspect | Auto-compaction | Manual `/clear` |
|--------|-----------------|-----------------|
| When | ~95% context | User types `/clear` |
| What happens | Early messages summarized | ALL messages removed |
| `CLAUDE.md` | Preserved | Preserved |
| Recent context | Preserved (most recent turns) | Gone |
| Recovery | Usually seamless | Must re-establish state |

### When to /clear

- Between unrelated tasks (don't carry task A's context into task B)
- After 2 failed correction attempts — fresh context helps more than more corrections
- At 75% context — checkpoint and start fresh

### When NOT to /clear

- Mid-feature (you'll lose the context about what you're building)
- After complex debugging (you'll lose the debugging trail)
- When corrections were made (those corrections guide the rest of the session)

### CLAUDE.md recovery section

Add a recovery section to `CLAUDE.md` so the instructions survive every compaction and `/clear`:

```markdown
## Recovery (after compaction or /clear)

If this is a fresh context, discover state:

1. `git log --oneline -5` — recent commits
2. `git status` — current changes
3. Read the project status file — feature status
4. Check the plan file if referenced above
```

---

## Session End — /session-end and Final /document

Ending a session cleanly takes 2 minutes and pays back every time. The steps:

1. **`/document`** — captures the session as an entry, updates roadmap and status, runs pattern analysis
2. **`/session-end`** — final checkpoint commit, optionally writes a session-summary note to persistent memory
3. **Push if appropriate** — only if the user asked; otherwise leave on a local branch

### What /session-end does

1. Check if `/document` was run; if not, suggest running it first
2. Run `git status`; if there are uncommitted changes, create a checkpoint commit (`git commit -m "checkpoint: [one-line description]"`)
3. Write a session-summary note to persistent memory: branch, commits, entry numbers, open tasks, anything the next session needs
4. Report: "Session ended. N commits. M entries. K tasks still open."

The session-summary is what makes the next `/session-start` valuable — if this session didn't write anything, the next session starts blind.

### Don't rely on the user running /session-end

Most users don't use `/session-end`. They close the terminal or let the session time out. This is fine — as long as `/document` ran at natural checkpoints during the session, the durable record survives. Design the workflow so that session *end* is graceful even if it's abrupt: every `/document` call leaves the project in a state where abrupt termination loses nothing important.

---

## Multi-Session Continuity

Tying it all together — the steady-state loop across sessions looks like:

```
Session N-1:
  /session-start → work → /document (mid-session checkpoint) →
  work → /document (end) → /session-end → close

Session N (next day):
  /session-start → reads entry from N-1, sees open tasks,
                   inherits branch context → work continues
```

The artifacts that flow between sessions:

| Artifact | What it carries | Read by |
|----------|-----------------|---------|
| Entry file (`entries/entry-XXX-topic.md`) | What happened, why, evidence | `/session-start` as recent context |
| Roadmap (`*-ROADMAP.md`) | Open tasks per branch | `/session-start` to see what's left |
| Status file (`system-status.json`, `MEMORY.md`) | Feature flags, active blockers, recent fixes | Loaded every session (always-on) |
| Plan file (`.claude/plans/*.md`) | In-progress plan | Referenced when continuing the plan |
| Persistent memory (Basic Memory MCP or equivalent) | Cross-project knowledge | `/session-start` query by branch/topic |

If all five are current at the end of session N-1, session N loses nothing. If any are stale, session N starts blind on that dimension.

---

## Anti-Patterns

**Ending a session without running /document.**
Every learning in the session is now in a random place in your scroll history. Next session starts blind on it.

**Loading completed tasks into context.**
Completed tasks waste tokens and add noise. Archive them in a separate table; load only open tasks.

**Manually updating 3 files at session end.**
That's what `/document` is for. Manual 3-file updates are error-prone — easy to forget one of the three.

**Relying on user-invoked session lifecycle.**
Most users don't run `/session-start` or `/session-end`. Build durability into `/document` so that abrupt session termination loses nothing critical.

**Compacting early.**
Compaction is free if it happens at 95%. Compacting at 50% by running `/clear` wastes the accumulated context. Only `/clear` when switching tasks.

**Skipping the PreCompact hook.**
Compaction without guidance drops corrections first (they're older and shorter than recent file reads). Losing corrections means repeating mistakes.

**Creating one monolithic entry for a whole week's work.**
Entries are per-session. Weekly summaries are a different artifact. Keeping them separate makes entries searchable and summaries scannable.

---

## Key Takeaways

1. **Every lifecycle seam has a primitive.** `/session-start` → task tracking → `/document` → PreCompact hook → `/session-end`. Wire them once; use them automatically.
2. **`TaskCreate` is ephemeral; roadmap is durable.** Use `TaskCreate` proactively (2+ steps, multi-file, feature work). Use the roadmap for cross-session tasks.
3. **`/document` runs 3-level pattern analysis.** Machine / project / branch. It scans for duplicates before suggesting new rules. It writes entries, roadmap updates, status updates, and the commit in one shot.
4. **Checkpoint at 75%, not 95%.** Quality degrades past 75%. Proactive checkpoint + new session beats auto-compaction every time.
5. **The PreCompact hook preserves corrections.** Priority order: errors/corrections → active work → completed work → pending tasks → references.
6. **`/clear` and auto-compaction need different recovery.** `/clear` wipes everything; add a recovery section to `CLAUDE.md` so state rediscovery survives.
7. **Multi-session continuity lives in files, not memory.** Entries + roadmap + status + plan file + persistent memory. If all five are current, next session starts with full context.
8. **Don't rely on user-invoked lifecycle.** Run `/document` at natural checkpoints during the session so abrupt termination loses nothing important.
