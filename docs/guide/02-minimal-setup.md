# Minimal Setup (30 Minutes)

**Goal**: Working Claude Code with immediate productivity gains
**Time**: 30 minutes
**Prerequisites**: Claude Code installed, Git configured, Node.js + npx available
**Outcome**: Pattern-aware Claude with persistent memory and troubleshooting skills

---

## What You'll Get

After this 30-minute setup:

✅ **Claude knows your project patterns** - References CORE-PATTERNS.md automatically
✅ **Session continuity** - Picks up where you left off across sessions
✅ **Troubleshooting support** - Decision tree routes to solutions fast
✅ **GitHub integration** - PR reviews, issue management via MCP
✅ **Validation tools** - Scripts verify setup is correct

**Value**: Consistent responses, safe git operations, faster debugging

---

## Step-by-Step Setup

### Step 1: Clone Template (5 min)

```bash
# Option A: Use setup wizard (recommended)
cd ~/my-new-project
bash ../claude-code-guide/scripts/setup-wizard.sh

# Option B: Manual setup
cd ~/my-new-project
cp -r ../claude-code-guide/template/.claude .
cp -r ../claude-code-guide/template/memory-bank .
```

**Validation**:

```bash
# Check structure was created
ls -la .claude/
ls -la memory-bank/always/

# Expected output:
# .claude/
#   ├── CLAUDE.md
#   ├── mcp_servers.json.template
#   └── skills/
#
# memory-bank/always/
#   ├── CORE-PATTERNS.md.template
#   ├── CONTEXT-ROUTER.md.template
#   └── system-status.json.template
```

✅ **Success**: Directories and templates exist

---

### Step 2: Rename Template Files (2 min)

```bash
# Navigate to project
cd ~/my-new-project

# Rename memory bank templates
mv memory-bank/always/CORE-PATTERNS.md.template \
   memory-bank/always/CORE-PATTERNS.md

mv memory-bank/always/system-status.json.template \
   memory-bank/always/system-status.json

mv memory-bank/always/CONTEXT-ROUTER.md.template \
   memory-bank/always/CONTEXT-ROUTER.md
```

**Validation**:

```bash
# Check files exist
ls memory-bank/always/

# Expected output:
# CORE-PATTERNS.md
# CONTEXT-ROUTER.md
# system-status.json
```

✅ **Success**: No .template extensions remaining

---

### Step 3: Customize Core Patterns (10 min)

**Edit**: `memory-bank/always/CORE-PATTERNS.md`

**Replace placeholders**:

- `[YOUR_PROJECT_NAME]` → Your actual project name
- `[DATE]` → Current date (YYYY-MM-DD)
- `[your_dev_db_name]` → Your database names (if applicable)

**Add your first pattern**:

````yaml
### Pattern 1: Database Safety (Example)
```yaml
DATABASE_SAFETY:
  Rule: "Always verify database environment before operations"
  Pattern: "SELECT current_database() before operations"

  Environments:
    Development: "my_project_dev"
    Production: "my_project_prod"

  Validation: |
    SELECT current_database();
````

````

**Validation**:
```bash
# Check no placeholders remain
grep '\[YOUR_' memory-bank/always/CORE-PATTERNS.md

# Should return nothing (no matches)
# If matches found, replace them
````

✅ **Success**: No placeholders, patterns are customized

**Edit**: `memory-bank/always/system-status.json`

**Update**:

```json
{
  "last_updated": "2025-12-14", // Today's date
  "current_sprint": "Initial setup",
  "branch": "main", // Your branch
  "features": [
    {
      "name": "Core_Setup",
      "status": "implementing",
      "passes": false,
      "description": "Basic Claude Code configuration"
    }
  ]
}
```

**Validation**:

```bash
# Validate JSON syntax
jq empty memory-bank/always/system-status.json

# If no output, JSON is valid ✅
# If error shown, fix JSON syntax
```

✅ **Success**: Valid JSON with your project info

---

### Step 4: Configure GitHub MCP (3 min)

**Why GitHub MCP**:

- PR reviews without leaving Claude
- Issue management
- Code search across repositories
- Free (official GitHub integration)

**Setup**:

```bash
# 1. Create MCP config from template
cp .claude/mcp_servers.json.template .claude/mcp_servers.json

# 2. Get GitHub token
# Go to: https://github.com/settings/tokens
# Generate new token (classic) with 'repo' scope
# Copy the token

# 3. Add token to config
# Edit .claude/mcp_servers.json
# Replace ${GITHUB_TOKEN} with your actual token
# OR set environment variable:
export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_your_token_here"
```

