# Chapter 6: MCP Integration

**Purpose**: Connect Claude Code to databases, APIs, and external tools via the Model Context Protocol
**Source**: Anthropic MCP docs + Production validation (48/48 tests, 100%)
**ROI**: High (zero-token validation, real-time data access, persistent knowledge)

---

## What is MCP?

The **Model Context Protocol** (MCP) is an open standard that lets AI assistants connect to external data sources and tools through lightweight servers. Instead of copying data into prompts, MCP gives Claude Code live access to databases, APIs, file systems, and more.

Each MCP server exposes **tools** (functions Claude can call) and optionally **resources** (data Claude can read). Claude Code discovers available tools automatically and uses them when relevant to your task.

**Key benefits**:

- **Live data**: Query databases in real time instead of pasting results
- **Tool access**: Automate browser testing, GitHub operations, web searches
- **Persistent state**: Store and retrieve knowledge across sessions
- **Zero tokens**: MCP tools don't consume context window until called

---

## How MCP Works with Claude Code

Claude Code connects to MCP servers as a client. Each server runs as a separate process, communicating over stdio. When Claude needs data or wants to perform an action, it calls the appropriate MCP tool, the server executes it, and returns results.

```
Claude Code (client) ──stdio──> MCP Server ──> External Service
                                                (DB, API, browser, etc.)
```

### Configuration Location

MCP servers are configured in your project's `.claude/mcp_servers.json` file:

```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "@package/name", "connection-string"],
      "env": {
        "API_KEY": "your-key-here"
      }
    }
  }
}
```

You can also configure MCP servers at the user level in `~/.claude/mcp_servers.json` for servers you want available across all projects.

---

## Popular MCP Servers

### PostgreSQL (Database Queries)

Direct database access for Claude Code -- query tables, check schemas, validate data.

```json
{
  "mcpServers": {
    "postgres-dev": {
      "command": "npx",
      "args": [
        "-y",
        "@anthropic-ai/mcp-server-postgres",
        "postgresql://user:pass@localhost:5432/mydb"
      ]
    }
  }
}
```

**Tools provided**: `query` (execute SQL)

**Best practice**: Use read-only credentials for production databases. Create a dedicated user with SELECT-only permissions.

### GitHub (PR and Issue Management)

Manage pull requests, issues, and repository operations without leaving Claude Code.

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_xxx"
      }
    }
  }
}
```

**Tools provided**: `create_issue`, `create_pull_request`, `search_repositories`, `get_file_contents`, and more.

### Playwright (Browser Automation)

Automate browser interactions for testing, screenshots, and web scraping.

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/mcp-server-playwright"]
    }
  }
}
```

**Tools provided**: `browser_navigate`, `browser_click`, `browser_fill_form`, `browser_take_screenshot`, `browser_snapshot`, and more.

### Perplexity (Web Search)

Real-time web search with AI-powered answers. Useful for current events, documentation lookups, and research.

```json
{
  "mcpServers": {
    "perplexity": {
      "command": "npx",
      "args": ["-y", "server-perplexity-ask"],
      "env": {
        "PERPLEXITY_API_KEY": "pplx-xxx"
      }
    }
  }
}
```

**Cost**: ~$0.005 per query. Use Claude Code's built-in `WebSearch` tool (free) for simple lookups first.

### Basic Memory (Persistent Notes)

Store and retrieve knowledge across sessions. Useful for decisions, patterns, and research caching.

```json
{
  "mcpServers": {
    "basic-memory": {
      "command": "npx",
      "args": ["-y", "basic-memory-server", "/path/to/memory-dir"]
    }
  }
}
```

**Tools provided**: `write_note`, `read_note`, `search_notes`, `build_context`, `recent_activity`.

### Fetch (Web Content Retrieval)

Fetch and parse web pages, APIs, and documentation.

```json
{
  "mcpServers": {
    "fetch": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/mcp-server-fetch"]
    }
  }
}
```

**Tools provided**: `fetch` (retrieve URL content as markdown).

---

## Debugging MCP Connections

Use the `/mcp` command in Claude Code to check server status:

```
/mcp
```

This shows:

- Which servers are connected
- Available tools per server
- Any connection errors

If a server fails to connect:

1. Check that the package is installable (`npx -y @package/name --help`)
2. Verify connection strings and API keys
3. Check that required services (databases, etc.) are running
4. Look at stderr output for error messages

---

## Security Considerations

MCP servers have significant access. Keep these practices in mind:

| Practice                              | Why                                          |
| ------------------------------------- | -------------------------------------------- |
| **Read-only DB credentials**          | Prevent accidental writes to production      |
| **Environment variables for secrets** | Don't hardcode tokens in config files        |
| **Project-level config**              | Scope servers to projects that need them     |
| **Review server source**              | Understand what tools a server exposes       |
| **Minimal permissions**               | GitHub tokens should have only needed scopes |

---

## MCP vs Built-in Tools

Claude Code has some built-in capabilities that overlap with MCP:

| Task         | Built-in           | MCP Alternative           |
| ------------ | ------------------ | ------------------------- |
| Web search   | `WebSearch` (free) | Perplexity (paid, deeper) |
| File reading | `Read` tool        | Filesystem MCP            |
| GitHub       | `gh` CLI via Bash  | GitHub MCP (richer API)   |
| Web fetch    | `WebFetch` tool    | Fetch MCP                 |

**Rule of thumb**: Start with built-in tools. Add MCP servers when you need deeper integration, persistent state, or specialized capabilities.

---

## Quick Start Checklist

1. Create `.claude/mcp_servers.json` in your project root
2. Add the server configuration (see examples above)
3. Restart Claude Code or start a new session
4. Run `/mcp` to verify the server is connected
5. Ask Claude to use the tool -- it will discover it automatically

---

**Previous**: [05: Developer Mode UI Feedback System](05-developer-mode-ui-feedback-system.md)
**Next**: [12: Memory Bank Hierarchy](12-memory-bank-hierarchy.md)
