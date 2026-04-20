---
layout: default
title: "Self-Telemetry for Claude Code"
parent: "Part V — Advanced"
nav_order: 3
redirect_from:
  - /docs/guide/78-self-telemetry-for-claude-code.html
  - /docs/guide/78-self-telemetry-for-claude-code/
---

# Self-Telemetry for Claude Code

**Scope**: how to measure *your own* Claude Code usage — tool calls, subagent dispatches, skill invocations, session KPIs — using only hooks and `jsonl` append logs. No external services, no OTLP collector, no OTEL setup. Grounded in CC 2.1.111 official docs + live-probed payload schemas.

**Why this chapter exists**: CC 2.1.108's `ENABLE_PROMPT_CACHING_1H` and 2.1.98's `TRACEPARENT` auto-propagation gave you Anthropic-blessed *trace* observability. CC 2.1.111 adds `OTEL_LOG_RAW_API_BODIES` for raw body capture when you need it. But for the plain question *"how am I actually using Claude Code this week?"* — the answer requires a handful of `async: true` hooks, a FIFO correlation queue, and one weekly aggregator script. This chapter ships a reference implementation and the validated facts that made it possible.

---

## 1. What the stack measures

Five `jsonl` append streams under `$HOME/.claude/metrics/`:

| Stream | Written by | Event | Key fields |
|---|---|---|---|
| `skill-activations.jsonl` | `prompt-length-logger.sh` + `skill-activation-logger.sh` | `UserPromptSubmit` + `PostToolUse(Skill)` | `ts`, `session_id`, `event:"prompt"|"skill_use"`, `msg_len`, `matched_skills` |
| `tool-calls.jsonl` | `tool-call-logger.sh` | `PreToolUse(.*)` + `PostToolUse(.*)` | `ts`, `session_id`, `tool_name`, `is_mcp`, `duration_ms`, `success`, `input_preview` |
| `subagent-dispatches.jsonl` | `subagent-logger.sh` | `SubagentStart` + `SubagentStop` | `ts`, `session_id`, `agent_type`, `agent_id`, `duration_ms`, `result_size_bytes` |
| `sessions.jsonl` | `auto-session-summary.sh` (extended) | `SessionEnd` | `session_id`, `started_at`, `ended_at`, `duration_min`, `prompts`, `tool_calls`, `skill_uses`, `subagent_dispatches`, `project`, `branch`, `commits` |
| `tmp/probes/*.json` | `telemetry-probe.sh` (disposable) | any | raw stdin JSON for schema discovery |

All five are privacy-conscious: `input_preview` is hard-capped at 200 chars; `last_assistant_message` is stored as a byte-length count only, never as body.

## 2. Docs-validated facts that shape the design

Before building any of this, four questions had to be answered against official docs and live payloads:

