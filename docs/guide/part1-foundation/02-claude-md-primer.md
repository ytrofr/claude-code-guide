---
layout: default
title: "CLAUDE.md Primer"
parent: "Part I — Foundation"
nav_order: 2
redirect_from:
  - /docs/guide/25-best-practices-reference.html
  - /docs/guide/25-best-practices-reference/
---

# CLAUDE.md Primer

`CLAUDE.md` is the single most leveraged file in any Claude Code setup. It's auto-loaded at the start of every session, it's cached by the prompt cache across sessions, and it shapes what Claude knows about your project before the first message. Treat it as prime real estate -- keep it short, keep it factual, and resist the temptation to dump best-practices lists into it.

**Purpose**: Author a CLAUDE.md that earns its place in every session's context
**Difficulty**: Beginner
**Applies to**: Any project using Claude Code

---

## What CLAUDE.md Is

CLAUDE.md is a Markdown file that Claude Code auto-loads as system-level context at the start of every session (and re-injects after `/compact`). It's visible to Claude as a block labelled `claudeMd` with a note that "these instructions OVERRIDE any default behavior and you MUST follow them exactly."

That override authority makes it powerful and dangerous. Every byte in CLAUDE.md is always-on -- loaded into context for every single turn. A 10K CLAUDE.md costs 10K tokens per turn, forever. A 500-line CLAUDE.md that repeats what your rules already say is waste.

The file is cached across sessions by Anthropic's prompt cache (5-minute TTL, extendable to 1 hour with `ENABLE_PROMPT_CACHING_1H`). Keep its content byte-stable across sessions and you get cache hits; vary it per-session and you pay full freight every time.

---

## Where It Lives

CLAUDE.md can live in three places, all loaded in a specific order:

| Location | Scope | When it loads |
|---|---|---|
| `~/.claude/CLAUDE.md` | Global / per-user | Every session on this machine |
| `<project>/CLAUDE.md` | Per-project | Sessions with cwd inside that project |
| `<project>/.claude/CLAUDE.md` | Per-project (alternative) | Same as above |
| `<any-subdir>/CLAUDE.md` | Nested | Loaded lazily when Claude enters that subdir |

Nested CLAUDE.md files are reloaded on directory change and are a clean way to scope instructions to a single package or module without bloating the top-level file. Global CLAUDE.md should be reserved for truly universal preferences; anything project-specific belongs in the project.

Most projects will have one `<project>/CLAUDE.md` and no global CLAUDE.md at all. Nested CLAUDE.md is a tool for monorepos and very large projects.

---

## Anatomy of a Good CLAUDE.md

A well-authored CLAUDE.md has four ingredients:

1. **Project identity** -- repo URL, one-sentence purpose
2. **Directory layout** -- where things live (just the map, not the details)
3. **An `@import` line** pulling in the universal best-practices doc
4. **Project-specific facts** that rules and skills can't know

That's it. No "Development Guidelines" list. No "coding standards." No best practices that repeat what your rules already enforce. Rules handle universal enforcement; skills handle reusable workflows; CLAUDE.md is for the irreducible facts of *this* project.

### Example

```markdown
# MyApp - Project Instructions

**Repository**: https://github.com/you/myapp
**Purpose**: E-commerce backend with Stripe integration

---

## Project Structure

```
myapp/
├── api/           # FastAPI routes
├── services/      # Business logic, Stripe client
├── models/        # SQLAlchemy models
├── migrations/    # Alembic migrations
└── tests/
```

## Stack

- Python 3.12 / FastAPI / SQLAlchemy 2.x / Alembic / PostgreSQL 16
- Stripe API v2024-11-20

## Commands

- `make dev` - run dev server (port 8080)
- `make test` - pytest with coverage
- `make migrate` - run Alembic migrations

@.claude/best-practices/BEST-PRACTICES.md
```

Notice what's *not* there: no "write clean code," no "follow SOLID," no "no mock data." Those live in rules (which the `@import` pulls in) and apply universally. The CLAUDE.md only says what's unique to MyApp.

---

## The `@import` Pattern

The `@path` syntax in CLAUDE.md tells Claude Code to inline another file's content at the import point. The installer sets up `best-practices/BEST-PRACTICES.md` as a single aggregated best-practices document; import it once in CLAUDE.md and you get all universal rules without copying them in.

```markdown
@.claude/best-practices/BEST-PRACTICES.md
```

This keeps CLAUDE.md small while still loading the full best-practices surface. When the best-practices file updates (via `update.sh` or re-running the installer), every project re-pulling that import picks up the change on next session start.

### Import gotchas

