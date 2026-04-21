---
layout: default
title: "Commit and Pull Request Workflow"
parent: "Part II — Workflow"
nav_order: 6
---

# Commit and Pull Request Workflow

Commits are how you tell future-you (and future collaborators) what changed and why. Pull requests are how you hand a set of commits to someone else — reviewer, deploy pipeline, or open-source maintainer — with enough context to act on them. Both are small surfaces where small mistakes cause disproportionate damage: a missed secret, an accidental `git add -A` that pulls in another agent's unfinished work, a commit message that says "fix" and nothing else.

This chapter is a reference, not a tutorial. If you need to make a commit right now, the decision flowcharts are all you need. The longer sections exist for the moments when something went wrong and you need to know why.

**Purpose**: Commit and ship work safely when multiple agents or sessions share a repo
**Difficulty**: Beginner
**Applies to**: Every commit, every PR, every push

---

## Scoped Commits: Stage Specific Files, Not Everything

**Rule**: Stage specific files by name. Never use `git add -A` or `git add .` unless you have personally reviewed every file in the staging set.

```bash
# CORRECT
git add src/auth/login.ts src/auth/login.test.ts

# WRONG (in a multi-agent repo)
git add -A
```

**Why**: if another Claude session, another developer, or a background tool has uncommitted work in your repo, `git add -A` pulls it all in. You end up committing other people's unfinished features, their debug `console.log` statements, their unencrypted test credentials. In a multi-agent setup this is the single most common cause of "I committed something I didn't write."

