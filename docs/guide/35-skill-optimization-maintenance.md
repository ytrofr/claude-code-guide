# Chapter 35: Skill Optimization & Maintenance

**Created**: 2026-02-05
**Source**: Production Entry #327 — 12.4k tokens saved via systematic optimization
**Pattern**: Audit → Merge → Fix → Trim → Curate → Verify

---

## The Problem: Skill Rot

As projects grow, skill libraries accumulate problems:

- **Broken references**: Skills deleted but still listed in branch configs
- **Stubs**: Skills that just redirect to "master skills" (wasting tokens)
- **Bloated skills**: 400-500 line skills that could be 150 lines
- **Overlap**: Multiple skills covering the same workflow
- **Outdated frontmatter**: Non-standard fields Claude Code ignores

**Evidence**: Production found 3 broken refs, 1 stub, 5 oversized skills in a single branch's top 10.

---

## Anthropic Official Frontmatter Fields

Per [code.claude.com/docs/en/skills](https://code.claude.com/docs/en/skills), these are the recognized YAML frontmatter fields:

| Field | Required | Purpose |
|-------|----------|---------|
| `name` | Yes | Skill identifier (kebab-case) |
| `description` | Yes | **THE triggering mechanism** — include "Use when..." |
| `user-invocable` | No | Whether user can invoke directly |
| `disable-model-invocation` | No | Prevent automatic invocation |
| `allowed-tools` | No | Restrict tool access |
| `model` | No | Force specific model |
| `context` | No | `fork` for isolated agent |
| `agent` | No | Only meaningful with `context: fork` |
| `hooks` | No | Skill-specific hooks |
| `argument-hint` | No | Hint for user-invocable skills |

### What's NOT Official

Any field not in the list above is **custom** — Claude Code ignores it during skill selection:

```yaml
# These are NOT recognized by Claude Code:
priority: high          # ← Remove (ignored)
agent: some-agent       # ← Only valid with context: fork
Triggers: keyword1      # ← Custom (for pre-prompt hooks only)
```

### Correct Frontmatter Order

```yaml
---
name: my-skill-name
description: "What it does. Use when [scenario 1], [scenario 2], or when user mentions [keywords]."
Triggers: keyword1, keyword2, keyword3  # Optional: for pre-prompt hooks
user-invocable: false
---
```

### The Description IS the Trigger

Claude Code uses the `description` field to decide when to activate a skill. This means:

- Put ALL "when to use" information in the description
- Don't rely on body content for activation
- Include specific keywords users would say
- Max 1024 characters

```yaml
# ❌ Bad: Vague description
description: "Helps with deployments"

# ✅ Good: Specific with triggers
description: "Deploy to Cloud Run with traffic routing and health checks. Use when deploying to staging/production, verifying deployments, or when changes don't appear after deploy."
```

---

## 6-Step Optimization Workflow

### Step 1: Audit

```bash
# Check branch config for broken references
BRANCH="dev-feature"  # Change per branch
for skill in $(python3 -c "
import json
d = json.load(open('memory-bank/always/branch-variables.json'))
print('\n'.join(d['$BRANCH']['top_skills']))
"); do
  if [ -d "$HOME/.claude/skills/$skill" ]; then
    lines=$(wc -l < "$HOME/.claude/skills/$skill/SKILL.md")
    echo "OK: $skill ($lines lines)"
  else
    echo "BROKEN: $skill"
  fi
done

# Find oversized skills (>300 lines)
find ~/.claude/skills -name "SKILL.md" \
  -exec sh -c 'l=$(wc -l < "$1"); [ "$l" -gt 300 ] && echo "$l $1"' _ {} \; \
  | sort -rn

# Check for non-standard frontmatter fields
grep -r "^priority:\|^agent:" ~/.claude/skills/*/SKILL.md 2>/dev/null
```

### Step 2: Merge Overlapping Skills

**When to merge**: Two skills share >70% content overlap.

```yaml
MERGE_PATTERN:
  1. Create NEW skill with combined name
  2. Keep best Quick Start from either source
  3. Keep ALL Failed Attempts from both
  4. Target <300 lines
  5. DELETE old directories entirely (rm -rf)

EXAMPLE:
  Before: context-testing-workflow-skill (178 lines)
        + context-preservation-enhancement-skill (335 lines)
  After:  context-preservation-skill (234 lines)
  Savings: 279 lines removed, 1 skill instead of 2
```

**Never deprecate** — delete entirely. Stub/redirect skills waste tokens.

### Step 3: Fix Frontmatter

```bash
# For each skill, verify:
# 1. name → description → [Triggers] → user-invocable order
# 2. description contains "Use when..."
# 3. No non-standard fields (priority, agent without fork)

# Quick check
for skill in ~/.claude/skills/*/SKILL.md; do
  line2=$(sed -n '2p' "$skill")
  line3=$(sed -n '3p' "$skill")
  echo "$line2" | grep -q "^name:" && echo "$line3" | grep -q "^description:" \
    && echo "OK: $skill" \
    || echo "FIX: $skill (wrong order)"
done
```

### Step 4: Trim Oversized Skills

**Target**: Under 300 lines (Anthropic scans ~100 tokens per skill for selection).

| Remove | Why |
|--------|-----|
| Body "Activation Triggers" section | Duplicates frontmatter |
| 5+ verbose examples | 1 complete example sufficient |
| Duplicate Evidence sections | Keep single Evidence table |
| System file listings | Already in rules/CORE-PATTERNS |

| Condense | Technique |
|----------|-----------|
| Multi-paragraph prose | Convert to table |
| Full code blocks | Method signatures only |
| Long explanations | YAML decision trees |
| Multiple similar examples | 1 example + "same pattern for..." |

**Never remove**: Quick Start, Failed Attempts, Evidence (metrics/dates), Decision criteria.

**Real results** (Entry #327):

| Skill | Before | After | Reduction |
|-------|--------|-------|-----------|
| ai-quality-validation | 444 | 148 | 67% |
| ai-pipeline-debugging | 471 | 188 | 60% |
| modular-rag-selection | 365 | 219 | 40% |
| sql-validation | 355 | 160 | 55% |
| ai-query-table-selection | 315 | 129 | 59% |
| **Total** | **1,950** | **844** | **57%** |

### Step 5: Curate Branch Top 10

If your project uses branch-specific skill loading (see Chapter 16), update the branch configuration:

```json
{
  "dev-feature": {
    "mission": "AI Accuracy & Response Time",
    "top_skills": [
      "pure-gemini-architecture-skill",
      "llm-application-development-skill",
      "ai-pipeline-debugging-skill",
      "modular-rag-selection-skill",
      "gemini-integration",
      "ai-quality-validation-skill",
      "context-preservation-skill",
      "sql-validation-comprehensive-skill",
      "baseline-fix-workflow-skill",
      "temporal-extraction-skill"
    ]
  }
}
```

**Curation principles**:
- Align skills with branch mission
- Replace broken references immediately
- Remove stubs (redirect skills)
- Prioritize high-impact skills (architecture, debugging, quality)

### Step 6: Rebuild Cache & Verify

```bash
# Rebuild skill cache
rm -f ~/.claude/cache/skill-index-hybrid.txt
echo '{"prompt": "test"}' | bash .claude/hooks/pre-prompt.sh >/dev/null 2>&1
wc -l ~/.claude/cache/skill-index-hybrid.txt

# Run 8 verification tests
# 1. Deleted skills gone
# 2. New/merged skills activate on keywords
# 3. Branch config has exactly N skills
# 4. All referenced skills exist as directories
# 5. Frontmatter order: name→description
# 6. All skills under 300 lines
# 7. No trailing quotes in Triggers
# 8. Cache line count matches expected
```

---

## Maintenance Schedule

| Frequency | Task | Time |
|-----------|------|------|
| **Monthly** | Check for broken references | 5 min |
| **Quarterly** | Find and trim oversized skills | 30 min |
| **Per branch switch** | Verify top 10 alignment with mission | 10 min |
| **After skill deletion** | Rebuild cache + verify | 5 min |
| **After merge** | Run activation tests | 10 min |

---

## Common Pitfalls

### 1. Deprecating Instead of Deleting

**Wrong**: Add "DEPRECATED" header, keep file around
**Problem**: Still consumes tokens in cache scan (~100 tokens per skill)
**Correct**: `rm -rf ~/.claude/skills/old-skill/` — clean deletion

### 2. Over-Trimming

**Wrong**: Remove Quick Start to save lines
**Problem**: Skill becomes useless without actionable content
**Correct**: Remove redundancy, keep essential sections

### 3. Forgetting Cache Rebuild

**Wrong**: Edit skill files, expect changes immediately
**Problem**: Pre-prompt hook uses cached index
**Correct**: Always `rm ~/.claude/cache/skill-index-hybrid.txt` after changes

### 4. Orphaned References

**Wrong**: Delete skill but forget branch-variables.json
**Problem**: Branch loads show "BROKEN: skill-name"
**Correct**: Update all references before deleting

---

## ROI

**Entry #327 Results**:
- Token savings: ~12,400 (~6% of 200k context budget)
- Broken references fixed: 3 → 0
- Stub references removed: 1 → 0
- Skills under 300 lines: 100% compliance
- Time invested: ~2 hours
- Reusable for: All 6 branches (×6 multiplier)

**Annual estimate**: 18 hours/year (6-12 optimizations × 1.5h each)

---

## References

- **Anthropic Docs**: [code.claude.com/docs/en/skills](https://code.claude.com/docs/en/skills)
- **Chapter 16**: Skills Activation Breakthrough (activation patterns)
- **Entry #327**: dev-feature Skills Optimization (source for this guide)
- **Entry #271**: Skill Creation Methodology (creation standards)

---

**Pattern Status**: Production ready (validated on 185-skill library)
**Next**: Chapter 18 - Advanced Branch Context Patterns (coming soon)