- **No circular imports** -- if `A.md` imports `B.md` and `B.md` imports `A.md`, Claude Code aborts the load.
- **Relative paths are resolved from the importing file**, not from cwd.
- **Use `@` only at the start of a line** -- mid-line `@` references are not imports.
- **Imports count toward the always-on context budget** -- the imported content is loaded verbatim.

---

## What Belongs Where

| Content | Goes in |
|---|---|
| Repo URL, one-line purpose, stack list | `CLAUDE.md` |
| Directory layout map | `CLAUDE.md` |
| Project-specific commands (`make dev`, etc.) | `CLAUDE.md` |
| Port numbers, DB names, credentials location | `CLAUDE.md` |
| Link to architecture doc | `CLAUDE.md` |
| Universal best practices (KISS, DRY, no-mock-data) | Rules (`.claude/rules/`) |
| Language-agnostic patterns (modularity, concurrency) | Rules |
| Reusable workflows (verify, canary, session-start) | Skills (`.claude/skills/`) |
| One-off investigations | Basic Memory notes, not CLAUDE.md |
| Stale metrics from 3 months ago | Nowhere -- delete it |

The test: if another project would benefit from this content too, it probably belongs in a rule or a skill, not CLAUDE.md.

---

## Keep It Under ~2K Characters

Budget target: **under 2,000 characters** for the top-level CLAUDE.md. Imports don't count toward this cap -- they're a separate concern -- but the file you actually write should be tight.

Why 2K? Because the always-on context budget matters. See [Part IV/04 — Context Budget](../part4-context-engineering/04-context-budget.md) for the full math, but the short version: everything in CLAUDE.md is paid for on every turn. Cheap content is content that earns its cost.

If your CLAUDE.md is approaching 4K, something has gone wrong -- you're probably duplicating rules content, or accumulating stale investigation notes, or padding with generic advice. Audit and cut.

---

## Anti-Patterns

### 1. The giant CLAUDE.md

Dropping every team agreement, coding standard, and recent debugging story into CLAUDE.md turns it into a 500-line wall of text. Claude will try to follow it, but the prime-position rules at the top drown out everything past the first screen. And you'll pay tokens for all of it on every turn.

**Fix**: move enforcement rules into `.claude/rules/`, move workflows into `.claude/skills/`, move past investigations into Basic Memory or a dedicated `docs/` folder.

### 2. Duplicating rules

Pasting `"Follow KISS, DRY, SOLID"` or `"Never use mock data"` into CLAUDE.md when those rules are already in `best-practices/rules/` or `~/.claude/rules/`. The rules are already auto-loaded -- the duplicate just inflates context and introduces drift risk.

**Fix**: delete the duplicates. Trust the rules system.

### 3. Stale project metrics

```markdown
## Current Metrics (as of 2024-11-15)
- 85% test coverage
- 42 open issues
- Last deploy: 2024-11-12
```

Dates, counts, and status go stale in days. Every session that loads this reads a lie.

**Fix**: if metrics matter for a session, put them in a skill that queries them live (`!`command`` injection), or in an auto-generated status file that's updated by CI. Not in CLAUDE.md.

### 4. Generic "best practices" essays

Sections like "Coding Standards", "How We Work", "Review Process" -- these are either rules content (belongs in rules), onboarding docs (belongs in CONTRIBUTING.md), or team lore (belongs in a wiki). They're rarely load-bearing for Claude's next action.

**Fix**: if Claude doesn't need it on every single turn to answer correctly, it's not CLAUDE.md material.

### 5. The forgotten @import

Adding `@path/to/big-doc.md` at the top and forgetting that every byte of `big-doc.md` now loads every turn. Imports are fine -- but they cost what their target costs.

**Fix**: audit imports periodically. `wc -c` the imported files. If `big-doc.md` is 20K, you just added 20K to your always-on budget.

---

## Pointers

- **How rules work** -- [Part IV/02 — Rules System](../part4-context-engineering/02-rules-system.md)
- **Context budget math** -- [Part IV/04 — Context Budget](../part4-context-engineering/04-context-budget.md)
- **Session lifecycle & prompt cache** -- [Part II/05 — Session Lifecycle](../part2-workflow/05-session-lifecycle.md)
- **Writing skills instead of stuffing workflows into CLAUDE.md** -- [Part III/01 — Skills](../part3-extension/01-skills.md) (if available), or the `skill-creator` plugin

---

## Checklist

Before committing a new or revised CLAUDE.md:

- [ ] Under 2K characters (run `wc -c CLAUDE.md`)
- [ ] No generic best-practices lists
- [ ] No stale dates or metrics
- [ ] `@import` present for the universal best-practices doc
- [ ] Directory layout reflects reality (`ls` and compare)
- [ ] Commands listed actually work (`make test` runs, etc.)
- [ ] No duplicate content from `.claude/rules/`

If all checks pass, ship it. CLAUDE.md is done.
