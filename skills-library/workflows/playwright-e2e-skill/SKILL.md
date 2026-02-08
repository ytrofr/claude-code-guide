---
name: playwright-e2e-skill
description: Browser automation and E2E testing with Playwright MCP. Use when automating web pages, testing UI, debugging visual issues, or validating user flows.
---

# Playwright E2E Testing Skill

**Purpose**: Browser automation via accessibility tree + E2E test patterns
**MCP Server**: `playwright` (user-level)
**Created**: December 2025
**Source**: production Entry #224 (176/176 tests passing)

---

## When to Use

- Automate web interactions (navigate, click, type)
- Debug UI issues with live browser inspection
- Run E2E test suites
- Validate page accessibility and structure
- Visual regression testing
- Mobile viewport testing

---

## Quick Start

### Setup

```bash
# Install MCP (WSL - use chromium flag)
claude mcp add --scope user playwright -- npx -y @playwright/mcp@latest --browser chromium

# Install test framework
npm install -D @playwright/test
npx playwright install chromium
```

### Live Debugging

```
1. browser_navigate("http://localhost:8080/dashboard")
2. browser_snapshot()           # Get page structure
3. browser_console_messages()   # Check JS errors
4. browser_network_requests()   # Check API failures
5. browser_click(element="Button", ref="e15")
```

### Run Tests

```bash
npx playwright test                    # All tests
npx playwright test --headed           # Visible browser
npx playwright test --debug            # Step through
npx playwright test --project=chromium # Single browser
```

---

## Key Tools

| Tool | Purpose |
|------|---------|
| `browser_navigate` | Go to URL |
| `browser_snapshot` | Get accessibility tree |
| `browser_click` | Click element |
| `browser_type` | Type into input |
| `browser_console_messages` | JS console output |
| `browser_network_requests` | API calls |
| `browser_take_screenshot` | Capture PNG |
| `browser_resize` | Change viewport |

---

## Best Practices

### 1. Always Snapshot After Navigate

```
browser_navigate(url="https://site.com")
browser_snapshot()  # Ensures page loaded
browser_click(element="Button", ref="e15")
```

### 2. Use Accessibility Labels

```
# WRONG: browser_click(element="#btn-submit")
# CORRECT: browser_click(element="Submit button", ref="e15")
```

### 3. Check Console for Errors

```
browser_console_messages(level="error")
```

### 4. Use Network Requests First

```
browser_network_requests()  # Catch API failures before UI debug
```

### 5. Test Mobile Viewport

```
browser_resize(width=375, height=667)
browser_snapshot()
```

---

## Test Patterns

### Auth Bypass

```javascript
test.beforeEach(async ({ page }) => {
  await page.addInitScript(() => {
    localStorage.setItem('authToken', JSON.stringify({
      token: 'test-token',
      user: { id: 1, username: 'test' },
    }));
  });
});
```

### Visible Text Only

```javascript
// Use innerText (not textContent) to exclude script content
const content = await page.evaluate(() => document.body.innerText);
expect(content).not.toContain('synthetic');
```

### API Response Capture

```javascript
const apiResponses = [];
page.on('response', (response) => {
  if (response.url().includes('/api/')) {
    apiResponses.push({ url: response.url(), status: response.status() });
  }
});
```

---

## Failed Attempts

| Wrong | Correct |
|-------|--------|
| CSS selectors (`#btn-submit`) | Accessibility labels (`Submit button`) |
| Navigate then immediate click | Navigate → snapshot → click |
| textContent for validation | innerText (excludes scripts) |
| Skip auth bypass | Add localStorage token injection |

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Not connected" | Restart Claude Code or `pkill -f chromium` |
| "Browser already in use" | Call `browser_close` first |
| "Browser not installed" | `npx playwright install chromium` |
| Tests timeout | Add `waitForLoadState('networkidle')` |
| Auth redirect | Add `page.addInitScript()` |

---

## Evidence

- **production**: 176/176 E2E tests passing (100%)
- **Coverage**: 5 test files, Chromium + Mobile Chrome
- **Execution**: ~4 minutes full suite

---

## Related

- `testing-workflow-skill` - Test selection decision tree
- `visual-regression-testing-skill` - Screenshot comparison
- `api-first-validation-skill` - Backend validation first
