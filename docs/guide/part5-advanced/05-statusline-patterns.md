---
layout: default
title: "Statusline Patterns"
parent: "Part V — Advanced"
nav_order: 5
redirect_from:
  - /docs/guide/75-claude-code-statusline-patterns.html
  - /docs/guide/75-claude-code-statusline-patterns/
---

# Statusline Patterns

**Added in**: Claude Code 2.1.97-2.1.98. Current as of 2.1.111+.

The statusline is a single line displayed at the bottom of the Claude Code interface, refreshed periodically. Two 2.1.97-2.1.98 additions make it practical for real workflows:

- `workspace.git_worktree` in the stdin JSON — worktree-aware paths.
- `refreshInterval` in `settings.json` — control re-run cadence.

---

## Configuration

In `settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ${HOME}/.claude/scripts/statusline.sh",
    "refreshInterval": 5
  }
}
```

- **`type: "command"`** — runs a shell command.
- **`command`** — the script that produces one line of output on stdout.
- **`refreshInterval`** — seconds between re-runs (integer, minimum 1).

The script receives a JSON object on **stdin** with session context.

---

## stdin JSON fields

The statusline script receives this JSON structure on stdin:

```json
{
  "workspace": {
    "git_worktree": "/home/user/project-worktree",
    "current_dir": "/home/user/project-worktree"
  },
  "model": {
    "display_name": "Opus 4.7",
    "id": "claude-opus-4-7"
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

## Example 1: Worktree + model + context

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

Output: `my-project-worktree | Opus 4.7 | ctx 14%`

---

## Example 2: Git branch + dirty flag

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

Output: `my-project (feature-x *)`

---

## Example 3: Service health indicator

```bash
#!/bin/bash
INPUT=$(timeout 2 cat 2>/dev/null || echo '{}')
wt=$(echo "$INPUT" | jq -r '.workspace.git_worktree // .cwd // empty' | awk -F/ '{print $NF}')

health="?"
if curl -sf --max-time 1 localhost:4444/health >/dev/null 2>&1; then
  health="up"
else
  health="down"
fi

printf '%s | svc:%s\n' "$wt" "$health"
```

Output: `my-project | svc:up`

---

## Example 4: Circuit breaker + governance overlap

Cache a governance-scanner report count and show it as a compact indicator:

```bash
#!/bin/bash
INPUT=$(timeout 2 cat 2>/dev/null || echo '{}')
wt=$(echo "$INPUT" | jq -r '.workspace.git_worktree // .cwd // empty' | awk -F/ '{print $NF}')
model=$(echo "$INPUT" | jq -r '.model.display_name // "?"')

ctx=$(echo "$INPUT" | jq -r '
  if .transcript.tokens.total then
    ((.transcript.tokens.total / 1000000 * 100) | floor | tostring) + "%"
  else "?" end')

# Read pre-scanned overlap count from a cache file (updated by a weekly cron)
CACHE="${HOME}/.claude/cache/overlap-count.state"
ov="?"
if [ -f "$CACHE" ]; then
  ov=$(cat "$CACHE")
fi

# Circuit breaker state (from a separate hook/daemon)
CB_STATE_FILE="${HOME}/.claude/cache/circuit-breaker.state"
cb="ok"
if [ -f "$CB_STATE_FILE" ]; then
  cb=$(cat "$CB_STATE_FILE")
fi

printf '%s | %s | ctx %s | cb:%s | ov:%s\n' "$wt" "$model" "$ctx" "$cb" "$ov"
```

Output: `my-project | Opus 4.7 | ctx 14% | cb:ok | ov:3`

The key trick: **never compute expensive metrics in the statusline**. Run scanners out of band (cron, hooks), cache their output to a file, read the cached value in the statusline. Target latency stays under 100ms even with five fields.

---

## Performance guidelines

- **Target**: < 300ms per refresh. The script runs every `refreshInterval` seconds.
- **Avoid**: network calls that could block. Use `curl -sf --max-time 1` with short timeouts.
- **Avoid**: `git status --porcelain` on very large repos — use `git diff --quiet HEAD` instead (faster).
- **jq processing**: parsing the stdin JSON typically takes < 10ms.
- **Expensive metrics**: compute out of band, cache to a file, read in the statusline.
- **If slow**: raise `refreshInterval` to 10-15 or simplify the script.

---

## Debugging

If your statusline doesn't appear:

1. Test the script directly: `echo '{}' | bash ${HOME}/.claude/scripts/statusline.sh`
2. Check `settings.json` for valid JSON: `jq . ${HOME}/.claude/settings.json`
3. Verify `type: "command"` is set (other types exist but `command` is most common).
4. On terminals shorter than 24 rows, statuslines may not render (fixed in 2.1.97).
5. Check that `refreshInterval` is a number, not a string.
6. Check the model field against current model ids — 2.1.111 is Opus 4.7 era; older cached reports may reference Opus 4.6.

---

## Combining with other Part V primitives

| Primitive | How statusline surfaces it |
|-----------|---------------------------|
| [Self-telemetry](03-self-telemetry.html) | `skill-activations.jsonl` line count this session |
| [Inter-agent bus](02-inter-agent-bus.html) | Unread thread count (reads `.last-seen/`) |
| [Cross-project knowledge](06-cross-project-knowledge.html) | Governance scanner overlap count (pre-cached) |
| [Monitor tool](04-monitor-tool.html) | Active background task count (from `Bash` task list) |

The pattern: the statusline is a **display layer** over cached state, never a compute layer. Every field should resolve to a `cat <cache-file>` or `jq <stdin-field>` — nothing more.

---

## See also

- [CC version history](../part6-reference/01-cc-version-history.html) — `workspace.git_worktree` (2.1.97), `refreshInterval` (2.1.98)
- [Self-telemetry](03-self-telemetry.html) — source of cached metrics the statusline reads
- [Monitor tool](04-monitor-tool.html) — complementary background-refresh primitive

---

*Last updated: 2026-04-20. Compatible with Claude Code 2.1.111+.*
