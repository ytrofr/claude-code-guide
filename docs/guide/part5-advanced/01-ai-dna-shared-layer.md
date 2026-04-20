---
layout: default
title: "AI DNA Shared-Layer Across Projects"
parent: "Part V — Advanced"
nav_order: 1
---

# AI DNA Shared-Layer Across Projects

A pattern for teams or individuals running multiple AI-using projects (LLM agents, RAG systems, multi-agent pipelines). Share universal AI patterns globally; keep project-specific patterns local. The shared layer becomes the collective memory of what your AI systems have learned — across every project, every session.

Think of it as DNA: small, well-tested genetic instructions that express themselves anywhere they're loaded. A circuit breaker pattern that took three outages to get right in `<PROJECT-A>` shouldn't need to be rediscovered in `<PROJECT-B>`.

---

## When this applies

- You have 2+ projects using Claude, Gemini, or other LLM APIs.
- You've discovered patterns that apply across projects (circuit breaker, multi-provider fallback, prompt caching, retry policy, tool-result format).
- You keep rediscovering the same solution in different projects — and fixing it slightly differently each time.
- You want one place to track "what we know about building AI systems".

If you have exactly one project, skip this chapter. AI DNA only pays off at 2+ projects. For a single-project setup, project-local `.claude/rules/` is enough.

## When NOT to use it

- You're building one thing. Premature shared layer = premature abstraction.
- The "pattern" has only shown up in one project. Wait for the second occurrence.
- The knowledge is genuinely project-specific (e.g. "our API uses REST"). Keep it local.

---

## Architecture (5 layers)

The shared AI layer lives across five Claude Code surfaces, each carrying a different kind of content:

```
Layer 1: Shared Rules     ~/.claude/rules/ai/          always loaded, every session
Layer 2: Shared Skills    ~/.claude/skills/shared-*/   on-demand deep-dive guides
Layer 3: Knowledge Graph  ~/basic-memory/ai-dna/       persistent, wiki-linked notes
Layer 4: Meta-skill       ~/.claude/skills/ai-dna/     maintains the whole system
Layer 5: Growth Log       ai-dna/knowledge-growth-log  chronological pattern ledger
```

### Layer 1 — Shared rules (`~/.claude/rules/ai/`)

Short, mandatory patterns that should be in context for every AI-adjacent session. One file per domain. Example file breakdown:

| File | Content |
|------|---------|
| `adk-core-patterns.md` | Agent registration, tool return format, entity resolution |
| `gemini-optimization.md` | Model selection, thinking control, tool forcing |
| `llm-resilience.md` | Circuit breaker, multi-provider fallback, retry, budget |
| `multi-agent-orchestration.md` | LLM-driven routing, scoped sessions, loop guards |
| `ai-observability.md` | Pipeline logging, cost tracking, health endpoints |
| `hebrew-llm-patterns.md` | RTL/UTF-8, temporal resolution, monolingual prompt |
| `ai-dna-methodology.md` | The methodology itself, recursively |

Kept short — each file is the distilled invariant, not the deep-dive. Deep-dive lives in Layer 2.

### Layer 2 — Shared skills (`~/.claude/skills/shared-*/`)

Loaded on demand when the relevant domain is active. Each shared skill is a richer guide with code samples, decision trees, gotcha tables.

| Skill | Typical content |
|-------|-----------------|
| `shared-adk-development/` | ADK setup, tool patterns, orchestration, testing |
| `shared-rag-architecture/` | RAG/CAG decision tree, pgvector, retrieval strategies |
| `shared-ai-quality/` | Baseline testing, quality scoring, pass^k methodology |

Rules say "what must be true". Skills say "here's how you do it in practice".

### Layer 3 — Knowledge graph (`~/basic-memory/ai-dna/`)

Persistent wiki-linked notes. Five core notes:

