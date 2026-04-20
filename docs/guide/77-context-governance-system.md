---
layout: default
title: "Context Governance System — A 6-Layer Model for Keeping ~/.claude/ Healthy at Scale"
description: "End-to-end governance for global Claude Code context: enforcement hooks, scanners, optimization skills, baseline git tags, regression detection, statusline monitoring, and a single methodology document. Built and validated through a real -27.5% condensation pass."
parent: Guide
nav_order: 77
---

# Context Governance System

**Purpose**: Stop the slow drift where `~/.claude/rules/`, skills, and CLAUDE.md grow unchecked until performance and Claude's behavior degrade
**Difficulty**: Advanced
**Time**: 2-4 hours initial setup; ~5 minutes per monthly cadence after that

---

## The Spiral

If you've used Claude Code seriously for more than a few weeks, the symptoms are familiar:

- Global rules grew **+80,000 chars in 48 hours** during an intense feature push
- Per-project `.claude/` directories ballooned to **180-430KB** each
- Tactical cleanup ("I'll just delete this one rule") got undone faster than it was done
- New rules accidentally duplicated existing ones because nobody could keep the full set in their head
- A `_token_` got added to a rule, then 2 weeks later the same `_token_` appeared in a new skill — pure overlap
- Skills referenced rules that had been renamed or deleted three sprints ago

Every existing tool addressed part of the problem. `/context-audit` measured size. `/context-optimization` walked you through reductions. `rule-size-gate.sh` enforced per-file caps. But they were **uncoordinated** — no shared baseline, no version control, no regression detection between sessions, no unified methodology.

This chapter describes a 6-layer governance system that integrates them all, plus the few new pieces needed to close the gaps.

---

## The 6-Layer Model

Each layer depends only on layers below it. Add them bottom-up; each is independently useful.

```
Layer 7 — Methodology              METHODOLOGY.md + /context-governance skill
                                   (single source of truth, orchestrator skill)
─────────────────────────────────────────────────────────────────────────────
Layer 6 — Monitoring               statusline indicator (`ov:N↑/↓/=`)
                                   + SessionStart warning hook
─────────────────────────────────────────────────────────────────────────────
Layer 5 — Regression detection     regression-test.py compares vs baseline tag
                                   exit 0/1/2 = green/yellow/red
─────────────────────────────────────────────────────────────────────────────
Layer 4 — Version control          git tag baseline-YYYY-MM-DD
                                   reproducible rollback target
─────────────────────────────────────────────────────────────────────────────
Layer 3 — Optimization             /context-optimization skill (5-phase reduction)
                                   + context-optimizer subagent
─────────────────────────────────────────────────────────────────────────────
Layer 2 — Measurement              /context-audit skill (chars, oversized, overlap)
                                   + rule-overlap-scanner.py (Jaccard 5-shingles)
                                   + missing-refs-scanner.py (broken pointers)
─────────────────────────────────────────────────────────────────────────────
Layer 1 — Enforcement              rule-size-gate.sh hook
                                   blocks Edit/Write at 4K/file + 200K total cap
```

**Read this top-down** when you want to know what to invoke. **Read it bottom-up** when you want to build it.

---

## Layer 1 — Enforcement (PreToolUse Hook)

A simple PreToolUse hook on `Edit` and `Write` that blocks any save crossing two budgets:

| Budget | Cap | Why |
|---|---|---|
| Per-file | 4 KB | Forces split-and-extract before a rule grows beyond a single screen |
| Global total | 200 KB | Hard ceiling for `~/.claude/rules/` (rule files only, no skills) |

The hook reads stdin JSON (per [Chapter 13](13-claude-code-hooks.md)), measures the proposed write, and exits 2 with a stderr message if either cap would be exceeded.

```bash
#!/bin/bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')

# Only enforce on rules dir
case "$FILE_PATH" in
  "$HOME/.claude/rules/"*) ;;
  *) exit 0 ;;
esac

NEW_SIZE=${#CONTENT}
[ "$NEW_SIZE" -gt 4000 ] && {
  echo "Rule size gate — blocked: $FILE_PATH would be $NEW_SIZE chars (max 4000)" >&2
  exit 2
}
# ... global total check follows ...
```

