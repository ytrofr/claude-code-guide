---
layout: default
title: "Claude Code Hooks"
parent: "Part III — Extension"
nav_order: 1
redirect_from:
  - /docs/guide/13-claude-code-hooks.html
  - /docs/guide/13-claude-code-hooks/
  - /docs/guide/14-git-vs-claude-hooks-distinction.html
  - /docs/guide/14-git-vs-claude-hooks-distinction/
---

# Claude Code Hooks

**Part III — Extension · Chapter 1**

Hooks are how you extend Claude Code. They are scripts that run automatically when specific events fire during a session — before a tool runs, after a file is written, when a subagent starts, when the session ends, and so on. With hooks you can enforce policy, format code, inject context, log activity, or block dangerous operations — without asking Claude to remember to do it.

This chapter covers **how to author hooks**. For the complete catalog of all 27 hook events and their payload schemas, see [Part VI / 03 — Hook Event Catalog](../part6-reference/03-hook-event-catalog.md).

---

## 1. Hooks vs Git Hooks

Claude Code hooks and git hooks are two separate systems. They do not interact. Confusing them is the most common first-day mistake.

| Aspect            | Git Hooks                          | Claude Code Hooks                    |
| ----------------- | ---------------------------------- | ------------------------------------ |
| Location          | `.git/hooks/` or `.husky/`         | `.claude/settings.json`              |
| Trigger           | Git operations (commit, push)      | Claude Code events (tool use, etc.)  |
| Language          | Any executable                     | Shell command or script              |
| Purpose           | Code-quality gates                 | AI-workflow automation               |
| Runs when         | Developer runs `git commit`        | Claude performs actions in a session |
| Can block what    | A commit or push                   | A tool call or config change         |
| Bypass flag       | `git commit --no-verify`           | None — governed by config + trust    |

Use both together. A typical project keeps lint/format/tests in git hooks (enforced at commit time) and keeps skill injection, pre-edit validation, and auto-formatting in Claude Code hooks (enforced at tool-use time). Each layer reinforces the other.

| Scenario                                           | Use                         |
| -------------------------------------------------- | --------------------------- |
| Lint code before committing                        | Git hook (pre-commit)       |
| Run tests before pushing                           | Git hook (pre-push)         |
| Validate commit message format                     | Git hook (commit-msg)       |
| Auto-format files after Claude edits them          | Claude hook (PostToolUse)   |
| Block Claude from writing to certain directories   | Claude hook (PreToolUse)    |
| Load branch-specific context at session start      | Claude hook (SessionStart)  |
| Inject skill suggestions based on query            | Claude hook (UserPromptSubmit) |

The rest of this chapter is only about Claude Code hooks.

---

## 2. The Seven Phases of a Session

All 27 hook events fall into seven phases. You rarely need more than a handful at once — the table below is the at-a-glance version so you know where to plug in.

| Phase             | Representative events                                   | Typical use                                 |
| ----------------- | ------------------------------------------------------- | ------------------------------------------- |
| Session lifecycle | `SessionStart`, `SessionEnd`, `Stop`                    | Inject context at start, save summaries at end |
| User input        | `UserPromptSubmit`                                      | Skill matching, preprocessing               |
| Tool lifecycle    | `PreToolUse`, `PostToolUse`, `PostToolUseFailure`       | Validation, formatting, logging             |
| Permissions       | `PermissionRequest`, `PermissionDenied`                 | Auto-approve safe commands, observability   |
| Agents            | `SubagentStart`, `SubagentStop`, `TeammateIdle`, `TaskCompleted` | Monitor and route agent work        |
| Context           | `PreCompact`, `PostCompact`, `InstructionsLoaded`       | Back up transcripts, track active rules     |
| Infrastructure    | `Setup`, `ConfigChange`, `CwdChanged`, `FileChanged`, `WorktreeCreate`, `WorktreeRemove`, `Notification`, `Elicitation`, `ElicitationResult`, `TaskCreated`, `StopFailure` | Init, VCS setup, cleanup |

Full schemas, matchers, and payload examples for every event live in the [Hook Event Catalog](../part6-reference/03-hook-event-catalog.md). The rest of this chapter uses a few representative events to teach the authoring patterns that apply to all of them.

---

## 3. Anatomy of a Hook

