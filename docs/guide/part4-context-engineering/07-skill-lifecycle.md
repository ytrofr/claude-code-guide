---
layout: default
title: "Skill Lifecycle — Archive, Delete, Promote"
parent: "Part IV — Context Engineering"
nav_order: 7
---

# Skill Lifecycle — Archive, Delete, Promote

**Current as of**: Claude Code 2.1.111+.
**Related**: [Chapter 04 — Context Budget](./04-context-budget.html), [Chapter 06 — Context Governance](./06-context-governance.html)

---

## Why a lifecycle

Skills accumulate. Each one you author feels useful at the time — a one-off retrospective, a workflow you want to capture, an experiment you want to remember. Six months later you have 180 skills, a 40 KB description budget ceiling, and no memory of which ones actually fire.

Three costs grow without you noticing:

1. **Skill budget pressure.** Every skill description counts against the global budget (default 2% of context, ~16 K chars; typically overridden to 40 K). When the budget fills, Claude Code silently drops skills — no warning, no error. The skills that "stop working" weren't deleted; they were pushed out.

2. **Description drift.** An old skill's description lists triggers that no longer match how you work. It auto-invokes on the wrong messages and doesn't invoke on the right ones. You stop trusting auto-invocation.

3. **Reference rot.** Skills reference other skills, rules, or files that have since moved or been deleted. The skill loads, then errors out when it tries to fetch the missing dependency.

The cure is discipline, applied on a cadence. This chapter covers the archive/delete/promote loop, the telemetry that makes it possible, and the quality gates that keep the remaining skills useful.

---

## Tracking invocations

You can't decide a skill is stale without knowing when it last fired. Claude Code doesn't track this by default. You add it with a `PostToolUse` hook matching the `Skill` tool.

### The activation logger hook

```bash
#!/bin/bash
# ~/.claude/hooks/skill-activation-logger.sh
INPUT=$(timeout 1 cat 2>/dev/null || exit 0)
SKILL=$(echo "$INPUT" | jq -r '.tool_input.skill // empty' 2>/dev/null)
SESSION=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
[ -z "$SKILL" ] && exit 0

METRICS_DIR="${HOME}/.claude/metrics"
mkdir -p "$METRICS_DIR" 2>/dev/null
printf '{"timestamp":"%s","epoch":%s,"matched_skills":"%s","session_id":"%s","hour":%s}\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$(date +%s)" "$SKILL" "$SESSION" "$(date -u +%H)" \
  >> "$METRICS_DIR/skill-activations.jsonl" 2>/dev/null
exit 0
```

Register in `settings.json` as a `PostToolUse` matcher on `"Skill"` — **before** any `.*` catch-all. The Skill tool's `tool_input` contains a single string field `skill` (plus optional `args`), so `jq -r '.tool_input.skill'` is the authoritative source.

**Why PostToolUse, not PreToolUse**: logging an invocation that succeeded is more useful than logging one that was attempted. PostToolUse fires after the skill returns; failures are self-evident in the transcript.

**Atomic append pattern**: `printf ... >> file` is atomic for small writes on Linux ext4/btrfs. No file-locking needed for a fire-and-forget log.

### Querying the log

```bash
# Last 10 activations
tail -10 ~/.claude/metrics/skill-activations.jsonl

# Total activation count
wc -l ~/.claude/metrics/skill-activations.jsonl

# Top 10 most-invoked skills
grep '"matched_skills":' ~/.claude/metrics/skill-activations.jsonl | \
  python3 -c "import json,sys; from collections import Counter; \
  skills=[s for l in sys.stdin for s in json.loads(l).get('matched_skills','').split(',') if s]; \
  [print(f'{s}: {c}') for s,c in Counter(skills).most_common(10)]"

# Skills with zero invocations (candidates for archive/delete)
comm -23 \
  <(find ~/.claude/skills -name 'SKILL.md' -exec dirname {} \; | xargs -n1 basename | sort -u) \
  <(grep -oE '"matched_skills":"[^"]*"' ~/.claude/metrics/skill-activations.jsonl | \
      sed 's/"matched_skills":"//;s/"$//' | tr ',' '\n' | sort -u)
```

There's also a `/skill-metrics` skill for a formatted dashboard (summary stats, daily breakdown, peak hours).

---

## Staleness SLAs

With activation data in hand, you can apply concrete thresholds.

| Age (no invocation) | Action |
|---------------------|--------|
| 90 days | **Archive candidate** — scope to single project OR mark deprecated |
| 180 days | **Delete candidate** — hard-delete unless reference-only purpose |

These are SLAs, not deadlines. The monthly cadence reviews candidates, asks "is this still useful?", and acts accordingly.

