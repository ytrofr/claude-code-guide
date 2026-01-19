# Chapter 31: Branch-Aware Development

**Evidence**: LIMOR AI MASTER-PLAN Phase 4 + 6
**Difficulty**: Intermediate
**Time**: 30 minutes setup
**ROI**: Auto-recommend skills, enforce patterns per branch

---

## Problem

Different branches have different needs:
- dev-Data needs gap-detection skills, not UI skills
- dev-UI needs theme skills, not database skills
- Manual skill selection = missed optimizations

---

## Solution: branch-variables.json

Central configuration for per-branch behavior.

### File Location

```
memory-bank/always/branch-variables.json
```

### Structure

```json
{
  "dev-Knowledge": {
    "mission": "Skills, Context, Agents & MCP Optimization",
    "skills_required": [
      "context-optimization-skill",
      "skill-detection-enhancement-skill",
      "anthropic-best-practices-skill",
      "blueprint-discovery-skill"
    ],
    "must_use_before_work": [
      "Check /context usage (<100k target)",
      "Validate skill activation (>90%)",
      "Review recent entries for patterns"
    ],
    "blueprints_auto_load": [
      "CONTEXT-SYSTEM",
      "SKILLS-SYSTEM"
    ]
  },
  "dev-Data": {
    "mission": "Find and close data gaps between environments",
    "skills_required": [
      "api-first-validation-skill",
      "gap-detection-and-sync-skill",
      "database-sync-matrix-skill",
      "comprehensive-parity-validation-skill"
    ],
    "must_use_before_work": [
      "Run comprehensive-gap-scan --api-check",
      "Validate API vs database parity (100% required)",
      "Check Cloud Scheduler job status"
    ],
    "blueprints_auto_load": [
      "DATABASE-SCHEMA",
      "GAP-SYSTEM-LIVING"
    ]
  },
  "dev-UI": {
    "mission": "UI Fixes & Improvements",
    "skills_required": [
      "dashboard-theme-migration-skill",
      "hebrew-preservation-skill",
      "mobile-responsive-skill"
    ],
    "must_use_before_work": [
      "Check mobile responsiveness",
      "Validate Hebrew RTL",
      "Run visual regression tests"
    ],
    "blueprints_auto_load": [
      "UI-COMPLETE",
      "DASHBOARD-PATTERNS"
    ]
  }
}
```

---

## Skill Weighting System

Branch-specific skills get +20 score bonus in pre-prompt hook.

### Hook Enhancement

```bash
# Add to .claude/hooks/pre-prompt.sh

get_branch_skills() {
    local current_branch=$(git branch --show-current 2>/dev/null)
    local branch_config="memory-bank/always/branch-variables.json"

    if [ -f "$branch_config" ]; then
        jq -r ".\"$current_branch\".skills_required[]?" "$branch_config" 2>/dev/null
    fi
}

score_skill_with_branch_bonus() {
    local skill_name="$1"
    local base_score="$2"
    local branch_skills=$(get_branch_skills)

    # +20 bonus if skill is in branch skills_required
    if echo "$branch_skills" | grep -qF "${skill_name}"; then
        echo $((base_score + 20))
    else
        echo "$base_score"
    fi
}
```

### Result

When on `dev-Knowledge` branch, `context-optimization-skill` ranks higher than unrelated skills.

---

## Branch Template Structure

Every branch follows standard structure:

```
CURRENT/{branch}/
├── {branch}-Instructions.md     # 100-150 lines max
├── {branch}-ROADMAP.md          # Living document  
└── CONTEXT-MANIFEST.json        # What files to load
```

### Instructions Template (100-150 lines)

```markdown
# {Branch} Branch Instructions

**Created**: YYYY-MM-DD
**Updated**: YYYY-MM-DD
**Mission**: [One sentence mission]
**Sacred**: 100% SHARP

---

## 🎯 Active Tasks

→ See {BRANCH}-ROADMAP.md for complete task list

---

## 🔧 Key Skills Required

- skill-1: [when to use]
- skill-2: [when to use]

→ Full list: branch-variables.json

---

## 📘 Auto-Loaded Blueprints

- Blueprint 1: [purpose]
- Blueprint 2: [purpose]

---

## 🚨 Critical Rules

1. **Rule 1**: [one sentence]
2. **Rule 2**: [one sentence]

→ Full rules: CORE-PATTERNS.md + .claude/rules/
```

### Roadmap Template

```markdown
# {Branch} Roadmap

**Last Updated**: YYYY-MM-DD
**Entry Range**: #{start}-#{current}

---

## 🎯 CURRENT (This Sprint)

| Task | Priority | Status |
|------|----------|--------|
| Task 1 | P0 | 🔄 IN PROGRESS |
| Task 2 | P1 | ⏸️ PLANNED |

---

## ✅ COMPLETED (This Session)

| Task | Status | Entry |
|------|--------|-------|
| Task done | ✅ COMPLETE | Entry #XXX |

---

## 📋 BACKLOG

- [ ] Future task 1
- [ ] Future task 2
```

---

## Pre-Prompt Display

Show branch context in hook output:

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 BRANCH: $current_branch"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Show mission
local mission=$(jq -r ".\"$current_branch\".mission" "$branch_config")
echo "Mission: $mission"
echo ""

# Show must-use checklist
echo "Before starting work:"
jq -r ".\"$current_branch\".must_use_before_work[]?" "$branch_config" | while read item; do
    echo "  □ $item"
done
```

---

## Setup Steps

### Step 1: Create branch-variables.json

```bash
cat > memory-bank/always/branch-variables.json << 'EOF'
{
  "main": {
    "mission": "Production stability",
    "skills_required": ["deployment-workflow-skill"],
    "must_use_before_work": ["Check all tests passing"],
    "blueprints_auto_load": []
  }
}
EOF
```

### Step 2: Add Your Branches

For each branch, add configuration with:
- `mission`: One sentence purpose
- `skills_required`: 5-10 most relevant skills
- `must_use_before_work`: 3-5 checklist items
- `blueprints_auto_load`: Auto-load blueprint names

### Step 3: Create Branch Directories

```bash
for branch in dev-Data dev-UI dev-Knowledge; do
    mkdir -p "CURRENT/$branch"
    # Create Instructions, ROADMAP, CONTEXT-MANIFEST
done
```

### Step 4: Update Hook

Add skill weighting to pre-prompt.sh (see above).

---

## Validation

```bash
# Check branch config exists
jq ".\"$(git branch --show-current)\"" memory-bank/always/branch-variables.json

# Verify skill weighting works
echo '{"prompt": "context optimization"}' | bash .claude/hooks/pre-prompt.sh
# context-optimization-skill should rank higher on dev-Knowledge

# Check branch structure
ls CURRENT/$(git branch --show-current)/
# Should show: Instructions.md, ROADMAP.md, CONTEXT-MANIFEST.json
```

---

**Related Chapters**:
- Chapter 29: Branch Context System (CONTEXT-MANIFEST)
- Chapter 30: Blueprint Auto-Loading
- Chapter 32: Document Automation

---

**Previous**: [30: Blueprint Auto-Loading](30-blueprint-auto-loading.md)
**Next**: [32: Document Automation](32-document-automation.md)