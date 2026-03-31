---
layout: default
title: "UI/UX Best Practices Rules — Enforced Standards from WCAG, Material Design & Core Web Vitals"
description: "Ship a global Claude Code rules file that enforces UI/UX best practices across all projects: accessibility (WCAG 2.2 AA), layout (Material Design 3), performance (Core Web Vitals 2026), forms, RTL, and Nielsen heuristics."
---

# Chapter 52: UI/UX Best Practices Rules

Most UI bugs aren't logic bugs — they're **standards violations**: missing focus indicators, tiny touch targets, poor contrast ratios, layout shifts, placeholder-only labels. These problems recur across every project because there's no enforcement layer.

This chapter shows how to create a **global Claude Code rule** that enforces UI/UX best practices automatically, sourced from authoritative standards.

## The Problem

Without enforced standards, Claude Code (or any AI assistant) may generate UI code that:

- Uses `<div onclick>` instead of `<button>` (not keyboard-accessible)
- Sets `font-size: 11px` (below readable minimum)
- Removes `:focus` outlines without replacement
- Creates 20px touch targets (too small for mobile)
- Uses color alone to convey meaning (fails for colorblind users)
- Omits `width`/`height` on images (causes layout shifts)

A rules file catches these at generation time.

## Sources

The rule file draws from five authoritative sources:

| Source | Authority | Key Contributions |
|--------|-----------|-------------------|
| [WCAG 2.2 AA](https://www.w3.org/WAI/standards-guidelines/wcag/) | W3C standard, legally required in EU/US | Contrast 4.5:1, touch 24px min, keyboard nav, text spacing |
| [Material Design 3](https://m3.material.io/) | Google's design system | 8px grid, type scale, spacing tokens, design tokens |
| [Core Web Vitals](https://web.dev/vitals/) | Google ranking signal | LCP ≤2.5s, INP ≤200ms, CLS ≤0.1 |
| [Nielsen Norman Group](https://www.nngroup.com/articles/ten-usability-heuristics/) | 30 years of usability research | 10 heuristics: system status, error prevention, user control |
| [CSS Logical Properties](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_logical_properties_and_values) | W3C/MDN | RTL-safe `margin-inline-start` instead of `margin-left` |

## The Rule File

Create at `~/.claude/rules/technical/ui-ux-best-practices.md` (global — applies to all projects):

```markdown
# UI/UX Best Practices - Enforced Standards

**Scope**: ALL projects with frontend UI
**Authority**: WCAG 2.2 AA, Material Design 3, Nielsen Norman Group, Core Web Vitals
**Created**: 2026-02-23
```

### 10 Categories

The file covers 10 enforceable categories, each with YAML rules and Correct/Forbidden code examples:

**1. Layout & Spacing** — 8px grid for all spacing. No arbitrary values like `padding: 13px`.

**2. Typography** — 16px minimum body text, max 2 typefaces, consistent type scale, `font-display: swap`.

**3. Color & Contrast** — 4.5:1 for text, 3:1 for UI components, never convey meaning by color alone.

**4. Interactive Elements** — 44px touch targets (recommended), visible focus indicators with 3:1 contrast.

**5. Responsive Design** — Mobile-first breakpoints, no horizontal scroll at 320px, explicit image dimensions.

**6. Accessibility (WCAG 2.2 AA)** — Semantic HTML, `<label for>` on all inputs, keyboard navigation, skip links, drag alternatives.

**7. Performance (Core Web Vitals)** — LCP ≤2.5s, INP ≤200ms, CLS ≤0.1. Only animate `transform`/`opacity`.

**8. Forms** — Persistent visible labels, inline validation after field completion, human-readable error messages with fix suggestions.

**9. Feedback & States** — Loading skeletons for operations >300ms, undo for destructive actions, helpful empty states.

**10. RTL & Internationalization** — CSS logical properties (`margin-inline-start` not `margin-left`), `lang`+`dir` attributes.

## Key Numbers to Remember

These are the most frequently referenced thresholds:

| Metric | Value | Source |
|--------|-------|--------|
| Text contrast ratio | 4.5:1 minimum | WCAG 2.2 AA |
| Large text contrast | 3:1 minimum | WCAG 2.2 AA |
| Touch target size | 44×44px (recommended) | Apple HIG |
| WCAG minimum target | 24×24px | WCAG 2.2 |
| Minimum body font | 16px | Browser default, M3 |
| Spacing grid unit | 8px | Material Design 3 |
| LCP threshold | ≤ 2.5 seconds | Core Web Vitals |
| INP threshold | ≤ 200 milliseconds | Core Web Vitals |
| CLS threshold | ≤ 0.1 | Core Web Vitals |
| Loading indicator | Show after 300ms | UX convention |
| Line height (body) | 1.5× font size | WCAG 2.2 |
| Letter spacing tolerance | 0.12× font size | WCAG 2.2 |

## CSS Logical Properties Quick Reference

For RTL/i18n support, replace physical properties with logical ones:

```css
/* BEFORE (breaks in RTL) */
margin-left: 16px;
padding-right: 8px;
text-align: left;
border-left: 2px solid;

/* AFTER (works in any direction) */
margin-inline-start: 16px;
padding-inline-end: 8px;
text-align: start;
border-inline-start: 2px solid;
```

All modern browsers support logical properties (Chrome, Firefox, Safari, Edge — since 2020).

## Example: Before and After

### Before (no rule enforcement)

```html
<div onclick="save()" style="font-size: 11px; padding: 5px;">
  <img src="icon.png">
  Save
</div>
```

Problems: not a `<button>`, no keyboard access, font too small, touch target too small, no alt text, inline styles, no focus indicator.

### After (with rule enforcement)

```html
<button class="btn-primary" aria-label="Save document">
  <img src="icon.png" alt="" width="16" height="16" aria-hidden="true">
  Save
</button>
```

```css
.btn-primary {
  min-height: 44px;
  min-width: 44px;
  font-size: 1rem;
  padding-inline: 16px;
}
.btn-primary:focus-visible {
  outline: 2px solid var(--color-primary-500);
  outline-offset: 2px;
}
```

## Installation

Copy the rule file to your global Claude Code rules:

```bash
# Create directory if needed
mkdir -p ~/.claude/rules/technical/

# Copy or create the file
cp ui-ux-best-practices.md ~/.claude/rules/technical/
```

The file is automatically discovered by Claude Code on every conversation.

## Combining with Project Rules

The global rule provides universal standards. Projects can add specific rules in `.claude/rules/`:

```
~/.claude/rules/technical/ui-ux-best-practices.md  (global - universal standards)
.claude/rules/hebrew/preservation.md               (project - Hebrew RTL specific)
.claude/rules/design/brand-colors.md               (project - brand guidelines)
```

Project rules override global rules when they conflict.

## Validation Checklist

The rule file ends with a quick validation checklist — run this before any UI ships:

- Contrast ratios pass (4.5:1 text, 3:1 UI)
- Touch targets >= 44px
- All inputs have visible `<label>`
- Keyboard navigation works (Tab through all interactive elements)
- No horizontal scroll at 320px
- Images have explicit width/height
- Loading states for async operations
- Error messages are human-readable with fix suggestions
- `font-display: swap` on custom fonts
- Core Web Vitals: LCP ≤ 2.5s, INP ≤ 200ms, CLS ≤ 0.1

---

**Key takeaway**: A 130-line rules file prevents the most common UI/UX violations at generation time — no separate linting tool needed. The standards haven't changed much in 30 years (Nielsen's heuristics are from 1994), so this file has a long shelf life.
