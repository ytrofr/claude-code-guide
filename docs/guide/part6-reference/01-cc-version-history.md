---
layout: default
title: "CC Version History"
parent: "Part VI — Reference"
nav_order: 1
redirect_from:
  - /docs/guide/54-claude-code-2176-new-features.html
  - /docs/guide/54-claude-code-2176-new-features/
  - /docs/guide/57-claude-code-2177-2181-features.html
  - /docs/guide/57-claude-code-2177-2181-features/
  - /docs/guide/60-claude-code-2182-2183-features.html
  - /docs/guide/60-claude-code-2182-2183-features/
  - /docs/guide/64-claude-code-2184-2186-features.html
  - /docs/guide/64-claude-code-2184-2186-features/
  - /docs/guide/66-claude-code-2187-2188-features.html
  - /docs/guide/66-claude-code-2187-2188-features/
  - /docs/guide/70-claude-code-2189-2192-features.html
  - /docs/guide/70-claude-code-2189-2192-features/
  - /docs/guide/71-claude-code-2193-2194-features.html
  - /docs/guide/71-claude-code-2193-2194-features/
  - /docs/guide/72-claude-code-2195-2197-features.html
  - /docs/guide/72-claude-code-2195-2197-features/
  - /docs/guide/73-claude-code-2198-2199-features.html
  - /docs/guide/73-claude-code-2198-2199-features/
---

# CC Version History

A curated reference of Claude Code releases. Each entry highlights features that still matter in the current 2.1.121 line. Superseded features are noted once with their replacement.

For the definitive changelog, run `/release-notes` inside CC or see `claude update` output.

---

## Latest

### 2.1.121 (current)

- **`alwaysLoad: true` MCP server config** — opt a server out of `ENABLE_TOOL_SEARCH` deferral so its tools are always loaded. Use sparingly; each always-loaded tool consumes context every turn. Per-tool opt-in also available via `_meta.anthropic/alwaysLoad: true` in the tool definition.
- **`claude plugin prune`** (alias `autoremove`) removes auto-installed plugin dependencies that no longer have a parent. Flags: `--dry-run` (preview), `--scope user|project|local` (default `user`), `-y` (skip confirm — required when stdin is not a TTY). `claude plugin uninstall --prune` cascades the cleanup.
- **PostToolUse `hookSpecificOutput.updatedToolOutput`** now works for **all** tools (previously MCP-only). Hooks can rewrite or redact Bash, Read, Write, etc. output before it reaches the model.
- `/skills` gains a **type-to-filter search box** for long lists.
- Fullscreen mode: typing into the prompt no longer jumps scroll back to the bottom after you scrolled up.
- Dialogs that overflow the terminal are now scrollable with arrow keys, PgUp/PgDn, home/end, mouse wheel — both fullscreen and non-fullscreen.
- Long URLs that wrap across rows in fullscreen are clickable on any wrapped line.
- `CLAUDE_CODE_FORK_SUBAGENT=1` works in non-interactive `-p` and SDK sessions.
- `--dangerously-skip-permissions` no longer prompts for writes to `.claude/skills/`, `.claude/agents/`, `.claude/commands/`.
- MCP servers that hit a transient error during startup auto-retry up to **3 times** instead of staying disconnected.
- Vertex AI: support **X.509 certificate-based Workload Identity Federation** (mTLS ADC).
- LSP diagnostic summaries expand on click / Ctrl+O.
- SDK `mcp_authenticate` accepts `redirectUri` for custom scheme completion and claude.ai connectors.
- OpenTelemetry: LLM request spans add `stop_reason`, `gen_ai.response.finish_reasons`, and `user_system_prompt` (gated behind `OTEL_LOG_USER_PROMPTS`).
- **Memory fixes**: unbounded RSS growth on image-heavy sessions, up to ~2 GB leak in `/usage` on machines with large transcript histories, leak when long-running tools fail to emit progress events.
- Fixed Bash tool becoming permanently unusable when the directory CC was started in is deleted/moved mid-session.
- Fixed `--resume` failing on large/corrupt session transcripts; corrupt lines are now skipped.
- Fixed scrollback duplication on tmux, GNOME Terminal, Windows Terminal, Konsole when redrawing in non-fullscreen.

