---
layout: default
title: "Security Checklist"
parent: "Part VI — Reference"
nav_order: 6
redirect_from:
  - /docs/guide/62-security-scanning.html
  - /docs/guide/62-security-scanning/
---

# Security Checklist

*Detecting secrets, permission gaps, and injection risks in your `~/.claude/` setup.*

Your Claude Code configuration is executable surface area: hooks run shell, MCP servers inherit environment, skills can carry hidden directives, and `permissions.allow` entries gate every tool call. This chapter lists what to scan for, how to scan, how to automate it, and what to do when something leaks.

## Why Scan

A mature setup (dozens of rules, skills, and hooks) accumulates risk silently:

- A hook written last month may shell out with `rm -f` under `>/dev/null`
- An MCP server added "temporarily" still inherits every env var including `ANTHROPIC_API_KEY`
- A permission entry like `Bash(docker *)` lets the model run `docker exec -it ... sh`
- A skill fetched from a community repo may include curl-to-external in its body
- An OAuth `.credentials.json` can end up in git history if `.gitignore` is misconfigured

Scan monthly. Scan after every plugin/skill install. Scan after upgrading Claude Code — new features shift the threat model.

## What to Scan For

### 1. Plaintext secrets

API keys, tokens, passwords, connection strings — anywhere under `~/.claude/`.

- `~/.claude/settings.json` and `~/.claude/settings.local.json`
- `~/.claude.json` (MCP server definitions live here, **not** in `settings.json`)
- Project `.claude/settings.json` files
- `~/.bashrc` / `~/.zshrc` exports (these leak into every subprocess unless scrubbed — see CC 2.1.98 note below)
- MCP server `env` blocks
- Skills and rules markdown (people paste tokens into examples)

### 2. OAuth credential files in git

- `.credentials.json`, `credentials.json`, `token.json`, `*.pem`, `id_rsa*`
- Check both working tree AND git history — a token removed from `HEAD` still lives in `git log -p`

### 3. Overly broad permissions

`permissions.allow` entries that amount to arbitrary code execution:

| Pattern | Risk |
|---------|------|
| `Bash(*)` | Full shell access |
| `Bash(docker *)` | `docker exec -it <container> sh` |
| `Bash(node *)` | `node -e "require('child_process').exec(...)"` |
| `Bash(curl *)` | Arbitrary network fetch + pipe-to-shell |
| `Bash(npx *)` | Arbitrary package execution |
| `Bash(sudo:*)` | Privilege escalation |

Prefer narrow patterns: `Bash(docker ps)`, `Bash(docker logs *)`, `Bash(curl -sf http://localhost:*)`.

### 4. Missing or weak deny list

A deny list backstops the allow list. CC 2.1.99 made `permissions.deny` authoritative — it overrides PreToolUse "ask" hooks, so a correctly written deny entry cannot be bypassed by prompting a hook. But CC 2.1.98 also closed six bypass vectors in the deny matcher itself; your patterns must account for them.

**Minimum deny set** (every entry should resist CC 2.1.98-era bypass attempts):

```json
"deny": [
  "Bash(rm -rf /)*",
  "Bash(sudo:*)",
  "Bash(chmod 777 *)",
  "Bash(> /dev/*)",
  "Bash(ssh *)",
  "Bash(killall node)*",
  "Bash(pkill -f node)*",
  "Bash(pkill node)*"
]
```

The closing `*` and `:*` variants guard against compound-command smuggling and whitespace padding that earlier CC versions allowed through.

### 5. Hook scripts doing dangerous things

Hooks run unattended. Scan every file in `~/.claude/hooks/` and inline hook commands in `settings.json` for:

- `rm -f`, `rm -rf`, `> /dev/*`, `2>/dev/null` masking errors on deletes
- `git config --global` mutations
- Network egress: `curl`, `wget`, `nc`, `/dev/tcp/`, `/dev/udp/`
- Credential files read: `cat ~/.aws/*`, `cat ~/.ssh/*`, `cat **/credentials*`
- Environment dumps: `env >`, `printenv >`, unscoped `$*` passed to external commands

