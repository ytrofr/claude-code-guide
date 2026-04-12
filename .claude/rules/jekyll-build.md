# Jekyll Build — Pre-Commit Gate

**Scope**: claude-code-guide
**Authority**: MANDATORY before pushing to main (GH Pages auto-deploys)

---

Before committing changes that touch `docs/`, `_config.yml`, or chapter files:

```bash
# Option 1: Local bundle
bundle exec jekyll build 2>&1 | tail -5

# Option 2: Docker fallback (no local Ruby needed)
docker run --rm -v "$PWD:/srv/jekyll" jekyll/jekyll:4 jekyll build
```

If `jekyll build` fails, DO NOT push. Common failures:
- Invalid YAML front-matter (missing `---` delimiter)
- Liquid template errors (unescaped `{{` in code blocks — use `{% raw %}`)
- Missing layout reference (all chapters use `layout: default`)

GH Pages builds are NOT visible until push — broken builds = broken live site.

---

**Last Updated**: 2026-04-12
