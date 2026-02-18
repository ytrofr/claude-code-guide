# Validation Workflow - MANDATORY FOR EVERY TASK

**Scope**: Universal - ALL tasks
**Authority**: NO EXCEPTIONS to this workflow

---

## 7-Step Task Workflow

1. **UNDERSTAND** -> What exactly is needed? (not more)
2. **SEARCH** -> Does solution already exist? (use agents)
3. **VALIDATE** -> Pass all 5 pre-implementation gates
4. **DESIGN** -> Simplest approach that works
5. **IMPLEMENT** -> Only after validation passes
6. **TEST** -> Verify it works as intended
7. **REFACTOR** -> Simplify if possible

---

## 5 Pre-Implementation Gates (MANDATORY)

| Gate   | Check                     | Pass Criteria         |
| ------ | ------------------------- | --------------------- |
| Gate 1 | Existing solution check   | Via agents            |
| Gate 2 | Complexity assessment     | <100 lines            |
| Gate 3 | Modularity validation     | Single responsibility |
| Gate 4 | Best practices compliance | KISS/DRY/SOLID        |
| Gate 5 | Performance validation    | <1k tokens impact     |

---

## 6-Point Planning Validation

Before creating any plan:

1. **Simplicity**: Can this be solved with <50 lines? (Prefer simple)
2. **Reuse**: Does similar code/endpoint already exist?
3. **Modular**: Routes/Controllers/Services separated?
4. **Budget**: What's the cost vs managed service alternatives?
5. **Dependencies**: Zero new packages without justification
6. **Best Practices**: KISS/DRY/SOLID/YAGNI compliant?

---

## Production Impact Validation

### 3-Tier Validation Approach

1. **Code Correctness** - Does the code work as written?
   - Unit tests pass
   - No syntax/type errors
   - Functions return expected data structures

2. **Integration Validation** - Does it work in the real system?
   - Runs in actual pipeline
   - Integrates with existing services
   - No breaking changes to dependencies

3. **Production Impact** - Does it solve the actual problem?
   - Measure real metrics (performance, cost, etc.)
   - Compare before/after in production-like environment
   - Validate against original problem statement

**Only claim success if all 3 tiers pass.**
