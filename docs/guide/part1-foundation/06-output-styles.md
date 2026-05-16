---
layout: default
title: "Output Styles"
parent: "Part I — Foundation"
nav_order: 6
---

# Output Styles

Output styles are how you change *the way Claude communicates with you* without changing *what Claude is allowed to do*. They replace parts of Claude Code's default system prompt with your own framing, and they persist across sessions once set. They are the cleanest, lowest-risk way to enforce a writing pattern (e.g. problem-first explanations, no jargon up front) globally or per-project.

**Purpose**: Pick or author the output style that matches how you want to read Claude's responses
**Difficulty**: Beginner
**Applies to**: Any project using Claude Code 2.1.x

---

## What an Output Style Is

An output style is a Markdown file with YAML frontmatter that Claude Code loads into the system prompt at session start. It can replace the default coding-assistant framing entirely, or sit alongside it via the `keep-coding-instructions: true` frontmatter flag.

Three things you can do with output styles:

1. **Pick a built-in**: `Default`, `Explanatory`, `Learning` ship with Claude Code.
2. **Author a custom style**: drop a `.md` file in the right directory and it appears in the picker after a restart.
3. **Toggle between them**: switch styles via `/config` -- the choice is persisted to `settings.json`.

Output styles are not slash commands, not hooks, and not agents. They are a single config setting that swaps a chunk of system-prompt text.

---

## Output Styles vs CLAUDE.md vs `--append-system-prompt`

These three mechanisms all "shape Claude's behavior" but they are not interchangeable.

| Mechanism | What it does | Persistence | Best for |
|---|---|---|---|
| **Output style** | Replaces parts of the default system prompt | Saved to `settings.json`, survives restarts | Communication style, response shape, role/tone |
| **CLAUDE.md** | Adds a user-message block after the default system prompt | Per-project file, every session | Project-specific facts (stack, paths, commands) |
| **`--append-system-prompt`** | Appends to the system prompt for one session only | Session only | Per-session experiments, scripted runs |

The key distinction: an output style **edits the system prompt itself**, so it competes less with Anthropic's baked-in coding instructions. CLAUDE.md sits *below* the system prompt as a user message and competes with whatever's already there.

If you want Claude to stop leading with file paths and class names, an output style will fight less than a CLAUDE.md addition.

---

## Where Custom Styles Live

```
~/.claude/output-styles/<name>.md       # User-level (every project)
.claude/output-styles/<name>.md         # Project-level (this project only)
```

User-level styles apply to every session you start on this machine. Project-level styles apply only when cwd is inside that project.

Most users want one user-level style for their preferred communication shape, with project-level overrides only for unusual projects.

---

## File Format

```markdown
---
name: My Style
description: One-line summary shown in the /config picker.
keep-coding-instructions: true
---

# My Style Instructions

(...prompt content here...)
```

Frontmatter fields:

| Field | Required | Purpose |
|---|---|---|
| `name` | yes | Display name in the `/config` picker |
| `description` | yes | One-line summary in the picker |
| `keep-coding-instructions` | no | If `true`, retains Claude Code's default coding-assistant framing (recommended for most styles) |

If you omit `keep-coding-instructions: true`, Claude Code's default coding instructions are *replaced* by your style. That is rarely what you want -- you usually want to *add* a communication shape on top of the existing coding smarts.

---

## Activating a Style

Output styles are activated through `/config`, not through a dedicated slash command (in 2.1.121 there is no `/output-style` slash). The flow:

1. Type `/config` in any Claude Code session.
2. Pick "Preferred output style" from the menu.
3. Select your style. It writes to `settings.json` and applies to all future sessions.

Custom style files are only discovered at session start. If you add a new file to `~/.claude/output-styles/`, restart Claude Code before checking the `/config` picker.

To revert: `/config` -> "Preferred output style" -> `Default`.

You can also edit `~/.claude/settings.json` directly:

```json
{
  "outputStyle": "bluf"
}
```

Set the value to `default` or remove the key to revert.

---

## Worked Example: BLUF Style

