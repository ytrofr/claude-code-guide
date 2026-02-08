---
name: playwright-testing-skill
description: Browser automation with Playwright MCP. Use when automating web pages, testing UI, filling forms, taking screenshots, or extracting data from websites.
---

# Playwright Testing Skill

**Purpose**: Browser automation via accessibility tree (no vision model)
**MCP Server**: `playwright` (global user-level)
**Install**: `claude mcp add --scope user playwright -- npx -y @playwright/mcp@latest`

---

## When to Use

- Automate web interactions (navigate, click, type)
- Test web UI functionality
- Fill and submit forms
- Take page screenshots
- Extract data from rendered pages

---

## Quick Start

```bash
# Install globally (once)
claude mcp add --scope user playwright -- npx -y @playwright/mcp@latest

# Verify
claude mcp list  # Should show playwright connected
```

---

## Key Tools

| Tool | Purpose |
|------|---------|
| `browser_navigate` | Go to URL |
| `browser_snapshot` | Get accessibility tree |
| `browser_click` | Click element |
| `browser_type` | Type into field |
| `browser_fill` | Fill form field |
| `browser_screenshot` | Capture page image |

---

## Common Pattern: Login Flow

```
1. browser_navigate("https://app.example.com/login")
2. browser_snapshot()  # Verify form exists
3. browser_fill(element="Email", text="user@example.com")
4. browser_fill(element="Password", text="secret")
5. browser_click(element="Sign in")
6. browser_snapshot()  # Verify logged in
```

---

## Failed Attempts

### Wrong: CSS Selectors

```
# DON'T: browser_click(element="#btn-submit")
# DO: browser_click(element="Submit button")
```

Use accessibility labels, not CSS selectors.

### Wrong: No Snapshot First

```
# DON'T: Navigate then click immediately
# DO: Navigate → Snapshot → Click
```

Snapshot waits for page load and returns structure.

---

## Evidence

```bash
# Dec 31, 2025 - Verified
$ claude mcp list
playwright: npx -y @playwright/mcp@latest - ✓ Connected

# Production test on example.com
browser_navigate("https://example.com") ✓
browser_snapshot() → Hebrew accessibility tree ✓
browser_screenshot() → Image captured ✓
```

---

## Trigger Keywords

browser, automation, web testing, playwright, screenshot, form fill, click element
