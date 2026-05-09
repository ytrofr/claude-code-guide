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

## Example 5: Bus identity + active-peer indicator

When you run multiple parallel CC sessions in the same project (see Part V ch.2 — Inter-agent bus, "Same-project parallel sessions"), the statusline can show your own session id + which peers you have active threads with + an unread (`●`) glyph:

```bash
#!/bin/bash
# Reads stdin's session_id, looks up registry → full_id, queries threads.json.
# The full helper lives at ~/.claude/scripts/statusline-bus.sh and exposes a
# `bus_indicator` function the main statusline sources:

bus_indicator() {
  local ROOT="${INTER_AGENT_ROOT:-$HOME/shared/inter-agent}"
  local SID="$1" SESS_DIR="$ROOT/sessions" THREADS="$ROOT/threads.json"
  local LASTSEEN="$ROOT/.last-seen"

  # 1. Resolve own full_id from registry (or fallback to bare agent)
  local FULL_ID=""
  [ -n "$SID" ] && [ -f "$SESS_DIR/$SID.json" ] \
    && FULL_ID="$(jq -r '.full_id // empty' "$SESS_DIR/$SID.json" 2>/dev/null)"
  [ -z "$FULL_ID" ] && FULL_ID="$(~/shared/inter-agent/bin/resolve-identity.sh 2>/dev/null)"
  [ -z "$FULL_ID" ] && { printf '?'; return; }

  # 2. Find active threads I'm in, format peer list (cap 2 + overflow)
  [ -f "$THREADS" ] || { printf '%s' "$FULL_ID"; return; }
  local rows
  rows="$(jq -r --arg me "$FULL_ID" '
    .threads // {} | to_entries
    | map(select(.value.status == "active" and (.value.participants | index($me))))
    | sort_by(.value.last_activity) | reverse | .[:3]
    | .[] | [.key, (.value.participants | map(select(. != $me)) | join(",")),
             (.value.last_activity // "")] | @tsv
  ' "$THREADS" 2>/dev/null)"
  [ -z "$rows" ] && { printf '%s' "$FULL_ID"; return; }

  # 3. Aggregate peers + unread check (last_activity > last-seen file timestamp)
  local peers="" unread=0 my_agent="${FULL_ID%%:*}"
  while IFS=$'\t' read -r tid plist last; do
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      [[ "$p" == "${my_agent}:"* ]] && p="${p#"${my_agent}:"}"
      peers="${peers:+${peers},}$p"
    done <<<"$(printf '%s\n' "$plist" | tr ',' '\n')"
    if [ "$unread" = "0" ]; then
      local seen_file="$LASTSEEN/$FULL_ID-$tid.ts"
      local last_e seen_iso seen_e
      last_e="$(date -u -d "$last" +%s 2>/dev/null || echo 0)"
      [ -f "$seen_file" ] && seen_iso="$(awk '{print $2}' "$seen_file" | head -1)"
      seen_e="$(date -u -d "${seen_iso:-1970-01-01}" +%s 2>/dev/null || echo 0)"
      [ "$last_e" -gt "$seen_e" ] && unread=1
    fi
  done <<<"$rows"

  local uniq; uniq="$(printf '%s\n' "$peers" | tr ',' '\n' | awk 'NF && !seen[$0]++')"
  local n; n="$(printf '%s\n' "$uniq" | grep -c .)"
  local shown; shown="$(printf '%s\n' "$uniq" | head -2 | paste -sd ',' -)"
  [ "$n" -gt 2 ] && shown="${shown}+$((n - 2))"
  printf '%s%s→%s' "$FULL_ID" "$([ "$unread" = 1 ] && echo "●")" "$shown"
}
```

Source it from your main statusline and invoke at the end of the field row:

```bash
sid=$(echo "$INPUT" | jq -r '.session_id // empty')
bus=$(bus_indicator "$sid" 2>/dev/null || echo "?")
printf '%s | %s | ctx %s | cb:%s | ov:%s | bus:%s\n' "$wt" "$model" "$ctx" "$cb" "$ov" "$bus"
```

Output examples:
| State | Field |
|-------|-------|
| Idle (registered, no active threads) | `bus:limor:s2` |
| 1 thread with peer s1 | `bus:limor:s2→s1` |
| Same, with unread | `bus:limor:s2●→s1` |
| 3-way thread | `bus:limor:s2●→s1,s3` |
| Cross-agent peer | `bus:limor:s2●→smith,s1` |
| 4+ peers | `bus:limor:s2●→smith,s1+2` |
| Joined a convo (workstream isolation) | `bus:limor:s2@planx→s1` |
| Bus unreachable | `bus:?` |

