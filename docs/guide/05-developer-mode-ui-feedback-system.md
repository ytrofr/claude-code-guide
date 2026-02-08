# Developer Mode UI Feedback System

**Purpose**: Visual debugging tool for capturing UI issues with element selection, screenshots, and feedback forms  
**Access**: Super admin only (role_id = 1) in production, always enabled on localhost/dev  
**Created**: December 2025  
**Source**: Production implementation (Entry #177)

---

## Overview

The Developer Mode UI Feedback System provides a visual debugging interface that allows developers to:

1. **Select any UI element** with a crosshair cursor
2. **Capture screenshots** automatically using html2canvas
3. **Submit structured feedback** with priority, category, and tags
4. **Get Claude Code hints** for finding the relevant source files

### Key Features

- **Floating button** (bottom-left, RTL-aware) for one-click activation
- **Crosshair cursor** with element highlighting during selection
- **Auto-capture** of element info (selector, dimensions, computed styles, parent hierarchy)
- **Screenshot capture** of selected element
- **Feedback form** with title, description, category, priority, tags
- **Claude Code integration** - API returns suggested grep commands and likely files
- **Dark mode support** with CSS variables
- **Security** - uses textContent and safe DOM methods (no innerHTML with user data)

---

## Quick Start (5 minutes)

### Step 1: Add the Files

Copy these files to your project:

```
public/
├── js/
│   └── developer-mode.js    # Main JavaScript class
└── css/
    └── developer-mode.css   # Styling for all components

src/routes/admin/
└── dev-feedback.routes.js   # Backend API routes
```

### Step 2: Include in HTML Pages

Add to any page where you want Developer Mode available:

```html
<!-- At end of body, AFTER your main scripts -->
<script src="/js/developer-mode.js"></script>
```

The system auto-loads CSS when initialized (no need to add CSS link manually).

### Step 3: Register Routes

In your main Express app (index.js or similar):

```javascript
const devFeedbackRoutes = require('./src/routes/admin/dev-feedback.routes');

// Initialize with dependencies
const dependencies = { pool: yourDatabasePool };
app.use('/api/dev-feedback', devFeedbackRoutes(dependencies));
```

### Step 4: Create Database Tables

Tables are auto-created on first route initialization, but here's the schema:

```sql
CREATE TABLE dev_feedback (
    id SERIAL PRIMARY KEY,
    feedback_id VARCHAR(100) UNIQUE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'open',
    priority VARCHAR(20) NOT NULL DEFAULT 'medium',
    category VARCHAR(30) NOT NULL,
    tags TEXT[],
    page_url VARCHAR(500) NOT NULL,
    page_title VARCHAR(255),
    element_info JSONB NOT NULL DEFAULT '{}',
    screenshot_base64 TEXT,
    browser_context JSONB DEFAULT '{}',
    title VARCHAR(255) NOT NULL,
    description TEXT,
    steps_to_reproduce TEXT,
    resolution_notes TEXT,
    resolved_by VARCHAR(100),
    resolved_at TIMESTAMP,
    submitted_by VARCHAR(100) NOT NULL,
    assigned_to VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE dev_feedback_notes (
    id SERIAL PRIMARY KEY,
    feedback_id VARCHAR(100) REFERENCES dev_feedback(feedback_id) ON DELETE CASCADE,
    note_text TEXT NOT NULL,
    note_type VARCHAR(30) DEFAULT 'general',
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);
```

---

## Architecture

### Frontend (developer-mode.js)

```
DeveloperMode Class
├── init()                    # Initialize all components
├── createFloatingButton()    # SVG icon button (bottom-left)
├── createOverlay()           # Full-screen selection overlay
├── createHighlightBox()      # Element highlight (dashed border)
├── createTooltip()           # Element info on hover
├── createModal()             # Feedback form modal
├── bindEvents()              # Event listeners
├── handleMouseMove()         # Track mouse for highlighting
├── handleElementClick()      # Capture selected element
├── captureElementData()      # Gather all element info + screenshot
└── handleSubmit()            # POST to API
```

### Backend (dev-feedback.routes.js)

```
API Endpoints
├── GET  /api/dev-feedback           # List feedback (with filters)
├── GET  /api/dev-feedback/stats     # Dashboard statistics
├── GET  /api/dev-feedback/:id       # Single feedback with details
├── POST /api/dev-feedback           # Submit new feedback
├── PUT  /api/dev-feedback/:id       # Update status/priority
├── DELETE /api/dev-feedback/:id     # Delete feedback
└── POST /api/dev-feedback/:id/notes # Add note to feedback
```

### Claude Code Integration

The API response includes `claude_hints` for each feedback item:

```json
{
  "claude_hints": {
    "likely_files": ["public/dashboard/labor-cost.html", "src/routes/*labor*.js"],
    "suggested_search": "grep -r 'employee-count' public/",
    "element_path": "div.card > span.metric-value"
  }
}
```

---

## Customization

### Access Control

By default, Developer Mode checks:
1. **Localhost/dev**: Always enabled
2. **Production**: Checks `/api/auth/me` for `role_id === 1` (super admin)

To customize, modify the `initDevMode()` function:

```javascript
async function initDevMode() {
    // Your custom access logic
    const response = await fetch('/api/auth/me');
    const data = await response.json();
    
    if (data.user?.role === 'admin') {  // Your condition
        window.developerMode = new DeveloperMode();
        await window.developerMode.init();
    }
}
```

### Button Position (RTL vs LTR)

Default is bottom-left (RTL-friendly). For LTR layouts:

```css
.dev-mode-floating-btn {
    bottom: 2rem;
    right: 2rem;  /* Change from left to right */
    left: auto;
}
```

### Theme Variables

The system uses CSS variables for theming:

```css
/* Override these in your theme */
:root {
    --color-primary-500: #6366f1;
    --color-primary-600: #4f46e5;
    --bg-surface: #ffffff;
    --bg-card: #ffffff;
    --text-primary: #111827;
    --text-secondary: #6b7280;
    --border-default: #e5e7eb;
}

[data-theme="dark"] {
    --bg-surface: #1f2937;
    --bg-card: #1f2937;
    --text-primary: #f9fafb;
    --text-secondary: #9ca3af;
    --border-default: #374151;
}
```

---

## API Reference

### POST /api/dev-feedback

Submit new feedback:

```javascript
const response = await fetch('/api/dev-feedback', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
        title: "Button not clickable",           // Required
        category: "bug",                          // Required: bug|ui_issue|enhancement|question
        priority: "high",                         // Optional: critical|high|medium|low
        description: "The submit button...",      // Optional
        steps_to_reproduce: "1. Go to...",       // Optional
        tags: ["dashboard", "forms"],            // Optional
        page_url: "/dashboard/settings.html",    // Required (auto-captured)
        page_title: "Settings",                  // Optional (auto-captured)
        element_info: { selector: "...", ... },  // Required (auto-captured)
        screenshot_base64: "data:image/png...",  // Optional (auto-captured)
        browser_context: { viewport_width: ... } // Optional (auto-captured)
    })
});

// Response
{
    "success": true,
    "data": {
        "feedback_id": "df_20251217_a1b2c3d4",
        "created_at": "2025-12-17T10:30:00Z"
    }
}
```

### GET /api/dev-feedback

List feedback with filters:

```bash
curl "/api/dev-feedback?status=open&priority=critical&limit=10"
```

Query parameters:
- `status`: open|in_progress|resolved|all
- `priority`: critical|high|medium|low|all
- `category`: bug|ui_issue|enhancement|question|all
- `sort`: priority|created|updated
- `order`: asc|desc
- `limit`: number (default 50)
- `offset`: number (default 0)

### PUT /api/dev-feedback/:id

Update feedback status:

```javascript
await fetch('/api/dev-feedback/df_20251217_a1b2c3d4', {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
        status: 'resolved',
        resolution_notes: 'Fixed in commit abc123',
        resolved_by: 'claude_code'
    })
});
```

---

## Integration with Claude Code Workflows

### Using Feedback in Sessions

When you have Developer Mode feedback, Claude Code can use it:

```bash
# List open critical issues
curl -s localhost:8080/api/dev-feedback?status=open&priority=critical | jq

# Get specific feedback with Claude hints
curl -s localhost:8080/api/dev-feedback/df_20251217_a1b2c3d4 | jq '.data.claude_hints'
```

### Creating a Skill for Developer Feedback

Create `developer-mode-debugging-skill/SKILL.md`:

```markdown
---
name: developer-mode-debugging-skill
description: Debug UI issues captured via Developer Mode with element selection and screenshots
---

## When to Use

1. User says "there's a bug on the dashboard" → Check dev_feedback table
2. Working on UI issues → Use captured element selectors and screenshots
3. Need to find source files → Use claude_hints.likely_files and suggested_search

## Quick Commands

# List all open issues
curl -s localhost:8080/api/dev-feedback?status=open | jq '.data.items[] | {id: .feedback_id, title, priority, page_url}'

# Get full details with Claude hints
curl -s localhost:8080/api/dev-feedback/{feedback_id} | jq '.data'

# Mark as resolved after fixing
curl -X PUT localhost:8080/api/dev-feedback/{feedback_id} \
  -H "Content-Type: application/json" \
  -d '{"status":"resolved","resolution_notes":"Fixed X","resolved_by":"claude_code"}'
```

---

## Security Considerations

1. **No innerHTML** - All DOM manipulation uses safe methods (textContent, createElement)
2. **Access Control** - Production requires super admin authentication
3. **Input Validation** - Backend validates all required fields and enum values
4. **SQL Injection** - Uses parameterized queries only
5. **XSS Prevention** - Screenshot data stored/displayed safely

---

## Troubleshooting

### Floating Button Not Appearing

1. Check console for `[DEV-MODE]` messages
2. Verify `/api/auth/me` returns `role_id: 1` (or you're on localhost)
3. Ensure script is loaded after DOM ready

### Screenshot Capture Failing

1. html2canvas loads from CDN - check network tab
2. Cross-origin elements may not capture correctly
3. Check console for `[DEV-MODE] Screenshot capture failed`

### Form Submission 400 Error

Required fields: `title`, `category`, `page_url`, `element_info`

All are auto-captured except `title` and `category` which user must provide.

---

## Files Reference

| File | Purpose | Lines |
|------|---------|-------|
| `public/js/developer-mode.js` | Main JavaScript class | ~885 |
| `public/css/developer-mode.css` | All styling | ~537 |
| `src/routes/admin/dev-feedback.routes.js` | Backend API | ~670 |

---

## ROI & Time Savings

- **Issue Discovery**: Visual element capture saves 10-15 min/issue vs manual investigation
- **Context Preservation**: Screenshots + element info eliminate "can't reproduce" scenarios
- **Claude Code Integration**: Suggested grep commands save 5-10 min/issue
- **Estimated Savings**: 20-40 hours/year for active dashboard development

---

## Related Patterns

- **Task Tracking System**: See `docs/guide/04-task-tracking-system.md`
- **Skills System**: See `docs/guide/03-skills-framework.md`
- **Pre-prompt Hooks**: See `template/.claude/hooks/pre-prompt.sh.template`

---

**Pattern Source**: Production (Entry #177 - developer-mode-debugging-patterns.md)  
**Status**: Production validated December 2025  
**License**: MIT
