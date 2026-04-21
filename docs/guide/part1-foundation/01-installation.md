---
layout: default
title: "Installation"
parent: "Part I — Foundation"
nav_order: 1
redirect_from:
  - /docs/guide/02-minimal-setup.html
  - /docs/guide/02-minimal-setup/
---

# Installation

Claude Code is Anthropic's official CLI. This guide's best-practices package adds a curated set of rules, skills, and hooks on top of it. This chapter walks through installing the package in three tiers -- pick the one that matches how deep you're going.

**Purpose**: Get from zero to a working, opinionated Claude Code setup
**Difficulty**: Beginner
**Time**: 5-30 minutes depending on tier

---

## Prerequisites

Before anything here runs, you need Claude Code itself and a few supporting tools.

```bash
claude --version        # Claude Code CLI (required)
git --version           # Git (required)
jq --version            # jq (required by the installer)
node --version          # Node v18+ (required for several MCP servers)
npx --version           # Ships with Node
```

If `claude` is missing, install Claude Code via the official instructions at [claude.com/claude-code](https://claude.com/claude-code) first. If `jq` is missing: `sudo apt install jq` on Debian/Ubuntu/WSL2, `brew install jq` on macOS.

---

## Three Tiers at a Glance

The installer is manifest-driven. A single `best-practices/manifest.json` defines what each tier installs, and `Recommended` extends `Core`, `Full` extends `Recommended` -- so you can always upgrade without reinstalling from scratch.

| Tier | Audience | Rules | Skills | Hooks | Install time |
|---|---|---:|---:|---:|---|
| **Core** | Newcomer / trying things out | 8 | 3 | 1 | ~2 min |
| **Recommended** | Working developer | ~30 | 16 | 7 | ~5 min |
| **Full** | Power user, governance, cross-project AI | 55+ | 43 | 12 | ~10 min |

**Core** gives you validation workflow, no-mock-data enforcement, session protocol, safety rules, and three everyday skills (`verify`, `session-start`, `troubleshooting-decision-tree`). It's enough to feel the difference.

**Recommended** layers in the debugging discipline (diagnostic-first, no-band-aids, layer-escalation), planning (`plan-checklist`, delegation), TDD, Basic Memory MCP patterns, and canary/verify for deploys. This is where most developers land.

**Full** adds governance scaffolding (context-budget, overlap scanner, missing-refs scanner), AI-specific rules (ADK, Gemini, multi-agent orchestration, Hebrew+LLM), self-telemetry, and the inter-agent bus for cross-project coordination.

See [Part VI, Chapter 04 — Skill Catalog](../part6-reference/04-skill-catalog.md) for the full list of skills and what each does.

---

## Quick Install

### Core (curl one-liner, no clone needed)

```bash
curl -sL https://raw.githubusercontent.com/ytrofr/claude-code-guide/master/install.sh | bash
```

Run this from any project directory. It installs Core into `<project>/.claude/` and writes a marker file `.claude-best-practices-installed` so updates work later.

### Recommended or Full (clone + flag)

The richer tiers pull in more files than a curl pipeline can comfortably fetch, so they require cloning the repo first.

```bash
git clone https://github.com/ytrofr/claude-code-guide.git
cd claude-code-guide

# In the project you want to install into:
./install.sh --recommended /path/to/project
# or
./install.sh --full /path/to/project
```

If you omit the path, the installer installs into the current directory.

### Dry run first (recommended)

```bash
./install.sh --recommended --dry-run
```

Prints everything that would install without touching any files. Use this to see exactly what each tier adds.

---

## What Each Tier Installs

### Core

- **Rules** (8): `global/context-checking`, `global/validation-workflow`, `process/safety-rules`, `process/session-protocol`, `process/task-tracking`, `quality/no-mock-data`, `quality/standards`, `technical/patterns`
- **Skills** (3): `verify`, `session-start`, `troubleshooting-decision-tree`
- **Hooks** (1): `SessionStart` memory-context-loader
- **Docs**: `BEST-PRACTICES.md` (universal, auto-loaded via `@import`)
- **Templates**: `CLAUDE.md.template` (starter CLAUDE.md for your project)

### Recommended (adds to Core)

- **Debugging rules**: `diagnostic-first`, `follow-the-data`, `layer-escalation`, `logs-before-metadata`, `no-band-aids`, `trace-before-planning`
- **Planning rules**: `plan-checklist`, `delegation-rule`, `kpi-validation`, `plan-link`
- **Quality rules**: `sequential-user-simulation`, `two-stage-review`, `data-validate-before-refactor`, `source-validation`
- **MCP rules**: `basic-memory-write-standards`, `memory-before-work`, `mcp-first`
- **Skills**: `tdd`, `plan-checklist`, `session-end`, `memory-*` (defrag, notes, search), `retrospective`, `canary`, `mcp-usage-patterns`, `doctor-workflow`, `perplexity-workflow`, `playwright-mcp`, `document`
- **Hooks**: `rule-size-gate`, `plan-sections-gate`, `skill-activation-logger`, `pre-compact`, `memory-pre-compact`, `safety-gate`
- **MCP config templates**: `basic-memory.json`

### Full (adds to Recommended)

- **AI rules**: ADK, Gemini, LLM resilience, multi-agent orchestration, approval-prompt-prescriptive, Hebrew+LLM, injected-context-role-framing, instruction-migration, `no-hardcoded-classification`, `per-user-oauth-isolation`, `llm-finish-reason-probe`, and more
- **Governance scaffolding**: context-budget, overlap scanner, missing-refs scanner, regression-session hook, statusline overlap indicator
- **AI-DNA methodology**: shared rules and skills for cross-project AI work
- **Inter-agent bus**: skill + global hook for coordinating between projects

See [Part VI, Chapter 04](../part6-reference/04-skill-catalog.md) for the full catalog.

---

## Global vs Per-Project Install

By default the installer writes to `<project>/.claude/`. Add `--global` to install into `~/.claude/` instead -- useful for rules and skills you want to apply to every project on this machine.

```bash
./install.sh --recommended --global
```

Conventionally:

- **Global** (`~/.claude/`): universal rules (safety, session protocol), general-purpose skills (verify, tdd, canary)
- **Per-project** (`<project>/.claude/`): project-specific CLAUDE.md, project-scoped rules (e.g. Jekyll build gate for this repo), per-project settings.json

User settings override project settings where they collide. See [Part I/03 — Project Structure](03-project-structure.md) for the full scope rules.

---

## Update and Uninstall

### Update

The Core tier ships with an `update.sh` in the installed project. Run it to pull the latest Core files without touching your custom additions.

```bash
# From a previously installed project:
./update.sh

# Or re-run the installer with --update:
./install.sh --update
```

For Recommended/Full, pull the latest guide repo and re-run the install command with the same tier flag -- the installer is idempotent and overwrites only files it owns per the manifest.

### Uninstall

```bash
./install.sh --uninstall
```

Removes only files listed in the manifest under the installed marker. Your own CLAUDE.md, custom rules, and custom skills are left alone.

---

## Verifying the Install

After installing, confirm it worked.

### Filesystem check

```bash
# What got installed?
ls -la .claude/rules/
ls -la .claude/skills/

# Marker file (proves installer ran)
cat .claude-best-practices-installed
```

The marker file records which tier was installed and the version.

### Inside Claude Code

Start Claude Code in the project:

```bash
cd /path/to/project
claude
```

Then in the Claude Code session:

```
/skills
```

The `/skills` built-in lists every skill Claude Code has discovered from `~/.claude/skills/`, `<project>/.claude/skills/`, and any plugins. Verify the skills you expect to be there are listed. If a skill is missing, check its `description` field for a trigger clause -- without one, auto-invocation won't work (see [Part I/05 — Troubleshooting](05-setup-troubleshooting.md)).

You can also check the CLI version:

```bash
claude --version
```

If the output is older than what's documented in [Part VI/01 — CC Version History](../part6-reference/01-cc-version-history.md), update Claude Code itself (not just this package).

---

## Common Gotchas

- **`jq not found` during install**: install jq first (`sudo apt install jq` / `brew install jq`).
- **Skills don't appear in `/skills`**: the description field may be missing or lacking a trigger clause. See [Part I/05 — Troubleshooting](05-setup-troubleshooting.md).
- **Installer overwrites my CLAUDE.md**: it doesn't. The installer writes `CLAUDE.md.template` next to your existing one if you already have one. Merge manually.
- **Per-project install but I want global**: re-run with `--global`, the installer is idempotent.
- **`claude mcp add` for MCP servers, not settings.json**: MCP servers registered in `settings.json` are silently ignored by recent Claude Code versions. Use the `claude mcp add` command instead.

For a deeper troubleshooting reference, see [Part I/05 — Setup Troubleshooting](05-setup-troubleshooting.md).

---

## Next Steps

- **Author your CLAUDE.md**: [Part I/02 — CLAUDE.md Primer](02-claude-md-primer.md)
- **Understand the directory layout**: [Part I/03 — Project Structure](03-project-structure.md)
- **First session walkthrough**: [Part I/04 — First Session](04-first-session.md)
- **Something broken?**: [Part I/05 — Setup Troubleshooting](05-setup-troubleshooting.md)
