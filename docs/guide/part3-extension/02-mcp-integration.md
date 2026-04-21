---
layout: default
title: "MCP Integration"
parent: "Part III — Extension"
nav_order: 2
redirect_from:
  - /docs/guide/06-mcp-integration.html
  - /docs/guide/06-mcp-integration/
  - /docs/guide/18-perplexity-cost-optimization.html
  - /docs/guide/18-perplexity-cost-optimization/
  - /docs/guide/19-playwright-e2e-testing.html
  - /docs/guide/19-playwright-e2e-testing/
  - /docs/guide/19b-playwright-mcp-integration.html
  - /docs/guide/19b-playwright-mcp-integration/
---

# MCP Integration

**Part III — Extension · Chapter 2**

The **Model Context Protocol** (MCP) is the open standard Claude Code uses to talk to databases, APIs, browsers, and external services. An MCP server runs as a separate process, exposes **tools** (functions Claude can call) and optional **resources** (data Claude can read), and communicates with Claude Code over stdio. When Claude needs data or wants to perform an action, it calls a tool, the server executes it, and the result flows back.

This chapter covers **how to install, configure, and use** MCP servers. For the complete catalog of known-good servers (connection strings, scope recommendations, operational notes), see [Part VI / 05 — MCP Server Catalog](../part6-reference/05-mcp-server-catalog.md).

---

## 1. What MCP Is (And Why You Want It)

Without MCP, getting live data into a Claude Code session means pasting query results into the prompt. With MCP, Claude calls a tool, gets the data, and responds — no copy/paste, no context bloat, no stale information.

```
Claude Code (client) ──stdio──> MCP Server ──> External Service
                                                (DB, API, browser, etc.)
```

Key properties:

- **Live data.** Query a database in real time instead of pasting results.
- **Tool access.** Automate browsers, GitHub, web searches, file systems.
- **Persistent state.** Store and retrieve knowledge across sessions.
- **Zero context cost until called.** MCP tool definitions are deferred — they don't consume context window until Claude actually invokes one (since CC 2.1.97, with `ENABLE_TOOL_SEARCH=true`).

The rest of this chapter walks through the **install → configure → use → debug** loop.

---

## 2. Installing an MCP Server

### 2.1 The canonical command: `claude mcp add`

MCP servers are registered via the CLI:

```bash
claude mcp add --scope user playwright -- \
  npx -y @playwright/mcp@latest --browser chromium --isolated
```

Anatomy:

- `--scope user` — install at user scope (applies to all projects). Alternatives: `--scope project`, `--scope local`.
- `playwright` — the server's **name** (what you'll see in `/mcp`).
- `--` — separator between the `claude mcp add` flags and the server's launch command.
- The rest — the actual command line that starts the server process.

Registration is written to `~/.claude.json` (user scope) or the project equivalent. You can list what's installed with:

```bash
claude mcp list
```

### 2.2 `claude mcp add` writes to `~/.claude.json`, NOT `settings.json`

Older guides sometimes show an `mcpServers` block inside `settings.json`. **That block is silently ignored.** Claude Code does not read MCP server definitions from `settings.json`. The only supported registration path is `claude mcp add` (or editing `~/.claude.json` directly). If a server "isn't showing up" in `/mcp`, the most common cause is that someone configured it in `settings.json`.

The one thing `settings.json` is involved in: hooks that match MCP tool names (see §8 below) and environment variables used by wrappers.

### 2.3 Scope precedence

| Scope     | Location               | Use case                                          |
| --------- | ---------------------- | ------------------------------------------------- |
| `user`    | `~/.claude.json`       | Servers you want available in every project       |
| `project` | Project `.claude.json` | Team-shared servers committed with the repo       |
| `local`   | Local-only override    | Personal overrides that don't get committed       |

