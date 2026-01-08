# 28. Skill Optimization Patterns

**Created**: January 2026
**Source**: Claude Code changelog (January 2026) + LimorAI implementation
**Evidence**: 171 skills optimized with new frontmatter features

---

## Overview

Claude Code introduced new skill frontmatter features in January 2026 that enable:
- **Isolated execution** via `context: fork`
- **Agent routing** via `agent:` field
- **Menu visibility control** via `user-invocable: false`
- **Wildcard bash permissions** for cleaner configuration

This guide shows how to optimize your skills library with these features.

---

## 1. Context Fork (`context: fork`)

### What It Does
- Runs skill in an isolated sub-agent context
- Prevents context pollution from long-running operations
- Ideal for heavy skills that spawn many tool calls

### When to Use
- **Deployment skills** - Multiple gcloud/docker commands
- **Sync operations** - Database migrations, gap detection
- **Validation skills** - Cross-environment parity checks
- **Large-scale operations** - Anything with 10+ tool calls

### Implementation

```yaml
---
name: deployment-master-skill
description: "Deploy to GCP Cloud Run with Sacred compliance..."
context: fork
---
```

### Batch Update Script

```bash
# Add context: fork to heavy skills
for skill in deployment-master-skill gap-auto-healing-skill sync-workflow-skill; do
  if [ -f ~/.claude/skills/$skill/SKILL.md ]; then
    if ! grep -q "context:" ~/.claude/skills/$skill/SKILL.md; then
      sed -i '/^description:/a context: fork' ~/.claude/skills/$skill/SKILL.md
      echo "✅ Added context: fork to $skill"
    fi
  fi
done
```

### Recommended Skills for `context: fork`

| Category | Skills |
|----------|--------|
| Deployment | deployment-master, cloud-run-safe-deployment, post-deployment-validation |
| Sync | gap-auto-healing, gap-detection-and-sync, historical-reductions-sync |
| Validation | comprehensive-parity-validation, production-parity-workflow |
| Database | database-master, schema-recreation-sync, large-table-sync-safety |
| Testing | testing-master, staging-data-sync-validation |

---

## 2. Agent Routing (`agent:`)

### What It Does
- Specifies which agent type executes the skill
- Routes skill to specialized agent for better results
- Enables domain expertise matching

### Agent Mapping

| Domain | Agent | Use Cases |
|--------|-------|----------|
| Database | `database-agent` | Schema, sync, gaps, parity |
| API | `api-coordinator` | OAuth, endpoints, integrations |
| Testing | `test-engineer` | Jest, E2E, baseline tests |
| Deployment | `deploy-agent` | Cloud Run, GCP, CI/CD |
| AI/LLM | `vertex-ai-agent` | Prompts, embeddings, quality |
| Troubleshooting | `debug-specialist` | Errors, investigation, fixes |
| Hebrew | `hebrew-agent` | RTL, cultural, i18n |

### Implementation

```yaml
---
name: database-master-skill
description: "Database patterns and schema operations..."
agent: database-agent
context: fork
---
```

### Batch Update Script

```bash
# Add agent routing by domain
cd ~/.claude/skills

# Database skills
for skill in database-master-skill gap-auto-healing-skill schema-recreation-sync-skill; do
  if [ -f "$skill/SKILL.md" ] && ! grep -q "agent:" "$skill/SKILL.md"; then
    sed -i '/^description:/a agent: database-agent' "$skill/SKILL.md"
    echo "✅ database-agent → $skill"
  fi
done

# AI skills
for skill in ai-quality-validation-skill prompt-optimization-skill semantic-query-router-skill; do
  if [ -f "$skill/SKILL.md" ] && ! grep -q "agent:" "$skill/SKILL.md"; then
    sed -i '/^description:/a agent: vertex-ai-agent' "$skill/SKILL.md"
    echo "✅ vertex-ai-agent → $skill"
  fi
done
```

---

## 3. User Invocable (`user-invocable: false`)

### What It Does
- Hides skill from slash command menu
- Skill still works when called programmatically
- Reduces menu clutter for consolidated/internal skills

### When to Use
- **Consolidated skills** that redirect to master skills
- **Internal/utility skills** not meant for direct invocation
- **Template skills** used as references only

### Implementation

```yaml
---
name: api-authentication-patterns-skill
description: "Configure API authentication..."
user-invocable: false
---

# ⚠️ CONSOLIDATED

This skill has been consolidated into **api-master-skill**.
```

### Batch Update Script

```bash
# Find and mark consolidated skills
cd ~/.claude/skills

for skill in $(grep -l "consolidated into" */SKILL.md 2>/dev/null | xargs -I{} dirname {}); do
  if ! grep -q "user-invocable:" "$skill/SKILL.md"; then
    sed -i '/^description:/a user-invocable: false' "$skill/SKILL.md"
    echo "✅ Marked $skill as internal"
  fi
done
```

---

## 4. Wildcard Bash Permissions

