---
layout: default
title: "Hook Event Catalog"
parent: "Part VI — Reference"
nav_order: 3
---

# Hook Event Catalog

Reference for the 27 hook events in **CC 2.1.111**, grouped by lifecycle phase. Every hook receives JSON on stdin; the legacy env vars `$CLAUDE_HOOK_INPUT`, `$CLAUDE_HOOK_EVENT`, and `$CLAUDE_TOOL_INPUT` are dead and always empty. Use `$CLAUDE_PROJECT_DIR` for portable paths.

Hooks from all scopes (global, project, local) run in **parallel** — they don't override one another. Identical commands are deduplicated; different commands for the same event all fire.

---

## stdin pattern

Every hook reads a single JSON object on stdin. The canonical safe pattern:

```bash
#!/bin/bash
# Read stdin safely — timeout prevents hang, fallback prevents crash
INPUT=$(timeout 2 cat 2>/dev/null || true)

# Extract fields with jq (always use default // empty)
EVENT=$(echo "$INPUT"  | jq -r '.hook_event_name // empty' 2>/dev/null)
TOOL=$(echo "$INPUT"   | jq -r '.tool_name // empty'       2>/dev/null)
FILE=$(echo "$INPUT"   | jq -r '.tool_input.file_path // empty' 2>/dev/null)

# Portable paths — never hard-code your home dir
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
LOG="${CLAUDE_PROJECT_DIR:-.}/.claude/logs/events.log"

echo "[${EVENT}] tool=${TOOL} file=${FILE}" >> "$LOG"
```

Inline hooks configured in `settings.json` follow the same pattern:

```json
{
  "command": "INPUT=$(cat); echo \"[${(echo \"$INPUT\" | jq -r '.hook_event_name')}]\" >> $CLAUDE_PROJECT_DIR/.claude/logs/events.log"
}
```

### Available env vars

| Variable | Value | Available in |
|----------|-------|-------------|
| `CLAUDE_PROJECT_DIR` | Absolute path to project root | All hooks |
| `CLAUDE_ENV_FILE` | Writable env file path (export lines get sourced by CC) | `SessionStart`, `CwdChanged`, `FileChanged` |

### Dead env vars (never use)

| Dead variable | Use instead |
|---------------|-------------|
| `$CLAUDE_HOOK_INPUT` | `INPUT=$(cat)` then `echo "$INPUT" \| jq` |
| `$CLAUDE_HOOK_EVENT` | `jq -r '.hook_event_name'` from stdin |
| `$CLAUDE_TOOL_INPUT` | `jq -r '.tool_input'` from stdin |
| `$CLAUDE_TOOL_INPUT_FILE_PATH` | `jq -r '.tool_input.file_path'` from stdin |
| `$CLAUDE_TOOL_NAME` | `jq -r '.tool_name'` from stdin |

---

## Output channels — stdout vs stderr

PreToolUse hooks that block (`exit 2`) **must** write the user-visible reason to **stderr** (`>&2`). CC reads stderr and shows it to the model as the block reason. Stdout is reserved for hook JSON protocol output (e.g. `hookSpecificOutput`). A hook that exits 2 with its block message on stdout produces "No stderr output" in the model's view — the model sees that it was blocked but cannot see why, and cannot self-recover.

```bash
# WRONG — block message invisible to the model
echo "BLOCKED: <reason>"
exit 2

# CORRECT — message reaches the model via stderr
echo "BLOCKED: <reason>" >&2
exit 2

# Multi-line block — wrap in { ... } >&2 once
{
  echo "==="
  echo "BLOCK REASON:"
  echo "  - $missing_thing"
  echo "==="
} >&2
exit 2
```

Internal pipe-stages (`echo "$X" | grep ...`) stay on stdout — those are inputs to other commands, not user-facing.

### Exit code semantics

| Exit | Meaning |
|------|---------|
| `0`  | Pass — tool proceeds; stderr is informational only |
| `2`  | Block — stderr is shown to the model as the block reason; stdout is ignored |
| Other | Treated as hook failure; behavior depends on event and CC version |

### `tool_input` is authoritative — never `ls -t` disk state

For PreToolUse hooks, the canonical source for "which tool call is happening" is `.tool_input.*` in the stdin envelope. Reading file state via `ls -t` / `find -newer` is racy under parallel sessions — two sessions writing to the same directory concurrently can swap which file your hook validates. Read directly from stdin:

```bash
# ExitPlanMode envelope carries both: .tool_input.plan (markdown) AND .tool_input.planFilePath (path)
PLAN_PATH=$(echo "$INPUT" | jq -r '.tool_input.planFilePath // empty')
if [ -n "$PLAN_PATH" ] && [ -f "$PLAN_PATH" ]; then
    validate "$PLAN_PATH"
else
    # Defensive fallback only if stdin is unavailable / malformed
    validate "$(ls -t "$DIR"/*.md | head -1)"
fi
```

When trusting a path from stdin, validate it falls inside an expected scope (`case "$path" in "$EXPECTED"/*) ... ;; esac`) before reading.

### Authoring checklist

Before shipping a `PreToolUse` hook that can `exit 2`:

- [ ] Block message uses `>&2`, not bare `echo`
- [ ] `tool_input.*` consumed from stdin, not derived from disk state
- [ ] Path inputs from stdin are scope-validated before use
- [ ] Hook has a self-test mode (`--selftest`) or unit fixtures
- [ ] Bypass / override mechanism documented for emergencies

---

## Events by phase

### Startup

#### `SessionStart`

- **Trigger**: CC session begins (fresh launch, `--continue`, `--resume`).
- **Payload fields**: `hook_event_name`, `session_id`, `cwd`, `workspace.git_worktree` (2.1.97+), `source` (e.g. `startup`, `resume`).
- **Typical use**: load project state, prime memory, set env vars for the session.
- **Env writable**: yes — write `export KEY=value` lines to `$CLAUDE_ENV_FILE`.
- **Can block**: no.

#### `InstructionsLoaded`

- **Trigger**: CLAUDE.md hierarchy resolves (session start, nested directory traversal, explicit include, post-compact).
- **Matchers**: `session_start`, `nested_traversal`, `path_glob_match`, `include`, `compact`.
- **Payload fields**: `hook_event_name`, `session_id`, `matcher`, `files` (array of loaded CLAUDE.md paths).
- **Typical use**: audit which rule files loaded; observability only (cannot block).
- **Can block**: no.

#### `CwdChanged`

- **Trigger**: current working directory changes mid-session.
- **Payload fields**: `hook_event_name`, `session_id`, `old_cwd`, `new_cwd`.
- **Typical use**: reload project-scoped env, switch active venv, re-prime context.
- **Env writable**: yes (via `$CLAUDE_ENV_FILE`).
- **Can block**: no.

### Prompt

#### `UserPromptSubmit`

- **Trigger**: user submits a prompt.
- **Payload fields**: `hook_event_name`, `session_id`, `prompt` (the text), `cwd`.
- **Typical use**: prompt length logging, profanity/secrets redaction, forced slash-command routing.
- **Can block**: yes — return `{"decision":"block","reason":"..."}` to cancel the submission.

#### `PostCompact`

- **Trigger**: after auto-compaction completes.
- **Payload fields**: `hook_event_name`, `session_id`, `trigger` (`manual` or `auto`), `summary_length`.
- **Typical use**: remind Claude to re-read critical files (project-root CLAUDE.md is auto-reinjected; nested CLAUDE.md reloads lazily). Smart reload: display the N most recently read files.
- **Can block**: no.

### Tool use

Tool-use hooks support **matchers** scoped to tool name. Matcher syntax mirrors permission rules — e.g. `"Bash(git *)"`, `"Write|Edit"`, or `"*"` for all tools.

#### `PreToolUse`

- **Trigger**: before any tool call executes.
- **Payload fields**: `hook_event_name`, `session_id`, `tool_name`, `tool_input` (object), `cwd`.
- **Typical use**: validate args, redact secrets, enforce deny-patterns, rate-limit destructive commands.
- **Can block**: yes — return `{"decision":"block","reason":"..."}` to prevent the call, or `{"decision":"defer"}` in headless `-p` to pause for `--resume` (2.1.89).
- **Permission precedence**: `permissions.deny` in settings overrides any PreToolUse "ask" (2.1.99).

#### `PostToolUse`

- **Trigger**: after a tool call finishes, success or failure.
- **Payload fields**: `hook_event_name`, `session_id`, `tool_name`, `tool_input`, `tool_response` (string or structured), `cwd`.
- **Typical use**: lint after `Edit|Write`, format, emit metrics, tail-log results.
- **Can block**: no (the call already happened), but can emit warnings back to Claude via stderr.

Classic formatting hook (single matcher on Write/Edit):

```json
{
  "matcher": "Write|Edit",
  "hooks": [
    {
      "type": "command",
      "command": "FILE=$(cat | jq -r '.tool_input.file_path // empty'); [ -n \"$FILE\" ] && npx prettier --write \"$FILE\" 2>/dev/null || true"
    }
  ]
}
```

