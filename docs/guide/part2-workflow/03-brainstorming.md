---
layout: default
title: "Brainstorming"
parent: "Part II — Workflow"
nav_order: 3
---

# Brainstorming

Brainstorming is the step before planning. Before you write a plan, before you write code, before you write a test, you sit down with Claude and **figure out what you're actually building and why**. One clarifying question at a time. Two or three approaches on the table. Trade-offs made explicit. A short design document at the end.

This chapter was itself produced by brainstorming. The structure you're reading — six Part II chapters, the split between TDD and verification, the commit chapter as a reference rather than a tutorial — came from a conversation, not a first draft. If brainstorming works for a guide, it works for your feature.

**Purpose**: Replace "let me just start building" with "let me understand what we're building"
**Difficulty**: Beginner (to use), intermediate (to resist skipping)
**Applies to**: Any non-trivial change — features, refactors, architecture shifts

---

## When to Brainstorm

**Default to YES.** Brainstorm before creating any feature, building any component, changing any behavior, or starting any non-trivial work. The cost is ten minutes of conversation; the cost of skipping it is the day you spend rewriting the wrong thing.

**Skip brainstorming only when:**

- The bug has a traced root cause and the fix is obvious (<10 lines, one file)
- The change is a one-line typo, copy edit, or config tweak
- You are doing pure research — reading code, asking "what does this do?"
- The user explicitly says "just do it"

**Red flag phrases that mean you're skipping brainstorming when you shouldn't:**

- "I already know what they want"
- "Let me just start building"
- "This is too simple to need a design"
- "I'll figure it out as I go"

Every one of these has been the prelude to a day-long detour. When you catch yourself or Claude saying them, stop and brainstorm.

---

## The Process

Brainstorming has a shape. Follow it and the quality compounds; skip a step and the design collapses.

```
1. Understand        → restate the problem in your own words
2. Clarify           → ask one question at a time
3. Propose           → 2-3 approaches with trade-offs
4. Decide            → pick one with explicit reasoning
5. Design doc        → write it down
6. Self-review       → poke holes in your own design
7. User review       → get explicit approval
8. Hand off          → transition to writing-plans
```

Each step has a reason. Skipping steps is how you end up with a plan that doesn't match the user's intent.

---

## 1. Understand

Restate the problem in your own words. Not the solution — the **problem**.

> "You want a way to scope commits when multiple Claude sessions are touching the same repo, so one agent doesn't stage another agent's work-in-progress. The current pain is that `git add -A` pulls in everyone's unfinished changes."

If the restatement misses what the user cares about, they will correct it. If it nails the problem, you have permission to move to clarifying questions. If you skip this step, you are building a solution to a problem you haven't confirmed exists.

---

## 2. Clarify — One Question at a Time

The single biggest quality lift in brainstorming is asking **one question at a time** and waiting for the answer before asking the next. Not three at once. Not a bulleted list of seven. One.

Why: each answer changes what the next question should be. If you ask three questions up front, by the time you get the answers, question two is irrelevant and question three was premature.

**Good clarifying questions shape the design space:**

- "Is this a one-time script or a long-lived service?"
- "Who uses it — just you, your team, or the public?"
- "What's the failure mode you're most worried about?"
- "Is there an existing pattern in the codebase we should match?"
- "What does success look like — is there a measurable outcome?"

**Bad clarifying questions are premature solutioning:**

- "Should we use Postgres or SQLite?" — that depends on the shape of the data, which you haven't established
- "Do you want async or sync?" — same
- "Should I put this in `src/utils` or `src/services`?" — implementation detail, not design

Keep asking until you have enough to propose approaches. That's usually three to six questions. If you're on question ten, you're either overthinking or the ask is actually multiple features stacked — split it.

---

## 3. Propose — Two or Three Approaches, With Trade-Offs

Once the problem is clear, propose **2-3 approaches**. Not one "best" answer — multiple, with explicit trade-offs.

Why multiple: a single proposal is a sales pitch. Multiple proposals are a comparison. The user can see what you considered and rejected, and the trade-offs become part of the record.

**Template:**

```
Approach A — <short name>
  How: <one sentence>
  Pros: <2-3 bullets>
  Cons: <2-3 bullets>
  Cost: <rough effort estimate>

Approach B — <short name>
  How: <one sentence>
  Pros: <2-3 bullets>
  Cons: <2-3 bullets>
  Cost: <rough effort estimate>

Approach C — <short name>
  (same)

Recommendation: <which and why, one paragraph>
```

If you can't think of two approaches, you haven't thought hard enough about the problem. Every non-trivial problem has multiple valid solutions — the discipline is to name them.

---

## 4. Decide

Pick one approach. State why, briefly. The reasoning matters more than the choice — if the choice turns out wrong, the reasoning tells you what assumption broke.

> "Going with Approach B (explicit file list per commit) over Approach A (per-directory globs) because the multi-agent case has agents working in the same directory, so path-level scoping is necessary. Cost is a small tooling script; reward is zero cross-agent staging incidents."

---

## 5. Write the Design Doc

Write the design down. It doesn't need to be long — one page is often enough — but it needs to exist outside the conversation, because conversations get lost and plans disappear with the context window.

**Design doc structure:**

