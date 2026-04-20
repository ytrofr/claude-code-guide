---
layout: default
title: "Cross-Project Knowledge Sharing"
parent: "Part V — Advanced"
nav_order: 6
redirect_from:
  - /docs/guide/65-cross-project-ai-knowledge-sharing.html
  - /docs/guide/65-cross-project-ai-knowledge-sharing/
---

# Cross-Project Knowledge Sharing

## The problem

If you maintain multiple AI projects, each accumulates hard-won production knowledge independently. `<PROJECT-A>` discovers a circuit breaker pattern after a 3-hour outage. `<PROJECT-B>` hits the same issue two months later and loses another 3 hours. `<PROJECT-C>` never learns from either.

Claude Code's rules, skills, hooks, and crons can solve this — but only if you design a **shared knowledge layer** that grows automatically across sessions and projects.

This chapter shows how to build a self-sustaining shared-layer system using every Claude Code ability. The architecture is generic — adapt the content to your own AI stack.

For a deeper treatment of the AI DNA pattern (the meta-methodology behind this), see the [AI DNA shared layer chapter](01-ai-dna-shared-layer.html).

---

## Architecture overview

The system has 6 layers, each using a different Claude Code capability:

```
Layer 1: Shared Rules     (~/.claude/rules/ai/)        Always loaded, every session
Layer 2: Shared Skills    (~/.claude/skills/shared-*/) On-demand, triggered by keywords
Layer 3: Persistent Memory (Basic Memory MCP or files) Searchable knowledge graph
Layer 4: Project Context  (CLAUDE.md + MEMORY.md)      Per-project pointers
Layer 5: Automation       (hooks + crons)              Zero-manual-effort capture
Layer 6: Lifecycle        (freshness SLAs + review)    Prevents knowledge rot
```

### Why 6 layers?

Each layer serves a different purpose with different token costs:

| Layer | Token Cost | When Loaded | Best For |
|-------|-----------|-------------|----------|
| Rules | ~500 tokens/rule | Every message | Universal patterns (always need) |
| Skills | ~40 tokens (description only) | When triggered | Detailed guides (need sometimes) |
| Memory | 0 (on-demand search) | When searched | Historical decisions, gotchas |
| Context | ~200 tokens | Every message | Project-specific pointers |
| Hooks | 0 (external process) | On events | Automatic capture |
| Lifecycle | 0 (cron job) | Weekly/monthly | Staleness prevention |

---

## Layer 1: Shared rules

**Location**: `$HOME/.claude/rules/ai/`
**Cost**: Always loaded (~500 tokens per rule)
**Use for**: Universal patterns that apply to ALL your AI projects.

### Structure

Create a dedicated `ai/` subdirectory in your global rules:

```
$HOME/.claude/rules/ai/
├── core-patterns.md          # Framework-specific patterns
├── model-optimization.md     # Model selection, caching, cost reduction
├── resilience.md             # Circuit breaker, fallback, retry
├── orchestration.md          # Multi-agent coordination patterns
├── observability.md          # Logging, baselines, cost tracking
└── methodology.md            # The DNA system's own rules
```

### Rule template

Each rule should be concise (60-120 lines) with clear scope:

```markdown
# [Domain] Patterns — Universal

**Scope**: ALL projects using [framework/tool]
**Authority**: MANDATORY for [what it enforces]
**Source**: [Which projects contributed these patterns]

---

## Pattern Name

[2-3 sentence description]

## Code Example

[Minimal working pattern]

## Common Gotchas

| Gotcha | Fix |
|--------|-----|
| [trap] | [solution] |

---

**Last Updated**: YYYY-MM-DD
```

### Key principles

- **Keep rules short** — they load every message. 60-120 lines max.
- **Universal only** — if a pattern applies to only one project, use project-level `.claude/rules/`.
- **Patterns, not implementation** — describe WHAT to do, not project-specific HOW.
- **Source attribution** — note which project(s) discovered each pattern.

### Budget management

Global rules consume ~500 tokens each. Track your budget:

```bash
# Count total global rules
find $HOME/.claude/rules -name "*.md" | wc -l

# Rough token estimate (5 tokens/line)
find $HOME/.claude/rules -name "*.md" -exec wc -l {} + | tail -1
```

Stay under 85% of the skill budget (~16K chars for descriptions). Use `paths:` frontmatter for rules that only apply to specific file types.

