---
layout: default
title: "Browser Capture — Multi-Tenant Behavioral DNA"
parent: "Part V — Advanced"
nav_order: 8
---

# Browser Capture — Multi-Tenant Behavioral DNA

**Scope**: a zero-dependency, always-on observability layer for UI debugging across every project on your machine. One Node.js HTTP server on `localhost:9876`, one auto-injected browser client, one slash skill. Every project tags itself with `?project=<id>`; the server keeps per-project ring buffers. Production is unreachable by design.

**Why this chapter exists**: every UI debug session starts with "what does the console show?" — and the answer is almost always "I can't reproduce that." This chapter ships a pattern that captures the user's real browser state — clicks, longtasks, freezes, breadcrumbs, console errors — into a per-project ring you can `curl` or read via `/capture <project>`. Same port works for a Vite dev page, a Jekyll site, a Remotion editor, a Python backend tool dispatch. Five projects share one server.

---

## 1. The problem this solves

Most UI bugs surface as "it doesn't work on my machine" or "it froze and I don't know what I clicked." Screenshots lose timing. Console pastes lose attribution. Playwright replays don't reproduce the user's exact session.

What you actually want is the user's **behavioral DNA** — the sequence of events leading up to the failure — captured automatically and routed to a place you can read later. Standard solutions (Sentry, LogRocket, etc.) cost money, require account setup, and surface dashboards designed for shipping bugs to a triage queue, not for chat-driven debugging with Claude Code.

What works instead is a single localhost server, started once via `.bashrc`, that all your projects post to. Per-project ring buffers. 24-hour auto-purge. No external dependencies. No accounts. Production sites cannot reach it because it binds to 127.0.0.1.

## 2. Architecture

```
User's Browser (any project)           localhost:9876               Claude / curl
┌───────────────────────────┐  POST    ┌──────────────────┐  GET    ┌─────────┐
│ <script src=              │ ───────► │ server.js        │ ◄─────  │ /capture│
│  localhost:9876/inject.js │ /event   │ Map<proj, Ring>  │ /summary│ curl+jq │
│  ?project=hub>            │ /events  │ + translation    │ ?project│         │
└───────────────────────────┘          └──────────────────┘         └─────────┘
        │                                       ▲
        │ python httpx                          │
        ▼                                       │
┌───────────────────────────┐                   │
│ AgentSmith forensics_emit │ ──────────────────┘
│ (server-side, env-gated)  │
└───────────────────────────┘
```

Two-layer system: a Node.js server holds per-project ring buffers in memory, and a browser-side IIFE (`inject.js`) auto-posts events with the right project tag. Python services with no browser surface POST directly via a tiny `httpx` helper.

The server is **multi-tenant** — every event carries a `project` field (or the server infers it from `Origin`). Five rings, one server, no cross-project contamination.

## 3. The locked event contract

Three shapes coexist forever via a 10-line translation layer:

```javascript
// Shape 1: Locked (preferred for new projects)
POST /event
{
  "project":    "hub",                    // optional — server infers from Origin if omitted
  "session_id": "abc123",                 // required
  "stage":      "click" | "longtask" | "freeze" | "breadcrumb" | ...,
  "data":       { /* free-form */ },
  "timestamp":  1778440000000,            // optional, server fills
  "page":       "/dashboard",             // optional
  "git_branch": "feature/foo",            // optional
  "git_sha":    "abc1234",                // optional
  "user_agent": "Mozilla/..."             // optional
}

// Shape 2: Legacy OGAS — server maps {kind, entry} → {stage, data}
POST /event { "kind": "breadcrumb", "entry": { ... } }

// Shape 3: Legacy plural batch — for the existing pointer-event capturer
POST /events { "project": "hub", "events": [{type, t, x, y, ...}, ...] }
```

Why three shapes? Different projects already had different forensics primitives before the multi-tenant rollout. Picking one and forcing the others to migrate would block ship indefinitely. The translation layer adds ~10 lines to the server and resolves the migration problem permanently — projects upgrade to the locked shape on their own schedule, all three route to the same per-project ring.

## 4. Origin inference fallback

When `project` is omitted (typical for legacy forensics modules that predate the locked contract), the server infers from the `Origin` or `Referer` header against a known-project map:

| Origin prefix | Project |
|---|---|
| `http://localhost:8000`, `http://127.0.0.1:8000` | `ogas-websites` |
| `http://localhost:5173`, `http://127.0.0.1:5173` | `ogas-websites` |
| `http://localhost:4444`, `http://127.0.0.1:4444` | `ai-intelligence-hub` |
| `http://localhost:4000`, `http://127.0.0.1:4000` | `claude-code-guide` |
| `http://localhost:3000`, `http://localhost:3001` | `claude-remotion-editor` |
| `http://localhost:8001` | `agentsmith` |

