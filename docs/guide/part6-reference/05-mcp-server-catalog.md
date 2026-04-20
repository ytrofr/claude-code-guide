---
layout: default
title: "MCP Server Catalog"
parent: "Part VI — Reference"
nav_order: 5
---

# MCP Server Catalog

Major Model Context Protocol (MCP) servers compatible with Claude Code, grouped by purpose. Install with:

```bash
claude mcp add <name> <transport-and-args>
```

Servers registered this way are stored in `~/.claude.json`. **Note**: the `mcpServers` block in `settings.json` is silently ignored — always use `claude mcp add`. For installation recipes and environment setup, see [Part III, Ch. 02 — MCP integration]({{ site.baseurl }}/guide/part3-extension/02-mcp-integration/).

---

## Official / reference implementations

Maintained by Anthropic (or forks thereof). Good starting points — well-documented, stable wire format.

| Server | Purpose | Source | Notes |
|---|---|---|---|
| `filesystem` | Read/write local files inside a scoped path | Anthropic MCP reference | stdio, path-scoped; prefer over ad-hoc Bash file ops where available |
| `fetch` | HTTP fetch with optional rendering | Anthropic MCP reference | stdio; lighter than a full browser when you only need HTML |
| `memory` | Knowledge-graph memory (entities + observations + relations) | Anthropic MCP reference | **Different** from Basic Memory — check which one fits your workflow |
| `brave-search` | Web search via Brave Search API | Anthropic MCP reference | Requires `BRAVE_API_KEY`; lower cost than Perplexity for simple lookups |
| `git` | Git repo inspection (log, diff, blame) | Anthropic MCP reference | Useful when you want Claude to read history without granting shell exec |

---

## Knowledge / memory

Long-lived stores that persist across sessions. Where Claude stashes learnings.

