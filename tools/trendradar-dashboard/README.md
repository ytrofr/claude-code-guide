# AI Intelligence Hub

Local dashboard tracking 12 AI sources with full-text search, bookmarks, and keyword scoring.

## Quick Start

```bash
cd ~/claude-code-guide/tools/trendradar-dashboard
npm install
node server.js
# Open http://localhost:4444
```

## Sources (12)

| Source               | Type        | Rate Limit | What It Tracks                                             |
| -------------------- | ----------- | ---------- | ---------------------------------------------------------- |
| GitHub Trending      | github      | 60 min     | AI/LLM/MCP repos by stars                                  |
| HuggingFace          | huggingface | 30 min     | Trending ML models                                         |
| Hacker News          | rss         | 5 min      | Front page tech news                                       |
| Product Hunt         | rss         | 15 min     | New product launches                                       |
| AI News              | rss         | 60 min     | AI industry newsletter                                     |
| Anthropic Blog       | rss         | 60 min     | Official Anthropic announcements                           |
| OpenAI Blog          | rss         | 60 min     | OpenAI research and updates                                |
| MCP Servers          | mcp         | 30 min     | MCP server registry (glama.ai)                             |
| TechCrunch AI        | rss         | 15 min     | AI category from TechCrunch                                |
| MIT AI News          | rss         | 60 min     | MIT AI research (disabled)                                 |
| Claude Code Releases | changelog   | 60 min     | GitHub releases with version notes                         |
| Claude Code Docs     | changelog   | 360 min    | 98 documentation pages (plugins, commands, skills, agents) |

## Architecture

```
server.js (port 4444)
├── modules/           # Source fetchers (BaseModule pattern)
│   ├── base-module.js # Abstract base with normalize()
│   ├── github.js      # GitHub trending repos
│   ├── huggingface.js # HuggingFace models
│   ├── rss.js         # RSS/Atom feeds
│   ├── mcp-registry.js# MCP server registry
│   └── changelog.js   # Claude Code releases + docs
├── config/
│   ├── sources.json   # Source definitions
│   └── keywords.json  # Scoring categories
├── database/          # SQLite with FTS5
├── routes/            # Express API routes
└── public/            # Frontend (vanilla JS)
```

## API

| Endpoint             | Description             |
| -------------------- | ----------------------- |
| `GET /`              | Dashboard UI            |
| `GET /api/items`     | List items (paginated)  |
| `GET /api/fetch`     | Trigger source fetch    |
| `GET /api/sources`   | List configured sources |
| `GET /api/bookmarks` | Manage bookmarks        |
| `GET /api/stats`     | Dashboard statistics    |
| `GET /api/search`    | Full-text search (FTS5) |
| `GET /api/health`    | Health check            |

## Adding Sources

1. Create a module in `modules/` extending `BaseModule`
2. Register it in `modules/index.js`
3. Add source config to `config/sources.json`
4. Add badge CSS in `public/css/components.css`

## Requirements

- Node.js 18+
- No external services needed (all APIs are free, no auth required)
