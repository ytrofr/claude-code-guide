# Chapter 32: Document Automation with Pattern Analysis

**Evidence**: Production Entry #282 - 67% faster documentation
**Difficulty**: Intermediate
**Time**: 20 minutes setup
**ROI**: 67% faster docs + automatic pattern detection

---

## Problem

Chapter 23 covers basic `/document` for Entry creation.

But it's missing:

- **Pattern analysis**: Should this become a skill? A rule? A blueprint?
- **Decision matrix**: When to create what
- **5-type suggestions**: Automatic recommendations

---

## Solution: Enhanced /document with Pattern Analysis

The 13-step workflow:

```
1. Gather context (git diff)
2. Create Entry
3. Update Roadmap
4. Update system-status.json
5-8. PATTERN ANALYSIS (NEW)
9. Execute selected suggestions
10-13. Commit and validate
```

---

## Pattern Analysis Engine (Steps 5-8)

### Decision Tree (AND Logic - Multiple Can Apply)

```yaml
Pattern detected → Check ALL conditions:

  ✓ Repeatable (20+/year) + Saves >1h?
    → ADD: SKILL SUGGESTION

  ✓ Universal enforcement needed?
    → ADD: PROJECT RULE

  ✓ Branch-specific pattern?
    → ADD: BRANCH RULE + MANIFEST UPDATE

  ✓ Quick reference (<5 lines)?
    → ADD: CORE-PATTERNS update

  ✓ 3+ files changed?
    → ADD: BLUEPRINT SUGGESTION

Result: 0-5 suggestions can be generated simultaneously
```

### 5 Suggestion Types

| Type              | When                       | Template                |
| ----------------- | -------------------------- | ----------------------- |
| **SKILL**         | ROI >100%, used 20+/year   | SKILL-TEMPLATE.md       |
| **PROJECT RULE**  | Universal enforcement      | rules/domain/pattern.md |
| **BRANCH RULE**   | Branch-specific pattern    | CONTEXT-MANIFEST update |
| **CORE-PATTERNS** | Quick reference (<5 lines) | Add to CORE-PATTERNS.md |
| **BLUEPRINT**     | 3+ files, system change    | BLUEPRINT-TEMPLATE.md   |

---

## Enhanced Skill File

Update `~/.claude/skills/document-workflow-skill/SKILL.md`:

```yaml
---
name: document-workflow-skill
description: |
  Complete documentation with intelligent suggestion engine. Creates Entry,
  analyzes patterns, suggests skills/rules/blueprints. Use when work complete,
  session ending, or user says /document.
Triggers: document, /document, document work, create entry, session complete
user-invocable: true
---

# Document Workflow Skill

## 13-Step Workflow

### Phase 1: Context (Steps 1-2)
1. Run `git diff` and `git status`
2. Identify what was accomplished

### Phase 2: Core Documentation (Steps 3-4)
3. Create Entry: `memory-bank/learned/entry-XXX-topic.md`
4. Update Roadmap: Move task to "Completed" section

### Phase 3: Pattern Analysis (Steps 5-8) 🆕
5. Check: Repeatable 20+/year + >1h savings? → SKILL suggestion
6. Check: Universal enforcement needed? → RULE suggestion
7. Check: Quick reference pattern? → CORE-PATTERNS update
8. Check: 3+ files changed? → BLUEPRINT suggestion

### Phase 4: Execute (Steps 9-11)
9. Present suggestions to user
10. Execute selected suggestions
11. Update system-status.json

### Phase 5: Commit (Steps 12-13)
12. Create single commit with all changes
13. Validate cross-references

## Decision Matrix

### Create SKILL if:
- [ ] Pattern used 20+ times/year
- [ ] Time savings >1 hour per use
- [ ] ROI >100%
- [ ] Not foundational (foundational → rules)

### Create RULE if:
- [ ] MANDATORY enforcement needed
- [ ] Prevents critical bugs/issues
- [ ] Universal across all branches
- [ ] <300 lines

### Update CORE-PATTERNS if:
- [ ] Quick reference needed (<5 lines)
- [ ] Universal pattern
- [ ] Frequently looked up

### Create BLUEPRINT if:
- [ ] 3+ files modified
- [ ] System architecture changed
- [ ] Feature is recreatable/standalone

## Example Output

```

## 📋 DOCUMENTATION COMPLETE

Entry #282 created

## 🎯 PATTERN ANALYSIS (3 suggestions detected)

### 1. SKILL SUGGESTION ✓

Name: gap-detection-workflow-skill
ROI: 40+ hrs/year (20 uses × 2 hours)
Triggers: gap detection, missing data, investigate gaps

### 2. RULE SUGGESTION ✓

Name: database/gap-detection-patterns.md
Scope: PROJECT (applies to all branches)
Reason: Universal enforcement needed

### 3. CORE-PATTERNS UPDATE ✓

Pattern: Gap workflow quick reference (3 lines)

---

Select options (1-3 comma-separated, 'all', or 'none'): 1,3

```

```

---

## Overlap Detection

Before suggesting, check for existing:

```bash
# Check if skill already exists
grep -r "Use when" ~/.claude/skills/ | grep -i "[keywords]"

# Check if rule already exists
grep -r "[pattern]" .claude/rules/

# Check if in CORE-PATTERNS
grep "[pattern]" memory-bank/always/CORE-PATTERNS.md
```

---

## Integration with Chapter 23

This chapter ENHANCES Chapter 23 (Session Documentation):

| Aspect               | Chapter 23 | Chapter 32 |
| -------------------- | ---------- | ---------- |
| Entry creation       | ✅ Yes     | ✅ Yes     |
| Roadmap update       | ✅ Yes     | ✅ Yes     |
| Status update        | ✅ Yes     | ✅ Yes     |
| Pattern analysis     | ❌ No      | ✅ YES     |
| Skill suggestion     | ❌ No      | ✅ YES     |
| Rule suggestion      | ❌ No      | ✅ YES     |
| Blueprint suggestion | ❌ No      | ✅ YES     |

---

## Setup

### Option 1: Enhance Existing Skill

Update `~/.claude/skills/session-documentation-skill/SKILL.md` with:

- Decision matrix section
- Pattern analysis steps
- 5 suggestion types

### Option 2: Create New Skill

Create `~/.claude/skills/document-workflow-skill/SKILL.md` with full 13-step workflow.

---

## Validation

```bash
# Test skill activation
echo '{"prompt": "/document"}' | bash .claude/hooks/pre-prompt.sh

# Verify suggestions appear
# When prompted, select suggestions
# Verify files created correctly
```

---

**Related Chapters**:

- Chapter 23: Session Documentation (basic workflow)
- Chapter 29: Branch Context System
- Chapter 31: Branch-Aware Development

---

**Previous**: [31: Branch-Aware Development](31-branch-aware-development.md)
**Next**: [33: Branch-Specific Skill Curation](33-branch-specific-skill-curation.md)
