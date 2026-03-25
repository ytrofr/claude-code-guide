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

### Smart Discovery (Step 5 — runs BEFORE suggestions)

Before suggesting anything, `/document` scans existing artifacts at all 3 levels to prevent duplicates and correctly flag NEW vs UPDATE:

```bash
# Machine-level: scan categories and rule names
find ~/.claude/rules/ -name "*.md" -exec basename {} .md \; | sort

# Project-level: scan project rules
find .claude/rules/ -name "*.md" -exec basename {} .md \; 2>/dev/null | sort

# Branch-level: check for branch-specific rules/roadmap
ls .claude/rules/*$(git branch --show-current 2>/dev/null)* 2>/dev/null

# Skills and blueprints
ls ~/.claude/commands/ .claude/commands/ 2>/dev/null
```

This discovery step is critical — without it, `/document` would suggest creating rules that already exist, leading to duplication across the hierarchy.

### Decision Tree (AND Logic - Multiple Can Apply)

```yaml
Pattern detected → Check ALL conditions:

  ✓ Repeatable (20+/year) + Saves >1h?
    → ADD: SKILL SUGGESTION

  ✓ Enforcement needed? → CLASSIFY RULE LEVEL (see below)
    → ADD: MACHINE / PROJECT / BRANCH RULE

  ✓ Quick reference (<5 lines)?
    → ADD: CORE-PATTERNS update

  ✓ 3+ files changed?
    → ADD: BLUEPRINT SUGGESTION

Result: 0-5 suggestions can be generated simultaneously
```

### Rule Level Classification (3-Level Decision Tree)

When a pattern warrants a rule, classify it to the correct level:

```
Pattern discovered
    │
    ├─ Applies to ANY project on this machine?
    │  (tech-agnostic, universal NEVER/ALWAYS)
    │  YES → MACHINE RULE (~/.claude/rules/{category}/)
    │
    ├─ Applies to ALL branches of THIS project?
    │  (project conventions, tech stack rules)
    │  YES → PROJECT RULE (.claude/rules/)
    │
    ├─ Specific to current sprint/branch/feature?
    │  YES → BRANCH RULE (roadmap or .claude/rules/branch/)
    │
    └─ None of the above → Skip (not a rule)
```

**Classification examples**:

| Pattern | Level | Why |
|---------|-------|-----|
| "Never kill all node processes on WSL" | Machine | OS-specific, all projects |
| "Use barrel exports for 5+ file dirs" | Machine | Universal code organization |
| "Always use pgvector for embeddings" | Project | Project-specific tech choice |
| "Hebrew text must use RTL containers" | Project | Only relevant to this project |
| "Feature X requires flag Y this sprint" | Branch | Temporary, sprint-scoped |

### Rule Suggestion Format

Each rule suggestion includes full context for review:

```
[N]. [NEW|UPDATE] RULE — [level]: [category]/[name]
    Target: [exact file path]
    Exists: [yes — update needed | no — new rule]
    Pattern: [the lesson in 1 sentence]
    Why: [what happened this session that surfaced it]
    Draft:
    ---
    # [Rule Title]
    **Scope**: [what it applies to]
    **Authority**: MANDATORY
    ---
    ## Core Rule
    [1-2 sentence rule]
    ## When to Apply
    [conditions]
    ---
```

### 5 Suggestion Types

| Type              | When                       | Level | Template                |
| ----------------- | -------------------------- | ----- | ----------------------- |
| **SKILL**         | ROI >100%, used 20+/year   | Machine or Project | SKILL-TEMPLATE.md       |
| **MACHINE RULE**  | Universal NEVER/ALWAYS     | Machine | `~/.claude/rules/{cat}/` |
| **PROJECT RULE**  | Project-wide enforcement   | Project | `.claude/rules/`         |
| **BRANCH RULE**   | Sprint-specific pattern    | Branch | Roadmap or `.claude/rules/branch/` |
| **CORE-PATTERNS** | Quick reference (<5 lines) | Project | Add to CORE-PATTERNS.md |
| **BLUEPRINT**     | 3+ files, system change    | Project | BLUEPRINT-TEMPLATE.md   |

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

### Create MACHINE RULE if:
- [ ] MANDATORY enforcement needed
- [ ] Applies to ALL projects (tech-agnostic, universal)
- [ ] Prevents critical bugs/issues across any codebase
- [ ] <300 lines
- [ ] Location: `~/.claude/rules/{category}/`

### Create PROJECT RULE if:
- [ ] MANDATORY enforcement needed
- [ ] Applies to all branches of THIS project (not universal)
- [ ] Project-specific tech stack, conventions, or compliance
- [ ] <300 lines
- [ ] Location: `.claude/rules/`

### Create BRANCH RULE if:
- [ ] Sprint-specific or feature-flag tracking
- [ ] Temporary — will be removed or promoted after the sprint
- [ ] Location: Branch roadmap or `.claude/rules/branch/`

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
## PATTERN ANALYSIS — 4 suggestions

MACHINE-LEVEL (all projects):
  1. SKILL — gap-detection-workflow-skill: ROI 40+ hrs/year (20 uses x 2h)

PROJECT-LEVEL (all branches):
  2. NEW RULE — database/gap-detection-patterns.md: enforce gap query patterns
     Target: .claude/rules/database/gap-detection-patterns.md
     Exists: no — new rule
  3. CORE-PATTERNS — gap workflow quick reference (3 lines)

BRANCH-LEVEL (current branch):
  4. UPDATE RULE — branch/sprint-3-tracking.md: mark gap detection complete
     Target: .claude/rules/branch/sprint-3-tracking.md
     Exists: yes — update task status

Select (numbers / all / none): 1,2
```

---

## Overlap Detection (3-Level Scan)

Before suggesting, scan all 3 rule levels to prevent duplicates:

```bash
# Machine-level rules (universal)
find ~/.claude/rules/ -name "*.md" -exec basename {} .md \; | sort

# Project-level rules
find .claude/rules/ -name "*.md" -exec basename {} .md \; 2>/dev/null | sort

# Branch-level rules
ls .claude/rules/branch/ 2>/dev/null

# Skills (machine + project)
ls ~/.claude/commands/ .claude/commands/ 2>/dev/null

# CORE-PATTERNS
grep "[pattern]" memory-bank/always/CORE-PATTERNS.md 2>/dev/null
```

**If an existing rule covers the same pattern**: suggest UPDATE (not NEW).
**If the rule exists at the wrong level**: suggest MOVE (e.g., project rule that should be machine-level).

See also: [Chapter 26 — Global vs Project Rule Deduplication](26-claude-code-rules-system.md#global-vs-project-rule-deduplication)

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
- Chapter 26: Rules System (rule hierarchy, deduplication, placement)
- Chapter 29: Branch Context System
- Chapter 31: Branch-Aware Development
- Chapter 31b: Per-Branch Rules (branch-level rule loading)
- Chapter 55: /document v3 (production evidence of 3-level analysis)

---

**Previous**: [31: Branch-Aware Development](31-branch-aware-development.md)
**Next**: [33: Branch-Specific Skill Curation](33-branch-specific-skill-curation.md)
