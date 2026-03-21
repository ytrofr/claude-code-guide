# Agent Teams Status — Claude Code 2.1.77

**Investigated**: 2026-03-21 | **Status**: Research Preview (shipped in v2.1.32)

---

## Current Status

Agent Teams shipped as a **research preview** in Claude Code v2.1.32. Enable with:

```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

This allows defining named teams of agents that coordinate on tasks. The feature is experimental and may change in future releases.

## Historical Findings (v2.1.77)

At the time of initial investigation (v2.1.77), the feature was not discoverable via CLI help or settings. It required the experimental env var above.

---

## What DOES Exist (Use These Instead)

| Feature | Flag/Tool | Purpose |
|---------|-----------|---------|
| Custom agents | `--agents '{json}'` or `.claude/agents/` | Define named agents with custom prompts |
| Subagent delegation | `Task()` tool | Spawn fresh-context subagents for subtasks |
| Git worktrees | `--worktree [name]` | Isolated git worktree per session |
| Worktree + tmux | `--worktree --tmux` | Parallel sessions in separate panes |
| Background tasks | `run_in_background: true` | Non-blocking long-running commands |

---

## LIMOR Recommended Patterns (Current Capabilities)

**Parallel baselines (D1-D5)**: Use `run_in_background: true` with sequential batches. Do NOT attempt to run multiple Claude sessions against the same working directory.

**Multi-branch work**: Use `--worktree` to work on dev-Limor-routing-cleanup while main session stays on dev-Limor. Configured in settings via `worktree.sparsePaths`.

**Complex multi-file tasks**: Use `Task()` delegation per `delegation-rule.md` (3+ tasks touching different files/domains).

---

## When NOT to Use Parallel Patterns

- Single-file fixes (work inline)
- Sequential dependency chains (tasks depend on prior results)
- Debugging / iterative exploration (need accumulated context)
- Same-directory concurrent writes (git conflicts)

---

## Watch For in Future Versions

- A `--team` or `--agent-team` CLI flag
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` env var becoming documented
- `claude teams` subcommand appearing in `claude --help`
- Anthropic blog posts mentioning "Agent Teams" or "multi-agent orchestration"
- Settings schema additions with "team" keys in `settings.json`

---

**Last Updated**: 2026-03-20
