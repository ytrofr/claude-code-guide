# Claude Code Guide - Project Instructions

**Repository**: https://github.com/ytrofr/claude-code-guide
**Purpose**: Comprehensive guide for Claude Code CLI tool + utility tools

---

## Project Structure

```
claude-code-guide/
├── install.sh               # One-command best practices installer
├── best-practices/          # Installable best practices package
│   ├── BEST-PRACTICES.md   # Universal best practices (dynamic, updated)
│   ├── rules/              # 6 universal rules (project-agnostic)
│   └── VERSION             # Version for update tracking
├── docs/                    # Documentation (Markdown, MDX)
├── template/                # Full clone-and-go starter
├── tools/                   # Standalone utility tools
│   └── trendradar-dashboard/  # AI Intelligence Hub
└── CLAUDE.md               # This file
```

## Best Practices Installer

The `install.sh` script installs universal best practices into any project.
The `best-practices/` directory is the source package -- update BEST-PRACTICES.md
and bump VERSION when best practices evolve. All installed projects can then
run their local `update.sh` to pull the latest version.

---

## AI Intelligence Hub

**Location**: `tools/trendradar-dashboard/`
**Port**: 4444
**Cost**: $0/month (all FREE APIs)

### Quick Start

```bash
cd ~/claude-code-guide/tools/trendradar-dashboard
npm install  # First time only
node server.js
# Open http://localhost:4444
```

### Features

- **FTS5 Hybrid Search**: Boolean operators (AND, OR, NOT), phrase matching, prefix search
- **10 Data Sources**: GitHub, HuggingFace, Hacker News, Product Hunt, Anthropic Blog, OpenAI Blog, AI News, TechCrunch AI, MIT AI News, MCP Registry
- **Advanced Filters**: Date range, score threshold, bookmarks only
- **Sort Options**: Relevance, Date Published, Stars, Recently Added
- **Saved Searches**: Persist filter combinations with names
- **Search Suggestions**: Autocomplete from search history
- **Grid/List View**: Toggle persisted to localStorage
- **SVG Icons**: 20+ crisp vector icons
- **Dark Theme**: LIMOR Chakra design with 15% larger fonts

### API Endpoints

| Endpoint                  | Method          | Description             |
| ------------------------- | --------------- | ----------------------- |
| `/api/health`             | GET             | Health check            |
| `/api/items`              | GET             | List items with filters |
| `/api/fetch`              | POST            | Fetch from all sources  |
| `/api/sources`            | GET             | List configured sources |
| `/api/bookmarks`          | GET/POST/DELETE | Manage bookmarks        |
| `/api/search/suggestions` | GET             | Search autocomplete     |
| `/api/search/saved`       | GET/POST/DELETE | Saved searches          |

### Architecture

- **Modular**: ~25 files, all under 200 lines
- **Database**: SQLite with FTS5 virtual table
- **Frontend**: Vanilla JS with CSS variables
- **Backend**: Express.js with modular routes

---

## Development Guidelines

- Follow existing patterns in the codebase
- Keep files modular and under 200 lines
- Use CSS variables for theming
- Test endpoints before committing