| Question | Answer | Source |
|---|---|---|
| Does `PostToolUse` with `matcher: ".*"` fire for MCP, Skill, Agent, and subagent-initiated tool calls? | **Yes, all of them.** No exclusion list in the docs. | [code.claude.com/docs/en/hooks](https://code.claude.com/docs/en/hooks) |
| Is `tool_use_id` in `PostToolUse` stdin? | **No.** Only `session_id`, `tool_name`, `tool_input`, `tool_response`. | Ch 13 example + live probe 2026-04-20 |
| Can OpenTelemetry export to a local file? | **No.** `file://` / `console` exporters are unsupported; must run an OTLP collector process. | [monitoring-usage docs](https://docs.anthropic.com/en/docs/claude-code/monitoring-usage) |
| Is there a `PermissionGranted` event to pair with `PermissionDenied`? | **No.** Approvals are implicit (no event fires). | [hooks reference](https://code.claude.com/docs/en/hooks) |

Consequence: duration measurement cannot use a hook-supplied ID, and OTEL-free self-telemetry has to ride on hooks + `jsonl`. The stack below embraces both limitations.

## 3. Validated `SubagentStart` / `SubagentStop` payload (CC 2.1.111)

The docs list the events but under-specify the stdin schema. Live-probed payloads:

**`SubagentStart`:**

```json
{
  "session_id": "a6a72754-3eaa-4a0c-b282-4915b23d7c34",
  "transcript_path": "$HOME/.claude/projects/<proj>/<session>.jsonl",
  "cwd": "/some/working/dir",
  "agent_id": "a0ad066750581698a",
  "agent_type": "Explore",
  "hook_event_name": "SubagentStart"
}
```

**`SubagentStop`** adds:

```json
{
  "permission_mode": "bypassPermissions",
  "stop_hook_active": false,
  "agent_transcript_path": "$HOME/.claude/projects/<proj>/<session>/subagents/agent-<agent_id>.jsonl",
  "last_assistant_message": "<full agent output — privacy-sensitive>"
}
```

Key take-aways:

- `agent_id` is a **stable key across Start and Stop** — use it directly for duration pairing, no FIFO fallback needed.
- `agent_type` is one of CC's built-in names (`Explore`, `Plan`, `general-purpose`) or a custom subagent name.
- `last_assistant_message` is the **full assistant response text**. Record length only; never persist the body.
- `agent_transcript_path` points to the subagent's own transcript file — useful for forensic retrieval, but also a privacy vector if persisted.

## 4. The hook pipeline (wiring)

All four telemetry hooks wire via `"async": true` so they cannot block a tool call, user prompt, or session end. Settings fragment:

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": ".*",
      "hooks": [{
        "type": "command",
        "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/tool-call-logger.sh",
        "async": true
      }]
    }],
    "PostToolUse": [{
      "matcher": ".*",
      "hooks": [{
        "type": "command",
        "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/tool-call-logger.sh",
        "async": true
      }]
    }],
    "SubagentStart": [{
      "hooks": [{
        "type": "command",
        "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/subagent-logger.sh",
        "async": true
      }]
    }],
    "SubagentStop": [{
      "hooks": [{
        "type": "command",
        "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/subagent-logger.sh",
        "async": true
      }]
    }]
  }
}
```

Use `$CLAUDE_PROJECT_DIR` (not relative paths) per the hook patterns chapter.

## 5. Duration correlation without `tool_use_id` — the FIFO pattern

Since `PostToolUse` stdin has no `tool_use_id` and no `duration_ms`, pair `PreToolUse` and `PostToolUse` manually. A per-session FIFO queue on disk works because **Claude Code serialises tool calls per turn** — at any moment, for a given session, there is at most one tool of a given name in-flight.

Queue file: `$HOME/.claude/tmp/tool-queue/<session_id>.queue`
Format: one line per pending tool, `<start_ns>|<tool_name>`

**`PreToolUse(.*)` enqueues**:

```bash
START_NS=$(date +%s%N)
printf '%s|%s\n' "$START_NS" "$TOOL" >> "$QUEUE_FILE"
```

**`PostToolUse(.*)` dequeues the oldest matching row**:

```bash
MATCH_LINE=$(grep -n "|${TOOL}$" "$QUEUE_FILE" | head -1 | cut -d: -f1)
START_NS=$(sed -n "${MATCH_LINE}p" "$QUEUE_FILE" | cut -d'|' -f1)
DURATION_MS=$(( ($(date +%s%N) - START_NS) / 1000000 ))
sed -i "${MATCH_LINE}d" "$QUEUE_FILE"
```

Always prune entries > 5 minutes old at the start of each invocation so orphans (from crashes, pre-wiring sessions) don't accumulate:

```bash
NOW_NS=$(date +%s%N)
CUTOFF_NS=$(( NOW_NS - 300000000000 ))
awk -F'|' -v c="$CUTOFF_NS" '$1 >= c' "$QUEUE_FILE" > "${QUEUE_FILE}.tmp" && mv "${QUEUE_FILE}.tmp" "$QUEUE_FILE"
```

For subagents, use `agent_id` directly — no queue needed:

```bash
if [ -n "$AGENT_ID" ]; then
  MATCH_LINE=$(grep -n "|${AGENT_ID}$" "$QUEUE_FILE" | head -1 | cut -d: -f1)
