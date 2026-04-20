---
layout: default
title: "Session End and Defrag Workflow"
parent: "Part V — Advanced"
nav_order: 7
---

# Session End and Defrag Workflow

How to close a Claude Code session cleanly and keep memory sharp over time. Two skills, two different cadences: `/session-end` every session that produced something worth remembering; `/memory-defrag` monthly, when memory files start to drift into noise.

---

## Why bother

Session-end discipline prevents knowledge loss between sessions. Without it, Claude Code becomes a rolling window of context that forgets its own learnings — pattern `X` gets rediscovered, session after session, minus the evidence of why `X` is the right answer.

The failure mode looks like this:

- Session 1: wrestle with a tricky LLM retry pattern, arrive at a working solution.
- Session 2 (days later, fresh context): hit the same symptom, re-wrestle, arrive at a *different* working solution.
- Session 3: the two solutions drift. Now there are two "right answers" in the codebase.

A one-minute session-end ritual collapses that cost to zero: write the insight down once, in a canonical place, and every future session sees it.

---

## The `/session-end` skill

The skill runs a short structured closing. Typical flow:

1. **Surface uncommitted state** — `git status --short`, incomplete features, open `TODO` markers.
2. **Extract learnings** — ask: what did this session teach me? (Pattern, gotcha, decision, fix.)
3. **Categorize** — feedback note vs project note vs reference vs skill candidate.
4. **Write to memory** — append to the appropriate Basic Memory note or auto-memory file.
5. **Checkpoint or commit** — don't leave work half-committed.
6. **Update handoff** — brief "next steps" note so the next session picks up smoothly.

### Verification checklist (what `/session-end` enforces)

- [ ] All work committed or checkpointed?
- [ ] Any system-status file updated with progress?
- [ ] No features left in unknown state?
- [ ] Descriptive commit message created (not `wip`, not `fix`)?

### When to run

- After any session that produced a non-trivial learning (bug fix, new pattern, decision).
- Before context approaches its compact threshold.
- When you're about to close the terminal for the day.

### When NOT to run

- Pure exploration / reading sessions with no changes.
- One-off trivial edits (typo fix, dependency bump).
- Sessions where you haven't actually learned anything — forced session-end notes are noise.

The skill is an optimizer, not a religion. The gate is "did this session produce knowledge worth preserving?"

---

## The `/memory-defrag` skill

Over time, memory files accumulate. Daily notes pile up. The same fact gets written in three places. Stale entries reference projects that have shipped or been abandoned. MEMORY.md bloats past 500 lines and becomes slow to scan.

`/memory-defrag` is the periodic cleanup — like filesystem defrag, but for knowledge.

### Process

1. **Audit current state** — inventory all memory files. For each: line count, last modified, topic coverage, staleness.
2. **Identify problems** — from the checklist below.
3. **Plan changes** — write a short `Defrag Plan` with bullet items.
4. **Execute one at a time** — split, merge, prune, restructure.
5. **Verify & log** — ensure nothing was lost; record what was done in today's daily note.

### Common issues to fix

| Problem | Signal | Fix |
|---------|--------|-----|
| **Bloated file** | >300 lines, covers many topics | Split into focused files |
| **Duplicate info** | Same fact in multiple places | Consolidate to one location |
| **Stale entries** | References to completed work, resolved issues | Remove or archive |
| **Orphan files** | Files never referenced or updated | Review, merge, or remove |
| **Orphan skill refs** | Notes mention skills that no longer exist | Update or delete reference |
| **Inconsistencies** | Contradictory info across files | Resolve to ground truth |
| **Poor organization** | Related info scattered | Restructure by topic |

### Run cadence

- **Monthly** — the default. Memory drift compounds slowly; monthly is enough to keep it bounded.
- **On demand** — when MEMORY.md crosses ~500 lines or you notice "I had this noted somewhere but can't find it".
- **Not weekly** — weekly defrag is churn, not maintenance. You'll burn time rewriting things that were fine.

---

## Staleness SLAs (recap from `rules/ai/knowledge-lifecycle.md`)

Every note type has a freshness threshold. After the SLA expires without an edit, the note is flagged for review during `/memory-defrag` or the monthly AI DNA health check.

| Note type | Max age | Action when stale |
|-----------|---------|-------------------|
| `decision` | 90 days | Review: still valid? Update status or confirm |
| `investigation` | 60 days | Archive unless actively referenced |
| `log` | 30 days | Auto-archive (ephemeral by nature) |
| `note` | 120 days | Flag for review |
| `research-cache` | 90 days | Re-search if technology has changed |
| `ai-dna/*` | 60 days | Validate against current code |

Stale ≠ wrong. Stale = "has not been checked against current reality recently enough to trust blindly". The SLA forces a look.

---

## Manual session-end checklist (when the skill isn't available)

If `/session-end` isn't installed in your setup, run this by hand:

- [ ] `git status` — commit or checkpoint anything uncommitted.
- [ ] If non-trivial: write a one-line memory entry (feedback note or project note). Location: `~/.claude/projects/<project>/memory/MEMORY.md` or a Basic Memory note.
- [ ] Update any affected plan file (mark tasks done, log blockers).
- [ ] Note any follow-ups in a handoff file or the project's active task list.
- [ ] If this was a failure mode worth remembering: add to `production-gotchas.md` or equivalent.

Takes 2–5 minutes. Saves hours of re-learning in future sessions.

---

## Automation integrations

The manual workflow is the fallback. In a mature setup, scripts and hooks do most of the maintenance:

| Automation | Frequency | What it does |
|------------|-----------|--------------|
| `~/.claude/scripts/ai-knowledge-consolidation.sh` | Weekly (Sun) | Review growth log, flag stale notes, write consolidation log |
| `~/.claude/scripts/bm-daily-maintenance.sh` | Daily | Basic Memory reindex + growth counter |
| `/memory-defrag` skill | Monthly | Human-in-the-loop reorganization |
| `/session-end` skill | Per-session | Capture learnings, commit, checkpoint |

The scripts surface *what* needs attention. The skills do the thinking. The human makes the judgement calls (is this pattern universal? is this note still relevant?).

---

## Anti-patterns

- **Running `/session-end` on every session regardless of whether learnings emerged.** Noise in memory is worse than absence — it dilutes the signal.
- **Defragging every week.** `/memory-defrag` is meant to be monthly. More frequent = churn, not maintenance. You'll rewrite notes that were fine.
- **Letting `ai-dna/*` grow unchecked.** The 60-day SLA exists for a reason. AI infrastructure changes fast; a 6-month-old pattern may be obsolete.
- **Deleting raw daily notes during defrag.** Daily notes are the audit trail. Consolidate insights into topic files, but don't destroy the originals.
- **Skipping the commit/checkpoint step at session-end.** Uncommitted WIP across sessions is how you lose a day of work to a tab crash.
- **Writing session-end notes that say "worked on X, made progress".** Worthless. If the note doesn't capture a *specific* insight, don't write it.

---

## See also

- [Skill lifecycle](../part4-context-engineering/07-skill-lifecycle.html) — archive/delete thresholds for skills themselves.
- [AI DNA shared-layer](01-ai-dna-shared-layer.html) — the methodology; `/session-end` feeds its growth log.
- [Session lifecycle](../part2-workflow/05-session-lifecycle.html) — session start, flags, and lifecycle mechanics.