**BLUF** ("Bottom Line Up Front") is a writing pattern from military and executive communications: state the conclusion first, then the supporting detail. It's a good fit for Claude Code because dense technical responses are easy to skim *only* if the first sentences carry the conclusion.

The same pattern shows up under different names in plain-language guides:

- **BLUF** -- US military / executive comms
- **Inverted pyramid** -- journalism (US/UK plain-language guidelines)
- **Front-loading** -- Microsoft Writing Style Guide

Below is a small, paste-and-go BLUF style. Save as `~/.claude/output-styles/bluf.md`:

```markdown
---
name: BLUF
description: Problem-first communication. Plain English up front, technical details after.
keep-coding-instructions: true
---

# BLUF Communication Style

Structure every plan, option-presentation, recommendation, and task summary in this order:

1. **Problem** (1 sentence, plain English, no file paths or jargon): what is broken or what does the user want.
2. **Fix** (1 sentence, plain English): what will solve it.
3. **Why** (1-2 sentences, plain English): the reasoning, root cause, or tradeoff.
4. **Technical details** (only here): file paths, function names, commands, line numbers, internal terminology.

Apply BLUF (Bottom Line Up Front) and the inverted pyramid: the user must understand problem + fix in the first 3 lines, even if they stop reading there.

Plain-language rules:
- Active voice. Short sentences (<20 words avg).
- Define jargon on first use, e.g. "RBAC (role-based access control)".
- Prefer "use" over "utilize", "decide" over "make a decision".
- One idea per sentence.

For OPTIONS / tradeoffs, use this shape:
- **Problem**: <1 sentence>
- **Option A — <plain name>**: <plain English>. Tradeoff: <one line>.
- **Option B — <plain name>**: <plain English>. Tradeoff: <one line>.
- **Recommendation**: <which + one-line why>
- *Then* technical details for the chosen option.

Never lead with code, file paths, or class names. This is about parsing speed, not information density -- keep all the technical depth, just defer it.
```

After dropping the file, restart Claude Code and pick `BLUF` in `/config`.

### What changes after activation

A typical "what should I do about X" question that previously came back leading with `~/foo/bar.py` and class names will now come back as:

> **Problem**: One plain-English sentence describing what's broken.
> **Fix**: One plain-English sentence describing the action.
> **Why**: 1-2 sentences of reasoning.
> **Details**: file paths, code, commands -- in that order.

The total information is the same. The reading time is shorter because you can stop at line 2 if Problem + Fix is enough to act on.

---

## When to Pick Each Built-in

| Style | Use when |
|---|---|
| `Default` | Coding-task efficiency, minimum ceremony, you read every reply in full |
| `Explanatory` | Learning a new codebase, want rationale and tradeoffs surfaced |
| `Learning` | You want Claude to pause and let you write code segments yourself |
| `BLUF` (custom) | Long technical responses, mixed-fluency reading, fast triage |

You can switch any time. The cost is one `/config` interaction.

---

## Anti-Patterns

### 1. Replacing coding instructions accidentally

Forgetting `keep-coding-instructions: true` in the frontmatter. Without it, the style replaces Claude Code's default coding framing entirely -- you lose tool-use guidance, error-handling defaults, and other behavior that you actually want.

**Fix**: always include `keep-coding-instructions: true` unless you genuinely want to override the coding framing.

### 2. Stuffing project facts into the style

An output style is for *how* Claude responds, not *what* Claude knows about your project. Putting "we use Postgres 17" or "API runs on port 8080" into the style file means every project on the machine inherits those facts.

**Fix**: project facts go in `<project>/CLAUDE.md`. Output styles stay project-agnostic.

### 3. Custom styles that fight built-in coding rules

Writing a style that says "never write tests" or "skip error handling" turns Claude into a worse coding assistant in exchange for a stylistic preference. The framework can't compensate for instructions that contradict the coding job.

**Fix**: shape *communication*, not *coding behavior*. If you want different coding behavior, use rules (`.claude/rules/`) or skills, not output styles.

---

## Pair BLUF with a TL;DR Closing (Variant B)

BLUF gives the reader an **entry anchor** — Problem/Fix in the first lines. For substantive replies, a **TL;DR closing block** at the bottom gives a matching **exit anchor** with calibrated scoring. Together they turn every substantive reply into a scannable Problem → Fix → Score capsule.

