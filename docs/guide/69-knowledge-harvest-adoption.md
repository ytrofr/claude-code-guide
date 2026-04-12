---
layout: default
title: "Knowledge Harvest Adoption — Validating Community Patterns for Claude Code"
description: "How to aggregate community articles about Claude Code, validate claimed features against official sources, and adopt proven patterns into your setup."
parent: Guide
nav_order: 69
---

# Chapter 69: Knowledge Harvest Adoption — Validating Community Patterns

Community articles about Claude Code are proliferating across Builder.io, LinkedIn, Stack Overflow, and personal blogs. Some contain genuinely useful patterns. Many fabricate features. This chapter documents a systematic approach to harvesting, validating, and adopting community knowledge.

---

## 1. What Is Knowledge Harvesting

Knowledge harvesting uses the AI Intelligence Hub (localhost:4444) to aggregate community articles about Claude Code from across the web. The Hub's fetch pipeline pulls from configured sources, stores them in SQLite with FTS5, and lets you search and filter by relevance, date, and score.

The goal is not to read everything — it is to find patterns that are genuinely useful, validate them against official sources, and adopt only what passes validation.

**Typical harvest cycle:**
1. Hub fetches articles from configured community sources
2. Scan titles and summaries for novel patterns (skills, flags, workflows)
3. Validate each claim against official docs (see Section 3)
4. Adopt validated patterns into your setup (rules, skills, CLAUDE.md)
5. Discard unvalidated claims — do not propagate them

---

## 2. The Validation Problem

Community articles fabricate features. In a test of 40 articles harvested from Builder.io, LinkedIn, and various blogs, multiple claims turned out to be false:

| Claim | Source | Verdict | Evidence |
|-------|--------|---------|----------|
| `output-styles/` directory for controlling response format | Builder.io "50 tips" article | **FALSE** | Directory does not exist in Claude Code |
| `--teleport` flag for jumping between contexts | Attributed to Boris Cherny | **FALSE** | Not in `claude --help`, not in official docs |
| `--channels` flag for async phone approval | Multiple articles | **TRUE** | Guide Ch.57, GA since 2.1.81 |
| `--bare` flag for CI/scripted output | Multiple articles | **TRUE** | Guide Ch.57, GA since 2.1.81 |
| Progressive disclosure for skills | Multiple articles | **TRUE** | Guide Ch.44, validated in production |

**Key finding:** Roughly 1 in 5 "advanced tips" articles contain at least one fabricated feature. The more specific the claim (exact flag names, directory paths), the more likely it is real — but vague architectural claims ("output-styles directory") tend to be hallucinated.

---

## 3. Validation Protocol (3-Step)

Every claimed feature must pass all three steps before adoption.

### Step 1: Check CLI Help

```bash
claude --help | grep -i "claimed-flag"
claude --help    # Full scan for unknown flags
```

If the flag is not in `--help`, it does not exist. Community articles sometimes describe planned features, internal flags, or outright fabrications.

### Step 2: Search Official Guide and Docs

Search the guide chapters for documentation of the feature:

```bash
grep -ri "feature-name" ~/claude-code-guide/docs/guide/
```

Also check:
- Anthropic's official Claude Code documentation
- The `/claude-code-docs` skill for on-demand doc search
- The `/claude-code-changelog` skill for version-specific feature lists

### Step 3: Treat Unvalidated Claims as False

If a claim is not found in Step 1 or Step 2, do not adopt it. Do not add it to rules, skills, or documentation. Mark it as "unvalidated" in your notes if you want to revisit later.

**Exception:** If a community article describes a workflow pattern (not a CLI feature), you can validate it by testing it yourself. Workflow patterns like "iterative review loops" or "spec-first TDD" are about methodology, not CLI features — they can be validated through practice.

---

## 4. Progressive Disclosure for Skills (Validated Pattern)

This pattern is documented in Guide Ch.44 and validated in production. It reduces skill loading cost by splitting large skills into three levels.

### The Three Levels

| Level | What Loads | Cost | When |
|-------|-----------|------|------|
| Description | ~37 tokens | Every message (routing) | Always — used for skill matching |
| Body (SKILL.md) | ~500 tokens | On activation | When Claude decides to use the skill |
| References (`references/`) | ~2000 tokens | On demand | Only when Claude needs detailed docs |

