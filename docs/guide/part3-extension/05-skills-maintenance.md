---
layout: default
title: "Skills Maintenance"
parent: "Part III — Extension"
nav_order: 5
redirect_from:
  - /docs/guide/35-skill-optimization-maintenance.html
  - /docs/guide/35-skill-optimization-maintenance/
  - /docs/guide/61-stack-audit-maintenance.html
  - /docs/guide/61-stack-audit-maintenance/
---

# Skills Maintenance

Authoring a skill (covered in [Skills Authoring](04-skills-authoring.md)) is the easy part — keeping a library of 50, 100, or 200 skills healthy over years is the hard part. This chapter covers the maintenance side: staleness detection, stack audits, description drift, promotion, and automation.

Lifecycle policy (90/180-day SLAs, activation tracking data source) is at [Skill Lifecycle](../part4-context-engineering/07-skill-lifecycle.md).

---

## Why Audit Your Stack?

Claude Code configurations grow organically. Skills accumulate, rules are added, commands get copied with subtle errors. Without periodic audits, your setup silently degrades:

- **Commands with wrong frontmatter** silently ignore tool restrictions (security risk)
- **Outdated rules** reference features that no longer exist
- **Duplicate skills** waste context tokens on redundant descriptions
- **Version drift** means you miss new features that could save hours

One real-world audit found 7 of 9 commands had `allowed_tools` (underscored) instead of `allowed-tools` (hyphenated). Tool restrictions had been silently disabled for months.

---

## The Problem: Skill Rot

As a library grows, the following patterns emerge:

- **Broken references**: skills deleted but still listed in branch/top-N configs
- **Stubs**: skills that just redirect to "master skills" — they still cost tokens
- **Bloated skills**: 400-500 line skills that could be 150
- **Overlap**: multiple skills covering the same workflow
- **Outdated frontmatter**: non-standard fields Claude Code ignores
- **Description drift**: the skill body has evolved, but the description no longer matches

One production audit found 3 broken refs, 1 stub, and 5 oversized skills in a single branch's top-10.

---

## Staleness Signals

### Activation tracking

The most direct signal is: *has this skill actually been used?* A pre-prompt hook writes each activation to `~/.claude/metrics/skill-activations.jsonl` with timestamp and skill name. Query it for the last-used date per skill.

If a skill hasn't been invoked in 90 days, it's an archive candidate. 180 days without invocation — delete candidate, unless the skill serves reference-only purpose.

Full SLA table and data-source details: [Skill Lifecycle](../part4-context-engineering/07-skill-lifecycle.md).

### Description drift

A skill whose body has evolved past its description will never activate. Run a description-vs-body reality check quarterly:

```bash
for skill in ~/.claude/skills/*/SKILL.md; do
  desc=$(grep -A1 "^description:" "$skill" | head -1 | cut -d: -f2- | head -c 100)
  # Inspect first 30 body lines vs the description — does the skill still do what the description says?
  echo "=== $(basename $(dirname $skill)) ==="
  echo "Desc: $desc"
  sed -n '10,40p' "$skill" | head -10
done
```

If the body talks about X but the description only mentions Y, update the description — or split the skill.

### Broken references

Skills listed in branch configs, settings, or other skills' "see also" sections that no longer exist. These print `BROKEN:` on startup if your system checks them.

---

## The Stack Audit — Four Areas

A stack audit is broader than just skills: it checks skills, rules, hooks, MCP configs, and commands for health. Run monthly, or after major upgrades.

### 1. Command / user-invocable skill compliance

Check that all user-invocable skills use correct frontmatter format:

```bash
# Find wrong field names (underscored instead of hyphenated) — must return 0 results
grep -rl 'allowed_tools' ~/.claude/skills/ 2>/dev/null
grep -rl 'user_invocable' ~/.claude/skills/ 2>/dev/null

# Find JSON array format (should be comma-separated) — must return 0 results
grep -rl 'allowed-tools:.*\[' ~/.claude/skills/ 2>/dev/null
```

Correct format:

```yaml
---
description: Start with action verb. Include "Use when..." clause.
allowed-tools: Read, Bash, Grep
user-invocable: true
---
```

