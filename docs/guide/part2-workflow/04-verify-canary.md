---
layout: default
title: "Verify and Canary Post-Deploy"
parent: "Part II — Workflow"
nav_order: 4
redirect_from:
  - /docs/guide/50-verification-feedback-loop.html
  - /docs/guide/50-verification-feedback-loop/
---

# Verify and Canary Post-Deploy

The single biggest quality improvement you can give Claude Code is a way to check its own work before you see it. Without a verification step, every turn ends with "done" -- and you become the unpaid QA engineer who discovers the broken build, the failing test, the 500 error. With verification, Claude runs health checks, tests, and quality gates itself, fixes what it finds, and reports a clean result.

This chapter covers two skills that make that loop real: **`/verify`** (pre-commit checks on your changes) and **`/canary`** (post-deploy checks on production).

**Purpose**: Give Claude a systematic way to catch its own mistakes before the user, before commit, and before users see production
**Difficulty**: Beginner
**Time**: 5 minutes to install; runs automatically on every meaningful change

---

## Why Verify

Without verification, Claude's workflow looks like this:

```
Make changes → "Done"
```

The user then runs the tests, hits the endpoint, checks the page, and reports back. Each round-trip costs 5-15 minutes and poisons Claude's context with "this is broken, fix it again" turns.

With verification, the workflow becomes:

```
Make changes → Verify → Fix issues found → Report clean result
```

The cost of an extra verification turn is trivial. The cost of *not* having one is that Claude occasionally ships half-done work confidently, because "my tests pass therefore the feature works" is the single most common lie in software engineering.

The key is **low friction**. A 12-step mental checklist won't get run. A single command -- `/verify` -- will.

---

## The /verify Skill

`/verify` is a user-invocable skill that auto-detects scope (what changed, what tech stack), runs the relevant checks, and reports a structured PASS / FAIL / SKIP summary.

### Three modes

| Mode | What runs | When to use |
|------|-----------|-------------|
| `/verify quick` | Health endpoint + syntax check on changed files | Mid-conversation sanity check |
| `/verify deep` | Quick + test suite + lint + modularity (500-line limit) | Before commit on non-trivial changes |
| `/verify auto` (default) | Detects from diff: docs-only → quick, source → deep, test files → run those specific tests | Recommended default |

### Dynamic context injection

The skill uses `!` + backtick preprocessing to run shell commands at invocation time, before the model sees the prompt. By the time the model starts thinking, it already has:

- The current branch name
- The list of changed files (`git diff HEAD --name-only`)
- The server health status (if a dev server is running)

This eliminates the first round of tool calls the model would otherwise need. Without dynamic injection, the first turn would be "let me check what changed..." -- with it, the diff is already in the prompt.

### Minimal skill file

```markdown
---
name: verify
description: Verify recent changes with auto-detected scope. Use when
  changes complete, before commit/deploy, or user says 'verify', 'check',
  or 'validate'.
allowed-tools: Bash, Read, Grep, Glob
user-invocable: true
argument-hint: "[quick|deep|auto]"
---

# Verification: $ARGUMENTS mode

## Context (dynamic injection)

**Branch**: !`git branch --show-current`
**Changed files**: !`git diff HEAD --name-only`
**Unstaged**: !`git diff --stat`
**Server**: !`curl -s -o /dev/null -w "%{http_code}" http://localhost:${PORT:-8080}/health 2>/dev/null || echo "not running"`

## Instructions

Mode "$ARGUMENTS" (default: auto):

- **quick**: Health check + syntax check on changed files
- **deep**: Quick + test suite + lint + 500-line modularity check
- **auto**: Detect from changed files
  - Only docs/config → quick
  - Source code → deep
  - Test files → run those specific tests

Report each check as PASS / FAIL (with fix) / SKIP (with reason).
```

### Dynamic injection syntax gotcha

The correct syntax is `` !`command` `` — exclamation mark followed by a backtick-delimited command, as bare text in the markdown. Common mistakes that silently fail:

```markdown
# CORRECT
**Branch**: !`git branch --show-current`

