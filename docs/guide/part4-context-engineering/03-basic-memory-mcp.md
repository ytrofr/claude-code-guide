---
layout: default
title: "Basic Memory MCP — Semantic Knowledge Graph"
parent: "Part IV — Context Engineering"
nav_order: 3
redirect_from:
  - /docs/guide/34-basic-memory-mcp-integration.html
  - /docs/guide/34-basic-memory-mcp-integration/
---

# Basic Memory MCP — Semantic Knowledge Graph

**Current as of**: Claude Code 2.1.111+, Basic Memory v0.20.2+.
**Official docs**: [basic-memory.dev](https://basic-memory.dev), [MCP transport reference](https://modelcontextprotocol.io/)

---

## Why Basic Memory

Claude Code sessions forget. `--resume` restores a single thread; compaction loses detail; a new session starts cold. Basic Memory MCP provides **persistent, semantic, cross-session knowledge** stored as plain Markdown files with a graph database overlay.

Five capabilities define the value:

1. **Semantic observations** — typed observations (`[decision]`, `[bugfix]`, `[technique]`) with concept tags (`#how-it-works`, `#gotcha`)
2. **Wiki-links** — `[[Note Title]]` connects nodes into a knowledge graph
3. **Hybrid search** — text + semantic combined by default (v0.20.2)
4. **Progressive disclosure** — `search()` → `search_notes()` → `fetch()` for token efficiency
5. **Metadata filters** — query by frontmatter (`status: ACTIVE`, `priority > 5`, dot-notation for nested fields)

Setup cost: ~2 hours. Return: a queryable knowledge base that replaces manual context-searching across sessions and projects.

---

## Installation (stdio transport — modern default)

Basic Memory v0.20.2+ ships as an MCP server using **stdio transport** (local process, not SSE). Register it in your Claude Code MCP config:

```bash
# Install the package
pip install basic-memory

# Register the MCP server (stdio by default)
claude mcp add basic-memory -- basic-memory mcp

# Verify
claude mcp list | grep basic-memory
# Should show: basic-memory: stdio (running)
```

Stdio transport means:
- No port to configure, no daemon to run
- Each Claude Code session spawns its own `basic-memory mcp` child process
- Notes live on disk (default: `~/basic-memory/`) — any editor can read them

> **Why stdio, not SSE?** SSE made sense when every MCP server needed a shared endpoint. Stdio is simpler, faster, and survives session restarts cleanly. Claude Code 2.1.x treats stdio as the default for local tools.

---

## Note structure

Every Basic Memory note is a Markdown file with YAML frontmatter. The minimum structure:

```markdown
---
title: "Auth Bug Fix — Token Expiry"
type: note
tags: [bugfix, auth, session]
status: ACTIVE
---

# Auth Bug Fix — Token Expiry

## Observations

- [bugfix] JWT exp claim was in seconds, not ms — fix divided `Date.now()` by 1000 #gotcha #auth
- [technique] Add ISO 8601 timestamp assertion to integration test #pattern

## Relations

- relates_to [[Session Management Architecture]]
- supersedes [[Legacy Token Refresh Flow]]
```

Three rules the search engine expects:

1. **Observations start with `- [type]`** — `[bugfix]`, `[feature]`, `[refactor]`, `[change]`, `[discovery]`, `[decision]`
2. **Concept tags start with `#`** — `#how-it-works`, `#problem-solution`, `#gotcha`, `#pattern`, `#trade-off`
3. **Wiki-links use double brackets** — `[[Note Title]]` creates a graph edge

Notes without at least one observation and one wiki-link become orphan nodes.

---

## Progressive disclosure — the core retrieval pattern

Never fetch full content without filtering first. Use three layers, each ~10x cheaper than the next:

| Layer | Tool | Returns | Cost | Use When |
|-------|------|---------|------|----------|
| 1. Index | `mcp__basic-memory__search(query)` | IDs + titles | ~50 tokens/result | Exploring; unsure which notes are relevant |
| 2. Preview | `mcp__basic-memory__search_notes(query, page_size=5)` | Truncated preview | ~200 tokens/result | Scan before committing to full read |
| 3. Full | `mcp__basic-memory__fetch(id="folder/note-title")` | Complete note | ~500-1000 tokens | Only after filtering — know which note |

> **Exception**: `mcp__basic-memory__build_context(url='memory://folder/*')` is fine for small folders (<10 notes). `mcp__basic-memory__read_note()` is fine when you know the exact title.

See [Chapter 05: Progressive Disclosure](./05-progressive-disclosure.html) for the pattern applied to skills, docs, and other layered retrieval.

---

## Hybrid search (default in v0.20.2)

`search_notes` supports four modes. `hybrid` is the default and the right choice for nearly all queries.

| `search_type` | What it does | When |
|---|---|---|
| `hybrid` (default) | Text FTS + semantic embeddings combined | General-purpose — start here |
| `text` | Keyword/FTS only | Fast, exact keyword matching |
| `semantic` | Embedding similarity only | "Find related concepts" without shared vocabulary |
| `title` / `permalink` | Field-only search | Targeted lookups |

```python
# Default — hybrid, returns top matches across text + semantic
results = mcp__basic_memory__search_notes(query="auth token refresh")

# Explicit override
results = mcp__basic_memory__search_notes(
    query="auth token refresh",
    search_type="semantic",
    min_similarity=0.6,  # Higher = stricter
)
```

### `min_similarity` tuning

Default is `0.45`. Adjust per query:

- `0.3` — broad/conceptual ("anything vaguely about auth")
- `0.45` — balanced (default)
- `0.7` — tight/exact (only clear matches)

---

## Metadata filters — structured frontmatter queries

v0.20.2 added typed metadata filters that query frontmatter fields directly. Operators: `$eq`, `$gt`, `$lt`, `$gte`, `$lte`, `$in`, `$between`. Dot notation works for nested fields.

```python
# Status filter
search_notes(
    query="auth",
    metadata_filters={"status": "ACTIVE"},
)

# Range filter — priority > 5
search_notes(
    query="",
    metadata_filters={"priority": {"$gt": 5}},
)

# Nested field via dot notation
search_notes(
    query="",
    metadata_filters={"author.team": "infra"},
)

# Combined
search_notes(
    query="deployment",
    metadata_filters={
        "status": {"$in": ["ACCEPTED", "ACTIVE"]},
        "confidence": {"$gte": 0.8},
    },
)
```

Convenience filters layered on top:

- `tags=["bugfix"]` — tag array filter
- `note_types=["decision"]` — note_type filter
- `after_date="2026-03-01"` — modified-after shortcut

---

## `edit_note` operations — prefer over rewriting

When updating an existing note, use `edit_note` with a targeted operation rather than rewriting the whole file with `write_note`. Preserves history cleanly and avoids accidental deletions.

| Operation | Use For |
|-----------|---------|
| `append` | Add to end of note |
| `prepend` | Add to top (under frontmatter) |
| `find_replace` | Exact text replacement (pair with `expected_replacements` count for safety) |
| `replace_section` | Swap content under a specific `## Heading` |
| `insert_before_section` | Inject content before a heading |
| `insert_after_section` | Inject content after a heading |

```python
# Append a new observation
mcp__basic_memory__edit_note(
    identifier="fixes/auth-bug-token-expiry",
    operation="append",
    content="\n- [discovery] Issue also affects refresh flow when exp is ms vs s #gotcha",
)

# Replace a section with an updated architecture diagram
mcp__basic_memory__edit_note(
    identifier="decisions/session-architecture",
    operation="replace_section",
    section="## Current Flow",
    content="## Current Flow\n\n[updated diagram]",
)

# Safe find/replace — fails loud if expected_replacements doesn't match
mcp__basic_memory__edit_note(
    identifier="patterns/retry-logic",
    operation="find_replace",
    find="MAX_RETRIES = 3",
    replace="MAX_RETRIES = 5",
    expected_replacements=1,
)
```

---

## ADR status lifecycle

Architecture Decision Records (ADRs) live in Basic Memory with a status lifecycle encoded in frontmatter:

```yaml
---
title: "Decision: Use Postgres not DynamoDB for User Store"
status: ACTIVE
superseded_by: null
---
```

### States

`PROPOSED → ACCEPTED → ACTIVE → DEPRECATED → SUPERSEDED`

| Status | Meaning |
|--------|---------|
| `PROPOSED` | Under discussion; may change |
| `ACCEPTED` | Decided; implementing |
| `ACTIVE` | In production; enforced |
| `DEPRECATED` | Replaced by newer pattern; keep for history |
| `SUPERSEDED` | Points to replacement (requires `superseded_by: note-title`) |

### Transitions

- After implementing a decision → `ACCEPTED` → `ACTIVE`
- After replacing a pattern → old = `DEPRECATED`, add `superseded_by`
- After confirming still valid → update `date-released`, keep `ACTIVE`

### Freshness SLAs

| Note Type | Max Age (no edits) | Action When Stale |
|-----------|--------------------|-------------------|
| `decision` | 90 days | Review: still valid? Update status or confirm |
| `investigation` | 60 days | Archive unless actively referenced |
| `log` | 30 days | Auto-archive (ephemeral by nature) |
| `research-cache` | 90 days | Re-search if technology has changed |

Query stale notes with a `before_date` filter to surface them.

---

## Folder organization

Folders group notes by purpose, not by project. The graph spans folders via wiki-links.

```
~/basic-memory/
├── fixes/              # Bug solutions, production incidents
├── patterns/           # Reusable implementation patterns
├── decisions/          # Architecture/design decisions (ADRs)
├── investigations/     # Root-cause analysis, debugging sessions
├── research-cache/     # Perplexity/web search results (cache before re-querying)
├── session-summaries/  # Context from past sessions
├── quick-reference/    # Fast lookups, cheat sheets
└── <project-folders>/  # Optional: project-specific notes (<PROJECT-A>/, <PROJECT-B>/)
```

### Consolidation rules

| If you have | Merge into |
|---|---|
| Multiple 1-file folders | Parent folder |
| `bugs/`, `troubleshooting/` | `fixes/` |
| `research/`, `external-docs/` | `research-cache/` |
| `plans/`, `planning/`, `roadmaps/` | `planning/` |
| Empty folders | Delete |

Target: <30 total folders for a mature memory.

---

## Memory-before-work rule

Before writing code for a non-trivial change, **always search memory first**. This prevents re-solving solved problems.

| Trigger | Query |
|---------|-------|
| Starting a feature | `search_notes("feature-name", search_type="hybrid")` |
| Fixing a bug | `search_notes("error message")` |
| Architecture decision | `search_notes("component-name architecture")` |
| Touching unfamiliar code | `search_notes("module-name")` |
| Before any refactor | `search_notes("module refactor")` |

After the work:

| After | Write | Tags |
|-------|-------|------|
| Fixing a non-trivial bug | Root cause + fix | `[bugfix]` + `#problem-solution` |
| Making a design decision | Decision + rationale | `[decision]` + `#trade-off` |
| Discovering a gotcha | The trap + how to avoid | `[discovery]` + `#gotcha` |
| Completing a feature | Architecture overview | `[feature]` + `#how-it-works` |

---

## Recent activity

Quick entry point for "what have I been working on":

```python
mcp__basic_memory__recent_activity(timeframe="7d")
# Accepts: "today", "yesterday", "2 days ago", "last week", "3 months ago", "7d"
```

Useful at session start to surface active threads without explicit search.

---

## Write standards

Every note written to Basic Memory should include:

| Field | Required | Example |
|-------|----------|---------|
| `title` | yes | `"Auth Bug Fix — Token Expiry"` |
| `folder` | yes | `"fixes"` |
| `content` | yes | Markdown with observations |
| `tags` | yes | `["bugfix", "auth"]` |
| `note_type` | recommended | `"decision"`, `"investigation"`, `"log"`, `"note"` |

Minimum content invariants:

- At least one `- [type]` observation line
- At least one `[[wiki-link]]` (minimum: `- relates_to [[Project Name]]`)
- At least one `#concept` tag in observations

Notes missing these become orphan nodes — indexed but disconnected from the graph.

---

## Troubleshooting

### Search returns no results

```bash
# Check notes exist
find ~/basic-memory -name "*.md" | wc -l

# Check observations are formatted correctly
grep -rE "^- \[(bugfix|decision|technique)\]" ~/basic-memory/ | head

# Rebuild the index if notes were added outside the MCP interface
basic-memory sync
```

### MCP server won't start

```bash
# Check Claude Code sees it
claude mcp list

# Check the binary is on PATH
which basic-memory

# Reinstall if missing
pip install --upgrade basic-memory
```

### Hybrid search feels wrong

Default `min_similarity=0.45` is tuned for mixed vocabulary. Try `0.3` if getting too few results or `0.7` if getting too many irrelevant ones. Also confirm embeddings were built — v0.20.2 builds them on first `sync`.

---

## Further reading

- **[02 — Rules System](./02-rules-system.html)**: structured rules that complement semantic memory
- **[05 — Progressive Disclosure](./05-progressive-disclosure.html)**: the retrieval pattern applied to skills, docs, knowledge
- [Basic Memory docs](https://basic-memory.dev) — Official reference
- [MCP transport spec](https://modelcontextprotocol.io/) — stdio vs SSE
