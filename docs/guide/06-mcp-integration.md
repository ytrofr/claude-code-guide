# Chapter 6: MCP Integration

**Purpose**: Connect Claude Code to databases and external tools
**Source**: Anthropic MCP docs + Production production (48/48 tests, 100%)
**ROI**: High (zero-token validation, real-time data)

---

## Essential MCPs

| MCP | Cost | Use For |
|-----|------|---------|
| **GitHub** | FREE | PRs, issues, repo ops |
| **PostgreSQL** | FREE | Database queries |
| **Memory** | FREE | Persistent notes |
| **Perplexity** | $5/mo | Real-time search |

---

## Quick Setup

File: `.claude/mcp_servers.json`

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {"GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_xxx"}
    },
    "postgres-dev": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres",
               "postgresql://user:pass@localhost:5432/db"]
    }
  }
}
```

---

## Best Practices

1. **Read-only for production** - Use SELECT-only credentials
2. **Environment vars** - Don't hardcode tokens
3. **Cost optimize** - Use free WebSearch before Perplexity

**Full guide**: See Chapter 04 details in Production Entry #158-159

---

**Previous**: [05: Developer Mode](05-developer-mode-ui-feedback-system.md)
**Next**: [07: Skills Framework](07-skills-framework.md)
