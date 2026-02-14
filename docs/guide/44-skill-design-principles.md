---
layout: default
title: "Skill Design Principles - Anthropic's Official Patterns"
description: "Design Claude Code skills using Anthropic's official principles: degrees of freedom, progressive disclosure, scripts as black boxes, description-is-everything, anti-clutter, and negative scope."
---

# Chapter 44: Skill Design Principles

Previous chapters covered skill mechanics -- frontmatter fields, activation, budget. This chapter covers the _philosophy_ of skill design: Anthropic's principles for creating skills that are effective, maintainable, and context-efficient.

**Purpose**: Design better skills using Anthropic's official design principles
**Source**: Anthropic skill-creator guide (skills repo) + production experience
**Difficulty**: Intermediate
**Time**: 30 minutes to understand, ongoing application

---

## Founding Principle: The Context Window Is a Public Good

> _"The context window is a public good. Skills share the context window with everything else. Default assumption: Claude is already very smart. Only add context Claude doesn't already have."_
>
> -- Anthropic skill-creator guide

This principle should guide every skill design decision:

- **Don't teach Claude things it already knows** (general programming, common patterns)
- **Do teach Claude things specific to your project** (custom patterns, non-obvious conventions)
- **Every line has a cost** -- it competes with the user's actual work for context space

### Self-Test

For each line in your skill, ask: "Would removing this cause mistakes?" If the answer is no, the line is wasting context.

---

## Degrees of Freedom Framework

Skills exist on a spectrum from "strict script" to "open guidance." Choose the right level of freedom for the task:

### High Freedom

**When**: Multiple valid approaches, creative tasks.

```markdown
## Design Patterns

Consider the user's goals and project structure.
Choose the approach that best fits their architecture.
Common patterns include: [list]
```

The skill provides general guidance but trusts Claude's judgment for specifics.

**Examples**: Frontend design, code review, architecture planning.

### Medium Freedom

**When**: Preferred pattern exists but flexibility is needed.

```markdown
## Deployment

1. Build the project
2. Run pre-deploy checks: `npm test && npm run lint`
3. Deploy using the project's deployment tool
4. Verify health endpoint responds
```

The skill defines the workflow but allows flexibility in implementation details.

**Examples**: Deployment workflows, testing procedures, migration paths.

### Low Freedom

**When**: Fragile or error-prone operations. A narrow bridge with cliffs on both sides.

```markdown
## Database Migration

Run EXACTLY this command:
\`\`\`bash
pg_dump -h SOURCE --no-owner --exclude-table=audit_log | psql -h TARGET
\`\`\`
DO NOT modify the flags. DO NOT add --data-only. DO NOT skip --exclude-table.
```

The skill provides explicit commands with guardrails. Deviation causes failure.

**Examples**: Database operations, financial calculations, security-sensitive operations.

### Decision Guide

Think of Claude as exploring a path:

- **Open field** (high freedom): Many routes to the destination. General guidance suffices.
- **Forest trail** (medium freedom): Follow the marked path, but minor detours are fine.
- **Narrow bridge** (low freedom): One safe path. Guardrails required. Specific steps mandatory.

---

## Description Is Everything

The `description` field is the **only** mechanism for skill activation. If the description doesn't match the user's intent, the skill won't activate -- no matter how good its content is.

### Anatomy of a Good Description

```yaml
description: "Deploy to GCP Cloud Run with traffic routing verification. Use when deploying to staging or production, checking deployment status, or routing traffic to new revisions."
```

**Components**:

1. **Action verb** ("Deploy") -- what the skill does
2. **Specifics** ("GCP Cloud Run with traffic routing") -- distinguishes from similar skills
3. **"Use when..."** clause -- explicit activation scenarios
4. **Natural language triggers** -- words users actually say

### Common Mistakes

| Mistake            | Example                                     | Problem                                   |
| ------------------ | ------------------------------------------- | ----------------------------------------- |
| Too vague          | "Helps with database stuff"                 | Matches everything, distinguishes nothing |
| Too technical      | "PostgreSQL pgvector HNSW index management" | Users don't say these words               |
| Missing "Use when" | "Database operations for LIMOR AI"          | No activation guidance                    |
| Internal details   | "Uses pool.query with employee_id pattern"  | Implementation, not activation            |

### The 1024-Character Budget

Descriptions are capped at 1024 characters. Spend every character on activation quality, not feature lists. The skill BODY describes features -- the description describes WHEN to use it.

---

## Negative Scope

For skills that overlap with others, add explicit "Do NOT use" guidance to prevent false activation:

```yaml
description: "Debug production issues with decision tree routing. Use when encountering errors or investigating data gaps. Do NOT use for known patterns already covered by timezone, field-sync, or deployment skills."
```

**When to add negative scope**:

- Two skills cover similar domains (database-master vs database-schema)
- A general skill overlaps with specialists (troubleshooting-master vs deployment-troubleshooting)
- Users frequently trigger the wrong skill

**Pattern**: Add "Do NOT use for/when..." after the "Use when..." clause.

---

## Progressive Disclosure (Three Levels)

Skills should load context progressively, not all at once:

### Level 1: Description (Every Message)

```yaml
description: "Deploy to GCP Cloud Run. Use when deploying to staging/production."
```