### 2.1.120

- **Windows: Git for Windows (Git Bash) no longer required** — when absent, CC uses PowerShell as the shell tool. Pairs with the PowerShell auto-approve rules added in 2.1.119.
- **`claude ultrareview [target]`** non-interactive CLI subcommand. Runs cloud multi-agent review on the current branch, a PR number, or a base branch. Flags: `--json` (raw `bugs.json` payload), `--timeout <minutes>` (default 30). Exits 0 on completion, 1 on failure. Suitable for CI gating; **billed**, so wire to manual triggers, not pre-push.
- **`${CLAUDE_EFFORT}`** substitution in skill content — skills can reference the active effort level (`low|medium|high|xhigh|max`) to weight their guidance.
- **`AI_AGENT` env var** set on subprocesses spawned by the Bash tool, so `gh` and similar tools can attribute traffic to Claude Code.
- Spinner tips that recommend installing the desktop app or creating skills/agents are hidden when you already have them.
- "Use PgUp/PgDn to scroll" hint shown when the terminal sends arrow keys instead of scroll events.
- Faster session start when many claude.ai connectors are configured but not authorized.
- `claude plugin validate` accepts `$schema`, `version`, `description` at the top level of `marketplace.json` and `$schema` in `plugin.json`.
- Fixed pressing Esc during a stdio MCP tool call closing the entire server connection (regression from 2.1.105).
- Fixed `/rewind` and other interactive overlays not responding to keyboard input after `claude --resume`.
- Fixed `DISABLE_TELEMETRY` / `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` not suppressing usage metrics for API/enterprise users.
- Fixed false-positive "Dangerous rm operation" prompts in auto mode for multi-line bash commands containing both a pipe and a redirect.
- Fixed `find` in the Bash tool exhausting open file descriptors on large trees, causing host-wide crashes (macOS/Linux native builds).

### 2.1.119

- **`/config` settings persist to `~/.claude/settings.json`** (theme, editor mode, verbose, etc.) and now participate in project/local/policy override precedence. Project `.claude/settings.json` still wins.
- **`prUrlTemplate` setting** points the footer PR badge at a custom code-review URL instead of github.com. Supports `{host}`, `{owner}`, `{repo}`, `{number}`, `{url}` placeholders.
- **`CLAUDE_CODE_HIDE_CWD`** env var hides the working directory in the startup logo (privacy/screencast). Does NOT affect statusline, OTEL spans, or hook stdin paths.
- `--from-pr` now accepts **GitLab merge-request, Bitbucket pull-request, and GitHub Enterprise** PR URLs. Auth inherits per-provider CLI credentials.
- `--print` mode honors the agent's `tools:` / `disallowedTools:` frontmatter, matching interactive-mode behavior.
- `--agent <name>` honors the agent definition's `permissionMode` for built-in agents.
- **PowerShell tool commands now auto-approvable in permission mode** (same rules as Bash). Patterns like `PowerShell(Get-ChildItem:*)` allow, `PowerShell(Remove-Item:*)` deny.
- **Hooks**: `PostToolUse` and `PostToolUseFailure` receive **`duration_ms`** in their JSON input (tool execution time only — excludes permission prompts and PreToolUse hooks).
- Subagent and SDK MCP server reconfiguration connect servers in **parallel** instead of serially.
- Plugins pinned by another plugin's version constraint auto-update to the highest satisfying git tag.
- Vim mode: Esc in INSERT no longer pulls a queued message back into the input; press Esc again to interrupt.
- Slash command picker highlights matching characters and wraps long descriptions onto a second line.
- `owner/repo#N` shorthand links now use your git remote's host (not always github.com).
- Security: `blockedMarketplaces` correctly enforces `hostPattern` and `pathPattern` entries.
- OpenTelemetry: `tool_result` and `tool_decision` events include `tool_use_id`; `tool_result` adds `tool_input_size_bytes`.
- Statusline stdin JSON includes `effort.level` and `thinking.enabled`.
- Many UX bug fixes: pasting CRLF inserting blank lines, kitty keyboard losing newlines on multi-line paste, Glob/Grep disappearing when Bash denied (native builds), MCP HTTP OAuth on non-JSON discovery responses, Rewind showing "(no prompt)" for image messages, async PostToolUse hook empty-payload writes.

