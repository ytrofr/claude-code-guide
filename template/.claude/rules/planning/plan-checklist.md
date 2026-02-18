# Plan Mode Checklist - MANDATORY for Every Plan

**Authority**: Universal plan quality enforcement
**Scope**: ALL plans in ALL projects
**Enforcement**: Every plan MUST include ALL 11 sections below

---

## Rule

When writing ANY plan (via plan mode or /plan), the plan MUST contain these 11 mandatory sections. Do NOT skip any section. Each section must have real content, not placeholders.

---

## 11 Mandatory Plan Sections (Sections 0-10)

### Section 0: Requirements Clarification (BEFORE planning)

Before exploring code or writing the plan, ask clarifying questions.
Do NOT assume requirements -- confirm scope, constraints, and expected behavior first.

```
Questions to consider:
- Is the scope clear? (what's included, what's NOT)
- Are there constraints? (performance, compatibility, deadlines)
- What's the expected behavior? (input -> output, edge cases)
- Are there preferences? (approach, technology, patterns)
```

**Rule**: Skip ONLY if the user gave specific instructions with zero ambiguity.

### Section 1: Existing Code Check

```
## 1. Existing Code Check
- Searched: [list what was searched - grep, glob, skills]
- Found: [existing code/endpoints/patterns that can be reused]
- Reuse plan: [what existing code will be leveraged]
- New code needed: [only what doesn't exist yet]
```

**Rule**: Use Grep/Glob/Read BEFORE writing the plan.

### Section 2: Over-Engineering Prevention

```
## 2. Over-Engineering Check
| Aspect | Proposed | Simpler Alternative | Decision |
|--------|----------|---------------------|----------|
| Code   | X lines  | Y lines             | [why]    |
| Files  | X new    | Y new               | [why]    |
| Deps   | X new    | 0                   | [why]    |

- Can this be solved with <50 lines? [yes/no - if no, justify]
- Zero new dependencies? [yes/no - if no, justify each]
```

### Section 3: Best Practices Compliance

```
## 3. Best Practices
- [ ] KISS: Simplest solution that works
- [ ] DRY: No duplicated logic
- [ ] SOLID: Single responsibility per module
- [ ] YAGNI: No speculative features
- [ ] Security: No injection risks
```

### Section 4: Modular Architecture

```
## 4. Architecture
- Routes: [which route files affected]
- Controllers: [which controllers affected]
- Services: [which services affected]
- No logic in entry files (delegation only)
- Each file < 500 lines
```

### Section 5: Documentation Plan

```
## 5. Documentation
After implementation:
- [ ] Entry file (learned patterns)
- [ ] Skill (if pattern repeats 20+ times/year)
- [ ] Update status tracking
- [ ] Update relevant documentation
```

### Section 6: Testing Plan

```
## 6. Testing
- Unit tests: [what to test, expected count]
- Integration tests: [API endpoints to verify]
- E2E tests: [user flows to validate]
- Manual verification: [curl commands or browser checks]
```

### Section 7: Debugging and Logging

```
## 7. Debugging & Observability
- Logging: [what to log, at what level]
- Error handling: [how errors are caught and reported]
- Health checks: [endpoints to verify after deploy]
- Monitoring: [what metrics to watch post-implementation]
```

### Section 8: File Change Summary

```
## 8. Files Affected
| File | Action | What Changes |
|------|--------|-------------|
| `src/routes/auth.js` | MODIFY | Add logout endpoint |
| `src/services/session.service.js` | NEW | Session cleanup logic |
```

**Action values**: `NEW` (create), `MODIFY` (edit existing), `DELETE` (remove)

**Rule**: If you can't list the files, the plan isn't concrete enough.

### Section 9: Plan Summary (TL;DR)

```
## 9. TL;DR
- Add logout endpoint to auth routes with session cleanup
- Create session service for token invalidation
- Run auth tests + manual verification
```

**Rule**: A reader should understand the full plan from this section alone in <10 seconds.

### Section 10: Modularity Enforcement (BLOCKING GATE)

Every plan MUST pass ALL modularity checks below. **Plan is REJECTED if any check fails.**

```
## 10. Modularity Enforcement

### File Size Gate
- [ ] No file exceeds 500 lines after changes (if it will, identify split points)
- [ ] No function/method exceeds 50 lines (if it will, extract to named function)
- [ ] Every NEW file has ONE clear responsibility (state it in 1 sentence per file)

### Layer Separation Gate
- [ ] Routes: ONLY routing + middleware wiring (zero business logic)
- [ ] Controllers: ONLY request parsing + response formatting (delegate to services)
- [ ] Services: ALL business logic lives here
- [ ] No database queries outside services/database layer
- [ ] No HTTP response formatting inside services

### Extraction Gate
- [ ] Repeated logic (2+ occurrences) extracted to shared module
- [ ] Complex conditionals (>3 branches) extracted to named function
- [ ] Configuration/constants extracted to config files (not inline)

### God File Prevention
- [ ] Entry file stays under 500 lines (delegation only)
- [ ] No single service file handles more than 1 domain
- [ ] Will ANY existing file exceed 500 lines after these changes? [yes/no]
  - If yes: MUST include split plan (before/after line counts)
```

**Violation Response**: If ANY check fails, STOP. Redesign the plan to pass all checks.

**Rule**: This gate has equal weight to the Over-Engineering check (Section 2). A modular plan that's slightly more complex is ALWAYS preferred over a monolithic plan that's slightly simpler.

---

## Quick Validation

Before finalizing any plan, verify:

- [ ] All 11 sections present with real content
- [ ] Requirements clarified with user (or skipped -- instructions were unambiguous)
- [ ] Existing code searched (not building from scratch unnecessarily)
- [ ] Simplest approach chosen (not over-engineered)
- [ ] Modularity enforcement passed (no god files, layers separated, extractions done)
- [ ] Testing strategy defined (not "add tests later")
