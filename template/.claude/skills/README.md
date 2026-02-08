# Claude Code Skills - Starter Pack

**3 Essential Skills for Day 1 Productivity**

These skills provide immediate value when using Claude Code. They follow the proven pattern from production that achieves 84% activation rate.

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

- [ ] YAML frontmatter: `name`, `description` (with "Use when..."), `user-invocable`
- [ ] Optional: `Triggers` field (for pre-prompt hook keyword matching)
- [ ] Description is specific — includes keywords and scenarios (max 1024 chars)
- [ ] Failed Attempts table with 2-3 entries
- [ ] Quick Start section with concrete commands
- [ ] Evidence section with numbers and dates
- [ ] Under 300 lines total (optimal for token efficiency)
- [ ] No non-standard frontmatter fields (`priority`, `agent` without `context: fork`)

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

---

## Skill Maintenance & Optimization

As your skill library grows (50+ skills), regular maintenance prevents token waste and broken references.

### Monthly Maintenance

```bash
# Find oversized skills (>300 lines)
find ~/.claude/skills -name "SKILL.md" \
  -exec sh -c 'l=$(wc -l < "$1"); [ "$l" -gt 300 ] && echo "$l $1"' _ {} \; \
  | sort -rn

# Check for non-standard frontmatter
grep -r "^priority:\|^agent:" ~/.claude/skills/*/SKILL.md 2>/dev/null

# Count total skills
find ~/.claude/skills -name "SKILL.md" | wc -l
```

### Trimming Strategy (Keep Under 300 Lines)

| Remove | Why |
|--------|-----|
| Body "Triggers" section | Duplicates frontmatter Triggers field |
| 5+ verbose examples | 1 complete example is enough |
| Duplicate Evidence sections | Keep single Evidence table |

| Condense | Technique |
|----------|-----------|
| Multi-paragraph prose | Convert to tables |
| Full code blocks | Method signatures only |
| Long explanations | YAML decision trees |

**Never remove**: Quick Start, Failed Attempts, Evidence, Decision criteria.

### Merging Overlapping Skills

When two skills share >70% content, merge into one and delete the originals:

```bash
# Create new merged skill
mkdir -p ~/.claude/skills/merged-skill-name/
# ... write SKILL.md combining best content ...

# DELETE originals (don't deprecate — stubs waste tokens)
rm -rf ~/.claude/skills/old-skill-1/
rm -rf ~/.claude/skills/old-skill-2/

# Rebuild cache
rm -f ~/.claude/cache/skill-index-hybrid.txt
```

**Full guide**: See [docs/guide/35-skill-optimization-maintenance.md](../../docs/guide/35-skill-optimization-maintenance.md)

---

## Anthropic Official Frontmatter Reference

Per [code.claude.com/docs/en/skills](https://code.claude.com/docs/en/skills):

| Field | Purpose |
|-------|---------|
| `name` | Skill identifier |
| `description` | **THE triggering mechanism** — include "Use when..." |
| `user-invocable` | Allow direct invocation |
| `Triggers` | *Custom* — for pre-prompt hook keyword matching |

**Key insight**: Claude Code uses the `description` field to decide when to activate a skill. Put all activation keywords there.

---

## References

- **Full Guide**: See [docs/guide/06-skills-framework.md](../../docs/guide/06-skills-framework.md)
- **Optimization**: See [docs/guide/35-skill-optimization-maintenance.md](../../docs/guide/35-skill-optimization-maintenance.md)
- **Skills Library**: See [skills-library/](../../skills-library/) for complete catalog
- **Validation**: Run `./scripts/check-skills.sh` (if available)

---

**Starter Skills Pack**: Essential skills for Day 1 productivity
**Installation**: User-level (~/.claude/skills/) for cross-project usage
**Maintenance**: Monthly audit + trim oversized + merge overlapping
