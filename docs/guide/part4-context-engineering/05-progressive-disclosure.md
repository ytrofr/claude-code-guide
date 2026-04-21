---
layout: default
title: "Progressive Disclosure"
parent: "Part IV — Context Engineering"
nav_order: 5
redirect_from:
  - /docs/guide/15-progressive-disclosure.html
  - /docs/guide/15-progressive-disclosure/
---

# Progressive Disclosure

**Current as of**: Claude Code 2.1.111+.
**Related**: [Chapter 02 — Rules System](./02-rules-system.html), [Chapter 03 — Basic Memory MCP](./03-basic-memory-mcp.html)

---

## What it is

Progressive disclosure is the practice of loading **minimum context first, more on demand**. Instead of dumping every reference into the session, you provide a compact summary and let Claude read deeper when a task requires it.

Three reasons it matters:

1. **Finite context window** — 1M tokens on Opus 4.6/4.7 Max is a lot, but it's not free. Cache misses on large static content are expensive.
2. **Quality degrades above 75% usage** — Anthropic research + field evidence both show code quality drops as the window fills.
3. **Routing beats fetching** — Claude can often answer "which tool do I use" from a summary alone, never needing the full reference.

The rest of this chapter codifies the 3-layer pattern, applies it to four surfaces (memory, skills, docs, rules), and lists the anti-patterns.

---

## The 3-layer pattern

Each layer is roughly 10x cheaper than the next. The right workflow goes **down** one layer at a time, not straight to layer 3.

| Layer | What it returns | Typical cost | Use when |
|-------|-----------------|--------------|----------|
| 1. Index | Titles + IDs | ~50 tokens/result | Exploring; unsure what's relevant |
| 2. Preview | Truncated snippets | ~200 tokens/result | Scanning to pick the right one |
| 3. Full | Complete content | ~500-2000 tokens | Only after filtering — you know the target |

### Applied to Basic Memory

```python
# Layer 1 — cheap index
results = mcp__basic_memory__search(query="auth")

# Layer 2 — preview the top candidates
results = mcp__basic_memory__search_notes(query="auth", page_size=5)

# Layer 3 — fetch only the one you need
note = mcp__basic_memory__fetch(id="fixes/auth-token-expiry")
```

### Applied to files

For large Markdown/code files, use `Read` with `offset` and `limit` to load only the relevant section:

```
Read(file_path="~/docs/schema.md", offset=150, limit=50)
```

This fetches lines 150-200 — the specific table definition — without pulling the entire 800-line schema.

---

## MINI files for always-loaded context

When a reference genuinely needs to be loaded every session (e.g., core project rules), keep the loaded version small and reference the full version.

**Target sizes**:
- MINI file: 500-2,000 tokens (30-80 lines)
- Full file: 5,000-10,000 tokens (200-400 lines)

### Before — full file auto-loaded

```markdown
# API Integration Patterns

## External API A
Endpoint: https://api.example-a.com/v2/
Auth: OAuth2 client_credentials
Content-Type: application/x-www-form-urlencoded
... 50 more lines on auth
... 100 lines of endpoint inventory
... 200 lines of error handling
```

### After — MINI file auto-loaded, full file on demand

```markdown
# API-MINI.md

## Quick Reference

- External API A: api.example-a.com/v2/ (OAuth2, product catalog)
- External API B: api.example-b.com/v1/ (user/pass, employee data)
- LLM API: provider-model-version (region)

Full reference: ~/memory-bank/ondemand/api/integrations.md
```

**Rule of thumb**: The MINI answers "which API do I use?" and "what are the basics?" The full file answers "how exactly do I authenticate?" and "what are all the endpoints?"

---

## Progressive disclosure for skills

Skills benefit especially from this pattern because Claude Code loads activated skill content into the conversation. A 10k-token skill pays 10k every time it triggers.

### Structure

```
deployment-workflow/
├── SKILL.md                  # 2-3k — core workflow + decision tree
└── references/
    ├── cloud-run.md          # 2k — Cloud Run specifics
    ├── traffic-routing.md    # 2k — traffic management
    └── rollback.md           # 2k — rollback procedures
```

The main `SKILL.md` contains the workflow summary and points to which reference to read based on the task. Only one reference loads per query.

### Measured savings

For a real skill broken up this way:

- **Before**: 8.5k tokens always loaded (every query pays the cost)
- **After**: 2.5k base + 1.5-2.6k per reference = 4-5k per query
- **Savings**: ~50% per query

The ceiling on skill description size is 1536 chars (as of 2.1.105). If your skill core is pushing that, references are mandatory, not optional.

---

## Progressive disclosure for rules

Rules in `~/.claude/rules/` are always-on in every session. Treat them like MINI files: compact invariants, pointers to skills for detail.

### Pattern

```markdown
# Rule name — Invariant

**Scope**: ALL projects ...
**Detail**: invoke skill `<skill-name>` (full patterns, tests, evidence)

---

## Core Rule

<1-3 sentence invariant>

## When to Apply

- Bullet list of triggers

---

**Full patterns + code**: invoke skill `<skill-name>`.
```

Rules stay under ~4k chars. Detail lives in skills, which only load when invoked or activated. This is the **pointer pattern** — and it reclaimed ~17k chars of always-on context in one production audit.

See [Chapter 02 — Rules System](./02-rules-system.html) for the full rule format.

---

## Anti-patterns

**Loading everything upfront.** Importing every documentation file in CLAUDE.md wastes context and reduces quality. If it isn't needed in the majority of sessions, it doesn't belong in always-on.

**Duplicating content between MINI and full.** When one updates, the other goes stale. The MINI should **reference** the full file, never copy from it.

**Skipping the MINI level.** Going straight from "nothing loaded" to "read the entire 500-line file" defeats the pattern. The summary level prevents unnecessary full loads for simple questions.

**MINI files over 80 lines.** A 200-line "summary" is not a summary. If Claude needs more, it will read the full file — that's the whole point.

**Fetching layer 3 from a search.** `search_notes()` returns previews; `fetch()` is the layer below. Don't `fetch()` in a loop over search results — preview the results first, then fetch only the one you actually need.

---

## Token budget guidelines

| Context usage | Budget | Quality impact |
|---------------|--------|----------------|
| Under 50% | Optimal | Best code quality |
| 50-75% | Good | Slight degradation |
| 75-90% | Degraded | Checkpoint and start fresh |
| Over 90% | Poor | Error rate climbs sharply |

**The 75% rule**: code quality begins to degrade above 75% context usage. When you approach this threshold, commit your work and start a fresh session. Progressive disclosure keeps you below this limit for longer.

---

## Implementation checklist

1. Identify files that are auto-loaded but rarely needed in full
2. Create MINI versions with just the essential quick-reference content
3. Add a "Full reference: path/to/full-file.md" pointer in each MINI
4. Replace the `@` import in CLAUDE.md with the MINI version
5. For skills over 5k tokens, split into `SKILL.md` + `references/` subdirectory
6. For rules over 4k chars, move detail into a skill and leave a pointer
7. Monitor context usage (`/context`) and adjust

---

## Further reading

- **[02 — Rules System](./02-rules-system.html)**: rule format + path-scoped rules
- **[03 — Basic Memory MCP](./03-basic-memory-mcp.html)**: progressive disclosure in the MCP layer
- Chapter 15 (archived): the original version of this pattern, retained via redirect