### 2.1.118

- **Hooks can invoke MCP tools directly** via `type: "mcp_tool"` with `${tool_input.*}` / `${cwd}` templating. Replaces subprocess plumbing for MCP-writing hooks. Non-blocking on server disconnect; 60s default timeout; avoid on `SessionStart` (MCP servers typically not yet connected).
- `/cost` and `/stats` merged into `/usage`. Both remain as typing shortcuts that open the relevant tab.
- **Custom named themes**: create from `/theme` or hand-edit `~/.claude/themes/*.json`. Plugins can ship themes via a `themes/` directory.
- `DISABLE_UPDATES` env var blocks all update paths including manual `claude update` — stricter than `DISABLE_AUTOUPDATER`.
- WSL on Windows can inherit Windows-side managed settings via the `wslInheritsWindowsSettings` policy key.
- Auto mode `"$defaults"` placeholder — include in `autoMode.allow` / `soft_deny` / `environment` to extend the built-in list instead of replacing it.
- `claude plugin tag` creates release git tags for plugins with version validation.
- Vim visual mode (`v`) and visual-line mode (`V`) with selection, operators, and visual feedback.
- `--continue` / `--resume` finds sessions that added the current directory via `/add-dir`.
- Fixed `/fork` writing the full parent conversation to disk per fork (now writes a pointer and hydrates on read).
- Fixed agent-type hooks failing with "Messages are required" for events other than `Stop` / `SubagentStop`.

### 2.1.117

- **Native builds on macOS and Linux: embedded `bfs` and `ugrep` replace Glob and Grep tools** (available through the Bash tool). Faster searches without a separate tool round-trip. Windows and npm-installed builds unchanged.
- **Opus 4.7 `/context` 1M-window bug fixed** — CC was computing `/context %` against a 200K window, inflating usage and triggering early autocompact. If you measured context baselines during 2.1.111–2.1.116 on Opus 4.7, re-measure.
- `cleanupPeriodDays` retention sweep extended to `~/.claude/tasks/`, `~/.claude/shell-snapshots/`, and `~/.claude/backups/` (previously only `todos/`).
- `CLAUDE_CODE_FORK_SUBAGENT=1` enables forked subagents on external builds.
- Agent frontmatter `mcpServers` loads for main-thread agent sessions via `--agent`.
- `/resume` offers to summarize stale, large sessions before re-reading them.
- Faster MCP startup when both local and claude.ai servers are configured (concurrent connect now default).
- **Default effort for Pro/Max subscribers on Opus 4.6 and Sonnet 4.6 is now `high`** (was `medium`).
- OpenTelemetry: `user_prompt` events include `command_name` and `command_source` for slash commands. `cost.usage`, `token.usage`, `api_request`, `api_error` include an `effort` attribute when the model supports effort levels. Custom/MCP command names redacted unless `OTEL_LOG_TOOL_DETAILS=1`.

### 2.1.116

