# Multi-Agent Safety — MANDATORY when subagents are active

**Scope**: ALL projects using Task() delegation, parallel agents, or worktrees
**Authority**: Prevents cross-agent state corruption
**Source**: OpenClaw multi-agent patterns (2026-03)

---

## Core Rule

**Assume other agents may be working on the same repo. Scope your actions to YOUR changes only.**

---

## Git Safety (Multi-Agent)

| Action | Rule |
|--------|------|
| `git stash` | NEVER create/apply/drop unless explicitly requested |
| `git checkout <branch>` | NEVER switch branches unless explicitly requested |
| `git add -A` / `git add .` | NEVER when unrecognized files exist — add specific files only |
| `git worktree` | NEVER create/modify/remove unless explicitly requested |
| `git pull --rebase --autostash` | FORBIDDEN — autostash can corrupt other agent's WIP |

## Commit Scoping

| User Says | Agent Action |
|-----------|-------------|
| "commit" | Stage and commit ONLY files YOU changed |
| "commit all" | Stage everything, commit in grouped chunks by topic |
| "push" | May `git pull --rebase` first (no autostash), then push |

## Unrecognized Files

When you see files you didn't create or modify:
1. **Leave them alone** — another agent or the user may own them
2. **Continue your work** — focus on your task
3. **Note at the end** — brief "other uncommitted files present" only if relevant
4. Do NOT delete, stage, stash, or modify unrecognized files

## Formatting/Lint Churn

- Formatting-only diffs from your changes: auto-resolve, no confirmation needed
- Formatting in files you didn't touch: LEAVE THEM — another agent may be working there

---

**Last Updated**: 2026-03-20
