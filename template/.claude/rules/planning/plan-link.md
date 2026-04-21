# Plan File Metadata - MANDATORY

**Authority**: Plan discoverability and traceability

---

## Rule

When writing a plan file, ALWAYS include the metadata header AND Section 0 (verbatim user prompt) immediately after the title:

```
# Plan: Title Here
> **Plan file**: /path/to/plans/{plan-name}.md
> **Branch**: {current-branch} | **Created**: YYYY-MM-DD HH:MM UTC
> **Topic**: Short description of what this plan is about (1 sentence)
> **Keywords**: keyword1, keyword2, keyword3 (3-6 searchable terms)

---

## Section 0 — Original User Prompt (verbatim, preserved)

> {user's original message verbatim, `> ` prefixed on every line — no edits}
```

**Section 0**: the single message that triggered plan mode. Verbatim, immutable during revisions. Later clarifications go in Section 1.

### Example

```
# Plan: Fix Authentication Bug
> **Plan file**: /home/user/.claude/plans/wild-tickling-pretzel.md
> **Branch**: dev-Auth | **Created**: 2026-02-16 14:30 UTC
> **Topic**: Fix session expiry bug causing logout loops on mobile
> **Keywords**: auth, session, logout, mobile, cookie
```

### Field Definitions

| Field     | Purpose                                      | Format                    |
| --------- | -------------------------------------------- | ------------------------- |
| Plan file | Clickable path in VS Code terminal           | Full absolute path        |
| Branch    | Which branch this plan targets               | Git branch name           |
| Created   | When the plan was written                    | ISO 8601 with time + UTC  |
| Topic     | 1-sentence summary of the plan's goal        | Plain text, max ~80 chars |
| Keywords  | Searchable terms for finding this plan later | 3-6 comma-separated terms |

**Why**: Plan files have random names (e.g., `wild-tickling-pretzel.md`).
Without metadata, you can't tell what a plan is about, which branch it targets, or when it was created.

### Searching Plans

```bash
# Find plans by keyword
grep -rl "keyword" ~/.claude/plans/

# Find plans by branch
grep -rl "dev-Auth" ~/.claude/plans/

# Find plans by date
grep -rl "2026-02" ~/.claude/plans/
```
