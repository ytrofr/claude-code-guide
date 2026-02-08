# Chapter 19: Playwright MCP Integration

> Browser automation for Claude Code via accessibility tree (no vision model needed)

**Source**: Microsoft Playwright MCP (https://github.com/microsoft/playwright-mcp)
**Production Entry**: #224 (Dec 31, 2025)
**Evidence**: Tested on example.com - navigation, snapshots, interactions working

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

### 1. Install System Dependencies (WSL/Linux REQUIRED)

**🚨 CRITICAL for WSL**: Install these dependencies BEFORE Playwright MCP:

```bash
sudo apt-get update
sudo apt-get install -y libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 \
  libcups2 libxcomposite1 libxrandr2 libgbm1 libpango-1.0-0 libcairo2 libasound2t64
```

**Why needed**: Chromium requires these shared libraries. Without them, you'll see:
```
error while loading shared libraries: libnspr4.so: cannot open shared object file
```

### 2. Install Playwright MCP Globally

**For WSL/Linux (RECOMMENDED)**:
```bash
claude mcp add --scope user playwright -- npx -y @playwright/mcp@latest --browser chromium --isolated
```

**For macOS/Windows**:
```bash
claude mcp add --scope user playwright -- npx -y @playwright/mcp@latest
```

**Flags explained**:
- `--browser chromium`: Use bundled Chromium (WSL doesn't have system Chrome)
- `--isolated`: Prevent "browser already in use" errors

### 3. Install Browser Binaries

```bash
# Downloads ~165MB to ~/.cache/ms-playwright/
npx playwright install chromium
```

### 4. Verify Installation

```bash
claude mcp list
# Should show: playwright: npx -y @playwright/mcp@latest --browser chromium --isolated - ✓ Connected
```

### 5. Test It Works

**Restart Claude Code**, then test:

```
browser_navigate(url="https://example.com")
browser_snapshot()  # Returns accessibility tree
browser_screenshot()  # Returns page image
```

---

## Tool Reference

### Navigation Tools

| Tool | Purpose | Example |
|------|---------|---------|
| `browser_navigate` | Go to URL | `browser_navigate(url="https://example.com")` |
| `browser_navigate_back` | Navigate back | `browser_navigate_back()` |
| `browser_reload` | Refresh page | `browser_reload()` |

### Inspection Tools

| Tool | Purpose | Returns |
|------|---------|---------|
| `browser_snapshot` | Get accessibility tree | Structured page content |
| `browser_console_messages` | Console output | Logs, errors, warnings |
| `browser_network_requests` | Network activity | XHR/fetch requests |

### Interaction Tools

| Tool | Purpose | Example |
|------|---------|---------|
| `browser_click` | Click element | `browser_click(element="Submit button", ref="e123")` |
| `browser_type` | Type into field | `browser_type(element="Search", ref="e45", text="query")` |
| `browser_fill_form` | Fill multiple fields | `browser_fill_form(fields=[...])` |
| `browser_hover` | Hover element | `browser_hover(element="Menu", ref="e67")` |
| `browser_drag` | Drag and drop | `browser_drag(startElement="Item", startRef="e1", endElement="Target", endRef="e2")` |
| `browser_select_option` | Select dropdown | `browser_select_option(element="Country", ref="e89", values=["Israel"])` |

### Screenshot Tools

| Tool | Purpose | Output |
|------|---------|--------|
| `browser_take_screenshot` | Capture page/element | PNG file |
| `browser_evaluate` | Run JavaScript | Custom output |

### Tab Management

| Tool | Purpose |
|------|---------|
| `browser_tabs` (action="list") | List all tabs |
| `browser_tabs` (action="new") | Open new tab |
| `browser_tabs` (action="select") | Switch to tab |
| `browser_tabs` (action="close") | Close tab |

---

## Common Patterns

### Pattern 1: Login Automation

```
1. browser_navigate("https://app.example.com/login")
2. browser_snapshot()  # Verify login form exists
3. browser_fill_form(fields=[
     {name: "Email", type: "textbox", ref: "e5", value: "user@example.com"},
     {name: "Password", type: "textbox", ref: "e6", value: "password123"}
   ])
4. browser_click(element="Sign in", ref="e10")
5. browser_snapshot()  # Verify logged in
```

### Pattern 2: Form Filling

```
1. browser_navigate("https://form.example.com")
2. browser_snapshot()  # Get form structure & refs
3. browser_type(element="Name", ref="e3", text="John Doe")
4. browser_type(element="Email", ref="e4", text="john@example.com")
5. browser_select_option(element="Country", ref="e5", values=["Israel"])
6. browser_click(element="Submit", ref="e6")
7. browser_snapshot()  # Verify submission
```

### Pattern 3: Data Extraction

```
1. browser_navigate("https://data.example.com")
2. browser_snapshot()  # Returns all page text in structured YAML format
3. [Parse the accessibility tree for needed data]
```

### Pattern 4: Production Monitoring

```
1. browser_navigate("https://your-app.com")
2. browser_console_messages(level="error")  # Check for errors
3. browser_network_requests()  # Check API calls
4. [Alert if errors/failures found]
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
    "args": ["-y", "@playwright/mcp@latest", "--browser", "firefox", "--isolated"]
  }
}
```

Options: `chromium` (default, recommended for WSL), `firefox`, `webkit`

### Headless Mode

Default is headless (no visible browser). For visible:

```json
{
  "args": ["-y", "@playwright/mcp@latest", "--browser", "chromium", "--headless", "false"]
}
```

### Viewport Size

```json
{
  "args": ["-y", "@playwright/mcp@latest", "--browser", "chromium", "--viewport-width", "1920", "--viewport-height", "1080"]
}
```

---

## Failed Attempts (What NOT to Do)

### Wrong: Using CSS Selectors

```
# DON'T: browser_click(element="#submit-btn")
# DO: browser_click(element="Submit button", ref="e123")
```

Playwright MCP uses accessibility labels/text + refs from snapshot, not CSS selectors.

### Wrong: No Snapshot Before Interaction

```
# DON'T: Navigate then immediately click
browser_navigate("https://slow-site.com")
browser_click("Button", ref="e5")  # May fail if page not loaded

# DO: Always snapshot to verify page loaded
browser_navigate("https://slow-site.com")
browser_snapshot()  # Waits for page, returns structure with refs
browser_click("Button", ref="e5")
```

### Wrong: Using for API Testing

```
# DON'T: Use Playwright for API calls
# DO: Use curl, Bash, or HTTP tools for APIs
```

Playwright is for browser UI automation, not REST API testing.

### Wrong: Forgetting --browser chromium on WSL

```
# DON'T (hangs/fails on WSL):
claude mcp add --scope user playwright -- npx -y @playwright/mcp@latest

# DO (works on WSL):
claude mcp add --scope user playwright -- npx -y @playwright/mcp@latest --browser chromium --isolated
```

---

## WSL-Specific Setup (CRITICAL)

### Problem: Default Config Doesn't Work on WSL

**Issue**: Playwright MCP defaults to Chrome at `/opt/google/chrome/chrome` which doesn't exist in WSL.

**Symptom**: Browser hangs, "Not connected" errors, unresponsive MCP.

### Solution: Use Bundled Chromium

```bash
# 1. Install system dependencies (REQUIRED)
sudo apt-get update
sudo apt-get install -y libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 \
  libcups2 libxcomposite1 libxrandr2 libgbm1 libpango-1.0-0 libcairo2 libasound2t64

# 2. Install Playwright MCP with correct flags
claude mcp add --scope user playwright -- npx -y @playwright/mcp@latest --browser chromium --isolated

# 3. Install browser binaries
npx playwright install chromium

# 4. Restart Claude Code

# 5. Test
# In Claude Code: browser_navigate(url="https://example.com")
```

### Verified Working Config (WSL)

```json
{
  "playwright": {
    "type": "stdio",
    "command": "npx",
    "args": [
      "-y",
      "@playwright/mcp@latest",
      "--browser",
      "chromium",
      "--isolated"
    ]
  }
}
```

---

## Troubleshooting

### "Not connected" Error

**Symptom**: `browser_navigate` returns "Not connected" even though `claude mcp list` shows "Connected"

**Cause**: Browser process crashed or stale lock exists

**Solutions**:
1. **Restart Claude Code** (most reliable)
2. Kill Chromium: `pkill -f chromium`
3. Clear cache: `rm -rf ~/.cache/ms-playwright/mcp-chromium-*`

### "Browser is already in use"

**Cause**: Previous browser session didn't close cleanly

**Solutions**:
1. Use `--isolated` flag in MCP config (prevents this)
2. Call `browser_close()` before navigating
3. Restart Claude Code

### "Browser specified in config is not installed"

**Solution**: Install browser binaries:
```bash
npx playwright install chromium
```

### Missing Shared Libraries (WSL/Linux)

**Symptom**: `error while loading shared libraries: libnspr4.so`

**Solution**: Install system dependencies (see WSL-Specific Setup above)

### Browser Binaries Not Found

```bash
# First run downloads ~300-400MB
# Wait for download to complete
npx playwright install chromium
```

### Connection Timeout

```bash
# Restart Claude Code after installing MCP
# MCP servers start fresh with each session
```

### Element Not Found

```
# Always use browser_snapshot() first to see available elements
# Get element ref from snapshot, use exact text
```

---

## Validation Evidence

### Installation Test (Dec 31, 2025)

```bash
$ claude mcp list
playwright: npx -y @playwright/mcp@latest --browser chromium --isolated - ✓ Connected
```

### Production Production Test

**Test Results**:
- ✅ Navigation: `https://example.com` loaded successfully
- ✅ Accessibility tree: Full Hebrew RTL dashboard structure captured
- ✅ Interactions: Clicked chat button, typed Hebrew text
- ✅ Screenshots: 3 screenshots captured successfully
- ✅ Console logs: Error detection working (found 2 production errors)
- ✅ Network requests: API call monitoring working
- ✅ Multi-tab: Tab management working

**Data Extracted** (Dec 30, 2025):
- Labor cost ratio: 17.73%
- Total labor: ₪2,155
- Total sales: ₪12,156
- Shifts: 8 actual, 4 excluded
- Forecast: 20 products with trends

**Errors Found**:
- `/api/auth/me` → 404
- `/api/page-permissions/my-pages` → 500

---

## Integration with Other MCPs

| MCP | Integration Pattern | Example |
|-----|-------------------|---------|
| PostgreSQL | Verify UI matches DB | Extract dashboard value → query DB → compare |
| GitHub | Automate PR reviews | Navigate to PR → screenshot diff → analyze |
| Basic Memory | Cache test patterns | Store common workflows for reuse |
| Perplexity | Research before testing | Search for site structure before automating |

---

## Use Cases for Your Project

### 1. Production Monitoring (Immediate ROI)

```
Daily health check:
1. browser_navigate(production_url)
2. browser_console_messages(level="error")
3. browser_network_requests()
4. Alert if failures detected
```

**ROI**: Catch bugs in minutes vs hours/days

### 2. E2E Testing

```
Test critical workflows:
1. Login flow
2. Data submission
3. Report generation
4. Hebrew text input/display
```

### 3. Visual Regression

```
Before/after screenshots:
1. browser_navigate(dashboard)
2. browser_take_screenshot(filename="baseline.png")
3. [Make code changes]
4. browser_take_screenshot(filename="updated.png")
5. [Compare visually]
```

### 4. Accessibility Validation

```
Check page structure:
1. browser_snapshot()
2. Verify all buttons/inputs have labels
3. Check RTL for Hebrew pages
```

---

## Key Takeaways

1. **WSL Requires Special Setup**: Must use `--browser chromium --isolated` + system deps
2. **No Vision Model**: Uses accessibility tree = faster, cheaper, more reliable
3. **Global Install**: `--scope user` applies to ALL Claude Code projects
4. **Element Refs**: Get refs from `browser_snapshot()`, use in interactions
5. **Snapshot First**: Always get page structure before interacting
6. **Browser UI Only**: For web apps, not APIs
7. **Restart After Install**: MCP connection requires Claude Code restart

---

**Related Guides**:
- [Chapter 06: MCP Integration](06-mcp-integration.md)
- [Chapter 18: Perplexity Cost Optimization](18-perplexity-cost-optimization.md)

**Skills**:
- `playwright-mcp-skill` (recommended)
- `comprehensive-testing-skill` (for E2E patterns)
