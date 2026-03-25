---
layout: default
title: "Stack Audit & Maintenance Patterns"
parent: Guide
nav_order: 61
---

# Stack Audit & Maintenance Patterns

*How to keep your Claude Code configuration healthy as it grows*

## Why Audit Your Stack?

Claude Code configurations grow organically — skills accumulate, rules are added, commands get copied with subtle errors. Without periodic audits, your setup silently degrades:

- **Commands with wrong frontmatter** silently ignore tool restrictions (security risk)
- **Outdated rules** reference features that no longer exist
- **Duplicate skills** waste context tokens on redundant descriptions
- **Version drift** means you miss new features that could save hours

Real example: A March 2026 audit found **7 out of 9 commands** had `allowed_tools` (underscored) instead of `allowed-tools` (hyphenated). All tool restrictions were silently disabled for months.

## The Four-Area Audit

### 1. Command Compliance

Check that all commands use correct frontmatter format:

```bash
# Find wrong field names (underscored instead of hyphenated)
grep -rl 'allowed_tools' ~/.claude/commands/ 2>/dev/null

# Find JSON array format (should be comma-separated)
grep -rl 'allowed-tools:.*\[' ~/.claude/commands/ 2>/dev/null

# Both should return 0 results
```

**Correct format:**
```yaml
---
description: Start with action verb. Include "Use when..." clause.
allowed-tools: Read, Bash, Grep
user-invocable: true
---
```

**Wrong format (silently ignored):**
```yaml
allowed_tools: ["Read", "Bash", "Grep"]  # Underscored key + JSON array
```

### 2. Rules Inventory

Audit rules for relevance, duplication, and scope:

```bash
# Count rules by category
find ~/.claude/rules/ -name "*.md" | sed 's|.*/rules/||' | cut -d/ -f1 | sort | uniq -c | sort -rn

# Find potential duplicates (similar filenames)
find ~/.claude/rules/ -name "*.md" -exec basename {} \; | sort

# Check for outdated version references
grep -rl '2\.1\.[0-6]' ~/.claude/rules/ 2>/dev/null
```

**Health indicators:**
- Global rules (`~/.claude/rules/`): Universal patterns for all projects
- Project rules (`.claude/rules/`): Project-specific conventions
- No rule should exceed 100 lines
- Each rule has single responsibility

### 3. Skills Inventory

```bash
# Count skills
ls -d ~/.claude/skills/*-skill/ 2>/dev/null | wc -l

# Check for skills without proper description
for d in ~/.claude/skills/*/; do
  if ! grep -q '^description:' "$d/SKILL.md" 2>/dev/null; then
    echo "Missing description: $d"
  fi
done

# Find oversized skills (>500 lines)
wc -l ~/.claude/skills/*/SKILL.md 2>/dev/null | sort -rn | head -5
```

**Skill hygiene:**
- Every skill needs a clear `description:` in frontmatter (this is how Claude matches skills to tasks)
- Skills >500 lines should use supporting files (`reference.md`, `examples.md`)
- Use `globs:` to scope domain-specific skills (saves 30-50% tokens)
- Remove skills that duplicate built-in Claude Code capabilities

### 4. Version Currency

```bash
# Check Claude Code version
claude --version

# Compare against latest documented features
# If your version > guide's latest chapter, features may be undocumented
```

## The /document v3 Pattern

The `/document` command performs a three-level analysis to systematically discover documentation opportunities:

### Three Levels

| Level | Scope | What It Finds |
|-------|-------|---------------|
| **Machine** | `~/.claude/` (all projects) | Global rules, universal skills, machine-wide patterns |
| **Project** | `.claude/` (all branches) | Project-specific rules, shared conventions |
| **Branch** | Current branch only | Branch-specific context, current work patterns |

### Six Mandatory Checks (Per Level)

| Check | What It Looks For |
|-------|-------------------|
| **Rules** | NEVER/ALWAYS lessons from recent work |
| **Skills** | Reusable workflows worth extracting |
| **Blueprints** | Architecture docs for complex systems |
| **Roadmap** | Phase status updates, completed milestones |
| **Project Root** | CLAUDE.md updates, system-status.json |
| **Memory** | Auto-memory entries, stale information |

### Phase Workflow

```
Phase 1: GATHER + DOCUMENT (automatic)
  └── Scan recent work, git log, session history

Phase 2: ANALYZE + SUGGEST (6 checks × 3 levels)
  └── Present findings → STOP for user approval
  └── User selects which suggestions to implement

Phase 3: CREATE SELECTED (only approved items)
  └── Create rules, skills, docs as approved
```

**Critical**: The mandatory pause in Phase 2 prevents creating overlapping skills or wrong-scope rules.

## The /retrospective → Skill Pipeline

Sessions often produce reusable patterns that should become skills. The `/retrospective` command guides extraction:

### Five Questions

1. **What problem did you solve?** → Becomes the skill's `description:`
2. **What approaches failed?** → Becomes the "Failed Attempts" section (prevents future waste)
3. **What approach worked?** → Becomes the core skill content
4. **What trigger keywords should activate this?** → Becomes the skill's matching keywords
5. **What should the skill be named?** → Becomes the skill directory name

### When to Run /retrospective

- After solving a non-trivial bug (>30 min debugging)
- After discovering an unexpected system behavior
- After building a reusable pattern
- At session end if you learned something transferable

## Maintenance Cadence

| Frequency | Action |
|-----------|--------|
| **Weekly** | Quick scan: any new skills from this week's work? |
| **Monthly** | Full four-area audit (commands, rules, skills, version) |
| **After major upgrade** | Check new features, update rules for deprecated patterns |
| **After stack drift** | When commands/rules stop working as expected |

## Audit Checklist

```markdown
## Monthly Stack Audit

### Commands
- [ ] All commands have hyphenated frontmatter (`allowed-tools`, not `allowed_tools`)
- [ ] All commands have `description:` starting with action verb
- [ ] No commands reference deprecated tools or patterns
- [ ] Commands with `user-invocable: true` are ones users should trigger

### Rules
- [ ] No rule exceeds 100 lines
- [ ] Each rule has single responsibility
- [ ] No duplicate rules across global and project scope
- [ ] Version references are current
- [ ] Project-specific rules are in project, not global

### Skills
- [ ] All skills have clear `description:` field
- [ ] No duplicate or overlapping skills
- [ ] Skills >500 lines use supporting files
- [ ] Domain-specific skills use `globs:` for scoping

### Version
- [ ] Running latest Claude Code version
- [ ] New features documented in rules/skills where relevant
- [ ] Deprecated patterns removed or updated
```

## Anti-Patterns

| Anti-Pattern | Why It's Bad | Fix |
|-------------|-------------|-----|
| Never auditing | Silent degradation over months | Monthly cadence |
| Copying commands without checking frontmatter | Tool restrictions silently disabled | Verify format after copying |
| Accumulating skills without cleanup | Context bloat, slower matching | Remove duplicates, scope with globs |
| Keeping deprecated rules | Conflicting guidance to Claude | Archive or update |
| Global rules for project-specific patterns | Pollutes all project contexts | Move to project `.claude/rules/` |

---

*Previous: [Chapter 60 — Claude Code 2.1.82-2.1.83 Features](60-claude-code-2182-2183-features)*
