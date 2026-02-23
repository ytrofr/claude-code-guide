---
layout: default
title: "Verification Feedback Loop - /verify Command, verify-app Agent, and Stop Hook"
description: "Boris Cherny's #1 tip for Claude Code: give Claude a way to verify its work. Implements a /verify command with dynamic context injection, a verify-app verification agent, and a Stop hook that nudges verification when source code changes."
---

# Chapter 50: Verification Feedback Loop

Boris Cherny -- author of _Programming TypeScript_ and Anthropic employee -- says his number one tip for Claude Code is: "Give Claude a way to verify its work -- this 2-3x the quality of the final result." This chapter implements that insight with three components: a `/verify` command for interactive verification, a `verify-app` agent for deep automated checks, and a Stop hook that nudges verification when source code changes.

**Purpose**: Give Claude a systematic way to verify its own work before the user sees it
**Source**: Boris Cherny's Claude Code tips + production patterns
**Difficulty**: Beginner to Intermediate
**Prerequisites**: [Chapter 13: Claude Code Hooks](13-claude-code-hooks.md), [Chapter 36: Agents and Subagents](36-agents-and-subagents.md), [Chapter 47: Adoptable Rules and Commands](47-adoptable-rules-and-commands.md)

---

## The Core Insight

Without verification, Claude's workflow is:

```
Make changes --> Move on
```

The user becomes the verifier. They test the endpoint, check the UI, run the test suite, and report back. This creates a slow feedback loop with round-trips between Claude and the user.

With a verification loop, the workflow becomes:

```
Make changes --> Verify they work --> Fix issues --> Report clean result
```

Claude catches its own mistakes before the user ever sees them. The key to making this work is reducing friction. If verification requires remembering a manual checklist, it won't happen consistently. A single command -- `/verify` -- makes it automatic.

This chapter builds three components at increasing levels of automation:

| Component          | What It Does                           | When It Runs              |
| ------------------ | -------------------------------------- | ------------------------- |
| `/verify` command  | Interactive verification with modes    | User types `/verify`      |
| `verify-app` agent | Deep 3-tier verification as a subagent | Spawned by Task() call    |
| Stop hook          | Nudges verification after code changes | Automatically after turns |

---

## Component 1: The /verify Command

The `/verify` command is a slash command (see [Chapter 47](47-adoptable-rules-and-commands.md)) that uses dynamic context injection to pre-compute useful information before Claude processes the prompt. This means Claude sees the git diff, server health, and branch name immediately -- no round-trips needed.

### File Location

```
~/.claude/commands/verify.md      # Global (all projects)
.claude/commands/verify.md        # Project-specific (overrides global)
```

### The Command File

```markdown
---
allowed-tools: Bash, Read, Grep, Glob
description: Verify recent changes with auto-detected scope
---

# Verification: $ARGUMENTS mode

## Pre-computed Context (dynamic injection)

**Branch**: !`git branch --show-current`
**Changed files**:
!`git diff HEAD --name-only`

**Unstaged changes**:
!`git diff --stat`

**Server health** (if running):
!`curl -s -o /dev/null -w "%{http_code}" http://localhost:${PORT:-8080}/health 2>/dev/null || echo "not running"`

## Verification Instructions

Based on the mode argument ("$ARGUMENTS"), run the appropriate verification:

### Mode: quick (default if no argument)

1. Check server health endpoint (if server is running)
2. Verify no syntax errors in changed files (node --check, python -m py_compile, etc.)
3. Report: files changed, health status, any obvious issues

### Mode: deep

1. Everything in "quick" mode
2. Run the project test suite (npm test, pytest, go test, etc.)
3. Check for lint/format issues (if linter configured)
4. Verify no files exceed 500 lines (modularity check)
5. Report: test results, lint status, modularity violations

### Mode: auto (recommended)

1. Detect what changed from the git diff above
2. If only docs/config changed: quick mode
3. If source code changed: deep mode
4. If test files changed: run those specific tests
5. Report: what was detected, what was verified, results

## Output Format

Summarize verification results as:

