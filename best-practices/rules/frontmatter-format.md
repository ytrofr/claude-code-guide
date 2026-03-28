---
paths:
  - "**/.claude/skills/**/*.md"
  - "**/.claude/commands/*.md"
---

# Frontmatter Format — Hyphenated Keys, Comma-Separated Values

**Scope**: ALL skills and commands in `~/.claude/skills/` and `~/.claude/commands/`
**Authority**: MANDATORY — wrong format silently disables tool restrictions
**Evidence**: Production incident — commands had `allowed_tools` (underscored) for months, tool restrictions silently ignored

---

## Core Rule

**All YAML frontmatter in skills and commands MUST use hyphenated field names and comma-separated values.**

```yaml
# CORRECT
allowed-tools: Read, Bash, Grep
disable-model-invocation: true
user-invocable: false

# WRONG — silently ignored
allowed_tools: ["Read", "Bash", "Grep"]
```

## When to Apply

- Creating any new command in `~/.claude/commands/`
- Creating any new skill in `~/.claude/skills/`
- Editing frontmatter of existing commands/skills
- Reviewing commands/skills during audits

## Official Field Reference

| Field | Format | Example |
|-------|--------|---------|
| `allowed-tools` | Comma-separated | `Read, Bash, Grep, Glob` |
| `disable-model-invocation` | Boolean | `true` or `false` |
| `user-invocable` | Boolean | `true` or `false` |
| `argument-hint` | Quoted string | `"[topic-name]"` |
| `model` | Bare string | `haiku`, `sonnet`, `opus` |
| `effort` | Bare string | `low`, `medium`, `high`, `max` |
| `context` | Bare string | `fork` |

## Description Best Practices

- MUST start with action verb (Apply, Audit, Create, Debug, Execute, Fetch, Fix...)
- MUST include "Use when..." clause
- Under 1024 characters

## Quick Diagnostic

```bash
# Find wrong field names
grep -l 'allowed_tools' ~/.claude/commands/*.md ~/.claude/skills/*/SKILL.md 2>/dev/null
# Find JSON array format
grep -l 'allowed-tools:.*\[' ~/.claude/commands/*.md ~/.claude/skills/*/SKILL.md 2>/dev/null
```

---

**Last Updated**: 2025-03-25
