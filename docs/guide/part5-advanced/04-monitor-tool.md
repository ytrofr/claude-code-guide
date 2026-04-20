---
layout: default
title: "Monitor Tool — Streaming Background Process Events"
parent: "Part V — Advanced"
nav_order: 4
redirect_from:
  - /docs/guide/74-claude-code-monitor-tool.html
  - /docs/guide/74-claude-code-monitor-tool/
---

# Monitor Tool — Streaming Background Process Events

**Added in**: Claude Code 2.1.98. Current as of 2.1.111+.

The Monitor tool streams events from background scripts. Each stdout line from the monitored process becomes a notification event in your conversation.

---

## What it does

When you start a background process with `Bash(run_in_background: true)`, the process runs detached. Previously, you had to periodically `Read` the output file to check progress. Monitor changes this — it attaches to the background process and streams each stdout line as an event.

```
User: "Build my project and let me know when it's done"

1. Bash(run_in_background: true): npm run build
   → Returns task_id: "abc123"

2. Monitor(task_id: "abc123")
   → Streams: "Compiling TypeScript..."
   → Streams: "Building 47 modules..."
   → Streams: "Build complete in 34s"
```

---

## Monitor vs ScheduleWakeup — decision matrix

| Scenario | Use | Why |
|----------|-----|-----|
| Tailing build/deploy logs | **Monitor** | Each stdout line = notification |
| Waiting for long test to finish | **Monitor** | Notified on process exit |
| Watching streaming fetch output | **Monitor** | Observable progress lines |
| Log tailing for another process | **Monitor** | Wrap with `tail -F <file>` |
| Inter-agent bus live stream | **Monitor** | `tail -F log.jsonl \| jq filter` |
| "Check back in 30 min" | **ScheduleWakeup** | No process to attach to |
| Rate-limit backoff retry | **ScheduleWakeup** | Time-delayed, cache-window aware |
| `/loop` skill patterns | **ScheduleWakeup** | User-approved dynamic pacing |
| Idle loop, no signal to watch | **ScheduleWakeup** | Default to 1200-1800s delay |

**Key difference**: Monitor is event-driven (something is producing stdout). ScheduleWakeup is time-driven (you want to check later). They solve different problems — don't substitute one for the other.

---

## Usage patterns

### Build watching

```
1. Start build in background
2. Monitor the task to stream compiler output
3. React when build succeeds or fails
```

### Deploy streaming

```
1. Start deploy script in background (gcloud run deploy, vercel deploy, fly deploy)
2. Monitor for deployment progress, URL assignment, health check results
3. Proceed when "Service is live" appears
```

### Long database operations

```
1. Start migration in background
2. Monitor for per-table progress
3. React if an error line appears
```

### File tailing (wrap tail -F)

Monitor streams stdout, not file changes. To watch a log file, wrap it:

```
Bash(run_in_background: true): tail -F /var/log/app.log
→ task_id: "xyz789"
Monitor(task_id: "xyz789")
```

### Inter-agent bus streaming

When coordinating with another Claude session across projects (see [Inter-agent bus](02-inter-agent-bus.html)), attach Monitor to the shared event log filtered to this project:

```
Monitor(
  command: 'tail -n 0 -F ~/shared/inter-agent/log.jsonl | jq --unbuffered -c --arg me "alpha" "select(.to==\$me and .kind==\"msg\")"',
  description: "inter-agent messages to alpha",
  timeout_ms: 900000
)
```

Each new message from the other side fires as a notification. Replace `alpha` with your agent code per invocation.

---

## Anti-patterns

- **Monitor for short commands**: if the command takes <5 seconds, just run it with Bash directly. Monitor's per-event overhead isn't justified.
- **Monitor for file watching**: Monitor streams *stdout*, not file changes. Use `tail -F` as the background command (see above).
- **Nested Monitor without exit**: if the background process is noisy (hundreds of lines/second), Monitor will flood the conversation. Filter at the source: `command | grep -E 'ERROR|WARN|COMPLETE'`.
- **Using ScheduleWakeup to poll a live build**: wastes prompt cache windows — you'll re-read logs from scratch each wake-up.
- **Monitor on a process writing to a file, not stdout**: Monitor only streams stdout lines. Pipe the file via `tail -F`.

---

## Interaction with ScheduleWakeup and cache windows

ScheduleWakeup durations under 270s keep the prompt cache warm (5-minute TTL). Durations at exactly 300s are the worst: cache miss without meaningful wait benefit.

Monitor doesn't interact with cache scheduling at all — it's event-driven. Use it when you have stdout to stream, not to optimize cache windows.

---

## Combining Monitor with inter-project coordination

Monitor is what makes the [inter-agent bus](02-inter-agent-bus.html) feel live: one side posts to `log.jsonl`, the other side's Monitor filter surfaces it as a notification within ~100ms of the write. Without Monitor, the pattern degrades to "check `/talk list` periodically" — workable but not responsive.

Similar pairings:

| Pipeline | Monitor target |
|----------|----------------|
| Self-telemetry (this chapter) | Nothing — telemetry hooks are fire-and-forget, no polling needed |
| Inter-agent bus | `tail -F log.jsonl \| jq filter` |
| CI/CD watch | `tail -F <pipeline-log>` or attach to deploy task |
| Remote log tail | `ssh host 'tail -F /var/log/app.log'` |

---

## OTEL interaction

Monitor runs at the hook/tool layer and does not emit OTEL spans itself. If you're running a local OTLP collector (see [Self-telemetry](03-self-telemetry.html) §15), Monitor events won't show up in Honeycomb/Jaeger — they're a conversation-level UI primitive, not an API-level request.

The background Bash process *inside* Monitor may emit OTEL if it's a subprocess of a CC turn (2.1.98+ auto-propagates `TRACEPARENT`). But Monitor's own "stdout line → notification" step is not traced.

---

## See also

- [Inter-agent bus](02-inter-agent-bus.html) — primary consumer of Monitor for cross-project coordination
- [Self-telemetry](03-self-telemetry.html) — hooks + jsonl (no Monitor needed)
- [CC version history](../part6-reference/01-cc-version-history.html) — Monitor added in 2.1.98
- [Statusline patterns](05-statusline-patterns.html) — a different background-refresh primitive

---

*Last updated: 2026-04-20. Compatible with Claude Code 2.1.111+.*