**Example MCP config (minimal)**:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_your_token_here"
      }
    }
  }
}
```

**Validation**:

```bash
# Check JSON is valid
jq empty .claude/mcp_servers.json

# Check no placeholders remain
grep '${' .claude/mcp_servers.json

# Should return nothing (no placeholders)
```

✅ **Success**: MCP config has your token, valid JSON

---

### Step 5: Install Starter Skills (5 min)

**Copy to user directory** (shared across all your projects):

```bash
# Create skills directory if needed
mkdir -p ~/.claude/skills

# Copy all 3 starter skills
cp .claude/skills/starter/*.md ~/.claude/skills/

# Verify installation
ls ~/.claude/skills/

# Expected output:
# troubleshooting-decision-tree-skill.md
# session-start-protocol-skill.md
# project-patterns-skill.md
```

**Check skill structure**:

```bash
# View first skill
head -20 ~/.claude/skills/troubleshooting-decision-tree-skill.md

# Should see YAML frontmatter:
# ---
# name: troubleshooting-decision-tree-skill
# description: "..."
# ---
```

**Validation**:

```bash
# Count skills
find ~/.claude/skills/ -name "*.md" | wc -l

# Should be >= 3
```

✅ **Success**: 3+ skills in ~/.claude/skills/

---

### Step 6: Validate Complete Setup (2 min)

**Run master validator**:

```bash
# From claude-code-guide directory
./scripts/validate-setup.sh ~/my-new-project

# OR if in your project directory
../claude-code-guide/scripts/validate-setup.sh .
```

**Expected output**:

```
🔍 Claude Code Setup Validation
================================

📁 Checking directory structure...
  ✅ .claude
  ✅ memory-bank
  ✅ memory-bank/always
  ⚠️  Optional: .claude/hooks (not created)

📄 Checking core files...
  ✅ .claude/CLAUDE.md
     ✓ Auto-load references found
  ✅ memory-bank/always/CORE-PATTERNS.md
  ✅ memory-bank/always/system-status.json
     ✓ Valid JSON

🔌 Checking MCP configuration...
  ✅ MCP config is valid JSON
     ✓ 1 MCP server(s) configured
     - github

🎯 Checking skills system...
  ✅ Found 3 skill(s)
     ✓ 3 skill(s) have YAML frontmatter
  ⚠️  Skills hook not configured (optional but recommended)

🔧 Checking for unconfigured placeholders...
  ✅ No unconfigured placeholders found

================================
Validation Summary
================================
✅ Passed: 12
⚠️  Warnings: 2
❌ Errors: 0

✅ Setup is functional!
```

✅ **Success**: Validation passes with 0 errors

---

### Step 7: Test in Claude Code (3 min)

**Start Claude Code**:

```bash
cd ~/my-new-project
claude-code
```

**Test commands in Claude Code chat**:

```
1. Test pattern awareness:
   "What are my core patterns?"
   → Should reference CORE-PATTERNS.md

2. Test system status:
   "What features are incomplete?"
   → Should read system-status.json

3. Test MCP:
   "List my GitHub repositories"
   → Should use GitHub MCP

4. Test skill activation (if hook enabled):
   "I'm getting a connection error"
   → Should reference troubleshooting-decision-tree-skill
```

✅ **Success**: Claude responds with your project context

---

## Minimal Setup Complete! 🎉

**You now have**:

- ✅ Auto-loaded project patterns (CORE-PATTERNS.md)
- ✅ Feature tracking (system-status.json)
- ✅ GitHub integration (MCP)
- ✅ 3 troubleshooting/workflow skills
- ✅ Validation tools

**Time invested**: 30 minutes
**Immediate value**: Consistent responses, pattern compliance, basic automation

---

## What's Next?

### Phase 1: Essential Setup (Week 1 - Optional)

**Add these enhancements** (2-3 hours):

- Memory Bank MCP (session persistence)
- 5 more troubleshooting skills
- Pre-prompt hook (84% skill activation)
- Learned patterns directory

→ See [03-phase-1-essential.md](03-phase-1-essential.md)

### Phase 2: Productive Setup (Week 2-3 - Optional)

**Add specialized capabilities** (4-6 hours):

- PostgreSQL MCP (database access)
- 8 workflow skills
- Feature blueprints
- Domain authorities

→ See [04-phase-2-productive.md](04-phase-2-productive.md)

### Phase 3: Advanced Setup (Month 2+ - Optional)

**Build full ecosystem** (organic growth):

- Custom MCP servers
- 20-30 skill library
- Full agent system
- Complete 4-tier memory bank

→ See [05-phase-3-advanced.md](05-phase-3-advanced.md)

---

## Troubleshooting

### "Claude doesn't load CORE-PATTERNS.md"

**Check**:

```bash
# 1. File exists?
ls memory-bank/always/CORE-PATTERNS.md

# 2. Referenced in CLAUDE.md?
grep "@memory-bank/always/CORE-PATTERNS.md" .claude/CLAUDE.md

# 3. No .template extension?
ls memory-bank/always/*.template
# Should return nothing
```

**Fix**: Add to .claude/CLAUDE.md:

```markdown
## Auto-Load Context

@memory-bank/always/CORE-PATTERNS.md
@memory-bank/always/system-status.json
```

### "MCP servers not connecting"

**Check**:

```bash
# 1. Run MCP validator
./scripts/check-mcp.sh

# 2. Check for placeholders
grep '${' .claude/mcp_servers.json

# 3. Validate JSON
jq empty .claude/mcp_servers.json
```

**Fix**:

- Replace all `${VARIABLE}` with actual values
- For GitHub: Use classic PAT (not fine-grained)
- Verify token has `repo` scope

### "Skills not activating"

**Check**:

```bash
# 1. Skills in correct location?
ls ~/.claude/skills/

# 2. YAML frontmatter valid?
head -5 ~/.claude/skills/troubleshooting-decision-tree-skill.md

# Should start with:
# ---
# name: troubleshooting-decision-tree-skill
# description: "..."
# ---
```

**Fix**:

- Copy skills to `~/.claude/skills/` (user-level, not project)
- Verify YAML frontmatter format
- Enable pre-prompt hook for automatic activation (Phase 1)

### "Validation script fails"

**Check**:

```bash
# 1. Script is executable?
ls -l scripts/validate-setup.sh

# 2. jq installed?
which jq

# 3. Run with explicit path
bash scripts/validate-setup.sh
```

**Fix**:

- Make executable: `chmod +x scripts/validate-setup.sh`
- Install jq: `brew install jq` or `apt-get install jq`

---

## Validation Checklist

Use this to verify your setup:

- [ ] Template copied to project
- [ ] .template files renamed to actual files
- [ ] [PLACEHOLDERS] replaced with actual values
- [ ] system-status.json is valid JSON
- [ ] GitHub token added to mcp_servers.json
- [ ] 3 starter skills in ~/.claude/skills/
- [ ] `./scripts/validate-setup.sh` passes with 0 errors
- [ ] Claude Code loads CORE-PATTERNS.md automatically
- [ ] GitHub MCP connects successfully

**All checked?** You're ready to use Claude Code! 🎉

---

## Next Session

**Every time you start Claude Code** (< 2 min):

```bash
# Quick status check
git status
cat memory-bank/always/system-status.json | jq '.features[] | select(.passes == false)'

# Or use the skill
# In Claude Code: "Use session-start-protocol-skill"
```

**Before ending session**:

```bash
# Update status
# Edit memory-bank/always/system-status.json

# Commit progress
git add -A
git commit -m "checkpoint: [what you accomplished]"
```

---

## Success Metrics

**Minimal setup succeeds when**:

- ✅ Setup completed in ≤ 30 minutes
- ✅ Validation passes with 0 errors
- ✅ Claude references your patterns
- ✅ GitHub MCP works for PR/issue queries
- ✅ Skills activate on relevant triggers

**Time to value**: Immediate (Claude respects your patterns from first message)

---

## References

- **Complete Setup Guide**: [../guide/](../)
- **Skills Framework**: [06-skills-framework.md](06-skills-framework.md)
- **MCP Integration**: [07-mcp-integration.md](07-mcp-integration.md)
- **Troubleshooting**: [10-troubleshooting.md](10-troubleshooting.md)
- **Interactive Checklist**: [../../web/index.html](../../web/index.html)

---

**Minimal Setup Guide**: 30-minute path to productive Claude Code
**Next**: [Phase 1 Essential Setup](03-phase-1-essential.md) (optional, Week 1)
