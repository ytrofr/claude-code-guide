# Playwright MCP & E2E Testing

**Chapter 19** - Browser automation and end-to-end testing with Playwright MCP

**Created**: December 2025  
**Source**: Entry #224 (176/176 E2E tests passing)  
**Time to Implement**: 30 minutes

---

## Overview

Playwright MCP provides browser automation via accessibility tree inspection - no vision model needed. Combined with Playwright Test framework, you get powerful E2E testing capabilities.

### Two Approaches

| Approach            | Use Case                       | Tools                                                   |
| ------------------- | ------------------------------ | ------------------------------------------------------- |
| **Playwright MCP**  | Live debugging, manual testing | `browser_navigate`, `browser_snapshot`, `browser_click` |
| **Playwright Test** | Automated CI/CD testing        | `npx playwright test`                                   |

---

## Setup

### 1. Install Playwright MCP (User-Level)

```bash
# WSL/Linux - Use bundled Chromium (CRITICAL for WSL)
claude mcp add --scope user playwright -- npx -y @playwright/mcp@latest --browser chromium

# First-time: Download Chromium (~165MB)
npx playwright install chromium
```

**⚠️ WSL Note**: Default Playwright MCP looks for Chrome at `/opt/google/chrome/chrome` which doesn't exist in WSL. Always use `--browser chromium` flag.

### 2. Install Playwright Test Framework

```bash
npm install -D @playwright/test
npx playwright install
```

### 3. Create Playwright Config

```javascript
// playwright.config.js
const { defineConfig, devices } = require("@playwright/test");

module.exports = defineConfig({
  testDir: "./tests/e2e",
  timeout: 60000,
  use: {
    baseURL: "http://localhost:8080",
    trace: "on-first-retry",
  },
  projects: [
    { name: "chromium", use: { ...devices["Desktop Chrome"] } },
    { name: "Mobile Chrome", use: { ...devices["Pixel 5"] } },
  ],
});
```

---

## Playwright MCP Tools Reference

### Navigation

| Tool                    | Purpose       | Example                                           |
| ----------------------- | ------------- | ------------------------------------------------- |
| `browser_navigate`      | Go to URL     | `browser_navigate(url="https://app.example.com")` |
| `browser_navigate_back` | Back button   | `browser_navigate_back()`                         |
| `browser_close`         | Close browser | `browser_close()`                                 |

### Inspection (Most Used)

| Tool                       | Purpose                | Returns                           |
| -------------------------- | ---------------------- | --------------------------------- |
| `browser_snapshot`         | Get accessibility tree | Structured page content with refs |
| `browser_console_messages` | JS console output      | Logs, errors, warnings            |
| `browser_network_requests` | XHR/fetch requests     | Network activity, status codes    |

### Interaction

| Tool                    | Purpose              | Example                                                                  |
| ----------------------- | -------------------- | ------------------------------------------------------------------------ |
| `browser_click`         | Click element        | `browser_click(element="Login button", ref="e15")`                       |
| `browser_type`          | Type into input      | `browser_type(element="Email input", ref="e11", text="user@test.com")`   |
| `browser_fill_form`     | Fill multiple fields | `browser_fill_form(fields=[...])`                                        |
| `browser_select_option` | Dropdown selection   | `browser_select_option(element="Country", ref="e20", values=["Israel"])` |

### Capture

| Tool                      | Purpose         | Output                                  |
| ------------------------- | --------------- | --------------------------------------- |
| `browser_take_screenshot` | PNG screenshot  | Image file                              |
| `browser_resize`          | Change viewport | `browser_resize(width=375, height=667)` |

---

## 💡 Best Practices

### 1. Always Snapshot After Navigate

```
# WRONG: Navigate then immediately interact
browser_navigate(url="https://slow-site.com")
browser_click(element="Button")  # May fail - page not loaded

# CORRECT: Navigate, snapshot to verify, then interact
browser_navigate(url="https://slow-site.com")
browser_snapshot()  # Waits for page, returns structure
browser_click(element="Button", ref="e15")
```

### 2. Use Accessibility Labels, Not CSS Selectors

```
# WRONG: CSS selector
browser_click(element="#btn-submit")

# CORRECT: Accessibility label
browser_click(element="Submit button", ref="e15")
```

Playwright MCP uses accessibility tree, not DOM selectors.

### 3. Check Console for JS Errors

```
browser_navigate(url="https://app.example.com")
browser_console_messages(level="error")
```

Many bugs manifest as JavaScript errors before visible UI issues.

### 4. Use Network Requests to Catch API Failures

```
browser_navigate(url="https://app.example.com/dashboard")
browser_network_requests()
# Look for status >= 400
```

Catch backend issues before debugging frontend.

### 5. Test Mobile Viewport

```
browser_resize(width=375, height=667)  # iPhone SE
browser_snapshot()  # Check mobile layout
```

