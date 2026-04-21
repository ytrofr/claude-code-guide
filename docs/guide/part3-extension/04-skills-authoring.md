---
layout: default
title: "Skills Authoring"
parent: "Part III — Extension"
nav_order: 4
redirect_from:
  - /docs/guide/28-skill-optimization-patterns.html
  - /docs/guide/28-skill-optimization-patterns/
  - /docs/guide/44-skill-design-principles.html
  - /docs/guide/44-skill-design-principles/
  - /docs/guide/58-claude-skills-cookbook-patterns.html
  - /docs/guide/58-claude-skills-cookbook-patterns/
---

# Skills Authoring

A skill is a folder on disk with one required file — `SKILL.md` — and optional supporting files (reference docs, scripts, templates). Since Claude Code 2.1.88, the `commands/` directory was merged into skills; any `/<name>` slash is now just a skill with `user-invocable: true`. This chapter covers how to author a skill from scratch: frontmatter, body, progressive disclosure, and testing.

Maintenance (staleness, archive/delete, promotion) lives in [Skills Maintenance](05-skills-maintenance.md). Lifecycle policy (90/180 day SLAs, activation tracking) lives in [Skill Lifecycle](../part4-context-engineering/07-skill-lifecycle.md).

---

## The Founding Principle

> The context window is a public good. Skills share the context window with everything else. Default assumption: Claude is already very smart. Only add context Claude doesn't already have.
>
> — Anthropic skill-creator guide

Every line in a skill costs tokens. For each line, ask: *would removing this cause mistakes?* If not, the line is wasting context. Skills should teach Claude project-specific conventions, non-obvious workflows, and fragile operations — not general programming.

---

## Skill Directory Layout

```
~/.claude/skills/my-skill/         # Global (all projects)
.claude/skills/my-skill/           # Project-scoped
  SKILL.md                         # REQUIRED
  references/                      # Optional, loaded on-demand
    detailed-patterns.md
    api-reference.md
  scripts/                         # Optional executables
    validate.sh
  assets/                          # Optional templates/configs
    template.json
```

**Allowed subdirs**: `references/`, `scripts/`, `assets/`. **Never add**: `README.md` (SKILL.md is the readme), `CHANGELOG.md` (use git), `TODO.md`, `INSTALLATION_GUIDE.md`. Extra files are noise.

All reference files must be one level deep — nested `references/advanced/patterns/edge-cases.md` will never be found.

---

## Frontmatter Fields

Frontmatter is YAML between `---` delimiters at the top of `SKILL.md`. All fields are optional except — in practice — `description`, which is how Claude decides when to activate the skill.

| Field | Purpose | Notes |
|-------|---------|-------|
| `name` | Skill identifier | Optional; directory name used if omitted. Kebab-case, max 64 chars |
| `description` | **Activation trigger** | Up to 1536 chars (CC 2.1.105+); 250 chars pre-2.1.105. MUST include "Use when..." clause |
| `when_to_use` | Alternate trigger field | Combined with `description` for matching; same char budget |
| `user-invocable` | Show in `/slash` menu | Default `true`. Set `false` for background-only skills |
| `disable-model-invocation` | Force manual invocation only | Default `false`. Set `true` for side-effect skills (deploy, send, delete) |
| `effort` | Override session effort | `low` / `medium` / `high` (CC 2.1.80+). CC 2.1.111 adds `xhigh` and `max` |
| `model` | Force a specific model | `haiku` / `sonnet` / `opus`. Use haiku for cheap classification |
| `allowed-tools` | Restrict available tools | Comma-separated list. E.g. `Read, Grep, Glob` for read-only skills |
| `context` | Run in isolated subagent | `fork` value only. Prevents context pollution |
| `agent` | Route to specialized agent | Only meaningful with `context: fork` |
| `hooks` | Skill-scoped hooks | Run only when this skill is active |
| `argument-hint` | User hint for arguments | Shown in slash-command UI when user types `/skill-name ` |
| `paths` | Path-scoped loading | CSV string (see gotcha below) |

### Correct field naming

Frontmatter keys are **hyphenated**, never underscored. Underscored variants are silently ignored:

```yaml
# CORRECT
allowed-tools: Read, Bash, Grep
user-invocable: true

# WRONG — silently ignored, restrictions don't apply
allowed_tools: [Read, Bash, Grep]
user_invocable: true
```