- `/resume` up to **67% faster on 40MB+ sessions**; handles sessions with many dead-fork entries more efficiently.
- Faster MCP startup when multiple stdio servers are configured; `resources/templates/list` deferred to first `@`-mention.
- `/doctor` can be opened while Claude is responding (previously had to wait for turn).
- `/reload-plugins` and background auto-update now auto-install missing plugin dependencies from already-added marketplaces.
- Bash tool surfaces a hint when `gh` commands hit GitHub's API rate limit.
- **Sandbox auto-allow dangerous-path safety** — no longer bypasses the dangerous-path check for `rm` / `rmdir` targeting `/`, `$HOME`, or other critical system directories.
- Releases URL moved to `https://downloads.claude.ai/claude-code-releases`.

### 2.1.113

- **CLI now spawns a native Claude Code binary** (via a per-platform optional dependency) instead of bundled JavaScript.
- `sandbox.network.deniedDomains` setting blocks specific domains even when a broader `allowedDomains` wildcard would permit them.
- Ctrl+A and Ctrl+E move to the start/end of the current logical line (readline behavior for multiline input).
- Windows: Ctrl+Backspace deletes the previous word.
- Long URLs stay clickable when they wrap across lines (in terminals with OSC 8 hyperlinks).
- `/loop`: pressing Esc cancels pending wakeups. Wakeups display as "Claude resuming /loop wakeup".
- Subagents that stall mid-stream fail with a clear error after **10 minutes** instead of hanging silently.
- **Bash security hardening**:
  - Multi-line commands whose first line is a comment now show the full command in the transcript (closes a UI-spoofing vector).
  - Deny rules now match commands wrapped in `env` / `sudo` / `watch` / `ionice` / `setsid` and similar exec wrappers.
  - `Bash(find:*)` allow rules no longer auto-approve `find -exec` / `-delete`.
  - `dangerouslyDisableSandbox` respects permissions (no silent bypass).
  - macOS: `/private/{etc,var,tmp,home}` paths treated as dangerous removal targets under `Bash(rm:*)` allow rules.

### 2.1.111

- Opus 4.7 `xhigh` effort level, between `high` and `max`.
- Interactive `/effort` slider for setting reasoning depth.
- `/less-permission-prompts` skill: scans transcripts and proposes allowlist entries for `.claude/settings.json`.
- `/ultrareview` cloud multi-agent review.
- Auto-mode GA for Max on Opus 4.7 (no `--enable-auto-mode` flag needed).
- "Auto (match terminal)" theme option.
- Plan files named after the prompt instead of `plan-1.md`.
- `/skills` sort-by-token toggle.
- `OTEL_LOG_RAW_API_BODIES` env var for raw request/response debugging.
- Ctrl+U clears the whole input buffer; Ctrl+Y restores it.
- PowerShell tool progressive rollout via `CLAUDE_CODE_USE_POWERSHELL_TOOL`.

### 2.1.110

- `/tui` command and `tui` setting for fullscreen mode.
- `/focus` split from Ctrl+O; Ctrl+O is now verbose-only.
- Push notification tool (opt-in via Remote Control).
- `autoScrollEnabled` setting.
- `/doctor` warns on MCP-scope conflicts.
- Bash tool enforces the documented max timeout.
- SDK reads `TRACEPARENT` and `TRACESTATE` from env.

### 2.1.108

- `ENABLE_PROMPT_CACHING_1H` (1-hour cache window) and `FORCE_PROMPT_CACHING_5M` env vars.
- `/recap` command, default-on for telemetry-disabled users.
- `/undo` aliased to `/rewind`.
- `/model` warns on cache miss.
- `/resume` prefers the current working directory.
- Built-in slashes (`/init`, `/review`, `/security-review`) re-implemented via the Skill tool.

### 2.1.105

- `PreCompact` hooks can block compaction (`exit 2` or `{"decision":"block"}`).
- Skill `description` cap raised from 250 to 1536 characters.
- Plugin `monitors` manifest entry.
- `WebFetch` strips `<script>` and `<style>` before returning.
- Stalled-stream abort after 5 minutes.
- `/doctor f` applies auto-fixes.
- `/proactive` aliased to `/loop`.
- `EnterWorktree` accepts a path parameter.

### 2.1.101