| Note | Purpose |
|------|---------|
| `architecture-decisions.md` | ADRs for cross-project AI choices |
| `cross-project-patterns.md` | Patterns proven in 2+ projects with evidence |
| `production-gotchas.md` | Traps discovered in production with fixes |
| `model-selection-history.md` | Model changes with rationale and impact |
| `knowledge-growth-log.md` | Chronological log of every pattern added |

The graph is where *why* lives. Rules have the what; skills have the how; the graph has the history.

### Layer 4 — Meta-skill (`~/.claude/skills/ai-dna/`)

One skill that knows how to maintain the whole system:

- Scan for orphan rules (rules nothing references).
- Promote project-local patterns to global when the second project hits them.
- Flag stale notes past their freshness SLA.
- Surface promotion candidates during monthly health check.

Invoked by the human: "run `/ai-dna health check", "promote this skill to global".

### Layer 5 — Growth log

Append-only ledger in `ai-dna/knowledge-growth-log.md`:

```
| Date       | Project     | Domain     | Pattern                                          | Shareable? |
|------------|-------------|------------|--------------------------------------------------|------------|
| 2026-03-30 | <PROJECT-A> | orchestr.  | disallow_transfer_to_peers prevents lateral loops | YES → adk-core |
| 2026-03-28 | <PROJECT-B> | RAG        | pass^k=3 reduces flaky test false positives      | YES → shared-ai-quality |
| 2026-03-25 | <PROJECT-C> | resilience | Model pinning with 10min TTL prevents flip-flop  | YES → llm-resilience |
```

Every row is a micro-commit on institutional knowledge. Readers at month N can trace why a rule exists back to month N−6.

---

## Promotion criteria (project → global)

Before moving a pattern from a project's `.claude/rules/` into the global `rules/ai/`, it must pass all four gates:

| Gate | Check |
|------|-------|
| 1. Two-project rule | Pattern is used in ≥ 2 projects for ≥ 30 consecutive days |
| 2. No project paths | No references to project-specific file paths, env vars, or service names |
| 3. Trigger clause | Description contains explicit "Use when…" — so autoloaders can match |
| 4. Not already covered | Grep existing `rules/ai/` first; if a rule exists, edit it, don't create a new one |

If any gate fails, the pattern stays project-local. A premature promotion is worse than no promotion — it creates a rule that doesn't quite match any project's reality.

### Reverse flow (global → project)

Sometimes a rule that looked universal turns out to apply in only one project. Two options:

- Rename the skill to include the project (`blueprint` → `blueprint-<project>`).
- Move it to `<project>/.claude/skills/<name>/`.

Either way, log the direction in the growth log (`global → project`).

---

## The monthly health check

Run on the 1st of each month (manual or scheduled):

1. All `rules/ai/*.md` files have `Last Updated` within 60 days.
2. All `skills/shared-*/` skills load without errors.
3. All `ai-dna/*` memory notes exist and are non-empty.
4. Growth log has ≥ 1 entry from the past 30 days.
5. No ADR stuck in `PROPOSED` for > 30 days.
6. Weekly consolidation cron ran successfully.
7. No duplicate patterns across rules (grep for overlapping content).
8. Freshness SLAs: zero notes past their threshold without review.
9. Cross-project pattern count is growing month-over-month.
10. Memory graph connectivity: `ai-dna/*` notes have wiki-links to project notes.

Hit items 1–5 in ~10 minutes. Items 6–10 take longer but surface the real work: what's drifting, what's duplicated, what's dead.

### Staleness SLAs

| Note type | Max age | Action when stale |
|-----------|---------|-------------------|
| `decision` | 90 days | Review: still valid? Update status or confirm |
| `investigation` | 60 days | Archive unless actively referenced |
| `log` | 30 days | Auto-archive (ephemeral by nature) |
| `note` | 120 days | Flag for review |
| `research-cache` | 90 days | Re-search if tech changed |
| `ai-dna/*` | 60 days | Validate against current code |