Explicit `project` always wins. Unmapped Origin falls back to `_default`. The map lives at the top of `server.js` — add an entry when onboarding a new dev port.

Why this matters: it lets the legacy OGAS `ForensicsModule` (which POSTs `{kind, entry}` with no `project` field) land in the `ogas-websites` ring with **zero edits** to OGAS code. The translation + inference combo means cross-team rollouts don't block on cross-team commits.

## 5. Integrating a new project — three patterns

Pick the pattern that fits the surface. All three target the same `localhost:9876/event` endpoint.

### Static HTML / Vite / any browser dev page

```html
<!-- Inside <head> -->
<script src="http://localhost:9876/inject.js?project=my-project"
        defer onerror="this.remove()"></script>
```

`<my-project>` must match `[a-zA-Z0-9_-]+` (server sanitizes). The server reads `?project=` from the script-tag URL and prepends `window.__BCAP_PROJECT__=<name>;` to the served body so the IIFE picks up the project tag.

### Jekyll

Same `<script>` tag inside a `{% if jekyll.environment != "production" %}` guard in `_layouts/default.html`. Belt-and-suspenders — the production hostname-gate fail-closes regardless, but the guard keeps production HTML clean.

### Python / Node server-side

A small fire-and-forget client. Reference implementation:

```python
# app/observability/forensics_emit.py
import asyncio, os, time, uuid
import httpx

_ENABLED  = os.getenv("MYAPP_FORENSICS_ENABLED", "false").lower() == "true"
_ENDPOINT = "http://localhost:9876/event"
_TIMEOUT  = 0.1
_SID      = (os.getenv("K_REVISION") or os.getenv("HOSTNAME") or uuid.uuid4().hex)[:32]

async def emit(stage: str, data: dict | None = None) -> None:
    if not _ENABLED:
        return
    payload = {
        "project":    "my-project",
        "session_id": _SID,
        "stage":      str(stage)[:128],
        "data":       data or {},
        "timestamp":  int(time.time() * 1000),
    }
    try:
        async with httpx.AsyncClient(timeout=_TIMEOUT) as client:
            await client.post(_ENDPOINT, json=payload)
    except Exception:
        pass  # best-effort; never blocks the caller
```

**Default OFF**. Enable in `.env.local` only — NEVER in production deploy config. The 100ms timeout caps the worst case if the local server happens to be down.

Call sites use `asyncio.create_task(emit(...))` to make it truly fire-and-forget:

```python
async def execute(self, ...):
    if forensics_emit.is_enabled():
        asyncio.create_task(forensics_emit.emit("my_tool.execute", {
            "args_present": bool(args),
            "user_present": bool(user_id),
        }))
    # ... actual tool logic ...
```

## 6. The client side — `__capture` v3

When `inject.js` loads on a project page, it installs `window.__capture` with the following surface:

```javascript
window.__capture.breadcrumb('stage', { /* data */ })  // emit a forensics event
window.__capture.dump()                                // returns full snapshot
window.__capture.tagSession({ git_branch: 'foo' })    // attach metadata to future events
window.__capture.wrapConsole()                         // forward console.warn/error
window.__capture.start()                               // enable pointermove tracking
window.__capture.stop()                                // back to passive mode
window.__capture.project                               // the active project tag
window.__capture.sessionId                             // page-load random id
window.__capture._v                                    // 3
```

Three event streams collected automatically:

- **Pointer events** (always on): pointerdown / pointerup / click / dragstart / dragend — batched every 500ms to `POST /events`.
- **Longtasks** (`PerformanceObserver`): tasks >50ms blocking the main thread → posted as `stage: longtask`.
- **Freezes** (500ms heartbeat): if the JS thread gaps >800ms, a `stage: freeze` event with `gap_ms` is recorded.

Plus `console.warn`/`console.error` if you opt in with `?capture_console=1`.

All three categories ALSO write to `localStorage` rings (200 breadcrumbs, 50 longtasks, 50 freezes) so `__capture.dump()` recovers the last state even when the server is down.

## 7. Reading captured events — the `/capture` slash

User-invocable slash skill at `~/.claude/skills/capture/SKILL.md`. Usage:

```text
/capture                    → list active projects
/capture hub                → full summary: red flags + top longtasks + freezes + last 20 events
/capture hub freeze         → filter recent events to one stage type
```

Behind the slash, three curl commands:

