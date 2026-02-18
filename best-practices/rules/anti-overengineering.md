# Anti-Over-Engineering Standards

**Source**: Production evidence
**Evidence**: 80% code reduction, 77% cost savings

---

## 6-Point Validation Checklist

**BEFORE creating any plan, validate:**

1. **Simplicity**: Can this be solved with <50 lines? (Prefer simple)
2. **Reuse**: Does similar code/endpoint already exist? (Check project documentation)
3. **Modular**: Routes/Controllers/Services separated? (Single responsibility)
4. **Budget**: What's the cost vs managed service alternatives?
5. **Dependencies**: Zero new packages without justification
6. **Best Practices**: KISS/DRY/SOLID/YAGNI compliant?
7. **Context Budget**: Does this add context Claude doesn't already have?

---

## Plan Validation Template

Add to EVERY plan:

```markdown
## PLAN VALIDATION

**Over-Engineering Check**:

- [What's over-engineered] -> [Simpler alternative]

**Metrics**:
| Aspect | Original | Simplified | Savings |
|--------|----------|------------|---------|
| Code | X lines | Y lines | Z% less |
| Files | X new | Y new | Z fewer |
| Cost | $X | $Y | $Z/month |

**Reuse Check**:

- Searched: [project docs, grep, existing code]
- Found: [Existing code to reuse]

**Final**: Proceed with [simplified/original] approach
```

---

## Real Example

**Cron migration**:

- Original: 150 lines, 2 files, $1.50/month, 2-3h
- Simplified: 30 lines, 0 files, $0.35/month, 1h
- **Savings**: 80% less code, 77% cheaper, 67% faster
