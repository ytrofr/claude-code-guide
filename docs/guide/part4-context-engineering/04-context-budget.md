---
layout: default
title: "Context Budget and Cost Hierarchy"
parent: "Part IV — Context Engineering"
nav_order: 4
redirect_from:
  - /docs/guide/29-branch-context-system.html
  - /docs/guide/29-branch-context-system/
  - /docs/guide/38-context-costs-and-skill-budget.html
  - /docs/guide/38-context-costs-and-skill-budget/
  - /docs/guide/39-context-separation.html
  - /docs/guide/39-context-separation/
---

# Context Budget and Cost Hierarchy

**Current as of**: Claude Code 2.1.111+.
**Related**: [Chapter 02 — Rules System](./02-rules-system.html), [Chapter 05 — Progressive Disclosure](./05-progressive-disclosure.html), [Chapter 06 — Context Governance](./06-context-governance.html)

---

## Why budget matters

Every message you send to Claude Code loads a set of always-on context: your `CLAUDE.md`, the `.claude/rules/` directory, skill descriptions, agent descriptions, and MCP tool schemas. That content is repeated on every turn. The context window is finite — 1M tokens on Opus 4.6/4.7 Max is large, but it's not free. Quality degrades above 75% utilization, and cache misses on bloated static content get expensive fast.

Anthropic's skill design guide puts it plainly:

> "The context window is a public good. Skills share the context window with everything else."

This chapter covers the cost hierarchy (what loads when), thresholds (how much is too much), branch-scoped loading (how to shed cost per task), separation patterns (global vs project), and the measurement tools that let you see exactly where tokens are going.

---

## 1. The context cost hierarchy

Push content to the cheapest tier that serves its purpose.

| Tier | Per-message cost | Use for |
|------|------------------|---------|
| **Hook (shell)** | 0 tokens | Enforcement, logging, validation |
| **Skill body** | 0 until invoked | Procedures, reference material, workflows |
| **Path-scoped rule** | Conditional on matching path | File-type patterns (`paths:` CSV format) |
| **Rule** (`~/.claude/rules/`) | Every turn (cached) | Universal invariants |
| **`CLAUDE.md`** | Every turn (cached) | Critical facts, prime position |
| **Skill description** | Every turn, subject to 2% budget | Trigger text telling Claude when to invoke |
| **Agent description** | Every turn, no formal cap | Trigger text for `Task()` spawns |
| **MCP tool schema** | Every turn per connected server | Tool name + description + parameters |

### What this means in practice

- **CLAUDE.md** is your largest fixed cost. Every line repeats every turn. Ruthlessly prune it.
- **Rules** are cached, but still counted. The 200 KB global cap exists for a reason.
- **Skill descriptions** are capped (default 2% of context ≈ 16K chars). Over-budget skills are silently excluded — no warning, no error, they just don't appear to the model.
- **Skill bodies load on invocation only** — a 500-line skill costs zero tokens until triggered.
- **Agent bodies load into a forked context** when spawned via `Task()`. They don't compete with your main conversation.
- **Hooks are free**. Shell scripts run externally, zero token impact. Prefer hooks over rules when possible.
- **MCP tools** list their schemas every message. Five servers with 70 tools is meaningful overhead — disconnect what you're not using.

### The three-level progressive disclosure model

```
Level 1: Description      (always loaded, ~100-250 chars)
   → Tells the model WHEN to use a skill or agent

Level 2: Skill body       (on invocation, ~2-8K chars)
   → Tells the model HOW to execute the task

Level 3: Supporting files (on demand via Read, unlimited)
   → Deep reference data, examples, large configs
```

A deployment skill with 500 lines of content costs about 2K tokens at Level 2 — but only when triggered. The same content in `CLAUDE.md` would cost 2K tokens on every message.

---

## 2. Thresholds

Concrete caps per file and per session. These are the numbers the governance system (Chapter 06) enforces.

| Metric | Target | Warning | Critical | Action |
|--------|--------|---------|----------|--------|
| Single rule file | <2K chars | 2K-4K | >4K (hook blocks) | Condense or split into rule + skill |
| Global rules total | <150K chars | >200K (hook blocks) | >250K | Run `/context-optimization` |
| Session always-on total | <300K chars | >300K | >400K | Audit CLAUDE.md and skills |
| Skill descriptions total | <16K chars (2% default) | Approaching | Budget exceeded | Trim or `disable-model-invocation: true` |
| Individual skill description | 80-250 chars | 250-500 | >500 | Rewrite as action verb + trigger |
| `CLAUDE.md` length | <200 lines | 200-400 | >400 | Relocate to rules |

**The 4K per-file cap** forces you to split. When a rule wants to grow beyond a single screen, extract the invariant (1-2 KB) and pointer it to a paired skill that holds the detail.