# WRONG (dollar-bang syntax does not exist)
**Branch**: $!git branch --show-current!$

# WRONG (nested in a code fence — renders as literal text)
**Branch**: `!`git branch --show-current``
```

If your skill isn't picking up dynamic context, this is almost always the reason.

---

## When to Verify, When to Trust

Not every turn needs `/verify`. The cost of running it when nothing meaningful changed is small but not zero.

| Situation | Verify? |
|-----------|---------|
| Edited source files | YES — `/verify auto` |
| Added or changed tests | YES — run the tests |
| Changed config or env vars | YES — `/verify quick` (health check) |
| Docs-only change | NO — no runtime impact |
| Read files, searched code, answered a question | NO — no changes to verify |
| Refactored a module touched by 3+ callers | YES — `/verify deep` |
| About to commit | YES — `/verify deep` |
| About to deploy | YES — `/verify deep` then `/canary` post-deploy |

A gentle automated nudge covers most of the rest: a `Stop` hook that checks for changed source files and suggests `/verify` when it sees them. The nudge never blocks -- it just appends a line to Claude's next turn so the reminder is visible.

```bash
#!/bin/bash
# ~/.claude/hooks/stop-verify-nudge.sh
CHANGED=$(git diff --name-only HEAD 2>/dev/null | wc -l)
SRC=$(git diff --name-only HEAD 2>/dev/null | grep -cE '\.(js|ts|py|go|rs|java|rb|jsx|tsx)$')
if [ "$SRC" -gt 0 ]; then
  echo "[$SRC source file(s) changed] Consider running /verify to check your work."
elif [ "$CHANGED" -gt 5 ]; then
  echo "[$CHANGED files changed] Consider running /verify quick."
