---
layout: default
title: "CLI Flags and Environment Variables"
parent: "Part VI — Reference"
nav_order: 2
---

# CLI Flags and Environment Variables

Authoritative reference for Claude Code CLI invocation and runtime environment, current as of **CC 2.1.111**. The canonical source is `claude --help` — this page mirrors its output with added context. When in doubt, verify against the CLI.

```bash
claude --version            # 2.1.111 (Claude Code)
claude --help | head -50    # flag catalog
claude mcp --help           # MCP subcommand catalog
claude plugin --help        # plugin subcommand catalog
```

---

## Invocation flags

### Session mode

| Flag | What it does | Example |
|------|--------------|---------|
| `-p, --print` | Print response and exit (headless). Skips workspace trust dialog — only use in trusted dirs. | `claude -p "summarize README"` |
| `-c, --continue` | Continue the most recent conversation in the current directory. | `claude -c` |
| `-r, --resume [value]` | Resume by session ID or open interactive picker (optional search term). | `claude --resume myfeature` |
| `--from-pr [value]` | Resume a session linked to a PR by number/URL, or open picker. | `claude --from-pr 123` |
| `--fork-session` | On resume, create a new session ID instead of reusing the original. | `claude --continue --fork-session` |
| `--session-id <uuid>` | Use a specific session ID (must be a valid UUID). | `claude --session-id $(uuidgen)` |
| `-n, --name <name>` | Display name for the session (shown in `/resume` and terminal title). | `claude -n feat/auth` |
| `--no-session-persistence` | Don't save session to disk — cannot be resumed. `-p` only. | `claude -p --no-session-persistence "..."` |

### Context and configuration

| Flag | What it does |
|------|--------------|
| `--add-dir <directories...>` | Additional directories the session may read/write. |
| `--system-prompt <prompt>` | Replace the default system prompt for this session. |
| `--append-system-prompt <prompt>` | Append to the default system prompt (preserves CLAUDE.md etc.). |
| `--exclude-dynamic-system-prompt-sections` | Move per-machine sections (cwd, env, memory, git status) into the first user message. Improves cross-user prompt-cache reuse. Only applies with the default system prompt. |
| `--settings <file-or-json>` | Load additional settings from a JSON file or inline JSON string. |
| `--setting-sources <sources>` | Comma-separated list of setting sources to load: `user`, `project`, `local`. |
| `--mcp-config <configs...>` | Load MCP servers from JSON files or strings (space-separated). |
| `--strict-mcp-config` | Only use MCP servers from `--mcp-config`; ignore all other MCP configurations. |
| `--plugin-dir <path>` | Load plugins from a directory for this session only. Repeatable. |
| `--agent <agent>` | Agent for the current session. Overrides the `agent` setting. |
| `--agents <json>` | Define custom agents inline. Example: `'{"reviewer": {"description": "...", "prompt": "..."}}'`. |

### Model and effort

| Flag | What it does | Since |
|------|--------------|-------|
| `--model <model>` | Model alias (`sonnet`, `opus`) or full name (`claude-sonnet-4-6`). | — |
| `--fallback-model <model>` | Automatic fallback when the primary model is overloaded. `-p` only. | — |
| `--effort <level>` | Reasoning effort: `low`, `medium`, `high`, `xhigh`, `max`. | `xhigh` added 2.1.111 |
| `--betas <betas...>` | Beta headers to include in API requests (API-key users only). | — |

### Tool access

| Flag | What it does |
|------|--------------|
| `--allowedTools, --allowed-tools <tools...>` | Allowlist, comma- or space-separated (e.g. `"Bash(git *) Edit"`). |
| `--disallowedTools, --disallowed-tools <tools...>` | Denylist. Takes precedence over allowlist. |
| `--tools <tools...>` | Explicit tool set from the built-in catalog. `""` disables all; `"default"` enables all; or `"Bash,Edit,Read"`. |
| `--disable-slash-commands` | Disable all skills (slash commands) for this session. |
| `--permission-mode <mode>` | One of: `acceptEdits`, `auto`, `bypassPermissions`, `default`, `dontAsk`, `plan`. |
| `--allow-dangerously-skip-permissions` | Make bypassing permissions available as an option (still requires opt-in). |
| `--dangerously-skip-permissions` | Bypass all permission checks. Sandboxes only. |