```
# Design: <feature name>

## Context
Why are we doing this? What prompted the work? What's the current state?

## Non-Goals
What we are deliberately NOT doing. This section is where creep gets caught.

## Scope
What this change touches. What it does not touch. If the work spans multiple
independent workstreams, break each into its own sub-section.

## Detailed Design
For each workstream: data model changes, API shape, user-visible behavior,
error cases, edge cases. Include enough that someone else could plan from this.

## Security
Authentication, authorization, data leaks, injection surfaces. Even for
internal tools — especially for internal tools.

## Rollout
How does this ship? Feature flag? Migration? Backfill? Canary?

## Open Questions
Things we don't know yet. These become probes in the plan's pre-validation step.

## TL;DR
Three sentences at the top of the doc (written last). What, why, how.
```

Not every section applies to every design. If the change doesn't touch data, skip the data-model section. If there's no rollout risk, say so and move on. But do consider each section, because the one you're tempted to skip is often the one that bites.

---

## 6. Self-Review

Before you show the design to the user, **poke holes in it yourself**. This is the step that separates good engineers from senior engineers.

**Questions to ask your own design:**

- What assumptions am I making? Are any of them unverified?
- What's the failure mode under load? Under partial failure? Under bad input?
- Could this be simpler? Is the abstraction level justified?
- What happens if I need to roll this back?
- What are the hidden dependencies? What breaks if they change?
- Have I considered all three approaches seriously, or am I rationalizing a favorite?

If self-review finds a hole, fix the design before showing it. If self-review finds that the whole design is wrong, good — you just saved yourself a week.

---

## 7. User Review

Now show the design to the user. Not "here's what I'll build" — "here's what I think you want; does this match?"

The user has three possible answers:

1. **Yes, ship it.** → move to writing-plans
2. **Change X.** → edit the design, re-review
3. **That's the wrong problem.** → back to step 1

Answer three is the painful one, but it's why brainstorming exists. Catching "wrong problem" at the design stage costs ten minutes. Catching it after the code is written costs a day.

---

## 8. Hand Off to Writing-Plans

Once the design is approved, the next step is **not** code. It's a plan.

- The **design** answers "what and why"
- The **plan** answers "in what order, with what checkpoints, with what KPIs"

The plan pulls from the design. It does not replace the design. See [Chapter 01 — Plan Mode](/docs/guide/part2-workflow/01-plan-mode/) for the plan structure; the superpowers `writing-plans` skill turns a design into a plan with the required 14 sections.

---

## Scope Decomposition

If the user's ask spans multiple independent subsystems — say, "add auth, a new API endpoint, and a React component to display the result" — do **not** brainstorm it as one feature. Break it up.

```
Meta-brainstorm: What are the independent workstreams here?

Workstream 1: Auth
  Own brainstorm, own design, own plan, own PR

Workstream 2: API endpoint
  Own brainstorm, own design, own plan, own PR (depends on 1)

Workstream 3: UI component
  Own brainstorm, own design, own plan, own PR (depends on 2)
```

Why: a design doc that tries to cover three subsystems is harder to review, harder to challenge, and harder to ship incrementally. Three focused design docs are better than one comprehensive one.

The heuristic: if any workstream could be shipped independently and still provide value, it deserves its own design.

---

## Anti-Patterns

### "This is too simple to need a design"

The most dangerous phrase in engineering. If it's too simple to need a design, the design is one paragraph and takes two minutes. If it's not too simple, you were lying to yourself.

Count the number of times "this is too simple" preceded a day-long debugging session in your past. Every one of them was a brainstorming failure.

### Leading with implementation before understanding

```
User: "I need users to be able to sign in with Google"

Wrong: "Okay, I'll add OAuth2. Which library do you want — passport? authlib?"
Right: "Before I pick a library — is this for a web app, mobile, or both?
        One tenant or multi-tenant? Any existing auth we need to integrate with?"
```

The wrong response skipped understanding and jumped to solutioning. The user may have an answer to "which library," but it doesn't matter yet, because the shape of the feature isn't defined.

### Asking three questions at once

```
Wrong: "Before I start — is this web or mobile? Do you want Google or GitHub?
        Should sessions be stored in Redis or the database?"
```

The user picks one, ignores the others, and you've lost the thread. One question, one answer, next question.

### Brainstorming without writing it down

The conversation resolves, you feel good, you start implementing. Two days later the context has compacted and neither you nor Claude remembers why you chose approach B. The design doc is cheap insurance against forgetting.

### Re-brainstorming mid-implementation

Once the design is approved and the plan is written, stop brainstorming. If you discover a problem mid-implementation, either (a) fix it within the plan's scope, or (b) stop, amend the design, amend the plan, and continue. Do not silently drift from the design — that's how features end up not matching intent.

---

## Quick Reference

```
Problem arrives
  ↓
Is it trivial (<10 lines, one file, obvious fix)?
  YES → skip brainstorming, just do it
  NO  ↓
Restate the problem in your own words
Ask one clarifying question at a time (3-6 total)
Propose 2-3 approaches with trade-offs
Decide, state why
Write the design doc
Self-review, fix the holes
User review, incorporate feedback
Hand off to writing-plans → Chapter 01
```

---

## See Also

- [Chapter 01 — Plan Mode](/docs/guide/part2-workflow/01-plan-mode/) — what comes after the design
- [Chapter 02 — TDD](/docs/guide/part2-workflow/02-tdd/) — what comes after the plan
- superpowers `brainstorming` skill — one-command entry into this flow
- superpowers `writing-plans` skill — design-doc-to-plan handoff