**The 200K global cap** is enforced by a `PreToolUse` hook on `Edit` and `Write`. Override with `CLAUDE_RULE_SIZE_OVERRIDE=1` in emergencies, documented in your global `CLAUDE.md` so you remember it exists.

### The skill description budget

Default: `2% of context window ≈ 16,000 characters`. Override via environment variable:

```bash
# In ~/.bashrc or ~/.zshrc
export SLASH_COMMAND_TOOL_CHAR_BUDGET=40000
```

Measure before deciding:

```bash
total=0
for f in $(find ~/.claude/skills .claude/skills -maxdepth 3 -name "SKILL.md" 2>/dev/null); do
  desc=$(sed -n '/^description:/p' "$f" | head -1 | sed 's/^description: *//;s/^"//;s/"$//')
  total=$((total + ${#desc}))
done
echo "Total: $total chars (budget: ${SLASH_COMMAND_TOOL_CHAR_BUDGET:-16000})"
```

At high utilization (>90%), adding a single skill can silently drop others. Four ways to reclaim budget:

1. **Move unused skills** to `~/.claude/skills-disabled/` (not loaded, but recoverable)
2. **Trim verbose descriptions** — target 80-150 chars, not 300+
3. **Use `disable-model-invocation: true`** for user-only skills (removes from budget entirely)
4. **Move project-specific skills** from `~/.claude/skills/` to `.claude/skills/` so they only load per-project

### Good and bad description examples

```yaml
# Good (85 chars): action verb + what + when
description: "Deploy to GCP Cloud Run. Use for staging/production deployments and traffic routing."

# Bad (240 chars): prose, details, no trigger signal
description: "This agent is a deployment specialist that handles all aspects of deploying to Google Cloud Platform Cloud Run including staging deployments, production deployments, traffic routing, health checks, timeout configuration, and rollback procedures."
```

The model needs to know **when** to pick the skill, not **how** it works internally.

---

## 3. Branch-scoped context loading

Loading every rule and every skill for every task wastes tokens. A UI branch doesn't need database patterns; a database branch doesn't need UI patterns. Branch-scoped loading cuts always-on context by 30-50% per task on mature projects.

### The manifest pattern

Each branch gets a small JSON manifest defining what to load:

```json
{
  "manifest_version": "3.0",
  "branch": "dev-data",
  "mission": "Schema migrations + query optimization",
  "domain": "database",

  "ondemand_files": {
    "branch_context": [
      "CURRENT/dev-data/ROADMAP.md"
    ],
    "domain": [
      "memory-bank/ondemand/database/quick-reference.md",
      "memory-bank/ondemand/database/patterns.md"
    ]
  },

  "estimated_tokens": {
    "global_always": 64000,
    "ondemand_domain": 11000,
    "total_max": 75000
  },

  "should_NOT_load": {
    "deployment/ci-cd.md": "Not managing CI/CD on this branch",
    "database/COMPLETE-SCHEMA.md": "Too large — use quick-reference instead"
  }
}
```

### Session-start hook: write @ imports to CLAUDE.md

The critical detail: the `@` symbol only triggers file loading **when it's in `CLAUDE.md`**. A hook that just prints `@path` to the terminal does nothing. The hook must **write** the imports into the file.

```bash
#!/bin/bash
# .claude/hooks/session-start.sh
current_branch=$(git branch --show-current 2>/dev/null)
manifest="CURRENT/$current_branch/CONTEXT-MANIFEST.json"

# Step 1: cleanup — remove old auto-loaded section so it doesn't accumulate
if [ -f "CLAUDE.md" ] && grep -q "AUTO-LOADED DOMAIN FILES" CLAUDE.md; then
    sed -i '/^## AUTO-LOADED DOMAIN FILES/,$d' CLAUDE.md
fi

# Step 2: write @ imports
if [ -f "$manifest" ]; then
    cat >> CLAUDE.md <<EOF

---

## AUTO-LOADED DOMAIN FILES (Session-Specific)

**Branch**: $current_branch
**Source**: $manifest

EOF

    jq -r '.ondemand_files | to_entries[] | .value[]' "$manifest" 2>/dev/null | while read file; do
        [ -z "$file" ] && continue
        [ -f "$file" ] && echo "@$file" >> CLAUDE.md
    done
fi
```

- ❌ `echo "@$file"` — prints to terminal, files NOT loaded
- ✅ `echo "@$file" >> CLAUDE.md` — writes to file, files ARE loaded

### Example savings

An example project with 4 active branches and a 113K-token average baseline saw per-branch savings of 30-47% after adopting branch manifests — the UI branch shed database patterns, the database branch shed UI patterns, and the knowledge branch shed deployment files. Actual numbers depend on how cleanly your domains separate; measure before and after with `/context`.