Higher-specificity scope wins for a given server name. Most installs are `--scope user`; use `--scope project` when a server is tied to this codebase (e.g., a Postgres MCP pointing at the project's dev database).

### 2.4 Environment variable expansion

The `env` block of an MCP server definition supports `${VAR}` expansion, resolving from the shell that launched Claude Code:

```json
{
  "env": { "API_KEY": "${MY_API_KEY}" }
}
```

This is the **only** place in Claude Code config where `${VAR}` expansion works — the top-level `env` block in `settings.json` treats values as literal strings. Keep real secrets in shell-profile exports and reference them here.

Enable `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1` in your shell profile to prevent API credentials from leaking into unrelated subprocesses.

### 2.5 Restart Claude Code after install

Newly-registered MCP servers don't connect to the current session. After `claude mcp add`, start a new session or use `/mcp reconnect` — then `/mcp` should show the server `✓ Connected`.

---

## 3. Server Catalog Reference

For known-good configurations of PostgreSQL, GitHub, Playwright, Perplexity, Basic Memory, Fetch, Slack, and other common servers — including connection strings, auth notes, typical tool names, and which scope to install at — see [Part VI / 05 — MCP Server Catalog](../part6-reference/05-mcp-server-catalog.md).

The rest of this chapter works through four case studies that illustrate integration patterns that generalize to any server.

---

## 4. Case Study: PostgreSQL (The Wrapper Pattern)

Direct database access from Claude Code — query tables, inspect schemas, validate data.

### 4.1 The obvious-but-wrong install

```bash
# Looks right, often fails on connection
claude mcp add --scope user postgres -- \
  npx -y @modelcontextprotocol/server-postgres "postgresql://user:pass@localhost:5432/db"
```

On WSL and some Linux distros, the Node.js `pg` driver hangs during SSL negotiation against local PostgreSQL. The connection appears to succeed, then every query times out. The fix is a one-line URL parameter: `?sslmode=disable`.

### 4.2 The wrapper pattern

Rather than hard-coding the DSN (which forces you to put credentials into the registered command line), use a small wrapper script that builds the connection string from environment variables:

```bash
#!/bin/bash
# ~/.claude/scripts/pg-mcp-wrapper.sh
# Appends ?sslmode=disable to PG_URL before launching the MCP server
URL="${PG_URL}?sslmode=disable"
exec npx -y @modelcontextprotocol/server-postgres "$URL"
```

Make it executable (`chmod +x ~/.claude/scripts/pg-mcp-wrapper.sh`), then register it:

```bash
claude mcp add --scope user postgres -- bash ~/.claude/scripts/pg-mcp-wrapper.sh
```

With the env var set in your shell profile:

```bash
export PG_URL="postgresql://user:pass@localhost:5432/db"
```

### 4.3 Why the wrapper, not inline flags

1. **Credentials stay out of the registered command**. `~/.claude.json` is less frequently audited than `.bashrc` and may end up in backups you don't own.
2. **`args` do not support `${VAR}` expansion**. Only the `env` block does. A wrapper script gives you the expansion.
3. **One place to encode quirks.** The `?sslmode=disable` fix is invisible to the caller — every Claude Code session Just Works.

### 4.4 Read-only credentials in production

Give Claude a database user with `SELECT`-only grants against production. A `DROP TABLE` in a session you didn't expect is a bad day. Dev databases can have full write access.

---

## 5. Case Study: Perplexity (Budget-Aware Workflow)

Perplexity MCP provides web-grounded search inside Claude Code. It charges per query (~$0.005–$0.02 per call). Left unchecked, it can burn through a $5/month budget on repeated searches for the same topics.

### 5.1 The cache-first pattern

The goal: **never pay for the same query twice**. Before any Perplexity call, check a persistent cache. Only hit Perplexity on cache miss, then cache the result immediately.

1. **Before search** → `mcp__basic-memory__search_notes("topic")`
2. **If found** → use the cached result (free).
3. **If not found** → call Perplexity, then immediately write the result with `mcp__basic-memory__write_note(folder="research-cache")`.

In practice this delivers 60–80% cost savings on repeated research topics. See Part IV / 03 — Basic Memory MCP for the cache implementation.

### 5.2 Enforcing cache-first with hooks (the two-hook sandwich)

Rules in CLAUDE.md are soft — Claude may skip the cache check under context pressure. Hooks are hard enforcement. Wrap every Perplexity call with a PreToolUse reminder and a PostToolUse capture:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "mcp__perplexity__search|mcp__perplexity__perplexity_ask|mcp__perplexity__perplexity_search",
        "hooks": [
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/perplexity-cache-check.sh",
            "statusMessage": "Checking research cache..." }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "mcp__perplexity__search|mcp__perplexity__perplexity_ask|mcp__perplexity__perplexity_search",
        "hooks": [
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/perplexity-cache-reminder.sh" }
        ]
      }
    ]
  }
}
```

Different Perplexity packages expose different tool names (`mcp__perplexity__search`, `mcp__perplexity__perplexity_ask`, etc.). The matcher must cover all variants — run `/context` to see the actual names, then pipe them with `|`.

The pattern generalizes: **PreToolUse = gate, PostToolUse = capture** works for any paid MCP tool.

### 5.3 Budget ceilings

Track cumulative spend in the PostToolUse handler. When daily spend approaches the ceiling, the reminder script can escalate its output (or flip to a PreToolUse deny). Cost discipline is an engineering problem, not a willpower problem.

---

## 6. Case Study: Playwright (Preferred on WSL)

Playwright MCP drives browsers via Playwright's accessibility-tree protocol — faster, cheaper, and more deterministic than vision-model-based alternatives because it reads structured page data rather than pixels.

### 6.1 WSL setup (install system deps first)

On WSL and bare Linux, Chromium needs shared libraries most distros don't ship by default. Install them **before** registering the MCP:

```bash
sudo apt-get update
sudo apt-get install -y \
  libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libcups2 libxcomposite1 \
  libxrandr2 libgbm1 libpango-1.0-0 libcairo2 libasound2t64