### 6. MCP servers

MCP definitions live in `~/.claude.json` (registered via `claude mcp add`), **not** `settings.json`. The `mcpServers` key in `settings.json` is silently ignored — do not rely on it for audit.

Risks to check in `~/.claude.json`:

- `@latest` tag on npm MCP servers → supply-chain risk; pin versions
- Remote transport (SSE/HTTP) to an unverified endpoint
- `autoApprove: true` on any tool
- Missing `env` block → server inherits every env var (including `ANTHROPIC_API_KEY`, DB credentials)
- Unexpected entries you didn't add (prompt injection via a skill could theoretically suggest `claude mcp add`)

### 7. Skill and rule bodies

Skills and rules are loaded into context unmodified. A malicious or careless body can plant instructions:

- External fetches in SKILL.md (`curl https://...`, `<img src=http://...>`)
- Hidden directives ("ignore previous instructions", unicode zero-width text)
- `allowed-tools` frontmatter requesting `Bash(*)`
- Skills or rules you don't remember adding

## Manual Scan Recipes

Copy-paste greps. Adjust paths as needed.

```bash
# 1. Plaintext API keys under ~/.claude/
grep -rEn 'sk-ant-(oat|ort|api)[0-9]{0,2}-[A-Za-z0-9_-]{30,}' <USER_HOME>/.claude/ <USER_HOME>/.claude.json 2>/dev/null
grep -rEn '(api[_-]?key|secret|password|token)["\s:=]+["A-Za-z0-9_-]{20,}' <USER_HOME>/.claude/ 2>/dev/null

# 2. SSH keys / certs accidentally stored
grep -rEn 'BEGIN (RSA|OPENSSH|DSA|EC|PRIVATE) KEY' <USER_HOME>/.claude/ 2>/dev/null

# 3. Broad allow entries
jq '.permissions.allow[]? | select(. | test("\\*\\)$|Bash\\(\\*|Bash\\((docker|node|curl|npx|bash) "))' \
  <USER_HOME>/.claude/settings.json

# 4. MCP servers with @latest or missing env
jq '.mcpServers | to_entries[] | select(
  (.value.args // [] | any(. | test("@latest$"))) or
  (.value.env == null)
) | .key' <USER_HOME>/.claude.json

# 5. Hook scripts doing network egress or unsafe deletes
grep -rEn '(curl|wget|nc|/dev/tcp|/dev/udp|rm -rf|rm -f.*>/dev/null)' <USER_HOME>/.claude/hooks/ 2>/dev/null

# 6. OAuth credential files tracked in git (run in each project)
git ls-files | grep -Ei '(credentials|token|secret).*\.(json|yaml|yml|env)$'
git log --all --diff-filter=A --name-only | grep -Ei 'credentials\.json|token\.json'
```

## Automated Scanning

Two skills do most of the manual work:

- **`/audit-stack`** — runs the full sweep above (permissions, hooks, MCP, skills, git hygiene) and produces a scored report. Use monthly and after major changes.
- **`/gitignore-anchor-audit`** — catches unanchored top-level directory entries in `.gitignore` that recursively shadow nested paths (the exact misconfiguration that lets `.credentials.json` sneak into git). Use when adding to `.gitignore`, after finding a tracked file you didn't expect, or on a new repo.

For public/shared repos, also run a third-party scanner periodically:

```bash
npx ecc-agentshield scan <USER_HOME>/.claude/
```

It scores across secrets, permissions, hooks, MCP servers, and skill bodies. Triage anything below 75 this month; anything below 50 this week.

## Pre-Push Discipline

When pushing a config repo (shared-setup, dotfiles, or the guide repo itself):

