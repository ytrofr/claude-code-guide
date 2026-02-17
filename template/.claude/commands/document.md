---
description: "Document session work - Creates Entry files and analyzes patterns for skills/rules"
allowed_tools: ["Read", "Write", "Bash", "Grep", "Edit", "Glob"]
model: sonnet
---

# /document - Documentation + Pattern Analysis

**Purpose**: Document work + intelligent suggestions (Skill/Rule/Blueprint)
**Time**: ~10-15 minutes for complete documentation

---

## Step 1: Gather Session Context

```bash
echo "Branch: $(git branch --show-current)"
echo "Last 10 commits:"
git log --oneline -10
echo ""
echo "Modified files (recent):"
git diff --name-status HEAD~5 2>/dev/null | head -30
```

---

## Step 2: Identify Documentation Needs

| Documentation Type | Create If...                           | Location            |
| ------------------ | -------------------------------------- | ------------------- |
| **Entry File**     | New pattern discovered, problem solved | Project learned/    |
| **Skill**          | Pattern reusable >20x/year, ROI >100%  | ~/.claude/skills/   |
| **Blueprint**      | New feature with 3+ files              | Project blueprints/ |

---

## Step 3: Create Entry File (If Needed)

```markdown
# Entry #XXX: [pattern-name]

**Created**: [YYYY-MM-DD]
**Domain**: [api/database/frontend/deployment/etc.]
**Purpose**: [One-line description]

## Problem

[What was the issue?]

## Solution

[How was it solved?]

## Evidence

- [Metrics, test results]
- [Time saved]

## Pattern

[Reusable pattern with code]

## References

- Files: [paths]
```

---

## Step 4: Pattern Analysis

**Check ALL conditions - multiple suggestions can apply:**

```yaml
Repeatable (20+/year) + Saves >1h?    -> SKILL SUGGESTION
Universal enforcement needed?          -> PROJECT RULE
Quick reference (<5 lines)?            -> CORE PATTERNS update
3+ files modified for feature?         -> BLUEPRINT SUGGESTION
```

---

## Step 5: Final Verification

- [ ] Entry file created (if pattern discovered)
- [ ] Skill created (if ROI >100%)
- [ ] Status tracking updated
- [ ] All work committed

---

**Time Investment**: 10-15 minutes
**Value**: Complete knowledge preservation