fi
# fall back to agent_type FIFO if agent_id ever missing
```

## 6. The `grep -c ... || echo 0` gotcha

When aggregating per-session counts from `jsonl`, this pattern looks safe but doubles output on zero matches:

```bash
# WRONG — grep prints "0" AND exits 1 when no match, so `|| echo 0` adds a SECOND "0"
PROMPTS=$(grep -c "$PAT" "$FILE" 2>/dev/null || echo 0)
# → captured value is "0\n0" which breaks `jq --argjson prompts "$PROMPTS"`
#   with "invalid JSON text passed to --argjson"
```

Fix: a small helper that always outputs exactly one integer:

```bash
_safe_count() {
    local pat="$1" file="$2"
    if [ -f "$file" ]; then
        grep -c "$pat" "$file" 2>/dev/null | head -1
    else
        echo 0
    fi
}
PROMPTS=$(_safe_count "$PAT" "$FILE")
PROMPTS=${PROMPTS:-0}
```

This bit us once during the session-rollup implementation — `sessions.jsonl` wrote empty rows silently because every `--argjson` call rejected the bad value. Worth auditing existing shell scripts for the pattern.

## 7. The `event:` discriminator for multi-event streams

`skill-activations.jsonl` is written by *two* hooks (UserPromptSubmit and PostToolUse(Skill)), so each row carries a discriminator:

```json
{"ts":"...", "session_id":"...", "event":"prompt",    "msg_len":142, "matched_skills":""}
{"ts":"...", "session_id":"...", "event":"skill_use", "msg_len":null, "matched_skills":"frontend-design"}
```

Downstream aggregators filter by `event:`. This lets a single stream serve both questions — *how many prompts this week* and *which skills fired* — without joining across files.

## 8. Session rollup at `SessionEnd`

Extend your existing `SessionEnd` hook (if you have one for Basic Memory / session summaries) to emit one rollup row to `sessions.jsonl` **before** any gate that might exit early (e.g. "skip if no commits this session"). Derive counts via `_safe_count` over the four other jsonl streams keyed by `session_id`. The rollup is the *join key* that every weekly report hangs on — if you gate it behind "only commit-bearing sessions", you get a biased sample.

## 9. Weekly aggregator pattern

One Python script reads all five streams, produces a markdown report:

```
$HOME/.claude/scripts/weekly-review.py  → $HOME/.claude/reports/weekly-YYYY-WNN.md
```

Suggested sections:

1. **Summary** — prompts / tool calls / skill uses / subagent dispatches / sessions
2. **Tools** — top 10 by count, top 5 slowest by p95 (min 3 calls)
3. **MCP per-server latency** — `mcp__<server>__*` grouped, p50 / p95
4. **Skills** — invocation counts (join against `/slashes` to surface never-invoked skills)
5. **Subagent dispatches** — by `agent_type` with duration distribution
6. **Sessions** — last 10 rollups
7. **Telemetry health (meta)** — any logger with zero rows in the window = silent-failure flag

Wrap the script in a user-invocable skill (`user-invocable: true`) so `/weekly-review` runs the report without a flag. The `weekly-review` skill is available in the Full install tier.

## 10. Telemetry health as meta-observability

Section 7 of the report is the feature that catches silent hook failures the moment they happen: if the logger script exists in `$HOME/.claude/hooks/` but its output stream has zero rows in the window, the report flags it. This has a known false-positive window — a newly-wired logger will warn for one week until real data accumulates — but after that every warning is a real signal of a broken hook.

## 11. What you cannot measure (yet)

| Signal | Why blocked | Workaround |
|---|---|---|
| Prompt cache hit-rate | Only surfaced via OTEL, which needs an OTLP collector | Run a local OTLP collector (otelcol + `file_exporter` receiver) |
| Per-turn token counts | Same — OTEL only | Same as above |
| Permission approvals (vs denials) | `PermissionGranted` event does not exist; approvals are implicit | Infer via "PreToolUse fired + PostToolUse fired without a preceding PermissionDenied for this tool" — high complexity, low signal |
| `/cost` dashboard data programmatically | No first-party `claude metrics` / `claude usage` CLI export | Parse `/cost` output at `Stop` if you really need it; prefer OTEL once set up |

## 12. Reference implementation

A minimal working set (sanitize paths before distribution):

- `$HOME/.claude/hooks/tool-call-logger.sh` — ~100 LOC, PreToolUse+PostToolUse FIFO pairing, emits `tool-calls.jsonl`
- `$HOME/.claude/hooks/subagent-logger.sh` — ~90 LOC, `agent_id`-keyed pairing, emits `subagent-dispatches.jsonl`
- `$HOME/.claude/hooks/telemetry-probe.sh` — ~25 LOC disposable probe for schema discovery
- `$HOME/.claude/scripts/weekly-review.py` — ~300 LOC aggregator
- `$HOME/.claude/skills/weekly-review/SKILL.md` — user-invocable wrapper

Each hook follows three conventions enforced elsewhere in the guide:

1. `INPUT=$(timeout 1 cat 2>/dev/null || exit 0)` — safe stdin read.
2. `"async": true` in settings — fire-and-forget, never blocks.
3. `$CLAUDE_PROJECT_DIR/.claude/hooks/<name>.sh` paths — portable across sessions.

## 13. Rollout order (probe-first)

Do not ship the full stack in one go. The schema of `SubagentStart` / `SubagentStop` isn't fully documented, so:

1. Ship `telemetry-probe.sh` first, wired to `SubagentStart`, `SubagentStop`, `PreToolUse(.*)`, `PostToolUse(.*)`, all async.
2. Let it run for ~1 day of normal use (rate-limit to ≤ 3 samples per `<event>-<tool>` combo to avoid flooding).
3. Inspect the captured raw JSON to confirm field names in your CC version.
4. Replace the probe with the real loggers once the schema is confirmed.
5. Delete the probe script and purge `$HOME/.claude/tmp/probes/`.

Observe before you commit to behavior.

## 14. Privacy and retention

- **Hard cap `input_preview` at 200 chars** — enough to disambiguate, not enough to leak `file_path` contents, passwords, or API keys.
- **Never persist `tool_response` body** — drop it entirely, even truncated. A stored snippet is still a leak.
- **`last_assistant_message.length` only**, never the text.
- **Retention**: 90 days of raw `jsonl` + archive to `$HOME/.claude/metrics/archive/YYYY-MM/` afterwards. Weekly reports summarise the old data before archival so the dashboards remain navigable.
- **Audit before committing** — the first week's `tool-calls.jsonl` usually has surprises. Grep for `api_key|secret|token|bearer|AIza[A-Za-z0-9]{30,}|sk-[A-Za-z0-9]{30,}` before declaring the pipeline safe.

## 15. Tracing hooks vs telemetry hooks

CC 2.1.98+ auto-propagates `TRACEPARENT` into Bash subprocesses when OTEL tracing is enabled — child spans chain to the parent correctly in Honeycomb/Jaeger. CC 2.1.111 adds `OTEL_LOG_RAW_API_BODIES` for raw request/response body capture.

These are complementary to the hook-based telemetry described here:

| Layer | Tool | Question answered |
|---|---|---|
| OTEL traces | `TRACEPARENT`, `OTEL_LOG_*` | "What happened inside this one request?" (span waterfall, timing) |
| Hook telemetry | `jsonl` streams | "How am I using Claude Code over time?" (counts, p95s, session rollups) |

If you run both, the OTEL collector catches every API-level detail and the hook logs catch every session-level aggregation. Neither subsumes the other.

## 16. Takeaways

- Every Anthropic-blessed observability feature (OTEL, `TRACEPARENT`, `/cost`) answers a different question than "how am I using Claude Code *this week*." For that, hooks + `jsonl` + a Python aggregator is the right shape.
- `PostToolUse` stdin gives you `tool_name` and `tool_input`, but not `tool_use_id` or `duration_ms` — plan the correlation strategy accordingly.
- `SubagentStart` / `SubagentStop` do fire in CC 2.1.111 and carry `agent_id` for clean pairing. The schema is published in § 3 of this chapter.
- `async: true` makes hooks fire-and-forget; pair with `timeout 1 cat` on stdin and the read is never a blocker.
- The `grep -c ... || echo 0` pattern doubles output on zero-match; use `_safe_count`.
- Ship a probe before the real logger — schema assumptions are the most expensive thing to get wrong.

## See Also

- [Hook event catalog](../part6-reference/03-hook-event-catalog.html) — events, `async: true`, `$CLAUDE_PROJECT_DIR`, stdin patterns
- [CC version history](../part6-reference/01-cc-version-history.html) — `TRACEPARENT` auto-propagation, `OTEL_LOG_RAW_API_BODIES`, Monitor tool
- [Monitor tool](04-monitor-tool.html) — Monitor vs `ScheduleWakeup` decision matrix
- [Skill catalog](../part6-reference/04-skill-catalog.html) — `weekly-review` skill in the Full install tier
- Anthropic docs: [Monitoring usage](https://docs.anthropic.com/en/docs/claude-code/monitoring-usage) — official OTEL setup

---

*Last updated: 2026-04-20. Schema data current for CC 2.1.111.*