---

## Layer 2: Shared skills

**Location**: `$HOME/.claude/skills/shared-*/`
**Cost**: ~40 tokens per skill (description only, full content on-demand)
**Use for**: Detailed guides that are too long for rules.

### When to use a skill vs a rule

| Content | Use |
|---------|-----|
| Universal pattern, always needed | **Rule** (always loaded) |
| Detailed guide, needed sometimes | **Skill** (on-demand) |
| Step-by-step workflow | **Skill** (on-demand) |
| One-liner enforcement | **Rule** (always loaded) |

### Skill template

```markdown
---
name: shared-[domain]
description: "[Action verb] [what it does]. Use when [trigger scenarios]."
---

# [Domain] Guide

**Source**: [Which projects contributed]

## When to Use

1. When building [scenario 1]
2. When debugging [scenario 2]
3. When deciding between [option A] vs [option B]

## Decision Tree

| Need | Approach | Why |
|------|----------|-----|
| [scenario] | [solution] | [rationale] |

## Common Gotchas

[Project-validated traps and fixes]

## Key Files Reference

[Point to relevant code locations per project]
```

### Naming convention

- Directory: `shared-[domain]/SKILL.md` (e.g., `shared-rag-architecture/`)
- No `-skill` suffix on directory names.
- `name:` field must match directory name exactly.
- Description must start with an action verb and include "Use when...".

---

## Layer 3: Persistent memory

**Location**: Dedicated folder in your knowledge system (e.g., Basic Memory MCP, or plain files)
**Cost**: Zero tokens until searched
**Use for**: Architecture decisions, production gotchas, model selection history.

### What to store

| Note Type | Content | Example |
|-----------|---------|---------|
| Architecture Decisions | ADRs with status lifecycle | "Why we chose framework X over Y" |
| Cross-Project Patterns | Patterns validated in 2+ projects | "Budget enforcement works in <PROJECT-A> and <PROJECT-B>" |
| Production Gotchas | Bugs, traps, and fixes from all projects | "Model X returns empty on Hebrew input" |
| Model Selection History | What models you tried, results, costs | "Flash+pipeline beats Pro standalone" |
| Knowledge Growth Log | Track new learnings over time | Weekly entries of discoveries |

### ADR status lifecycle

Every architecture decision should have a status:

```
PROPOSED → ACCEPTED → ACTIVE → DEPRECATED → SUPERSEDED
```

This prevents acting on outdated decisions. When a pattern is replaced, mark it `DEPRECATED` with a pointer to the replacement.

### Growth log format

Track discoveries as they happen:

```markdown
| Date | Project | Domain | Pattern | Shareable? |
|------|---------|--------|---------|------------|
| 2026-03-30 | <PROJECT-A> | Resilience | Circuit breaker 120s cooldown optimal | YES |
| 2026-03-30 | <PROJECT-B> | RAG | kNN K=20 outperforms K=10 | YES |
```

This log feeds the weekly consolidation (Layer 5).

---

## Layer 4: Project context

**Location**: Each project's `CLAUDE.md` and `MEMORY.md`
**Cost**: ~200 tokens per project
**Use for**: Pointers from each project to the shared layer.

### CLAUDE.md addition

Add a section to each project's CLAUDE.md:

```markdown
## Shared AI Knowledge (Cross-Project)
This project shares universal AI patterns with [other projects]:
- **Rules**: `~/.claude/rules/ai/` (N files)
- **Skills**: `~/.claude/skills/shared-*/` (N skills)
- **Memory**: [path to shared knowledge notes]
```

### MEMORY.md addition

Add a section to each project's auto-memory:

```markdown
## Shared AI Knowledge
- Rules at ~/.claude/rules/ai/ provide universal patterns
- Skills at ~/.claude/skills/shared-*/ provide detailed guides
- Knowledge notes at [path] provide decisions and gotchas
```

---

## Layer 5: Automation

**Cost**: Zero tokens (hooks and crons run externally)
**Use for**: Automatic capture and maintenance with zero manual effort.

### Hook: auto-save research results

If you use a research MCP (like Perplexity), auto-save results to your knowledge system:

