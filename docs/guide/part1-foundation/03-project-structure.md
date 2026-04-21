---
layout: default
title: "Project Structure Conventions"
parent: "Part I — Foundation"
nav_order: 3
---

# Project Structure Conventions

Claude Code has strong opinions about where things live. Get the directory layout right and rules auto-load, skills auto-discover, hooks fire on the right events, and settings cascade in a predictable order. Get it wrong and pieces silently do nothing -- skills never trigger, rules aren't loaded, and you're debugging phantom "didn't follow instructions" bugs.

**Purpose**: Canonical reference for what lives where, and why
**Difficulty**: Beginner
**Applies to**: Any Claude Code project

---

## What Lives in `.claude/` vs the Project Root

The project root (next to your `package.json`, `pyproject.toml`, or equivalent) holds things other tools care about:

- `CLAUDE.md` -- project instructions, auto-loaded by Claude Code
- `README.md`, `LICENSE`, `CHANGELOG.md` -- for humans and GitHub
- `.gitignore` -- for git

The `.claude/` directory holds everything Claude Code itself owns:

```
.claude/
├── CLAUDE.md           # (alternative location for project instructions)
├── settings.json       # permissions, hooks, env vars, statusline
├── settings.local.json # local overrides, gitignored
├── rules/              # always-on instructions (see Part IV/02)
├── skills/             # reusable workflows, discoverable by name
├── hooks/              # shell scripts fired on events
├── agents/             # subagent definitions
├── commands/           # DEPRECATED -- use skills/ instead (CC 2.1.88+)
├── projects/           # auto-memory (gitignored, per-machine)
├── best-practices/     # installer-managed best practices package
└── session-backups/    # conversation backups (gitignored)
```

The root has things *for Claude*; `.claude/` has things *from and about Claude Code*.

---

## Global vs Per-Project

Claude Code loads content from two scopes, always:

| Scope | Location | When it loads | Typical content |
|---|---|---|---|
| **Global / per-user** | `~/.claude/` | Every session | Universal rules, general-purpose skills, machine-wide hooks |
| **Per-project** | `<project>/.claude/` | Sessions with cwd inside that project | Project-specific rules, project skills, project hooks |

Everything merges. If you have `~/.claude/skills/verify/` and `<project>/.claude/skills/verify/`, both are discoverable; Claude picks the right one based on precedence rules.

The global scope is for what you want *everywhere*. Safety rules, session protocol, `verify`/`tdd`/`canary` skills -- all universally useful, all belong in `~/.claude/`. Rules like "this project uses PostgreSQL 16 on port 5432" or skills like "deploy to our staging cluster" are project-specific and belong in `<project>/.claude/`.

### Rule of thumb

- **Global**: applies to 2+ projects → `~/.claude/`
- **Single project**: applies only to this codebase → `<project>/.claude/`

When a piece of content graduates from "single project" to "I keep copying this to every new project," promote it to global.

---

## Subdirectory Meanings

### `rules/`

Always-on instructions auto-loaded at session start. Organized by category (`global/`, `debugging/`, `quality/`, `technical/`, `ai/`, `mcp/`, `process/`, `planning/`, `documentation/`). Each rule is a single `.md` file with a frontmatter header and a short body.

Rules are **always in context**. Keep them tight. See [Part IV/02 — Rules System](../part4-context-engineering/02-rules-system.md) for the full rules authoring guide.

### `skills/`

Reusable workflows Claude can invoke by name (slash commands like `/verify`, `/session-start`, `/tdd`) or auto-trigger via their `description` field. Each skill is a directory containing `SKILL.md` plus any supporting files.

```
skills/
└── verify/
    └── SKILL.md
```

Skills are **discovery-time only**. The `description` field is what Claude sees when deciding whether to invoke -- the body only loads when the skill actually runs. Budget ~1% of context for skill descriptions in aggregate.

**Naming**: bare name directories (`tdd/`, `canary/`), never with `-skill` suffix. See `feedback_skill_naming.md` reference in the global memory for the rationale.

### `hooks/`

Shell scripts that fire on specific Claude Code events -- `PreToolUse`, `PostToolUse`, `SessionStart`, `SessionEnd`, `PreCompact`, and ~22 others. Registered in `settings.json` under a `hooks` block; the script files live in `.claude/hooks/`.

```
hooks/
├── memory-context-loader.sh    # SessionStart
├── rule-size-gate.sh           # PreToolUse (Write/Edit)
└── skill-activation-logger.sh  # PostToolUse
```

Hooks get their input via **stdin JSON**, not env vars. The legacy env-var hook API is dead. See the hooks reference in [Part VI/03 — Hook Event Catalog](../part6-reference/03-hook-event-catalog.md) for the full event list and stdin schema.

### `agents/`

Subagent definitions. Each `.md` file describes a specialized agent Claude can spawn via the `Task()` tool -- its purpose, tools it can use, memory scope, model, permission mode. Use agents for work that needs isolated context (heavy research, domain-specific refactors).

### `commands/` (DEPRECATED)

Pre-2.1.88 slash commands. **Do not author new files here** -- they were merged into skills. If you see a `commands/` directory in an old project, migrate its content to `skills/name/SKILL.md` format.

### `projects/`

Per-machine, per-cwd auto-memory. Contains `MEMORY.md` and feedback notes Claude accumulates across sessions. **Always gitignored** -- this is machine-local, user-specific state. Never commit `projects/`.

### `best-practices/` (installer-managed)