**Override** for genuine emergencies via env var (`CLAUDE_RULE_SIZE_OVERRIDE=1`), documented in your global CLAUDE.md so you remember it exists.

The hook scopes to `Edit` and `Write` PreToolUse events only. Bash-based writes (`cp`, `python3 -c "open(...).write(...)"`, `sed -i`) bypass it. This is intentional for emergency condensations that need to cross the cap mid-flight before settling under it.

---

## Layer 2 — Measurement (Skills + Scanners)

Three measurement instruments. None of them modify state; they all produce reports in `~/.claude/reports/`.

### `/context-audit` skill

Read-only health check. Reports:

- Always-on chars (CLAUDE.md + rules + MEMORY + skill descriptions)
- Per-file size warnings (>25K = warning, >40K = critical)
- md5 duplicates across rules and skills
- Rule/skill overlap by filename
- Project-specific terms in global rules (e.g., `LimorAI`, `OGAS` references that should relocate)
- CLAUDE.md length over 200 lines
- Latest overlap scanner result (Jaccard pairs ≥0.6)
- Latest missing-refs scanner result (broken pointers)

Run before any cleanup pass and on a monthly cadence.

### `rule-overlap-scanner.py`

Scans every `.md` file in global + per-project scopes, tokenizes each into 5-token shingles, computes pairwise Jaccard similarity, reports any pair ≥ 0.60.

Three thresholds (sourced from 2026 IR research on near-duplicate detection):

| Jaccard | Meaning | Action |
|---|---|---|
| ≥ 0.60 | Shared topic | Review manually |
| ≥ 0.80 | Near-duplicate | Merge candidate |
| ≥ 0.90 | Near-exact copy | Delete or hard-deduplicate |

Stdlib only. Deterministic — sorted inputs + stable hashing produce byte-identical reports on repeat runs. Inline `--selftest` validates the Jaccard math against 6 synthetic cases.

### `missing-refs-scanner.py`

Walks every rule, skill, and agent markdown file looking for references to other files (path tokens, backtick paths, markdown links, slash invocations like `/skill-name`) and reports any that don't resolve. External URLs and anchors are ignored.

3 selftests; deterministic; per-scope breakdown in the report.

These two scanners replace ad-hoc grep with a deterministic, repeatable signal. The first run is your baseline; every subsequent run is a delta.

---

## Layer 3 — Optimization (Skills + Subagent)

Once measurement says "you have a problem," optimization is what you actually run.

| Tool | Use For |
|---|---|
| `/context-optimization` slash skill | Guided 5-phase reduction (audit → classify → condense → relocate → verify) |
| `context-optimizer` subagent | Heavy lifting that needs an isolated context window — reads files, proposes condensations, never writes |
| `/context-governance` orchestrator | Routes you to the right tool based on `/context-audit` results |

The optimization skill consumes scanner reports as input. You don't re-scan inside the skill — the report exists, the skill plans against it. This separation matters when scans take 30 seconds and you want to iterate on the plan in 2 seconds.

The **pointer-rule pattern** is the workhorse condensation move. Take a 6 KB rule, extract the invariant (1.5-2 KB) plus a one-line pointer to a paired skill that holds the detail. The rule auto-loads on every turn; the skill loads only when invoked. See [Chapter 28 — Skill Optimization Patterns](28-skill-optimization-patterns.md) for the full pattern.

---

## Layer 4 — Version Control (Git Tags)

Once `~/.claude/` is a git repo (it should be), tag your known-good state:

```bash
cd ~/.claude
git tag -f baseline-2026-04-16
```

This tag is your reproducible reference point. Two properties matter:

1. **Mutability while local**: as long as you haven't pushed, force-re-tagging is fine. Advance the baseline whenever you commit a known-good cleanup. We re-tagged `baseline-2026-04-16` three times in one day during the initial rollout — once after each major batch.

