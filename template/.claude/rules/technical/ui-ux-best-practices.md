# UI/UX Best Practices - Enforced Standards

**Scope**: ALL projects with frontend UI
**Authority**: WCAG 2.2 AA, Material Design 3, Nielsen Norman Group, Core Web Vitals
**Created**: 2026-02-23
**Sources**: m3.material.io, w3.org/WAI, nngroup.com, web.dev/vitals

---

## 1. Layout & Spacing

```yaml
GRID: "8px base unit for ALL spacing (margins, padding, gaps)"
CONSISTENT: "Use spacing tokens (--spacing-xs/sm/md/lg/xl), never arbitrary values"
WHITESPACE: "Generous whitespace improves scanability - don't cram elements"
MAX_WIDTH: "Content max-width 1200-1440px with auto margins for centering"
```

**Correct**: `padding: 16px` (2 units), `gap: 24px` (3 units), `margin: 32px` (4 units)
**Forbidden**: `padding: 13px`, `margin: 7px` (non-grid values)

---

## 2. Typography

```yaml
MIN_BODY: "16px minimum body text (browser default, proven readable)"
MAX_TYPEFACES: "1-2 typefaces per project (1 sans-serif + optional mono)"
SCALE: "Use consistent type scale: 12/14/16/18/20/24/28/32/36/48px"
LINE_HEIGHT: "1.5 for body text, 1.2-1.3 for headings (WCAG 2.2 tolerance)"
FONT_DISPLAY: "font-display: swap on all @font-face (prevents invisible text)"
```

**Correct**: `font-size: var(--font-size-md)` with scale token
**Forbidden**: `font-size: 13px`, `font-size: 0.69rem` (off-scale arbitrary values)

---

## 3. Color & Contrast

```yaml
TEXT_CONTRAST: "4.5:1 minimum for normal text (WCAG 2.2 AA)"
LARGE_TEXT_CONTRAST: "3:1 minimum for large text (18pt+ or 14pt+ bold)"
UI_COMPONENT_CONTRAST: "3:1 minimum for UI components and graphical objects"
PALETTE: "1 primary + 1 accent + neutrals. Avoid 5+ competing colors"
SEMANTIC: "Green=success, Red=error, Yellow=warning, Blue=info (universal)"
NEVER_COLOR_ONLY: "Never convey meaning by color alone - add icon/text/pattern"
```

**Validation**: Use WebAIM Contrast Checker or browser DevTools contrast audit

---

## 4. Interactive Elements

```yaml
TOUCH_TARGET: "44x44px recommended (Apple HIG), 24x24px WCAG 2.2 minimum"
FOCUS_VISIBLE: "All interactive elements MUST have visible focus indicator"
FOCUS_CONTRAST: "3:1 contrast on focus indicators (WCAG 2.2)"
HOVER_STATE: "All clickable elements must show hover state change"
CURSOR: "cursor: pointer on buttons/links, cursor: text on inputs"
DISABLED: "Disabled elements: reduced opacity (0.5) + cursor: not-allowed"
```

**Correct**: `button { min-height: 44px; min-width: 44px; }`
**Forbidden**: Tiny 20px click targets, removing `outline` without replacement

---

## 5. Responsive Design

```yaml
MOBILE_FIRST: "Write base styles for mobile, enhance with min-width queries"
BREAKPOINTS: "320px (phone), 768px (tablet), 1024px (desktop), 1440px (wide)"
NO_HSCROLL: "No horizontal scroll at 320px width (WCAG 2.2 reflow)"
DIMENSIONS: "ALL images/videos/embeds MUST have explicit width + height"
VIEWPORT: "<meta name='viewport' content='width=device-width, initial-scale=1.0'>"
```

**Correct**: `@media (min-width: 768px) { .grid { grid-template-columns: repeat(2, 1fr); } }`
**Forbidden**: Fixed-width layouts, `@media (max-width)` as primary strategy

---

## 6. Accessibility (WCAG 2.2 AA)

```yaml
SEMANTIC_HTML: "Use <button>, <nav>, <main>, <header>, <footer> - not div soup"
LABELS: "All inputs MUST have <label for='id'> (never placeholder-only)"
ALT_TEXT: "All meaningful images need alt text; decorative images: alt=''"
KEYBOARD: "All functionality accessible via keyboard (Tab, Enter, Escape)"
SKIP_LINK: "Provide 'Skip to content' link for keyboard users"
ARIA: "Use ARIA only when semantic HTML is insufficient"
TEXT_SPACING: "Content must remain usable at: line-height 1.5x, letter-spacing 0.12x, word-spacing 0.16x"
DRAG_ALT: "Any drag-and-drop MUST have click/keyboard alternative (WCAG 2.2)"
```