### Input/output streaming

| Flag | What it does |
|------|--------------|
| `--input-format <format>` | `-p` only: `text` (default) or `stream-json`. |
| `--output-format <format>` | `-p` only: `text` (default), `json`, or `stream-json`. |
| `--include-hook-events` | Include hook lifecycle events in the output stream (`--output-format=stream-json` only). |
| `--include-partial-messages` | Include partial message chunks as they arrive (`-p` + `--output-format=stream-json`). |
| `--replay-user-messages` | Re-emit user messages back on stdout for acknowledgment (stream-json in both directions). |
| `--json-schema <schema>` | JSON Schema for structured output validation. |
| `--max-budget-usd <amount>` | Maximum dollar spend per run (`-p` only). |

### Workflow

| Flag | What it does |
|------|--------------|
| `-w, --worktree [name]` | Create a new git worktree for this session. Names MUST NOT contain forward slashes (hung pre-2.1.83). |
| `--tmux` | Create a tmux session for the worktree (requires `--worktree`). iTerm2 native panes when available; `--tmux=classic` for traditional tmux. |
| `--ide` | Auto-connect to IDE on startup if exactly one valid IDE is available. |
| `--chrome` / `--no-chrome` | Enable/disable Claude in Chrome integration. |
| `--brief` | Enable the `SendUserMessage` tool for agent-to-user communication (channels-style async). |
| `--file <specs...>` | Download file resources at startup. Format: `file_id:relative_path`. |
| `--remote-control-session-name-prefix <prefix>` | Prefix for auto-generated Remote Control session names (default: hostname). |

### Debug and meta

| Flag | What it does |
|------|--------------|
| `-d, --debug [filter]` | Enable debug mode with optional category filtering (e.g. `"api,hooks"` or `"!1p,!file"`). |
| `--debug-file <path>` | Write debug logs to a file (implicitly enables debug mode). |
| `--mcp-debug` | **Deprecated** — use `--debug` instead. |
| `--verbose` | Override the verbose setting from config. |
| `-v, --version` | Print the version. |
| `-h, --help` | Print the help text (canonical). |

### Bare mode (CI/headless)

`--bare` is the minimal mode for CI, scripts, and one-shot `-p` calls. It skips:

- Hooks (all 27 events)
- LSP
- Plugin sync
- Attribution
- Auto-memory
- Background prefetches
- Keychain reads
- CLAUDE.md auto-discovery

`--bare` sets `CLAUDE_CODE_SIMPLE=1`. Authentication is strictly `ANTHROPIC_API_KEY` or `apiKeyHelper` via `--settings` — OAuth and keychain are never read. Third-party providers (Bedrock, Vertex, Foundry) use their own credentials.

**Skills still resolve** via `/skill-name` invocations in the prompt — they're not considered plugin content.

To feed bare sessions context explicitly, combine with:

- `--system-prompt[-file]`, `--append-system-prompt[-file]`
- `--add-dir` (to include CLAUDE.md-bearing dirs)
- `--mcp-config`, `--settings`, `--agents`, `--plugin-dir`

Example (CI):

```bash
ANTHROPIC_API_KEY=$API_KEY \
  claude --bare -p "check diff for obvious bugs" \
    --add-dir "$CLAUDE_PROJECT_DIR" \
    --mcp-config ci-mcp.json \
    --output-format json
```

### MCP subcommand (`claude mcp`)

