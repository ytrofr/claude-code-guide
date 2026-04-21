---
layout: default
title: "Context Governance — 7-Layer System"
parent: "Part IV — Context Engineering"
nav_order: 6
redirect_from:
  - /docs/guide/77-context-governance-system.html
  - /docs/guide/77-context-governance-system/
---

# Context Governance — 7-Layer System

**Current as of**: Claude Code 2.1.111+.
**Related**: [Chapter 04 — Context Budget](./04-context-budget.html), [Chapter 07 — Skill Lifecycle](./07-skill-lifecycle.html)

---

## The spiral

If you've used Claude Code seriously for more than a few weeks, the symptoms are familiar:

- Global rules grew **+80,000 chars in 48 hours** during an intense feature push
- Per-project `.claude/` directories ballooned to **180-430 KB** each
- Tactical cleanup ("I'll just delete this one rule") got undone faster than it was done
- New rules accidentally duplicated existing ones because nobody could keep the full set in their head
- A token got added to a rule, then two weeks later the same token appeared in a new skill — pure overlap
- Skills referenced rules that had been renamed or deleted three sprints ago

Every existing tool addressed part of the problem. `/context-audit` measured size. `/context-optimization` walked through reductions. A rule-size-gate hook enforced per-file caps. But they were **uncoordinated** — no shared baseline, no version control, no regression detection between sessions, no unified methodology.

This chapter describes a 7-layer governance system that integrates them all, plus the few new pieces needed to close the gaps.

---

## The 7-layer model

Each layer depends only on layers below it. Add them bottom-up; each is independently useful.