Every hook is a small piece of config in `settings.json` pointing at a runnable command. Claude Code invokes the command when the event fires, pipes structured JSON to it on stdin, and inspects the exit code plus any stdout output.

### 3.1 The config block

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/prettier-format.sh",
            "statusMessage": "Formatting file..."
          }
        ]
      }
    ]
  }
}
```

- `matcher` — narrows which tool calls the handler runs for (e.g. `Write|Edit`, or a specific MCP tool name).
- `type` — one of `command`, `prompt`, or `agent` (see §3.4).
- `command` — the shell command; prefer `$CLAUDE_PROJECT_DIR/...` absolute paths.
- `statusMessage` — shown in the UI while the hook runs.

### 3.2 stdin JSON is canonical (legacy env vars are dead)

Claude Code passes event data as JSON on **stdin only**. The old `$CLAUDE_HOOK_INPUT`, `$CLAUDE_HOOK_EVENT`, `$CLAUDE_TOOL_INPUT`, `$CLAUDE_TOOL_NAME` variables no longer exist — they are always empty. Any hook that reads them silently runs with no data, never enforces what it was meant to enforce, and often produces "hook error" noise in the UI.

```bash
#!/bin/bash
# Canonical pattern: read stdin with timeout fallback, extract with jq
INPUT=$(timeout 2 cat 2>/dev/null || true)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // empty' 2>/dev/null)
```

The only environment variables Claude Code sets for hooks are:

| Variable              | Value                                        | Available in                          |
| --------------------- | -------------------------------------------- | ------------------------------------- |
| `$CLAUDE_PROJECT_DIR` | Absolute path to the project root            | All hooks                             |
| `$CLAUDE_CODE_REMOTE` | `"true"` in web sessions; unset in the CLI   | All hooks                             |
| `$CLAUDE_ENV_FILE`    | Writable env-file path                       | `SessionStart`, `CwdChanged`, `FileChanged` |

### 3.3 Exit codes

- `0` — success, non-blocking.
- `2` — block (interpreted per event — see the table below).
- Anything else — treated as an error.

The effect of exit code 2 depends on the event:

| Event               | Exit 2 effect                                   |
| ------------------- | ----------------------------------------------- |
| `PreToolUse`        | Blocks the tool call                            |
| `UserPromptSubmit`  | Blocks the prompt from being processed          |
| `ConfigChange`      | Blocks the config change (except policy)        |
| `WorktreeCreate`    | Fails worktree creation                         |
| `TeammateIdle`      | Pauses the idle teammate                        |
| `TaskCompleted`     | Can reassign the completed task                 |
| `PostToolUse`, `PostToolUseFailure`, `Stop`, `SessionEnd`, `Notification`, `SubagentStart`, `SubagentStop`, `Setup`, `WorktreeRemove`, `InstructionsLoaded` | Ignored |
| `PreCompact`        | Blocks the compaction (since CC 2.1.105)         |

Rule of thumb: exit 2 only blocks on "Pre" events. Everything else is observational.

### 3.4 Three hook types

Every hook entry has a `type`. Most of the time, pick `command`.

| Aspect        | `command`          | `prompt`              | `agent`                    |
| ------------- | ------------------ | --------------------- | -------------------------- |
| Execution     | Shell script       | Single LLM turn       | Multi-turn LLM with tools  |
| Latency       | Milliseconds       | 1–3 seconds           | 5–30+ seconds              |
| Cost          | Free (local)       | 1 LLM call            | Multiple LLM calls         |
| Tool access   | External commands  | None                  | Full Claude tools          |
| Best for      | Automation, policy | Quick safety checks   | Deep code review           |

`prompt` and `agent` let an LLM decide allow/deny based on the event context. They are expensive. Use `command` for anything that can be expressed as pattern-matching or deterministic logic.

---

## 4. Your First Hook — A Walkthrough

Build a PostToolUse hook that auto-formats any file Claude writes.

**Step 1.** Create the script at `.claude/hooks/prettier-format.sh`:

```bash
#!/bin/bash
exec 2>/dev/null   # Prevent stderr leakage from subcommands

INPUT=$(timeout 2 cat 2>/dev/null || true)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
  case "$FILE_PATH" in
    *.js|*.ts|*.json|*.css|*.html|*.md|*.yaml)
      timeout 10 npx prettier --write "$FILE_PATH" 2>/dev/null || true
      ;;
  esac