| Command | Purpose |
|---------|---------|
| `claude mcp add <name> <command-or-url> [args...]` | Register an MCP server. Stdio, HTTP, or SSE transports. |
| `claude mcp add --transport http <name> <url>` | HTTP MCP server. Use `--header "Authorization: Bearer ..."` for auth. |
| `claude mcp add -e KEY=val <name> -- <cmd> [args]` | Stdio server with env vars. |
| `claude mcp add-json <name> <json>` | Add a server from a JSON config string. |
| `claude mcp add-from-claude-desktop` | Import servers from Claude Desktop (macOS and WSL only). |
| `claude mcp get <name>` | Show server details. Health-checks stdio servers by spawning them — trusted dirs only. |
| `claude mcp list` | List all configured servers. |
| `claude mcp remove <name>` | Delete a server. |
| `claude mcp reset-project-choices` | Reset approved/rejected project-scoped (`.mcp.json`) servers. |
| `claude mcp serve` | Run Claude Code itself as an MCP server. |

MCP servers registered via `claude mcp add` are stored in `~/.claude.json`. `settings.json`'s `mcpServers` field is silently ignored — always use the CLI subcommand.

### Plugin subcommand (`claude plugin` / `claude plugins`)

| Command | Purpose |
|---------|---------|
| `claude plugin install <plugin>` (`i`) | Install a plugin from available marketplaces. Use `plugin@marketplace` to target a specific marketplace. |
| `claude plugin uninstall <plugin>` (`remove`) | Uninstall an installed plugin. |
| `claude plugin enable <plugin>` | Enable a disabled plugin. |
| `claude plugin disable [plugin]` | Disable an enabled plugin. |
| `claude plugin list` | List installed plugins. |
| `claude plugin update <plugin>` | Update a plugin (restart required). |
| `claude plugin marketplace` | Manage marketplaces. |
| `claude plugin validate <path>` | Validate a plugin or marketplace manifest. |

### Other top-level subcommands

| Command | Purpose |
|---------|---------|
| `claude agents` | List configured agents. |
| `claude auth` | Manage authentication. |
| `claude auto-mode` | Inspect auto mode classifier configuration. |
| `claude doctor` | Check auto-updater health. Spawns stdio MCP servers from `.mcp.json` for health checks — trusted dirs only. |
| `claude install [target]` | Install a native build (`stable`, `latest`, or specific version). |
| `claude setup-token` | Set up a long-lived authentication token (requires a Claude subscription). |
| `claude update` (`upgrade`) | Check for updates and install if available. |

---

## Settings `env:` block

These env vars are typically set inside `settings.json` under the `env:` block so they apply to every session:

| Variable | Default | What it does | Since |
|----------|---------|--------------|-------|
| `ENABLE_TOOL_SEARCH` | unset | Deferred tool loading via ToolSearch — fetch schemas on demand to cut context baseline. | 2.1.x |
| `CLAUDE_CODE_BLOCKING_LIMIT_OVERRIDE` | 500000 | Override the blocking tool output character cap. Raise for large outputs; lower to force truncation earlier. | — |
| `CLAUDE_CODE_SCRIPT_CAPS` | 500 | Cap on script output lines returned inline. | 2.1.98 |
| `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS` | 3000 | Milliseconds allowed for SessionEnd hooks before timeout. | — |
| `CLAUDE_CODE_NO_FLICKER` | unset | Flicker-free alt-screen with virtualized scrollback. | 2.1.89 |
| `MCP_CONNECTION_NONBLOCKING` | unset | Skip MCP connection wait in `-p` mode. | 2.1.89 |

---

## Shell environment

These env vars are typically exported from `~/.bashrc`, `~/.zshrc`, or the launching CI environment.

### Authentication

| Variable | What it does |
|----------|--------------|
| `ANTHROPIC_API_KEY` | Required for `--bare` and any non-OAuth flow. Scrubbed from subprocesses when `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1`. |
| `apiKeyHelper` *(in `--settings`)* | External script that returns an API key on demand. Honored in `--bare`. |

### Security

| Variable | What it does | Since |
|----------|--------------|-------|
| `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` | `=1` strips Anthropic credentials from subprocesses (Bash, hooks, MCP stdio). On Linux, triggers PID namespace isolation. **Incompatible with `skipDangerousModePermissionPrompt: true`** — check for that setting before enabling. | 2.1.98 |

### Timeouts and caching