- `/team-onboarding` skill generates a teammate ramp-up guide from local usage patterns.
- OS CA certificate trust is now the default (enterprise TLS proxies work out of the box). Set `CLAUDE_CODE_CERT_STORE=bundled` to restrict.
- `API_TIMEOUT_MS` is honored (previous 5-minute hardcoded timeout removed).
- Brief-mode retry on transient failures.
- Remote auto cloud environment detection.

---

## 2.1.98 — 2.1.99

### 2.1.99

- **Settings resilience**: an unrecognized hook event name no longer discards the whole `settings.json`. Only the bad entry is skipped. Audit hooks after upgrading — silently-dead hooks may start firing.
- `permissions.deny` now overrides a PreToolUse hook's `permissionDecision: "ask"`.
- Subagents inherit MCP tools from dynamically-injected servers (tools added mid-session via `claude mcp add`).
- Subagents in isolated worktrees can Read/Edit files inside their own worktree.
- `--resume <name>` accepts session titles set via `/rename` or `--name`.
- `/team-onboarding` command (see 2.1.101).
- Fixed `--dangerously-skip-permissions` being silently downgraded to accept-edits mode.
- Fixed `permissions.additionalDirectories` changes not applying mid-session.
- Fixed command injection in POSIX `which` fallback.

### 2.1.98

- **Monitor tool**: streams stdout events from background scripts. Each stdout line becomes a notification. Use for long builds, deploys, or fetches. See Part V chapter on Monitor for patterns.
- **Bash permission hardening** — 6 bypass vectors closed:
  - Compound commands (`echo x && killall node`) now prompt in auto/bypass modes.
  - Backslash-escaped flags (`killall\ node`) no longer auto-allowed.
  - `/dev/tcp` and `/dev/udp` redirects prompt instead of auto-allowing.
  - Env-var prefix (`LANG=C killall node`) prompts unless the var is known-safe (`LANG`, `TZ`, `NO_COLOR`, etc.).
  - Whitespace matching: `Bash(cmd:*)` wildcards match extra spaces/tabs.
- **PID namespace isolation** on Linux when `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1` is set.
- `CLAUDE_CODE_SCRIPT_CAPS=<N>` limits per-session script invocations.
- **OTEL tracing**: Bash tool auto-injects `TRACEPARENT` to subprocesses. Opt-in span attributes: `OTEL_LOG_USER_PROMPTS`, `OTEL_LOG_TOOL_DETAILS`, `OTEL_LOG_TOOL_CONTENT` (debug-only, never in shared config).
- `/agents` view split into Running and Library tabs.
- Interactive Bedrock and Vertex AI setup wizards on the login screen.
- `--exclude-dynamic-system-prompt-sections` flag for print mode enables cross-user prompt caching.

---

## 2.1.95 — 2.1.97

### 2.1.97

- **Focus view** (Ctrl+O in `CLAUDE_CODE_NO_FLICKER=1` mode): clean view showing prompt, one-line tool summary with diffstats, and final response. (Split to dedicated `/focus` in 2.1.110.)
- **Statusline `refreshInterval`** setting re-runs the script every N seconds for live indicators.
- **`workspace.git_worktree`** field added to statusline stdin JSON — shows active worktree path. Important for multi-worktree setups.
- Accept Edits mode auto-approves commands prefixed with known-safe env vars (`LANG=`, `NO_COLOR=`, `timeout`).
- `/agents` view shows `● N running` indicators for live subagent instances.
- Fixed 429 retries burning all attempts in ~13s (exponential backoff is now the minimum).
- Fixed MCP HTTP/SSE connections leaking ~50 MB/hr on reconnect.
- Fixed subagents with worktree isolation leaking cwd back to the parent session.

### 2.1.96

- Fixed Bedrock 403 regression with `AWS_BEARER_TOKEN_BEDROCK` and `CLAUDE_CODE_SKIP_BEDROCK_AUTH`.

