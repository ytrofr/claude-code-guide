# Feature Toggle Principle — Every Optional Feature Needs a Kill Switch

**Scope**: ALL projects with optional or toggleable features
**Authority**: MANDATORY for new features that can be disabled independently

---

## Core Rule

**Every optional feature MUST have a `{FEATURE}_ENABLED` env var, defaulting to `true`, checked at the feature's entry point.**

## Pattern

```python
# Read once at module level
FEATURE_ENABLED = os.getenv("MY_FEATURE_ENABLED", "true").lower() == "true"

# Guard at entry point — skip silently if disabled
if not FEATURE_ENABLED:
    return
```

## Why

- Disable broken features without redeploying
- Gradual rollout (staging=true, production=false)
- Zero-downtime incident response
- A/B test features per environment

---

**Last Updated**: 2026-03-24
