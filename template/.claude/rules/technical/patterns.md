# Universal Technical Patterns

**Scope**: ALL projects and environments
**Authority**: Standard patterns for technical consistency

---

## Development Workflow (Format-First)

```bash
# 90% Issue Prevention
npm run format       # 1. FORMAT FIRST (always)
npm run lint         # 2. CHECK SECOND
npm test            # 3. TEST THIRD
git add . && git commit -m "msg"  # 4. COMMIT FOURTH
```

---

## Core Patterns

```javascript
// Port Standard - Default development port
const PORT = process.env.PORT || 3000;

// Financial Precision - ALWAYS 2 decimal places
const cost = amount.toFixed(2);

// UTF-8 Encoding - Preserve character encoding
const text = "Special characters preserved";
```

---

## Modular Development Rules

| Rule                  | Standard                                           |
| --------------------- | -------------------------------------------------- |
| File Size Limit       | Max 500 lines (exceptions documented)              |
| Single Responsibility | One clear purpose per module                       |
| Extract Pattern       | Functions >50 lines -> separate modules            |
| Module Structure      | /src/modules/ for business, /src/utils/ for shared |

---

## Decision Framework

| Impact Level | Score | Action         |
| ------------ | ----- | -------------- |
| Critical     | 10    | Immediate      |
| High         | 7     | Current sprint |
| Medium       | 5     | Prioritize     |
| Low          | 2     | Backlog        |

**Priority Calculation**: (Impact x Urgency) / Effort

---

## Best Practices Enforcement

- **SOLID**: Single responsibility, Open-closed, Liskov, Interface segregation, Dependency inversion
- **DRY**: Don't Repeat Yourself
- **KISS**: Keep It Simple, Stupid
- **YAGNI**: You Aren't Gonna Need It
