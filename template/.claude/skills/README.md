# Claude Code Skills - Starter Pack

**3 Essential Skills for Day 1 Productivity**

These skills provide immediate value when using Claude Code. They follow the proven pattern from LimorAI that achieves 84% activation rate.

---

## Installation

### Copy to User Directory (Recommended)

Skills are stored at **user-level** (not project-level) so they work across all your Claude Code projects.

**CRITICAL**: Skills MUST use directory structure with SKILL.md (uppercase):

```bash
# Copy all starter skills (correct structure)
cp -r starter/troubleshooting-decision-tree-skill ~/.claude/skills/
cp -r starter/session-start-protocol-skill ~/.claude/skills/
cp -r starter/project-patterns-skill ~/.claude/skills/
```

**WRONG** ❌:
```bash
# DON'T copy .md files directly!
cp starter/*.md ~/.claude/skills/  # This won't work!
```

### Verify Installation

```bash
# Check skills directory structure
ls ~/.claude/skills/

# Should see DIRECTORIES (not .md files):
# troubleshooting-decision-tree-skill/
# session-start-protocol-skill/
# project-patterns-skill/

# Verify SKILL.md files exist
find ~/.claude/skills -name "SKILL.md"

# Should see:
# ~/.claude/skills/troubleshooting-decision-tree-skill/SKILL.md
# ~/.claude/skills/session-start-protocol-skill/SKILL.md
# ~/.claude/skills/project-patterns-skill/SKILL.md
```

---

## The 3 Starter Skills

### 1. troubleshooting-decision-tree-skill ⭐ CRITICAL

**When to use**: Encountering any error or unexpected behavior

**Value**: Routes you to the right solution fast (84% success rate)

**Triggers**: "error", "not working", "broken", "issue", "debug"

**Time Saved**: 10-30 min per debug session

---

### 2. session-start-protocol-skill 🔄 ESSENTIAL

**When to use**: Starting every Claude Code session

**Value**: Multi-session continuity (Anthropic best practice)

**Triggers**: "start session", "resume work", "what was I working on"

**Time Saved**: 10-30 min per session (vs getting oriented randomly)

---

### 3. project-patterns-skill 📋 FOUNDATIONAL

**When to use**: Implementing features, validating code, onboarding team

**Value**: Quick reference to your project's core patterns

**Triggers**: "check patterns", "validate", "onboarding", "conventions"

**Time Saved**: 5-10 min per implementation

---

## Skill Activation

### Automatic Activation (Recommended - Phase 1+)

Enable the pre-prompt hook for 84% activation rate:

```bash
# Copy hook template
cp ../hooks/pre-prompt.sh.template ../hooks/pre-prompt.sh

# Make executable
chmod +x ../hooks/pre-prompt.sh

# Configure
cp ../hooks/settings.local.json.template ~/.claude/hooks/settings.local.json
```

### Manual Activation (Phase 0)

Without the hook, you can still reference skills manually:

```
# In Claude Code chat:
"Use troubleshooting-decision-tree-skill to debug this error"
"Follow session-start-protocol-skill to initialize"
"Check project-patterns-skill for validation standards"
```

---

## Creating Your Own Skills

### Use the Template

```bash
# Copy template
cp SKILL-TEMPLATE.md ~/.claude/skills/my-new-skill.md

# Edit and customize
# Follow the structure - especially:
#   - Numbered triggers (1), (2), (3)
#   - Failed Attempts table
#   - Evidence with numbers
```

### Critical Success Factors

**84% Activation Rate Requires**:
1. **Numbered triggers**: Use (1), (2), (3) format
2. **Specific scenarios**: "When encountering 'ECONNREFUSED'" (not "connection issues")
3. **Concrete evidence**: "15/15 tests (100%)" (not "works well")
4. **Failed Attempts**: Documents what didn't work
5. **Quick Start**: Value in < 5 minutes

### Skill Quality Checklist

- [ ] YAML frontmatter with name and description
- [ ] Description mentions specific triggers
- [ ] Usage Scenarios use numbered format (1), (2), (3)
- [ ] Failed Attempts table with 2-3 entries
- [ ] Quick Start section with concrete commands
- [ ] Evidence section with numbers and dates
- [ ] Integration section lists related skills

---

## Skill Naming Convention

**Pattern**: `{domain}-{purpose}-skill`

**Examples**:
- `database-connection-troubleshooting-skill`
- `api-authentication-workflow-skill`
- `deployment-validation-procedure-skill`

**Why**:
- Clear categorization
- Easy to search
- Consistent with ecosystem

---

## Success Metrics

**Starter Skills Provide**:
- 30-60 min saved per day (across 3 skills)
- 84% activation rate (with hook enabled)
- Multi-session continuity
- Faster onboarding for team members

**Next Steps**:
- Create 5 troubleshooting skills (Week 1)
- Create 8 workflow skills (Week 2-3)
- Build specialized domain skills (Month 2+)

---

## References

- **Full Guide**: See [docs/guide/06-skills-framework.md](../../docs/guide/06-skills-framework.md)
- **Skills Library**: See [skills-library/](../../skills-library/) for complete catalog
- **Validation**: Run `./scripts/check-skills.sh` (if available)

---

**Starter Skills Pack**: Essential skills for Day 1 productivity
**Installation**: User-level (~/.claude/skills/) for cross-project usage
**Success**: 84% activation rate with numbered triggers pattern