2. **Tree as data**: the regression detector reads file sizes directly from the tag's tree (`git ls-tree -r --long <tag> -- rules/`). No need to maintain a separate baseline manifest — the tag IS the manifest.

Build a `/context-governance-rollback` skill that knows the tag's name and how to use it. Four scenarios cover essentially every rollback need:

- Single file: `git checkout <tag> -- path/to/file.md`
- Last N commits: `git reset --hard HEAD~N`
- Full revert to baseline: `git reset --hard <tag>`
- Local backup file (`.backup-<date>`): `cp` it back

Always end the rollback with: re-run scanner selftests, then a full scan, then a size check against your cap. Confirm GREEN before declaring "rolled back."

---

## Layer 5 — Regression Detection (`regression-test.py`)

A small Python script (~280 LOC, stdlib only) that compares current state vs the baseline tag across four KPIs:

| KPI | Source | Yellow | Red |
|---|---|---|---|
| Total rules size | `find ... \| wc -c` | +5% | +15% |
| Broken references | `missing-refs` report | +10 | +50 |
| Overlap pairs (≥0.6) | `overlap-matrix` report | +1 | +3 |
| Oversized files (>4 KB) | `find -size +4k` | n/a | any > 0 |

Exit codes: `0=green`, `1=yellow`, `2=red`, `3=missing baseline`, `4=report write failed`, `5=selftest failed`.

The script ships with 9 inline selftests (`--selftest` flag). Identical state → green; +3% → green; +7% → yellow; +20% → red; +15 refs → yellow; +60 refs → red; determinism (same input → same hash); per-scope path argument; per-project scope resolution.

Each run writes a markdown report to `~/.claude/reports/regression-YYYY-MM-DD.md` with KPI deltas, threshold legend, and current state hash.

---

## Layer 6 — Monitoring (Statusline + SessionStart Hook)

Two human-visible signals that surface state without you needing to ask.

### Statusline indicator

Extend your statusline (see [Chapter 75 — Statusline Patterns](75-claude-code-statusline-patterns.md)) with a 4-character overlap field:

```
worktree | model | ctx % | cb:state | ov:N[↑↓]
                                       ^^^^^^^
                                       N = overlap pairs ≥0.60
                                       ↑ = grew since last check
                                       ↓ = shrank
                                       (none) = unchanged
```

Cache the previous value in a 3-line state file (`current\nprevious\nmtime`). Invalidate by source-report mtime — when the scanner writes a new report, the statusline picks it up automatically. Latency budget: <100 ms (we measure ~65 ms).

### SessionStart warning hook

A warn-only hook reads the latest regression report at session start and writes one stderr line:

- GREEN → silent (no output)
- YELLOW → `[regression-warn] yellow: size +6.2%, refs +12. Consider /context-optimization.`
- RED → `[regression-warn] RED: oversized files: 3. Consider rollback.`

Always exits 0. Never blocks the session. The hook surfaces the signal the moment you sit down; you decide whether to act.

---

## Layer 7 — Methodology (Single Source of Truth)

The hub is one document at `~/.claude/METHODOLOGY.md`. Not auto-loaded (it lives at root, not in `rules/`), so it doesn't consume context every turn — but it's the single place that explains the whole system.

Four sections, ~5K chars total:

1. **The 6 layers** — what each one does
2. **When to run what** — green/yellow/red decision table
3. **KPI thresholds reference** — the table from Layer 5, sourced authoritatively
4. **Monthly cadence** — what to run, in what order, and what to commit

The hub is paired with a `/context-governance` orchestrator skill that walks Claude through:

```
1. Check state              → /context-audit + cat reports/regression-*.md
2. Decide action            → green = no-op | yellow = /context-optimization | red = optimizer agent or rollback
3. Execute action           → dispatched
4. Verify                   → re-run /context-audit
```

