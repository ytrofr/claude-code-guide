---
layout: default
title: "Slash Commands (now Skills)"
parent: "Part III — Extension"
nav_order: 7
---

# Slash Commands (now Skills)

Short answer: slash commands still exist, but they are now just skills with `user-invocable: true`. If you're writing a new one, read [Skills Authoring](04-skills-authoring.md). If you have legacy `commands/*.md` files from before Claude Code 2.1.88, read the migration section below.

---

## Historical Note

Before CC 2.1.88, user-invocable slash commands lived in two directories:

```
~/.claude/commands/       # Global
.claude/commands/         # Project-scoped
```

Each was a single Markdown file with YAML frontmatter. In 2.1.88, Anthropic merged commands into skills — the `commands/` directories were deprecated and any `/<name>` invocation that used to be a command is now a skill with `user-invocable: true`.

There is no longer a separate command type. Skills are the one primitive.

---

## Invocation Patterns

### Plain skill invocation

```
/skill-name
/skill-name argument text here
```

The first form runs the skill with empty arguments. The second passes everything after the name as `$ARGUMENTS` (see [Skills Authoring → Arguments](04-skills-authoring.md)).

### Plugin-namespaced invocation

Skills installed via a plugin are addressed with the plugin prefix:

```
/plugin-name:skill-name
```

Example: the `superpowers` plugin exposes `/superpowers:brainstorming`, `/superpowers:writing-plans`, etc.

### Built-in slashes (2.1.108+)

Several built-in commands are now rewired through the Skill tool:

| Slash | What it does |
|-------|--------------|
| `/init` | Initialize a new CLAUDE.md for the project |
| `/review` | Review a pull request |
| `/security-review` | Security review of pending changes |

Plus the classic built-ins (not implemented as skills): `/help`, `/clear`, `/cost`, `/config`, `/doctor`, `/model`, `/resume`, `/compact`, `/release-notes`, and others. These are hard-wired into the CLI.

---

## Authoring a User-Invocable Skill

The short form — full details in [Skills Authoring](04-skills-authoring.md):

```yaml
---
name: my-command
description: "Short action-verb description. Use when user says 'my command' or types /my-command."
user-invocable: true
argument-hint: "[optional argument description]"
---

# My Command

$ARGUMENTS

## Workflow

Steps to execute using the argument text above.
```

Key fields:

- `user-invocable: true` — required to show in the `/` menu
- `argument-hint` — text displayed in the UI when the user types `/my-command<space>`
- `$ARGUMENTS` — expanded to whatever the user typed after the command name

To prevent accidental automatic invocation (e.g., for deploy commands that must be explicit):

```yaml
disable-model-invocation: true
```

This keeps the skill user-invocable via slash but prevents Claude from auto-triggering it based on conversation context.

---

## Migrating Legacy `commands/` Files

If you have files in `~/.claude/commands/` or `.claude/commands/` from before 2.1.88, migrate them to the skills layout:

### Before (legacy command file)

```
~/.claude/commands/
  deploy.md
  ship-it.md
  weekly-review.md
```

Each file had frontmatter and a body. The filename (minus `.md`) was the slash name.

### After (skill directory)

```
~/.claude/skills/
  deploy/
    SKILL.md
  ship-it/
    SKILL.md
  weekly-review/
    SKILL.md
```

The directory name becomes the slash name. `SKILL.md` replaces the old command file.

### Migration steps

```bash
# For each legacy command file:
OLD="deploy"
mkdir -p ~/.claude/skills/$OLD
mv ~/.claude/commands/$OLD.md ~/.claude/skills/$OLD/SKILL.md
```

Then edit `SKILL.md` and ensure the frontmatter has:

```yaml
---
name: deploy                         # optional; directory name is used if omitted
description: "Deploy to production. Use when user says /deploy or 'deploy to prod'."
user-invocable: true
---
```

Important frontmatter hygiene during migration:

- Rename `allowed_tools` → `allowed-tools` (hyphenated, not underscored — the old form is silently ignored)
- Convert JSON-array tool lists to comma-separated strings: `["Read", "Bash"]` → `Read, Bash`
- Add `user-invocable: true` if the old command was invocable (most were, by default)
- Update `description` to include "Use when..." trigger text

Then remove the empty `commands/` directory (if nothing else remains in it):

```bash
rmdir ~/.claude/commands 2>/dev/null || true
```

---

## Common Migration Issues

| Problem | Cause | Fix |
|---------|-------|-----|
| Slash doesn't appear in `/` menu | Missing `user-invocable: true` | Add the field |
| Tool restrictions ignored | Used `allowed_tools` (underscore) | Rename to `allowed-tools` |
| Arguments not expanded | Legacy command used `{{args}}` | Replace with `$ARGUMENTS` |
| Tool list parsed as empty | Used JSON array format | Use comma-separated string |
| Slash fires when unwanted | Model auto-invokes from context | Add `disable-model-invocation: true` |

---

## See Also

- [Skills Authoring](04-skills-authoring.md) — frontmatter fields, body structure, arguments, testing
- [Skills Maintenance](05-skills-maintenance.md) — keeping user-invocable skills healthy
- [CLI Flags and Env Vars](../part6-reference/02-cli-flags-and-env.md) — built-in slashes and CLI options