### 2.1.95

- NO_FLICKER mode stability fixes (URL wrapping, MCP hover crash, Windows scrolling, short-terminal statusline, Korean/Japanese copy).

---

## 2.1.93 — 2.1.94

### 2.1.94

- **Default effort level changed from `medium` to `high`** for API-key, Bedrock, Vertex, Foundry, Team, and Enterprise users. Use `/effort low` to revert per-session.
- Amazon Bedrock Mantle support via `CLAUDE_CODE_USE_MANTLE=1`.
- Plugin skill YAML hooks now fire correctly (were silently ignored before).
- Plugin output styles gained `keep-coding-instructions` frontmatter.
- Fixed agents stuck after 429 with long `Retry-After` headers.
- Fixed Console login on macOS when the keychain is locked.
- Fixed plugin hooks failing when `CLAUDE_PLUGIN_ROOT` is unset.

---

## 2.1.89 — 2.1.92

### 2.1.92

- **`/cost` per-model and cache-hit breakdown** for subscription users.
- `/release-notes` presents an interactive version picker.
- `apply-seccomp` helper ships in npm and native builds for Linux sandbox.
- `/tag` and `/vim` removed. Editor mode now in `/config`.

### 2.1.91

- MCP tool results can be up to 500K chars via `_meta.anthropic/maxResultSizeChars`.
- Edit tool uses shorter context anchors (token savings, no behavior change).
- Plugins can ship executables in a `bin/` directory.
- `disableSkillShellExecution` setting blocks inline shell in skills/commands/plugins.

### 2.1.90

- `/powerup` command: interactive lessons with animated terminal demos for CC features.
- Auto mode respects explicit natural-language boundaries ("don't push", "only edit these files").
- Fixed Edit/Write failing when a PostToolUse hook reformats the file (Prettier, Black, rustfmt workflows).
- Fixed full prompt-cache miss on the first request after `--resume`.

### 2.1.89

- **Autocompact thrash guard**: after 3 consecutive compact-refill cycles, CC halts with an actionable error instead of looping.
- Hook stdout/stderr over 50K chars saves to disk; context gets a file path and 2KB preview.
- Edit tool works on files previously viewed via Bash `cat`/`sed`/`head`/`tail` without a prior Read call.
- PreToolUse hooks can return `{"defer": true}` to pause headless `-p` sessions for later resume.
- New settings: `sandbox.failIfUnavailable`, `managed-settings.d/` drop-in directory, `disableDeepLinkRegistration`, `showThinkingSummaries` (now OFF by default).
- New env vars: `MCP_CONNECTION_NONBLOCKING`, `CLAUDE_CODE_PLUGIN_KEEP_MARKETPLACE_ON_FAILURE`.

---

## 2.1.87 — 2.1.88

### 2.1.88

Significant stability release. Highlights worth remembering:

- **Nested CLAUDE.md re-injection fix** — in setups with global + per-project CLAUDE.md, nested files were re-injected dozens of times per long session, silently eating context. Now fixed.
- **Prompt cache fix** — tool schema bytes changing mid-session no longer invalidate the prompt cache on every turn. Setups with many MCP servers benefit most.
- **Hook `if` compound-command fix** — `if: "Bash(git *)"` now correctly matches `ls && git push`, `FOO=bar git push`, etc. Hooks may now fire more often than before (correct behavior).
- **PreToolUse/PostToolUse absolute `file_path`** — Write/Edit/Read hooks now receive absolute paths, not relative.
- **`CLAUDE_CODE_NO_FLICKER=1`** env var opts into alt-screen rendering with virtualized scrollback (reduces flicker, especially on WSL2). Tradeoff: scrollback discarded on exit.
- **PermissionDenied hook event** fires after auto-mode classifier denials. Return `{retry: true}` to allow retry.
- Named subagents appear in `@` mention typeahead.
- LSP server auto-restarts after crash instead of staying zombie.
- Fixed memory leak where large JSON stdin payloads were retained as LRU cache keys.
- `showThinkingSummaries` now OFF by default.
- Computer use (macOS only, Pro/Max) via `computer-use` MCP server.
- Fixed StructuredOutput schema cache bug, Edit OOM on >1 GiB files, CJK/emoji prompt history truncation at 4KB, `/stats` dropping subagent/fork tokens.