### Keep manifests focused

- Aim for **5-15 files per branch**
- Document **why** certain files are excluded via `should_NOT_load`
- Track a rough token budget (`global_always + ondemand_domain`) in the manifest itself so growth is visible

---

## 4. Separation patterns

Everything in `~/.claude/` loads for every project. Skills, rules, and `CLAUDE.md` content designed for one project become dead weight everywhere else. The fix is to push project-specific content down one level.

### The three contamination vectors

**1. Project references in global rules.** `~/.claude/rules/` should be universal. Over time, project-specific examples creep in:

```markdown
<!-- ~/.claude/rules/global/context-checking.md (BAD) -->
1. Search context: memory-bank/learned/, ULTIMATE-MINI files   # project-specific
2. Use database-context-loader-skill                            # project-specific
3. Check UNIVERSAL-SYSTEM-MASTER.md for existing APIs           # project-specific
```

Every unrelated project now loads those irrelevant references on every message.

**2. Project-specific skills at user level.** Skills in `~/.claude/skills/` load their descriptions for all projects. If 25 of 47 user-level skills only apply to one project, every other project's skill budget carries 25 irrelevant descriptions.

**3. Bloated `CLAUDE.md`.** Content useful during development gets left behind even after it's been moved to rules, skills, or on-demand files.

### Three-phase cleanup

**Phase 1 — Clean global rules.** Remove project-specific references from `~/.claude/rules/`:

```bash
# Audit: find project-specific terms in global rules
grep -rn "MyProject\|specific-tool\|api-name" ~/.claude/rules/

# Fix: replace project-specific items with generic equivalents
```

| Before (project-specific) | After (universal) |
|---------------------------|-------------------|
| `memory-bank/learned/` | `project documentation` |
| `UNIVERSAL-SYSTEM-MASTER.md` | `project system docs` |
| `Sacred Commandment X` | `single responsibility principle` |

Verify with a zero-hit grep:

```bash
grep -rn "MyProject\|specific-tool" ~/.claude/rules/   # expect: no output
```

**Phase 2 — Relocate project-specific skills.** Move them from `~/.claude/skills/` to `.claude/skills/`.

| Level | Location | Loads for | Use when |
|-------|----------|-----------|----------|
| User (global) | `~/.claude/skills/` | All projects | Skill is useful everywhere |
| Project | `.claude/skills/` | This project only | Skill is project-specific |

Decision criteria for each skill:

- Would this help in a brand-new project? → **Keep at user level**
- Does it reference project-specific APIs, schemas, or patterns? → **Move to project level**
- Does it use project-specific terminology or paths? → **Move to project level**

**Phase 3 — Trim `CLAUDE.md`.** For each section, ask:

> "Would removing this cause Claude to make mistakes?"

If the content exists in `.claude/rules/`, `memory-bank/always/`, or any other auto-loaded file, the answer is **no**. Remove it.

Common duplications to eliminate:

| `CLAUDE.md` section | Already covered by | Action |
|---------------------|-------------------|--------|
| Deployment rules | `.claude/rules/deployment/` | Remove, add 1-line reference |
| Sacred/compliance rules | `.claude/rules/sacred/` | Remove, add 1-line reference |
| Context system explanation | Auto-loaded always/ files | Remove entirely |
| Validation workflow | `.claude/rules/global/validation.md` | Remove entirely |
| Historical achievements | Move to learned/ files | Remove entirely |
| Feature status | `system-status.json` | Remove entirely |

Keep in `CLAUDE.md` only:

- Content that exists **nowhere else** (truly unique rules)
- `@` import declarations (if using file imports)
- Project identity (1-2 lines: what this project is)

### Expected savings

| Cleanup | Typical savings | Who benefits |
|---------|----------------|--------------|
| Project refs in global rules | 500-3,000 chars | All other projects |
| Project skills moved to project level | 2,000-8,000 chars of description budget | All other projects |
| `CLAUDE.md` trim | 5,000-25,000 chars | This project (every message) |

### Prevention (maintenance heuristics)

- **New rule?** "Does this apply to ALL my projects, or just this one?" Universal → `~/.claude/rules/`. Project-specific → `.claude/rules/`.
- **New skill?** "Would this help in a completely different project?" Yes → `~/.claude/skills/`. No → `.claude/skills/`.
- **Editing `CLAUDE.md`?** "Is this already in a rule file or auto-loaded file?" Yes → don't add it. No → "Would removing this cause mistakes?" No → don't add it.

Run a quarterly audit:

```bash
echo "=== Global Rules ==="
echo "Files: $(find ~/.claude/rules -name '*.md' | wc -l)"
echo "Total chars: $(find ~/.claude/rules -name '*.md' -exec cat {} + | wc -c)"

echo "=== Global Skills ==="
echo "Skills: $(find ~/.claude/skills -name 'SKILL.md' | wc -l)"

echo "=== CLAUDE.md ==="
wc -l CLAUDE.md
```