```
Layer 7 — Methodology              METHODOLOGY.md + /context-governance skill
                                   (single source of truth, orchestrator skill)
─────────────────────────────────────────────────────────────────────────────
Layer 6 — Monitoring               statusline indicator (`ov:N[↑↓]`)
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

## Layer 1 — Enforcement (PreToolUse hook)

A `PreToolUse` hook on `Edit` and `Write` that blocks any save crossing two budgets:

| Budget | Cap | Why |
|--------|-----|-----|
| Per-file | 4 KB | Forces split-and-extract before a rule grows beyond a single screen |
| Global total | 200 KB | Hard ceiling for `~/.claude/rules/` (rule files only, no skills) |

The hook reads stdin JSON, measures the proposed write, and exits 2 with a stderr message if either cap would be exceeded.

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

**Override** for genuine emergencies via env var (`CLAUDE_RULE_SIZE_OVERRIDE=1`), documented in your global `CLAUDE.md` so you remember it exists.

The hook scopes to `Edit` and `Write` events only. Bash-based writes (`cp`, `python3 -c "open(...).write(...)"`, `sed -i`) bypass it. This is intentional for emergency condensations that need to cross the cap mid-flight before settling under it.

See [Chapter 04 — Context Budget](./04-context-budget.html) for the threshold rationale and the full cost hierarchy this hook enforces.

---

## Layer 2 — Measurement (skills + scanners)

Three measurement instruments. None of them modify state; they all produce reports in `~/.claude/reports/`.

### `/context-audit` skill

Read-only health check. Reports:

- Always-on chars (`CLAUDE.md` + rules + MEMORY + skill descriptions)
- Per-file size warnings (>25 K = warning, >40 K = critical)
- md5 duplicates across rules and skills
- Rule/skill overlap by filename
- Project-specific terms in global rules (references that should relocate)
- `CLAUDE.md` length over 200 lines
- Latest overlap scanner result (Jaccard pairs ≥0.60)
- Latest missing-refs scanner result (broken pointers)

Run before any cleanup pass and on a monthly cadence.

### `rule-overlap-scanner.py`

Scans every `.md` file in global and per-project scopes, tokenizes each into 5-token shingles, computes pairwise Jaccard similarity, and reports any pair ≥ 0.60.

Three thresholds (sourced from 2026 IR research on near-duplicate detection):

| Jaccard | Meaning | Action |
|---------|---------|--------|
| ≥ 0.60 | Shared topic | Review manually |
| ≥ 0.80 | Near-duplicate | Merge candidate |
| ≥ 0.90 | Near-exact copy | Delete or hard-deduplicate |

Stdlib only. Deterministic — sorted inputs plus stable hashing produce byte-identical reports on repeat runs. Inline `--selftest` validates the Jaccard math against 6 synthetic cases.

### `missing-refs-scanner.py`

Walks every rule, skill, and agent markdown file looking for references to other files (path tokens, backtick paths, markdown links, slash invocations like `/skill-name`) and reports any that don't resolve. External URLs and anchors are ignored.

Three selftests; deterministic; per-scope breakdown in the report.

These two scanners replace ad-hoc grep with a deterministic, repeatable signal. The first run is your baseline; every subsequent run is a delta.

---

## Layer 3 — Optimization (skills + subagent)

Once measurement says "you have a problem," optimization is what you actually run.

| Tool | Use for |
|------|---------|
| `/context-optimization` slash skill | Guided 5-phase reduction (audit → classify → condense → relocate → verify) |
| `context-optimizer` subagent | Heavy lifting that needs an isolated context window — reads files, proposes condensations, never writes |
| `/context-governance` orchestrator | Routes you to the right tool based on `/context-audit` results |

The optimization skill consumes scanner reports as input. You don't re-scan inside the skill — the report exists, the skill plans against it. This separation matters when scans take 30 seconds and you want to iterate on the plan in 2 seconds.

The **pointer-rule pattern** is the workhorse condensation move. Take a 6 KB rule, extract the invariant (1.5-2 KB) plus a one-line pointer to a paired skill that holds the detail. The rule auto-loads on every turn; the skill loads only when invoked.

---

## Layer 4 — Version control (git tags)

Once `~/.claude/` is a git repo (it should be), tag your known-good state:

```bash
cd ~/.claude
git tag -f baseline-2026-04-16
```

This tag is your reproducible reference point. Two properties matter:

1. **Mutability while local**: as long as you haven't pushed, force-re-tagging is fine. Advance the baseline whenever you commit a known-good cleanup. The original rollout re-tagged `baseline-2026-04-16` three times in one day — once after each major batch.

2. **Tree as data**: the regression detector reads file sizes directly from the tag's tree (`git ls-tree -r --long <tag> -- rules/`). No need to maintain a separate baseline manifest — the tag IS the manifest.

Build a `/context-governance-rollback` skill that knows the tag's name and the four rollback scenarios:

- **Single file**: `git checkout <tag> -- path/to/file.md`
- **Last N commits**: `git reset --hard HEAD~N`
- **Full revert to baseline**: `git reset --hard <tag>`
- **Local backup file** (`.backup-<date>`): `cp` it back

Always end the rollback with: re-run scanner selftests, then a full scan, then a size check against your cap. Confirm GREEN before declaring "rolled back."

---

## Layer 5 — Regression detection (`regression-test.py`)

A small Python script (~280 LOC, stdlib only) that compares current state vs the baseline tag across four KPIs:

| KPI | Source | Yellow | Red |
|-----|--------|--------|-----|
| Total rules size | `find ... \| wc -c` | +5% | +15% |
| Broken references | `missing-refs` report | +10 | +50 |
| Overlap pairs (≥0.6) | `overlap-matrix` report | +1 | +3 |
| Oversized files (>4 KB) | `find -size +4k` | n/a | any > 0 |

Exit codes: `0=green`, `1=yellow`, `2=red`, `3=missing baseline`, `4=report write failed`, `5=selftest failed`.

The script ships with 9 inline selftests (`--selftest` flag): identical state → green; +3% → green; +7% → yellow; +20% → red; +15 refs → yellow; +60 refs → red; determinism (same input → same hash); per-scope path argument; per-project scope resolution.

Each run writes a markdown report to `~/.claude/reports/regression-YYYY-MM-DD.md` with KPI deltas, threshold legend, and current state hash.

---

## Layer 6 — Monitoring (statusline + SessionStart hook)

Two human-visible signals that surface state without you needing to ask.

### Statusline indicator

Extend your statusline with a 4-character overlap field:

```
worktree | model | ctx % | cb:state | ov:N[↑↓]
                                       ^^^^^^^
                                       N = overlap pairs ≥0.60
                                       ↑ = grew since last check
                                       ↓ = shrank
                                       (none) = unchanged
