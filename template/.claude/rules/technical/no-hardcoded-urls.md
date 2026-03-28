---
paths:
  - "**/*.{js,ts,jsx,tsx}"
  - "**/*.py"
---

# No Hardcoded URLs or Ports — Environment Config Only

**Scope**: ALL projects with staging/production environments or external services
**Authority**: MANDATORY — prevents environment drift and OAuth failures

---

## Core Rule

**NEVER hardcode base URLs, ports, API endpoints, or OAuth redirect URIs in source code. Always read from environment variables or config files.**

Hardcoded URLs cause silent failures when code runs in a different environment (localhost vs staging vs production).

---

## What Must Be Configurable

| Item | Example Bad | Example Good |
|------|------------|-------------|
| API base URL | `fetch('https://api.prod.example.com/...')` | `fetch(\`\${API_BASE_URL}/...\`)` |
| Service port | `app.listen(8080)` | `app.listen(process.env.PORT \|\| 8080)` |
| OAuth redirect | `redirect_uri: 'https://myapp.com/callback'` | `redirect_uri: process.env.OAUTH_REDIRECT_URI` |
| Webhook URL | `webhookUrl: 'https://n8n.example.com/webhook/abc'` | `webhookUrl: process.env.WEBHOOK_URL` |
| Database host | `host: 'db.internal.prod'` | `host: process.env.DB_HOST` |

## Exceptions (OK to Hardcode)

- `localhost` in development-only code (guarded by `NODE_ENV`)
- Well-known public URLs that never change (e.g., `https://accounts.google.com`)
- Protocol constants (`wss://`, `https://`)

## Quick Diagnostic

```bash
# Find hardcoded URLs in source (excluding node_modules, .git, tests)
grep -rn 'https\?://[a-z]' src/ --include='*.{js,ts,py}' | grep -v 'google.com\|github.com\|schema.org'
```

---

**Last Updated**: 2026-03-24