~100-200 characters. Loaded every message. Cost: minimal.

### Level 2: Skill Body (On Activation)

```markdown
# Deployment Skill

## Quick Start

1. Build and deploy: `gcloud run deploy ...`
2. Route traffic: `gcloud run services update-traffic ...`
3. Verify: `curl https://service-url/health`

## Common Issues

- Traffic not routing → run update-traffic command
- Timeout → set --timeout=600
```

~200-500 lines. Loaded only when the skill activates. Cost: one-time per activation.

### Level 3: Supporting Files (On Demand)

```
skill-directory/
  SKILL.md                    # Level 2 (500 lines max)
  references/
    advanced-deployment.md    # Level 3 (loaded via Read tool)
    rollback-procedures.md    # Level 3 (loaded via Read tool)
    environment-parity.md     # Level 3 (loaded via Read tool)
```

Unlimited size. Loaded only when the skill explicitly reads them. Cost: zero until needed.

### Token Math

| Level | When Loaded   | Typical Size | Context Cost         |
| ----- | ------------- | ------------ | -------------------- |
| 1     | Every message | ~150 chars   | ~37 tokens/message   |
| 2     | On activation | ~2,000 chars | ~500 tokens (once)   |
| 3     | On demand     | ~8,000 chars | ~2,000 tokens (rare) |

A skill with 3 reference files costs **37 tokens per message** when inactive, not 2,500+.

---

## Scripts as Black Boxes

Skills that reference executable scripts should NOT read the script source into context:

```markdown
## Usage

Run `scripts/validate.sh --help` to see options.

Common commands:

- `scripts/validate.sh --quick` -- fast validation
- `scripts/validate.sh --full` -- comprehensive check
- `scripts/validate.sh --fix` -- auto-fix issues

DO NOT read the script source. Run with --help instead.
```

**Why**: A 200-line bash script = ~800 tokens of implementation details that Claude doesn't need. The `--help` output gives Claude everything it needs to use the script correctly.

**Rule**: All scripts referenced by skills MUST support `--help` for self-documentation.

---

## Anti-Clutter Rules

Keep skill directories clean. Only include files that serve a purpose:

### Allowed Files

```
skill-directory/
  SKILL.md          # Required: main skill file
  references/       # Optional: detailed content
  scripts/          # Optional: executable scripts
  assets/           # Optional: templates, configs
```

### Forbidden Files

Do NOT create these in skill directories:

- `README.md` -- SKILL.md IS the readme
- `INSTALLATION_GUIDE.md` -- installation belongs in SKILL.md
- `QUICK_REFERENCE.md` -- the skill IS the quick reference
- `CHANGELOG.md` -- use git history for changes
- `TODO.md` -- use issue tracker

**Why**: Extra files in skill directories are noise. They don't load automatically, aren't referenced, and confuse maintenance. Every file should be either the skill itself or a supporting file explicitly referenced by the skill.

### References One Level Deep

All reference files should be directly reachable from SKILL.md. No nested subdirectories:

```
# GOOD: One level deep
references/
  advanced.md       # SKILL.md links to this
  troubleshooting.md

# BAD: Nested references
references/
  advanced/
    patterns/
      edge-cases.md  # Too deep, will be forgotten
```

**Rule**: If a file is more than one directory level from SKILL.md, it will never be found. Keep references flat.

---

## Subagent "Fresh Eyes" QA

For skills that generate complex output, add a verification step using a subagent:

```markdown
## Post-Generation Verification

After generating output, spawn a verification subagent:

Task(subagent_type: "Explore",
prompt: "Verify the generated [output] is correct and consistent.
Check for: [specific things to verify].")
```

**Why this works**: The generating skill has been "staring at the code" and sees what it expects. A fresh subagent has no bias and catches obvious mistakes.

**When to recommend**: Multi-file changes, generated configurations, deployment scripts, database migrations.

---

## Skill Size Guidelines

| Skill Size | Lines   | Action                                 |
| ---------- | ------- | -------------------------------------- |
| Compact    | <100    | Ideal for focused patterns             |
| Standard   | 100-300 | Most skills land here                  |
| Large      | 300-500 | Use progressive disclosure             |
| Over limit | >500    | MUST split into SKILL.md + references/ |

Claude Code enforces a 500-line limit on skill files. But even within 500 lines, prefer smaller skills that do one thing well.

---

## Checklist: Before Creating a Skill

- [ ] **Frequency**: Is this pattern used 20+ times per year?
- [ ] **Time savings**: Does it save >1 hour per use?
- [ ] **Repeatability**: Is the pattern consistent (not one-off)?
- [ ] **No duplicate**: Does an existing skill cover this? (Check first!)
- [ ] **Not foundational**: If it's a universal rule, put it in `.claude/rules/` instead
- [ ] **Description quality**: Action verb + specifics + "Use when..." + natural language
- [ ] **Negative scope**: Added "Do NOT use when..." if overlaps exist
- [ ] **Under 500 lines**: Large content in references/ subdirectory
- [ ] **No clutter**: Only SKILL.md + references/ + scripts/ + assets/
- [ ] **Freedom level**: Correct guardrail level for the task's risk

---

**Previous**: [43: Claude Agent SDK](43-claude-agent-sdk.md)
