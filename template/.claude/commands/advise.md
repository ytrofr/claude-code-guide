---
description: "Search skills registry before starting new work"
allowed_tools: ["Read", "Bash", "Grep"]
---

# /advise - Search Skills Before Starting Work

Search the skills registry for relevant past solutions before implementing something new.

**Source**: Sionic AI Skills Training (Hugging Face)
**Purpose**: Prevent reinventing solutions that already exist

---

## Step 1: Understand User's Goal

Extract the key topic/problem from the user's request:

- What are you trying to accomplish?
- What errors or issues are you facing?
- What domain does this relate to?

---

## Step 2: Search Skills Registry

```bash
# Search skill descriptions for keywords
echo "=== Searching skill descriptions ==="
grep -li "[TOPIC_KEYWORD]" ~/.claude/skills/*-skill.md 2>/dev/null

# Search for exact error messages
echo "=== Searching for error messages ==="
grep -rn "[ERROR_MESSAGE]" ~/.claude/skills/ 2>/dev/null
```

---

## Step 3: Load Relevant Skills

For each matching skill file, read and extract:

1. **What worked** (from "CORRECT PATTERN" or "Quick Start" sections)
2. **What failed** (CRITICAL - from "Failed Attempts" tables)
3. **Recommended approach** (from "Quick Decision Tree" or main content)

---

## Step 4: Provide Recommendation

### If Skills Found:

```markdown
## Relevant Skills Found

**Matching skills**:

- [skill-1-name]: [brief description]

**Recommended approach** (from [skill-name]):
[Copy key steps from the skill]

**Patterns to AVOID** (from Failed Attempts):

- Don't: [failed approach] -> [why it failed]

**Quick Start**:
[Copy the quick start steps from the skill]
```

### If No Skills Match:

```markdown
## No Existing Skills Match

No skills found for: [topic/error]

**Safe to proceed**: This appears to be a new pattern.

**After solving**: Consider running `/retrospective` to capture learnings as a new skill.
```

---

**Time to complete**: ~2 minutes
**Value**: Prevents 30-60 minutes of reinventing solutions
