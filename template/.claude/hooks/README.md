# Claude Code Hook Templates

Ready-to-use hook scripts based on Anthropic blog patterns and LIMOR AI research.

## Quick Start

```bash
# Copy to your project
cp template/.claude/hooks/*.sh your-project/.claude/hooks/
chmod +x your-project/.claude/hooks/*.sh
```

## Available Hooks

| Hook | Purpose | Documentation |
|------|---------|---------------|
| **pre-prompt.sh** ⭐ NEW | Skill detection with 4-phase enhancement | [Chapter 17](../../docs/guide/17-skill-detection-enhancement.md) |
| **session-start.sh** | Session initialization, git status, context loading | [Chapter 13](../../docs/guide/13-claude-code-hooks.md) |
| **pre-compact.sh** | Context backup before compaction | [Chapter 13](../../docs/guide/13-claude-code-hooks.md) |
| **stop-hook.sh** | Session cleanup, checkpoint commits | [Chapter 13](../../docs/guide/13-claude-code-hooks.md) |

## pre-prompt.sh (Skill Detection Enhancement)

**Score**: 700/700 (100% test accuracy)
**Source**: Entry #204 - Skill Detection Enhancement

### 4-Phase Detection

| Phase | Description | Impact |
|-------|-------------|--------|
| 1A | Synonym mapping (PR↔github, 403→oauth2) | +15% |
| 1B | Relevance scoring + context boosts | Ordering |
| 2 | Stem variations (deploying→deploy) | +5% |
| 3 | Multi-word patterns ("create PR") | +2.5% |
| 4 | Description keyword extraction | +2% |

### Customization

Add project-specific patterns in pre-prompt.sh:

```bash
# Phase 1A: Add your synonyms
echo "$msg_lower" | grep -qiF "yourterm" && \
    expanded_msg="$expanded_msg your-skill-keyword"

# Phase 3: Add your patterns
echo "$msg_lower" | grep -qiE "your.*pattern" && \
    expanded_msg="$expanded_msg your-skill"
```

## Configuration

Add to `.claude/settings.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "command": ".claude/hooks/pre-prompt.sh"
    }],
    "SessionStart": [{
      "command": ".claude/hooks/session-start.sh"
    }],
    "PreCompact": [{
      "command": ".claude/hooks/pre-compact.sh"
    }],
    "Stop": [{
      "command": ".claude/hooks/stop-hook.sh"
    }]
  }
}
```

## Source

- **LIMOR AI**: Production config (96% validation)
- **Anthropic Blog**: [Hooks documentation](https://claude.com/blog/how-to-configure-hooks)
- **Scott Spence**: [Skills activation research](https://scottspence.com/posts/how-to-make-claude-code-skills-activate-reliably)