- PASS: What verified successfully
- FAIL: What failed (with fix suggestions)
- SKIP: What was skipped and why
```

### How Dynamic Injection Works

The `` !`command` `` syntax (see [Chapter 46: Advanced Configuration Patterns](46-advanced-configuration-patterns.md)) runs shell commands at command invocation time -- before Claude processes the prompt. When a user types `/verify`, Claude Code:

1. Runs `git branch --show-current` and injects the result
2. Runs `git diff HEAD --name-only` and injects the file list
3. Runs `curl` against the health endpoint and injects the status code
4. Hands the fully-rendered prompt to Claude with all context pre-computed

This eliminates the first round of tool calls Claude would otherwise need. Instead of: "Let me check what changed... [Bash] git diff... OK now let me check health... [Bash] curl...", Claude sees the diff and health status immediately and jumps straight to verification.

**Critical: The correct syntax is `` !`command` `` (exclamation mark followed by a backtick-wrapped command).** An earlier version of this chapter used the `$!command!$` syntax, which does not work. The preprocessor looks for `` !`...` `` patterns -- an exclamation mark immediately followed by a backtick-delimited command. Keep injections as bare text in the markdown:

```markdown
<!-- CORRECT: !`command` syntax -->

**Branch**: !`git branch --show-current`

<!-- WRONG: $!...!$ does not work -->

**Branch**: $!git branch --show-current!$

<!-- WRONG: code fence prevents execution -->

**Branch**: `!`git branch --show-current``
```

### Usage

```bash
# Auto-detect mode (recommended)
/verify auto

# Quick health check only
/verify quick

# Full verification with tests
/verify deep

# No argument defaults to quick
/verify
```

---

## Component 2: The verify-app Agent

The `/verify` command is for interactive use -- the user types it. The `verify-app` agent is for programmatic use -- Claude spawns it as a subagent via `Task()` when it wants to verify its own work without user intervention.

### File Location

```
~/.claude/agents/verify-app.md      # Global (all projects)
.claude/agents/verify-app.md        # Project-specific (overrides global)
```

### The Agent File

````markdown
---
model: sonnet
allowed_tools:
  - Bash
  - Read
  - Grep
  - Glob
permissionMode: auto
memory: project
---

# verify-app: 3-Tier Verification Agent

You are a verification agent. Your job is to verify that recent code changes
work correctly. You run three tiers of checks, each building on the last.
If an earlier tier fails, skip later tiers and report immediately.

## Tier 1: Static Analysis (always runs)

Detect the tech stack from the project root:

- Node.js: check for package.json
- Python: check for requirements.txt, pyproject.toml, or setup.py
- Go: check for go.mod
- Rust: check for Cargo.toml

Then run static checks appropriate to the stack:

- Node.js: `node --check` on changed .js files, `npx tsc --noEmit` if tsconfig exists
- Python: `python -m py_compile` on changed .py files
- Go: `go vet ./...`
- All: Check for files >500 lines, check for conflict markers (<<<<<<)

## Tier 2: Health Endpoints (if server is running)

Check if a dev server is running:

- Try common ports: 8080, 3000, 5173, 4000, 8000
- Hit /health or / endpoint
- If server responds: verify HTTP 200
- If server is not running: skip this tier (not a failure)

## Tier 3: Test Suite (if tests exist)

Detect and run tests:

- Node.js: `npm test` (if test script exists in package.json)
- Python: `pytest` (if pytest installed) or `python -m unittest discover`
- Go: `go test ./...`
- If no test infrastructure: skip this tier

## Output Format

Report results as a structured summary:

```
VERIFICATION RESULTS
====================
Tier 1 (Static):  PASS / FAIL (details)
Tier 2 (Health):  PASS / FAIL / SKIP (details)
Tier 3 (Tests):   PASS / FAIL / SKIP (details)

Issues Found:
- [list any failures with file paths and error messages]

