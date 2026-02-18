# MCP-First Rule - MANDATORY

**Authority**: Global enforcement for all projects
**Enforcement**: ALWAYS prefer MCP tools over npm/pip installations

---

## Core Rule

**BEFORE installing ANY tool via npm/pip/apt, CHECK if an MCP tool exists!**

```yaml
MCP_FIRST_ENFORCEMENT:
  Rule: "NEVER install tools when MCP equivalent exists"
  Check: "Search skills for '{tool}-mcp-skill' or check available MCPs"
  Violation: "Installing Playwright/Chromium when playwright-mcp exists"
```

---

## Decision Flow

```
Task requires tool (e.g., browser automation)
    |
1. CHECK: Is there an MCP skill?
    | YES
2. USE the MCP skill immediately
    | NO
3. CHECK: Is there an MCP server available?
    | YES
4. USE ToolSearch to find and select the tool
    | NO
5. ONLY THEN consider npm/pip installation
```

---

## Common MCP Tools

| Task               | MCP Tool         | DO NOT Install      |
| ------------------ | ---------------- | ------------------- |
| Browser automation | Playwright MCP   | Playwright/Chromium |
| Database queries   | PostgreSQL MCP   | psql client         |
| Web research       | Perplexity MCP   | curl/wget           |
| Knowledge storage  | Basic Memory MCP | Local JSON files    |
| GitHub operations  | GitHub MCP       | gh CLI              |

---

## Enforcement Triggers

```yaml
BLOCKED_PATTERNS:
  - "npm install playwright"
  - "npm install puppeteer"
  - "npx playwright install"
  - "pip install selenium"
  - "apt install chromium"

CORRECT_PATTERNS:
  - "I'll use the Playwright MCP..."
  - "ToolSearch for browser automation"
  - "Use MCP server for database queries"
```

---

## Why MCP-First?

1. **No installation needed** - MCP tools ready immediately
2. **Consistent interface** - Same patterns across projects
3. **No dependency bloat** - No node_modules growth
4. **Faster execution** - Pre-configured, optimized
5. **Better context** - MCP tools designed for Claude
