---
layout: default
title: "Context Separation - Isolating Project-Specific Content from Global Settings"
description: "How to separate project-specific skills, rules, and CLAUDE.md content from global machine context so other projects don't pay the token cost."
---

# Chapter 39: Context Separation

When you work on multiple projects with Claude Code, anything in your global config (`~/.claude/`) loads for every project. Skills, rules, and CLAUDE.md content designed for one project become dead weight everywhere else. This chapter shows how to audit for project contamination, relocate project-specific content to the right level, and trim your CLAUDE.md to its essential minimum.

**Purpose**: Eliminate per-project token waste by keeping global context truly universal
**Source**: Production case study -- LIMOR AI context separation (Entry #356)
**Difficulty**: Intermediate
**Time**: 1-2 hours for a full audit and cleanup

---

## The Problem

Project-specific content leaks into global context in three common ways:

### 1. Project References in Global Rules

Global rules (`~/.claude/rules/`) should work for every project. But over time, project-specific examples creep in:

```markdown
<!-- ~/.claude/rules/global/context-checking.md -->

## Pre-Build Checklist

1. Search context: memory-bank/learned/, ULTIMATE-MINI files ← Project-specific paths
2. Use database-context-loader-skill ← Project-specific skill
3. Check UNIVERSAL-SYSTEM-MASTER.md for existing APIs ← Project-specific file
```

Every non-related project loads these irrelevant references on every message.

### 2. Project-Specific Skills at User Level

Skills in `~/.claude/skills/` load their descriptions for all projects. If 25 of your 47 skills only apply to one project, every other project's skill budget carries 25 irrelevant descriptions.

```
~/.claude/skills/
├── context-optimization-skill/     # Universal ✓
├── deployment-workflow-skill/      # Project-specific ✗
├── sacred-commandments-skill/      # Project-specific ✗
├── database-schema-skill/          # Project-specific ✗
└── playwright-mcp-skill/           # Universal ✓
```

### 3. Bloated CLAUDE.md

Project CLAUDE.md files grow organically. Content that was useful during development gets left behind even after it's been moved to rules, skills, or on-demand files:

```markdown
<!-- Before: 526 lines of CLAUDE.md -->

## Deployment Rules ← Duplicated in .claude/rules/deployment/patterns.md

## Sacred Commandments ← Duplicated in .claude/rules/sacred/commandments.md

## Context System ← Duplicated in always/CONTEXT-ROUTER-MINI.md

## Skills System ← Duplicated in branch-variables.json

## Agent Ecosystem ← Duplicated in AGENT-MASTER-REGISTRY.md
```

---

## The Solution: Three-Phase Cleanup

### Phase 1: Clean Global Rules

**Goal**: Remove all project-specific references from `~/.claude/rules/`

**Audit**:

```bash
# Find project-specific terms in global rules
grep -rn "YourProject\|your-specific-tool\|your-api-name" ~/.claude/rules/
```

**Fix**: Replace project-specific items with generic equivalents:

| Before (Project-Specific)    | After (Universal)                 |
| ---------------------------- | --------------------------------- |
| `memory-bank/learned/`       | `project documentation`           |
| `UNIVERSAL-SYSTEM-MASTER.md` | `project system docs`             |
| `Sacred Commandment X`       | `single responsibility principle` |
| `₪X cost`                    | `$X cost`                         |

**Verification**:

```bash
# Should return zero results
grep -rn "YourProject\|your-specific-tool" ~/.claude/rules/
```

### Phase 2: Relocate Project-Specific Skills

**Goal**: Move project-specific skills from `~/.claude/skills/` (global) to `.claude/skills/` (per-project)

Claude Code discovers skills at both levels. The difference is scope:

| Level         | Location            | Loads For         | Use When                   |
| ------------- | ------------------- | ----------------- | -------------------------- |
| User (global) | `~/.claude/skills/` | All projects      | Skill is useful everywhere |
| Project       | `.claude/skills/`   | This project only | Skill is project-specific  |

**Decision criteria for each skill**:

- Would this skill help in a brand new project? → **Keep at user level**
- Does this skill reference project-specific APIs, schemas, or patterns? → **Move to project level**
- Does this skill use project-specific terminology? → **Move to project level**

**How to move a skill**:

```bash
# Move from global to project level
mv ~/.claude/skills/my-project-skill/ .claude/skills/my-project-skill/

# Verify it still works (Claude Code discovers both levels)
head -5 .claude/skills/my-project-skill/SKILL.md
```

**Note**: If your project `.gitignore` excludes `.claude/skills/`, the relocated skills won't be committed to git. This is fine -- they're local development tools, not shared code. If you want them shared across team members, remove the gitignore exclusion.

### Phase 3: Trim CLAUDE.md

**Goal**: Remove everything from CLAUDE.md that's already covered by auto-loaded rules and files

**The CLAUDE.md Gate Test**:

> For each section, ask: **"Would removing this cause Claude to make mistakes?"**
>
> If the content exists in `.claude/rules/`, `memory-bank/always/`, or any other auto-loaded file, the answer is **no**. Remove it.

**Common duplications to eliminate**:

| CLAUDE.md Section             | Already Covered By                   | Action                       |
| ----------------------------- | ------------------------------------ | ---------------------------- |
| Deployment rules              | `.claude/rules/deployment/`          | Remove, add 1-line reference |
| Database patterns             | `.claude/rules/database/`            | Remove, add 1-line reference |
| Sacred/compliance rules       | `.claude/rules/sacred/`              | Remove, add 1-line reference |
| Context system explanation    | Auto-loaded always/ files            | Remove entirely              |
| Validation workflow           | `.claude/rules/global/validation.md` | Remove entirely              |
| Agent/skill ecosystem summary | Registry files                       | Remove, add 1-line reference |
| Historical achievements       | Move to learned/ files               | Remove entirely              |
| Feature status                | `system-status.json`                 | Remove entirely              |

**Keep in CLAUDE.md only**:

- Content that exists **nowhere else** (truly unique rules)
- `@` import declarations (if using file imports)
- Project identity (1-2 lines: what this project is)

**Real result**: One project went from 526 lines to 103 lines (80% reduction, ~5,500 tokens saved per message).

---

## Measuring the Impact

### Before/After Token Comparison

```bash
# Measure CLAUDE.md token cost
wc -c CLAUDE.md | awk '{printf "CLAUDE.md: %d chars (~%d tokens)\n", $1, $1/4}'

# Measure global rules cost
find ~/.claude/rules -name "*.md" -exec cat {} + | wc -c | \
  awk '{printf "Global rules: %d chars (~%d tokens)\n", $1, $1/4}'

# Measure global skill description budget usage
total=0
for f in $(find ~/.claude/skills -name "SKILL.md" 2>/dev/null); do
  desc=$(grep "^description:" "$f" | head -1)
  total=$((total + ${#desc}))
done
echo "Global skill descriptions: $total chars (budget: ${SLASH_COMMAND_TOOL_CHAR_BUDGET:-16000})"
```

### Expected Savings

| What You Clean                        | Typical Savings                         | Who Benefits                 |
| ------------------------------------- | --------------------------------------- | ---------------------------- |
| Project refs in global rules          | 500-3,000 chars                         | All other projects           |
| Project skills moved to project level | 2,000-8,000 chars of description budget | All other projects           |
| CLAUDE.md trim                        | 5,000-25,000 chars                      | This project (every message) |

---

## Maintenance: Preventing Future Contamination

### When Adding New Rules

Ask: "Does this apply to ALL my projects, or just this one?"

```
Universal (all projects)     → ~/.claude/rules/
Project-specific             → .claude/rules/
```

### When Creating New Skills

Ask: "Would this help in a completely different project?"

```
Yes (universal utility)      → ~/.claude/skills/
No (project-specific)        → .claude/skills/
```

### When Editing CLAUDE.md

Ask: "Is this already in a rule file or auto-loaded file?"

```
Yes → Don't add it to CLAUDE.md
No  → Ask "Would removing this cause mistakes?" If no → Don't add it
```

### Periodic Audit

Run quarterly:

```bash
echo "=== Global Rules Audit ==="
echo "Files: $(find ~/.claude/rules -name '*.md' | wc -l)"
echo "Total chars: $(find ~/.claude/rules -name '*.md' -exec cat {} + | wc -c)"

echo ""
echo "=== Global Skills Audit ==="
echo "Skills: $(find ~/.claude/skills -name 'SKILL.md' | wc -l)"

echo ""
echo "=== CLAUDE.md Size ==="
wc -l CLAUDE.md
echo "(Target: under 200 lines)"
```

---

## Case Study: Production Cleanup

A production project with 228 skills, 52 agents, and 5 MCP servers underwent context separation:

| Phase     | Action                                            | Time       | Token Savings                      |
| --------- | ------------------------------------------------- | ---------- | ---------------------------------- |
| 1         | Cleaned 18 project references from 4 global rules | 15 min     | ~750 tokens/msg (other projects)   |
| 2         | Moved 25 project-specific skills to project level | 30 min     | ~1,200 tokens/msg (other projects) |
| 3         | Trimmed CLAUDE.md from 526 → 103 lines            | 30 min     | ~3,100 tokens/msg (this project)   |
| **Total** | **3 phases**                                      | **75 min** | **~5,000 tokens/msg**              |

The project's functionality was unaffected -- all removed content was accessible through rule files and on-demand imports. Three branches were validated with zero regressions.

---

## Key Takeaways

1. **Global context is shared cost**. Everything in `~/.claude/` loads for every project. Keep it universal.
2. **Project-specific skills belong at project level**. Move them from `~/.claude/skills/` to `.claude/skills/`.
3. **CLAUDE.md should be minimal**. If content exists in a rule file or auto-loaded file, it doesn't belong in CLAUDE.md.
4. **The gate test works**: "Would removing this cause Claude to make mistakes?" If not, remove it.
5. **80% of CLAUDE.md may be redundant**. Rules, always-loaded files, and skills already carry the information.
6. **75 minutes of cleanup can save thousands of tokens per message** -- permanently.

---

**Previous**: [38: Context Costs and Skill Budget](38-context-costs-and-skill-budget.md)
**Next**: [40: Agent Orchestration Patterns](40-agent-orchestration-patterns.md)