### 2.1.87

- Fixed Cowork Dispatch message delivery.

---

## 2.1.84 — 2.1.86

### 2.1.86

- **Skill description cap: 250 characters** (raised to 1536 in 2.1.105). Descriptions over cap were silently truncated, cutting off "Use when..." trigger phrases. Audit with a `wc -c` loop over `~/.claude/skills/*/SKILL.md`.
- Read tool uses a compact line-number format and deduplicates unchanged re-reads.
- `@`-mention content no longer JSON-escaped — token savings on `@file` references.
- `/skills` sorted alphabetically.
- `.jj` and `.sl` added to VCS exclusions (Jujutsu, Sapling).
- `X-Claude-Code-Session-Id` header for proxy session aggregation.

### 2.1.85

- **Conditional `if` field for hooks** on `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest`. Uses permission-rule syntax (`Bash(git *)`, `Edit(*.ts)`). Filters BEFORE process spawn — zero overhead for misses. Eliminates ~90% of wasted spawns in hooks that matched broadly and filtered internally.
- MCP server env vars `CLAUDE_CODE_MCP_SERVER_NAME` and `CLAUDE_CODE_MCP_SERVER_URL` available in MCP headers.
- Fixed `/compact` failing on very large sessions.

### 2.1.84

- **`paths:` frontmatter accepts YAML list** on rules and skills. Domain-specific rules can now scope to file types (`**/*.py`, `**/*.sh`) so they only load when relevant.
- **System-prompt caching works with `ENABLE_TOOL_SEARCH=true`** — previously the two were incompatible, forcing a choice between cache savings and deferred tools.
- MCP tool descriptions and server instructions capped at 2KB.
- Code intelligence LSP plugins published (`typescript-lsp`, `pyright-lsp`, `gopls-lsp`, `rust-analyzer-lsp`, `clangd-lsp`, `ruby-lsp`). Enable per-plugin in `enabledPlugins`.
- New `TaskCreated` hook event.
- Idle-return prompt nudges `/clear` after 75+ minutes idle.

---

## 2.1.82 — 2.1.83

### 2.1.83

- **New hook events**: `CwdChanged` (fires on directory change, useful for `direnv allow`) and `FileChanged` (fires on disk changes, enables hot-reload patterns).
- **Background agent stability fix** — agents now survive context compaction without becoming invisible or spawning duplicates.
- **`TaskOutput` tool deprecated** — use `Read` on the task's output file path instead.
- **MEMORY.md auto-capped at 25KB / 200 lines** to prevent memory bloat.
- **Transcript search**: Ctrl+O to enter transcript mode, `/` to search, `n`/`N` for next/previous.
- Ctrl+L clears and redraws the UI.
- `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1` strips API credentials from all subprocesses.
- `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS` extends SessionEnd hook timeout beyond 1.5s default.
- Agents can declare `initialPrompt:` in frontmatter for autonomous first-turn dispatch.
- Fixed worktree names with `/` causing hangs.
- `sandbox.failIfUnavailable`, `managed-settings.d/`, `disableDeepLinkRegistration` settings added.

### 2.1.82

- Reactive-hooks groundwork shipped with 2.1.83.

---

## 2.1.76 — 2.1.81

### 2.1.81

- `--bare` flag: skips hooks, LSP init, plugin sync, skill-directory walks. Requires `ANTHROPIC_API_KEY`. For CI pipelines and scripted `-p` calls.
- `--channels` permission relay (GA) — routes approval prompts to a mobile notification channel.
- Fixed concurrent-session OAuth re-auth storm.
- MCP tool calls collapse into a single "Queried {server}" line in the transcript.

