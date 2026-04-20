---
layout: default
title: "Inter-Agent Bus"
parent: "Part V — Advanced"
nav_order: 2
redirect_from:
  - /docs/guide/76-inter-agent-coordination.html
  - /docs/guide/76-inter-agent-coordination/
---

# Inter-Agent Bus — Shared Coordination Channel

**Problem**: You run Claude Code in two (or six) projects on the same machine. When work in `<PROJECT-A>` depends on agreement from `<PROJECT-B>` — a coordinated deploy, a cross-service contract change, a "did you flip the flag yet?" check — the only channel today is you, as the human, copy-pasting messages between terminal windows. Slow, no audit trail, breaks context.

**Solution**: a shared file-based bus every Claude session can read and write, with three invariants:

1. **Pointer-not-content**: SessionStart injects a ≤800 char pointer, not the thread body. Full thread loaded only on-demand.
2. **User-supervised**: every send defaults to draft-and-confirm; user approves each message before it crosses the bus.
3. **Three-tier storage**: active thread (markdown) → archive (markdown, 7-90 days) → Basic Memory (90d+, wiki-linked).

No new daemons, no MCP server, no external service. Just files, a global SessionStart hook, one skill, and one cron.

Compatible with Claude Code 2.1.111+ (uses Monitor tool for live streaming and `$CLAUDE_PROJECT_DIR` for path portability).

---

## When you need this

- Two projects on one machine where Claude-A is waiting on Claude-B (coordinated auth flip, schema migration, deploy gate).
- Cross-service contract changes (e.g. a breaking API shape change) that require both parser and sender to land in order.
- You want a durable record of agent-to-agent agreements so a future Claude in either project can pick up the thread.
- You're copying messages between terminals more than twice per task.

## When NOT to use it

- Talking to the user (just respond normally).
- Notes-to-self (TodoWrite or memory systems).
- Broadcast announcements — this is 1:1 or small-group, not pub/sub.
- Anything urgent that needs human attention — tell the user directly.

---

## Architecture

```
                    ┌─────────────────────────────────────────┐
                    │        $HOME/shared/inter-agent/        │
                    │                                         │
                    │  active/   log.jsonl   threads.json     │
                    │  archive/  .staging/   identity-map     │
                    └────────────┬────────────────────────────┘
                                 │
          ┌──────────────────────┼──────────────────────┐
          │                      │                      │
   ┌──────▼──────┐        ┌──────▼──────┐        ┌──────▼──────┐
   │ <PROJECT-A> │        │ <PROJECT-B> │        │ <PROJECT-C> │
   │  Claude     │        │  Claude     │        │  Claude     │
   │             │        │             │        │             │
   │ SessionStart│        │ SessionStart│        │ SessionStart│
   │  → pointer  │        │  → pointer  │        │  → pointer  │
   │             │        │             │        │             │
   │ /talk <id>  │◄──────►│ /talk <id>  │        │             │
   │ (on-demand) │  log   │ (on-demand) │        │             │
   │             │        │             │        │             │
   │ Monitor tail│        │ Monitor tail│        │             │
   │ jq filter   │        │ jq filter   │        │             │
   └─────────────┘        └─────────────┘        └─────────────┘
          │                      │                      │
          └──────────────────────┴──────────────────────┘
                                 │
                    ┌────────────▼────────────────┐
                    │  $HOME/basic-memory/        │
                    │  inter-agent/               │
                    │  (90d archive promotion)    │
                    └─────────────────────────────┘
```

### File layout

```
$HOME/shared/inter-agent/
├── active/                    # Live threads — one markdown file per topic
├── archive/YYYY-MM/           # Resolved / stale threads
├── log.jsonl                  # Append-only event log (flocked writes)
├── log/                       # ops.log + rotated month files
├── threads.json               # Index of all threads
├── identity-map.json          # project-dir basename → agent code
├── .staging/                  # Drafts awaiting user --confirm
├── .last-seen/                # Per-agent unread-tracking
└── bin/
    ├── resolve-identity.sh    # git toplevel → agent code
    ├── active-thread-pointer.sh  # SessionStart injection
    └── talk.sh                # list, new, send, resolve, stream, history, doctor
```

### Three-tier storage

| Tier | Location | When loaded into Claude's context | Size cap |
|------|----------|-----------------------------------|----------|
| Pointer | SessionStart hook stdout | Every session, only when active threads exist | ≤800 chars (≤5 threads × ~150 chars) |
| Thread content | `active/{id}.md` | On-demand via `/talk <id>` | 0 unless opened |
| Event log | `log.jsonl` | Never auto-loaded; `talk.sh history` greps | 0 |
| Archive | `$HOME/basic-memory/inter-agent/` (≥90d) | On-demand search | 0 |

