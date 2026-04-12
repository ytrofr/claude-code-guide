# Public Repo Hygiene — claude-code-guide

**Scope**: claude-code-guide (public, MIT-licensed)
**Authority**: MANDATORY for all commits

---

## Checklist (before every push)

1. **No secrets**: `git diff --cached | grep -iE 'api.key|secret|password|token'` — must be empty
2. **No internal paths**: `git diff --cached | grep -E '/home/ytr|/Users/'` — must be empty
3. **Version refs current**: If claiming "CC 2.1.X compatible", verify X matches latest documented
4. **CITATION.cff synced**: Chapter count, hook count, rule count match actual `docs/guide/` contents
5. **LICENSE present**: MIT, no modifications
6. **robots.txt**: Allow all crawlers + AI bots

## Stale Version Detection

```bash
grep -rn "2\.1\.[0-8][0-9]\b" docs/guide/ --include="*.md" | grep -v "^.*:.*|" | head
# Any hits outside version-history tables = potentially stale reference
```

---

**Last Updated**: 2026-04-12
