# Quick Start - Claude Code in 30 Minutes

**Get productive with Claude Code immediately**

This quick-start guide gets you from zero to a working Claude Code setup in 30 minutes.

---

## What is Claude Code?

**Claude Code** is Claude's official CLI tool that provides:

- **Persistent configuration** - Your patterns remembered across all sessions
- **Tool integrations** - MCP servers for GitHub, databases, memory, and more
- **Skills system** - Reusable workflows that activate automatically
- **Context awareness** - Auto-loaded project documentation

**vs Regular Claude**: Web chat forgets everything between sessions. Claude Code maintains project context forever.

---

## Prerequisites (5 min)

### 1. Install Claude Code

```bash
# Follow official installation
# https://claude.com/claude-code
```

### 2. Verify Prerequisites

```bash
# Check installations
claude-code --version   # Should show version
git --version           # Should show version
node --version          # Should show v18+
npx --version           # Should show version
jq --version            # Should show version (or install: brew install jq)
```

---

## Quick Setup (30 min)

### Three Paths - Choose One:

#### Path A: Setup Wizard (Easiest - Recommended)

```bash
# 1. Clone this guide
git clone https://github.com/YOUR_USERNAME/claude-code-guide
cd claude-code-guide

# 2. Navigate to your project
cd ~/my-project

# 3. Run wizard
bash ../claude-code-guide/scripts/setup-wizard.sh
# Follow prompts (10-15 min)

# 4. Validate
../claude-code-guide/scripts/validate-setup.sh
```

#### Path B: Manual Template Copy

```bash
# 1. Copy template
cp -r claude-code-guide/template/.claude ~/my-project/
cp -r claude-code-guide/template/memory-bank ~/my-project/

# 2. Customize (10 min)
cd ~/my-project
# - Rename .template files
# - Replace [PLACEHOLDERS]
# - Add GitHub token

# 3. Install skills (2 min)
cp .claude/skills/starter/*.md ~/.claude/skills/

# 4. Validate (2 min)
../claude-code-guide/scripts/validate-setup.sh
```

#### Path C: From Scratch (Learning Experience)

Follow the detailed guide:
→ [docs/guide/02-minimal-setup.md](guide/02-minimal-setup.md)

---

## Verify Setup Works

### Start Claude Code

```bash
cd ~/my-project
claude-code
```

### Test Basic Functionality

Ask Claude these questions:

```
1. "What are my core patterns?"
   ✅ Should reference CORE-PATTERNS.md

2. "What's the current feature status?"
   ✅ Should read system-status.json

3. "List my GitHub repositories"
   ✅ Should use GitHub MCP (if configured)

4. "I'm getting a database connection error"
   ✅ Should reference troubleshooting-decision-tree-skill (if installed)
```

**All working?** Setup is complete! 🎉

---

## What You Just Created

### Configuration

- `.claude/CLAUDE.md` - Project context (auto-loaded every session)
- `.claude/mcp_servers.json` - MCP server configuration
- `memory-bank/always/` - Core patterns and status tracking

### Skills (in ~/.claude/skills/)

- `troubleshooting-decision-tree-skill` - Error routing (84% success)
- `session-start-protocol-skill` - Session continuity (Anthropic pattern)
- `project-patterns-skill` - Pattern reference

### Tools

- `scripts/validate-setup.sh` - Setup validator
- `scripts/check-mcp.sh` - MCP connection tester

---

## Immediate Benefits

**You can now**:

- ✅ Have Claude reference your patterns automatically
- ✅ Track feature completion with system-status.json
- ✅ Review PRs and manage issues without leaving Claude
- ✅ Debug with decision tree routing (10-30 min saved per issue)
- ✅ Resume work across sessions seamlessly

---

## Next Steps (Optional)

### Week 1: Add More Value (2-3 hours)

- Add Memory Bank MCP for session persistence
- Create 5 troubleshooting skills for your domains
- Enable pre-prompt hook (84% activation rate)

→ See [guide/03-phase-1-essential.md](guide/03-phase-1-essential.md)

### Week 2-3: Specialized Workflows (4-6 hours)

- Add PostgreSQL MCP for database access
- Create 8 workflow skills (deployment, testing, etc.)
- Build feature blueprints

→ See [guide/04-phase-2-productive.md](guide/04-phase-2-productive.md)

### Month 2+: Full Ecosystem

- Custom MCP servers
- 20-30 skill library
- Full agent coordination
- 561-709 hours/year ROI (proven)

→ See [guide/05-phase-3-advanced.md](guide/05-phase-3-advanced.md)

---

## Troubleshooting

### Setup Issues

**Problem**: Validation fails
**Solution**: Check error output, fix specific issues, run again

**Problem**: Claude doesn't load patterns
**Solution**: Verify file paths in .claude/CLAUDE.md start with `@memory-bank/`

**Problem**: MCP not connecting
**Solution**: Run `./scripts/check-mcp.sh` for detailed diagnostics

### Getting Help

- **Troubleshooting Guide**: [guide/10-troubleshooting.md](guide/10-troubleshooting.md)
- **Detailed Setup**: [guide/02-minimal-setup.md](guide/02-minimal-setup.md)
- **Skills Framework**: [guide/06-skills-framework.md](guide/06-skills-framework.md)
- **MCP Integration**: [guide/07-mcp-integration.md](guide/07-mcp-integration.md)

---

## Success Checklist

- [ ] Completed setup in ≤ 30 minutes
- [ ] Validation passed with 0 errors
- [ ] Claude references CORE-PATTERNS.md
- [ ] GitHub MCP connects
- [ ] 3 skills installed and working
- [ ] Can resume work across sessions

**All checked?** You're ready to be productive with Claude Code! 🚀

---

**Quick Start**: 30-minute path to productive Claude Code
**Next**: [Complete Guide](guide/) for advanced features
**Help**: [Troubleshooting](guide/10-troubleshooting.md)