Net always-on cost: 0 when idle, ≤800 chars when any threads. Compare with "auto-load full history" (5 threads × 10 msgs × 200 chars = 10K always-on) — 12× reduction.

---

## Identity resolution — no new per-project file

Every project gets an "agent code" derived from the git toplevel basename:

```bash
# bin/resolve-identity.sh (~15 lines)
TOP="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
DIR="$(basename "$TOP")"
AGENT="$(jq -r --arg d "$DIR" '.map[$d]' identity-map.json)"
```

The map is a single JSON file:

```json
{
  "map": {
    "project-alpha":  "alpha",
    "project-beta":   "beta",
    "multi-branch-*": "shared"
  },
  "prefix_map": {
    "multi-branch-": "shared"
  }
}
```

Adding a project = one JSON edit. Prefix matching supports monorepo or multi-branch setups where multiple directories share an identity.

---

## Thread file format

```markdown
---
thread_id: auth-flip-20260415
participants: [alpha, beta]
status: active              # active | resolved | stale
mode: draft-confirm         # draft-confirm | auto
topic: Cross-service auth flip coordination
created: 2026-04-15T14:30:00Z
last_activity: 2026-04-15T15:04:00Z
last_msg_preview: "Confirmed 10:00 UTC. Deploying now."
---

## Timeline
- **[14:30 alpha]** Ready to deploy toggle OFF. Flip window 10:00 UTC tomorrow?
- **[14:32 beta]** Confirmed 10:00 UTC. Deploying now.
```

Human-readable. Greppable. Edit-friendly. No database.

---

## Event log (log.jsonl)

One JSON object per line. Append-only. `flock`-serialized to prevent concurrent-write corruption:

```json
{"ts":"2026-04-15T15:02:00Z","thread":"auth-flip-20260415","from":"alpha","to":"beta","kind":"msg","body":"..."}
{"ts":"...","thread":"auth-flip-20260415","kind":"status","status":"resolved","by":"alpha"}
```

`kind` ∈ `{msg, status, system}`. Never auto-loaded into context; used for history search and Monitor tool streaming.

---

## SessionStart injection (the always-on part)

Rather than editing every project's `session-start.sh`, put the pointer call in your global SessionStart hook declared in `$HOME/.claude/settings.json`:

```bash
# Appended to the end of your existing global SessionStart hook
if [ -x "$HOME/shared/inter-agent/bin/active-thread-pointer.sh" ]; then
    "$HOME/shared/inter-agent/bin/active-thread-pointer.sh" 2>/dev/null || true
fi
```

**Why global, not per-project**: in practice, not every project has a `session-start.sh`. A global hook runs in every session in every project — one edit covers all N projects. Suppresses all errors so the hook chain never breaks.

The pointer script reads `threads.json`, filters to threads involving the current project's agent code, and prints a pointer block:

```
═══ ACTIVE INTER-AGENT THREADS ═══
- [auth-flip-20260415] with beta — 1h ago (unread) — "Confirmed 10:00 UTC..."
- [schema-migration-v4-20260413] with beta — 2d ago — "still blocked on..."
Use /talk <id> to open, /talk-new <to> "<topic>" to start.
```

- ≤5 threads shown, most recent first.
- `(unread)` marker until the current agent runs `/talk <id>` (tracked per-agent in `.last-seen/`).
- Silent exit when no active threads — zero pollution of idle sessions.

## The skill

Register as a machine-level skill at `$HOME/.claude/skills/inter-agent/SKILL.md` with frontmatter:

```yaml
---
name: inter-agent
description: "Coordinate with Claude in another project via shared bus. Use when two projects need to align on a deploy, fix, or decision. Commands: /talk list, /talk <id>, /talk-new <to> \"<topic>\", /talk-send <id> \"<msg>\", /talk-resolve <id>."
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Monitor
---
```

The **description is the entire always-on discovery cost** — Claude sees it in the skill list every session. No separate always-on rule is needed. If you have a rules budget cap (which most production setups do, once you cross 100+ rules), this matters: it saves you from adding ~1,500 chars of always-on rule content.

---

## Supervision: draft-and-confirm

Default flow:

```bash
talk.sh send "$TID" "Ready to deploy toggle OFF"
# Writes draft to $HOME/shared/inter-agent/.staging/<TID>.pending.md
# Prints: "DRAFT staged: ... To send, re-run with --confirm"
```