| Server | Purpose | Source | Notes |
|---|---|---|---|
| `basic-memory` | Semantic knowledge graph — Markdown + frontmatter + wiki-links, hybrid FTS+vector search | [basicmachines-co/basic-memory](https://github.com/basicmachines-co/basic-memory) | stdio; v0.20.2+ recommended for `metadata_filters` and per-query `min_similarity`. See [Part IV, Ch. 03]({{ site.baseurl }}/guide/part4-context-engineering/03-basic-memory-mcp/). |
| `memory` | Anthropic's reference knowledge-graph impl | Anthropic | Lighter than Basic Memory; no FTS, no frontmatter. Pick one, don't run both. |

---

## Database / data

Direct query access against your own databases. Faster and safer than granting shell access to `psql`.

| Server | Purpose | Notes |
|---|---|---|
| `postgres` | PostgreSQL queries, schema introspection, table reads | Multiple implementations available. On WSL / Node.js `pg`, a wrapper appending `?sslmode=disable` to the connection URL is often required — without it, `pg` hangs on SSL negotiation against plaintext Postgres. |
| `sqlite` | SQLite queries + schema introspection | Useful for FTS5-backed app databases and on-disk caches. |

---

## Web / research

External search and content extraction. Budget-aware.

| Server | Purpose | Notes |
|---|---|---|
| `perplexity` | Web search with model routing (`perplexity_ask`, `perplexity_search`, `perplexity_research`, `perplexity_reason`) | Budget-aware — set a monthly ceiling (e.g. $5/month) and use `perplexity_ask` for quick answers, `perplexity_research` for multi-source investigations. |
| `tavily` | Research API — search + extract | **Use Tavily Extract for LinkedIn** — Firecrawl explicitly blocks LinkedIn (`403 we do not support this site`). Tavily Extract handles it. |
| `firecrawl` | Scraping, structured extraction, crawling | Rich extraction and page rendering. **LinkedIn-blocked** — route LinkedIn URLs to Tavily instead. |

---

## Browser automation

For UI testing, screenshots, form filling, and data extraction.

| Server | Purpose | Notes |
|---|---|---|
| `playwright` | Headless browser control — navigate, click, snapshot, screenshot, network capture | **Preferred on WSL**. Stable, no session-disconnect issues. Ships with the `playwright-mcp` skill in the Recommended tier. |
| `claude-in-chrome` | Live Chrome extension — drives your actual browser tabs | Rich feature set (tabs, console, network, screenshots). **Known disconnection issues on WSL** — use Playwright if you hit reconnect loops. See [Part III, Ch. 02]({{ site.baseurl }}/guide/part3-extension/02-mcp-integration/) for routing guidance. |

---

## Development tools

| Server | Purpose | Notes |
|---|---|---|
| `github` | PRs, issues, reviews, file reads, code search | Preferred over `gh` CLI for programmatic access — typed responses, no stdout parsing. |
| `context7` | Version-specific library docs (React, Django, Next.js, Prisma, hundreds more) | Upstash-hosted. **Use BEFORE guessing library APIs** — your training data may not reflect recent changes. Reference: the context7 plugin ships with Claude Code official plugins. |

---

## Integrations / productivity

| Server | Purpose | Notes |
|---|---|---|
| `claude_ai_Gmail` | Read + send email via Gmail OAuth | Anthropic-hosted connector; OAuth flow handled by CC. |
| `claude_ai_Google_Calendar` | Read + create calendar events | Same OAuth model as Gmail. |
| `claude_ai_Google_Drive` | Read files from Drive | Complements filesystem when content lives in Drive. |

---

## Security / auditing

| Server | Purpose | Notes |
|---|---|---|
| `ecc-agentshield` | Scan `~/.claude/` configs for plaintext secrets, permission gaps, prompt-injection vectors | npx-invoked; scoring output. Run monthly against your global config directory. See [Part VI, Ch. 06 — Security checklist]({{ site.baseurl }}/guide/part6-reference/06-security-checklist/). |

---

## MCP-first philosophy

Before `npm install X` or `pip install X`, check whether an MCP server already does it. MCP servers run out-of-process, expose a typed tool interface, and don't pollute your project's dependency tree.

| Task | MCP Preferred | Don't install |
|---|---|---|
| Browser automation | `playwright` | Playwright/Chromium as project dep |
| Database queries | `postgres`, `sqlite` | psql/sqlite3 CLI |
| Web research | `perplexity`, `tavily` | curl/wget scripts |
| Knowledge storage | `basic-memory` | Ad-hoc JSON files |
| GitHub operations | `github` | `gh` CLI for read paths |

In the Recommended tier this is enforced via `rules/mcp/mcp-first.md`.

---

## Installing

Standard pattern (stdio transport via npx):

```bash
# Official reference impl
claude mcp add filesystem npx @modelcontextprotocol/server-filesystem ~/work

# Community / third-party
claude mcp add perplexity npx @perplexity-ai/mcp-server

# With an env var for the API key
claude mcp add tavily -e TAVILY_API_KEY=$TAVILY_API_KEY -- npx @tavily/mcp-server
```

Verify:

```bash
claude mcp list            # see all registered servers
claude mcp get <name>      # inspect one server's config
/doctor                    # CC 2.1.110+ warns on MCP scope conflicts
```

### Scope precedence

When the same MCP server name is registered at multiple scopes, CC resolves in this order (closest wins):

1. `--scope=local` (per-project, per-user)
2. `--scope=project` (per-project, shared via `.mcp.json`)
3. `--scope=user` (global, all projects)

Default scope is `user`. Override with `claude mcp add --scope=project <name>`.

---

## See also

- [Part III, Ch. 02 — MCP integration]({{ site.baseurl }}/guide/part3-extension/02-mcp-integration/) — full installation walkthrough
- [Part IV, Ch. 03 — Basic Memory MCP]({{ site.baseurl }}/guide/part4-context-engineering/03-basic-memory-mcp/) — deep dive on the knowledge-graph server
- [Part VI, Ch. 06 — Security checklist]({{ site.baseurl }}/guide/part6-reference/06-security-checklist/) — secrets, permissions, and MCP audit
