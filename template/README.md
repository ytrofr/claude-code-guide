# Claude Code Project Template

**Quick-start template for new Claude Code projects**

This template provides a minimal viable setup that can be customized for your project in 30 minutes.

---

## Quick Setup

```bash
# 1. Copy template to your project
cp -r claude-code-guide/template/.claude ~/my-project/
cp -r claude-code-guide/template/memory-bank ~/my-project/

# 2. Navigate to your project
cd ~/my-project

# 3. Customize core files
# Edit these files and replace [PLACEHOLDERS]:
- .claude/CLAUDE.md
- memory-bank/always/CORE-PATTERNS.md.template (rename to .md)
- memory-bank/always/system-status.json.template (rename to .json)
- memory-bank/always/CONTEXT-ROUTER.md.template (rename to .md)

# 4. Configure MCP (optional but recommended)
cp .claude/mcp_servers.json.template .claude/mcp_servers.json
# Edit mcp_servers.json and add your credentials

# 5. Copy starter skills to user directory
# CRITICAL: Skills use directory structure (NOT standalone .md files!)
cp -r .claude/skills/starter/troubleshooting-decision-tree-skill ~/.claude/skills/
cp -r .claude/skills/starter/session-start-protocol-skill ~/.claude/skills/
cp -r .claude/skills/starter/project-patterns-skill ~/.claude/skills/

# 6. Validate setup
./scripts/validate-setup.sh
# (Note: scripts are in the main guide repository)

# 7. Start Claude Code
claude-code
```

---

## What's Included

### Configuration Files

**`.claude/CLAUDE.md`**

- Project-level context auto-loaded every session
- Define your core rules and patterns
- Reference your memory bank files

**`.claude/mcp_servers.json.template`**

- Pre-configured for GitHub, Memory Bank, PostgreSQL, Perplexity
- Use `${VARIABLE}` placeholders for credentials
- Rename to `mcp_servers.json` after customizing

**`.claude/hooks/` (optional)**

- `pre-prompt.sh.template` - Skills activation hook (84% success rate)
- `settings.local.json.template` - Hook configuration
- Enable after Phase 1 (Week 1)

### Memory Bank Structure

**`memory-bank/always/` - Auto-loaded context**

- `CORE-PATTERNS.md.template` - Single source of truth for all patterns
- `CONTEXT-ROUTER.md.template` - Agent routing rules
- `system-status.json.template` - Feature tracking (Anthropic JSON pattern)

**`memory-bank/learned/` - Documented patterns**

- Start empty, grows organically
- Add Entry #1, #2, #3 as you solve problems
- Organize by domain for fast discovery

**`memory-bank/ondemand/` - Reference docs**

- Detailed documentation loaded on-demand
- Keep token costs low
- Use for complex implementations

**`memory-bank/blueprints/` - Recreation guides**

- Complete feature rebuild instructions
- Generated after features are working
- Enables system recovery

### Starter Skills

**`.claude/skills/starter/` - 3 essential skills**

1. `troubleshooting-decision-tree-skill.md` - Route to appropriate solutions
2. `session-start-protocol-skill.md` - Anthropic best practice for continuity
3. `project-patterns-skill.md` - Your core patterns reference

**Usage**: Copy to `~/.claude/skills/` (user-level, shared across projects)

---

## Customization Checklist

### Required Replacements

- [ ] `[YOUR_PROJECT_NAME]` → Your project name
- [ ] `[DATE]` → Current date (YYYY-MM-DD)
- [ ] `[YOUR_*]` → Your specific values (database names, API endpoints, etc.)

### File Renames

- [ ] `CORE-PATTERNS.md.template` → `CORE-PATTERNS.md`
- [ ] `system-status.json.template` → `system-status.json`
- [ ] `CONTEXT-ROUTER.md.template` → `CONTEXT-ROUTER.md`
- [ ] `mcp_servers.json.template` → `mcp_servers.json` (add credentials first!)

### Configuration Steps

- [ ] Add your core patterns to CORE-PATTERNS.md
- [ ] Define your features in system-status.json
- [ ] Configure MCP servers with your credentials
- [ ] Copy starter skill DIRECTORIES to ~/.claude/skills/ (NOT .md files!)
- [ ] Test with `claude-code` to verify auto-loading

### Optional Enhancements

- [ ] Enable pre-prompt hook (`.claude/hooks/pre-prompt.sh`)
- [ ] Add Memory Bank MCP for session persistence
- [ ] Configure PostgreSQL MCP for database access
- [ ] Create project-specific skills

---

## Validation

After setup, verify everything works:

```bash
# If using validation scripts from main guide
cd ~/claude-code-guide
./scripts/validate-setup.sh ~/my-project

# Manual validation
cd ~/my-project
claude-code

# In Claude Code session, ask:
"What are my core patterns?"
# Should reference CORE-PATTERNS.md

"What's the current feature status?"
# Should read system-status.json
```

**Success Criteria**:

- Claude loads CORE-PATTERNS.md automatically
- system-status.json is readable (valid JSON)
- MCP servers connect (if configured)
- Skills activate on relevant triggers

---

## Next Steps

### Phase 1: Essential Setup (Week 1)

1. Add Memory Bank MCP for session persistence
2. Create 5 troubleshooting skills
3. Enable pre-prompt hook
4. Build TIER-2-REGISTRY for learned patterns

→ See [docs/guide/03-phase-1-essential.md](../docs/guide/03-phase-1-essential.md)

### Phase 2: Productive Setup (Week 2-3)

1. Add PostgreSQL MCP for database access
2. Create 8 workflow skills
3. Build feature blueprints
4. Add domain authorities

→ See [docs/guide/04-phase-2-productive.md](../docs/guide/04-phase-2-productive.md)

---

## Troubleshooting

### Common Issues

**"Claude doesn't load CORE-PATTERNS.md"**

- Check filename: Must be `CORE-PATTERNS.md` (not .template)
- Check location: Must be in `memory-bank/always/`
- Check CLAUDE.md: Should have `@memory-bank/always/CORE-PATTERNS.md`

**"MCP servers not connecting"**

- Rename `mcp_servers.json.template` to `mcp_servers.json`
- Replace all `${VARIABLE}` placeholders
- Run `./scripts/check-mcp.sh` to diagnose

**"Skills not activating"**

- Copy skills to `~/.claude/skills/` (not project directory)
- Check YAML frontmatter is valid
- Enable pre-prompt hook (optional but recommended)

---

## Support

- [Complete Guide](../docs/guide/) - Detailed documentation
- [Quick Start](../docs/quick-start.md) - 30-minute path
- [Troubleshooting](../docs/guide/10-troubleshooting.md) - Common issues

---

**Template Version**: 1.0
**Last Updated**: 2025-12-14
**Source**: Based on LimorAI proven patterns
