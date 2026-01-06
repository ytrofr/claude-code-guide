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
├── README.md              # Index of all rules (quick reference)
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
- All `.md` files are loaded automatically
- Subdirectories help organize by domain
- README.md provides quick navigation

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

## Rule File Templates

### Domain Rule Template

```markdown
# [Domain] Rules - [Project Name]

**Authority**: [What this rule governs]
**Source**: [Reference documentation]

---

## Core Patterns

```yaml
Pattern_Name:
  Rule: 'Description of the rule'
  Example: 'Code or usage example'
  Violation: 'What NOT to do'
```

---

## Quick Reference

| Pattern | Usage |
|---------|-------|
| Pattern 1 | When to use |
| Pattern 2 | When to use |

---

**Skills Reference**: [Related skills]
```

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
```

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

[400 lines copied from CORE-PATTERNS.md]  # Causes duplication!
```

### 3. Add Index README

Always include a README.md for quick navigation:

```markdown
# Project Rules Index

| Rule File | Domain | Key Patterns |
|-----------|--------|---------------|
| `sacred/commandments.md` | Core | 14 Sacred Commandments |
| `database/patterns.md` | Database | Golden Rule, SQL |
| `api/integrations.md` | External | OAuth2, endpoints |

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

| Aspect | CLAUDE.md | .claude/rules/ |
|--------|-----------|----------------|
| Loading | Always loaded | Auto-discovered |
| Path-specific | No | Yes (YAML frontmatter) |
| Organization | Single file | Directory structure |
| Best for | Core project instructions | Domain-specific patterns |
| Size limit | Keep concise | Can be detailed |

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

| # | Rule | Quick Check |
|---|------|-------------|
| I | Golden Rule | `employee_id` not `id` |
| II | Real Data | No hardcoding |
...
```

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