```

Cache the previous value in a 3-line state file (`current\nprevious\nmtime`). Invalidate by source-report mtime — when the scanner writes a new report, the statusline picks it up automatically. Latency budget under 100 ms (measured around 65 ms in the reference implementation).

### SessionStart warning hook

A warn-only hook reads the latest regression report at session start and writes one stderr line:

- GREEN → silent (no output)
- YELLOW → `[regression-warn] yellow: size +6.2%, refs +12. Consider /context-optimization.`
- RED → `[regression-warn] RED: oversized files: 3. Consider rollback.`

Always exits 0. Never blocks the session. The hook surfaces the signal the moment you sit down; you decide whether to act.

---

## Layer 7 — Methodology (single source of truth)

The hub is one document at `~/.claude/METHODOLOGY.md`. Not auto-loaded (it lives at root, not in `rules/`), so it doesn't consume context every turn — but it's the single place that explains the whole system.

Four sections, ~5 K chars total:

1. **The 7 layers** — what each one does
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

**Hub-and-spoke principle**: the methodology lives in ONE place. Other skills and rules link to it; they don't duplicate it. When the methodology evolves, you update one file. Cross-reference lines belong on three spokes — the `context-audit` skill, the `context-optimization` skill, and the `context-budget` rule — each pointing to `METHODOLOGY.md`.

---

## Cap-tight editing strategies

Once your global rules are at 199,994 / 200,000 chars (real number from a recent rollout), every new edit risks crossing the cap. Three strategies, in priority order:

### Strategy 1: Swap-not-add (preferred for cross-references)

Replace an existing line of similar length rather than appending:

```diff
- - **Theory**: `/anthropic-best-practices` (context cost table, skill budget math)
+ - **Methodology**: `METHODOLOGY.md`; theory: `/anthropic-best-practices`
```

Old: 82 chars. New: 84 chars. Net: +2.

### Strategy 2: Skill destination (preferred for new content)

When you need a NEW rule file, write it as a skill instead. Skills don't count toward the global rules cap — their descriptions cost ~250 chars each in the skill registry, but their bodies load only on invocation.

```bash
# WRONG — would push global rules over cap
~/.claude/rules/technical/new-pattern.md  # 2K chars added

# CORRECT — skill loaded only on invocation
~/.claude/skills/new-pattern/SKILL.md     # 0 chars to always-on context
```

### Strategy 3: Bash bypass (emergency only)

The size-gate hook scopes to `Edit` and `Write` events. `cp`, `mv`, `python3 -c "open(...).write(...)"`, `sed -i` bypass it. This is sometimes the only way to land a condensation that crosses the cap mid-flight (temporarily +500 chars while moving content to a skill, then -800 chars when the source rule is shrunk).

NEVER use bypass as a permanent workaround. Always verify post-bypass that you're back under the cap.

See the `cap-tight-rule-editing` skill for the full decision tree and patterns.

---

## Production discoveries

Three patterns worth borrowing from a real rollout.

### Gitignore anchor pattern

If you put `~/.claude/` under git and add a top-level dir to `.gitignore` like this:

```
projects/
session-backups/
plans/
```

…Git interprets each entry as **"any directory named `projects` anywhere in the tree"** — including `rules/projects/`. During one rollout, a 2,166-char governance rule (`rules/projects/registry.md`) was silently untracked for an unknown duration because of this. The regression scanner caught it: a +1.09 % size delta between a freshly tagged baseline and disk that nobody could explain.

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

### Tag mutability for local-only tags

You can force-re-tag local Git tags freely. One rollout re-tagged `baseline-2026-04-16` three times in one day:

1. After the condensation task lands → tag at commit fc123fc
2. After gitignore anchor fix lands → tag advances to commit 654a7b5
3. After governance Phases 3-5 land → tag advances to commit 57ae283

This works ONLY because no one had pushed. The moment a tag is published, treat it as immutable; create a new tag (`baseline-2026-04-23`) instead.

### TDD-first for governance scripts

Every script in this system ships with an inline `--selftest` flag that runs deterministic synthetic test cases. Total counts after rollout:

- `rule-overlap-scanner.py` — 6 cases (identity, disjoint, 50% overlap, unicode, determinism, file-count sanity)
- `missing-refs-scanner.py` — 7 cases (valid ref, broken ref, external URL ignored, etc.)
- `regression-test.py` — 9 cases (status thresholds, determinism, scope-path arg)
- `statusline-overlap.sh` — 10 cases (parse zero/N pairs, missing report, cache fresh/stale, trend up/down/equal)

Total: 32 selftests run in under 3 seconds. They run automatically before every governance commit. Add tests when you add features; don't ship governance code that can't validate itself.

---

## Case study: single-session condensation

Real numbers from one focused session that ran the optimization layer at scale:

| Metric | Before | After | Delta |
|--------|--------|-------|-------|
| Global rules total | 275,698 chars | 199,993 chars | **−27.5%** |
| Files exceeding 4K cap | 21 | 0 | **−21** |
| Broken references | unknown | 203 | (baselined) |
| New skills extracted | 0 | 9 | (paired with condensed rules) |
| Existing skill extended | 0 | 1 | |

The pattern was the same for each oversized file:

1. Read the rule
2. Extract the invariant (1-2 paragraphs of MUST/MUST-NOT) into the rule
3. Move the detail (code, examples, gotcha tables) into a paired skill
4. Add a one-line pointer at the end of the rule: `**Full code + examples**: invoke skill \`<skill-name>\``

