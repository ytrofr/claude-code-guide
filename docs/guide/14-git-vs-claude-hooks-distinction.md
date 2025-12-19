# Chapter 14: Git Hooks vs Claude Code Hooks

**Purpose**: Understand the difference between two hook systems
**Critical**: Don't confuse them - they serve different purposes

---

## Quick Comparison

| Aspect | Git Hooks | Claude Code Hooks |
|--------|-----------|-------------------|
| **Location** | `.git/hooks/` | `settings.json` |
| **Trigger** | Git operations | Claude Code events |
| **Examples** | pre-commit, pre-push | SessionStart, PostToolUse |

---

## When to Use Each

**Git Hooks**: Code quality before commits
**Claude Code Hooks**: Workflow automation during sessions

**Both work together** - use for different purposes

---

**Full guide**: Complete distinction with examples in LIMOR AI

**Previous**: [13: Claude Code Hooks](13-claude-code-hooks.md)
**Next**: [15: Progressive Disclosure](15-progressive-disclosure.md)