```bash
# Block real token material in staged diff — pattern strings are fine, token bodies are not
git diff --cached | grep -E 'sk-ant-oat01-[A-Za-z0-9_-]{30,}|sk-ant-ort01-[A-Za-z0-9_-]{30,}|sk-ant-api[0-9]{2}-[A-Za-z0-9_-]{30,}' \
  && { echo "REAL TOKEN IN DIFF — STOP"; exit 1; } || echo "no real tokens in diff"

# Block SSH/PEM keys
git diff --cached | grep -E 'BEGIN (RSA|OPENSSH|DSA|EC|PRIVATE) KEY' \
  && { echo "PRIVATE KEY IN DIFF — STOP"; exit 1; } || echo "no private keys"

# Block internal paths if repo is public
git diff --cached | grep -E '/home/[a-z]+/|/Users/[a-z]+/' \
  && echo "WARN: internal path in diff" || echo "no internal paths"
```

Wire the first two into a pre-push hook for any repo that has ever held a credential file.

## CC Version-Specific Notes

Several security-relevant changes landed in the 2.1.98–2.1.111 window. Update your mental model:

| Version | Change | What it means for audits |
|---------|--------|--------------------------|
| 2.1.98 | `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1` strips Anthropic API creds from subprocesses + triggers PID namespace isolation on Linux | Set this in `.bashrc` to stop shell subprocesses from inheriting API keys. **Trade-off**: incompatible with `skipDangerousModePermissionPrompt: true` — if you rely on that for automation, the scrub stays off and env-based MCP auth is still exposed. Pick one. |
| 2.1.98 | Six deny-list bypass vectors closed (compound commands, backslash escapes, `/dev/tcp`, `/dev/udp`, env-prefix commands, whitespace padding) | Old deny entries like `"Bash(ssh *)"` without the closing-paren variant may have been bypassable. Re-audit using the minimum deny set above. |
| 2.1.99 | Settings resilience: unrecognized hook event names fail gracefully instead of nuking the whole `settings.json` | A typo in a hook matcher no longer silently disables *all* your hooks. But a malicious skill that injects a malformed hook now fails quietly — scan hook output regularly. |
| 2.1.99 | `permissions.deny` overrides PreToolUse "ask" hooks | Any advice assuming a hook could gate a deny-listed tool is wrong. Deny wins. Move "ask"-style prompts to allowed tools; keep deny for hard blocks. |
| 2.1.105 | PreCompact hook can block compaction via `{"decision":"block"}` | Write a PreCompact hook that refuses compaction when context contains secrets-shaped strings or OAuth tokens — prevents a compacted summary from persisting a leaked credential. |
| 2.1.105 | Skill description budget 250 → 1536 chars | Longer descriptions can now hide prompt injection text; include skill descriptions in your grep for hidden directives. |

## Incident Response

If you find a leaked credential:

1. **Rotate immediately.** Don't clean up first — rotate the token at the provider (Anthropic console, Google OAuth, etc.) before anything else. Old token is now untrusted.
2. **Archive the leak.** Copy the offending file/commit to an offline archive for audit. Do not force-push the secret out of history until it's rotated — force-push can race with a cloner.
3. **Scrub history.** Once rotated, use `git filter-repo` or BFG to purge the file from all refs. Then `git push --force-with-lease` to the public remote.
4. **Audit reach.** Check recent provider logs for any access using the leaked token. Treat any unexpected use as hostile.
5. **Fresh init.** Regenerate the Claude Code setup that leaked it — run a clean `~/.claude/` tree from a known-good backup repo, then re-apply skills/rules file by file, re-scanning at each step.
6. **Write it up.** Add a note to your project memory describing what leaked, how, and what changed. This is the pattern that stops the next one.

## See Also

- Part I — Installation & Setup: initial permission and hook posture
- Part II — Core Configuration: `settings.json` structure, hook catalogue
- Part IV — Advanced Workflows: MCP server management
- `/audit-stack` skill — automated monthly scan
- `/gitignore-anchor-audit` skill — `.gitignore` recursive-shadow detection
