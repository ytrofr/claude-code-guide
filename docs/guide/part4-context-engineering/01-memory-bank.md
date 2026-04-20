---
layout: default
title: "Memory Bank and Hierarchy"
parent: "Part IV — Context Engineering"
nav_order: 1
redirect_from:
  - /docs/guide/12-memory-bank-hierarchy.html
  - /docs/guide/12-memory-bank-hierarchy/
  - /docs/guide/51-persistent-memory-patterns.html
  - /docs/guide/51-persistent-memory-patterns/
---

# Memory Bank and Hierarchy

**Current as of**: Claude Code 2.1.111+.

Claude Code reads your `CLAUDE.md` and any `@`-imported files at the start of every conversation. As projects grow, you accumulate patterns, decisions, fixes, and reference docs. Without organization, you either load everything (wasting context window) or load nothing (losing knowledge).

The memory bank is a 4-tier hierarchy that solves this: always-loaded essentials at the top, rarely-needed archives at the bottom. Each tier has a clear purpose and loading strategy. On top of the hierarchy, Claude Code's auto-memory (`~/.claude/projects/<project>/memory/`) captures persistent cross-session notes, and hook-driven patterns make knowledge capture automatic.

---

## The 4-Tier Structure

| Tier               | Directory                 | Auto-Load             | Purpose                            |
| ------------------ | ------------------------- | --------------------- | ---------------------------------- |
| **1. always/**     | `memory-bank/always/`     | Yes (via `@` imports) | Core patterns needed every session |
| **2. learned/**    | `memory-bank/learned/`    | No (search on demand) | Solved problems, reusable patterns |
| **3. ondemand/**   | `memory-bank/ondemand/`   | No (load when needed) | Domain-specific reference docs     |
| **4. blueprints/** | `memory-bank/blueprints/` | No (rare use)         | Full system recreation guides      |

### Tier 1: Always (auto-loaded)

These files are `@`-imported from your `CLAUDE.md` and load into every conversation automatically.

**What belongs here**:

- Core patterns and rules (single source of truth)
- System status (current state of the project)
- Context routing rules (how to find other information)
- Session protocol (start/end procedures)

**Example**:

```
memory-bank/always/
├── CORE-PATTERNS.md          # Single source of truth for all patterns
├── CONTEXT-ROUTER-MINI.md    # How to find information across tiers
├── system-status.json        # Current feature status, recent fixes
└── SESSION-PROTOCOL-MINI.md  # Session start/end commands
```

Keep Tier 1 files compact. Use MINI versions (summaries) instead of full documents. Every token here is loaded in every conversation.

**`@` import syntax** (in `CLAUDE.md`):

```markdown
@memory-bank/always/CORE-PATTERNS.md
@memory-bank/always/system-status.json
```

### Tier 2: Learned (on-demand lookup)

Entries that document solved problems, discovered patterns, and implementation decisions. Not auto-loaded, but searchable when needed.

**What belongs here**:

- Bug fix documentation (what broke, why, how it was fixed)
- Implementation patterns (approaches that worked)
- Investigation results (data analysis, root cause findings)
- Decision records (why a particular approach was chosen)

**Naming convention**: `entry-NNN-descriptive-name.md`

```
memory-bank/learned/
├── entry-179-hooks-implementation.md
├── entry-296-migration-plan.md
├── entry-314-cost-crisis.md
└── TIER-2-REGISTRY-BY-DOMAIN.md      # Index for finding entries
```

Claude searches these files with Grep or reads specific entries when a topic comes up. A registry file helps navigate by domain.

### Tier 3: Ondemand (domain-specific reference)

Comprehensive reference documentation organized by domain. Loaded only when working in that specific area.

```
memory-bank/ondemand/
├── api/              # API endpoint details, auth patterns
├── database/         # Full schema, sync patterns
├── deployment/       # CI/CD procedures, Cloud Run guides
└── skills-dev/       # Skill creation standards
```

**Loading strategy**: For large files, use `offset` + `limit` to read just the section you need:

```
Read(file="api-authority.md", offset=30, limit=214)
```

### Tier 4: Blueprints (system recreation)

Complete guides for recreating major systems from scratch. Only needed when rebuilding or deeply understanding architecture.

```
memory-bank/blueprints/
├── system/
│   └── COMPLETE-SYSTEM-BLUEPRINT.md
└── context/
    └── CONTEXT-SYSTEM-BLUEPRINT.md
```

---

## Setting Up a Memory Bank

**Step 1 — Create the directory structure**:

```bash
mkdir -p memory-bank/{always,learned,ondemand,blueprints}
```

**Step 2 — Create your core patterns file**:

```markdown
# CORE-PATTERNS.md — Single Source of Truth

## Project Patterns

- Port: 8080
- Database: PostgreSQL
- API style: REST with snake_case

## Key Rules

- Always validate input before database operations
- Use environment variables for all credentials
- Test locally before deploying
```

**Step 3 — Create a system status file**:

```json
{
  "last_updated": "2026-04-20",
  "current_sprint": "Feature X implementation",
  "system_health": {
    "production": { "status": "operational" },
    "staging": { "status": "operational" }
  },
  "recent_fixes": []
}
```

**Step 4 — Add `@` imports to `CLAUDE.md`**:

```markdown
## Auto-loaded Context

@memory-bank/always/CORE-PATTERNS.md
@memory-bank/always/system-status.json
```

---

## Best Practices

**Single source of truth**. Define each pattern in exactly one place (usually `CORE-PATTERNS.md`). Other files should reference it, not duplicate it. Duplication leads to contradictions when one copy is updated but not the other.

**Progressive disclosure**. Start with MINI summaries in Tier 1. When Claude needs more detail, it reads the full file from Tier 2 or 3. This keeps the always-loaded context small while making deep knowledge accessible. See [Progressive Disclosure](05-progressive-disclosure.html).

**Stable entry numbers**. Use `entry-179`, `entry-296` so references remain valid when file names change. Keep a registry that maps entry numbers to topics and file paths.

**Avoid loading everything**. Resist the urge to `@`-import every documentation file. More context does not mean better results — Anthropic's guidance is that quality improves when you load less but more relevant context.

---

## Persistent Memory — Claude Code's Auto-Memory

In addition to the project-owned memory bank, Claude Code writes persistent per-project notes to `~/.claude/projects/<project>/memory/MEMORY.md`. This auto-memory survives sessions, compactions, and branch switches, and loads automatically at session start.

### Size limits you must respect

The auto-loaded `MEMORY.md` has a hard cap enforced at session start:

- **200 lines** or **25 KB**, whichever comes first
- Content beyond the cap is **silently dropped** — you get no warning
- The cap applies to `MEMORY.md` only; `CLAUDE.md` files load in full

### Topic files — the overflow pattern

When `MEMORY.md` approaches the limit, move detail to topic files in the same directory:

```
~/.claude/projects/<project>/memory/
├── MEMORY.md          ← Index (loaded at startup, under 200 lines)
├── infrastructure.md  ← Detail (loaded on demand)
├── decisions.md       ← Detail (loaded on demand)
└── patterns.md        ← Detail (loaded on demand)
```

Topic files are NOT loaded at startup. Claude reads them on demand when their content is relevant. The index stays auto-loaded; detail is a file read away.

### Categories used by `/document` and auto-memory

When generated by tooling (`/document`, `memory-defrag`, etc.), entries tend to cluster into four categories. Keeping this taxonomy explicit in `MEMORY.md` makes retrieval predictable:

| Prefix            | Purpose                                                       |
| ----------------- | ------------------------------------------------------------- |
| `feedback_*.md`   | Lessons learned about CC behavior, tools, conventions         |
| `project_*.md`    | In-flight project state (cleanup, migrations, audits)         |
| `reference_*.md`  | Static reference data (locations, schemas, registries)        |
| `user_*.md`       | User-specific preferences and patterns                        |

### Compression strategies

When `MEMORY.md` exceeds the cap:

1. **Archive to Basic Memory**. Move historical sections (completed audits, past sprints, infrastructure state) to Basic Memory notes with proper observation taxonomy.
2. **Replace with pointers**. Each archived section becomes a 1-line summary pointing to the Basic Memory note or topic file.
3. **Keep only active context**. Feedback links, in-progress work, frequently-referenced state stay in `MEMORY.md`.
4. **Target 60-70 % of cap**. Leave room for future entries (~120-140 lines).

A section of 70+ lines of infrastructure detail collapses to two pointer lines — one to a topic file, one to a Basic Memory note — and the cap reclaims ~95% of the space.

### Subagent memory

Subagents with the `memory` frontmatter field get their own `MEMORY.md`:

| Scope     | Location                              |
| --------- | ------------------------------------- |
| `user`    | `~/.claude/agent-memory/<name>/`      |
| `project` | `.claude/agent-memory/<name>/`        |
| `local`   | `.claude/agent-memory-local/<name>/`  |

The same 200-line / 25 KB cap applies. Use the same topic file pattern if the subagent's memory grows large.

---

## Automatic Capture via Hooks

Manual note-taking skips under time pressure. The hook system can automate capture so every session contributes to the knowledge base, without a worker service or per-call AI processing.

### Auto-observation (`PostToolUse`)

Capture only meaningful actions — `Edit`, `Write`, `NotebookEdit`, and significant `Bash` commands — to a JSONL log keyed by `session_id`. Skip `Read`, `Glob`, `Grep`, etc.

`~/.claude/hooks/auto-observation.sh` (abridged):

```bash
#!/bin/bash
JSON_INPUT=$(cat 2>/dev/null || echo '{}')
TOOL_NAME=$(echo "$JSON_INPUT" | jq -r '.tool_name // empty')
SESSION_ID=$(echo "$JSON_INPUT" | jq -r '.session_id // empty')

OBS_DIR="$HOME/.claude/session-observations"; mkdir -p "$OBS_DIR"
OBS_FILE="$OBS_DIR/${SESSION_ID:-unknown}.jsonl"
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

case "$TOOL_NAME" in
  Edit|Write|NotebookEdit)
    CTX=$(echo "$JSON_INPUT" | jq -c '{file: (.tool_input.file_path // .tool_input.notebook_path // "unknown")}')
    TYPE=file_change ;;
  Bash)
    CMD=$(echo "$JSON_INPUT" | jq -r '.tool_input.command // empty')
    case "$CMD" in
      *"git commit"*|*"git push"*|*"gcloud run deploy"*|*"npm test"*|*"npm run"*)
        CTX=$(echo "$JSON_INPUT" | jq -c '{cmd: .tool_input.command}'); TYPE=command ;;
      *) exit 0 ;;
    esac ;;
  *) exit 0 ;;
esac

echo "{\"ts\":\"$TS\",\"type\":\"$TYPE\",\"tool\":\"$TOOL_NAME\",\"ctx\":${CTX:-\{\}}}" >> "$OBS_FILE"
```

Register in `~/.claude/settings.json` under `hooks.PostToolUse` with `matcher: "Write|Edit|Bash"` and `async: true`. `async: true` runs the hook in the background so it never blocks Claude.

### Auto session summary (`SessionEnd`)

At session end, combine the JSONL log with git history (`git log --oneline --since="2 hours ago"`, `git log --name-only`, `git diff --stat HEAD~3`) and write a structured note to Basic Memory. The summary note carries a `[change]` observation and `[[wiki-links]]` to project and branch, making the session discoverable from the knowledge graph. Register the handler on the `SessionEnd` event; with both hooks in place, every session writes a summary with zero manual effort.

### Why not a worker service?

Popular alternatives run a worker process that AI-compresses every tool event. The hook approach trades AI compression for zero infrastructure — no daemon, no vector DB, no per-call AI cost. For most projects, this delivers the majority of the value at a fraction of the complexity.

---

## Observation Taxonomy (for Persisted Notes)

When hooks or `/document` write to Basic Memory, inconsistent tagging makes retrieval unreliable. Standardize with six types and five concept tags.

### 6 observation types

| Tag           | Meaning                                    |
| ------------- | ------------------------------------------ |
| `[bugfix]`    | Something was broken, now fixed            |
| `[feature]`   | New capability or functionality added      |
| `[refactor]`  | Code restructured, behavior unchanged      |
| `[change]`    | Generic modification (docs, config, misc)  |
| `[discovery]` | Learning about existing system             |
| `[decision]`  | Architectural/design choice with rationale |

### 5 concept tags

| Tag                 | Meaning                         |
| ------------------- | ------------------------------- |
| `#how-it-works`     | Understanding mechanisms        |
| `#problem-solution` | Issues and their fixes          |
| `#gotcha`           | Traps or edge cases to remember |
| `#pattern`          | Reusable approach               |
| `#trade-off`        | Pros/cons of a decision         |

### Format

```
- [type] Description of what happened #concept #domain
```

Examples:

```
- [bugfix] Fixed timezone offset in cron job #problem-solution #deployment
- [decision] Use Cloud Scheduler not in-process crons #trade-off #deployment
- [discovery] Basic Memory search() returns IDs only — large savings #how-it-works #context
```

See [Basic Memory MCP](03-basic-memory-mcp.html) for the full write/read schema and the progressive-disclosure retrieval pattern.

---

## Global vs Project Scope for Hooks

All capture hooks should live in `~/.claude/` (global), not `.claude/` (project-specific):

```
~/.claude/hooks/auto-observation.sh           ← works for ANY project
~/.claude/hooks/auto-session-summary.sh       ← works for ANY project with git
~/.claude/rules/mcp/memory-search-patterns.md ← applies to all sessions
~/.claude/settings.json                       ← registers global hooks
```

If observation hooks exist at both the global and project level, they run twice, producing duplicate JSONL entries and double-writing session summaries. Keep capture hooks global.

---

## End-to-End Verification

After installing the hooks and memory bank, sanity-check:

```bash
# Hook syntax
bash -n ~/.claude/hooks/auto-observation.sh && echo OK
bash -n ~/.claude/hooks/auto-session-summary.sh && echo OK

# Settings JSON valid
jq '.' ~/.claude/settings.json > /dev/null && echo OK

# Hooks registered
jq '.hooks.PostToolUse[] | select(.hooks[].command | contains("auto-observation"))' \
  ~/.claude/settings.json | grep -q auto-observation && echo OK

# No duplicates at project level
grep -q "auto-observation" .claude/settings.json 2>/dev/null \
  && echo "FAIL — remove project duplicate" \
  || echo OK
```

---

## Related Chapters

- [Rules System and Path-Scoped Rules](02-rules-system.html)
- [Basic Memory MCP — Semantic Knowledge Graph](03-basic-memory-mcp.html)
- [Progressive Disclosure](05-progressive-disclosure.html)
