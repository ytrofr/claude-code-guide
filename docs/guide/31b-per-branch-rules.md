---
layout: default
title: "Per-Branch Rules - Branch-Specific Rule Files That Only Load on Their Branch"
description: "How to organize rules into per-branch directories so each branch only loads relevant enforcement rules, saving tokens and reducing noise."
---

# Chapter 31b: Per-Branch Rules

Claude Code auto-loads every `.md` file in `.claude/rules/`. That works well for universal rules, but some rules only apply to one branch. Loading AI architecture enforcement rules on a UI branch wastes tokens and adds noise. This chapter shows how to create per-branch rule directories that load only when you're on the right branch.

**Purpose**: Move branch-specific rules out of the global rules directory so they only load on their branch
**Source**: Production pattern -- LIMOR AI (6 branches, 351 lines moved to branch-specific)
**Difficulty**: Easy
**Time**: 15 minutes setup

---

## The Problem

`.claude/rules/` loads ALL rules on ALL branches:

```
.claude/rules/
├── sacred/commandments.md       # Universal - needed everywhere
├── database/patterns.md         # Universal - needed everywhere
├── ai/anti-regression.md        # Only needed on dev-Limor (AI branch)
├── ai/pure-gemini-enforcement.md # Only needed on dev-Limor
└── ai/vertex-ai-cost.md         # Only needed on dev-Limor
```

When you're on `dev-UI` fixing CSS, those 3 AI rules (~350 lines, ~875 tokens) load for nothing.

---

## The Solution: memory-bank/rules/{branch}/

Create a parallel rules directory organized by branch name:

```
memory-bank/rules/
├── dev-Limor/
│   ├── anti-regression.md
│   ├── pure-gemini-enforcement.md
│   └── vertex-ai-cost.md
├── dev-Data/
│   └── (branch-specific rules for data work)
├── dev-UI/
│   └── (branch-specific rules for UI work)
└── dev-MERGE/
    └── (branch-specific rules for deployment)
```

Rules in `.claude/rules/` stay universal. Rules in `memory-bank/rules/{branch}/` only load on that branch.

---

## How It Works

A `session-start.sh` hook detects the current branch, finds rule files in its directory, and writes `@` imports into CLAUDE.md:

```bash
# Add to .claude/hooks/session-start.sh

BRANCH=$(git branch --show-current 2>/dev/null)
BRANCH_RULES_DIR="memory-bank/rules/${BRANCH}"

if [ -d "$BRANCH_RULES_DIR" ]; then
    RULE_FILES=$(find -L "$BRANCH_RULES_DIR" -name "*.md" -not -name ".*" -type f 2>/dev/null | sort)
    if [ -n "$RULE_FILES" ]; then
        cat >> CLAUDE.md << 'EOF'

## Branch-Specific Rules (Auto-Loaded)

EOF
        echo "$RULE_FILES" | while read rule_file; do
            echo "@$rule_file" >> CLAUDE.md
        done
        echo "" >> CLAUDE.md
        echo "_Auto-loaded from $BRANCH_RULES_DIR/_" >> CLAUDE.md
    fi
fi
```

**Result in CLAUDE.md** (when on dev-Limor):

```markdown
## Branch-Specific Rules (Auto-Loaded)

@memory-bank/rules/dev-Limor/anti-regression.md
@memory-bank/rules/dev-Limor/pure-gemini-enforcement.md
@memory-bank/rules/dev-Limor/vertex-ai-cost.md

_Auto-loaded from memory-bank/rules/dev-Limor/_
```

When on `dev-UI`, this section is empty -- those AI rules never load.

---

## Decision Criteria: Universal vs Branch-Specific

Before moving a rule, ask one question:

> **"Does every branch need this rule to avoid mistakes?"**

| Answer                      | Location                      | Example                                                                   |
| --------------------------- | ----------------------------- | ------------------------------------------------------------------------- |
| Yes, all branches need it   | `.claude/rules/` (universal)  | Sacred Commandments, database credentials, git safety                     |
| No, only one branch uses it | `memory-bank/rules/{branch}/` | AI anti-regression (only AI branch), deploy patterns (only deploy branch) |
| 2-3 branches need it        | `.claude/rules/` (universal)  | Keep universal -- the overhead of duplication isn't worth the savings     |

**Rule of thumb**: If a rule mentions a specific system, architecture, or workflow that only one branch works on, it's branch-specific.

### Examples

| Rule                        | Verdict                     | Reasoning                                                                       |
| --------------------------- | --------------------------- | ------------------------------------------------------------------------------- |
| Sacred Commandments         | Universal                   | Every branch must follow Golden Rule, financial precision                       |
| Database credentials        | Universal                   | Any branch might query the database                                             |
| AI anti-regression workflow | Branch-specific (AI branch) | Only the AI branch edits tier files                                             |
| Pure Gemini enforcement     | Branch-specific (AI branch) | Only the AI branch modifies AI architecture                                     |
| Deployment patterns         | Could go either way         | If only one branch deploys, move it; if any branch might deploy, keep universal |

