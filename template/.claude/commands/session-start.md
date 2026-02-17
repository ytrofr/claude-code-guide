---
description: "Initialize session following Anthropic best practices"
allowed_tools: ["Bash", "Read"]
---

# Session Start Protocol (Anthropic Best Practice)

Run these commands to discover current state:

```bash
echo "=== GIT STATUS ===" && git status --short && echo && echo "=== BRANCH ===" && git branch --show-current
```

```bash
echo "=== RECENT COMMITS ===" && git log --oneline -5
```

## Session Protocol

1. Review git status and recent commits above
2. Identify any uncommitted work or in-progress features
3. Select ONE task to focus on this session
4. Work incrementally with frequent commits

---

**Next Step**: Select ONE incomplete task and implement incrementally.

**Remember**:

- Focus on incremental progress
- Create checkpoint commits frequently
- Update status tracking before session end