### When to Split

Split when a skill exceeds 300 lines. The body should contain the decision tree and quick reference. Move detailed examples, full API docs, and edge case handling to `references/`.

### Directory Structure

```
~/.claude/skills/my-skill/
├── SKILL.md              # Body: decision tree + quick reference (< 300 lines)
└── references/
    ├── detailed-patterns.md   # Full examples and edge cases
    └── api-reference.md       # Complete API documentation
```

### Real Results

| Skill | Before (body lines) | After (body lines) | References (lines) |
|-------|---------------------|--------------------|--------------------|
| context-engineering | 504 | 85 | 216 |
| mcp-usage-patterns | 401 | 77 | 180 |
| anthropic-best-practices | 399 | 100 | 195 |

Body size reduced 80-85% while retaining full information on demand.

---

## 5. New Skills Created from Harvest

Two new skills emerged from the community harvest after validation.

### `/iterative-review` — Convergence-Based Review Loop

Inspired by the "ralph-loop" pattern found in community articles: a review-fix-verify cycle that runs until findings converge to zero (or a severity threshold is met).

**Pattern:**
```
Review (find issues) → Fix (address by severity) → Verify (re-review) → Converge?
    └── NO: loop back to Review
    └── YES: done
```

**Key design decisions:**
- Fix by severity (critical first, then high, then medium)
- Stop when no critical/high findings remain — do not chase cosmetic issues indefinitely
- Maximum 3 iterations to prevent infinite loops

### `/fix-ci` — CI Failure Diagnosis

Uses `gh` CLI to fetch GitHub Actions failure logs, classify the root cause (test failure, lint error, dependency issue, timeout), and apply targeted fixes.

**Pattern:**
```
gh run view --log-failed → classify error → apply fix → push → verify
```

### Spec-First TDD Gate

Added to the existing `/tdd` skill: before writing tests, write a brief spec (3-5 bullet points) of what the feature should do. The spec becomes the test plan. This prevents the common failure mode where TDD tests verify the wrong behavior because the developer started coding without clarifying requirements.

---

## 6. Community Patterns Worth Adopting (Validated)

These patterns passed the 3-step validation protocol and are recommended for adoption.

### `--bare` for CI/Scripted Calls

Strips all formatting from Claude's output. Essential for piping Claude output into other tools:

```bash
claude --bare "generate the SQL migration" > migration.sql
```

### `--channels` for Async Phone Approval

Sends approval requests to configured channels (phone, Slack) instead of blocking the terminal:

```bash
claude --channels phone "deploy to production"
```

### Iterative Review Loops

The review-fix-verify-converge pattern described in Section 5. Produces higher quality code than single-pass reviews.

### Spec-First Before TDD

Write the spec before writing tests. Prevents testing the wrong thing.

### Skill Self-Improvement via A/B Testing

Use the `skill-creator` plugin's eval framework to measure skill performance before and after changes. Never claim a skill improved without before/after data.

**Pattern:**
1. Write eval cases for the skill (5-10 representative inputs)
2. Run baseline measurement
3. Make changes
4. Run comparison measurement
5. Only ship if metrics improve

---

## Key Takeaways

1. **Community articles fabricate features** — always validate against `claude --help` and official docs
2. **3-step validation is mandatory** — CLI check, guide search, reject if unvalidated
3. **Progressive disclosure saves 80%+ body tokens** — split skills over 300 lines
4. **Workflow patterns can be validated by testing** — methodology is different from CLI features
5. **Always measure before and after** — use eval frameworks for skill improvements

---

## See Also

- [Chapter 44: Skill Design Principles](44-skill-design-principles.md) — Progressive disclosure framework
- [Chapter 57: Claude Code 2.1.77-2.1.81 Features](57-claude-code-2177-2181-features.md) — `--bare`, `--channels` documentation
- [Chapter 58: Skills Cookbook Patterns](58-claude-skills-cookbook-patterns.md) — Skill design recipes
- [Chapter 68: Battle-Tested Patterns Adoption](68-battle-tested-patterns-adoption.md) — Previous adoption methodology

*Next: [Chapter 70 — Claude Code 2.1.89-2.1.92 Features](70-claude-code-2189-2192-features)*