### Why 90 and 180

Three months of inactivity is a strong signal the skill no longer matches your workflow. Six months means it probably never will again — the problem it solved has either been superseded by a rule, baked into a tool, or isn't part of what you do anymore.

Exceptions get called out explicitly:

- **Seasonal skills** (tax time, end-of-year audit) that genuinely fire once a year — keep them, accept the stale signal.
- **Reference-only skills** that users invoke by hand when they remember (e.g., a rare workflow) — document the expected cadence in the description.
- **Emergency-only skills** (recovery, rollback) — they should never fire often; their value is in existing when needed.

---

## Archive vs delete vs promote — decision tree

```
Skill has zero invocations in 90+ days
        │
        ▼
Is it reference-only (rare workflow, seasonal, emergency)?
   │
   ├─ YES → KEEP. Document expected cadence in description. Next review in 90 days.
   │
   └─ NO
        │
        ▼
   Is the content still unique (no other rule/skill covers it)?
      │
      ├─ NO (superseded, duplicate, or byte-identical to another skill)
      │     → DELETE. Hard-delete the directory.
      │
      └─ YES
           │
           ▼
      Does it only apply to one project?
         │
         ├─ YES → ARCHIVE. Move from ~/.claude/skills/ to .claude/skills/ (project scope).
         │
         └─ NO → KEEP but mark deprecated. Re-review at 180 days.
              │
              ▼
         At 180 days with still zero invocations → DELETE.
```

### Archive action

"Archive" doesn't mean "move to `.archive/`." It means **scope the skill down**. A universal skill that fires only for one project belongs at project level.

```bash
# From global to project-local
mv ~/.claude/skills/my-skill/ .claude/skills/my-skill/

# Verify
head -5 .claude/skills/my-skill/SKILL.md
```

The skill still works — Claude Code discovers skills at both levels. It just no longer loads its description for every other project. This reclaims budget where the skill has no value.

### Delete action

Hard-delete when the skill is superseded, a duplicate, or byte-identical to another:

```bash
rm -rf ~/.claude/skills/obsolete-skill/
```

Before deleting, grep your Memory notes and other skills for references to the name — dangling pointers are a different kind of rot. The missing-refs scanner (Chapter 06) catches these, but it's cheaper to fix them up front.

### Promote action

Promotion is the opposite direction: project skill → global skill.

---

## Promotion criteria (project → global)

Don't promote every project skill. A skill earns global status by proving utility across contexts.

- **Used in 2+ projects for 30+ days** (D0 activation data confirms — the jsonl tells you which sessions triggered it)
- **No project-specific file paths** in body (if the skill references `/home/you/proj/src/...`, it belongs at project level)
- **No project-specific terminology** (Sacred Commandments, specific API names, hardcoded ports)
- **Description contains explicit trigger clause** ("Use when...") — otherwise Claude Code can't auto-invoke it

```bash
# Move from project to global
mv .claude/skills/my-skill/ ~/.claude/skills/my-skill/

# Verify the description has a trigger
grep -A1 "^description:" ~/.claude/skills/my-skill/SKILL.md
```

---

## Description quality gate

A skill without a trigger clause is effectively dead. Claude Code's auto-invocation scans descriptions for phrases like "Use when...", "Apply when...", or "Run when...". Without that signal, the skill only fires when the user types `/skill-name` explicitly.

### The gate

Every skill description (or `when_to_use:` field) MUST contain trigger text. Combined length ≤1536 chars (Claude Code 2.1.105+).

```yaml
# Good — explicit trigger
description: "Deploy to GCP Cloud Run. Use when deploying, running smoke tests, or managing revisions."

# Bad — no trigger, only describes what
description: "Helper for Cloud Run deploys. Handles staging and production and traffic routing."

# Acceptable — separate when_to_use field
description: "Cloud Run deploy helper."
when_to_use: "Use when deploying to GCP, running post-deploy smoke tests, or rotating traffic."
```

The `/context-audit` skill's Check 10 flags skills without trigger text. Run it as part of the monthly cadence.

### Description length

- **Target**: 80-150 chars
- **Maximum**: 1536 chars (combined description + when_to_use, CC 2.1.105+)
- **Format**: action verb + what + "Use when X, Y, Z."

Longer descriptions eat the budget without adding signal. The model needs to know **when** to pick the skill, not every detail of how it works.

---

## Workflow example

Concrete walkthrough on a real scenario.

**Trigger**: `/context-audit` reports a skill hasn't fired in 120 days.

1. **Check the jsonl**:
   ```bash
   grep '"my-skill"' ~/.claude/metrics/skill-activations.jsonl | tail -3
   ```
   Last fire was 124 days ago. Before that, three invocations in the same week — looks like a one-off experiment.