The staging file is both the **confirmation UI** and the **editable draft**. User can read it, edit it in place, or re-run with `--confirm` to commit:

```bash
# Option 1: Commit as-is
talk.sh send "$TID" "Ready to deploy toggle OFF" --confirm

# Option 2: Edit staging file, then
talk.sh send-staged "$TID"
```

Opt-in autonomous: set `mode: auto` in the thread's frontmatter. Future `talk.sh send` on that thread skips staging. Use only for established back-and-forth flows where both sides agreed on a protocol (e.g. "ack" / "done" pings between already-coordinated deploys).

---

## Live streaming with the Monitor tool

When actively collaborating, attach Monitor (CC 2.1.98+) to stream the other side's messages as notifications:

```
Monitor(
  command: 'tail -n 0 -F ~/shared/inter-agent/log.jsonl | jq --unbuffered -c --arg me "alpha" --arg t "auth-flip-20260415" "select(.thread==\$t and .to==\$me and .kind==\"msg\")"',
  description: "inter-agent messages on auth-flip to alpha",
  timeout_ms: 900000
)
```

Each new line becomes one notification (~200 chars). Replace `alpha` and the thread id per invocation. See Part V ch.4 (Monitor tool) for the full decision matrix.

---

## Commands

| Slash (or alias) | Shell | Effect |
|------------------|-------|--------|
| `/talk list` | `talk.sh list` | Active threads for current project |
| `/talk <id>` | `talk.sh show <id>` | Render thread markdown (on-demand load) |
| `/talk-new <to> "<topic>"` | `talk.sh new <to> "<topic>"` | Create thread + system:created event |
| `/talk-send <id> "<msg>"` | `talk.sh send <id> "<msg>" [--confirm]` | Draft or send |
| `/talk-send-staged <id>` | `talk.sh send-staged <id>` | Commit staged draft after edit |
| `/talk-stream <id>` | Monitor pipe (above) | Live notifications |
| `/talk-resolve <id>` | `talk.sh resolve <id>` | Flip status; archive after 24h |
| `/talk-history <query>` | `talk.sh history <query>` | Grep log.jsonl + rotated logs |
| `/talk doctor` | `talk.sh doctor` | Validate JSON, permissions, identity |

---

## Archival + Basic Memory promotion

Daily cron at 04:05 UTC (`$HOME/.claude/scripts/inter-agent-maintenance.sh`):

| Event | Action |
|-------|--------|
| `status=resolved` | Stays in `active/` 24h, then → `archive/YYYY-MM/` |
| No activity ≥7 days | → `archive/YYYY-MM/` with `status=stale` |
| Archive entries ≥90 days | Promoted to Basic Memory `inter-agent/`, original deleted |
| `log.jsonl` ≥10MB | Rotated to `log/YYYY-MM.jsonl` |

Register with:

```bash
(crontab -l; echo "5 4 * * * \$HOME/.claude/scripts/inter-agent-maintenance.sh >/dev/null 2>&1") | crontab -
```

The Basic Memory promotion generates proper observation taxonomy and wiki-links back to participating projects — the thread becomes a searchable knowledge-graph node even after the file is gone.

---

## End-to-end walkthrough

Real case: two projects (call them `<PROJECT-A>` and `<PROJECT-B>`) need to coordinate a two-layer OIDC + user-claim JWT auth flip. Feature toggle default-OFF on both sides, 24h soak, simultaneous flip the next day.

### Before (copy-paste era)

```
<A>'s terminal: "<A> deployed revision 00037-nxc, toggle OFF. <B>, verify env vars?"
user: [Ctrl-C, switch terminal, paste]
<B>'s terminal: "Confirmed env vars mounted. Deploying <B> now with toggle OFF."
user: [Ctrl-C, switch terminal, paste]
<A>'s terminal: "24h soak starts now. Flip at 10:00 UTC tomorrow?"
user: [Ctrl-C, switch terminal, paste]
<B>'s terminal: "Confirmed 10:00 UTC."
```

Six copy-pastes, no record.

### After (inter-agent bus)

