# Domain Patterns - [Project Name]

**Authority**: Project-specific business rules
**Scope**: Domain logic and business patterns

---

## Overview

This file contains domain-specific rules for your project. Customize based on your business requirements.

---

## Core Business Rules

### Rule Template

```yaml
Rule_Name:
  Description: 'What this rule enforces'
  Pattern: 'How to implement correctly'
  Violation: 'What NOT to do'
  Example: 'Code or usage example'
```

### Example: Data Validation

```yaml
Input_Validation:
  Description: 'All user input must be validated'
  Pattern: 'Use schema validation at API boundary'
  Violation: 'Trusting raw user input'
  Example: |
    const validated = schema.parse(req.body);
    // Use validated data, not req.body directly
```

---

## API Patterns

### Response Format

```javascript
// Standard success response
{
  "success": true,
  "data": { /* result */ },
  "metadata": { /* optional */ }
}

// Standard error response
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable message"
  }
}
```

---

## Database Patterns

### Query Safety

```javascript
// ✅ DO: Parameterized queries
const result = await db.query(
  'SELECT * FROM users WHERE id = $1',
  [userId]
);

// ❌ DON'T: String concatenation
const result = await db.query(
  `SELECT * FROM users WHERE id = ${userId}`  // SQL injection risk!
);
```

---

## Quick Reference

| Pattern | Usage | Priority |
|---------|-------|----------|
| Input Validation | All API endpoints | HIGH |
| Error Handling | All async operations | HIGH |
| Logging | All business operations | MEDIUM |

---

## Customization

Replace the examples above with your project-specific:

1. **Business rules** - Domain constraints and validations
2. **API standards** - Response formats, authentication
3. **Data patterns** - Database access, caching
4. **Integration rules** - External service patterns

---

**Related Skills**: [Add your project skills here]
