# Chapter 26: Claude Code Rules System

**Official Documentation**: https://code.claude.com/docs/en/memory

## Overview

Claude Code automatically discovers `.md` files in `.claude/rules/` directories. Rules provide persistent instructions that load automatically based on context, enabling domain-specific guidance without cluttering your main CLAUDE.md file.

## Rule Hierarchy (Priority Order)

```
1. Enterprise rules: ~/.claude/enterprise/rules/  (organization-level)
2. User rules:       ~/.claude/rules/              (personal defaults)
3. Project rules:    .claude/rules/                (project-specific)
```

**Higher priority rules override lower ones.** This allows:

- Organizations to enforce standards
- Developers to set personal preferences
- Projects to define specific patterns

## Directory Structure

### Recommended Organization

```
.claude/rules/
├── INDEX.txt              # Index of all rules (.txt = not auto-loaded)
├── src-code.md            # Path-specific: src/**/*.js
├── tests.md               # Path-specific: tests/**/*
├── sacred/
│   └── commandments.md    # Core compliance rules
├── database/
│   └── patterns.md        # Database access patterns
├── api/
│   └── integrations.md    # External API standards
└── hebrew/
    └── preservation.md    # Cultural/i18n standards
```

### File Discovery

- Claude Code recursively searches `.claude/rules/`
- **Only `.md` files are loaded** — `.txt`, `.json`, etc. are ignored
- Subdirectories help organize by domain
- Use INDEX.txt (not README.md) for human navigation — see "Optimization Tips" below

## Path-Specific Rules

Use YAML frontmatter to target specific file paths:

```markdown
---
path_patterns:
  - "src/**/*.js"
  - "src/**/*.ts"
---

# Source Code Rules

## Modular Architecture

- Routes in src/routes/
- Controllers in src/controllers/
- Utilities in src/utils/

## Code Standards

- Use async/await (not callbacks)
- Prefer const over let
- Document public functions
```

This rule only loads when working with files matching the patterns.

### Production Path-Specific Rules Examples

Here are real examples from a production project with 13 rule files, where 5 use conditional loading and 8 remain unconditional:

**Conditional rules** (only load when editing matching files):

```yaml
# .claude/rules/sacred/commandments.md — Core code patterns
---
paths:
  - "src/**"
  - "index.js"
---
# .claude/rules/deployment/patterns.md — Deploy safety
---
paths:
  - "Dockerfile"
  - "*.yml"
  - "scripts/deploy*"
  - "start-limor.sh"
---
# .claude/rules/hebrew/preservation.md — UI/prompt encoding
---
paths:
  - "public/**"
  - "src/prompts/**"
---
# .claude/rules/database/patterns.md — Database operations
---
paths:
  - "src/database/**"
  - "src/sync/**"
  - "scripts/*sync*"
  - "scripts/*gap*"
---
# .claude/rules/api/integrations.md — API patterns
---
paths:
  - "src/routes/**"
  - "src/controllers/**"
  - "src/services/**"
---
```

**Unconditional rules** (always relevant, no `paths:` needed):

- `src-code.md` — App structure reference (needed for all code work)
- `process/git-safety.md` — Git push/commit rules (always applies)
- `process/branch-files.md` — Naming conventions (always applies)
- `infrastructure/docker-setup.md` — Container safety (always applies)
- `mcp/memory-usage.md` — Memory patterns (always applies)

**Decision guide**: Use `paths:` when the rule is domain-specific. Keep unconditional when the rule applies regardless of which file is being edited.

## Rule File Templates

### Domain Rule Template

````markdown
# [Domain] Rules - [Project Name]

**Authority**: [What this rule governs]
**Source**: [Reference documentation]

---

## Core Patterns

```yaml
Pattern_Name:
  Rule: "Description of the rule"
  Example: "Code or usage example"
  Violation: "What NOT to do"
```
````

---

## Quick Reference

| Pattern   | Usage       |
| --------- | ----------- |
| Pattern 1 | When to use |
| Pattern 2 | When to use |

---

**Skills Reference**: [Related skills]

````

### Path-Specific Rule Template