Suggested Fixes:
- [actionable fix for each issue]
```
````

### When to Use the Agent vs the Command

| Situation                           | Use             | Why                                        |
| ----------------------------------- | --------------- | ------------------------------------------ |
| User wants to verify interactively  | `/verify`       | Direct, fast, user sees results in-line    |
| Claude wants to self-check          | `verify-app`    | Fresh context, doesn't pollute main window |
| After a multi-step plan             | `verify-app`    | Subagent verifies all changes at once      |
| Quick sanity check mid-conversation | `/verify quick` | Lightweight, no subagent overhead          |
| CI-like verification before commit  | `verify-app`    | Thorough, 3-tier, reports structured       |

### Spawning the Agent

Claude (or a rule) can spawn the verification agent like this:

```
Task(subagent_type: "verify-app",
  prompt: "Verify the changes I just made to src/routes/auth.routes.js
    and src/services/auth.service.js. Check that the server is healthy
    and tests pass.")
```

The agent gets a fresh context window, runs all three tiers, and reports back without consuming the main conversation's context budget.

---

## Component 3: The Stop Hook

The Stop hook is the gentlest component. It runs after every Claude turn and checks whether source code was changed. If so, it suggests running `/verify`. It does not force verification -- it nudges.

### The Hook Script

Create this file at `~/.claude/hooks/stop-verify-nudge.sh`:

```bash
#!/bin/bash
# Stop hook: suggest /verify when source code changes detected
# Runs after each Claude turn completes

# Count changed files (staged + unstaged)
CHANGED_FILES=$(git diff --name-only HEAD 2>/dev/null | wc -l)

# Count source code files specifically
SRC_CHANGES=$(git diff --name-only HEAD 2>/dev/null | grep -cE '\.(js|ts|py|go|rs|java|rb|php|jsx|tsx|vue|svelte)$')

# Build suggestion message
if [ "$SRC_CHANGES" -gt 0 ]; then
  echo "[$SRC_CHANGES source file(s) changed] Consider running /verify to check your work."
elif [ "$CHANGED_FILES" -gt 5 ]; then
  echo "[$CHANGED_FILES files changed] Consider running /verify quick for a health check."
fi

# Always exit 0 -- hook should never block Claude
exit 0
```

Make it executable:

```bash
chmod +x ~/.claude/hooks/stop-verify-nudge.sh
```

### Wiring the Hook

Add the Stop hook to your settings file. For global use, edit `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/stop-verify-nudge.sh"
          }
        ]
      }
    ]
  }
}
```

For project-specific use, add the same block to `.claude/settings.json` in your repo.

### How It Works

1. Claude finishes a turn (writes code, edits files, etc.)
2. The Stop event fires
3. The hook script runs `git diff --name-only HEAD` to see what changed
4. If source files changed: suggests `/verify`
5. If many files changed but no source: suggests `/verify quick`
6. If nothing significant changed: outputs nothing (silent)

The hook is async -- it does not block Claude's response. See [Chapter 13](13-claude-code-hooks.md) for details on hook execution.

### Why a Nudge, Not a Gate

The Stop hook could force verification by returning an error or blocking the response. It does not do this for three reasons:

1. **Not every turn needs verification.** Reading files, searching code, and answering questions do not produce code changes.
2. **Forced verification is annoying.** Users will disable it after the third unnecessary check.
3. **The nudge is sufficient.** Seeing "[3 source files changed] Consider running /verify" is enough to remind Claude (or the user) to verify. If ignored, no harm done.

---

## Global vs Project Scope

All three components support both global and project-level installation.

### Two-Layer Pattern

```
~/.claude/                           .claude/
  commands/verify.md        <-->       commands/verify.md
  agents/verify-app.md      <-->       agents/verify-app.md
  hooks/stop-verify-nudge.sh          hooks/stop-verify-nudge.sh
  settings.json                        settings.json
```

**Global** (`~/.claude/`): Generic, auto-detects tech stack, works with any project. Install once, use everywhere.

**Project** (`.claude/`): Can add project-specific checks -- custom health endpoints, specific test suites, Sacred compliance validation, linter configurations. Gets committed to the repo so the whole team benefits.

**Override rule**: When both exist, the project-level version takes precedence. This lets you install a generic global `/verify` and override it in specific projects that need custom checks.

### Recommended Approach

1. Install all three components globally (generic versions)
2. In projects that need custom verification, create a project-level `.claude/commands/verify.md` that adds project-specific checks
3. Leave the global agent and hook as-is (they auto-detect)

---

## Adoptable Templates

These are the copy-paste versions of all three components.

### Template 1: /verify Command

Save to `~/.claude/commands/verify.md`:

```markdown
---
allowed-tools: Bash, Read, Grep, Glob
description: Verify recent changes with auto-detected scope
---

# Verification: $ARGUMENTS mode

## Context

**Branch**: !`git branch --show-current`
**Changed files**:
!`git diff HEAD --name-only`
**Server**: !`curl -s -o /dev/null -w "%{http_code}" http://localhost:${PORT:-8080}/health 2>/dev/null || echo "not running"`

## Instructions

Mode "$ARGUMENTS" (default: quick):

