# Chapter 12: Memory Bank Hierarchy

**Purpose**: 4-tier knowledge organization for optimal context
**Source**: LIMOR AI (34% token reduction, zero functionality loss)
**Pattern**: always → learned → ondemand → blueprints

---

## 4-Tier Structure

| Tier | Auto-Load | Size | Use For |
|------|-----------|------|---------|
| **1. always/** | ✅ Yes | <40k | Core patterns, always needed |
| **2. learned/** | ❌ No | Varies | Solved problems (Entries) |
| **3. ondemand/** | ❌ No | Large | Reference docs |
| **4. blueprints/** | ❌ No | Largest | System recreation |

---

## Example Structure

```
memory-bank/
├── always/
│   ├── CORE-PATTERNS.md          # Single source of truth
│   └── system-status.json        # Feature tracking
├── learned/
│   └── entry-179-hooks.md        # Reusable patterns
├── ondemand/
│   └── COMPLETE-GLOSSARY.md      # Large references
└── blueprints/
    └── SYSTEM-BLUEPRINT.md        # Recreation guides
```

---

## Key Patterns

**CORE-PATTERNS as single source** - All other files reference it (avoid duplication)

**Entry numbering** - Stable cross-references (entry-NNN-name.md)

**File size limits** - Tier 1: <40k, Tier 2: <25k

**Full guide**: See LIMOR AI CONTEXT-ROUTER.md

---

## Multi-Branch Projects 🆕

For projects with multiple branches (dev-Data, dev-UI, etc.):

→ **See [Chapter 29: Branch Context System](29-branch-context-system.md)** for:
- CONTEXT-MANIFEST.json per branch
- @ import enforcement
- 47-70% token savings per branch

---

**Previous**: [11: Session Documentation](11-session-documentation.md)
**Next**: [13: Claude Code Hooks](13-claude-code-hooks.md)