#### `PermissionRequest`

- **Trigger**: a tool call needs permission (user prompt would otherwise appear).
- **Payload fields**: `hook_event_name`, `session_id`, `tool_name`, `tool_input`, `cwd`.
- **Typical use**: auto-approve safe read-only calls; auto-deny known-bad patterns.
- **Can block**: yes.
- **Output format** (critical — wrong shape fails silently):

```bash
# CORRECT
echo '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow"}}}'

# WRONG — "approve" is not a valid behavior
echo '{"decision": "approve"}'
```

Valid `behavior` values: `allow`, `deny`, `ask`.

#### `PermissionDenied`

- **Trigger**: fires after the user (or an auto-mode classifier) denies a permission.
- **Payload fields**: `hook_event_name`, `session_id`, `tool_name`, `tool_input`, `reason`.
- **Typical use**: log denials for auditing; return `{"retry": true}` to retry once (2.1.89).
- **Can block**: no; can request retry.

#### `FileChanged`

- **Trigger**: a file in the project tree changes externally (editor save, git operation, etc.).
- **Payload fields**: `hook_event_name`, `session_id`, `file_path`, `change_type` (`created`, `modified`, `deleted`).
- **Typical use**: invalidate caches, re-index search, re-run type-check.
- **Env writable**: yes (via `$CLAUDE_ENV_FILE`).
- **Can block**: no.

### Subagent

#### `SubagentStart`

- **Trigger**: `Agent()` / `Task()` dispatched.
- **Matcher**: agent type (`Explore`, `Plan`, `general-purpose`, named subagent, etc.).
- **Payload fields**: `hook_event_name`, `session_id`, `agent_id` (stable key), `agent_type`, `prompt_length`, `cwd`.
- **Typical use**: log dispatch, enforce concurrency caps, record start timestamp.
- **Can block**: no.

#### `SubagentStop`

- **Trigger**: subagent finishes (success, error, or cancellation).
- **Payload fields**: `hook_event_name`, `session_id`, `agent_id`, `agent_type`, `duration_ms`, `last_assistant_message` (privacy-sensitive — redact before logging).
- **Typical use**: record duration, emit metrics, detect failing subagents.
- **Can block**: no.

#### `TeammateIdle`

- **Trigger**: a teammate agent (channels feature) becomes idle.
- **Payload fields**: `hook_event_name`, `session_id`, `teammate_id`, `idle_ms`.
- **Typical use**: nudge user via push notification or `SendUserMessage`.
- **Can block**: yes — can stop the teammate.

### Task lifecycle

#### `TaskCreated`

- **Trigger**: a task is created via `TaskCreate` (e.g. user or Claude tracks work).
- **Payload fields**: `hook_event_name`, `session_id`, `task_id`, `subject`, `status`.
- **Typical use**: mirror tasks into external tracker (Jira, Linear).
- **Can block**: yes.

#### `TaskCompleted`

- **Trigger**: a task's status transitions to `completed` (or `cancelled`, per tracker).
- **Payload fields**: `hook_event_name`, `session_id`, `task_id`, `subject`, `completed_at`.
- **Typical use**: push completion to external system; can stop a teammate blocked on this task.
- **Can block**: yes.

### Worktree

#### `WorktreeCreate`

- **Trigger**: a new git worktree is created (e.g. via `-w, --worktree`).
- **Payload fields**: `hook_event_name`, `session_id`, `worktree_path`, `worktree_name`, `branch`.
- **Typical use**: run `npm install`, symlink shared caches, warm the new worktree.
- **Can block**: no.

#### `WorktreeRemove`

- **Trigger**: a worktree is destroyed (stale cleanup or explicit removal).
- **Payload fields**: `hook_event_name`, `session_id`, `worktree_path`, `worktree_name`.
- **Typical use**: clean shared caches, archive logs.
- **Can block**: no.

#### `EnterWorktree`

- **Trigger**: session enters a worktree. Accepts a path parameter since 2.1.105.
- **Payload fields**: `hook_event_name`, `session_id`, `worktree_path`.
- **Typical use**: swap to worktree-scoped env, reload settings.
- **Can block**: no.

#### `ExitWorktree`

- **Trigger**: session leaves a worktree and returns to the parent repo.
- **Payload fields**: `hook_event_name`, `session_id`, `worktree_path`.
- **Typical use**: restore parent-repo env, flush worktree metrics.
- **Can block**: no.

### Compaction

#### `PreCompact`