**Correct**: `<button onclick="save()">Save</button>`
**Forbidden**: `<div onclick="save()">Save</div>` (not keyboard-accessible)

---

## 7. Performance (Core Web Vitals 2026)

```yaml
LCP: "Largest Contentful Paint <= 2.5s (preload hero image, inline critical CSS)"
INP: "Interaction to Next Paint <= 200ms (break long tasks, defer non-critical JS)"
CLS: "Cumulative Layout Shift <= 0.1 (explicit dimensions, font-display: swap)"
ANIMATION: "Only animate transform and opacity (GPU-composited, no layout thrash)"
LAZY_LOAD: "loading='lazy' on below-fold images, eager on above-fold"
IMAGE_FORMAT: "WebP/AVIF preferred (25-50% smaller than JPEG)"
CRITICAL_CSS: "Inline critical CSS in <head>, defer non-critical stylesheets"
```

**Correct**: `<img src="hero.webp" width="800" height="400" loading="eager" alt="...">`
**Forbidden**: Images without dimensions, render-blocking CSS in `<head>` for non-critical styles

---

## 8. Forms

```yaml
LABELS: "Visible persistent labels above inputs (never placeholder-only)"
REQUIRED: "Mark required fields with asterisk (*), label optional as '(optional)'"
VALIDATION: "Inline validation after field completion (not just on submit)"
ERRORS: "Plain language, specific problem + suggested fix, near the field"
ERROR_VISUAL: "Red border + icon + text (never color alone)"
AUTOCOMPLETE: "Use autocomplete attribute (name, email, tel, address)"
GROUPING: "Related fields in <fieldset> with <legend>"
```

**Correct**: Error: "Please enter a valid email address (e.g., name@example.com)"
**Forbidden**: Error: "Invalid input", Error: "Error 422"

---

## 9. Feedback & States (Nielsen Heuristics)

```yaml
LOADING: "Show skeleton/spinner for any operation >300ms"
PROGRESS: "Show progress indicator for operations >2s"
SUCCESS: "Confirm completed actions with transient success message"
ERRORS: "Plain language + what went wrong + how to fix it (Heuristic #9)"
UNDO: "Provide undo for destructive actions (Heuristic #3)"
EMPTY_STATE: "Helpful empty states with action CTA, not blank screens"
SYSTEM_STATUS: "Keep users informed of system state at all times (Heuristic #1)"
```

**Correct**: Skeleton loader while data fetches, then content replaces it
**Forbidden**: Blank screen during loading, cryptic error codes to users

---

## 10. RTL & Internationalization

```yaml
LOGICAL_PROPS: "Use CSS logical properties for RTL-safe layouts"
DIRECTION: "Set lang + dir attributes on <html> for i18n"
NUMBERS_LTR: "Numbers and currency always LTR within RTL context"
```

**Property Mapping** (use logical, not physical):

| Physical (avoid) | Logical (use) |
|---|---|
| `margin-left` | `margin-inline-start` |
| `margin-right` | `margin-inline-end` |
| `padding-left` | `padding-inline-start` |
| `padding-right` | `padding-inline-end` |
| `text-align: left` | `text-align: start` |
| `text-align: right` | `text-align: end` |
| `float: left` | `float: inline-start` |
| `border-left` | `border-inline-start` |

**Correct**: `margin-inline-start: 16px` (flips automatically for RTL)
**Forbidden**: `margin-left: 16px` in components that may be used in RTL contexts

---

## Quick Validation Checklist

Before any UI goes live:

- [ ] Contrast ratios pass (4.5:1 text, 3:1 UI)
- [ ] Touch targets >= 44px
- [ ] All inputs have visible `<label>`
- [ ] Keyboard navigation works (Tab through all interactive elements)
- [ ] No horizontal scroll at 320px
- [ ] Images have explicit width/height
- [ ] Loading states for async operations
- [ ] Error messages are human-readable with fix suggestions
- [ ] `font-display: swap` on custom fonts
- [ ] Core Web Vitals: LCP <= 2.5s, INP <= 200ms, CLS <= 0.1