```bash
#!/usr/bin/env bash
# PostToolUse hook — saves research results automatically
# Matcher: mcp__perplexity__search

INPUT=$(timeout 1 cat 2>/dev/null || exit 0)
QUERY=$(echo "$INPUT" | jq -r '.tool_input.query // "unknown"')
RESULT=$(echo "$INPUT" | jq -r '.tool_response.content // ""')

# Skip if empty
[[ -z "$RESULT" || "$RESULT" == "null" ]] && exit 0

# Generate filename from query
SLUG=$(echo "$QUERY" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | head -c 60)
CACHE_FILE="$HOME/knowledge/research-cache/${SLUG}.md"

# Dedup — skip if already cached
[[ -f "$CACHE_FILE" ]] && exit 0

# Save with frontmatter
cat > "$CACHE_FILE" <<EOF
---
title: $QUERY
date: $(date +%Y-%m-%d)
tags: [research, auto-cached]
---

$RESULT
EOF
```

### Hook: pre-compact recovery

Save critical context before compaction so you can recover:

```bash
#!/usr/bin/env bash
# PreCompact hook — lists loaded AI rules for post-compact reference

echo "### AI Rules Loaded (for post-compact reload)"
for f in $HOME/.claude/rules/ai/*.md; do
  [[ -f "$f" ]] && echo "- $(basename "$f")"
done
```

### Hook: session start context

Load shared knowledge status on session start:

```bash
#!/usr/bin/env bash
# SessionStart hook — check for stale knowledge

STALE=$(find $HOME/knowledge/ai/ -name "*.md" -mtime +60 2>/dev/null | wc -l)
if [[ $STALE -gt 0 ]]; then
  echo "### Warning: $STALE AI knowledge notes older than 60 days"
fi
```

### Cron: weekly consolidation

Review the growth log and check freshness:

```bash
#!/usr/bin/env bash
# Weekly cron (e.g., Sunday 3 AM)
# Checks knowledge freshness against SLAs

REPORT="$HOME/.claude/logs/consolidation-$(date +%Y-%m-%d).md"

echo "# Weekly Knowledge Consolidation" > "$REPORT"
echo "> Date: $(date +%Y-%m-%d)" >> "$REPORT"

# Check for stale notes
for dir in decisions investigations research-cache; do
  MAX_DAYS=90  # Adjust per note type
  STALE=$(find "$HOME/knowledge/$dir" -name "*.md" -mtime +$MAX_DAYS 2>/dev/null | wc -l)
  TOTAL=$(find "$HOME/knowledge/$dir" -name "*.md" 2>/dev/null | wc -l)
  echo "- **$dir**: $STALE/$TOTAL stale (SLA: ${MAX_DAYS}d)" >> "$REPORT"
done
```

### Cron: monthly health check

A smoke test script that verifies the entire system:

```bash
#!/usr/bin/env bash
# Monthly cron (1st of month, 5 AM)

echo "=== AI Knowledge Smoke Test ==="
echo "1. Rules: $(ls $HOME/.claude/rules/ai/*.md 2>/dev/null | wc -l) files"
echo "2. Skills: $(ls -d $HOME/.claude/skills/shared-*/ 2>/dev/null | wc -l) dirs"
echo "3. Knowledge notes: $(ls $HOME/knowledge/ai/*.md 2>/dev/null | wc -l) files"

BUDGET=$(find $HOME/.claude/skills -name SKILL.md -exec grep -m1 'description:' {} \; | wc -c)
echo "4. Skill budget: $((BUDGET * 100 / 16000))%"
```

---

## Layer 6: Knowledge lifecycle

**Use for**: Preventing knowledge rot over time.

### Freshness SLAs

Different note types decay at different rates:

| Note Type | Max Age (no edits) | Action When Stale |
|-----------|-------------------|-------------------|
| Decision | 90 days | Review: still valid? |
| Investigation | 60 days | Archive unless referenced |
| Log | 30 days | Auto-archive |
| Research cache | 90 days | Re-search if technology changed |

### Promotion flow

When a pattern appears in 2+ projects, promote it:

```
Project discovers pattern
  → Capture in growth log
  → Weekly consolidation flags cross-project patterns
  → Review: Is it universal?
    → YES: Promote to ~/.claude/rules/ai/ or skills/shared-*/
    → NO: Keep in project-level rules
```

### The `/document` integration

If you use a documentation command, add two checks:

1. **Research Lookup**: Before documenting, search your knowledge system for related prior findings.
2. **Cross-Project Detection**: When documenting an AI pattern, check if similar patterns exist in other projects and suggest promotion.

