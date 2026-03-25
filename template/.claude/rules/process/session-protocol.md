# Session Protocol - Claude Code 2.1.83

**Scope**: ALL projects
**Authority**: Session lifecycle management
**Updated**: 2026-03-25

---

## Session Start

1. `/session-start` or manual state discovery (git status, system-status.json)
2. Use `--name <name>` flag to label sessions by branch/feature for easy resume
3. Use `/effort` to set model effort level (low for routine, high for complex)

## During Session

- **1M context**: Opus 4.6 has 1M context by default (Max/Team/Enterprise)
- **PostCompact hook**: After compaction, re-read critical files listed in the hook output
- **75% rule**: Checkpoint at 75% context — quality degrades past this point
- **`/context`**: Use to audit context usage and get optimization suggestions
- **Transcript search**: Press `/` in transcript mode (Ctrl+O) to search, `n`/`N` to step through matches
- **Ctrl+L**: Full screen clear + redraw — recovery when UI goes blank

## Session End

- `/session-end` or manual checkpoint commit
- `SessionEnd` hooks have 5s timeout (configured via `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS`)

## Worktree Usage

- Use `--worktree` for parallel agent work on large repos
- Stale worktrees from interrupted runs are auto-cleaned (2.1.76+)
- Worktree names must NOT contain forward slashes (caused hangs pre-2.1.83)

## Hook Events

- `CwdChanged` / `FileChanged` — reactive environment management (e.g., direnv)
- `PostCompact` — fires after compaction, reload context
- Agents can declare `initialPrompt` in frontmatter to auto-submit first turn

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS=5000` | Extend SessionEnd hook timeout |
| `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1` | Strip API credentials from subprocesses (Bash, hooks, MCP stdio) |
| `CLAUDE_CODE_DISABLE_NONSTREAMING_FALLBACK` | Disable non-streaming fallback |

## Settings

| Setting | Purpose |
|---------|---------|
| `sandbox.failIfUnavailable` | Exit with error when sandbox can't start (instead of running unsandboxed) |
| `managed-settings.d/` | Drop-in directory for modular policy fragments (merge alphabetically) |
| `disableDeepLinkRegistration` | Prevent `claude-cli://` protocol handler registration |

## Key Features by Version

| Feature | Version | Usage |
|---------|---------|-------|
| `/effort` | 2.1.76 | Set effort level per-session |
| `--name` | 2.1.76 | Label session at startup |
| `worktree.sparsePaths` | 2.1.76 | Sparse checkout for large repos |
| Deferred tools fix | 2.1.76 | ToolSearch survives compaction |
| Background agent fix | 2.1.83 | No longer invisible after compaction |
| `TaskOutput` deprecated | 2.1.83 | Use `Read` on task's output file path instead |
| MEMORY.md cap | 2.1.83 | Truncates at 25KB + 200 lines |
| Transcript search | 2.1.83 | `/` in Ctrl+O, `n`/`N` to navigate |