```bash
curl -s http://localhost:9876/projects | jq .
curl -s 'http://localhost:9876/summary?project=hub' | jq .
curl -s 'http://localhost:9876/summary?project=hub&types=freeze&limit=200' | jq .
```

Plus a companion **soft-hint rule** at `~/.claude/rules/quality/browser-capture-first.md` that tells Claude: when the user reports a UI bug, prefer `/capture <project>` before asking "what does the console show?". Pointer-rule shape, ≤2 KB, no auto-curl mandate.

## 8. Two production-safety gates

The system is fail-closed at two layers:

**Network**: `localhost:9876` binds to `127.0.0.1` — unreachable from any production site. Even if a script tag accidentally shipped to production, the POST would fail.

**Hostname gate (client)**: `inject.js` installs a no-op `__capture` stub UNLESS one of these is true:

```javascript
const ok =
    location.hostname === 'localhost' ||
    location.hostname === '127.0.0.1' ||
    location.hostname === '::1' ||
    location.hostname.endsWith('.local') ||
    new URLSearchParams(location.search).get('capture') === '1' ||
    localStorage.getItem('capture') === '1';
```

Verified via Playwright fresh-context probe against the production OGAS site — both `sigmafier.com` plain and `sigmafier.com?capture=1` make zero requests to `localhost:9876`. The first because the production HTML doesn't include the script tag; the second because even if it did, the hostname check fails before the IIFE runs.

## 9. Two gotchas worth knowing

**sendBeacon + `Content-Type: application/json` = silent cross-origin drop.** A `Content-Type: application/json` POST is NOT a CORS-simple request. The browser issues a preflight `OPTIONS` — but `sendBeacon` does not wait for the preflight response. If the preflight is in-flight when the page unloads, the actual POST is dropped silently with no error. Fix: use `Content-Type: text/plain` (CORS-simple — no preflight). The server JSON-parses the body regardless of `Content-Type`, so the shape is unchanged.

**Origin inference exists for a reason.** A common pattern is "we already have a forensics module, we just want it to land in the right ring." Don't force every project to migrate to the locked shape upfront. Add the Origin to the server's map, let the existing client POST whatever shape it already POSTs, and migrate later. Translation + Origin inference together resolve the cross-team migration problem permanently.

## 10. Validation

The reference implementation ships two test runners:

```bash
node ~/.claude/tools/browser-capture/test_server.js   # 20 unit tests for the server
bash ~/.claude/tools/browser-capture/e2e_validate.sh  # 38 E2E checks across the full stack
```

E2E coverage: pre-flight, server lifecycle, three event shapes, Origin inference (5 scenarios incl. unmapped → `_default`), `/clear?project=` surgical, `/summary?project=` filtering, `/inject.js?project=` echo and sanitization, helper module in-process round-trip, every per-project integration file (script tag + Python helper imports), rule + slash-skill artifacts, status file invariants, all five production projects appearing in `/projects`.

Browser-side checks (cross-origin sendBeacon, hostname-gate fail-closed) are validated interactively via the Playwright MCP — see the project's status file phase log for evidence.

## 11. When to skip

This pattern is overkill for:

- Pure backend services with no chat / UI / debug surface (one of the projects on the reference machine is documented as `no-surface` for exactly this reason).
- Static documentation sites where there is nothing to debug.
- Production-only services that never run on a developer machine.

For the projects where it does apply, it pays for itself the first time you skip a 20-minute back-and-forth ("can you check the console?", "no errors", "can you screenshot?", "still nothing", ...) by running `/capture <project>` and seeing the freeze and longtask sequence in one shot.

---

**Files**:

- `~/.claude/tools/browser-capture/server.js` — multi-tenant server, ~430 LOC
- `~/.claude/tools/browser-capture/inject.js` — browser client, ~440 LOC
- `~/.claude/tools/browser-capture/ensure-running.sh` — autostart, called from `~/.bashrc`
- `~/.claude/tools/browser-capture/test_server.js` — 20-case unit tests
- `~/.claude/tools/browser-capture/e2e_validate.sh` — 38-check E2E runner
- `~/.claude/tools/browser-capture/README.md` — full integration guide
- `~/.claude/skills/browser-capture/SKILL.md` — knowledge skill (auto-loaded)
- `~/.claude/skills/capture/SKILL.md` — `/capture` slash skill
- `~/.claude/rules/quality/browser-capture-first.md` — soft-hint pointer rule (≤2 KB)
- `~/.claude/state/global-forensics-status.md` — locked contract + rollout status
- Port `9876` — registered in `~/.claude/rules/projects/registry.md`