Wrong format (silently ignored):

```yaml
allowed_tools: ["Read", "Bash", "Grep"]   # Underscored key + JSON array
```

### 2. Rules inventory

```bash
# Count rules by category
find ~/.claude/rules/ -name "*.md" | sed 's|.*/rules/||' | cut -d/ -f1 | sort | uniq -c | sort -rn

# Find potential duplicates (similar filenames)
find ~/.claude/rules/ -name "*.md" -exec basename {} \; | sort

# Check for outdated version references
grep -rl '2\.1\.[0-6]' ~/.claude/rules/ 2>/dev/null
```

Health indicators:

- Global rules (`~/.claude/rules/`): universal patterns for all projects
- Project rules (`.claude/rules/`): project-specific conventions
- No rule should exceed 100 lines
- Each rule has single responsibility

### 3. Skills inventory

```bash
# Count skills
ls -d ~/.claude/skills/*/ 2>/dev/null | wc -l

# Find skills missing required description field
for d in ~/.claude/skills/*/; do
  if ! grep -q '^description:' "$d/SKILL.md" 2>/dev/null; then
    echo "Missing description: $d"
  fi
done

# Find oversized skills (>500 lines)
wc -l ~/.claude/skills/*/SKILL.md 2>/dev/null | sort -rn | head -5

# Find non-standard frontmatter fields
grep -r "^priority:\|^agent:" ~/.claude/skills/*/SKILL.md 2>/dev/null
```

Skill hygiene:

- Every skill needs a clear `description:` — it is how Claude matches skills to tasks
- Skills >500 lines should use supporting files (`references/*.md`)
- Remove skills that duplicate built-in Claude Code capabilities
- No skill should have `priority:` or `agent:` (without `context: fork`) — those fields are ignored

### 4. Version currency

```bash
# Check Claude Code version
claude --version

# Compare against latest documented features
# If your version > the guide's latest chapter, some features may be undocumented
```

---

## 6-Step Optimization Workflow

When an audit surfaces issues, walk through the following steps.

### Step 1 — Audit

```bash
# Find oversized skills (>300 lines)
find ~/.claude/skills -name "SKILL.md" \
  -exec sh -c 'l=$(wc -l < "$1"); [ "$l" -gt 300 ] && echo "$l $1"' _ {} \; \
  | sort -rn

# Check for non-standard frontmatter fields
grep -r "^priority:\|^agent:" ~/.claude/skills/*/SKILL.md 2>/dev/null

# Check for broken top-N references (if your config tracks them)
# Iterate your config and test each referenced skill exists as a directory
```

### Step 2 — Merge overlapping skills

When two skills share >70% content overlap, merge them.

**Merge pattern:**

1. Create a new skill with a combined name
2. Keep the best Quick Start from either source
3. Keep ALL Anti-Patterns / Failed Attempts sections from both
4. Target <300 lines
5. **Delete** both old directories entirely (`rm -rf`). Never deprecate.

Example: `context-testing-workflow` (178 lines) + `context-preservation-enhancement` (335 lines) → `context-preservation` (234 lines). Net: 279 lines removed, 1 skill instead of 2.

**Never deprecate**: a skill with a `DEPRECATED` header still costs ~100 tokens every time Claude scans the skill index. Delete it.

### Step 3 — Fix frontmatter

Verify for each skill:

- Field order: `name` → `description` → optional fields
- `description` contains "Use when..."
- No non-standard fields (`priority`, `agent` without fork)
- Hyphenated keys (`allowed-tools`, `user-invocable`, `disable-model-invocation`)

### Step 4 — Trim oversized skills

**Target**: under 300 lines (Anthropic scans ~100 tokens per skill description for routing).

Remove:

| Remove | Why |
|--------|-----|
| Body "Activation Triggers" section | Duplicates frontmatter |
| 5+ verbose examples | 1 complete example suffices |
| Duplicate Evidence sections | Keep single Evidence table |
| System file listings | Already in rules / core patterns |

Condense:

| Transform | Technique |
|-----------|-----------|
| Multi-paragraph prose | Convert to table |
| Full code blocks | Method signatures only |
| Long explanations | YAML decision trees |
| Multiple similar examples | 1 example + "same pattern for X" |

**Never remove**: Quick Start, Anti-Patterns, Evidence (metrics/dates), Decision criteria.

Real results from one production trim pass:

| Skill | Before | After | Reduction |
|-------|--------|-------|-----------|
| ai-quality-validation | 444 | 148 | 67% |
| ai-pipeline-debugging | 471 | 188 | 60% |
| modular-rag-selection | 365 | 219 | 40% |
| sql-validation | 355 | 160 | 55% |
| query-table-selection | 315 | 129 | 59% |
| **Total** | **1,950** | **844** | **57%** |

### Step 5 — Curate top-N (if applicable)

If your project uses branch-specific or scope-specific skill loading, update the config to:

- Align skills with the scope's mission
- Replace broken references immediately
- Remove stubs / redirect skills
- Prioritize high-impact skills

### Step 6 — Rebuild cache & verify

```bash
# Rebuild skill cache if your setup uses one
rm -f ~/.claude/cache/skill-index-hybrid.txt

# Rerun whatever hook builds the index (depends on setup)
# Then verify cache line count matches expected
wc -l ~/.claude/cache/skill-index-hybrid.txt
```

Run activation tests for any merged or renamed skills — try a keyword phrase and verify the skill triggers.

---

## Description Drift — The Silent Killer

Drift happens when:

- A skill starts as "Deploy to Cloud Run"
- Someone adds a section on traffic routing
- Another edit adds rollback procedures
- The description still says "Deploy to Cloud Run"

Users ask about rollback — the skill doesn't activate, because the description doesn't mention rollback. The content is there, but invisible.

**Fix cadence**: quarterly. Read the first 40 lines of each skill body; if it no longer matches the description, update one or the other (or split the skill).

---

## Promotion — Project to Global

A skill lives in a project's `.claude/skills/` until it proves itself universally useful. Promotion criteria:

- Used in 2+ projects for 30+ days
- No project-specific file paths in content
- Description contains explicit trigger clause ("Use when...")

When promoting:

1. Copy the skill directory from `.claude/skills/` to `~/.claude/skills/`
2. Strip project-specific references (paths, service names, domain terms)
3. Generalize any examples
4. Test activation from a fresh session
5. Delete the project-local copy

Reverse (global → project) when a skill's usage narrows to a single project. Description quality gate: without "Use when..." trigger text in `description` or `when_to_use`, Claude cannot auto-invoke the skill.

---

## Anti-Patterns

### 1. Deprecating instead of deleting

**Wrong**: add "DEPRECATED" header, keep the file around
**Problem**: still consumes tokens every skill-index scan (~100 tokens)
**Correct**: `rm -rf ~/.claude/skills/old-skill/`

### 2. Over-trimming

**Wrong**: remove Quick Start to save lines
**Problem**: skill becomes useless without actionable content
**Correct**: remove redundancy, keep essential sections

### 3. Forgetting cache rebuild

**Wrong**: edit skill files, expect changes immediately
**Problem**: pre-prompt hook uses a cached index
**Correct**: clear cache after changes if your setup caches the index

### 4. Orphaned references

**Wrong**: delete a skill but forget the top-N config
**Problem**: config loads show `BROKEN: skill-name`
**Correct**: update all references before deleting

### 5. Global rules for project-specific patterns

**Wrong**: put a project-specific rule in `~/.claude/rules/`
**Problem**: pollutes all project contexts
**Correct**: keep it in the project's `.claude/rules/`

---

## Automation

Several skills/commands automate parts of the workflow:

| Command / Skill | Purpose |
|-----------------|---------|
| `/audit-stack` (if installed) | Run the 4-area audit end-to-end |
| `/skill-metrics` | Report activation counts from `~/.claude/metrics/skill-activations.jsonl` |
| `/weekly-review` | Weekly cron: flag stale skills, report new patterns, suggest promotions |
| `/memory-defrag` | Reorganize Basic Memory notes; related to skill lifecycle because memory notes often become skills |
| `/document` | Three-level analysis (machine / project / branch) to discover documentation and skill opportunities |
| `/retrospective` | Extract a skill from session learnings — five-question structured pipeline |

