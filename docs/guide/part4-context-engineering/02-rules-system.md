---
layout: default
title: "Rules System and Path-Scoped Rules"
parent: "Part IV — Context Engineering"
nav_order: 2
redirect_from:
  - /docs/guide/26-claude-code-rules-system.html
  - /docs/guide/26-claude-code-rules-system/
---

# Rules System and Path-Scoped Rules

**Current as of**: Claude Code 2.1.111+.
**Official docs**: [Memory reference](https://code.claude.com/docs/en/memory)

Claude Code automatically discovers `.md` files in `.claude/rules/` directories. Rules provide persistent instructions that load based on scope and path, giving you domain-specific guidance without cluttering `CLAUDE.md`.

---

## Rule Hierarchy (priority order)

```
1. Enterprise rules : ~/.claude/enterprise/rules/   (organization-level)
2. User rules       : ~/.claude/rules/              (personal defaults)
3. Project rules    : .claude/rules/                (project-specific)
```

Higher priority rules override lower ones. This lets organizations enforce standards, developers set personal preferences, and projects define local patterns.

---

## Directory Structure

A recommended layout:

```
.claude/rules/
├── INDEX.txt              # Human navigation (not auto-loaded)
├── src-code.md            # Path-specific: src/**/*.js
├── tests.md               # Path-specific: tests/**/*
├── global/
│   └── context-checking.md
├── database/
│   └── patterns.md
├── api/
│   └── integrations.md
└── quality/
    └── standards.md
```

### Discovery rules

- Claude Code recursively searches `.claude/rules/`.
- **Only `.md` files are loaded** — `.txt`, `.json`, etc. are ignored.
- Subdirectories organize by domain.
- Use `INDEX.txt` (not `README.md`) for human navigation — see [Optimization Tips](#optimization-tips).

---

## Path-Scoped Rules (`paths:` frontmatter)

You can scope a rule to specific file paths with YAML frontmatter. Such a rule loads only when the current task touches a matching path.

### The format — CSV, not a YAML array

**Important**: the `paths:` key uses a comma-separated string, quoted. YAML arrays are silently ignored due to a parser bug ([Claude Code issue #13905](https://github.com/anthropics/claude-code/issues/13905), also #17204).

```markdown
---
paths: "src/**/*.js, src/**/*.ts"
---

# Source Code Rules

- Routes in src/routes/
- Controllers in src/controllers/
- Utilities in src/utils/

Prefer `const` over `let`. Use async/await, not callbacks.
```

**Wrong** (silently ignored):

```markdown
---
paths:
  - "src/**/*.js"
  - "src/**/*.ts"
---
```

**Right** (works):

```markdown
---
paths: "src/**/*.js, src/**/*.ts"
---
```

When the user edits a matching file, Claude Code auto-loads the rule. When the task is unrelated, the rule stays dormant and costs nothing.

### Production examples

A project with 13 rule files might have 5 path-scoped and 8 always-on:

```yaml
# .claude/rules/deployment/patterns.md — deploy safety
paths: "Dockerfile, *.yml, scripts/deploy*"

# .claude/rules/database/patterns.md — database operations
paths: "src/database/**, src/sync/**, scripts/*sync*"

# .claude/rules/api/integrations.md — API patterns
paths: "src/routes/**, src/controllers/**, src/services/**"

# .claude/rules/i18n/preservation.md — localized UI/prompt encoding
paths: "public/**, src/prompts/**"
```

Always-on (no `paths:` key at all):

- `src-code.md` — app structure reference
- `process/git-safety.md` — git push/commit rules
- `process/branch-files.md` — naming conventions
- `infrastructure/docker-setup.md` — container safety
- `mcp/memory-usage.md` — memory patterns

**Decision guide**: use `paths:` when the rule is domain-specific (only relevant for certain files). Omit `paths:` when it applies regardless of which file is being edited.

---

## Rules vs. `CLAUDE.md`

| Aspect        | `CLAUDE.md`               | `.claude/rules/`         |
| ------------- | ------------------------- | ------------------------ |
| Loading       | Always loaded             | Auto-discovered          |
| Path-specific | No                        | Yes (via `paths:`)       |
| Organization  | Single file               | Directory structure      |
| Best for      | Core project instructions | Domain-specific patterns |
| Size budget   | Keep concise              | Can be more detailed     |

**Use `CLAUDE.md` for**: project overview, critical deployment rules, session protocols, MCP/plugin configuration, auto-load file references (`@file`).

**Use `.claude/rules/` for**: domain-specific patterns (database, API, testing), path-scoped rules, detailed compliance standards, reference material.

---

## Rule File Templates

### Domain rule

```markdown
# [Domain] Rules

**Authority**: [What this rule governs]
**Source**: [Reference documentation or entry link]

---

## Core Patterns

- Pattern_Name: description of the rule
  - Example: code or usage example
  - Violation: what NOT to do

## Quick Reference

| Pattern   | Usage       |
| --------- | ----------- |
| Pattern 1 | When to use |
| Pattern 2 | When to use |

---

**Related skills**: [Links]
```

### Path-scoped rule

```markdown
---
paths: "path/to/files/**/*"
---

# Rules for [Path]

## Standards
- Standard 1
- Standard 2

## Patterns
- Pattern 1
- Pattern 2
```

---

## Best Practices

### 1. Keep each rule focused

One domain per file:

```
.claude/rules/
├── database/patterns.md     # Database only
├── api/integrations.md      # API only
└── testing/standards.md     # Testing only
```

Avoid a single `everything.md` that mixes database + API + testing — it forces the whole file into every relevant context load.

### 2. Reference, don't duplicate

Point to an authoritative source instead of copying content:

```markdown
# Database Rules

**Full reference**: see `CORE-PATTERNS.md` (authoritative source).

## Quick summary
- Golden rule: always use `employee_id`
- Safety: `SELECT current_database()` before destructive operations
```

Duplicating content across rules leads to silent drift: one copy gets updated, the other goes stale.

### 3. Use `INDEX.txt`, not `README.md`

Claude Code auto-loads every `.md` in `.claude/rules/`. A `README.md` index wastes context on content humans read but Claude does not need. Use `.txt`:

```bash
mv .claude/rules/README.md .claude/rules/INDEX.txt
```

`INDEX.txt` is ignored by Claude Code but still human-readable.

### 4. Version your rules

Track rule evolution in `INDEX.txt`:

```markdown
## Changelog

### 2026-04-20
- Added: quality/source-validation.md
- Updated: database/patterns.md (migrated to pgvector)

### 2026-01-06
- Initial rules structure
```

---

## Context Optimization

### The context-bloat failure mode

Rules that duplicate content waste tokens and degrade output quality above ~75% context utilization. Common causes:

- The same core pattern defined in three files
- API patterns restated everywhere they are referenced
- Full evidence dumps (dated narratives, bug histories) stored inside rules

### Cross-reference pattern

- **Primary source**: `CORE-PATTERNS.md` (single authoritative document)
- **Rules summary**: `.claude/rules/` (navigation + domain-specific additions)
- **`CLAUDE.md`**: brief references only, never duplicate

### Trim evidence out of rules

Rules should contain the rule, not the history of why it was created. Move evidence, dated lessons, and bug narratives to `memory-bank/learned/` or Basic Memory:

**Before** (bloated):

```markdown
## Golden Rule

Rule: use employee_id
Evidence: Dec 22, 2025 — found bug where...
Lesson: the 0-employees bug occurred when...
Sprint-C: 4-hour debugging session led to...
```

**After** (focused):

```markdown
## Golden Rule

Rule: use `employee_id` (never `id`).
Validation: `grep -r 'record\.employee\.id' src/`
```

### Measure your rule budget

```bash
total=0
while IFS= read -r f; do
  chars=$(wc -c < "$f")
  tokens=$((chars / 4))
  total=$((total + tokens))
  printf '%6d tokens | %s\n' "$tokens" "$f"
done < <(find .claude/rules -name '*.md' -type f) | sort -rn
echo "TOTAL: $total tokens"
```

Target: under ~15 k tokens across all auto-loaded rules. Above 20 k the content usually contains duplication or stale evidence.

---

## Global vs. Project Deduplication

### The double-load trap

Claude Code loads rules from both `~/.claude/rules/` and `.claude/rules/`. If the same file exists in both, it loads twice. This happens most often when a project-level rule is promoted global but the project copy is not deleted.

### Detect duplicates

```bash
for f in $(find .claude/rules -name '*.md' -type f); do
  rel="${f#.claude/rules/}"
  global="$HOME/.claude/rules/$rel"
  [ -f "$global" ] || continue
  if diff -q "$f" "$global" > /dev/null 2>&1; then
    echo "DUPLICATE (identical): $rel"
  else
    echo "DIVERGED (different):  $rel"
  fi
done
```

### Resolution

| Situation                            | Rule nature                   | Action                                |
| ------------------------------------ | ----------------------------- | ------------------------------------- |
| Identical, universal                 | Agents, planning, quality     | Delete project copy, keep global      |
| Identical, project-specific          | Database, API, domain         | Delete global copy, keep project      |
| Diverged, global is generic          | Generic content globally      | Keep global; drop project if redundant |
| Diverged, project adds domain detail | Both serve different purposes | Keep both                             |

### Placement guide

| Rule purpose                              | Location                      |
| ----------------------------------------- | ----------------------------- |
| Universal workflow (agents, quality)      | `~/.claude/rules/` only       |
| Project-specific (domain patterns)        | `.claude/rules/` only         |
| Organization standards                    | `~/.claude/enterprise/rules/` |

**Never duplicate across locations**. Keep an `INDEX.txt` in each to document what lives where.

---

## Auto-Classification via `/document`

When you run `/document`, the pattern analysis engine scans all three levels (machine, project, branch) and classifies each discovered pattern:

```
Pattern discovered
  ├─ Applies to ANY project?               → MACHINE RULE  (~/.claude/rules/)
  ├─ Applies to ALL branches of THIS?      → PROJECT RULE  (.claude/rules/)
  ├─ Sprint/feature-specific?              → BRANCH RULE   (.claude/rules/branch/)
  └─ None                                   → Not a rule
```

`/document` then suggests NEW, UPDATE (with diff), or MOVE (if the rule exists at the wrong level).

| If the pattern…                | Level   |
| ------------------------------ | ------- |
| Universal NEVER/ALWAYS         | Machine |
| Tech-agnostic best practice    | Machine |
| Project tech-stack convention  | Project |
| Domain-specific to this project| Project |
| Temporary for this sprint      | Branch  |

See the [document automation](../25-best-practices-reference.html) coverage for the full rule-suggestion format.

---

## Validation Commands

```bash
# List all rule files
find .claude/rules -name '*.md' -type f

# Count rules
find .claude/rules -name '*.md' | wc -l

# Search for a pattern across rules
grep -r 'Golden Rule' .claude/rules/

# Confirm no duplication with CLAUDE.md
grep -c 'Golden Rule' CLAUDE.md   # Should be < 3
```

---

## Related Chapters

- [Memory Bank and Hierarchy](01-memory-bank.html)
- [Basic Memory MCP — Semantic Knowledge Graph](03-basic-memory-mcp.html)
- [Progressive Disclosure](05-progressive-disclosure.html)