```markdown
---
path_patterns:
  - "path/to/files/**/*"
---

# Rules for [Path]

## Standards
- Standard 1
- Standard 2

## Patterns
- Pattern 1
- Pattern 2
````

## Best Practices

### 1. Keep Rules Focused

**DO**: One domain per file

```
.claude/rules/
├── database/patterns.md     # Database only
├── api/integrations.md      # API only
└── testing/standards.md     # Testing only
```

**DON'T**: Mix domains

```
.claude/rules/
└── everything.md            # Database + API + Testing (too broad)
```

### 2. Reference, Don't Duplicate

**DO**: Point to authoritative sources

```markdown
# Database Rules

**Full Reference**: See `CORE-PATTERNS.md` (authoritative source)

## Quick Summary

- Golden Rule: Always use `employee_id`
- Safety: `SELECT current_database()` before operations
```

**DON'T**: Copy entire documents

```markdown
# Database Rules

[400 lines copied from CORE-PATTERNS.md] # Causes duplication!
```

### 3. Use INDEX.txt (Not README.md)

**Important**: Since Claude Code auto-loads all `.md` files in `.claude/rules/`, a `README.md` index file wastes context tokens on human navigation content. Rename it to `INDEX.txt` — Claude Code ignores non-`.md` files, but humans can still read it.

```bash
# Save ~700 tokens per session
mv .claude/rules/README.md .claude/rules/INDEX.txt
```

Include an INDEX.txt for quick navigation:

```markdown
# Project Rules Index

| Rule File                | Domain   | Key Patterns           |
| ------------------------ | -------- | ---------------------- |
| `sacred/commandments.md` | Core     | 14 Sacred Commandments |
| `database/patterns.md`   | Database | Golden Rule, SQL       |
| `api/integrations.md`    | External | OAuth2, endpoints      |

**Last Updated**: YYYY-MM-DD
```

### 4. Version Your Rules

Track rule changes in your index:

```markdown
## Changelog

### 2026-01-06

- Added: hebrew/preservation.md
- Updated: database/patterns.md (Cloud SQL credentials)

### 2025-12-15

- Initial rules structure created
```

## Rules vs CLAUDE.md

| Aspect        | CLAUDE.md                 | .claude/rules/           |
| ------------- | ------------------------- | ------------------------ |
| Loading       | Always loaded             | Auto-discovered          |
| Path-specific | No                        | Yes (YAML frontmatter)   |
| Organization  | Single file               | Directory structure      |
| Best for      | Core project instructions | Domain-specific patterns |
| Size limit    | Keep concise              | Can be detailed          |

### When to Use Each

**Use CLAUDE.md for**:

- Project overview and mission
- Critical deployment rules
- Session protocols
- MCP/plugin configuration
- Auto-load file references (@file)

**Use .claude/rules/ for**:

- Domain-specific patterns (database, API, testing)
- Path-specific rules (src/, tests/)
- Detailed compliance standards
- Reference material

## Context Optimization

### Problem: Context Bloat

Rules that duplicate content waste context tokens:

- Same Sacred Commandments in 3 files
- API patterns repeated everywhere
- 75%+ context utilization degrades quality

### Solution: Cross-Reference Pattern

```yaml
CROSS_REFERENCE_RULE:
  Primary_Source: CORE-PATTERNS.md (authoritative)
  Rules_Summary: .claude/rules/ (navigation)
  CLAUDE.md: Brief reference only (never duplicate)
```

### Implementation

**In CLAUDE.md**:

```markdown
## Sacred Compliance

→ See `.claude/rules/sacred/commandments.md` for details
→ Full reference: `CORE-PATTERNS.md`
```

**In rules/sacred/commandments.md**:

```markdown
# Sacred Commandments Summary

**Full Reference**: CORE-PATTERNS.md (authoritative source)

| #   | Rule        | Quick Check            |
| --- | ----------- | ---------------------- |
| I   | Golden Rule | `employee_id` not `id` |
| II  | Real Data   | No hardcoding          |

...
```

## Optimization Tips

### 1. Rename Non-Rule Files to .txt

Claude Code only auto-loads `.md` files. Any file that exists for human reference (indexes, changelogs, READMEs) should use `.txt` extension:

```bash
mv .claude/rules/README.md .claude/rules/INDEX.txt      # ~700 tokens saved
mv .claude/rules/CHANGELOG.md .claude/rules/CHANGELOG.txt  # if applicable
```

### 2. Trim Evidence from Rules

Rules should contain the **rule itself**, not the history of why it was created. Move evidence, dated lessons, and bug narratives to `memory-bank/learned/`:

```markdown
# Before (bloated - 2,900 tokens)