---

## Setup Steps

### Step 1: Create Branch Directories

```bash
# Create a directory for each branch
for branch in main dev-feature dev-data dev-ui; do
    mkdir -p "memory-bank/rules/$branch"
done
```

### Step 2: Move Branch-Specific Rules

```bash
# Move rules that only apply to one branch
mv .claude/rules/ai/anti-regression.md memory-bank/rules/dev-feature/
mv .claude/rules/ai/pure-gemini-enforcement.md memory-bank/rules/dev-feature/

# Remove empty directory
rmdir .claude/rules/ai/
```

### Step 3: Add Hook Logic

Add the hook code from the "How It Works" section above to your `.claude/hooks/session-start.sh`. If you already have a session-start hook, add this as a new step.

**Important**: The hook must write `@` imports to CLAUDE.md (not just print to terminal). The `@` symbol only triggers file loading when it appears **in CLAUDE.md**.

### Step 4: Validate

```bash
# Switch to the branch
git checkout dev-feature

# Run hook manually
bash .claude/hooks/session-start.sh

# Verify @ imports appear in CLAUDE.md
grep "Branch-Specific Rules" CLAUDE.md
grep "^@memory-bank/rules/" CLAUDE.md

# Switch to a different branch and verify rules DON'T appear
git checkout dev-ui
bash .claude/hooks/session-start.sh
grep "^@memory-bank/rules/" CLAUDE.md  # Should show nothing (or different rules)
```

---

## File Structure: Flat, Not Nested

Keep rules flat within each branch directory:

```
# DO: flat structure
memory-bank/rules/dev-Limor/
├── anti-regression.md
├── pure-gemini-enforcement.md
└── vertex-ai-cost.md

# DON'T: nested subdirectories
memory-bank/rules/dev-Limor/
├── ai/
│   ├── anti-regression.md
│   └── pure-gemini-enforcement.md
└── cost/
    └── vertex-ai-cost.md
```

Flat is simpler, and the `find` command in the hook handles it cleanly. Each branch typically has 1-5 rules -- not enough to warrant subdirectories.

---

## Relationship to Other Branch Context Systems

This pattern complements the other per-branch systems from Chapters 29-31:

| System                          | Location                                 | What It Controls                      | Loaded By          |
| ------------------------------- | ---------------------------------------- | ------------------------------------- | ------------------ |
| **Branch context** (Ch. 29)     | `CURRENT/{branch}/CONTEXT-MANIFEST.json` | Which on-demand files to `@`-import   | session-start hook |
| **Blueprints** (Ch. 30)         | `blueprint-registry.json`                | Which blueprints auto-load per branch | session-start hook |
| **Branch variables** (Ch. 31)   | `branch-variables.json`                  | Mission, skills, pre-work checklist   | pre-prompt hook    |
| **Branch rules** (this chapter) | `memory-bank/rules/{branch}/`            | Enforcement rules per branch          | session-start hook |

They all share the same principle: **load only what the current branch needs**.

---

## Measuring Impact

```bash
# Count lines saved on non-target branches
moved_lines=0
for f in memory-bank/rules/dev-Limor/*.md; do
    moved_lines=$((moved_lines + $(wc -l < "$f")))
done
echo "Lines NOT loaded on other branches: $moved_lines"
echo "Estimated token savings: ~$((moved_lines * 5 / 2)) tokens per session"
```

### Real Results

| What Moved                          | Lines | Tokens Saved (per session, per non-target branch) |
| ----------------------------------- | ----- | ------------------------------------------------- |
| 3 AI rules → dev-Limor              | 351   | ~875 tokens                                       |
| **Per session on 5 other branches** |       | **~875 tokens not loaded**                        |

Small per-file, but it compounds: 875 tokens x 5 branches x multiple sessions/day.

---

## Key Takeaways

1. **`.claude/rules/` is for universal rules** that every branch needs. Keep it lean.
2. **`memory-bank/rules/{branch}/` is for branch-specific enforcement** that only one branch uses.
3. **The session-start hook** auto-discovers and `@`-imports branch rules. No manual maintenance.
4. **Flat structure** -- no subdirectories within branch rule folders.
5. **One question decides placement**: "Does every branch need this rule to avoid mistakes?"
6. **Move cautiously** -- validate on the target branch before committing. A rule that doesn't load when needed is worse than one that loads when not needed.

---

**Related Chapters**:

- Chapter 29: Branch Context System (CONTEXT-MANIFEST.json)
- Chapter 30: Blueprint Auto-Loading (per-branch blueprints)
- Chapter 31: Branch-Aware Development (branch-variables.json)
- Chapter 39: Context Separation (global vs project-level)

---

**Previous**: [31: Branch-Aware Development](31-branch-aware-development.md)
**Next**: [32: Document Automation](32-document-automation.md)
