# CITATION.cff Versioning — Release Rigor

**Scope**: claude-code-guide
**Authority**: MANDATORY on documentation releases

---

## When to Bump

Bump CITATION.cff version when:
- Adding new chapters (minor bump, e.g. 1.2.0 → 1.3.0)
- Major restructuring (major bump)
- Bug-fix-only releases (patch bump)

## Fields to Update

```yaml
version: "X.Y.Z"           # Semver
date-released: "YYYY-MM-DD" # Release date
abstract: "..."             # Update counters: chapters, hooks, rules
```

## Counter Sync

These numbers MUST agree across files:
- `CITATION.cff` abstract
- `README.md` hero section
- `CHANGELOG.md` latest entry description
- `llms.txt` header (if it has counts)

If any disagree after a push, the next session must fix them.

---

**Last Updated**: 2026-04-12