fi
exit 0
```

**Step 2.** Make it executable:

```bash
chmod +x .claude/hooks/prettier-format.sh
```

**Step 3.** Register it in `.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/prettier-format.sh",
            "statusMessage": "Formatting..."
          }
        ]
      }
    ]
  }
}
```

**Step 4.** Test it locally:

```bash
# Simulate a PostToolUse event
echo '{"tool_name":"Write","tool_input":{"file_path":"/tmp/test.js","content":"const x=1"}}' \
  | bash .claude/hooks/prettier-format.sh
echo "Exit: $?"
```

Next time Claude edits a JS file, Prettier will run automatically. No prompts, no forgetting.

---

## 5. Matchers

Matchers filter which events a handler runs for. They are most common on `PreToolUse` / `PostToolUse`, but any event that carries context-specific data (config type, agent type, MCP tool name) accepts them.

### 5.1 Built-in tool names

```json
{ "matcher": "Write|Edit" }           // Write or Edit
{ "matcher": "Bash" }                 // Bash only
{ "matcher": "Read|Glob|Grep" }       // Read-side tools
```

### 5.2 MCP tool names

MCP tools are named `mcp__<server>__<tool>`. Match them the same way:

```json
{
  "PreToolUse": [
    {
      "matcher": "mcp__postgres__query",
      "hooks": [
        { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/validate-sql.sh" }
      ]
    }
  ]
}
```

You can pipe multiple MCP tool names together: `"mcp__perplexity__search|mcp__perplexity__perplexity_ask"`. Different MCP packages sometimes expose the same capability under different names — run `/context` in each project to see the actual tool identifiers.

### 5.3 ConfigChange matchers

`ConfigChange` uses a matcher against the config type:

```json
{ "matcher": "user_settings|project_settings|local_settings" }
```

---

## 6. Output Formats

Most hooks just exit 0. Some need to return structured JSON on stdout to influence Claude.

### 6.1 PreToolUse decisions

```json
{
  "hookSpecificOutput": {
    "decision": "deny",
    "reason": "Cannot write files to project root. Use src/ instead."
  }
}
```

Valid decisions: `"allow"`, `"deny"`, `"ask_user"`.

### 6.2 PreToolUse additionalContext (inject guidance without blocking)

```json
{
  "additionalContext": "Remember: this project uses tabs, not spaces. New files need the copyright header."
}
```

Claude sees the context alongside the tool result. No block.

### 6.3 PermissionRequest

```bash
# Correct nested structure with decision.behavior
echo '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow"}}}'
```

`"approve"` is not a valid value — use `"allow"` or `"deny"`. And yes, the nesting is weird; don't flatten it.

### 6.4 Stop/SubagentStop/TeammateIdle/TaskCompleted continue:false

Return `{"continue": false, "stopReason": "..."}` to stop the agent entirely (CC 2.1.69+).

### 6.5 Other events

Events that support blocking and aren't `PreToolUse` use a top-level `decision` field:

```json
{ "decision": "block", "reason": "Reason shown to the user" }
```

---

## 7. Settings Integration

### 7.1 Scope hierarchy (six locations)

Hooks load from up to six scopes. They **merge** — later scopes add to earlier ones, they don't replace them.

| Priority | Location                      | Scope                      |
| -------- | ----------------------------- | -------------------------- |
| 1        | `~/.claude/settings.json`     | User (all projects)        |
| 2        | `.claude/settings.json`       | Project (committed)        |
| 3        | `.claude/settings.local.json` | Local (not committed)      |
| 4        | Managed policy                | Enterprise (admin-managed) |
| 5        | Plugin hooks                  | Installed plugins          |
| 6        | Skill/agent frontmatter       | YAML `hooks:` field        |

If the same event has handlers at multiple scopes, **all of them run**. This means a user-level `SessionStart` hook and a project-level `SessionStart` hook both fire every session.

### 7.2 Deduplication across scopes

Claude Code deduplicates **identical commands** across scopes — if you define exactly the same `command` string at user and project scope, it fires once. But different commands on the same event do **not** replace each other — they both fire. The practical rule: keep universal guards (security, cost control, observability) at user scope and keep project-specific logic (sacred patterns, formatters, file-size rules) at project scope. Never mirror the same handler between them.

### 7.3 Skill/agent frontmatter hooks

Hooks can live inside a skill or agent's YAML frontmatter, scoped to that component's lifecycle:

```yaml
---
name: my-deployment-skill
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: "command"
          command: "$CLAUDE_PROJECT_DIR/.claude/hooks/block-production-commands.sh"
      once: true   # Only runs once per session, not on every match
---
```

These fire only while the skill/agent is active. `once: true` limits execution to the first match per session.

### 7.4 Settings resilience (CC 2.1.99)

Before 2.1.99, a typo in **one** hook event name would cause the **entire** `settings.json` file to be silently ignored — all other hooks, permissions, and settings stopped working with no error message. Since 2.1.99, only the bad entry is skipped; the rest of the file still loads. After upgrading, re-audit your hooks: some you thought were running may have been dead for months, and will start firing for the first time.

### 7.5 `permissions.deny` beats PreToolUse "ask" (CC 2.1.99)

If a command matches a `permissions.deny` rule, no PreToolUse hook can downgrade it to a user prompt. Deny wins, always. Previously a well-meaning hook returning `permissionDecision: "ask"` could weaken an unconditional deny — that vector is now closed.

---

## 8. Common Patterns

### 8.1 SessionStart context loader

```json
{
  "SessionStart": [
    {
      "hooks": [
        { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/session-start.sh" }
      ]
    }
  ]
}
```

Typical payload: current branch, git status summary, last session's focus, active skills index. Writes to stdout; Claude reads it as context for the session.

### 8.2 PostToolUse auto-formatter

See §4. PostToolUse on `Write|Edit` is the canonical auto-format hook.

### 8.3 PreToolUse policy gate

Block writes to the project root directory:

```bash
#!/bin/bash
exec 2>/dev/null
INPUT=$(timeout 2 cat 2>/dev/null || true)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
DIR=$(dirname "$FILE_PATH")

if [ "$DIR" = "$PROJECT_ROOT" ]; then
  cat <<EOF
{"hookSpecificOutput":{"decision":"deny","reason":"Do not write to project root. Use src/ or docs/."}}
EOF
fi
exit 0
```

### 8.4 Cross-tool cost gate (two-hook sandwich)

Paid MCP calls (Perplexity, external APIs) are good candidates for a **PreToolUse = gate, PostToolUse = capture** sandwich. PreToolUse injects a "check cache first" reminder; PostToolUse reminds to cache the result. See Part IV / 03 — Basic Memory MCP for the cache-first pattern.

### 8.5 PreCompact backup (CC 2.1.105)

Since CC 2.1.105, a `PreCompact` hook can block compaction with exit 2 or `{"decision":"block"}`. Useful for backing up the transcript before compaction destroys detail.

### 8.6 PermissionDenied logger (CC 2.1.89)

Introduced in CC 2.1.89, `PermissionDenied` fires when auto-mode's classifier denies a command. Log denials to understand which commands Claude keeps trying that you haven't allowlisted.

### 8.7 Async background hooks

Any hook can run in the background with `"async": true`. The hook cannot influence Claude — it's fire-and-forget. Ideal for logging, analytics, Slack/Discord notifications.

```json
{
  "SubagentStart": [
    {
      "hooks": [
        { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/subagent-monitor.sh", "async": true }
      ]
    }
  ]
}
```

Use `async` for monitoring; keep synchronous for validation and blocking.

---

## 9. Gotchas

### 9.1 stdin must have a timeout

If the stdin pipe doesn't close promptly (rare, but happens under heavy load), `$(cat)` blocks forever and Claude Code appears stuck. Always:

```bash
INPUT=$(timeout 2 cat 2>/dev/null || true)
```

A cascade of hook errors on `Edit` (or similar) after one bad hook hangs is a classic signature — fix the root cause, the cascade disappears.

### 9.2 Suppress stderr globally

Claude Code treats **any** stderr output as a hook error, even when the exit code is 0. Individual `2>/dev/null` on each command is fragile — a subshell or signal handler can still leak. Add this as the first line after the shebang:

```bash
#!/bin/bash
exec 2>/dev/null   # Global stderr suppression
```

### 9.3 Use `$CLAUDE_PROJECT_DIR`, never hardcode

A hardcoded `/home/you/my-project` path silently fails the moment the repo moves or someone else clones it. Use the portable form:

```bash
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
LOG_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/logs/my-hook.log"
```

### 9.4 Absolute paths in `settings.json` commands

Relative paths like `.claude/hooks/x.sh` are resolved from the session's working directory. If a session starts in a subdirectory (monorepo, package workspace), the resolution fails and every tool call shows a "hook error" (exit 127). Always:

```json
{ "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/my-hook.sh" }
```

### 9.5 Inline hooks in `settings.json` still need stdin

Inline command strings are hooks too. They must `cat` stdin, not read `$CLAUDE_HOOK_INPUT`:

```json
{
  "command": "INPUT=$(cat); echo \"$(echo \"$INPUT\" | jq -r '.file_path')\" >> ~/.claude/logs/loaded.log"
}
```

### 9.6 Always exit 0 unless you mean to block

Non-blocking hooks that exit non-zero produce error banners and disrupt the workflow. A safe pattern:

```bash
#!/bin/bash
trap 'exit 0' ERR
set -euo pipefail
# ... hook logic ...
exit 0
```

### 9.7 Don't duplicate hooks across scopes

Hooks merge, they don't override. A universal observation logger at user scope **plus** the same logger at project scope runs twice — you get double entries, double statusMessages, double latency. Pick one scope per concern.

### 9.8 File-scoped checks: use `command`, not `prompt`

`type: "prompt"` delegates every matched event to an LLM. Even with a clear "only check files in src/" instruction, LLMs don't reliably respect file-scoping — they block edits to markdown or config files you never meant to gate. For path-based filtering, use `command` with a shell `case` statement. Reserve `prompt` for content-quality checks where LLM judgment is the point.

---

## 10. Debugging Hooks

**Test with mock input.** Pipe a representative JSON payload to the script and check the exit code:

```bash
echo '{"tool_name":"Write","tool_input":{"file_path":"/tmp/x.js"}}' | bash .claude/hooks/my-hook.sh
echo "Exit: $?"
```

**Check for hung stdin.** If the UI ever feels stuck, simulate a pipe that never closes:

```bash
mkfifo /tmp/test-fifo; (sleep 100 > /tmp/test-fifo) &
time bash .claude/hooks/my-hook.sh < /tmp/test-fifo   # Should finish in ~2s, not hang
kill %1; rm /tmp/test-fifo
```

**Find silent dead hooks.** When a handler has **never** fired, check the three usual suspects: (1) a typo in the event name (pre-2.1.99 killed the whole file, 2.1.99+ only skips the bad entry), (2) a relative `command` path that didn't resolve from the session's cwd, (3) use of the dead `$CLAUDE_HOOK_INPUT` / `$CLAUDE_TOOL_INPUT` / `$CLAUDE_HOOK_EVENT` variables — all empty, so matchers and body logic run against nothing.

**Log everything during authoring.** Route observability to `${CLAUDE_PROJECT_DIR:-.}/.claude/logs/`. A one-line append-only log per hook makes "is it even running?" answerable instantly.

**CC 2.1.105 stalled-stream abort.** If a hook appears to finish but the session hangs, the 5-minute stalled-stream abort means something downstream is stuck. Inspect subprocesses your hook spawned and `timeout`-wrap every external call.

---

## 11. See Also

- [Part VI / 03 — Hook Event Catalog](../part6-reference/03-hook-event-catalog.md) — Complete reference for all 27 events, payload schemas, matcher syntax.
- [Part VI / 01 — CC Version History](../part6-reference/01-cc-version-history.md) — When each hook event was introduced, and version-specific behavior changes.
- [Part II — Setup](../part2-setup/index.md) — Where `settings.json` lives, scope hierarchy, settings precedence.
- [Part IV / 03 — Basic Memory MCP](../part4-knowledge/03-basic-memory-mcp.md) — Cache-first pattern used in the §8.4 cost-gate example.
- [Part III / 02 — MCP Integration](02-mcp-integration.md) — Matching MCP tools in hooks, the `mcp__<server>__<tool>` naming pattern.

---

**Previous**: [Part III Index](index.md) · **Next**: [Part III / 02 — MCP Integration](02-mcp-integration.md)