See [Multi-Agent Safety](https://github.com/ytrofr/claude-code-guide) for the full ruleset. The short version: if you didn't change it in this session, don't stage it.

### When "commit everything" is actually what you want

```bash
# Step 1: Review
git status
# Confirm every file listed is YOURS

# Step 2: Stage explicitly
git add file1 file2 file3 ...

# Step 3: Commit
git commit
```

Three steps, small overhead, catches the accident.

---

## /commit vs Manual Commits

The `commit-commands` plugin (official) ships three slash commands:

| Command | Use for |
|---|---|
| `/commit` | Create a single commit on the current branch |
| `/commit-push-pr` | Commit, push to origin, open a PR — one shot |
| `/clean-gone` | Clean up local branches whose remote was deleted |

### When to use /commit

- Two or more logically distinct commits coming out of a session
- You want to write the message yourself or review the diff first
- You're on `main` and pushing directly (no PR flow)

The skill drafts a message from the diff, shows it to you, and commits on confirmation. Scope is respected — it stages only files you specify.

### When to use /commit-push-pr

- Single-session feature work on a feature branch
- You have commit access to the repo
- There's no review gate between your branch and `main`

This is the fast path: one command takes a dirty working tree and produces a PR URL. It stages, commits, pushes (setting upstream if needed), and opens the PR with a draft title and body.

### When to use neither

- The work spans multiple logical commits — do them manually, one at a time
- You're rebasing or amending — slash commands won't help
- You need to sign commits with GPG — configure git directly

---

## Commit Message Conventions

**Short subject, body explains why, not what.**

```
feat(auth): add Google OAuth sign-in

The existing email/password flow has a 38% abandonment rate at the
password-creation step (growth metrics, Q1). Google sign-in removes
that step entirely for the ~70% of users who already have a Google
session on-device.

Implementation follows the OAuth2 authorization-code flow with PKCE.
Refresh tokens are stored server-side; client only sees the session
cookie.
```

### The rules

- **Subject**: 50-72 chars, imperative mood ("add" not "added"), optional type-scope prefix (`feat(auth):`, `fix(api):`, `docs(guide):`)
- **Blank line** between subject and body
- **Body**: explain *why* the change was needed and *why this approach*. The diff shows *what*; don't repeat it.
- **Wrap body at 72 chars** for readability in `git log` and email clients

### What NOT to put in commit messages

- `@claude` or AI attribution unless the repo explicitly requires it
- Secrets, API keys, internal paths (`/home/username/...`, `/Users/...`)
- Jira or issue tracker links if the repo is public and the tracker is private
- Dates or times (git already records these)

---

## Pre-Commit Hygiene Checklist

Before every commit — especially to public repos — run this check:

```bash
# No secrets
git diff --cached | grep -iE 'api.key|secret|password|token|bearer' | head

# No internal paths
git diff --cached | grep -E '/home/|/Users/|C:\\Users'

# No large binaries
git diff --cached --stat | awk '$3 > 500 { print }'

# No debug artifacts
git diff --cached | grep -E 'console\.log|print\(|debugger|binding\.pry'
```

If any of these return hits, stop. Fix first, commit second.

### For public repos

Additional checks:

- License header present on new source files (if required)
- No references to private infrastructure (internal hostnames, VPN-only URLs)
- No screenshots or logs containing PII
- CITATION.cff, CHANGELOG.md, version files synced if this is a release

---

## Pull Request Structure

A good PR has two things: a title that tells you what changed, and a description that tells you why it's safe to merge.

### Title

Same rules as a commit subject. Imperative, 50-72 chars, scope prefix if you use conventional commits.

```
feat(auth): add Google OAuth sign-in
fix(api): return 404 not 500 when project_id is unknown
docs(guide): add chapter on commit and PR workflow
```

### Description — two required sections

```markdown
## Summary

- One to three bullets describing what changed
- Focus on user-visible behavior, not implementation mechanics
- If there's a "why," include it here briefly

## Test plan

- [ ] Specific manual steps the reviewer or CI can run
- [ ] Include expected outputs where non-obvious
- [ ] Link to automated tests if this is TDD work
```

The **Test plan** is the section that matters most. A PR without a test plan is a PR that says "trust me." A PR with a clear test plan says "here's exactly how to verify this works." Reviewers can run the steps; automated systems can parse the checklist.

### Optional sections

Add only if relevant:

- **Breaking changes** — what will break, who needs to be notified
- **Rollout** — feature flags, canaries, migration steps
- **Screenshots** — for UI changes only
- **Related issues** — link, don't paraphrase

---

## Multi-Agent Safety Rules

When more than one Claude session, human, or background process can touch the repo, a few commit-level habits prevent cross-contamination.

### Do not touch what you did not change

- `git stash` — never run `stash`, `stash pop`, or `stash drop` unless the user asked. Stashes are another agent's insurance.
- `git checkout <file>` — never discard uncommitted changes in files you didn't modify
- `git clean` — never remove untracked files; they may be another agent's new work

### Do not auto-stash

```bash
# FORBIDDEN
git pull --rebase --autostash

# CORRECT
git status                    # confirm clean
git pull --rebase
```

`--autostash` silently moves uncommitted work onto a stash, does the rebase, and pops the stash. If the pop conflicts, another agent's changes are stuck in the stash list and may be lost.

### Do not switch branches without asking

Another session may have an active branch. Switching branches under them will break their working tree. Ask first, or let them switch when ready.

### Unrecognized files: leave them alone

`git status` shows a file you don't recognize. **Do nothing with it.** It belongs to another agent, the user, or a background tool. Commit your own work, leave theirs untouched, and note "other uncommitted files present" in your report only if it affects the user's next action.

---

## Rebase and Amend Discipline

### Never use `git rebase -i`

Interactive rebase requires a real terminal. Claude Code cannot handle the interactive editor. If you need to squash, reword, or reorder commits, do it through explicit commands or ask the user.

### Never amend a pushed commit

```bash
# FORBIDDEN if the previous commit is pushed
git commit --amend

# CORRECT
git commit -m "fix: followup to <sha>"
```

`--amend` rewrites history. On a pushed branch, force-push is required to sync, and force-push is dangerous on shared branches. New commit instead, always.

### Pre-commit hook failures: new commit, not --amend

If a pre-commit hook fails, **the commit did not happen**. Running `git commit --amend` after a failed commit will modify the *previous* successful commit — likely destroying unrelated work. Fix the issue, stage the fix, create a **new** commit.

---

## Quick Decision Tree

```
Need to ship changes?
  ↓
Is every file in `git status` yours?
  NO  → stash your changes with `git stash -u -m "my-work"`, sort out
         whose files are whose, come back when clean
  YES ↓
One logical change or multiple?
  ONE → /commit-push-pr (if branch+PR) or /commit (if direct to main)
  MANY ↓
Stage and commit each logically-distinct group separately:
  git add <group-1-files>
  git commit -m "..."
  git add <group-2-files>
  git commit -m "..."
  ...
  git push (and open PR manually)
```

---

## See Also

- [Chapter 01 — Plan Mode](/docs/guide/part2-workflow/01-plan-mode/) — post-validation entry after commits
- [Chapter 02 — TDD](/docs/guide/part2-workflow/02-tdd/) — format-lint-test-commit cycle
- [Chapter 04 — Verify and Canary](/docs/guide/part2-workflow/04-verify-canary/) — pre-commit verification
- `commit-commands` plugin — `/commit`, `/commit-push-pr`, `/clean-gone`