The installer's staging directory. Contains `BEST-PRACTICES.md` (the universal doc that CLAUDE.md `@imports`), a frozen copy of the installed rules, and `VERSION`/manifest files used by `update.sh`. Don't hand-edit -- re-run the installer to refresh.

### `session-backups/` and similar

Conversation snapshots, transcript exports, trace logs. **Gitignored**. Useful locally for recovery or `/weekly-review`, not for the repo.

---

## Scope Precedence: User > Project > Local

When the same setting exists in multiple scopes, Claude Code resolves with this order (highest wins):

1. **`<project>/.claude/settings.local.json`** -- your local overrides (gitignored)
2. **`<project>/.claude/settings.json`** -- project-committed settings
3. **`~/.claude/settings.json`** -- global user settings

For content that merges rather than overrides (rules, skills, hooks), all scopes contribute. You don't have to choose -- the project scope adds to the global scope.

The mental model: global is a baseline you carry between projects; per-project adds project-specific layers; local is your private override on top.

---

## What Belongs in Git vs What Doesn't

### Commit these

- `CLAUDE.md`
- `.claude/settings.json`
- `.claude/rules/` (all of it)
- `.claude/skills/` (all of it)
- `.claude/hooks/` (scripts you authored)
- `.claude/agents/`
- `.claude/best-practices/` (if you want teammates to have the same installed version)

### Never commit these

- `.claude/settings.local.json` -- local overrides, may contain paths or secrets
- `.claude/projects/` -- per-machine auto-memory
- `.claude/session-backups/` -- conversation dumps
- `.credentials.json`, `.env`, `**/secrets/**` -- secrets, obviously
- `.mcp_servers.json` if it contains API tokens (prefer `${VAR}` env-var refs or register servers via `claude mcp add` instead)

### Recommended `.gitignore` block

```
# Claude Code - per-machine / local state
.claude/settings.local.json
.claude/projects/
.claude/session-backups/
.claude/logs/
.claude/cache/

# Secrets
.credentials.json
.env
.env.local
```

One gotcha to watch for: an unanchored `.gitignore` entry like `projects/` can accidentally match *any* `projects/` directory anywhere in the tree. Prefer anchored paths (`/.claude/projects/`) or explicitly scope to `.claude/`. See the `gitignore-anchor-audit` skill for a systematic check.

---

## Naming Conventions

### Skills: bare names

```
skills/
├── tdd/               # good
├── canary/            # good
├── verify/            # good
├── tdd-skill/         # BAD -- remove the -skill suffix
```

The `-skill` suffix was an old convention and confuses Claude Code's skill discovery. Strip it.

### Rules: kebab-case filenames, category directories

```
rules/
├── debugging/
│   ├── diagnostic-first.md
│   └── no-band-aids.md
└── technical/
    └── patterns.md
```

### Hooks: purpose-named shell scripts

```
hooks/
├── memory-context-loader.sh
├── rule-size-gate.sh
└── pre-compact.sh
```

Filenames describe *what* the hook does, not *when* it fires -- the `when` is configured in `settings.json`.

### Agents: role-named files

```
agents/
├── database-architect.md
├── backend-engineer.md
└── explore.md
```

---

## Plugins

Plugins live under `~/.claude/plugins/` and are registered via marketplace install, not hand-authored. If you want to add a plugin:

```bash
# In a Claude Code session
/plugin install <plugin-name>
```

The plugin's files are managed automatically. **Do not hand-create files under `~/.claude/plugins/`** -- they won't register correctly. Plugins bring their own skills, rules, agents, and commands; those show up alongside yours but are owned by the plugin author.

See the plugin docs at [code.claude.com](https://code.claude.com) for authoring plugins from scratch.

---

## Typical Layouts

### Minimal project (Core tier install)

```
myapp/
├── CLAUDE.md
├── .gitignore
└── .claude/
    ├── settings.json
    ├── rules/
    │   ├── global/
    │   ├── process/
    │   ├── quality/
    │   └── technical/
    ├── skills/
    │   ├── verify/
    │   ├── session-start/
    │   └── troubleshooting-decision-tree/
    ├── hooks/
    │   └── memory-context-loader.sh
    └── best-practices/
        ├── BEST-PRACTICES.md
        └── VERSION
```

### Richer project (Recommended/Full tier)

Same shape, more categories under `rules/` (debugging, planning, mcp, etc.), more skills, more hooks. The structure doesn't change -- just the population.

---

## Checklist

Before committing a new project scaffold:

- [ ] `.claude/` directory exists and contains the expected subdirs
- [ ] `.gitignore` excludes `settings.local.json`, `projects/`, `session-backups/`
- [ ] No `-skill` suffixes on skill directory names
- [ ] No files hand-authored under `~/.claude/plugins/`
- [ ] No `commands/` directory being authored fresh (use `skills/` instead)
- [ ] `CLAUDE.md` exists at project root (or `.claude/CLAUDE.md`)
- [ ] No secrets in any committed file (`git diff --cached | grep -iE 'api.key|token'` returns empty)

---

## Pointers

- **What goes in CLAUDE.md** -- [Part I/02 — CLAUDE.md Primer](02-claude-md-primer.md)
- **Rules authoring in depth** -- [Part IV/02 — Rules System](../part4-context-engineering/02-rules-system.md)
- **Hook event catalog** -- [Part VI/03 — Hook Events](../part6-reference/03-hook-event-catalog.md)
- **Skill catalog** -- [Part VI/04 — Skill Catalog](../part6-reference/04-skill-catalog.md)
- **Installation & tiers** -- [Part I/01 — Installation](01-installation.md)