---

## E2E Test Patterns

### Pattern 1: Auth Bypass for Testing

```javascript
// tests/e2e/example.spec.js
const { test, expect } = require("@playwright/test");

// Global auth bypass for all tests
test.beforeEach(async ({ page }) => {
  await page.addInitScript(() => {
    localStorage.setItem(
      "authToken",
      JSON.stringify({
        token: "test-token-for-e2e",
        user: { id: 1, username: "test", role_id: 1 },
        timestamp: Date.now(),
      }),
    );
  });
});

test("should load dashboard", async ({ page }) => {
  await page.goto("/dashboard");
  await page.waitForLoadState("networkidle");
  await expect(page).toHaveTitle(/Dashboard/);
});
```

### Pattern 2: Use innerText for Visible Content Only

```javascript
// WRONG: textContent includes script tags
const content = await page.textContent("body");
expect(content).not.toContain("synthetic"); // May fail - word in JS code

// CORRECT: innerText only visible text
const content = await page.evaluate(() => document.body.innerText);
expect(content).not.toContain("synthetic"); // Only checks visible text
```

### Pattern 3: Sacred Compliance Validation

```javascript
test("should have RTL layout", async ({ page }) => {
  await page.goto("/dashboard");
  await page.waitForLoadState("networkidle");

  const dir = await page.getAttribute("html", "dir");
  expect(dir).toBe("rtl");

  const lang = await page.getAttribute("html", "lang");
  expect(lang).toBe("he");
});

test("should display Hebrew correctly", async ({ page }) => {
  await page.goto("/dashboard");
  const content = await page.textContent("body");

  // Check for Hebrew characters
  const hasHebrew = /[\u0590-\u05FF]/.test(content);
  expect(hasHebrew).toBeTruthy();

  // No encoding issues
  expect(content).not.toContain("???????");
});
```

### Pattern 4: API Response Capture

```javascript
test("should receive 200 from API", async ({ page }) => {
  const apiResponses = [];

  page.on("response", (response) => {
    if (response.url().includes("/api/")) {
      apiResponses.push({
        url: response.url(),
        status: response.status(),
      });
    }
  });

  await page.goto("/dashboard");
  await page.waitForLoadState("networkidle");

  const errors = apiResponses.filter((r) => r.status >= 400);
  expect(errors).toHaveLength(0);
});
```

---

## Debugging Workflow

### Live Bug Investigation

```
1. browser_navigate("http://localhost:8080/problem-page")
2. browser_snapshot()           # See page structure
3. browser_console_messages()   # Check for JS errors
4. browser_network_requests()   # Check for API failures
5. browser_take_screenshot()    # Visual capture
```

### Common Issues & Solutions

| Issue                    | Solution                                    |
| ------------------------ | ------------------------------------------- |
| "Not connected" error    | Restart Claude Code, or `pkill -f chromium` |
| "Browser already in use" | Call `browser_close` first                  |
| "Browser not installed"  | Run `npx playwright install chromium`       |
| Tests timeout            | Add `waitForLoadState('networkidle')`       |
| Auth redirect            | Add `page.addInitScript()` with token       |

---

## Integration with Testing Workflow

### Run Commands

```bash
# Run all E2E tests
npx playwright test

# Run specific file
npx playwright test tests/e2e/dashboard.spec.js

# Run with visible browser
npx playwright test --headed

# Debug mode (step through)
npx playwright test --debug

# Single browser
npx playwright test --project=chromium
```

### CI/CD Integration

```yaml
# .github/workflows/e2e.yml
name: E2E Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: npm ci
      - run: npx playwright install --with-deps
      - run: npm start &
      - run: npx playwright test
```

---

## Visual Regression Testing

Combine Playwright screenshots with comparison:

```javascript
test("visual regression - dashboard", async ({ page }) => {
  await page.goto("/dashboard");
  await page.waitForLoadState("networkidle");

  // Take screenshot
  await page.screenshot({
    path: "screenshots/dashboard.png",
    fullPage: true,
  });

  // Compare with baseline (using external tool)
  // pixelmatch, looks-same, or Percy
});
```

---

## Related Skills

- **testing-workflow-skill** - 5Q/60Q/Guardian test selection
- **visual-regression-testing-skill** - Screenshot comparison patterns
- **api-first-validation-skill** - Validate backend before UI testing

---

## Evidence

**Production Results** (December 2025):

- 176/176 E2E tests passing (100%)
- 5 test files covering critical workflows
- Chromium + Mobile Chrome browsers
- ~4 minutes full suite execution

---

## Next Steps

1. Set up Playwright MCP with `--browser chromium`
2. Create first test file in `tests/e2e/`
3. Add auth bypass pattern if needed
4. Run with `npx playwright test`
5. Integrate into CI/CD pipeline
