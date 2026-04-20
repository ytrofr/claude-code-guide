---
layout: default
title: "Skill Catalog"
parent: "Part VI — Reference"
nav_order: 4
---

# Skill Catalog

Skills shipped by the `install.sh` installer, grouped by tier. The authoritative source for what each tier contains is `best-practices/manifest.json` — this chapter is a human-readable projection of that file.

Install a tier with:

```bash
# Core (3 skills, 8 rules, 1 hook)
curl -sL https://raw.githubusercontent.com/ytrofr/claude-code-guide/master/install.sh | bash

# Recommended (16 skills, 30 rules, 7 hooks)
./install.sh --recommended

# Full (44 skills, 55+ rules, 12 hooks, governance scaffolding)
./install.sh --full
```

Skills install to `~/.claude/skills/<name>/SKILL.md` and are **global** across every project on the machine — per-user, not per-project. One install; every Claude Code session across every repo picks them up.

---

## Core tier (3 skills)

Newcomer-friendly starter. Covers the two highest-ROI loops (verify, session-start) plus a routing tree for debugging.

| Skill | Description |
|---|---|
| `verify` | Verify app after changes — auto-detects scope, runs health checks, tests, code quality. Use before commit or deploy. |
| `session-start` | Initialize session following Anthropic best practices (checkpoint discovery, git status, memory context). |
| `troubleshooting-decision-tree` | Route troubleshooting patterns by issue type (connection errors, integration failures, behavioral mismatches). |

---

## Recommended tier — adds 13 (total 16)

Working developer set. Adds debugging workflows, planning rigor, TDD discipline, memory hygiene, MCP usage patterns, and documentation.

### Workflow (5)

| Skill | Description |
|---|---|
| `tdd` | Enforce Test-Driven Development: RED (failing test) → GREEN (min code to pass) → REFACTOR. |
| `plan-checklist` | Generate plan templates with 13 mandatory sections, KPI dashboard, pre-validation probe, modularity gates. |
| `session-end` | End session per Anthropic best practices — invoke when approaching context limit or wrapping up. |
| `retrospective` | Create a skill from session learnings (guided). Use after major milestones or when discovering a reusable pattern. |
| `document` | Document session work plus 7-check pattern analysis at 3 levels (machine / project / branch). Suggests rules, skills, memory notes. Stops for user confirmation. |

### Memory (3)

| Skill | Description |
|---|---|
| `memory-defrag` | Defragment and reorganize agent memory — split bloated files, merge duplicates, remove stale info. Run weekly. |
| `memory-notes` | Write well-structured Basic Memory notes with frontmatter, observations, semantic categories, and wiki-links. |
| `memory-search-patterns` | Progressive-disclosure Basic Memory search: 3-layer workflow (index → preview → fetch) for 10× token savings. |

### MCP / tools (3)

| Skill | Description |
|---|---|
| `mcp-usage-patterns` | Select the right MCP tool per task (PostgreSQL, GitHub, Memory, Perplexity). |
| `perplexity-workflow` | Perplexity API usage with monthly budget ceiling, cache-first memory enforcement, tool selection. |
| `playwright-mcp` | Automate browsers with Playwright MCP — testing, screenshots, form filling, data extraction. |

### Deploy / ops (2)

| Skill | Description |
|---|---|
| `canary` | Post-deploy canary checks — screenshot capture, console error detection, network error scanning, baseline comparison. |
| `doctor-workflow` | Interpret and act on doctor script results. Use when doctor fails, before deploys, or when diagnosing project health. |

---

## Full tier — adds 28 (total 44)

Power-user set. Adds governance scaffolding, AI/LLM patterns (Gemini, multi-agent, resilience), architecture patterns (observability, auth, data cascade), and cross-project coordination.

### Governance (8)

Context-budget management, self-telemetry, hygiene scanning, rollback.

| Skill | Description |
|---|---|
| `context-audit` | Audit context budget health — measures char costs, detects bloat, flags duplicates, identifies optimization targets. |
| `context-optimization` | Optimize full context stack — audit, classify, condense, relocate, verify. Use when budget exceeds targets. |
| `context-governance` | Orchestrate context governance — audit state, decide action by status, dispatch to /context-audit, /context-optimization, or rollback. |
| `context-governance-rollback` | Roll back governance changes (rules, skills, scanners) to a tagged baseline. |
| `audit-stack` | Audit Claude Code stack freshness against latest official docs and Hub data. Use after CC upgrades. |
| `skill-metrics` | Display skill activation metrics from pre-prompt logging. Use when checking which skills are being triggered. |
| `weekly-review` | Generate a CC weekly self-telemetry review — prompts, tool calls, MCP latency, skills, subagent dispatches, session KPIs. |
| `gitignore-anchor-audit` | Audit .gitignore files for unanchored top-level dirs that recursively shadow nested paths. |

### AI patterns (9)

Gemini/Claude/multi-model patterns, orchestration, resilience, evaluation.