```

Missing these produces `error while loading shared libraries: libnspr4.so` at runtime — you'll only see it in the MCP stderr, not in `/mcp` status.

### 6.2 Register with the right flags

```bash
claude mcp add --scope user playwright -- \
  npx -y @playwright/mcp@latest --browser chromium --isolated
```

Flag meanings:

- `--browser chromium` — use Playwright's bundled Chromium. The default is to look for Chrome at `/opt/google/chrome/chrome`, which doesn't exist on WSL and fails hard.
- `--isolated` — prevents "browser already in use" errors across sessions by using a fresh profile each run.

Then download the browser binaries (~165 MB to `~/.cache/ms-playwright/`):

```bash
npx playwright install chromium
```

Restart Claude Code. Verify:

```bash
claude mcp list
# playwright: npx -y @playwright/mcp@latest --browser chromium --isolated - ✓ Connected
```

### 6.3 Core tool vocabulary

| Category     | Tools                                                                             |
| ------------ | --------------------------------------------------------------------------------- |
| Navigation   | `browser_navigate`, `browser_navigate_back`, `browser_close`                      |
| Inspection   | `browser_snapshot`, `browser_console_messages`, `browser_network_requests`        |
| Interaction  | `browser_click`, `browser_type`, `browser_fill_form`, `browser_select_option`, `browser_hover`, `browser_drag` |
| Capture      | `browser_take_screenshot`, `browser_resize`, `browser_evaluate`                   |
| Tabs         | `browser_tabs` (list / new / select / close)                                      |

### 6.4 Canonical workflow

```
1. browser_navigate("https://app.example.com")
2. browser_snapshot()          # Returns accessibility tree with element refs
3. browser_click(element="Submit button", ref="e15")
4. browser_snapshot()          # Verify new state
```

Always **snapshot after navigate**. The snapshot both waits for the page to settle and returns element refs (`e15`, etc.) that you use in subsequent interactions. Refs are Playwright-internal — you cannot predict them, you have to read them from a snapshot.

### 6.5 Interaction style

Playwright MCP identifies elements by **accessibility label + ref**, not by CSS selector:

```
# WRONG — CSS selector will fail
browser_click(element="#submit-btn")

