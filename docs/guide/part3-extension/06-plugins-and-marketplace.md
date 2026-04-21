---
layout: default
title: "Plugins and Marketplace"
parent: "Part III — Extension"
nav_order: 6
redirect_from:
  - /docs/guide/22-wshobson-marketplace-integration.html
  - /docs/guide/22-wshobson-marketplace-integration/
  - /docs/guide/63-plugin-marketplace.html
  - /docs/guide/63-plugin-marketplace/
---

# Plugins and Marketplace

A plugin is the distribution format for Claude Code extensions. One plugin can ship any combination of **skills**, **agents**, **hooks**, **MCP servers**, **LSP servers**, and — on newer versions — bin executables, monitors, and YAML-defined skill hooks. Instead of copying dozens of individual files across projects, you add a marketplace once and install plugins from it on demand.

This chapter covers plugin structure, how to install and manage plugins, the built-in marketplaces, and how to publish your own. Security implications (permission review, scope validation) are covered in Part VI — Security.

---

## What a Plugin Is

A plugin is a directory (or Git repo) containing one or more of:

| Component | Location inside plugin | Purpose |
|-----------|----------------------|---------|
| Skills | `skills/<name>/SKILL.md` | Reusable procedures and domain knowledge |
| Agents | `agents/<name>.md` | Named subagents with their own prompts |
| Hooks | `hooks/*.sh` + manifest entries | Event handlers (PreToolUse, SessionStart, etc.) |
| MCP servers | `mcp/<server>.json` or manifest | Bundled MCP configuration |
| LSP servers | Manifest entry | Language-server wiring |
| bin/ executables | `bin/<name>` | CLI tools callable from the session (2.1.91+) |
| Monitors | Manifest entry | Live-tail targets for the Monitor tool (2.1.105+) |

A plugin that only ships skills is still a plugin — the envelope is what makes it installable and updatable as a single unit. That's the value: one `/plugin install` gives you a coherent bundle instead of a pile of loose files.

---

## Plugin Directory Structure

A typical plugin looks like this:

```
my-plugin/
  .claude-plugin/
    marketplace.json         # plugin metadata + component index
  skills/
    deploy-helper/
      SKILL.md
    test-runner/
      SKILL.md
  agents/
    backend-architect.md
  hooks/
    pre-commit.sh
  bin/                       # 2.1.91+
    my-plugin-cli
  README.md                  # optional, for GitHub browsers
  LICENSE
```

The one required file is `.claude-plugin/marketplace.json` — it's how Claude Code knows this is a plugin and what it contains.

### Minimal `marketplace.json`

```json
{
  "name": "my-plugin",
  "version": "1.2.0",
  "description": "Deploy helpers and test runners for our stack",
  "author": "you@example.com",
  "license": "MIT",
  "components": {
    "skills": ["deploy-helper", "test-runner"],
    "agents": ["backend-architect"],
    "hooks": {
      "PreToolUse": [{ "matcher": "Bash", "command": "./hooks/pre-commit.sh" }]
    }
  }
}
```

Required fields: `name`, `version`, `description`. `author` and `license` are strongly recommended for public plugins. `components` is how Claude Code discovers what ships inside.

---

## Installing Plugins

Claude Code ships with a `/plugin` command that handles discovery, install, enable/disable, and update.

```bash
# Browse available plugins interactively
/plugin

# Register a marketplace
/plugin marketplace add anthropics/claude-plugins-official

# Install a plugin from a registered marketplace
/plugin install pr-review-toolkit@claude-plugins-official

# List installed plugins
/plugin marketplace list

# Reload after changes
/reload-plugins
```

### Marketplace Source Types

| Source | Example | Use Case |
|--------|---------|----------|
| GitHub shorthand | `anthropics/claude-plugins-official` | Most common |
| Git URL | `https://gitlab.com/company/plugins.git` | Private Git hosts |
| Local path | `./my-local-marketplace` | Development / testing |
| JSON URL | `https://example.com/marketplace.json` | Custom registries |

### Install Scope

Plugins install at **user** scope by default — they live under `~/.claude/plugins/` and are available in every session. Use `--scope project` to pin a plugin to the current project only (stored under `.claude/plugins/`).

User scope is right for workflow tools (commit helpers, review agents). Project scope is right for stack-specific bundles (a Remotion plugin, an ADK plugin) that other projects shouldn't see.

---

## Built-in Marketplaces

### `claude-plugins-official`

Anthropic's curated marketplace. Around 90+ plugins at time of writing, covering code review, security, documentation, LSP integration, workflow automation, and more.

Notable plugins in wide use:

| Plugin | What it ships | When to enable |
|--------|---------------|---------------|
| `commit-commands` | `/commit`, `/commit-push-pr`, `/clean-gone` | You want a consistent commit workflow with message templates |
| `pr-review-toolkit` | 6 review agents (silent-failure-hunter, type-design-analyzer, etc.) | You want structured PR review beyond "does this work" |
| `skill-creator` | Skill-authoring assistant + eval framework | You're writing skills and want measurement/benchmarks |
| `context7` | Version-specific library docs via MCP | You hit hallucinated API usage for popular libraries |
| `superpowers` | Brainstorming, git-worktrees, writing-plans, code-review workflows | You want meta-skills for planning and review |
| `claude-code-setup` | Codebase analysis + automation recommendations | Greenfield setup or audit of existing config |
| `frontend-design` | Production-grade UI design skill | You're building polished frontends |

The marketplace is already registered in default installs; `/plugin install <name>@claude-plugins-official` just works.

### Community marketplaces

The `wshobson/agents` marketplace ([github.com/wshobson/agents](https://github.com/wshobson/agents)) ships a large bundle of agents and skills organized by domain (backend development, database design, LLM application dev, observability). At time of writing it advertises around 273 components — the exact count has fluctuated as components are added, deprecated, and reorganized, so treat the number as a rough indicator rather than a stable contract.

Representative agents from `wshobson/agents`:

| Agent | Purpose |
|-------|---------|
| `backend-architect` | API design, microservices, service boundaries |
| `database-architect` | Schema modeling, technology selection |
| `ai-engineer` | RAG systems, embeddings, agent wiring |
| `observability-engineer` | Metrics, tracing, dashboard setup |
| `database-optimizer` | Query performance, indexing, EXPLAIN ANALYZE |
| `performance-engineer` | Load testing, optimization |

Add it the same way as any other marketplace:

```bash
/plugin marketplace add wshobson/agents
/plugin install backend-development@agents
```

Before installing anything from a community marketplace, read the source. Plugins can ship hooks and MCP servers that run code on your machine — treat a plugin install the same way you'd treat `npm install` from an unknown author.

---

## Plugin-Namespaced Skill Invocation

Skills that ship inside a plugin are namespaced to avoid collisions with your own skills. If the `pr-review-toolkit` plugin ships a skill called `review-pr`, you invoke it as:

```
/pr-review-toolkit:review-pr
```

The `<plugin>:<skill>` form is how Claude Code disambiguates when a plugin skill has the same short name as one of yours. Your local `/review-pr` (if you have one) stays bound to the short form; the plugin version is always reachable via its namespace.

This matters for two reasons:

1. **No silent shadowing.** You can install a plugin without worrying that it will take over a short name you already use.
2. **Explicit provenance.** When you type `/pr-review-toolkit:review-pr`, it's obvious where the skill came from — useful for debugging and for code review of config changes.

---

## Plugin Metadata

The `.claude-plugin/marketplace.json` manifest is the plugin's public face. Keep it honest — users read it to decide whether to install.

### Required

- `name` — kebab-case identifier, unique within the marketplace
- `version` — semver (`MAJOR.MINOR.PATCH`), bump on every release
- `description` — one sentence, what it does and when to use it

### Recommended

- `author` — name or email
- `license` — SPDX identifier (MIT, Apache-2.0, etc.) — no license = most users will skip
- `homepage` — link to docs or source
- `keywords` — array of tags for discovery

### Components block

The `components` object declares what ships inside. Claude Code uses this to populate the skill list, register hooks, and wire up MCP/LSP servers at install time. Components that aren't declared don't activate, even if the files are present.

---

## Version-specific Plugin Features

Plugin capabilities have grown across Claude Code releases. If you're authoring a plugin and want to use a newer feature, document the minimum CC version in your README.

### `bin/` executables (CC 2.1.91+)

A plugin can ship executable files under `bin/`. Claude Code adds them to the session `PATH` when the plugin is enabled, so users can call `my-plugin-cli` directly from Bash without a full path.

```
my-plugin/
  bin/
    my-plugin-cli        # chmod +x required; shebang line required
```

Use this for small helpers that complement skills (e.g., a validator script the skill tells the user to run).

### Plugin YAML hooks in skill frontmatter (CC 2.1.94+)

Skills shipped by a plugin can declare hooks inline in their SKILL.md frontmatter, instead of requiring users to wire them into `settings.json` manually. The plugin's install flow registers them at plugin-enable time and removes them at disable time.

```yaml
---
name: deploy-helper
description: Deploy to production with safety checks
hooks:
  PreToolUse:
    - matcher: "Bash(gcloud run deploy.*)"
      command: "./scripts/preflight.sh"
---
```

This keeps hook logic colocated with the skill that owns it — which matters when you uninstall the plugin and don't want orphan hooks lingering.

### `monitors` manifest entry (CC 2.1.105+)

Plugins can declare long-running log sources as first-class `monitors`, which users can then stream via the Monitor tool. Use this for deploy scripts, CI watchers, or any command whose stdout is useful as a live feed.

```json
{
  "monitors": [
    { "name": "deploy-log", "command": "tail -f ./deploy.log" }
  ]
}
```

The Monitor tool treats each stdout line as an event, so the user gets incremental notifications instead of polling.

---

## Managing Installed Plugins

```bash
# Enable / disable without uninstalling
/plugin enable plugin-name@marketplace
/plugin disable plugin-name@marketplace

# Uninstall completely
/plugin uninstall plugin-name@marketplace

# Update marketplace catalogs (fetches new plugin versions)
/plugin marketplace update marketplace-name

# Validate your own plugin during development
/plugin validate .
```

Disable rather than uninstall when you're testing whether a plugin is responsible for flaky behavior — disable keeps the files in place, so re-enabling is instant.

### Stale-plugin cleanup

Over time you accumulate plugins from marketplaces you no longer use. Check which plugins reference which marketplaces:

```bash
cat ~/.claude/plugins/installed_plugins.json | grep -o '"[^"]*@[^"]*"'
cat ~/.claude/plugins/known_marketplaces.json
```

If a plugin references a marketplace no longer in `known_marketplaces.json`, uninstall it — it won't receive updates anyway.

---

## Creating Your Own Marketplace

A marketplace is just a Git repo (or a served JSON file) that Claude Code can point `/plugin marketplace add` at. The minimum structure is a top-level `marketplace.json` listing plugins the marketplace offers:

```
my-marketplace/
  marketplace.json          # top-level index
  plugins/
    plugin-one/
      .claude-plugin/marketplace.json
      skills/...
    plugin-two/
      .claude-plugin/marketplace.json
      agents/...
```

The top-level `marketplace.json`:

```json
{
  "name": "my-marketplace",
  "description": "Internal deploy tooling for our team",
  "plugins": [
    { "name": "plugin-one", "path": "plugins/plugin-one" },
    { "name": "plugin-two", "path": "plugins/plugin-two" }
  ]
}
```

Users add it with:

```bash
/plugin marketplace add your-org/your-marketplace
/plugin install plugin-one@your-marketplace
```

For private marketplaces (internal team tooling), point at a private Git URL or a path on a shared volume.

---

## Evaluating a Plugin Before Installing

The default answer for "should I install this plugin?" is **no, unless it fills a gap you already have**. Plugins add context (skill descriptions, agent prompts, hooks) that compete with your own for attention — bloating your setup makes every skill harder to find.

**Quality signals** before installing:

| Signal | Good | Concerning |
|--------|------|-----------|
| Install count | >10K | <100 |
| Publisher | Anthropic, known org | Unknown individual |
| License | MIT, Apache-2.0 | No license or proprietary |
| Permissions | Scoped `allowed-tools` | `Bash(*)` or no restrictions |
| Activity | Commits in last 3 months | Stale for a year |

After installing, scan what you got (`npx ecc-agentshield scan ~/.claude/plugins/cache/`) and read any `hooks/*.sh` and `bin/*` files before enabling — those run on your machine with your credentials. See Part VI — Security for the full permission-review workflow.

Common anti-patterns: installing everything popular (context bloat), ignoring plugin permissions (supply-chain risk), never updating marketplaces (missed patches), mixing a plugin skill and a custom skill for the same task (unpredictable precedence), using `@latest` in plugin-shipped MCP servers (non-reproducible), authoring a plugin without a LICENSE (most users skip).

---

## Enterprise Restrictions

Organizations can lock down which marketplaces and plugins are allowed via managed settings:

```json
// managed-settings.d/security.json
{
  "strictKnownMarketplaces": true,
  "blockedPlugins": ["risky-plugin@some-marketplace"]
}
```

With `strictKnownMarketplaces: true`, users can only add marketplaces that the org has pre-registered. `blockedPlugins` is a denylist for known-bad bundles.

---

## Plugin vs Skill vs Agent — When to Use Which

| You want to ship... | Use |
|---------------------|-----|
| One skill for your own use | A plain `skills/<name>/` directory |
| Several skills that belong together, shared with a team | A plugin with `skills/` bundled |
| A named sub-personality for delegation | An agent — inside a plugin if you're sharing it |
| A hook that enforces a rule on every file write | A hook in `settings.json`, or inside a plugin that ships it |
| An MCP server your team needs | An MCP config — optionally bundled inside a plugin |

Plugins are the distribution format. Skills, agents, hooks, and MCP servers are the primitives. If you only need one primitive for yourself, skip the plugin envelope — `skills/<name>/SKILL.md` is enough.

---

## Related Chapters

- [Skills Authoring](04-skills-authoring.md) — writing the skills a plugin ships
- [Skills Maintenance](05-skills-maintenance.md) — lifecycle policy and staleness
- [Agents and Subagents](03-agents-and-subagents.md) — agents bundled inside plugins
- [Claude Code Hooks](01-hooks.md) — event handlers plugins can ship
- [MCP Integration](02-mcp-integration.md) — MCP servers a plugin can bundle
- Part VI — Security — permission review, plugin scanning, managed settings