Time per file: 5-15 minutes. Twenty-one files in one session, with batched commits at natural break points. The size-gate hook caught two attempts to push back over cap mid-flight; both were resolved by extracting an extra 200 chars to the paired skill before retrying.

---

## When to adopt this system

Not every project needs the full stack. A rough sizing guide:

| Your global rules total | Recommended layers |
|-------------------------|--------------------|
| < 50 KB | Layer 1 (size gate) only — anything more is overkill |
| 50-150 KB | Layers 1-3 (add measurement + optimization skills) |
| 150-200 KB | Add Layer 4 (baseline tag) + 5 (regression script) |
| 200 KB+ | Full stack — you're already in the danger zone |

Per-project `.claude/` directories follow the same sizing. If a single project's rules are 200 KB+, that project alone justifies the system.

The **methodology layer** (Layer 7) is worth adding regardless of size — a single 5 K-character document explaining how your context is structured pays for itself the first time a new collaborator (or a future you, six months later) needs to understand it.

---

## Per-project rollout

The system as described above governs `~/.claude/` (your global Claude Code context). The same 7 layers apply unchanged to per-project `.claude/` directories — same scanners, same baseline tag pattern, same regression script with `--scope-path` and `--baseline-tag` flags.

Per-project rollout adds:

- One `git tag baseline-<project>-YYYY-MM-DD` per project repo
- One SessionStart hook entry per project's `.claude/settings.json`
- One per-project size-gate matcher in the global hook config

---

## Skill lifecycle: a parallel asymmetry

The 7-layer model governs **rules** (always-on context). The same pattern extends to **skills** (on-demand context), with one critical asymmetry: rules load every turn (measurable by size), skills load when invoked (measurable only by *activation*).

That asymmetry means skill governance needs a signal the rule governance doesn't — invocation telemetry via a `PostToolUse` hook matching the `Skill` tool, writing to `~/.claude/metrics/skill-activations.jsonl`.

Skill archive/delete/promote discipline has its own chapter — see [Chapter 07 — Skill Lifecycle](./07-skill-lifecycle.html).

---

## Key takeaways

1. **Governance is layered.** Build bottom-up. Each layer is independently useful, and each depends only on layers below it.
2. **Enforcement comes first.** A `PreToolUse` hook that blocks oversized writes prevents most drift before it starts.
3. **Scanners produce deterministic signals.** Grep is not a replacement. Overlap and missing-refs reports are the baseline every other layer compares against.
4. **The baseline tag IS the manifest.** Git tags are free, immutable once pushed, and readable as data via `git ls-tree`.
5. **Regression detection closes the loop.** Green/yellow/red against baseline is the signal that tells you when to act.
6. **Monitoring surfaces state without asking.** Statusline indicator and SessionStart hook keep the status visible without you needing to run `/context-audit` every session.
7. **Methodology lives in one place.** `METHODOLOGY.md` + `/context-governance` orchestrator. Everything else is a spoke that references it.

---

**See also**:
- [Chapter 04 — Context Budget and Cost Hierarchy](./04-context-budget.html) — the arithmetic this system enforces
- [Chapter 07 — Skill Lifecycle](./07-skill-lifecycle.html) — the on-demand side of the same discipline
- The `context-budget`, `overlap-scanner-usage`, and `missing-refs-scanner-usage` rules
- The `/context-audit`, `/context-optimization`, `/context-governance`, and `/context-governance-rollback` skills