## Sacred Commandment I

Rule: Use employee_id
Evidence: Dec 22, 2025 - Found bug where...
Lesson: The 0-employees bug occurred when...
Sprint-C: 4-hour debugging session led to...

# After (focused - 1,800 tokens)

## Sacred Commandment I

Rule: Use employee_id (NEVER just id)
Validation: grep -r 'record\.employee\.id' src/
```

### 3. Deduplicate Across Files

If the same rule appears in both `.claude/rules/database/patterns.md` and `CORE-PATTERNS.md`, keep the full version in one place and reference from the other:

```markdown
# In database/patterns.md (condensed)

## Golden Rule (Sacred I)

→ See sacred/commandments.md for full rule
Quick check: always use employee_id, never id
```

### 4. Measure Your Token Budget

```bash
# Count tokens across all auto-loaded rules
total=0
for f in $(find .claude/rules -name "*.md" -type f); do
  chars=$(wc -c < "$f")
  tokens=$((chars / 4))
  total=$((total + tokens))
  echo "$tokens tokens | $f"
done | sort -rn
echo "TOTAL: $total tokens"
```

**Target**: Keep total rules under 15k tokens. Over 20k likely contains duplicated content.

## Global vs Project Rule Deduplication

### The Problem: Double-Loading

Claude Code loads rules from both `~/.claude/rules/` (global) and `.claude/rules/` (project). If the same rule file exists in both locations, it's loaded **twice** -- wasting context tokens on identical content.

This commonly happens when you start with project rules and later promote them to global rules, forgetting to delete the project copies.

### How to Detect Duplicates

```bash
# Compare global and project rules
for f in $(find .claude/rules -name "*.md" -type f); do
  rel="${f#.claude/rules/}"
  global="$HOME/.claude/rules/$rel"
  if [ -f "$global" ]; then
    if diff -q "$f" "$global" > /dev/null 2>&1; then
      echo "DUPLICATE (identical): $rel"
    else
      echo "DIVERGED (different): $rel"
    fi
  fi
done
```

### Resolution Strategy

| Scenario          | Rule Type                             | Action                                   |
| ----------------- | ------------------------------------- | ---------------------------------------- |
| Identical in both | Universal (agents, planning, quality) | Delete from project, keep global         |
| Identical in both | Project-specific (database, API)      | Delete from global, keep project         |
| Diverged          | Global has generic content            | Keep global; delete project if redundant |
| Diverged          | Project has domain additions          | Keep both (different purposes)           |

### Production Evidence

A production project with 26 rule files discovered 15 were identical duplicates:

- **Before**: 26 project rules + 15 global rules = 41 files loaded (15 duplicated)
- **After**: 11 project rules + 15 global rules = 26 files loaded (0 duplicated)
- **Savings**: ~1,139 lines of redundant context per session

### Best Practice: Rule Placement

| Rule Purpose                                   | Location                      | Why                           |
| ---------------------------------------------- | ----------------------------- | ----------------------------- |
| Universal workflow (agents, quality, safety)   | `~/.claude/rules/` only       | Applies to all projects       |
| Project-specific (domain patterns, compliance) | `.claude/rules/` only         | Only relevant to this project |
| Organization-wide standards                    | `~/.claude/enterprise/rules/` | Enforced by organization      |

**Never duplicate a rule across locations.** Use `INDEX.txt` (not `.md`) in each location to document what lives where.

## Example: Complete Rules Setup

See the `template/.claude/rules/` directory for a complete working example.

## Validation Commands

```bash
# List all rule files
find .claude/rules -name "*.md" -type f

# Check rule file count
find .claude/rules -name "*.md" | wc -l

# Search for specific pattern
grep -r "Golden Rule" .claude/rules/

# Verify no duplication with CLAUDE.md
grep -c "Sacred Commandment" CLAUDE.md  # Should be < 3
```

## Related Resources

- [Official Memory Documentation](https://code.claude.com/docs/en/memory)
- Chapter 12: Memory Bank Hierarchy
- Chapter 25: Best Practices Reference
- Entry #245: Implementation example (15 rule files)
- Entry #247: Context optimization patterns
