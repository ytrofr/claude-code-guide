# Chapter 19: Playwright MCP Integration

> Browser automation for Claude Code via accessibility tree (no vision model needed)

**Source**: Microsoft Playwright MCP (https://github.com/microsoft/playwright-mcp)
**LIMOR AI Entry**: #224 (Dec 31, 2025)
**Evidence**: Tested on limor.app - navigation, snapshots, interactions working

---

## Overview

Playwright MCP enables Claude Code to automate web browsers using Playwright's accessibility tree approach. Instead of screenshots and vision models, it uses structured accessibility data—making it faster, cheaper, and more reliable.

### Key Benefits

| Aspect | Playwright MCP | Screenshot-based |
|--------|----------------|------------------|
| Data Format | Structured accessibility tree | Pixel images |
| Model Type | Language model only | Vision model required |
| Speed | Faster (no image processing) | Slower (image analysis) |
| Cost | Lower (no vision models) | Higher (vision models) |
| Reliability | Higher (deterministic) | Lower (ambiguity risk) |

---

## Quick Start

### 1. Install Globally (All Claude Code Projects)

```bash
claude mcp add --scope user playwright -- npx -y @playwright/mcp@latest
```

### 2. Verify Installation

```bash
claude mcp list
# Should show: playwright: npx -y @playwright/mcp@latest - ✓ Connected
```

### 3. Test It Works

In your next Claude Code session, you'll have access to `browser_*` tools:

```
browser_navigate(url="https://example.com")
browser_snapshot()  # Returns accessibility tree
browser_screenshot()  # Returns page image
```

---

## Tool Reference

### Navigation Tools

| Tool | Purpose | Example |
|------|---------|--------|
| `browser_navigate` | Go to URL | `browser_navigate(url="https://limor.app")` |
| `browser_go_back` | Navigate back | `browser_go_back()` |
| `browser_go_forward` | Navigate forward | `browser_go_forward()` |
| `browser_reload` | Refresh page | `browser_reload()` |

### Inspection Tools

| Tool | Purpose | Returns |
|------|---------|--------|
| `browser_snapshot` | Get accessibility tree | Structured page content |
| `browser_get_console_logs` | Console output | Logs, errors, warnings |
| `browser_network_requests` | Network activity | XHR/fetch requests |

### Interaction Tools

| Tool | Purpose | Example |
|------|---------|--------|
| `browser_click` | Click element | `browser_click(element="Submit button")` |
| `browser_type` | Type into field | `browser_type(element="Search", text="query")` |
| `browser_fill` | Fill form field | `browser_fill(element="Email", text="a@b.com")` |
| `browser_hover` | Hover element | `browser_hover(element="Menu item")` |
| `browser_drag` | Drag and drop | `browser_drag(from="Item", to="Target")` |
| `browser_select` | Select option | `browser_select(element="Country", value="IL")` |

### Screenshot Tools

| Tool | Purpose | Output |
|------|---------|--------|
| `browser_screenshot` | Capture page | Base64 image |
| `browser_pdf_save` | Save as PDF | File path |

### Tab Management

| Tool | Purpose |
|------|--------|
| `browser_tab_list` | List all tabs |
| `browser_tab_new` | Open new tab |
| `browser_tab_select` | Switch to tab |
| `browser_tab_close` | Close tab |

---

## Common Patterns

### Pattern 1: Login Automation

```
1. browser_navigate("https://app.example.com/login")
2. browser_snapshot()  # Verify login form exists
3. browser_fill(element="Email", text="user@example.com")
4. browser_fill(element="Password", text="password123")
5. browser_click(element="Sign in")
6. browser_snapshot()  # Verify logged in
```

### Pattern 2: Form Filling

```
1. browser_navigate("https://form.example.com")
2. browser_snapshot()  # Get form structure
3. browser_fill(element="Name", text="John Doe")
4. browser_fill(element="Email", text="john@example.com")
5. browser_select(element="Country", value="Israel")
6. browser_click(element="Submit")
7. browser_snapshot()  # Verify submission
```

### Pattern 3: Data Extraction

```
1. browser_navigate("https://data.example.com")
2. browser_snapshot()  # Returns all page text in structured format
3. [Parse the accessibility tree for needed data]
```

### Pattern 4: Screenshot Documentation

```
1. browser_navigate("https://app.example.com/dashboard")
2. browser_screenshot()  # Capture for docs/reports
```

---

## Configuration Options

### Browser Selection

Playwright MCP defaults to Chromium. For other browsers:

```json
{
  "playwright": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@playwright/mcp@latest", "--browser", "firefox"]
  }
}
```

Options: `chromium` (default), `firefox`, `webkit`

### Headless Mode

Default is headless (no visible browser). For visible:

```json
{
  "args": ["-y", "@playwright/mcp@latest", "--headless", "false"]
}
```

### Viewport Size

```json
{
  "args": ["-y", "@playwright/mcp@latest", "--viewport-width", "1920", "--viewport-height", "1080"]
}
```

---

## Failed Attempts (What NOT to Do)

### Wrong: Using CSS Selectors

```
# DON'T: browser_click(element="#submit-btn")
# DO: browser_click(element="Submit button")
```

Playwright MCP uses accessibility labels/text, not CSS selectors.

### Wrong: No Snapshot Before Interaction

```
# DON'T: Navigate then immediately click
browser_navigate("https://slow-site.com")
browser_click("Button")  # May fail if page not loaded

# DO: Always snapshot to verify page loaded
browser_navigate("https://slow-site.com")
browser_snapshot()  # Waits for page, returns structure
browser_click("Button")
```

### Wrong: Using for API Testing

```
# DON'T: Use Playwright for API calls
# DO: Use curl, Bash, or HTTP tools for APIs
```

Playwright is for browser UI automation, not REST API testing.

---

## Validation Evidence

### Installation Test (Dec 31, 2025)

```bash
$ claude mcp list
playwright: npx -y @playwright/mcp@latest - ✓ Connected
```

### LIMOR AI Test (limor.app)

```
1. browser_navigate("https://limor.app") ✓
2. browser_snapshot() → Returns Hebrew accessibility tree ✓
3. browser_click("Dashboard") → Navigation works ✓
4. browser_screenshot() → Image captured ✓
```

---

## Integration with Other MCPs

| MCP | Integration Pattern |
|-----|-------------------|
| PostgreSQL | Verify data after browser action |
| GitHub | Automate GitHub web UI when API insufficient |
| Basic Memory | Cache automation patterns for reuse |
| Perplexity | Research site structure before automating |

---

## Troubleshooting

### Browser Binaries Not Found

```bash
# First run downloads ~300-400MB of browser binaries
# Wait for download to complete
npx playwright install chromium
```

### Connection Timeout

```bash
# Restart Claude Code session after installing MCP
# MCP servers start fresh with each session
```

### Element Not Found

```
# Use browser_snapshot() first to see available elements
# Match element text exactly as shown in accessibility tree
```

---

## Key Takeaways

1. **No Vision Model**: Uses accessibility tree = faster, cheaper, more reliable
2. **Global Install**: `--scope user` applies to ALL Claude Code projects
3. **Accessibility Labels**: Use element text/labels, not CSS selectors
4. **Snapshot First**: Always get page structure before interacting
5. **Browser UI Only**: For web apps, not APIs

---

**Related Guides**:
- [Chapter 06: MCP Integration](06-mcp-integration.md)
- [Chapter 18: Perplexity Cost Optimization](18-perplexity-cost-optimization.md)

**Skills**:
- `playwright-mcp-skill` (recommended)
- `comprehensive-testing-skill` (for E2E patterns)