- **quick**: Health check + syntax check on changed files
- **deep**: Quick + test suite + lint + modularity (500-line limit)
- **auto**: Detect from changed files (docs=quick, source=deep, tests=run them)

Report as PASS / FAIL / SKIP for each check.
```

### Template 2: verify-app Agent

Save to `~/.claude/agents/verify-app.md`:

```markdown
---
model: sonnet
allowed_tools:
  - Bash
  - Read
  - Grep
  - Glob
permissionMode: auto
memory: project
---

# Verification Agent

Run 3-tier verification on recent changes:

1. **Static** (always): syntax check changed files, conflict markers, file size >500L
2. **Health** (if server running): hit health endpoint on ports 8080/3000/5173/8000
3. **Tests** (if test infra exists): npm test / pytest / go test

Auto-detect tech stack from package.json / requirements.txt / go.mod / Cargo.toml.

Report: PASS/FAIL/SKIP per tier, list issues, suggest fixes.
```

### Template 3: Stop Hook Script

Save to `~/.claude/hooks/stop-verify-nudge.sh` and run `chmod +x` on it:

```bash
#!/bin/bash
CHANGED=$(git diff --name-only HEAD 2>/dev/null | wc -l)
SRC=$(git diff --name-only HEAD 2>/dev/null | grep -cE '\.(js|ts|py|go|rs|java|rb|jsx|tsx)$')
if [ "$SRC" -gt 0 ]; then
  echo "[$SRC source file(s) changed] Consider running /verify to check your work."
elif [ "$CHANGED" -gt 5 ]; then
  echo "[$CHANGED files changed] Consider running /verify quick."
fi
exit 0
```

### Template 4: settings.json Hook Wiring

Add to `~/.claude/settings.json` (merge with existing hooks if present):

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/stop-verify-nudge.sh"
          }
        ]
      }
    ]
  }
}
```

---

## Design Decisions

### Why dynamic injection (`` !`command` ``) in the command

The `` !`git diff HEAD --name-only` `` syntax runs at command invocation time, not when Claude processes the prompt. This eliminates an entire round-trip. Without it, Claude would need to call `Bash("git diff HEAD --name-only")` as its first action, wait for the result, then proceed. With dynamic injection, the diff is already in the prompt. Zero round-trips for context gathering.

One important caveat: the `` !`...` `` preprocessor only finds injections written as bare text in the markdown. If the injection is nested inside another code fence or escaped, it renders as literal text instead of being executed. See the "How Dynamic Injection Works" section above for the correct format. Note that an earlier draft of this chapter used the `$!command!$` syntax, which does not work -- the correct syntax is `` !`command` ``.

### Why the Stop hook is async

Stop hooks run after Claude's response is complete. They cannot modify the response -- they can only append output that Claude sees on the next turn. This is by design. A synchronous verification gate would slow every response, even ones that don't change code. The async nudge only costs anything when it has something useful to say.

### Why auto-detect mode in both command and agent

Requiring the user to specify "this is a Node.js project, run npm test" defeats the purpose. Both the command and agent detect the tech stack from project files (package.json, go.mod, etc.) and choose the right tools. This means `/verify` works in any project without configuration.

### Why 3 tiers in the agent with graceful degradation

Not every project has a running server. Not every project has tests. The 3-tier design means:

- Tier 1 (static) always runs -- every project has source files to check
- Tier 2 (health) runs only if a server responds -- skipped if no server
- Tier 3 (tests) runs only if test infrastructure exists -- skipped if no tests

A "SKIP" is not a failure. It means the check was not applicable.

---

## Key Takeaways

1. **Make verification a single command.** The `/verify` command reduces a multi-step checklist to one action. Dynamic injection (`` !`command` ``) pre-computes context so Claude can verify immediately with zero round-trips.
2. **Use a dedicated agent for deep checks.** The `verify-app` agent runs in a fresh context window, so verification does not consume your main conversation's context budget. Spawn it via `Task()` after multi-step changes.
3. **Nudge, don't gate.** The Stop hook detects source code changes and suggests verification without forcing it. This keeps the workflow lightweight while building a verification habit.
4. **Layer global and project scope.** Install generic versions globally, override with project-specific checks where needed. The global versions auto-detect tech stack and work everywhere.

---

**Previous**: [49: Workflow Resilience Patterns](49-workflow-resilience-patterns.md)
