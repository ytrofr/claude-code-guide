---
layout: default
title: "Setup Troubleshooting"
parent: "Part I — Foundation"
nav_order: 5
---

# Setup Troubleshooting

Most Claude Code setup failures fall into a dozen buckets, and almost all of them have a diagnostic that takes under a minute. This chapter is organized symptom-first -- find your symptom, try the fix.

**Purpose**: Unblock common setup issues fast
**Difficulty**: Beginner
**When to use**: The install or first session isn't behaving as expected

---

## 1. `claude` command not found

**Symptom**: `claude --version` returns "command not found" or "no such file."

**Diagnosis**:

```bash
which claude
echo $PATH
```

**Fix**:

- If `claude` installed but not on PATH: add the install dir to PATH in `~/.bashrc` or `~/.zshrc`, then `source ~/.bashrc`.
- If `claude` never installed: follow [claude.com/claude-code](https://claude.com/claude-code) to install the CLI itself. This guide's installer adds best practices *on top of* Claude Code; it does not install Claude Code.
- On WSL2: ensure you installed `claude` inside WSL, not on Windows. Windows-installed binaries won't show up in WSL's PATH by default.

---

## 2. OAuth login fails

**Symptom**: `claude` starts, opens a browser to authenticate, but login never completes or returns an error.

**Common causes and fixes**:

- **Firewall / corporate proxy**: Claude Code needs outbound HTTPS to `anthropic.com` and related domains. Check with `curl https://api.anthropic.com/v1/messages -I` -- if that fails, it's network.
- **Stale token**: clear the saved credentials and re-auth.
  ```bash
  rm -rf ~/.claude/credentials/
  claude  # will re-prompt for login
  ```
- **Headless environment**: if there's no browser, use `claude --bare` with `ANTHROPIC_API_KEY` set instead of OAuth. Useful for CI / SSH sessions.
- **WSL2**: the browser opens on Windows, and the callback may not reach WSL. If callback fails, try running `claude` in Windows Terminal with WSL tab (WSLg handles the callback cleanly) or fall back to `ANTHROPIC_API_KEY`.

---

## 3. Hook scripts not executing

**Symptom**: A hook in `.claude/hooks/*.sh` should fire on SessionStart / PreToolUse / etc., but nothing happens. No errors either.

**Check 1 -- executable bit**:

```bash
ls -l .claude/hooks/
# Scripts need +x
chmod +x .claude/hooks/*.sh
```

**Check 2 -- registered in settings.json**:

Hooks are not auto-discovered. They must be registered in `settings.json` under the right event:

```json
{
  "hooks": {
    "SessionStart": [
      { "command": "bash ${CLAUDE_PROJECT_DIR}/.claude/hooks/memory-context-loader.sh" }
    ]
  }
}
```

Typos in the event name (e.g. `"session-start"` instead of `"SessionStart"`) fail silently. Use exact event names from [Part VI/03 — Hook Event Catalog](../part6-reference/03-hook-event-catalog.md).

**Check 3 -- stdin pattern, not env vars**:

The legacy env-var hook API (`$CLAUDE_HOOK_INPUT`, `$CLAUDE_TOOL_INPUT`, `$CLAUDE_HOOK_EVENT`) is dead. Hooks now receive all data via **stdin JSON**. If your script reads from env vars, it reads empty strings.

```bash
#!/bin/bash
# CORRECT
INPUT=$(timeout 2 cat 2>/dev/null || true)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
```

**Check 4 -- portable paths**:

Use `$CLAUDE_PROJECT_DIR` (Claude Code sets this per-session) rather than hard-coded paths. Hard-coded paths break the moment the repo is cloned to a different location.

**Check 5 -- hook logs**:

```bash
ls -la ~/.claude/logs/
# Or project-scoped:
ls -la .claude/logs/
```

Most installed hooks log to `.claude/logs/<hookname>.log`. Empty or missing log = hook never fired.

---

## 4. MCP server not appearing

**Symptom**: Added an MCP server to `settings.json` under `mcpServers`, but `claude mcp list` doesn't show it, and the tools aren't available.

**Cause**: In recent Claude Code versions, MCP servers declared in `settings.json`'s `mcpServers` block are **silently ignored**. MCP registration must go through the `claude mcp add` CLI, which writes to `~/.claude.json`.

**Fix**:

```bash
# Remove the mcpServers block from settings.json
# Then register via CLI:

claude mcp add github -- npx -y @modelcontextprotocol/server-github
# Or with env:
claude mcp add github -e GITHUB_PERSONAL_ACCESS_TOKEN=ghp_xxx -- npx -y @modelcontextprotocol/server-github

# Verify:
claude mcp list
```

See [Part VI/05 — MCP Server Catalog](../part6-reference/05-mcp-server-catalog.md) for per-server recipes.

---

## 5. Skills not auto-activating

**Symptom**: Skill exists in `~/.claude/skills/myskill/SKILL.md` and `/skills` shows it, but Claude never invokes it automatically when the trigger situation arises.

**Cause 1 -- missing trigger clause in `description`**:

Claude auto-invokes skills based on the `description` field in the skill's frontmatter. Without an explicit trigger clause ("Use when..."), Claude can't auto-match.

**Bad**:

```yaml
---
name: myskill
description: Does a thing with files.
---
```

**Good**:

```yaml
---
name: myskill
description: Process CSV files into Parquet. Use when user asks to convert data files, reduce CSV size, or prepare data for analytics.
---
```

**Cause 2 -- description too short / no keywords**:

Description field has a 1536-char limit (was 250 pre-2.1.105). Use the space. Include the keywords Claude will encounter.

**Cause 3 -- `disable-model-invocation: true`**:

If the frontmatter has `disable-model-invocation: true`, Claude can't auto-invoke it -- only the user can. This is intentional for side-effect skills (deploys, commits) but often accidental.

**Cause 4 -- still not triggering**:

Check with `/skills` that the skill is loaded at all. If it's not, the skill directory name may have the deprecated `-skill` suffix (use bare names like `myskill/`, not `myskill-skill/`).

---

## 6. `settings.json` silently ignored

**Symptom**: Edited `settings.json`, but changes don't take effect. No errors.

**Cause 1 -- JSON syntax error**:

```bash
jq empty .claude/settings.json
# No output = valid JSON
# Error = your problem
```

Pre-2.1.99 versions would nuke the entire settings file on unrecognized event names. 2.1.99+ is more resilient (unknown keys ignored, rest still loads) -- but a JSON syntax error still kills the whole file.

**Cause 2 -- typo in hook event name**:

```json
"hooks": {
  "SessionStarts": [ ... ]   // BAD: should be "SessionStart"
}
```

Unknown event names are silently dropped. Always cross-check against the authoritative list in [Part VI/03 — Hook Event Catalog](../part6-reference/03-hook-event-catalog.md).

**Cause 3 -- scope confusion**:

`settings.json` cascades: `~/.claude/settings.json` (global) → `<project>/.claude/settings.json` (project) → `<project>/.claude/settings.local.json` (local). Later overrides earlier. If your "setting isn't working," check whether a more specific scope is overriding it.

---

## 7. `jq` not installed

**Symptom**: Installer fails with `jq: command not found` or similar.

**Fix**:

```bash
# Debian/Ubuntu/WSL2
sudo apt install jq

# macOS
brew install jq

# Arch
sudo pacman -S jq

# Verify
jq --version
```

The installer uses `jq` to read `manifest.json`; it's a hard dependency.

---

## 8. WSL2 Chrome MCP disconnects

**Symptom**: On WSL2, the Chrome MCP server (`mcp__claude-in-chrome__*`) disconnects mid-session or fails to connect at all.

**Cause**: Chrome MCP requires a running Chrome with the extension, and the WSL2 ↔ Windows Chrome bridge is unreliable (network isolation, handshake timing).

**Fix**: use Playwright MCP instead. Playwright runs fully inside WSL and doesn't need the browser bridge.

```bash
claude mcp add playwright -- npx -y @playwright/mcp
```

The `playwright-mcp` skill (installed with Recommended tier) wraps common flows (navigate, screenshot, form fill, extract). See [Part VI/05 — MCP Server Catalog](../part6-reference/05-mcp-server-catalog.md) for setup.

---

## 9. Pre-2.1.88: authoring `.claude/commands/`

**Symptom**: Created `.claude/commands/mycommand.md` expecting Claude Code to recognize a new slash command, but nothing happens.

**Cause**: Commands were merged into skills in Claude Code 2.1.88. The `commands/` directory is deprecated -- new slash commands are authored as skills.

**Fix**: migrate to skill format.

```bash
# Old (don't author this format any more):
# .claude/commands/mycommand.md

# New:
mkdir -p .claude/skills/mycommand
# Move content into .claude/skills/mycommand/SKILL.md
# Add frontmatter with `name` and `description` containing a trigger clause
```

See the `skill-creator` plugin or [Part III/01 — Skills](../part3-extension/01-skills.md) (when available) for the full authoring guide.

---

## 10. Nothing in this list matches

**Escalation path**:

### a) Run `/doctor`

```
/doctor
```

The `doctor` skill (Recommended tier) runs a self-diagnostic: checks Claude Code version, config parse, MCP health, hook registration, permissions. If it finds something, it'll tell you what. Since 2.1.105 the doctor can auto-fix many common issues (press `f`).

### b) Check the logs

```bash
ls -la ~/.claude/logs/       # Claude Code's own logs
ls -la .claude/logs/          # project-scoped hook logs
```

Look for the most recent file with content. Hook failures often leave a single-line error in their log file that points right at the problem.

### c) Inspect current state

```bash
# What does Claude Code think is loaded?
# Inside a Claude Code session:
/context         # shows context composition
/skills          # lists loaded skills
/cost            # session cost breakdown
claude mcp list  # lists registered MCP servers
```

### d) Grep the global rules and memory

Most failure modes encountered by prior sessions are documented. Inside Claude Code:

```
Search my ~/.claude/rules/ for the error I'm seeing.
```

Or grep the Basic Memory knowledge graph (Recommended tier with Basic Memory MCP):

```
Search memory for "hook not firing"
```

### e) Open an issue

If nothing resolves, the guide's GitHub issues are the last stop:

[github.com/ytrofr/claude-code-guide/issues](https://github.com/ytrofr/claude-code-guide/issues)

Include:

- `claude --version`
- OS / WSL2 status
- Relevant section of `settings.json` (sanitized)
- What you tried
- Full error if any

---

## Quick Diagnostic Commands

Keep these handy.

```bash
# Claude Code version
claude --version

# What settings are in effect
jq . ~/.claude/settings.json
jq . .claude/settings.json 2>/dev/null

# What MCP servers are registered
claude mcp list

# What hooks are registered
jq '.hooks' .claude/settings.json 2>/dev/null
jq '.hooks' ~/.claude/settings.json

# What rules are installed
ls ~/.claude/rules/
ls .claude/rules/

# What skills are installed
ls ~/.claude/skills/
ls .claude/skills/

# Marker file for this installer
cat .claude-best-practices-installed 2>/dev/null

# jq is present
jq --version

# Node is recent
node --version  # should be v18+
```

---

## Pointers

- **Installation details** -- [Part I/01 — Installation](01-installation.md)
- **Project structure reference** -- [Part I/03 — Project Structure](03-project-structure.md)
- **Hook event catalog + stdin schemas** -- [Part VI/03 — Hook Events](../part6-reference/03-hook-event-catalog.md)
- **MCP server catalog + setup** -- [Part VI/05 — MCP Servers](../part6-reference/05-mcp-server-catalog.md)
- **Skills + trigger clauses** -- [Part III/01 — Skills](../part3-extension/01-skills.md) (when available)
