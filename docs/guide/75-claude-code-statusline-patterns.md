---
layout: default
title: "Claude Code Statusline Patterns — workspace.git_worktree & refreshInterval"
description: "How to build dynamic statuslines using the workspace.git_worktree JSON field and refreshInterval setting, with example scripts for multi-worktree setups."
parent: Guide
nav_order: 75
---

# Claude Code Statusline Patterns

**Added in**: Claude Code 2.1.97-2.1.98

The statusline is a single line displayed at the bottom of the Claude Code interface, refreshed periodically. Two 2.1.97-2.1.98 additions make it practical for real workflows.

---

## Configuration

In `settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/scripts/statusline.sh",
    "refreshInterval": 5
  }
}
```

- **`type: "command"`** — runs a shell command
- **`command`** — the script that produces one line of output on stdout
- **`refreshInterval`** — seconds between re-runs (integer, minimum 1)

The script receives a JSON object on **stdin** with session context.

---

## stdin JSON Fields

The statusline script receives this JSON structure on stdin:

```json
{
  "workspace": {
    "git_worktree": "/home/user/project-worktree",
    "current_dir": "/home/user/project-worktree"
  },
  "model": {
    "display_name": "Opus 4.6",
    "id": "claude-opus-4-6"
  },
  "transcript": {
    "tokens": {
      "total": 147000
    }
  },
  "cwd": "/home/user/project-worktree"
}
```

The `workspace.git_worktree` field (new in 2.1.97) is set whenever the current directory is inside a linked git worktree. This enables worktree-aware statuslines for multi-worktree setups.

---

## Example 1: Worktree + Model + Context

```bash
#!/bin/bash
INPUT=$(timeout 2 cat 2>/dev/null || echo '{}')

wt=$(echo "$INPUT" | jq -r '.workspace.git_worktree // .cwd // empty' | awk -F/ '{print $NF}')
[ -z "$wt" ] && wt=$(basename "${PWD:-?}")

model=$(echo "$INPUT" | jq -r '.model.display_name // "?"')

ctx=$(echo "$INPUT" | jq -r '
  if .transcript.tokens.total then
    ((.transcript.tokens.total / 1000000 * 100) | floor | tostring) + "%"
  else "?" end')

printf '%s | %s | ctx %s\n' "$wt" "$model" "$ctx"
```

Output: `LimorAI-Limor | Opus 4.6 | ctx 14%`

---

## Example 2: Git Branch + Dirty Flag

```bash
#!/bin/bash
INPUT=$(timeout 2 cat 2>/dev/null || echo '{}')
wt=$(echo "$INPUT" | jq -r '.workspace.git_worktree // .cwd // empty')
[ -z "$wt" ] && wt="$PWD"

branch=$(git -C "$wt" branch --show-current 2>/dev/null || echo "?")
dirty=""
if [ -n "$(git -C "$wt" status --porcelain 2>/dev/null)" ]; then dirty=" *"; fi

printf '%s (%s%s)\n' "$(basename "$wt")" "$branch" "$dirty"
```

Output: `LimorAI-Limor (feature-x *)`

---

## Example 3: Service Health Indicator

```bash
#!/bin/bash
INPUT=$(timeout 2 cat 2>/dev/null || echo '{}')
wt=$(echo "$INPUT" | jq -r '.workspace.git_worktree // .cwd // empty' | awk -F/ '{print $NF}')

health="?"
if curl -sf localhost:4444/health >/dev/null 2>&1; then health="up"; else health="down"; fi

printf '%s | hub:%s\n' "$wt" "$health"
```

Output: `ai-intelligence-hub | hub:up`

---

## Performance Guidelines

- **Target**: < 300ms per refresh. The script runs every `refreshInterval` seconds.
- **Avoid**: network calls that could block (use `curl -sf --max-time 1` with short timeouts)
- **Avoid**: `git status --porcelain` on very large repos (use `git diff --quiet HEAD` instead — faster)
- **jq processing**: parsing the stdin JSON typically takes < 10ms
- **If slow**: reduce `refreshInterval` to 10-15 or simplify the script

---

## Debugging

If your statusline doesn't appear:
1. Test the script directly: `echo '{}' | bash ~/.claude/scripts/statusline.sh`
2. Check `settings.json` for valid JSON: `jq . ~/.claude/settings.json`
3. Verify `type: "command"` is set (other types exist but command is most common)
4. On terminals shorter than 24 rows, statuslines may not render (fixed in 2.1.97)
5. Check that `refreshInterval` is a number, not a string

---

*See also: [Chapter 74 — Monitor Tool](74-claude-code-monitor-tool.md) | [Chapter 73 — 2.1.98-2.1.99 Features](73-claude-code-2198-2199-features.md)*