**Hub-and-spoke principle**: the methodology lives in ONE place. Other skills and rules link to it; they don't duplicate it. When the methodology evolves, you update one file. We added cross-reference lines to three spokes — `context-audit` skill, `context-optimization` skill, and `context-budget` rule — each pointing to METHODOLOGY.md.

---

## Cap-Tight Editing Strategies

Once your global rules are at 199,994 / 200,000 chars (real number from a recent rollout), every new edit risks crossing the cap. Three strategies, in priority order:

### Strategy 1: Swap-Not-Add (preferred for cross-references)

Replace an existing line of similar length rather than appending:

```diff
- - **Theory**: `/anthropic-best-practices` (context cost table, skill budget math)
+ - **Methodology**: `~/.claude/METHODOLOGY.md`; theory: `/anthropic-best-practices`
```

Old: 82 chars. New: 84 chars. Net: +2.

### Strategy 2: Skill Destination (preferred for new content)

When you need a NEW rule file, write it as a skill instead. Skills don't count toward the global rules cap — their descriptions cost ~250 chars each in the skill registry, but their bodies load only on invocation.

```bash
# WRONG — would push global rules over cap
~/.claude/rules/technical/new-pattern.md  # 2K chars added

# CORRECT — skill loaded only on invocation
~/.claude/skills/new-pattern/SKILL.md     # 0 chars to always-on context
```

### Strategy 3: Bash Bypass (emergency only)

The size-gate hook scopes to `Edit` and `Write` events. `cp`, `mv`, `python3 -c "open(...).write(...)"`, `sed -i` bypass it. This is sometimes the only way to land a condensation that crosses the cap mid-flight (temporarily +500 chars while moving content to a skill, then -800 chars when the source rule is shrunk).

NEVER use bypass as a permanent workaround. Always verify post-bypass that you're back under the cap.

---

## Production Discoveries

Three patterns we hit during the rollout that are worth borrowing.

### Gitignore Anchor Pattern

If you put `~/.claude/` under git and add a top-level dir to `.gitignore` like this:

```
projects/
session-backups/
plans/
```

…Git interprets each entry as **"any directory named `projects` anywhere in the tree"** — including `rules/projects/`. We had a 2,166-char governance rule (`rules/projects/registry.md`) silently untracked for an unknown duration because of this. The regression scanner caught it: a +1.09 % size delta between a freshly tagged baseline and disk that nobody could explain.

Always anchor top-level directory ignores with a leading slash:

```diff
- projects/
- session-backups/
- plans/
+ /projects/
+ /session-backups/
+ /plans/
```

Verify with `git check-ignore -v <path/to/suspect-file>`.

### Tag Mutability for Local-Only Tags

You can force-re-tag local Git tags freely. We re-tagged `baseline-2026-04-16` three times in one day:

1. After Task #27 condensation lands → tag at commit fc123fc
2. After gitignore anchor fix lands → tag advances to commit 654a7b5
3. After governance Phases 3-5 land → tag advances to commit 57ae283

This works ONLY because we hadn't pushed. The moment a tag is published, treat it as immutable; create a new tag (`baseline-2026-04-23`) instead.

### TDD-First for Governance Scripts

Every script in this system ships with an inline `--selftest` flag that runs deterministic synthetic test cases. Total counts after rollout:

- `rule-overlap-scanner.py` — 6 cases (identity, disjoint, 50% overlap, unicode, determinism, file-count sanity)
- `missing-refs-scanner.py` — 7 cases (valid ref, broken ref, external URL ignored, etc.)
- `regression-test.py` — 9 cases (status thresholds, determinism, scope-path arg)
- `statusline-overlap.sh` — 10 cases (parse zero/N pairs, missing report, cache fresh/stale, trend up/down/equal)

Total: 32 selftests run in under 3 seconds. They run automatically before every governance commit. Add tests when you add features; don't ship governance code that can't validate itself.

---

## Case Study: Single-Session Condensation

Real numbers from one focused session that ran the optimization layer at scale:

| Metric | Before | After | Delta |
|---|---|---|---|
| Global rules total | 275,698 chars | 199,993 chars | **−27.5%** |
| Files exceeding 4K cap | 21 | 0 | **−21** |
| Broken references | unknown | 203 | (baselined) |
| New skills extracted | 0 | 9 | (paired with condensed rules) |
| Existing skill extended | 0 | 1 | (`gemini-patterns`) |

The pattern was the same for each oversized file:

1. Read the rule
2. Extract the invariant (1-2 paragraphs of MUST/MUST-NOT) into the rule
3. Move the detail (code, examples, gotcha tables) into a paired skill
4. Add a one-line pointer at the end of the rule: `**Full code + examples**: invoke skill \`<skill-name>\``

Time per file: 5-15 minutes. Twenty-one files in one session, with batched commits at natural break points. The size-gate hook caught two attempts to push back over cap mid-flight; both were resolved by extracting an extra 200 chars to the paired skill before retrying.

---

## Skill Lifecycle Extension (D0-D4)

The 6-layer model above governs **rules** (always-on context). The same pattern extends to **skills** (on-demand context), with one critical asymmetry: rules load every turn (measurable by size), skills load when invoked (measurable only by *activation*). That asymmetry means skill governance needs a signal the rule governance doesn't — invocation telemetry.

### D0 — Invocation Logging (PostToolUse Hook)

A `PostToolUse` hook matching the `Skill` tool appends one JSONL row per invocation to `~/.claude/metrics/skill-activations.jsonl`:

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

### D1 — Skill Lifecycle SLA (Rule Extension)

Extend your knowledge-lifecycle rule with concrete thresholds:

| Age (no invocation) | Action |
|---|---|
| 90 days | Archive candidate — scope to single project OR mark deprecated |
| 180 days | Delete candidate — hard-delete unless reference-only purpose |

**Promotion criteria** (project skill → global):
- Used in 2+ projects for 30+ days (D0 data confirms)
- No project-specific file paths in body
- Description contains explicit trigger clause ("Use when…")

**Description-quality gate**: `description` OR `when_to_use:` field MUST contain trigger text (combined cap: 1536 chars). Without trigger text, Claude Code cannot auto-invoke the skill.

### D2 — Integration into Existing Measurement Skills

Extend `/context-audit` with a Check 10 (skill freshness) that reads the D0 jsonl:

```python
# Inline Python block inside the audit skill
from pathlib import Path
import json, time
from collections import Counter

JSONL = Path.home() / '.claude' / 'metrics' / 'skill-activations.jsonl'
if not JSONL.exists():
    print('NOT-ACTIVATED: D0 hook not installed yet')
else:
    now = time.time()
    recent = Counter()
    with JSONL.open() as f:
        for line in f:
            row = json.loads(line)
            if now - row['epoch'] < 30 * 86400:
                recent[row['matched_skills']] += 1
    # Report top 10 + any skill missing from past 90d vs disk
```

Extend `memory-defrag` with an **orphan skill reference** scan — Memory notes referencing deleted skill names. Filter to notes with ≥2 refs to cut noise.

### D3 — Monthly Skill-Health Cron

```bash
# crontab entry
15 5 1 * * ~/.claude/scripts/skill-health-monthly.sh \
    >> ~/.claude/logs/skill-health-cron.log 2>&1
```

The script generates a markdown report: top 10 invocations (30d), archive candidates (>90d no activity), delete candidates (>180d). First fire is a dry-run output only; second fire acts on the archive list.

### D4 — ai-dna Promotion Workflow

If you maintain cross-project AI knowledge (see [Chapter 65](65-cross-project-ai-knowledge-sharing.md)), add a **skill promotion section** distinct from pattern promotion:

- **Pattern promotion**: project rule → global rule (always-on)
- **Skill promotion**: project skill → global skill (on-demand)

The reverse flow (demote global skill back to a single project): rename `<skill>` → `<skill>-<project>` in that project's `.claude/skills/`; delete from global; update Memory notes referencing the old global name.

### D0-D4 Extension Summary

