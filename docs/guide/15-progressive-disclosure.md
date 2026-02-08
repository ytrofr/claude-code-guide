# Chapter 15: Progressive Disclosure for Skills

**Purpose**: Split large skills for token efficiency
**Source**: Anthropic blog "Building Skills for Claude Code"
**Evidence**: Production 53% token savings (4k vs 8.5k), 24/25 tests (96%)

---

## The Pattern

**Structure**:
```
skill-name/
├── SKILL.md (2-3k) - Workflow
└── references/
    ├── category-a.md (2k) - Details
    ├── category-b.md (2k) - Details
    └── category-c.md (2k) - Details
```

**Result**: Load only needed reference (53% savings)

---

## Real Example

**api-endpoint-inventory-skill**:
- Before: 8.5k always loaded
- After: 2.5k + 1.5-2.6k (one reference) = 4-5k
- Savings: 47-53% per query

**Validation**: 3 questions → 3 different references loaded ✅

---

## When to Use

✅ **Use for**: Large skills (>5k), multiple categories, high frequency
❌ **Skip for**: Small skills (<5k), linear workflows

**Monitoring**: Track with skill-access-monitor.sh hook

---

**ROI**: 10-20 hours/year (if frequently used)

**Full guide**: Production Entry #179 with test validation

---

**Previous**: [14: Git vs Claude Hooks](14-git-vs-claude-hooks-distinction.md)