### What It Does
- Uses `*` wildcard at any position in Bash rules
- Simplifies permission configuration
- Reduces maintenance overhead

### Before (Explicit Rules)

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run test)",
      "Bash(npm run lint)",
      "Bash(npm run format)",
      "Bash(npm install)",
      "Bash(git status)",
      "Bash(git log)",
      "Bash(git diff)",
      "Bash(git add)",
      "Bash(gcloud run deploy)",
      "Bash(gcloud run services)",
      "Bash(docker build)",
      "Bash(docker push)"
    ]
  }
}
```

### After (Wildcard Patterns)

```json
{
  "permissions": {
    "allow": [
      "Bash(npm *)",
      "Bash(npx *)",
      "Bash(git *)",
      "Bash(gcloud *)",
      "Bash(docker *)",
      "Bash(node *)",
      "Bash(curl *)",
      "Bash(jq *)",
      "Bash(grep *)",
      "Bash(find *)",
      "Bash(ls *)",
      "Bash(cat *)",
      "Bash(PGPASSWORD=* psql *)"
    ]
  }
}
```

### Wildcard Patterns

| Pattern | Matches |
|---------|--------|
| `Bash(npm *)` | All npm commands |
| `Bash(* install)` | Any command ending with install |
| `Bash(git * main)` | Git commands with "main" at end |
| `Bash(PGPASSWORD=* psql *)` | Any psql with any password |

---

## 5. Complete Optimization Workflow

### Step 1: Identify Skills to Optimize

```bash
# Count current state
echo "Skills with context: fork → $(grep -rl 'context: fork' ~/.claude/skills/*/SKILL.md | wc -l)"
echo "Skills with agent: → $(grep -rl '^agent:' ~/.claude/skills/*/SKILL.md | wc -l)"
echo "Skills with user-invocable: false → $(grep -rl 'user-invocable: false' ~/.claude/skills/*/SKILL.md | wc -l)"
```

### Step 2: Categorize Skills

```bash
# Find consolidated skills
grep -l "consolidated into" ~/.claude/skills/*/SKILL.md

# Find heavy/master skills
ls ~/.claude/skills/ | grep -E "(master|deployment|sync|gap|parity)"
```

### Step 3: Apply Optimizations

1. Mark consolidated skills with `user-invocable: false`
2. Add `context: fork` to heavy skills
3. Add `agent:` routing to domain-specific skills
4. Update `settings.json` with wildcard permissions

### Step 4: Validate

```bash
# Validate settings.json
jq . ~/.claude/settings.json > /dev/null && echo "✅ Valid JSON"

# Validate skill frontmatter
for skill in ~/.claude/skills/*/SKILL.md; do
  if grep -q "^---" "$skill" && grep -q "name:" "$skill"; then
    echo "✅ $(basename $(dirname $skill))"
  else
    echo "❌ $(basename $(dirname $skill))"
  fi
done
```

---

## 6. Results from LimorAI Implementation

### Optimization Summary

| Feature | Skills Updated |
|---------|---------------|
| `context: fork` | 25 heavy skills |
| `agent:` routing | 39 domain skills |
| `user-invocable: false` | 26 consolidated skills |
| Wildcard permissions | 19 rules (from 30+) |

### Agent Distribution

| Agent | Skills |
|-------|--------|
| `database-agent` | 14 |
| `vertex-ai-agent` | 10 |
| `deploy-agent` | 6 |
| `test-engineer` | 4 |
| `debug-specialist` | 4 |
| `api-coordinator` | 2 |

### Benefits

- **Cleaner slash menu** - 26 fewer internal skills visible
- **Better isolation** - Heavy operations don't pollute context
- **Smarter routing** - Skills execute with domain expertise
- **Simpler config** - 19 wildcard rules vs 30+ explicit

---

## 7. Migration Checklist

- [ ] Audit skills directory (`ls ~/.claude/skills/`)
- [ ] Identify consolidated skills (grep for "consolidated into")
- [ ] Identify heavy skills (deployment, sync, gap, parity)
- [ ] Map skills to agent domains
- [ ] Add `user-invocable: false` to consolidated skills
- [ ] Add `context: fork` to heavy skills
- [ ] Add `agent:` to domain-specific skills
- [ ] Update `settings.json` with wildcard permissions
- [ ] Validate JSON/YAML syntax
- [ ] Restart Claude Code session
- [ ] Test skill activation

---

## References

- **Claude Code Changelog**: January 2026 release notes
- **Source Implementation**: LimorAI (171 skills, 97 components)
- **Related Guide**: [17-skill-detection-enhancement.md](17-skill-detection-enhancement.md)
- **Related Guide**: [24-skill-keyword-enhancement-methodology.md](24-skill-keyword-enhancement-methodology.md)

---

**Status**: ✅ PRODUCTION VALIDATED
**Implementation Time**: ~2-3 hours for full optimization
**ROI**: Cleaner menu, better isolation, smarter routing