BLUF answers "should I keep reading?"; TL;DR answers "what now?"

### Canonical Format (Variant B — traffic-light dots)

```
✨ TL;DR
🔴 Problem  <one sentence, plain English>
🟢 Fix      <one sentence — what happened, or what to do next>
📊 Score    Conf 🟢 HIGH · Effort 🟢 LOW · Time ⏱ 5m · Impact 🟡 MED
```

Score dots reflect **favorability** (🟢 good · 🟡 mixed · 🔴 concerning), not the label value — so for Effort, LOW = 🟢 because lower effort is better. Time has no dot, just the ⏱ marker.

Compact one-liner for short substantive replies:

```
✨ TL;DR — 🔴 Problem. 🟢 Fix. 🟢HIGH · 🟢LOW · ⏱5m · 🟡MED
```

### When to include the block

Include when the reply contains:

- Code changes this turn (Edit / Write / MultiEdit fired)
- Recommendation, decision, or option-list presented to the user
- Plan / audit / analysis output
- Error blocker — user must fix or decide to unblock
- Multi-step work report (3+ distinct actions)
- A `/<skill>` slash command invocation

Skip when the reply is:

- Tool-echo confirmation ("done", "committed", "file written")
- Single-fact answer (≤2 sentences, no action implied)
- Clarifying question back to the user (reply ends with `?`)
- Mid-work status update ("checking X", "found Y")

### Enforcement (optional soft-warn)

A `Stop` event hook can log misses to `~/.claude/logs/tldr-misses.jsonl` without ever blocking. The hook scans the last 5 lines of the assistant reply for the literal string `TL;DR` (emoji-prefix tolerant) and triggers when either Edit/Write/MultiEdit fired this turn or the reply exceeded ~1500 chars. A reference implementation lives at `~/.claude/hooks/tldr-miss-logger.sh`.

Soft-warn first; escalate to a blocking gate (Stop hook returning `decision="block"`) only after a 14-day eyeball confirms a high miss rate. Kill switch: `touch ~/.claude/state/tldr-miss-logger-disabled`.

### Subagent path

`outputStyle` does **not** propagate to subagents — they run with their own system prompt. When an orchestrator relays subagent output to the user, it must reformat the result into the BLUF + TL;DR shape itself. Encode this in your delegation rule so it isn't forgotten on long multi-agent sessions.

For the full spec — Include-When triggers, Skip-When list, scoring calibration table, override grammar — see `best-practices/BEST-PRACTICES.md` **Section 28** (`Reply Closing Format (TL;DR)`).

### 4. Forgetting the restart

Adding a file to `~/.claude/output-styles/` and expecting it to appear in `/config` immediately. The picker loads styles at session start.

**Fix**: restart Claude Code, then check `/config`.

### 5. Fabricated `/output-style` slash command

Some third-party guides reference an `/output-style <name>` slash command. In Claude Code 2.1.121 this does not exist -- only `/config` activates styles. Trust `/config` and `settings.json`.

**Fix**: use `/config` to switch, or edit `settings.json` directly.

---

## Pointers

- **CLAUDE.md primer** -- [Part I/02](02-claude-md-primer.md)
- **Settings file structure** -- [Part VI/02 -- CLI flags & env](../part6-reference/02-cli-flags-and-env.md)
- **Skills (different mechanism, similar shape)** -- [Part III/04 -- Skills authoring](../part3-extension/04-skills-authoring.md)

---

## Checklist

Before shipping a custom output style:

- [ ] Frontmatter has `name`, `description`, and (almost always) `keep-coding-instructions: true`
- [ ] Content describes *how* to respond, not *what* to know about a project
- [ ] No project-specific paths, ports, or stack details
- [ ] Restart and verify the style appears in `/config`
- [ ] Pick the style and run a real prompt -- does the response shape match the style?
- [ ] If user-level: works across at least 2 different projects without weirdness

If all checks pass, ship it. Output styles are cheap to revert (`/config` -> `Default`) so the cost of getting it slightly wrong is low.