### 2.1.80

- Statusline scripts receive a `rate_limits` field (5-hour and 7-day usage/limit).
- Skills and slash commands accept `effort:` in YAML frontmatter.
- `source: 'settings'` plugin marketplace declaration (groundwork for discovery).
- Fixed `--resume` dropping parallel tool results.

### 2.1.79

- `claude auth login --console` — terminal-only OAuth via paste-back code. For remote servers, Docker, CI.
- Turn duration display toggle in `/config`.
- `/remote-control` for VS Code.

### 2.1.78

- **`StopFailure` hook event** fires when CC stops from API error (rate limit, network, auth). Fills the gap between `Stop` (normal) and `SessionEnd` (always).
- `${CLAUDE_PLUGIN_DATA}` env var — per-plugin persistent state directory.
- Plugin agent frontmatter accepts `effort`, `maxTurns`, `disallowedTools`.
- Line-by-line response streaming (later disabled on Windows/WSL in 2.1.81).

### 2.1.77

- Opus 4.6 default max output raised from 32k to 64k (upper bound 128k).
- `sandbox.allowRead` — grant read-only sandbox access to specific paths.
- `/copy N` copies the Nth-latest response.
- `/branch` (renamed from `/fork`) for conversation branch points.

### 2.1.76

- **`PostCompact` hook event** fires after compaction completes. Reload critical rules, CLAUDE.md, or state that compaction discarded. Pairs with `PreCompact` (save-before, restore-after).
- `/effort low|medium|high` slash command (`xhigh` added in 2.1.111).
- `--name` / `-n` flag and `/rename` command for session display names.
- `worktree.sparsePaths` setting — git sparse-checkout for large monorepo worktrees.
- **MCP elicitation**: MCP servers can request structured input mid-task. New `Elicitation` and `ElicitationResult` hook events.
- 1M context window default for Opus 4.6 on Max, Team, Enterprise plans.
- `autoMemoryDirectory` setting redirects auto-memory storage to a custom path.
- `/context` command shows actionable diagnostics, not just token counts.
- Deferred tool schemas now survive compaction.
- RTL text (Hebrew, Arabic) renders correctly in terminal output.

### 2.1.73 — 2.1.75

- 2.1.75: 1M context default for Opus 4.6 (see 2.1.76 entry).
- 2.1.74: Configurable SessionEnd hook timeout, `autoMemoryDirectory`, `/context` diagnostics.
- 2.1.73: Groundwork for 2.1.76 reactive-hook surface.

---

## Superseded features

Features that shipped but have since been replaced or deprecated:

| Shipped | Feature | Replaced by |
|---------|---------|-------------|
| Pre-2.1.88 | Commands directory (`commands/`) | Skills directory (`skills/<name>/SKILL.md`) |
| 2.1.83 | `TaskOutput` tool | `Read` on the task's output file path |
| Pre-2.1.92 | `/tag`, `/vim` commands | Removed; editor mode via `/config` |
| 2.1.86 | 250-char skill description cap | Raised to 1536 in 2.1.105 |
| 2.1.88 | Ctrl+O = focus view | `/focus` command (2.1.110); Ctrl+O is verbose-only |
| 2.1.76 | `/fork` | `/branch` |
| 2.1.118 | `/cost`, `/stats` commands | `/usage` (both remain as typing shortcuts) |
| Pre-2.1.120 | Git for Windows requirement on Windows | PowerShell fallback when Git Bash absent (2.1.120) |

---

## See also

- [Part III — Extension]({{ "/docs/guide/part3-extension/" | relative_url }}) — hook event catalog (27 events).
- [Part V — Advanced Patterns]({{ "/docs/guide/part5-advanced/" | relative_url }}) — Monitor tool, OTEL self-telemetry, statusline patterns.
- `/release-notes` inside CC for the interactive version picker (2.1.92+).