# CORRECT — accessibility label + ref from snapshot
browser_click(element="Submit button", ref="e15")
```

For layout testing, resize first then snapshot:

```
browser_resize(width=375, height=667)   # iPhone SE viewport
browser_snapshot()
```

### 6.6 Chrome-in-Chrome MCP: why Playwright is preferred on WSL

An alternative MCP, `claude-in-chrome`, drives the user's actual Chrome. It's useful on macOS and Windows for live debugging of a real browsing session. On WSL, however, the browser connection regularly disconnects — `tabs_context` returns errors, `browser_click` times out, and recovering usually requires restarting Claude Code. Prefer Playwright MCP on WSL; reserve `claude-in-chrome` for macOS/Windows where it's stable.

### 6.7 When Playwright is the wrong tool

Playwright is for **browser UI automation**, not REST API testing. For APIs, use curl, the Bash tool, or a dedicated HTTP MCP. A Playwright call to "GET /api/users" loads the JSON in a browser window — slow, wasteful, and hard to assert against.

---

## 7. Case Study: Basic Memory (Persistent Knowledge Across Sessions)

Basic Memory MCP stores notes that survive across sessions — decisions, research cache, debugging history. It's the backbone of the Perplexity cache-first pattern in §5 and the cross-project knowledge graph in Part IV.

Registration is one command:

```bash
claude mcp add --scope user basic-memory -- npx -y basic-memory-server
```

Core tool vocabulary: `write_note`, `read_note`, `search_notes`, `build_context`, `recent_activity`, `edit_note`.

Because Basic Memory is the most cross-cutting MCP in the stack — it underpins cache-first cost control, multi-session continuity, and the cross-project knowledge lifecycle — the detailed guide (note schemas, progressive-disclosure search pattern, 3-layer retrieval, observation taxonomy) lives in [Part IV / 03 — Basic Memory MCP](../part4-knowledge/03-basic-memory-mcp.md).

---

## 8. Matching MCP Tools in Hooks

MCP tools are named `mcp__<server>__<tool>` where `<server>` is the name you registered with. Match them in `PreToolUse` / `PostToolUse` hooks the same way you match built-in tools:

```json
{
  "PreToolUse": [
    {
      "matcher": "mcp__postgres__query",
      "hooks": [
        { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/validate-sql-query.sh" }
      ]
    }
  ]
}
```

Common use cases:

- **Gate destructive SQL** (check that `DELETE`/`DROP`/`TRUNCATE` include a `WHERE` clause before the Postgres MCP executes).
- **Approval for GitHub writes** (`mcp__github__create_pull_request` — block if the branch isn't clean).
- **Cost control** (Perplexity cache-first — §5.2).
- **Audit logging** (capture every `mcp__slack__post_message` to an append-only log).

See Part III / 01 — Claude Code Hooks for the full hook authoring guide. The matcher syntax is identical; only the tool-name pattern changes.

---

## 9. Gotchas

### 9.1 `settings.json` is not where MCP servers go

Putting an `mcpServers` block in `settings.json` silently does nothing. Use `claude mcp add` (which writes to `~/.claude.json`). If `/mcp` doesn't show your server, this is the first thing to check.

### 9.2 WSL Chrome MCP disconnects

`claude-in-chrome` MCP is unstable on WSL — expect regular "not connected" errors. Use Playwright MCP instead. If you genuinely need to drive the user's Chrome (not a bundled Chromium), do that work on macOS or Windows.

### 9.3 `?sslmode=disable` for local Postgres

The Node `pg` driver's default SSL behavior hangs against local PostgreSQL on many distros. Always add `?sslmode=disable` to the DSN for local/dev databases. Production DBs behind TLS-terminating proxies don't need this — test both.

### 9.4 `args` does not support `${VAR}` expansion

Only the `env` block does. If you need a credential in the command line (a connection string, an API endpoint), use a wrapper script (see §4.2) and pass the raw value via `env`.

### 9.5 Restart required after install

New MCP servers don't auto-connect to the current session. Start a fresh session (or use `/mcp reconnect` in recent CC versions). If `/mcp` still doesn't show it, check `claude mcp list` to confirm registration landed.

### 9.6 Tool names vary between packages

Different NPM packages that implement the "same" MCP can expose different tool names. One Perplexity package uses `mcp__perplexity__search`; another uses `mcp__perplexity__perplexity_search`. Hooks matching these need to cover all variants with `|`. Confirm actual names with `/context`.

### 9.7 `disable-model-invocation` for side-effect servers

If an MCP server has side effects you don't want Claude invoking on its own (deploy commands, email sends, financial writes), mark it `disable-model-invocation: true` in the skill or agent frontmatter that wraps it. The server stays available for user-invoked calls; Claude can't reach for it during autocomplete of a plan.

### 9.8 `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1`

Set this in your shell profile. It prevents API credentials in your environment from leaking to unrelated subprocesses. Combined with MCP `env` blocks that reference `${VAR}` from the shell, it gives you a reasonable secret-handling posture without external tooling.

---

## 10. Debugging MCP Connections

When an MCP server isn't behaving, work through these in order.

**`/mcp` — check connection status.** Shows connected servers, available tools, and any connection errors. A server that registers but fails to start will show `✗ Disconnected`.

**`claude mcp list` — confirm registration.** If a server doesn't appear here, it's not registered — go back to §2.1. If it appears but `/mcp` shows disconnected, the server process is failing at startup.

**Test the launch command manually.** Run the exact command string from `claude mcp list` in a terminal. Most startup failures (missing package, bad DSN, missing system dependency) produce immediate error output there.

**Check the server's stderr.** MCP server stderr is logged; recent CC versions also surface errors in `/mcp`. For WSL Playwright, missing `libnspr4.so` shows up here.

**`/doctor` — MCP scope conflicts (CC 2.1.110+).** Flags when the same server name is registered at multiple scopes with different configs.

**Restart Claude Code.** A surprising number of transient MCP issues resolve with a fresh session. The overhead is low; try this before deeper debugging.

**Logs.** The CC logs directory captures MCP stdout/stderr. For long-running debugging, tail the log while reproducing the issue.

---

## 11. Security Considerations

MCP servers have **significant access**. A Postgres MCP can drop tables; a GitHub MCP can force-push; a Playwright MCP can fill a login form on any site Claude navigates to. Treat MCP permissions like system permissions.

Quick rules:

- **Read-only DB credentials** for production. Write-grants only on dev.
- **Environment variables for secrets.** Never hardcode tokens into `~/.claude.json` or wrapper scripts committed to a repo.
- **Minimal GitHub token scopes.** `repo` is too broad for most automation; prefer fine-grained tokens scoped to specific repos.
- **Review server source.** Before installing a third-party MCP, read what tools it exposes. `npx -y` will happily run arbitrary packages.
- **Project-level config** for DB/API servers tied to a codebase. User-level only for generic servers (Playwright, Basic Memory, Perplexity).

Full checklist, token scope matrix, and hardening steps: [Part VI / 06 — Security Checklist](../part6-reference/06-security-checklist.md).

---

## 12. See Also

- [Part VI / 05 — MCP Server Catalog](../part6-reference/05-mcp-server-catalog.md) — Known-good server configs (Postgres, GitHub, Playwright, Perplexity, Basic Memory, Fetch, Slack).
- [Part VI / 06 — Security Checklist](../part6-reference/06-security-checklist.md) — MCP permissions, token scopes, hardening.
- [Part IV / 03 — Basic Memory MCP](../part4-knowledge/03-basic-memory-mcp.md) — Note schemas, progressive-disclosure search, cache-first pattern internals.
- [Part III / 01 — Claude Code Hooks](01-hooks.md) — Hook authoring, matcher syntax, cost-gate pattern for paid MCPs.
- [Part II — Setup](../part2-setup/index.md) — Where `~/.claude.json` lives, scope hierarchy, shell-profile env-var handling.

---

**Previous**: [Part III / 01 — Claude Code Hooks](01-hooks.md) · **Next**: [Part III Index](index.md)
