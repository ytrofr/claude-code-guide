# Primacy-Recency Pattern for CLAUDE.md

**Scope**: ALL projects with CLAUDE.md
**Authority**: Context retention optimization
**Source**: Claude Code 2026 docs — "Stop Stuffing Everything into CLAUDE.md"

---

## Core Rule

**The first 5 and last 5 lines of CLAUDE.md are remembered best. Put critical rules there.**

Claude has a primacy/recency effect — middle content fades when the file is long. If a rule MUST be followed, put it at the top or bottom.

## Implementation

```markdown
<!-- CRITICAL RULES — Primacy Zone (top 5 lines) -->
<!-- 1. Your most critical rule -->
<!-- 2. Your second most critical rule -->
<!-- ... -->

# Project Title
... (normal CLAUDE.md content) ...

<!-- CRITICAL RULES — Recency Zone (bottom 5 lines) -->
<!-- Your most-forgotten rules that need reinforcement -->
```

## Why HTML Comments

- HTML comments are read by Claude but don't render in GitHub
- They stay out of the rendered README while being in the context window
- They don't interfere with the visual structure of CLAUDE.md

## When to Use

- Project has >100 lines in CLAUDE.md
- You have rules that get violated despite being documented
- You've corrected the same mistake 3+ times

---

**Last Updated**: 2026-03-20