| Variable | What it does | Since |
|----------|--------------|-------|
| `API_TIMEOUT_MS` | API request timeout in ms. Previously ignored (5-min timeout hardcoded). | 2.1.101 |
| `ENABLE_PROMPT_CACHING_1H` | Extend prompt cache window from 5 minutes to 1 hour. Cache-hit ROI improves for long/quiet sessions. | 2.1.108 |
| `FORCE_PROMPT_CACHING_5M` | Force the 5-minute cache window (useful for per-user cache separation tests). | 2.1.108 |

### Observability (OTEL)

| Variable | What it does | Since |
|----------|--------------|-------|
| `TRACEPARENT` | Auto-propagated into Bash subprocesses when OTEL tracing is enabled. Child spans parent correctly in Honeycomb/Jaeger. Also read from env by the SDK (2.1.110+). | 2.1.98 |
| `TRACESTATE` | Companion W3C Trace Context state field. Read from env by the SDK. | 2.1.110 |
| `OTEL_LOG_USER_PROMPTS` | Emit user prompts as span attributes. **Dev-only** — never set in `~/.bashrc`. | 2.1.98 |
| `OTEL_LOG_TOOL_DETAILS` | Emit tool call details as span attributes. Dev-only. | 2.1.98 |
| `OTEL_LOG_TOOL_CONTENT` | Emit tool input/output content as span attributes. Dev-only. | 2.1.98 |
| `OTEL_LOG_RAW_API_BODIES` | Emit raw request/response bodies as span attributes. Debug only. | 2.1.111 |

Set OTEL opt-in flags inline per session — `export OTEL_LOG_USER_PROMPTS=1 && claude ...` — not globally.

### Feature flags (progressive rollout)

| Variable | What it does | Since |
|----------|--------------|-------|
| `CLAUDE_CODE_USE_POWERSHELL_TOOL` | Enable PowerShell tool (progressive rollout on Windows). | 2.1.111 |
| `CLAUDE_CODE_SIMPLE` | Set by `--bare`; callable programs can check it to detect minimal mode. | 2.1.x |
| `CLAUDE_CODE_DISABLE_NONSTREAMING_FALLBACK` | Disable the non-streaming fallback path. | 2.1.89 |
| `CLAUDE_CODE_PLUGIN_KEEP_MARKETPLACE_ON_FAILURE` | Keep cached marketplace data when `git pull` fails during sync. | 2.1.90 |

### Hook-side variables (set by CC)

Hooks read these from their own environment (not from shell config):

| Variable | Value | Available in |
|----------|-------|-------------|
| `CLAUDE_PROJECT_DIR` | Absolute path to project root. | All hooks |
| `CLAUDE_ENV_FILE` | Writable env file path. | `SessionStart`, `CwdChanged`, `FileChanged` |

Use `${CLAUDE_PROJECT_DIR:-$PWD}` for portable paths inside hook scripts.

---

## Retired flags and aliases

| Flag / command | Retired or aliased at | Replacement |
|----------------|----------------------|-------------|
| `/tag`, `/vim` | 2.1.92 | Removed entirely. |
| `/proactive` | 2.1.105 | Aliased to `/loop`. |
| `/undo` | 2.1.108 | Aliased to `/rewind`. |
| `Ctrl+O` fullscreen | 2.1.110 | Split: `/focus` for fullscreen; `Ctrl+O` is now verbose-only. |
| `--enable-auto-mode` | 2.1.111 | Auto-mode is GA for Max on Opus 4.7; flag no longer needed. |
| `--mcp-debug` | deprecated | Use `--debug` (optionally with `"mcp"` filter). |
| `install.sh --commands` | 2.1.88 | Commands merged into skills. Use `--skills`. |

See `part6-reference/01-cc-version-history.md` for per-version details.

---

## See also

- `part3-extension/01-hooks.md` — hooks authoring tutorial (deep dive)
- `part6-reference/03-hook-event-catalog.md` — all 27 hook events with payload shapes
- `part6-reference/01-cc-version-history.md` — version changelog
- `part6-reference/06-security-checklist.md` — safe settings and deny-list patterns