SLAs exist because AI infrastructure changes fast. A pattern from six months ago may be obsolete. The SLA forces a look, not necessarily a rewrite.

---

## Worked example

A pattern's full lifecycle from discovery to global adoption:

**Month 1** — `<PROJECT-A>` ships a new multi-agent system. Under load, one agent starts transferring control laterally to a peer, creating a loop. Investigation reveals the LLM is inferring it should route peer-to-peer. Fix: add `disallow_transfer_to_peers=True` on sub-agents. Outcome: 13 lateral transfers per day → 0.

Pattern stays in `<PROJECT-A>/.claude/rules/` as an investigation note. Growth-log entry written with `Shareable? PENDING`.

**Month 2** — `<PROJECT-B>`, an independent codebase, starts building a similar multi-agent architecture. During planning, a `grep` over `~/basic-memory/ai-dna/` surfaces `<PROJECT-A>`'s investigation. `<PROJECT-B>` adopts the fix upfront. Growth-log entry updated: `Shareable? YES`.

**Month 3** — Pattern satisfies all four promotion gates (used in 2 projects for 30+ days, no project paths, has trigger clause, no overlap). Moved to `~/.claude/rules/ai/multi-agent-orchestration.md` as a core invariant.

**Month 4** — `<PROJECT-C>` starts a new multi-agent build. The rule loads automatically at session start. The pattern is applied on day one. The circuit closes: three projects, one rule, no re-discovery.

The growth log records the whole arc. A year later, someone asking "why this flag?" finds the answer in 30 seconds.

---

## Scripts and automation

The meta-skill orchestrates maintenance; scripts do the heavy lifting:

| Script | Frequency | Purpose |
|--------|-----------|---------|
| `~/.claude/scripts/ai-knowledge-consolidation.sh` | Weekly (Sun) | Scan for new patterns, flag stale notes, write log |
| `~/.claude/scripts/bm-daily-maintenance.sh` | Daily | Basic Memory reindex + growth counter |

Output files land in `~/.claude/logs/ai-consolidation-{date}.md`. The human reviews weekly:

1. **New patterns detected** — are they truly universal?
2. **Staleness alerts** — patterns approaching their freshness SLA.
3. **Cross-reference gaps** — patterns missing wiki-links or evidence.

Act on findings: promote, archive, or update.

### Integration with `/document`

The `/document` skill (run at natural session-end points) includes a "Cross-Project Pattern Detection" phase. It:

1. Identifies patterns used in the current project's session.
2. Scans other projects' `.claude/` directories for similar patterns.
3. If found in 2+ projects, recommends promotion.

Makes the growth log self-populating rather than a manual chore.

---

## Anti-patterns

- **Promoting project-specific paths to global.** If the rule mentions `~/some-project/config.yaml`, it's not global. Scrub or leave local.
- **Creating a global rule for a single-project pattern.** Wait for the second occurrence. One is anecdote, two is pattern.
- **Not reading existing rules before writing a new one.** Duplication at the global layer is worse than duplication at the project layer because every session pays the cost.
- **Letting `ai-dna/*` grow unchecked.** The 60-day SLA exists for a reason — stale AI knowledge misleads future sessions.
- **Writing the growth log as an afterthought.** The log IS the institutional memory. If you skip logging, you skip the compounding.
- **Using AI DNA with one project.** The overhead (maintenance, health checks, promotion gates) doesn't pay off at N=1.

---

## See also

- [Cross-project knowledge sharing](06-cross-project-knowledge.html) — the mechanics (this chapter is the methodology).
- [Rules system](../part4-context-engineering/02-rules-system.html) — how global rules are auto-loaded.
- [Skill lifecycle](../part4-context-engineering/07-skill-lifecycle.html) — archive/delete SLAs for skills.
- [Session-end and defrag workflow](07-session-end-and-defrag.html) — keeping the layer healthy session-to-session.
