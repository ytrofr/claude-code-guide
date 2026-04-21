---
layout: default
title: "First Session Walkthrough"
parent: "Part I — Foundation"
nav_order: 4
---

# First Session Walkthrough

You've installed the best-practices package (Core or Recommended) and written a CLAUDE.md. Now what? This chapter walks through a complete first session end to end: start Claude Code, give it a task, plan, implement, verify, end the session. About 30 minutes.

**Purpose**: End-to-end orientation for your first real work session
**Difficulty**: Beginner
**Prerequisites**: Core tier or higher installed ([Part I/01](01-installation.md))

---

## Step 1: Install and Pick a Project

If you haven't already, install the Core tier in a project. Any real project works; if you don't have one handy, `mkdir ~/firstrun && cd ~/firstrun && git init && npm init -y` gives you a scratch project.

```bash
curl -sL https://raw.githubusercontent.com/ytrofr/claude-code-guide/master/install.sh | bash
```

For Recommended, clone and run `./install.sh --recommended` instead (see [Part I/01](01-installation.md)).

---

## Step 2: Start Claude Code

From the project directory:

```bash
cd ~/firstrun
claude
```

Claude Code starts. You'll see a welcome prompt and the model will auto-load:

- Your `CLAUDE.md` (always-on context)
- All rules from `~/.claude/rules/` and `.claude/rules/`
- All skill descriptions from both scopes
- Any `SessionStart` hooks (Core installs `memory-context-loader.sh`)

The first-session context load is usually 20-80K chars of always-on content. You can inspect it anytime with `/context`.

---

## Step 3: Write a Minimal CLAUDE.md

If the installer didn't create one (or you're on a fresh project), make a tiny one. Remember: under 2K characters, only project-specific facts (see [Part I/02](02-claude-md-primer.md)).

```markdown
# Firstrun - Project Instructions

**Purpose**: Scratch project for learning Claude Code

## Stack
- Node.js 20
- No deps yet

## Commands
- `npm test` - run tests (once we have them)

@.claude/best-practices/BEST-PRACTICES.md
```

Save it. It's auto-loaded on the next session start, but for this session you can also ask Claude to re-read it:

```
Re-read CLAUDE.md
```

---

## Step 4: Warm Up with `/session-start`

If you installed the Recommended tier (or added the `session-start` skill from Core), invoke it:

```
/session-start
```

This skill runs a short discovery pass -- checks git status, reads recent commits, identifies any pending work. It's the Anthropic-recommended "orient before you act" pattern. On a fresh project it won't have much to say; on a real project mid-flight, it catches you up in ~30 seconds.

If you're on pure Core and don't have the skill, you can manually ask:

```
Check git status and summarize where the project is.
```

Either way, you've grounded the session in current reality before asking for work.

---

## Step 5: Ask Claude About the Codebase

Try an exploratory question to confirm Claude sees your project correctly:

```
What does this project do? What's the stack?
```

Claude should answer from your CLAUDE.md. If it hallucinates or gives a generic answer, something is wrong -- check that CLAUDE.md is at the project root or `.claude/CLAUDE.md`, and that you're running `claude` from the project directory.

Then try something concrete:

```
List the files in src/. What's the entry point?
```

Claude uses the `Glob` and `Read` tools to answer. You'll see tool invocations inline -- that's normal. The transparency is deliberate: you can see exactly what Claude is doing.

---

## Step 6: Plan a Small Feature with `/plan`

Now the real work. Pick a small task -- something that would take you 15-30 minutes. For this walkthrough: "Add a `greet` function that returns a greeting by name."

Enter plan mode:

```
/plan
```

(Or press `Shift+Tab` to cycle to plan mode, or type the request and Claude will offer to plan first for non-trivial work.)

Then:

```
Add a `greet(name)` function in src/greet.js that returns "Hello, <name>!". Handle empty/undefined names with "Hello, world!". Export it.
```

Claude produces a written plan -- the sections you'll see depend on tier, but at minimum:

- What will be created/modified
- Test approach
- Files affected

Read the plan. If it misses something ("but I wanted TypeScript" / "but export it as default") push back *before* accepting. Plan mode exists specifically so you catch mismatches before code is written.

When the plan is right, accept it. Claude exits plan mode and starts implementing.

For the full 14-section plan structure (used by `/plan-checklist` in Recommended tier), see [Part II/01 — Plan Mode](../part2-workflow/01-plan-mode.md).

---

## Step 7: Let Claude Implement

