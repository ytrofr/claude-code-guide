# Project Rules Index

**Location**: `.claude/rules/`
**Purpose**: Project-specific rules auto-discovered by Claude Code
**Reference**: https://code.claude.com/docs/en/memory

---

## Directory Structure

```
.claude/rules/
├── README.md           # This index file
├── src-code.md         # Path-specific: src/**/*
├── tests.md            # Path-specific: tests/**/*
└── domain/
    └── patterns.md     # Domain-specific patterns
```

---

## Quick Reference

| Rule File | Domain | Key Patterns |
|-----------|--------|---------------|
| `src-code.md` | Source Code | Modular architecture, code standards |
| `tests.md` | Testing | Coverage targets, test patterns |
| `domain/patterns.md` | Domain | Project-specific business rules |

---

## How Rules Work

1. **Auto-discovered**: Claude Code finds `.claude/rules/*.md` automatically
2. **Recursive**: Subdirectories are searched
3. **Priority**: Project rules override user rules (`~/.claude/rules/`)
4. **Path-specific**: YAML frontmatter targets specific file paths

---

## Adding New Rules

1. Create `.md` file in appropriate location
2. Add YAML frontmatter for path-specific rules (optional)
3. Update this README index
4. Keep rules focused (one domain per file)

---

## Related

- **CLAUDE.md**: Core project instructions
- **User Rules**: `~/.claude/rules/` (personal defaults)
- **Official Docs**: https://code.claude.com/docs/en/memory

---

**Last Updated**: YYYY-MM-DD (update when adding rules)