---

## 5. Measurement tools

You can't optimize what you can't measure. Two tools, one manual and one automated.

### `/context` — live session inspection

Run `/context` during any session to see current utilization: total tokens, per-surface breakdown (CLAUDE.md, skills, MCP tools, conversation), and any warnings about oversized files or excluded skills. This is the fastest way to see if a specific session is bloated.

### `/context-audit` — read-only health report

A skill that produces a full health report in 30 seconds:

- Always-on chars (CLAUDE.md + rules + MEMORY + skill descriptions)
- Per-file size warnings (>25K = warning, >40K = critical)
- md5 duplicates across rules and skills
- Project-specific terms in global rules (regex scan)
- `CLAUDE.md` length over 200 lines
- Overlap pairs (Jaccard ≥0.60) from the overlap scanner
- Broken references from the missing-refs scanner

Run on a monthly cadence and before any cleanup pass.

### Direct measurement commands

```bash
# CLAUDE.md token cost
wc -c CLAUDE.md | awk '{printf "CLAUDE.md: %d chars (~%d tokens)\n", $1, $1/4}'

# Global rules cost
find ~/.claude/rules -name "*.md" -exec cat {} + | wc -c | \
  awk '{printf "Global rules: %d chars (~%d tokens)\n", $1, $1/4}'

# Find duplicate agent names across user and project levels
comm -12 \
  <(ls ~/.claude/agents/*.md 2>/dev/null | xargs -I{} basename {} | sort) \
  <(ls .claude/agents/*.md 2>/dev/null | xargs -I{} basename {} | sort)
```

---

## 6. What to do when thresholds are exceeded

The right tool depends on the signal.

| Signal | Tool |
|--------|------|
| `/context` shows warnings about file size or excluded skills | `/context-audit` for a full report |
| Session compaction happens earlier than expected | `/context-audit`, then `/context-optimization` |
| Adding a new rule or `CLAUDE.md` section — ask: must this be always-on? | Move to a skill body or hook |
| Single file over 4K chars | Extract invariant to rule, move detail to paired skill (pointer-rule pattern) |
| Global rules total over 200K | `/context-optimization` guided 5-phase reduction |
| Monthly cadence | `/context-audit` → decide action → `/context-optimization` if needed |

The `/context-optimization` skill walks you through audit → classify → condense → relocate → verify. For heavy lifting that needs an isolated context window, delegate to the `context-optimizer` subagent.

The full governance methodology — enforcement hooks, scanners, baseline tags, regression detection, monitoring — is covered in [Chapter 06 — Context Governance](./06-context-governance.html).

---

## Checklist

Use this checklist to audit a project's context costs:

- [ ] `CLAUDE.md` under 200 lines? Move details to `.claude/rules/` or on-demand files.
- [ ] Skill descriptions total under budget? (default 16K chars, or your `SLASH_COMMAND_TOOL_CHAR_BUDGET`)
- [ ] Each skill description under 250 chars? Action verb + trigger format?
- [ ] User-only skills marked `disable-model-invocation: true`?
- [ ] Heavy skills using `context: fork` for isolation?
- [ ] Skill bodies under 500 lines? Large data in supporting files?
- [ ] Agent descriptions short and action-focused?
- [ ] No same-name agents at user + project level?
- [ ] Meta-enforcement via `.claude/rules/` instead of agents?
- [ ] Only connected MCP servers you actively use?
- [ ] Zero project-specific references in global rules?
- [ ] Branch manifests present for branches with distinct domains?

---

## Key takeaways

1. **Push content to the cheapest tier.** Hooks are free, skill bodies are free until invoked, rules cost every turn.
2. **Rules cap is 4K per file, 200K total.** The governance hook enforces it. Override only in emergencies.
3. **Skill description budget is 16K chars default.** Exceed it and skills silently disappear. Override via `SLASH_COMMAND_TOOL_CHAR_BUDGET`.
4. **Branch manifests cut per-task context** by 30-50% on mature projects with distinct domains.
5. **Global is shared cost.** Everything in `~/.claude/` loads for every project. Keep it universal.
6. **The `CLAUDE.md` gate test**: "Would removing this cause Claude to make mistakes?" If not, remove it.
7. **Measure before optimizing.** `/context` for live sessions, `/context-audit` for the full picture.

---

**Next**: [Chapter 05 — Progressive Disclosure](./05-progressive-disclosure.html)
**Related**: [Chapter 06 — Context Governance](./06-context-governance.html), [Chapter 07 — Skill Lifecycle](./07-skill-lifecycle.html)