```bash
# <A>'s session:
talk.sh new <B> "Auth flip coordination — revision 00037-nxc"
talk.sh send auth-flip-coordination-revision-00037-20260415 \
  "<A> deployed rev 00037-nxc, toggle OFF. Verify env vars on your side?" --confirm

# <B>'s session (next SessionStart shows pointer):
talk.sh show auth-flip-coordination-revision-00037-20260415
talk.sh send auth-flip-coordination-revision-00037-20260415 \
  "Confirmed. Deploying <B> with toggle OFF now." --confirm

# <A>'s session (Monitor fires notification):
talk.sh send auth-flip-coordination-revision-00037-20260415 \
  "24h soak. Flip at 10:00 UTC tomorrow?" --confirm

# <B>'s session:
talk.sh send auth-flip-coordination-revision-00037-20260415 \
  "Confirmed 10:00 UTC." --confirm

# after successful flip:
talk.sh resolve auth-flip-coordination-revision-00037-20260415
```

Zero copy-pastes. Durable record. 90 days later, any future Claude in either project can grep `talk.sh history auth-flip` or search Basic Memory for the full decision trail.

---

## Token budget math

Always-on budget impact (in addition to your existing setup):

| Component | Cost | Notes |
|-----------|------|-------|
| Skill description | ~250 chars | Skill budget, not rules |
| SessionStart pointer (0 active threads) | 0 chars | Silent exit |
| SessionStart pointer (1 active thread) | ~180 chars | 3 lines |
| SessionStart pointer (5 active threads) | ~800 chars | 7 lines (header + 5 + footer) |

At the ceiling case (5 active threads), you're adding ~1 KB to your always-on budget. If your baseline is at 200-250 KB (typical mature setup), this is a <0.5% increase.

Compare with the naive approach — auto-load full thread content:
- 5 threads × ~2 KB avg × auto-load = 10 KB always-on
- Scales with thread length, potentially 50 KB+ on long conversations
- Eats a non-trivial chunk of your budget

The pointer-not-content design is the difference between "feature is free" and "feature costs 5% of your budget."

---

## Why this is a pattern, not a product

Every piece of this bus is ~200 lines of bash or shorter:

- `resolve-identity.sh` — 15 lines
- `active-thread-pointer.sh` — 50 lines
- `talk.sh` — 250 lines
- `inter-agent-maintenance.sh` — 100 lines

Total ~600 LOC + 1 skill + 1 cron entry + 1 global hook edit. No dependencies beyond `jq`, `flock`, `tail -F`, `git` (all standard).

Fork it, adapt the identity map to your project set, adjust the archive TTL, add authentication if you're spanning machines — every piece is swap-in-replace at this scale.

---

## Design principles (transferable beyond this feature)

1. **Pointer-not-content for any "inbox" feature**. Surface the unread *count*, not the unread *content*. Cost scales with thread count, not thread size.
2. **Global hook > per-project hooks for cross-cutting features**. One edit covers N projects. Eliminates drift risk.
3. **Skill description is free always-on context**. If you have a rules budget cap, put feature docs in a skill's `description` field — Claude discovers it every session via the skill list without consuming rules budget.
4. **Draft-and-confirm via staging file**. The staging file is simultaneously the UI (user can read it), the edit surface (user can modify it), and the confirmation gate (user runs `--confirm` or `send-staged` to commit). One artifact, three functions.
5. **Three-tier storage**. Active (hot, on-demand into context) → Archive (cold, filesystem, greppable) → Knowledge graph (searchable, wiki-linked). Each tier is zero always-on cost.

---

## Caveats

- **Single-user machine only, as specified here.** No HMAC, no encryption. If you want this to span machines: add signed tokens per message, move `$HOME/shared/` to a synced dir (iCloud, Dropbox, S3), handle write conflicts.
- **No pub/sub.** Messages are explicitly addressed (`to:` field). If you need broadcast, fork and add it.
- **Requires `jq`, `flock`, `tail -F`, `git`.** Standard on Linux/macOS with common tooling.
- **Global hook is best-effort.** If your SessionStart hook chain already has 10+ entries, one more adds to startup latency. Profile before adding.
- **Basic Memory promotion is one-way.** Once a thread goes to Basic Memory, the original file is deleted. Treat the 90-day cutoff as a soft ceiling — long-running threads should be resolved or refreshed before expiry.

---

## See also

- [Monitor tool](04-monitor-tool.html) — streaming log.jsonl for live notifications
- [Cross-project knowledge sharing](06-cross-project-knowledge.html) — related shared-layer patterns
- [Hook event catalog](../part6-reference/03-hook-event-catalog.html) — SessionStart payload format
- [Context costs & skill budget](../part6-reference/04-skill-catalog.html) — skill description budget math

---

*Last updated: 2026-04-20. Compatible with Claude Code 2.1.111+.*
