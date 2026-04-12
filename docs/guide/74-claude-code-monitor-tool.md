---
layout: default
title: "Claude Code Monitor Tool — Streaming Background Process Events"
description: "When and how to use the Monitor tool for streaming stdout from background scripts, versus ScheduleWakeup for time-delayed polling."
parent: Guide
nav_order: 74
---

# Claude Code Monitor Tool — Streaming Background Process Events

**Added in**: Claude Code 2.1.98

The Monitor tool streams events from background scripts. Each stdout line from the monitored process becomes a notification event in your conversation.

---

## What It Does

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

## Monitor vs ScheduleWakeup Decision Matrix

| Scenario | Use | Why |
|----------|-----|-----|
| Tailing build/deploy logs | **Monitor** | Each stdout line = notification |
| Waiting for long test to finish | **Monitor** | Notified on process exit |
| Watching streaming fetch output | **Monitor** | Observable progress lines |
| "Check back in 30 min" | **ScheduleWakeup** | No process to attach to |
| Rate-limit backoff retry | **ScheduleWakeup** | Time-delayed, cache-window aware |
| `/loop` skill patterns | **ScheduleWakeup** | User-approved dynamic pacing |
| Idle loop, no signal to watch | **ScheduleWakeup** | Default to 1200-1800s delay |

**Key difference**: Monitor is event-driven (something is producing stdout). ScheduleWakeup is time-driven (you want to check later). They solve different problems.

---

## Usage Patterns

### Build Watching

```
1. Start build in background
2. Monitor the task to stream compiler output
3. React when build succeeds or fails
```

### Deploy Streaming

```
1. Start deploy script in background (gcloud run deploy, vercel deploy)
2. Monitor for deployment progress, URL assignment, health check results
3. Proceed when "Service is live" appears
```

### Long Database Operations

```
1. Start migration in background
2. Monitor for per-table progress
3. React if an error line appears
```

---

## Anti-Patterns

- **Monitor for short commands**: If the command takes <5 seconds, just run it with Bash directly. Monitor's per-event overhead isn't justified.
- **Monitor for file watching**: Monitor streams *stdout*, not file changes. If you need to watch a log file, wrap it: `tail -f /var/log/app.log` as the background command.
- **Nested Monitor without exit**: If the background process is noisy (hundreds of lines/second), Monitor will flood the conversation. Add `| grep -E 'ERROR|WARN|COMPLETE'` to the background command.
- **Using ScheduleWakeup to poll a live build**: Wastes prompt cache windows — you'll re-read logs from scratch each wake-up.

---

## Interaction with ScheduleWakeup and Cache Windows

ScheduleWakeup durations under 270s keep the prompt cache warm (5-minute TTL). Durations at exactly 300s are the worst: cache miss without meaningful wait benefit.

Monitor doesn't interact with cache scheduling at all — it's event-driven. Use it when you have stdout to stream, not to optimize cache windows.

---

*See also: [Chapter 73 — 2.1.98-2.1.99 Features](73-claude-code-2198-2199-features.md) | [Chapter 75 — Statusline Patterns](75-claude-code-statusline-patterns.md)*