The `●` glyph indicates an unread peer message; reading via `talk.sh show <tid>` or `talk.sh listen <tid>` updates the per-session last-seen file and clears it.

---

## Example 6: Two-line statusline + OSC-8 clickable link

When you have a per-session resource (an active quest, a current ticket, a deploy URL) worth eyeballing, surface it as a **clickable hyperlink** on a second line. Modern terminals (Windows Terminal, iTerm2, kitty, recent VS Code terminal, Ghostty) honor [OSC-8 hyperlink escapes](https://gist.github.com/egmontkob/eb114294efbcd5adb1944c9f3cb5feda); bare xterm shows the raw escapes (provide a `*_NO_OSC8=1` env var for graceful fallback).

```bash
# Helper at ~/.claude/scripts/statusline-resource.sh
resource_indicator() {
  local cwd="${1:-${PWD:-}}"
  # ... your logic to compute (url, short_tag) for this session ...
  local url="http://localhost:8770/path/to/resource"
  local tag="my-resource-id"

  if [ -n "$STATUSLINE_NO_OSC8" ]; then
    printf '%s' "$tag"
  else
    # OSC-8: ESC]8;;URL ST  TAG  ESC]8;; ST   (ST = ESC \)
    printf '\033]8;;%s\033\\%s  →  %s\033]8;;\033\\' "$url" "$tag" "$url"
  fi
}
```

The `→ <url>` suffix is plain text inside the OSC-8 wrapper — it makes the URL visible (and copy-pasteable) even on terminals that ignore the hyperlink escape, while keeping the whole row clickable on terminals that honor it.

```bash
# Main statusline.sh — print TWO lines
source "$(dirname "${BASH_SOURCE[0]}")/statusline-resource.sh"
resource=$(resource_indicator "$cwd")
printf '%s | %s | ctx %s\nresource: %s\n' "$wt" "$model" "$ctx" "$resource"
```

Output (terminal renders second-line tag as a clickable link):

```
my-project | Opus 4.7 | ctx 14%
resource: my-resource-id  →  http://localhost:8770/path/to/resource
```

CC 2.1.131 verified to render multi-line statusline output (newlines preserved). Each line gets full terminal width — useful for long URLs that would otherwise truncate at the right edge.

### Pattern: hybrid session→resource binding

For per-session resource binding, use a hybrid resolver:

1. **Explicit claim** — a CLI command writes `~/.cache/<app>/session-<key>.bind` with the chosen resource id. Statusline reads it first.
2. **Auto-detect** — fall back to deriving from `cwd` (e.g. via a path map) plus a "most-recently-touched" signal in your data.
3. **Landing page** — when nothing matches, link to a known-good page so the link is never dead.

The session key needs to be stable per CC instance and accessible from both Bash (statusline) and any CLI you write. A robust approach without depending on the inter-agent bus:

```bash
# Walk up parent processes to find the `claude` ancestor; combine its pid +
# raw /proc/<pid>/stat field-22 starttime ticks. Deterministic per CC instance.
session_key() {
  local pid=$$ depth=0
  while [ "$depth" -lt 40 ] && [ -n "$pid" ] && [ "$pid" -gt 1 ] 2>/dev/null; do
    local comm=""
    [ -r "/proc/$pid/comm" ] && comm=$(cat "/proc/$pid/comm" 2>/dev/null)
    if [ "$comm" = "claude" ]; then
      local ticks
      ticks=$(sed 's/([^)]*)/X/' "/proc/$pid/stat" 2>/dev/null | awk '{print $22}')
      [ -n "$ticks" ] && echo "${pid}-${ticks}"
      return 0
    fi
    local ppid
    ppid=$(sed 's/([^)]*)/X/' "/proc/$pid/stat" 2>/dev/null | awk '{print $4}')
    [ -z "$ppid" ] || [ "$ppid" = "0" ] && return 1
    pid="$ppid"
    depth=$((depth + 1))
  done
  return 1
}
```

Pair with a `SessionEnd` hook that removes the claim file so stale binds don't accumulate.

### When to use OSC-8 vs FinalTerm escapes

OSC-8 (`\e]8;;URL\e\\TEXT\e]8;;\e\\`) wraps a span of text as a hyperlink — best for "click this to open X". Don't confuse with FinalTerm escapes (`\e]133;A`) used by Ghostty / iTerm2 to mark prompt boundaries for "scroll to last command" — different problem, different escapes. Both can coexist.

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