2. **Read the skill**:
   ```bash
   cat ~/.claude/skills/my-skill/SKILL.md
   ```
   It's 220 lines, references a workflow I no longer use. Content is specific to a project I archived last quarter.

3. **Classify**: Not reference-only. Not unique (the current project uses a different pattern). → **DELETE**.

4. **Check for dangling references**:
   ```bash
   grep -rn "my-skill" ~/.claude/rules/ ~/.claude/skills/ 2>/dev/null
   ```
   One rule references it. Update the rule to remove the pointer.

5. **Delete**:
   ```bash
   rm -rf ~/.claude/skills/my-skill/
   ```

6. **Verify**: Re-run `/context-audit`. Skill budget shrinks by 240 chars. Broken-references report stays clean.

Elapsed: ~5 minutes. Budget reclaimed: 240 chars. Cognitive load reclaimed: one fewer skill to remember.

---

## Automation

You don't have to do this by hand every month.

### `/context-audit` Check 10

The monthly audit includes a skill freshness check that reads the activation JSONL and reports:

- Top 10 invocations in the past 30 days
- Skills with no activity in 90+ days (archive candidates)
- Skills with no activity in 180+ days (delete candidates)
- Skills missing trigger text (quality-gate failures)

### Monthly skill-health cron

```bash
# crontab entry
15 5 1 * * ~/.claude/scripts/skill-health-monthly.sh \
    >> ~/.claude/logs/skill-health-cron.log 2>&1
```

The script generates a markdown report at `~/.claude/reports/skill-health-YYYY-MM.md`. First fire is a dry-run output only; second fire acts on the archive list (moves to project-local). Deletion always requires manual review — automation should never hard-delete.

### `/weekly-review` dashboard

For tighter cadence, the `/weekly-review` skill includes a skill-invocation summary in its output — which skills fired this week, which haven't fired in a month, budget utilization trend.

---

## Anti-patterns

Things that look like lifecycle management but aren't.

### Keeping every skill you've ever written

The "just in case" skill. You wrote it during a one-hour experiment. It has never fired since. You keep it because "maybe someday." It costs you 200 chars of budget every turn until you archive it.

**Rule**: if you can't state the trigger in a single sentence, the skill doesn't earn its budget.

### Writing skills without triggers

A skill that only fires on explicit invocation (`/skill-name`) has uses — a dangerous operation you want gated, a user-only workflow. But if auto-invocation is the goal and the description has no trigger clause, the skill is silently dead.

**Rule**: every auto-invocable skill has explicit "Use when..." trigger text. Check with `/context-audit` Check 10.

### Archiving without noting WHY

Moving a skill to `.archive/` is tempting but lossy. In six months you've forgotten why you archived it, and either resurrect a duplicate or spend 20 minutes re-reading to decide if it's worth restoring.

**Rule**: if you're archiving (rather than deleting), leave a one-line breadcrumb — in the skill's frontmatter, or in a project note. "Archived 2026-05 — superseded by /new-pattern." Your future self will thank you.

### Deleting without checking references

Hard-deleting a skill that's referenced by a rule, memory note, or another skill creates a dangling pointer. The missing-refs scanner (Chapter 06) catches these, but it's cheaper to grep first.

**Rule**: before `rm -rf`, run `grep -rn "skill-name" ~/.claude/rules/ ~/.claude/skills/ ~/basic-memory/`.

---

## Key takeaways

1. **Skill budget is finite.** Every stale skill pushes an active one out of the registry. Archive or delete on cadence.
2. **You can't decide without data.** Install the `PostToolUse(Skill)` activation logger — 15 lines of bash, and every subsequent decision is evidence-based.
3. **SLAs, not deadlines.** 90 days = archive candidate, 180 days = delete candidate. Review monthly; act deliberately.
4. **Archive means scope down.** Move from global to project-local before deleting. It often reclaims the value without losing the content.
5. **Promotion is earned, not granted.** A project skill graduates to global only after proving it fires in 2+ projects for 30+ days.
6. **Trigger text is mandatory.** Without "Use when...", Claude Code can't auto-invoke. `/context-audit` Check 10 flags the violations.
7. **Automate the signal, not the action.** Cron reports find candidates; humans decide deletes.

---

**See also**:
- [Chapter 04 — Context Budget](./04-context-budget.html) — the skill description budget this system manages
- [Chapter 06 — Context Governance](./06-context-governance.html) — the rule-side governance; skill governance is the on-demand parallel
- Part V, Chapter 07 — Session end and memory defrag (the memory-lifecycle sibling pattern)
- The `knowledge-lifecycle` rule, `skill-metrics` skill, and `/context-audit` skill