### The `/document` three-level pattern

| Level | Scope | What it finds |
|-------|-------|---------------|
| **Machine** | `~/.claude/` (all projects) | Global rules, universal skills, machine-wide patterns |
| **Project** | `.claude/` (all branches) | Project-specific rules, shared conventions |
| **Branch** | Current branch only | Branch-specific context, current work patterns |

Six mandatory checks per level: Rules, Skills, Blueprints, Roadmap, Project Root, Memory. A mandatory pause before Phase 3 lets you approve or reject each suggestion — prevents creating overlapping skills or wrong-scope rules.

### The `/retrospective` five-question pipeline

1. **What problem did you solve?** → becomes the skill's `description`
2. **What approaches failed?** → becomes the Anti-Patterns section
3. **What approach worked?** → becomes the core skill content
4. **What trigger keywords should activate this?** → informs description wording
5. **What should the skill be named?** → becomes the directory name

Run `/retrospective` after: solving a non-trivial bug (>30 min debugging), discovering an unexpected system behavior, building a reusable pattern, session end if you learned something transferable.

---

## Maintenance Cadence

| Frequency | Action |
|-----------|--------|
| **Weekly** | Quick scan: any new skills from this week's work? |
| **Monthly** | Full 4-area audit (commands, rules, skills, version) + security scan |
| **Quarterly** | Trim oversized skills, run description-drift check |
| **After major upgrade** | Check new features, update rules for deprecated patterns |
| **After stack drift** | When commands/rules stop working as expected |
| **After skill deletion** | Rebuild cache + verify activation tests |
| **After merge** | Run activation tests on merged skills |

---

## Audit Checklist

```markdown
## Monthly Stack Audit

### Commands / User-Invocable Skills
- [ ] All use hyphenated frontmatter (`allowed-tools`, not `allowed_tools`)
- [ ] All have `description:` starting with action verb
- [ ] None reference deprecated tools or patterns
- [ ] `user-invocable: true` is set only on skills users should trigger

### Rules
- [ ] No rule exceeds 100 lines
- [ ] Each rule has single responsibility
- [ ] No duplicate rules across global and project scope
- [ ] Version references are current
- [ ] Project-specific rules are in project, not global

### Skills
- [ ] All skills have clear `description:` field with "Use when..."
- [ ] No duplicate or overlapping skills
- [ ] Skills >500 lines use supporting `references/`
- [ ] Description matches body (no drift)
- [ ] No broken references in top-N configs

### Version
- [ ] Running latest Claude Code version
- [ ] New features documented in rules/skills where relevant
- [ ] Deprecated patterns removed or updated
```

---

## Security Scanning

Structural audits catch wrong-field issues. Security scans catch active risks:

```bash
npx ecc-agentshield scan ~/.claude/
npx ecc-agentshield scan ~/.claude/ | tee ~/.claude/logs/agentshield-$(date +%Y-%m-%d).log
```

What it catches:

- Hardcoded API keys in CLAUDE.md, skills, or settings
- Overly broad permissions (`Bash(docker *)`, `Bash(curl *)`)
- Hook scripts with `rm -f`, `git config --global`, or output suppression
- MCP servers inheriting full environment (secret leakage)
- Unversioned MCP packages (`@latest` = supply-chain risk)

Add to the monthly checklist:

```markdown
### Security
- [ ] Run `npx ecc-agentshield scan ~/.claude/`
- [ ] All critical/high findings resolved
- [ ] Deny list covers `chmod 777`, `ssh`, `> /dev/*`
- [ ] No MCP servers using `@latest`
```

---

## See Also

- [Skills Authoring](04-skills-authoring.md) — frontmatter, body, testing
- [Skill Lifecycle](../part4-context-engineering/07-skill-lifecycle.md) — 90/180-day SLA, activation data source
- [Slash Commands (now Skills)](07-slash-commands.md) — invocation and legacy migration
