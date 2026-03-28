---
paths:
  - "**/.bashrc"
  - "**/.zshrc"
  - "**/.profile"
  - "**/*.env*"
  - "**/docker-compose*"
---

# API Key Hygiene — NEVER in Shell Profiles

**Scope**: ALL projects using API keys
**Authority**: MANDATORY — prevents env pollution across all child processes
**Evidence**: A `.bashrc` free-tier key overrode a billing key in a server process, causing hours of 429 errors

---

## Core Rule

**NEVER export API keys in `.bashrc`, `.profile`, `.zshrc`, or any shell profile.**

Shell profile exports pollute EVERY child process (servers, scripts, tests). Even `load_dotenv(override=True)` can't reliably fix this when process inheritance, caching, or forking is involved.

## Where API Keys Belong

| Location | When | Example |
|----------|------|---------|
| `.env.local` | Local development | `GOOGLE_API_KEY=AQ.Ab8R...` |
| Secret Manager | Production/staging | Cloud provider secrets |
| CI/CD env vars | Pipelines | GitHub Actions secrets |

## Where API Keys Do NOT Belong

| Location | Why Not |
|----------|---------|
| `.bashrc` / `.profile` | Pollutes ALL processes |
| `.env` (committed) | Exposed in git |
| Hardcoded in code | Obvious |
| Docker Compose env | Visible in `docker inspect` |

## Diagnostic

```bash
# Check for leaked keys in shell profiles
grep -r "API_KEY\|SECRET" ~/.bashrc ~/.profile ~/.zshrc 2>/dev/null
# Should return NOTHING
```

---

**Last Updated**: 2026-03-20
