---
description: "Create a skill from session learnings - GUIDED mode"
allowed_tools: ["Read", "Write", "Bash", "Grep", "Edit"]
---

# Retrospective - Guided Skill Creation

Create a reusable skill from this session's learnings through guided questions.

**Source**: Sionic AI Skills Training (Hugging Face) + Anthropic Best Practices
**ROI**: 67% faster skill creation (30 min -> 10 min)

---

## Step 1: Gather Context Automatically

First, see what happened this session:

```bash
echo "=== RECENT COMMITS ===" && git log --oneline -10
```

```bash
echo "=== MODIFIED FILES ===" && git diff --name-only HEAD~5 2>/dev/null || git diff --name-only HEAD~3
```

```bash
echo "=== CURRENT BRANCH ===" && git branch --show-current
```

---

## Step 2: Ask Guided Questions

### Question 1: Problem Statement

**What problem were we solving in this session?**

### Question 2: Failed Attempts (CRITICAL)

**What approaches did we try that DID NOT work?**

### Question 3: Working Solution

**What finally worked?**

### Question 4: Trigger Keywords

**When should this skill be activated?**

### Question 5: Skill Name

**What should we name this skill?**

- Format: `[domain]-[purpose]-skill`

---

## Step 3: Generate Skill File

Based on answers, create skill at: `~/.claude/skills/[name]-skill.md`

**Required sections**:

1. Specific trigger scenarios (NUMBERED list with exact error messages)
2. Failed Attempts table (CRITICAL - document what did not work)
3. Evidence with concrete numbers (success rate, tests, dates)
4. Quick start steps (target < 5 minutes)

---

## Step 4: Validate

```bash
# Verify skill exists
ls -la ~/.claude/skills/ | grep [skill-name]
```

```bash
# Verify it has Failed Attempts section (CRITICAL)
grep -l "Failed Attempts" ~/.claude/skills/[skill-name]-skill.md
```

---

**Time to complete**: ~10 minutes
**Value created**: Prevents repeating same debugging in future sessions