fi
exit 0
```

Wire it as a `Stop` hook in settings. It runs after every turn, silent when there's nothing to say, visible when there is.

---

## 3-Tier Validation: Code, Integration, Production

`/verify` passing means your **code** is correct. It does not mean the feature **works**. This is the most expensive lie in the verification loop.

The 3-tier model separates the claims:

| Tier | Question | How to check | If it fails |
|------|----------|--------------|-------------|
| 1. Code correctness | Does the code run as written? | Unit tests, type check, lint, syntax | Fix the code |
| 2. Integration | Does it work in the real system? | Integration tests, curl the endpoint, hit the page | Fix the integration |
| 3. Production impact | Does it solve the actual problem? | Re-measure the KPI from the plan; compare before/after | Re-plan |

Only claim success if **all three** pass. `/verify` handles tiers 1 and 2 automatically. Tier 3 is what the plan's Section 13 (post-validation) is for -- re-measure the same KPIs from Section 12 and compare.

### A real example of the gap

> **Feature**: Canvas capture to improve clone SSIM score
>
> - Tier 1 (Code): ✅ `toDataURL()` works, no errors, tests pass
> - Tier 2 (Integration): ✅ `data-captured-canvas` markers present in rendered HTML
> - Tier 3 (Production): ❌ +0.1 points SSIM (negligible impact on the real metric)
>
> **Verdict**: Code correct, integration working, **problem not solved**. The work was undone and re-planned.

If the team had stopped at Tier 1 or Tier 2, they would have shipped a "success" that didn't move the metric. Tier 3 -- re-measuring the actual KPI -- caught it.

---

## The /canary Skill — Post-Deploy

`/verify` runs before commit. `/canary` runs after deploy. It takes a screenshot, captures console and network errors, and compares against a baseline. If anything regressed, you find out in 30 seconds instead of 30 minutes from an angry user.

### What /canary does

1. **Screenshot**: Playwright navigates to the deployed URL, captures a full-page PNG
2. **Console scan**: collects every browser console message, filters for errors and warnings
3. **Network scan**: collects every network request, flags non-2xx responses (and non-expected 3xx)
4. **Baseline compare**: diffs against the last known-good baseline (screenshot pixel diff + error count delta)
5. **Report**: PASS / FAIL with the specific errors, network failures, or visual regressions

### When to run /canary

- Immediately after every production deploy
- After any change to a routing, auth, or infrastructure file
- In CI, scheduled every 15-30 minutes to catch silent regressions
- Before declaring a plan's Section 13 verdict PASS

### Baseline management

The first `/canary` run on a page establishes the baseline. Subsequent runs compare against it. When you ship an intended visual change, bless the new output as the baseline:

```bash
/canary bless home-page
/canary bless login-page
```

Without bless, intentional changes flag as regressions and the signal drowns in noise.

---

## Pairing /verify and /canary in a Plan

Plans that include a deploy follow this sequence in their post-validation (Section 13):

```
1. /verify deep         # pre-commit — code, tests, modularity
2. commit + push
3. deploy
4. /canary              # post-deploy — screenshot, console, network
5. Re-measure Section 12 KPIs  # tier 3 — production impact
6. Fill Section 13 verdict: PASS / PARTIAL / FAIL
```

Missing any one of these turns "shipped" into "shipped something that may or may not work."

See the [plan mode chapter](01-plan-mode.md) for the full Section 13 template and how the KPIs in Section 12 feed into post-deploy re-measurement.

---

## Anti-Patterns

**"My tests pass, therefore the feature works."**
Tier 1 passing says nothing about tiers 2 or 3. Only co-passing tier 3 (the actual KPI re-measured) confirms the feature works.

**"/verify came back clean, we're good."**
`/verify` is pre-deploy. If you haven't run `/canary` post-deploy, you haven't verified production.

**"We fixed the regression by reverting."**
Reverts aren't verification. They're a reset. After a revert, re-run `/verify` and `/canary` to confirm the reset actually reverted cleanly.

**Running `/verify` inside the plan but not after implementation.**
The plan describes intent. The post-implementation run confirms reality. Both are needed.

**Blessing baselines carelessly.**
Blessing on every run hides regressions. Bless only when the visual change is intentional and reviewed.

**Verifying only what Claude changed.**
Changes to config, env vars, or shared dependencies can break files Claude didn't touch. `/verify deep` runs the full test suite for exactly this reason.

---

## Installation Summary

To install both skills globally:

```bash
# /verify skill
mkdir -p ~/.claude/skills/verify
# write SKILL.md (see above)

# /canary skill (full implementation uses Playwright MCP)
mkdir -p ~/.claude/skills/canary
# write SKILL.md with Playwright screenshot + console + network logic

# Stop hook for verify nudge
chmod +x ~/.claude/hooks/stop-verify-nudge.sh
# add Stop hook entry to ~/.claude/settings.json
```

For project-specific overrides, create `.claude/skills/verify/` in the project -- the project-level skill takes precedence over the global one. Use this to add project-specific health endpoints, custom test runners, or domain-specific quality checks.

---

## Key Takeaways

1. **One command, not a checklist.** `/verify` collapses "run tests, check health, scan lint, count lines" into a single invocation. Low friction = high usage.
2. **Dynamic context injection saves a round-trip.** The `` !`command` `` syntax runs at invocation time, so the diff and health status are already in the prompt when Claude starts thinking.
3. **3-tier validation, not 1-tier.** Code correctness ≠ integration ≠ production impact. Ship only when all three pass.
4. **`/canary` catches what `/verify` cannot.** Post-deploy screenshots, console errors, and network failures surface regressions in seconds.
5. **Nudge, don't gate.** A `Stop` hook that suggests `/verify` when source files changed is enough. Forced verification gets disabled; gentle prompts get followed.
6. **Pair with the plan's Section 13.** The post-validation template re-measures the same KPIs from Section 12. `/verify` covers tiers 1-2; the KPI re-measurement covers tier 3.
7. **Bless baselines deliberately.** `/canary` baselines only work as regression detection if you bless them on intentional changes and never otherwise.