| Layer | Extends | Adds |
|---|---|---|
| D0 | Layer 1 (Enforcement) | PostToolUse(Skill) hook → activation JSONL |
| D1 | Layer 4+7 (Git tags + Methodology) | Skill lifecycle SLA thresholds |
| D2 | Layer 2 (Measurement) | Check 10 + orphan scan |
| D3 | Layer 6 (Monitoring) | Monthly cron report |
| D4 | Layer 7 (Methodology) | Promotion workflow in ai-dna skill |

D0 blocks D1-D4 — no lifecycle SLA can fire without activation data. Deploy in strict order.

### Real Numbers from a Governance Rollout

One session closed the skill governance loop end-to-end:

| Metric | Before | After |
|---|---|---|
| Skill invocation logging | None | D0 hook live, jsonl writing per invocation |
| Skill lifecycle SLA | None | Documented thresholds (90d/180d), promotion gates |
| Monthly skill-health report | None | Cron-driven, markdown output |
| Project skills (one repo) | 187 | 184 (3 genuinely-obsolete deleted via hand-verify) |

The headline: the **cleanup loop replaced bulk delete**. An earlier plan targeted 192 → 70 via agent-classified batches. Hand-verify of the classifier's output showed ~20% disagreement on random samples — meaning ~40 skills would have been mis-deleted. The pivot: ship the governance loop (D0-D4), let invocation telemetry surface dead skills over 90d/180d, delete on cadence. Three surgical deletes today; the rest is now self-healing.

---

## When to Adopt This System

Not every project needs the full stack. A rough sizing guide:

| Your global rules total | Recommended layers |
|---|---|
| < 50 KB | Layer 1 (size gate) only — anything more is overkill |
| 50-150 KB | Layers 1-3 (add measurement + optimization skills) |
| 150-200 KB | Add Layer 4 (baseline tag) + 5 (regression script) |
| 200 KB+ | Full stack — you're already in the danger zone |

Per-project `.claude/` directories follow the same sizing. If a single project's rules are 200 KB+, that project alone justifies the system.

The **methodology layer** (Layer 7) is worth adding regardless of size — a single 5K-character document explaining how your context is structured pays for itself the first time a new collaborator (or a future you, six months later) needs to understand it.

---

## Future: Per-Project Rollout

The system as described above governs `~/.claude/` (your global Claude Code context). The same 6 layers apply unchanged to per-project `.claude/` directories — same scanners, same baseline tag pattern, same regression script with `--scope-path` and `--baseline-tag` flags.

The patterns are validated end-to-end on global. Per-project rollout adds:

- One `git tag baseline-<project>-YYYY-MM-DD` per project repo
- One SessionStart hook entry per project's `.claude/settings.json`
- One per-project size-gate matcher in the global hook config

A future revision of this chapter will add concrete numbers from a multi-project rollout (3 projects ranging 100-240 KB). The global numbers above are real; the per-project numbers will be added once the rollout completes.

---

## Cross-References

- [Chapter 26 — Claude Code Rules System](26-claude-code-rules-system.md): how `~/.claude/rules/` works
- [Chapter 28 — Skill Optimization Patterns](28-skill-optimization-patterns.md): the pointer-rule + skill-destination pattern
- [Chapter 35 — Skill Optimization Maintenance](35-skill-optimization-maintenance.md): cadence for keeping skills tight
- [Chapter 38 — Context Costs and Skill Budget](38-context-costs-and-skill-budget.md): the budget arithmetic this system enforces
- [Chapter 39 — Context Separation](39-context-separation.md): per-project vs global, the prerequisite to per-project governance
- [Chapter 75 — Statusline Patterns](75-claude-code-statusline-patterns.md): how the overlap indicator hooks into your existing statusline
- [Chapter 76 — Inter-Agent Coordination](76-inter-agent-coordination.md): another file-based, governance-friendly system pattern

---

**Previous**: [76: Inter-Agent Coordination](76-inter-agent-coordination.md)
**Next**: TBD

---

**Last updated**: 2026-04-20 (+Skill Lifecycle Extension D0-D4)