- **Trigger**: before compaction begins.
- **Payload fields**: `hook_event_name`, `session_id`, `trigger` (`manual` or `auto`), `context_usage_pct`.
- **Typical use**: checkpoint transcript, commit WIP, veto compaction if mid-critical-operation.
- **Can block**: **yes** since 2.1.105 — `exit 2` or `{"decision":"block"}` cancels compaction.

### MCP elicitation

#### `Elicitation`

- **Trigger**: an MCP server requests structured input from the user.
- **Matcher**: MCP server name.
- **Payload fields**: `hook_event_name`, `session_id`, `server_name`, `prompt`, `schema`.
- **Typical use**: auto-fill known answers, log prompts, enforce policy.
- **Can block**: yes.

#### `ElicitationResult`

- **Trigger**: user responds to an MCP elicitation.
- **Matcher**: MCP server name.
- **Payload fields**: `hook_event_name`, `session_id`, `server_name`, `result` (structured per schema).
- **Typical use**: audit, enrichment, sync to external system.
- **Can block**: no.

### Stop and session end

#### `Stop`

- **Trigger**: Claude finishes its current response. Fires after **every** turn — not once per session.
- **Payload fields**: `hook_event_name`, `session_id`, `stop_reason`, `turn_count`.
- **Typical use**: emit per-turn metrics, auto-run verification after certain turns.
- **Can block**: yes (can keep the model thinking).

#### `SessionEnd`

- **Trigger**: session terminates. Fires once.
- **Matchers**: `clear`, `resume`, `logout`, `prompt_input_exit`, `other`.
- **Payload fields**: `hook_event_name`, `session_id`, `matcher`, `duration_ms`, `total_turns`.
- **Typical use**: flush metrics, archive transcript, emit session summary.
- **Can block**: no. Default timeout 3000ms; extend with `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS=5000`.

---

## Hook configuration in `settings.json`

Hooks are declared per event, with an optional `matcher` and one or more `command` entries. Blocks run in parallel.

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash $CLAUDE_PROJECT_DIR/.claude/hooks/session-start.sh"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash(rm -rf *)",
        "hooks": [
          {
            "type": "command",
            "command": "echo '{\"decision\":\"block\",\"reason\":\"rm -rf blocked by policy\"}'"
          }
        ]
      },
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash $CLAUDE_PROJECT_DIR/.claude/hooks/protect-secrets.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "FILE=$(cat | jq -r '.tool_input.file_path // empty'); [ -n \"$FILE\" ] && npx prettier --write \"$FILE\" 2>/dev/null || true"
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash $CLAUDE_PROJECT_DIR/.claude/hooks/session-summary.sh"
          }
        ]
      }
    ]
  }
}
```

---

## Common gotchas

- **stdin-JSON only**: legacy env vars are dead. Parse stdin with `jq`. Fall back with `// empty` so missing fields don't crash.
- **Portable paths**: use `${CLAUDE_PROJECT_DIR:-$PWD}`; never hard-code your home directory. Hooks may run from any cwd.
- **Deduplication**: identical commands across scopes (global + project + local) are deduped. Different commands for the same event all fire — avoid accidental duplication.
- **Inline hooks still need stdin**: a one-liner `"command"` in `settings.json` must still read stdin via `$(cat)`. Putting data in the command string doesn't work.
- **`PermissionRequest` output format**: the response MUST be `{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow"}}}`. Wrong shape (e.g. `{"decision":"approve"}`) fails silently — the prompt still appears.
- **`permissions.deny` beats PreToolUse "ask"** (2.1.99): explicit denies in settings take precedence.
- **Output cap**: hook output over 50K chars is saved to disk with a file path + preview (2.1.89). Don't stream logs through stdout.
- **CC 2.1.99 settings resilience**: unrecognized event names no longer nuke the whole `hooks` block — only the unknown entry is ignored. Before 2.1.99, a typo disabled all hooks.
- **Subagent inheritance** (2.1.99): subagents now inherit parent MCP config and can Read/Edit worktree paths.
- **Timeout by event**: `SessionEnd` has a 3000ms budget by default (extend via `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS`). Other events default to longer budgets; keep hooks fast.

---

## See also

- `part3-extension/01-hooks.md` — hooks authoring tutorial (deep dive, step-by-step)
- `part6-reference/02-cli-flags-and-env.md` — CLI flags and env vars, including hook-side env
- `part6-reference/06-security-checklist.md` — hook-injection risks and safe patterns
- `part6-reference/01-cc-version-history.md` — when each event/matcher became available