### Skill lifecycle SLA

| Age (no invocation) | Action |
|---------------------|--------|
| 90 days | Archive candidate — scope to single project OR mark deprecated |
| 180 days | Delete candidate — hard-delete unless reference-only purpose |

Promotion criteria (project → global):
- Used in 2+ projects for 30+ days.
- No project-specific file paths in content.
- Description contains explicit trigger clause ("Use when...").

---

## Putting it all together

### Initial setup (one-time)

1. Create `$HOME/.claude/rules/ai/` with 3-7 universal rules extracted from your projects.
2. Create `$HOME/.claude/skills/shared-*/` with 2-4 detailed guides.
3. Create knowledge notes directory with initial ADRs and gotchas.
4. Add shared knowledge section to each project's CLAUDE.md.
5. Wire hooks (research auto-save, pre-compact, session start).
6. Add crons (weekly consolidation, monthly smoke test).

### Ongoing (automatic)

Once set up, the system is self-sustaining:

- **Every session**: Rules load automatically, skills trigger on keywords.
- **Every research query**: Results auto-saved by hook.
- **Every week**: Consolidation cron checks freshness, flags cross-project patterns.
- **Every month**: Smoke test verifies system health.
- **When you discover a pattern**: Growth log → weekly review → promote if universal.

### Token budget tracking

Monitor your budget monthly:

```bash
# Skills budget (descriptions only)
find $HOME/.claude/skills -name SKILL.md -exec grep -m1 'description:' {} \; | wc -c
# Target: under 13,600 chars (85% of 16K)

# Rules count
find $HOME/.claude/rules -name "*.md" | wc -l
# Each rule costs ~500 tokens in every message
```

---

## Common pitfalls

| Pitfall | Fix |
|---------|-----|
| Rules too long (>120 lines) | Split into rule (short) + skill (detailed) |
| Rules too project-specific | Keep in project `.claude/rules/`, not global |
| Knowledge never gets reviewed | Weekly cron + freshness SLAs |
| Growth log stays empty | Check hooks are firing (test with simulated input) |
| Token budget overflow | Archive low-value skills, use `paths:` on domain rules |
| Same pattern rediscovered | Promote to shared rule after 2nd occurrence |

---

## Example: dedup after sharing

After creating shared rules, your project-level rules may overlap. Audit and remove duplicates:

```bash
# Find potential overlaps between project rules and global AI rules
for f in .claude/rules/*.md; do
  TOPIC=$(head -1 "$f" | sed 's/^# //')
  MATCH=$(grep -rl "$TOPIC" $HOME/.claude/rules/ai/ 2>/dev/null)
  [[ -n "$MATCH" ]] && echo "OVERLAP: $(basename $f) ↔ $(basename $MATCH)"
done
```

For each overlap:
1. Compare content — is the project rule 90%+ covered by the global rule?
2. If yes: update cross-references, then delete the project rule.
3. If partial: keep project-specific details, reference global rule for universal patterns.

---

## Summary

| What | Where | Cost | Automatic? |
|------|-------|------|------------|
| Universal patterns | `~/.claude/rules/ai/` | ~500 tokens/rule | Always loaded |
| Detailed guides | `~/.claude/skills/shared-*/` | ~40 tokens (desc) | Keyword triggered |
| Decisions & gotchas | Knowledge notes | 0 (on-demand) | Searchable |
| Project pointers | CLAUDE.md + MEMORY.md | ~200 tokens | Always loaded |
| Research capture | PostToolUse hook | 0 | Automatic |
| Freshness checks | Weekly/monthly crons | 0 | Automatic |

The key insight: **every layer has a different token cost and loading strategy**. Rules are expensive but always available. Skills are cheap but on-demand. Memory is free but requires search. Hooks and crons are invisible. Use each layer for what it does best.

---

## See also

- [AI DNA shared layer](01-ai-dna-shared-layer.html) — meta-methodology behind the shared-layer approach
- [Inter-agent bus](02-inter-agent-bus.html) — live coordination channel between projects
- [Self-telemetry](03-self-telemetry.html) — measure how the shared layer is being used
- [Hook event catalog](../part6-reference/03-hook-event-catalog.html) — hook event reference

---

*Published: March 2026. Last updated: 2026-04-20. Compatible with Claude Code 2.1.111+.*
