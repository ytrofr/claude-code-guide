# Universal Quality Standards

**Scope**: ALL projects and environments
**Authority**: Non-negotiable quality requirements

---

## Accuracy Standards

| Metric                 | Target                     |
| ---------------------- | -------------------------- |
| Technical Accuracy     | 99.997% (NEVER compromise) |
| Agent Coordination     | 100% success rate          |
| Context Relevance      | 100% task alignment        |
| Knowledge Organization | Mandatory validation       |
| Data Authenticity      | 100% (ZERO hardcoded)      |

---

## Self-Verification Before User Testing (MANDATORY)

```yaml
PRE_USER_TESTING:
  Rule: "ALWAYS self-test BEFORE asking user to test"
  Tier_1: "curl localhost:PORT/health, node --check, basic connectivity"
  Tier_2: "curl API -> verify JSON, check calculations"
  Tier_3: "Restart server, document expected behavior"
  Pattern: "Infrastructure -> Integration -> Document -> User"
```

---

## Validation Requirements

**ALWAYS enforce:**

1. Use agent system (never direct execution)
2. Validate before data operations
3. Investigate real data sources before coding
4. Maintain context hierarchy compliance
5. Preserve project-specific patterns
6. Respect knowledge boundaries
7. Enforce authentic data usage (never hardcoded)