A March 2026 audit found 7 of 9 commands used the underscored form — tool restrictions had been disabled for months without anyone noticing.

### The `paths:` CSV gotcha

Path-scoped skills only load when the user is working with files matching a pattern. The field parser has a bug (Claude Code issues #13905/#17204) where YAML array format fails silently — you must use a quoted CSV string:

```yaml
# CORRECT — quoted CSV, parses reliably
paths: "**/*.py, **/*.pyi, src/**"

# WRONG — YAML array, silently empty
paths:
  - "**/*.py"
  - "**/*.pyi"
```

---

## Description: The Only Activation Mechanism

The `description` field is the one and only mechanism for skill activation. If the description doesn't match what the user is trying to do, the skill won't activate — regardless of how good the body is.

### Anatomy of a good description

```yaml
description: "Deploy to Cloud Run with traffic routing verification. Use when deploying to staging or production, checking deployment status, or routing traffic to new revisions."
```

Four components:

1. **Action verb** (`Deploy`) — what the skill does
2. **Specifics** (`Cloud Run with traffic routing`) — distinguishes from similar skills
3. **"Use when..." clause** — explicit activation scenarios
4. **Natural-language triggers** — words users actually say

### Common mistakes

| Mistake | Example | Why it fails |
|---------|---------|--------------|
| Too vague | `Helps with database stuff` | Matches everything, distinguishes nothing |
| Too technical | `PostgreSQL pgvector HNSW index management` | Users don't say these words |
| Missing "Use when" | `Database operations for the app` | No activation guidance |
| Internal details | `Uses pool.query with employee_id pattern` | Implementation, not activation |

### Description budget: 250 → 1536 chars

- **Pre-CC 2.1.105**: descriptions capped at 250 characters. Every character counted.
- **CC 2.1.105+**: cap raised to 1536 characters. The combined `description` + `when_to_use` budget is 1536.

More room does not mean more prose. Spend characters on activation quality, not feature lists — the body describes features, the description describes **when to use**.

### Negative scope

When two skills overlap, add explicit "Do NOT use" guidance:

```yaml
description: "Debug production issues with decision tree routing. Use when encountering errors or investigating data gaps. Do NOT use for known patterns already covered by timezone, field-sync, or deployment skills."
```

Add negative scope when: two skills cover similar domains, a general skill overlaps with specialists, or users frequently trigger the wrong skill.

---

## Degrees of Freedom

Skills exist on a spectrum from strict script to open guidance. Choose the right level for the task's risk.

### High freedom — open field

Multiple valid approaches, creative tasks. General guidance, trust Claude's judgment.

```markdown
## Design Patterns

Consider the user's goals and project structure.
Choose the approach that best fits their architecture.
Common patterns include: [list]
```

Examples: frontend design, code review, architecture planning.

### Medium freedom — forest trail

Preferred pattern exists, but flexibility is needed. Define the workflow, allow flexibility in implementation.

```markdown
## Deployment

1. Build the project
2. Run pre-deploy checks: `npm test && npm run lint`
3. Deploy using the project's deployment tool
4. Verify health endpoint responds
```

Examples: deployment workflows, testing procedures, migration paths.

### Low freedom — narrow bridge

Fragile or error-prone operations. Explicit commands, strict guardrails, deviation causes failure.

````markdown
## Database Migration

Run EXACTLY this command:

```bash
pg_dump -h SOURCE --no-owner --exclude-table=audit_log | psql -h TARGET
```

DO NOT modify the flags. DO NOT add --data-only. DO NOT skip --exclude-table.
````

Examples: database operations, financial calculations, security-sensitive work.

**Decision**: open field (many routes) → high. Forest trail (marked path, minor detours fine) → medium. Narrow bridge (one safe path, cliffs either side) → low.

---

## Body Structure

A typical SKILL.md body follows this shape:

```markdown
# Skill Name

One-line purpose statement.

## When to Use

Bullet list of activation scenarios (redundant with description but helps humans).

## Quick Start

Minimal working example — 3-5 steps.

## How It Works

Brief explanation of the mechanism (only if non-obvious).

## Examples

1-2 complete examples. Don't repeat variations — use "same pattern for X" instead.

## Anti-Patterns

What NOT to do and why. Preserves hard-won lessons.

## See Also

Links to related skills, rules, or external docs.
```

### Size guidelines

| Size | Lines | Action |
|------|-------|--------|
| Compact | <100 | Ideal for focused patterns |
| Standard | 100-300 | Most skills land here |
| Large | 300-500 | Use progressive disclosure (below) |
| Over limit | >500 | MUST split into SKILL.md + references/ |

Claude Code enforces a 500-line limit on skill bodies.

---

## Progressive Disclosure (Three Levels)

Skills load context progressively — description on every message, body on activation, references only when Claude reads them.

### Level 1 — Description

```yaml
description: "Deploy to Cloud Run. Use when deploying to staging/production."
```

Loaded every message for activation routing. Cost: ~37 tokens/message. Keep under 250 chars when possible.

### Level 2 — Body

SKILL.md body. Decision tree and quick reference. Loaded once when the skill activates. Cost: ~500 tokens one-time per activation.

### Level 3 — References

Detailed content in `references/*.md`. Unlimited size. Loaded only when Claude explicitly reads the file. Cost: zero until needed.

### When to split

Apply the split when a skill exceeds 300 lines. Before/after examples from production:

| Skill | Before | After body | References | Reduction |
|-------|--------|------------|------------|-----------|
| context-engineering | 504 | 85 | 216 | 83% |
| mcp-usage-patterns | 401 | 77 | 180 | 81% |
| best-practices | 399 | 100 | 195 | 75% |

Rules for splitting:

- Body must be self-sufficient for the 80% case; references are for edge cases
- Never put the decision tree in references — it is needed on every activation
- Each reference file should be independently useful, not fragments of one document
- One level deep only

---

## Scripts as Black Boxes

Skills that reference executable scripts should NOT read the script source into context:

```markdown
## Usage

Run `scripts/validate.sh --help` to see options.

Common commands:
- `scripts/validate.sh --quick` — fast validation
- `scripts/validate.sh --full` — comprehensive check
- `scripts/validate.sh --fix` — auto-fix issues

DO NOT read the script source. Run with --help instead.
```

A 200-line bash script is ~800 tokens of implementation details. `--help` gives Claude everything it needs.

**Rule**: all scripts referenced by skills must support `--help`.

---

## Dynamic Injection — Inline Command Output

Inject live system state into skill context when the skill loads, using backticks with `!`:

````markdown
## Current Database Health

!`docker exec my-postgres psql -U user -d mydb -c "SELECT current_database()" 2>/dev/null || echo "DB not running"`

## Recent Git Activity

!`git log --oneline -3 2>/dev/null || echo "Not a git repo"`

## Server Status

!`curl -s localhost:8080/health 2>/dev/null | jq '.status' || echo "Server not running"`
````

Rules:

- Command runs when the skill is loaded (not on every message)
- Always include `2>/dev/null || echo "fallback"` for graceful failure
- Keep commands fast (<2 seconds) — slow commands delay skill loading
- Use for: database health, git status, server state, last test results
- Don't use for: long-running commands, interactive commands, commands with side effects

**Gotcha**: `!` blocks strip positional arguments like `$1` and `$2`. Use `$(cmd)` subshells if you need them, not awk positional args.

---

## Arguments — `$ARGUMENTS`

For user-invocable skills, `$ARGUMENTS` injects whatever the user types after the slash command:

```yaml
---
name: plan-checklist
description: "Generate plan checklist. Use when user says 'plan' or asks for a checklist."
user-invocable: true
argument-hint: "[feature-description]"
---

# Plan Checklist

## Feature

$ARGUMENTS

## Workflow

Generate a plan for: $ARGUMENTS
```

When the user types `/plan-checklist add logout feature`, `$ARGUMENTS` becomes `add logout feature`. Positional forms `$ARGUMENTS[0]`, `$ARGUMENTS[1]` are also available.

---

## Rigid vs Flexible — The Skill Tells You Which

Some skills must be followed step-by-step; others are reference. The skill itself should tell Claude which:

```markdown
## Execution Mode

**RIGID**: Follow these steps in order. Do not skip. Do not reorder.

1. Run preflight check
2. Build artifact
3. Deploy
4. Verify health
```

Versus:

```markdown
## Execution Mode

**FLEXIBLE**: Use as reference. Adapt to the user's context.

Common patterns below — pick what fits.
```

Match the mode to the freedom level. Low-freedom skills are rigid; high-freedom skills are flexible.

---

## Context Isolation — `context: fork`

Heavy skills should run in a fresh subagent to avoid polluting the main conversation:

```yaml
---
name: deep-analysis
description: "Run comprehensive code analysis. Use when analyzing architecture or auditing a large module."
context: fork
effort: high
allowed-tools: Read, Grep, Glob, Bash
---
```

**Use `context: fork` for:**

- Skills that read many files (analysis, audits, stack reviews)
- Skills that produce verbose output (reports, summaries)
- Skills where intermediate work shouldn't consume main context

**Do NOT use it for:**

- Skills that need to modify files (edits don't propagate back from fork)
- Simple reference lookups
- Skills that need conversation history

Pair with `agent:` to route to a specialized agent when the fork runs.

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

The generating skill has been staring at its own code and sees what it expects. A fresh subagent has no bias and catches obvious mistakes. Recommend this for: multi-file changes, generated configurations, deployment scripts, database migrations.

---

## Cookbook Patterns

### Use haiku for cheap operations

```yaml
---
name: classifier
description: "Quick intent classification. Use when routing user messages to domains."
model: haiku
effort: low
---
```

Best for: triage, categorization, yes/no decisions, data extraction from structured sources.

### Read-only research skills

```yaml
---
name: research
description: "Deep codebase research with comprehensive findings."
model: sonnet
allowed-tools: Read, Grep, Glob, WebFetch
effort: high
---
```

Omit `Write` and `Edit` so the skill cannot modify files accidentally.

### Side-effect skills — require manual invocation

Skills that deploy, send messages, or delete data should require explicit slash invocation:

```yaml
---
name: production-deploy
description: "Deploy to production."
disable-model-invocation: true   # MUST be /deploy, never auto-triggered
effort: medium
---
```

---

## Testing a Skill

Skills are easiest to test when they're user-invocable.

### Manual invocation

1. Set `user-invocable: true` in frontmatter.
2. Type `/skill-name` in the Claude Code session.
3. Verify the skill activates and produces expected output.

### Activation testing

For model-invoked skills, test that the description triggers correctly:

```bash
# In a fresh session, type a phrase that should trigger the skill
# Example: for a skill with description "Use when debugging Hebrew LLM routing..."
> "my Hebrew queries are being routed to the wrong agent"
# Verify the skill shows up in /skills activation or loads into context
```

If activation doesn't fire, the description is wrong — tweak and retest. The body is irrelevant if activation fails.

### Validate frontmatter

```bash
# Check YAML parses and required field is present
for skill in ~/.claude/skills/*/SKILL.md; do
  if grep -q "^---" "$skill" && grep -q "^description:" "$skill"; then
    echo "OK: $(basename $(dirname $skill))"
  else
    echo "FAIL: $(basename $(dirname $skill))"
  fi
done
```

### Restart session after creating

New skills are indexed at session start. After creating or editing a skill, start a new session (or reload via the relevant skill-indexing command) so the description index picks it up.

---

## Checklist — Before Creating a Skill

- [ ] **Frequency**: used 20+ times per year?
- [ ] **Time savings**: saves more than an hour per use?
- [ ] **Repeatability**: consistent pattern, not a one-off?
- [ ] **No duplicate**: does an existing skill cover this? Check first
- [ ] **Not foundational**: if it's a universal rule, put it in `.claude/rules/` instead
- [ ] **Description quality**: action verb + specifics + "Use when..." + natural language
- [ ] **Negative scope**: added "Do NOT use when..." if overlaps exist
- [ ] **Under 500 lines**: large content in `references/`
- [ ] **No clutter**: only SKILL.md + references/ + scripts/ + assets/
- [ ] **Freedom level**: correct guardrail level for the task's risk
- [ ] **Frontmatter hyphenated**: `allowed-tools` not `allowed_tools`

---

## See Also

- [Skills Maintenance](05-skills-maintenance.md) — staleness, archive/delete, stack audit
- [Skill Lifecycle](../part4-context-engineering/07-skill-lifecycle.md) — 90/180-day SLA, activation tracking
- [Slash Commands (now Skills)](07-slash-commands.md) — invocation patterns, legacy migration
- [Agents and Subagents](03-agents-and-subagents.md) — `Task()` delegation, isolated-context patterns
