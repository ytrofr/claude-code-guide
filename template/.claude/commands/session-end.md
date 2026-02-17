---
description: "End session following Anthropic best practices"
allowed_tools: ["Bash", "Read"]
---

# Session End Protocol (Anthropic Best Practice)

Run these commands before ending session:

```bash
echo "=== UNCOMMITTED CHANGES ===" && git status --short
```

## Verification Checklist

Before ending this session, verify:

- [ ] All work committed or checkpointed?
- [ ] Status tracking updated with progress?
- [ ] No features left in unknown state?
- [ ] Descriptive commit message created?

## Checkpoint Command

If you have uncommitted work, create a checkpoint:

```bash
git add -A && git commit -m "checkpoint: [describe current work]"
```

---

**Remember**: Never stop mid-feature. Complete or checkpoint.