| Skill | Description |
|---|---|
| `multi-agent-patterns` | Advanced multi-agent orchestration patterns: streaming parity, sticky modes, correction flow, transparent delegation, knowledge propagation. |
| `gemini-patterns` | Gemini production patterns: JSON mode coercion, thinking+JSON conflict, empty-response nudge, non-determinism band, instruction position. |
| `llm-resilience-patterns` | Circuit breaker, multi-provider fallback, per-call retry, instruction-corruption recovery, context overflow, budget enforcement. |
| `multi-model-llm-routing` | Route between LLM models by task type, cost, and quality. Implements primary/fallback patterns. |
| `mcp-tool-evaluation` | Evaluate whether new tools should be MCP, Skill, or Agent. Prevents wrong-tool-type choices. |
| `prompt-optimization-methodology` | Compress LLM prompts systematically with accuracy validation. Reduce tokens without regressing quality. |
| `llm-finish-reason-probe` | Log Gemini `finish_reason` and Claude `stop_reason` non-normal values for observability. Catches silent mid-phrase truncations. |
| `a-b-c-variant-experiment` | Run a 3-variant A/B/C probe to determine whether a prompt change improves behavior or hits a ceiling. ~45 min. |
| `anthropic-eval-best-practices` | Apply Anthropic's 6 eval best practices: pass^k consistency, transient-failure handling, flaky-test recovery. |

### Architecture patterns (9)

Observability, cron safety, liveness, entity handling, refactoring, fetching, auth, invariants.

| Skill | Description |
|---|---|
| `observability-first-pattern` | Break the hypothesis-debate loop after 3+ failed fixes at the same layer. Build a per-request persistent tracer before the 4th attempt. |
| `cron-lock-patterns` | pg_try_advisory_lock async context manager + single-instance file lock + key-selection rationale + jitter formula. Prevents duplicate cron fires. |
| `service-liveness-monitoring` | Two-signal service liveness: indirect (work piling up?) + direct (loop beat recorded?). Detects stuck loops. |
| `entity-resolution-pattern` | Resolve entity names to IDs in code, not LLM chains. Fixes multi-step lookup failures. |
| `god-file-extraction-methodology` | Split god files (1500+ lines) safely into modular components with zero regressions. |
| `parallel-rate-limited-fetcher` | Fetch from multiple APIs in parallel with rate-limit checking, circuit breakers, and graceful failure isolation. |
| `signed-url-auth` | Signed-URL auth for session-less users (Telegram/WhatsApp/SMS/voice/CLI). JWT signing + verification + jti replay registry. |
| `ast-contract-tests` | Encode structural invariants as AST-walking pytests — required kwargs, decorators, call patterns. |
| `write-side-cascade` | Cascade pointer consistency at mutation time, not read time. Feature-toggled, idempotent backfill, observability. |

### Cross-project coordination (2)

For machines running multiple Claude Code projects that need to share knowledge or coordinate.

| Skill | Description |
|---|---|
| `ai-dna` | Maintain shared AI knowledge across multi-project setups — rules, skills, memory notes, pattern promotion, staleness checks, monthly health audits. |
| `inter-agent` | Coordinate with Claude in another project via shared bus. `/talk-new`, `/talk-send`, `/talk-stream`, `/talk-resolve` — no more terminal copy-paste. |

---

## Invoking skills

Once installed, skills are available in three ways:

### 1. Slash invocation (explicit)

```
/verify
/tdd
/plan-checklist
```

Always-available at the prompt. Works for every skill unless `user-invocable: false` is set in its frontmatter.

### 2. Auto-invocation (model-driven)

Claude reads each skill's `description:` field on session start and can invoke the skill on its own when the description matches the task at hand. Well-written descriptions use `Use when <trigger>` phrasing — this is what matches the incoming request.

Opt out per-skill with `disable-model-invocation: true` — keep it user-invocable, but prevent Claude from firing it unprompted. Useful for side-effect skills like deploy, commit, `/canary`.

### 3. Background knowledge (non-invocable)

Set `user-invocable: false` to hide a skill from the slash menu entirely. Claude loads its description and can use it as reference knowledge, but the user can't call it directly. Useful for "this is how we do X in this codebase" domain patterns.

### Description-field budget

Skill `description:` fields compete for ~2 percent of the context window. Keep each under 250 chars, with a clear trigger clause. Claude Code 2.1.105 raised the cap from 250 → 1536 chars, but shorter is still better — every byte counts against the budget.

Run `/skills` to see the full list and (in 2.1.111+) toggle sort-by-token-cost.

---

## See also

- [Part III, Ch. 04 — Skills authoring]({{ site.baseurl }}/guide/part3-extension/04-skills-authoring/) — how to write your own skill, frontmatter reference
- [Part III, Ch. 05 — Skills maintenance]({{ site.baseurl }}/guide/part3-extension/05-skills-maintenance/) — lifecycle, promotion, archival, SLAs
- [Part I, Ch. 05 — Installation]({{ site.baseurl }}/guide/part1-foundations/05-installation/) — the `install.sh` tiers end-to-end
- `best-practices/manifest.json` — the authoritative JSON this chapter projects
