---
layout: default
title: "Persistent Memory Patterns — Auto-Observation, Session Summary, and Progressive Disclosure"
description: "Inspired by claude-mem (30K+ stars): automatically capture every meaningful action to Basic Memory MCP, generate session summaries at end-of-session, and use progressive disclosure search to save 10x tokens."
---

# Chapter 51: Persistent Memory Patterns

[claude-mem](https://github.com/thedotmack/claude-mem) (30K+ GitHub stars) popularized the idea of automatically capturing every tool call Claude makes, compressing them with AI, and injecting context into future sessions. The core insight: **sessions are ephemeral, but knowledge should persist**.

This chapter adapts that insight for the Claude Code hook system — without a worker service, without a separate database, and without per-call AI processing. Four patterns work together to make every session contribute to a growing knowledge base.

**Purpose**: Automatically persist session knowledge to Basic Memory MCP with zero manual effort
**Source**: claude-mem architecture + Claude Code hook patterns
**Difficulty**: Intermediate
**Prerequisites**: [Chapter 13: Claude Code Hooks](13-claude-code-hooks.md), [Chapter 34: Basic Memory MCP Integration](34-basic-memory-mcp-integration.md)

---

## The Problem: Sessions Are Ephemeral

Without persistent memory, every session starts from scratch:

```
Session 1: Debug timezone bug → fix → commit → context compaction
Session 2: See similar bug → investigate from scratch → 45 min wasted
Session 3: "How did we fix that timezone issue?" → no memory
```

Memory MCP solves this — but only if you write to it. The gap is that writing requires manual effort, and manual effort is skipped under time pressure.

claude-mem's solution: **make capture automatic**.

---

## Pattern 1: Auto-Observation (PostToolUse Hook)

The first pattern captures every meaningful action automatically, without any per-call AI processing.

### Design Decisions

**Selective capture — not everything**. Capturing every Read, Glob, Grep, WebFetch call produces noise. The rule:

- `Edit`, `Write`, `NotebookEdit` → always capture (file was modified)
- `Bash` → capture only significant commands: `git commit`, `git push`, `gcloud run deploy`, `npm test`, `npm run`
- Everything else → skip silently

**JSONL format, not markdown**. Machine-readable, append-only, fast. The session summary hook reads this at session end.

**Async, <50ms**. Never block the main Claude Code flow.

### Implementation

Create `~/.claude/hooks/auto-observation.sh`:

```bash
#!/bin/bash
# Auto-Observation Hook — Global PostToolUse
# Captures Edit/Write/significant Bash to JSONL for session summary

JSON_INPUT=$(cat 2>/dev/null || echo '{}')
TOOL_NAME=$(echo "$JSON_INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
SESSION_ID=$(echo "$JSON_INPUT" | jq -r '.session_id // empty' 2>/dev/null)

OBS_DIR="$HOME/.claude/session-observations"
mkdir -p "$OBS_DIR"
OBS_FILE="$OBS_DIR/${SESSION_ID:-unknown}.jsonl"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Selective capture
case "$TOOL_NAME" in
    Edit|Write|NotebookEdit)
        ACTION_TYPE="file_change"
        CONTEXT=$(echo "$JSON_INPUT" | jq -c '{file: (.tool_input.file_path // .tool_input.notebook_path // "unknown")}' 2>/dev/null || echo '{}')
        ;;
    Bash)
        BASH_CMD=$(echo "$JSON_INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
        case "$BASH_CMD" in
            *"git commit"*|*"git push"*|*"gcloud run deploy"*|*"npm test"*|*"npm run"*)
                ACTION_TYPE="command"
                CONTEXT=$(echo "$JSON_INPUT" | jq -c '{cmd: .tool_input.command}' 2>/dev/null || echo '{}')
                ;;
            *)
                exit 0  # Skip routine bash
                ;;
        esac
        ;;
    *)
        exit 0  # Skip Read, Glob, Grep, WebFetch, etc.
        ;;
esac

echo "{\"ts\":\"${TIMESTAMP}\",\"type\":\"${ACTION_TYPE}\",\"tool\":\"${TOOL_NAME}\",\"ctx\":${CONTEXT:-\{\}}}" >> "$OBS_FILE"
exit 0
```

Register in `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "/home/you/.claude/hooks/auto-observation.sh",
            "async": true
          }
        ]
      }
    ]
  }
}
```

The `async: true` field is critical — it runs the hook in the background, never blocking Claude.

---

## Pattern 2: Auto Session Summary (SessionEnd Hook)

At session end, read the JSONL observations plus git history, and write a structured note to Basic Memory.

### What It Captures

```
git log --oneline --since="2 hours ago"   → commits this session
git log --name-only ...                    → files changed
session-observations/{session_id}.jsonl   → tool actions captured
git diff --stat HEAD~3                     → diff stats
```

### Implementation

Create `~/.claude/hooks/auto-session-summary.sh`:

```bash
#!/bin/bash
# Auto Session Summary — Global SessionEnd Hook
# Writes session summary to ~/basic-memory/session-summaries/

JSON_INPUT=$(timeout 2 cat 2>/dev/null || echo '{}')
SESSION_ID=$(echo "$JSON_INPUT" | jq -r '.session_id // empty' 2>/dev/null)

PROJECT_NAME=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || basename "$PWD")
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
TODAY=$(date +%Y-%m-%d)
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)

MEMORY_DIR="$HOME/basic-memory/session-summaries"
mkdir -p "$MEMORY_DIR"

SESSION_COMMITS=$(git log --oneline --since="2 hours ago" --no-merges 2>/dev/null | head -10)
FILES_CHANGED=$(git log --name-only --pretty=format: --since="2 hours ago" --no-merges 2>/dev/null | sort -u | grep -v '^$' | head -20)
DIFF_STATS=$(git diff --stat HEAD~3 2>/dev/null | tail -1)

OBS_LOG="$HOME/.claude/session-observations/${SESSION_ID:-unknown}.jsonl"
OBS_SUMMARY=""
if [ -f "$OBS_LOG" ]; then
    OBS_COUNT=$(wc -l < "$OBS_LOG")
    OBS_FILES=$(jq -r '.ctx.file // empty' "$OBS_LOG" 2>/dev/null | sort -u | head -10)
    OBS_SUMMARY="Observations: ${OBS_COUNT} actions captured"
    [ -n "$OBS_FILES" ] && OBS_SUMMARY="${OBS_SUMMARY}
Files touched: ${OBS_FILES}"
fi

# Skip if nothing happened
if [ -z "$SESSION_COMMITS" ] && [ -z "$FILES_CHANGED" ] && [ -z "$OBS_SUMMARY" ]; then
    exit 0
fi

SLUG=$(echo "${PROJECT_NAME}-${CURRENT_BRANCH}" | tr '/' '-' | tr ' ' '-')
FILENAME="Session Summary - ${TODAY} - ${SLUG} - Auto"
COUNTER=1
while [ -f "${MEMORY_DIR}/${FILENAME}.md" ]; do
    FILENAME="Session Summary - ${TODAY} - ${SLUG} - Auto ${COUNTER}"
    COUNTER=$((COUNTER + 1))
done

cat > "${MEMORY_DIR}/${FILENAME}.md" << SUMMARY_EOF
# ${FILENAME}

**Project**: ${PROJECT_NAME}
**Branch**: ${CURRENT_BRANCH}
**Date**: ${TODAY}
**Session**: ${SESSION_ID:-unknown}
**Auto-generated**: ${NOW}

## Commits

${SESSION_COMMITS:-No commits this session}

## Files Changed

${FILES_CHANGED:-No files changed}

## Stats

${DIFF_STATS:-No diff stats}

## Observations

${OBS_SUMMARY:-No observations captured}

- [change] Auto-generated session summary for ${PROJECT_NAME}/${CURRENT_BRANCH} on ${TODAY} #session-summary
- relates to [[${PROJECT_NAME}]]
- relates to [[${CURRENT_BRANCH}]]
SUMMARY_EOF

echo "Auto-summary: session-summaries/${FILENAME}"

# Cleanup
rm -f "$OBS_LOG"
find "$HOME/.claude/session-observations/" -name "*.jsonl" -mtime +7 -delete 2>/dev/null

exit 0
```

Register in `~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/home/you/.claude/hooks/auto-session-summary.sh",
            "async": true
          }
        ]
      }
    ]
  }
}
```

---

## Pattern 3: Progressive Disclosure Search

Basic Memory MCP has three retrieval tools that form a natural progression. Most users skip straight to the most expensive one.

### The 3-Layer Workflow

```
NEVER fetch full content without filtering first
```

| Layer       | Tool                               | Returns           | Tokens      | Use When                                        |
| ----------- | ---------------------------------- | ----------------- | ----------- | ----------------------------------------------- |
| 1 — Index   | `search(query)`                    | IDs + titles only | ~50/result  | Exploring — don't know which notes are relevant |
| 2 — Preview | `search_notes(query, page_size=5)` | Truncated preview | ~200/result | Need to scan before committing to full read     |
| 3 — Full    | `fetch(id="folder/note-title")`    | Complete note     | ~500-1000   | After filtering — you know exactly which note   |

### Token Savings Example

```
Bad:  search_notes(page_size=10) = ~2,000 tokens (mostly irrelevant)
Good: search() → pick 2 IDs → fetch(id) × 2 = ~200 tokens (targeted)
Savings: 10x reduction
```

### When To Skip Layers

```yaml
EXCEPTIONS:
  - build_context(url='memory://folder/*') is fine for small folders (<10 notes)
  - read_note() is fine when you know the exact title
```

### Add As A Global Rule

Create `~/.claude/rules/mcp/memory-search-patterns.md`:

```markdown
# Memory Search Patterns - Progressive Disclosure

RULE: NEVER fetch full content without filtering first. Use the 3-layer workflow:

Layer 1 — search(query="topic") → IDs only (~50 tokens per result)
Layer 2 — search_notes(query, page_size=5) → previews (~200 tokens per result)
Layer 3 — fetch(id="folder/note-title") → full note (~500-1000 tokens)

TOKEN_SAVINGS:
Bad: search_notes(page_size=10) = ~2,000 tokens (mostly irrelevant)
Good: search() → pick 2 IDs → fetch(id) x2 = ~200 tokens (targeted)
Savings: 10x reduction
```

---

## Pattern 4: Observation Taxonomy

When writing observations to Basic Memory, inconsistent tagging makes retrieval unreliable. Standardize with these 6 types and 5 concepts.

### 6 Observation Types

| Tag           | Meaning                                    |
| ------------- | ------------------------------------------ |
| `[bugfix]`    | Something was broken, now fixed            |
| `[feature]`   | New capability or functionality added      |
| `[refactor]`  | Code restructured, behavior unchanged      |
| `[change]`    | Generic modification (docs, config, misc)  |
| `[discovery]` | Learning about existing system             |
| `[decision]`  | Architectural/design choice with rationale |

### 5 Observation Concepts

| Tag                 | Meaning                         |
| ------------------- | ------------------------------- |
| `#how-it-works`     | Understanding mechanisms        |
| `#problem-solution` | Issues and their fixes          |
| `#gotcha`           | Traps or edge cases to remember |
| `#pattern`          | Reusable approach               |
| `#trade-off`        | Pros/cons of a decision         |

### Format

```
- [type] Description of what happened #concept #domain
```

### Examples

```
- [bugfix] Fixed timezone offset in cron job #problem-solution #deployment
- [decision] Use Cloud Scheduler not in-process crons #trade-off #deployment
- [discovery] Basic Memory search() returns IDs only — 10x savings #how-it-works #context
- [feature] Added kNN hybrid fusion for RAG tier selection #pattern #ai
- [change] Updated memory-search-patterns.md with 3-layer workflow #change #documentation
```

---

## Revalidation Before Building

A critical step in adopting claude-mem's patterns: check what already exists before implementing. In the original project, revalidation found:

| Pattern                      | First Assessment | After Revalidation                           |
| ---------------------------- | ---------------- | -------------------------------------------- |
| Auto-Observation PostToolUse | Missing          | TRUE gap — implement                         |
| Progressive Disclosure       | Missing          | DOWNGRADED — tools existed, only needed rule |
| Observation Taxonomy         | Missing          | DOWNGRADED — partial, just standardize       |
| Auto Session Summary         | Missing          | VALIDATED — clearest win                     |

Two of four patterns turned out to already have the underlying tools — they just needed rules to enforce their use. **The lesson: check what exists before building.**

---

## Global vs Project Scope

All four patterns should live in `~/.claude/` (global), not `.claude/` (project-specific):

```
~/.claude/hooks/auto-observation.sh       ← works for ANY project
~/.claude/hooks/auto-session-summary.sh   ← works for ANY project with git
~/.claude/rules/mcp/memory-search-patterns.md  ← applies to all sessions
~/.claude/settings.json                   ← registers global hooks
```

If you previously had observation hooks at the project level, remove them and register globally. Duplicate hooks run twice — producing duplicate JSONL entries and double-writing session summaries.

---

## E2E Verification

After implementation, verify all four patterns are working:

```bash
# 1. Hook syntax
bash -n ~/.claude/hooks/auto-observation.sh && echo "PASS"
bash -n ~/.claude/hooks/auto-session-summary.sh && echo "PASS"

# 2. Settings JSON is valid
jq '.' ~/.claude/settings.json > /dev/null && echo "PASS"

# 3. Global hooks are registered
jq '.hooks.PostToolUse[] | select(.hooks[].command | contains("auto-observation"))' \
  ~/.claude/settings.json | grep -q "auto-observation" && echo "PASS"
jq '.hooks.SessionEnd[] | select(.hooks[].command | contains("auto-session-summary"))' \
  ~/.claude/settings.json | grep -q "auto-session-summary" && echo "PASS"

# 4. No duplicate hooks at project level
if grep -q "auto-observation" .claude/settings.json 2>/dev/null; then
  echo "FAIL — remove project-level duplicate"
else
  echo "PASS"
fi

# 5. Trigger a capture (make a small edit, check JSONL)
echo "test" >> /tmp/test.txt  # Claude Edit action triggers hook
ls ~/.claude/session-observations/
# Should see a .jsonl file with today's session
```

---

## The Design: No Worker Service Required

claude-mem uses a worker service on port 37777 that receives tool events, runs an AI agent to compress them, and stores results in SQLite + Chroma. This is powerful but adds infrastructure complexity.

The hook-based approach trades AI compression for simplicity:

| Aspect         | claude-mem                  | Hook approach               |
| -------------- | --------------------------- | --------------------------- |
| Capture        | Worker service (port 37777) | PostToolUse hook (bash)     |
| Storage        | SQLite + Chroma DB          | Basic Memory MCP (markdown) |
| Compression    | AI agent per call           | None (raw git + file data)  |
| Injection      | Custom context system       | Basic Memory MCP search     |
| Infrastructure | Worker process required     | None                        |
| Cost           | Per-call AI processing      | Zero                        |

For most projects, the hook approach delivers 80% of the value at 10% of the complexity.

---

## Connecting The Patterns

The four patterns form a loop:

```
Every tool call
    ↓ (PostToolUse hook)
JSONL observation log
    ↓ (SessionEnd hook)
Basic Memory session summary note
    ↓ (Progressive disclosure search)
Retrieved with search() → filtered → fetch()
    ↓ (Taxonomy tags)
Consistently tagged for reliable retrieval
    ↑
Next session
```

Each session feeds the next. After a few weeks, Basic Memory becomes a reliable source of "how did we solve X?" — reducing re-investigation to a search query instead of a 45-minute dig.

---

**See Also**:

- [Chapter 13: Claude Code Hooks](13-claude-code-hooks.md)
- [Chapter 34: Basic Memory MCP Integration](34-basic-memory-mcp-integration.md)
- [Chapter 42: Session Memory Compaction](42-session-memory-compaction.md)
- [Chapter 48: Lean Orchestrator Pattern](48-lean-orchestrator-pattern.md)