Claude writes `src/greet.js`, maybe a test file, and tells you what changed. You'll see each `Write` and `Edit` tool call. No commits yet -- Claude doesn't commit unless you ask.

Open the file and read it. Does it match the plan? Does the test cover edge cases? If something is off, say so:

```
The test for undefined name is missing. Add it.
```

Claude updates. This conversational iteration is the core workflow.

---

## Step 8: Verify with `/verify`

When implementation feels done, don't take Claude's word for it -- verify.

```
/verify
```

The `verify` skill auto-detects what's present (tests, linter, type checker, health endpoints) and runs them. It reports what passed, what failed, and what it couldn't check. On a tiny project it might run `npm test`, check git status, and confirm files were created. On a larger project it runs the whole local validation suite.

**Always `/verify` before claiming done.** This is the gate between "I think it works" and "I watched it pass." See [Part II/04 — Verify and Canary](../part2-workflow/04-verify-canary.md) for the full verification methodology.

If verify fails, you iterate: read the error, fix (or ask Claude to fix), verify again. Loop until green.

---

## Step 9: Commit

Once green:

```
Commit these changes.
```

Claude stages only the files it changed (never `git add -A`), writes a commit message that follows your repo's convention (it reads `git log` to learn the style), and shows you the diff before committing. You approve; Claude commits.

See [Part II/06 — Commit and PR](../part2-workflow/06-commit-and-pr.md) for the deeper commit workflow -- branch hygiene, PR creation, scoped commits under multi-agent contention.

---

## Step 10: End the Session

Recommended tier users:

```
/session-end
```

This writes a session summary to `~/.claude/projects/<cwd>/sessions/`, captures learnings, and suggests `/document` for any patterns worth promoting to rules or skills. On Core, you can just close the terminal -- session state is preserved for `--resume` anyway.

Before ending, one good habit: glance at `/cost`. Cost per session tells you whether your setup is efficient (under $1 for most single-feature sessions) or bloated (multiple dollars for trivial work usually means your always-on context is too fat -- see [Part IV/04 — Context Budget](../part4-context-engineering/04-context-budget.md)).

---

## What You Just Did

In one session you:

1. Launched Claude Code with a curated rules+skills+hooks setup
2. Authored a lean CLAUDE.md as project context
3. Used `/session-start` to orient
4. Planned a feature with `/plan` (catching mismatches before coding)
5. Watched Claude implement with visible tool calls
6. Verified with `/verify` (no "it works on my machine")
7. Committed scoped changes
8. Wrapped up with `/session-end`

That loop -- orient, plan, implement, verify, commit, wrap -- is the entire core workflow. Everything else in this guide is either making a step better (richer plans, better verification, safer commits) or adding new capabilities (MCP servers, subagents, memory, governance).

---

## Next Steps

### Upgrade tiers

If you started on Core and want more, clone the repo and re-run the installer with `--recommended` or `--full`. The installer is idempotent -- it won't touch your CLAUDE.md or custom rules, just adds what's missing. See [Part I/01 — Installation](01-installation.md).

### Add MCP servers

MCP servers give Claude Code external capabilities -- GitHub, PostgreSQL, Basic Memory, Perplexity, Playwright. Register them with `claude mcp add` (not via settings.json -- those are silently ignored). See [Part VI/05 — MCP Server Catalog](../part6-reference/05-mcp-server-catalog.md) and [Part III/03 — MCP Servers](../part3-extension/03-mcp-servers.md) (when available).

### Explore Part II

Part II goes deep on the daily workflow -- plan mode sections, TDD cycle, brainstorming, verify/canary, session lifecycle, commit and PR. If the workflow above felt useful, Part II makes every step sharper.

### Run into trouble

Setup issues land in [Part I/05 — Setup Troubleshooting](05-setup-troubleshooting.md). Runtime issues (skills not activating, hooks not firing, MCP not connecting) are a search away in the global rules -- or ask Claude: "Why isn't `/verify` being found?" The troubleshooting skills route to specific fixes.

---

## Checklist

You've finished the first session successfully when:

- [ ] `claude --version` runs and shows a current version
- [ ] `/skills` inside Claude Code lists your installed skills
- [ ] Claude references your CLAUDE.md when asked "what does this project do?"
- [ ] `/plan` produces a written plan you can accept or reject
- [ ] `/verify` runs and reports pass/fail
- [ ] A commit was created with just the files you changed
- [ ] You know where to go next

That's it. You're set up. Go build something.
