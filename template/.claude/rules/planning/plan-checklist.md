# Plan Mode Checklist - MANDATORY for Every Plan

**Authority**: Universal plan quality enforcement
**Updated**: 2026-03-03 (v4: Condensed — full templates in /plan-checklist skill)
**Scope**: ALL plans in ALL projects

---

## Rule

Every plan (via EnterPlanMode, /plan, or plan permission mode) MUST contain ALL 13 sections (0, 0.1, 1-11). No placeholders. Write Section 0 FIRST.

For full section templates and examples, invoke `/plan-checklist`.

---

## 13 Mandatory Sections

### Section 0: TL;DR + KPIs (WRITE FIRST)

Executive summary — reader understands FULL plan in <10 seconds. Must include:

- **Problem -> Solution**: Pain point + fix in plain language
- **Scope line**: Files changed + lines + architectural or contained
- **KPI Dashboard** with columns: Status | KPI | Before | Source | Confidence | Target | Green | Yellow | Red

**KPI Rules**:
- Status: emoji only, NEVER text words
- Pick 2-5 KPIs per plan, all need Green/Yellow/Red thresholds
- Source: WHERE the Before number came from (DB query, baseline file, log grep)
- Confidence: `MEASURED` (real data, cite source), `ESTIMATED` (partial data, state basis), `UNKNOWN` (plan must include measurement step)
- At least 1 KPI MUST be MEASURED. ALL UNKNOWN = plan rejected.

### Section 0.1: Pre-Validation Probe (BLOCKING GATE)

**Before ExitPlanMode**, verify assumptions with real evidence. Convert UNKNOWN/ESTIMATED KPIs to MEASURED.

**The question**: "What does this plan ASSUME is true, and can I check it right now?"

**When to run**: Any UNKNOWN/ESTIMATED KPIs or verifiable assumptions.
**When to skip**: Trivial (<10 lines) + all KPIs MEASURED + no unverified assumptions.
**On DISPROVED**: Adjust plan. >50% disproved = REJECT and re-plan.
**On NO-GO feasibility**: STOP. Redesign.

Output format in plan file:

```
## 0.1 Pre-Validation Probe
**Status**: PASSED / FAILED / PARTIAL
**Run at**: YYYY-MM-DD HH:MM UTC

### Assumptions Tested
| # | Assumption | Test | Result | Verdict |
|---|-----------|------|--------|---------|
| 1 | [assumed true] | [how checked] | [found] | CONFIRMED/DISPROVED |

### KPI Baselines (UNKNOWN/ESTIMATED -> MEASURED)
| KPI | Was | Now | Source | Value |
|-----|-----|-----|--------|-------|

### Feasibility
| Check | Result | Go/No-Go |
|-------|--------|----------|

### Probe Verdict
- **VERDICT**: GO / NO-GO
```

### Sections 1-11 (invoke `/plan-checklist` for full templates)

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

---

## Quick Validation

- [ ] All 13 sections present with real content (0, 0.1, 1-11)
- [ ] TL;DR is Section 0 (reader understands plan in <10 seconds)
- [ ] Pre-Validation Probe ran (Section 0.1) — or justified skip
- [ ] All KPIs are MEASURED (probe converted UNKNOWN/ESTIMATED)
- [ ] At least 1 KPI MEASURED with cited source
- [ ] Existing code searched (not building from scratch)
- [ ] Simplest approach chosen
- [ ] Files Affected has Before/After/Why columns
- [ ] Modularity enforcement passed
- [ ] Testing strategy defined
- [ ] /document planned

---

## Sideways Detection

3+ consecutive failed attempts → re-plan. Scope creep >50% → re-plan.
Core assumption proven false → re-plan. Blocked by dependency → re-plan with alternative.
