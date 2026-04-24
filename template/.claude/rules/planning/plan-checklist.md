# Plan Mode Checklist - MANDATORY for Every Plan

**Authority**: Universal plan quality enforcement
**Updated**: 2026-04-22 (v9: Problem/Solution sub-section added at top of Section 12 TL;DR)
**Scope**: ALL plans in ALL projects

---

## Rule

Every plan (via EnterPlanMode, /plan, or plan permission mode) MUST contain ALL 15 sections (0, 0.1, 1-11, 12, 13). No placeholders. Section 0 (verbatim user prompt) written FIRST and never edited during revisions. Write Section 12 (TL;DR) LAST — after all detail sections are complete. Section 12 MUST be the last content section, followed only by Section 13 (post-validation template).

For full section templates and examples, invoke `/plan-checklist`.

---

## 15 Mandatory Sections

### Section 0: Original User Prompt (verbatim, preserved) — MANDATORY FIRST

Paste the single user message that triggered plan mode as a blockquote. No edits, no paraphrase, no cleanup. Section 0 is the immutable record of "what was asked" — never rewritten during plan revisions. Clarifications and scope negotiations go in Section 1, NOT here.

```markdown
## Section 0 — Original User Prompt (verbatim, preserved)

> {user's original message, `> ` prefixed on every line}
> {preserve typos, casing, emoji, non-English text, line breaks}
```

### Section 0.1: Pre-Validation Probe (BLOCKING GATE)

**Before ExitPlanMode**, verify assumptions with real evidence. Convert UNKNOWN/ESTIMATED KPIs to MEASURED.

**The question**: "What does this plan ASSUME is true, and can I check it right now?"

**When to run**: Any UNKNOWN/ESTIMATED KPIs or verifiable assumptions.
**When to skip**: Trivial (<10 lines) + all KPIs MEASURED + no unverified assumptions.
**On DISPROVED**: Adjust plan. >50% disproved = REJECT and re-plan.
**On NO-GO feasibility**: STOP. Redesign.

**All KPIs MUST be MEASURED after the probe.** No UNKNOWN or ESTIMATED allowed at ExitPlanMode time.

### Sections 1-11

| Section | Name | Key Requirement |
|---------|------|----------------|
| 1 | Requirements Clarification | AskUserQuestion BEFORE planning. Skip only if zero ambiguity. |
| 2 | Existing Code Check | Grep/Glob/Read BEFORE writing plan. Never build what exists. |
| 3 | Over-Engineering Prevention | <50 lines? Zero new deps? Justify if no. |
| 4 | Best Practices | KISS, DRY, SOLID, YAGNI, Security (OWASP top 10) |
| 5 | Modular Architecture | Routes/Controllers/Services separation. Each file <500 lines. |
| 6 | Visual Diagram | When 3+ components, architecture change, or state transitions. N/A for simple changes. |
| 7 | Documentation Plan | Run /document after implementation. |
| 8 | E2E Testing Plan | Unit + integration + E2E + baseline regression + manual verification. |
| 9 | Debugging & Observability | Logging levels, error handling, health checks, monitoring. |
| 10 | File Change Summary | Columns: File, Action, Before, After, Why. Each row is a mini-story. |
| 11 | Modularity Enforcement | BLOCKING GATE. File <500L, function <50L, layer separation, no god files. |

### Per-Fix BEFORE/AFTER (MANDATORY in implementation details)

Every fix MUST start with:
```
### Fix N: Title
**BEFORE**: One sentence — current broken behavior.
**AFTER**: One sentence — fixed behavior.
```

### Section 12: TL;DR + KPIs (WRITE LAST — ALWAYS the final content section)

Must include, in this order: **Problem / Solution** (one sentence each), Overall Plan Confidence, Problem (Before) table + Solution (After) table, Scope, and KPI Dashboard table.

**Problem / Solution** — the one-line anchor for why the plan exists. Opens Section 12:
```markdown
### Problem / Solution

**Problem**: [one sentence — what's broken, missing, or painful that triggered this plan]
**Solution**: [one sentence — what this plan does to resolve it]
```

Rules: one sentence each, Problem names the primary pain (not symptoms/tasks), Solution states the resolution (not HOW — that's in Sections 3-10), both should reconcile with Section 0.

**KPI Dashboard** — ALWAYS a pipe-delimited table:
```
| Status | KPI | Before | After (Target) | Source | Confidence | Green | Yellow | Red |
```

KPI Rules: emoji status only, 2-5 KPIs, all MEASURED, Source cited.

### Section 13: Post-Validation (template at plan time, filled after implementation)

Re-measures the SAME KPIs from Section 12 after implementation. Include template with empty rows at plan time.

---

## Quick Validation

- [ ] All 15 sections present with real content (0, 0.1, 1-11, 12, 13)
- [ ] Section 0 present with verbatim user prompt as blockquote (no paraphrase)
- [ ] TL;DR is Section 12 — ALWAYS the last content section, written LAST
- [ ] Section 12 opens with **Problem / Solution** one-sentence lines (v9), then has Problem (Before) table + Solution (After) table + KPI Dashboard table
- [ ] KPI Dashboard is a pipe-delimited table (never prose)
- [ ] Every fix has **BEFORE**: and **AFTER**: one-liners
- [ ] Section 13 Post-Validation template present
- [ ] All KPIs are MEASURED after Section 0.1 probe
- [ ] Existing code searched (not building from scratch)
- [ ] Modularity enforcement passed

---

## Sideways Detection

3+ consecutive failed attempts → re-plan. Scope creep >50% → re-plan.
Core assumption proven false → re-plan. Blocked by dependency → re-plan with alternative.
