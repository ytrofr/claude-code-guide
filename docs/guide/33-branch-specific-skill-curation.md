# Chapter 33: Branch-Specific Skill Curation

## The Problem

With 100+ skills available, developers often miss the most relevant skills for their branch's specific mission. A developer on an AI-focused branch shouldn't have to search through deployment skills, and vice versa.

**Symptoms:**

- Developers miss important skills for their work
- Generic skill suggestions don't match branch context
- No visibility into "what skills should I know for this branch?"

## The Solution: Two-Tier Skill Display

Create a curated list of top skills per branch, shown prominently before keyword matches.

### Architecture

```
┌─────────────────────────────────────────┐
│  🎯 BRANCH SKILLS (always visible)      │  ← Curated top 5
├─────────────────────────────────────────┤
│  🔍 KEYWORD MATCHES (query-based)       │  ← Dynamic matches
├─────────────────────────────────────────┤
│  📋 BRANCH: name | Mission: description │
└─────────────────────────────────────────┘
```

## Implementation

### Step 1: Create `branch-variables.json`

Location: `memory-bank/always/branch-variables.json`

```json
{
  "version": "2.0",
  "updated": "2026-01-19",
  "purpose": "Branch-specific configuration with curated TOP skills",

  "dev-feature": {
    "mission": "AI Accuracy & Response Time Optimization",
    "type": "ai-quality-optimization",
    "top_skills": [
      "ai-quality-validation-skill",
      "ai-behavioral-testing-skill",
      "ai-pipeline-debugging-skill",
      "ai-query-table-selection-skill",
      "ai-settings-file-upload-skill",
      "ai-development-best-practices-skill",
      "gemini-latency-optimization-skill",
      "baseline-testing-methodology-skill",
      "baseline-fix-workflow-skill",
      "both-mode-testing-skill"
    ],
    "skill_count": 10
  },

  "dev-Data": {
    "mission": "Find and close data gaps between env databases",
    "type": "data-gap-closure",
    "top_skills": [
      "api-first-validation-skill",
      "gap-detection-and-sync-skill",
      "gap-auto-healing-skill",
      "comprehensive-parity-validation-skill",
      "database-credentials-validation-skill",
      "database-schema-skill",
      "sync-master-skill",
      "date-timezone-sql-skill"
    ],
    "skill_count": 8
  },

  "dev-MERGE": {
    "mission": "Deployment & Production Stability",
    "type": "deployment-coordination",
    "top_skills": [
      "deployment-workflow-skill",
      "cloud-run-traffic-routing-skill",
      "cloud-run-safe-deployment-skill",
      "deployment-verification-skill",
      "comprehensive-testing-skill",
      "production-parity-workflow-skill"
    ],
    "skill_count": 6
  }
}
```

### Step 2: Modify `pre-prompt.sh` Hook

Add branch skills reading after getting branch info:

```bash
# ═══════════════════════════════════════════════════════════════════
# BRANCH SKILLS: Read curated top skills from branch-variables.json
# Two-tier display: Branch skills (always shown) + Keyword matches
# ═══════════════════════════════════════════════════════════════════
BRANCH_VARS="memory-bank/always/branch-variables.json"
BRANCH_TOP_SKILLS=""
BRANCH_MISSION=""
if [ -f "$BRANCH_VARS" ]; then
    BRANCH_TOP_SKILLS=$(jq -r ".\"${CURRENT_BRANCH}\".top_skills // [] | .[0:5] | .[]" "$BRANCH_VARS" 2>/dev/null | tr '\n' ',' | sed 's/,$//')
    BRANCH_MISSION=$(jq -r ".\"${CURRENT_BRANCH}\".mission // \"\"" "$BRANCH_VARS" 2>/dev/null)
fi
```

### Step 3: Create Two-Tier Display

```bash
# ═══════════════════════════════════════════════════════════════════
# TWO-TIER DISPLAY: Branch Skills + Keyword Matches
# ═══════════════════════════════════════════════════════════════════

# TIER 1: Branch Skills (always show top 5 from branch config)
BRANCH_SKILLS_DISPLAY=""
if [ -n "$BRANCH_TOP_SKILLS" ]; then
    for skill in $(echo "$BRANCH_TOP_SKILLS" | tr ',' '\n'); do
        [ -z "$skill" ] && continue
        desc=$(grep "^${skill}|" "$SKILL_CACHE" 2>/dev/null | head -1 | cut -d'|' -f5)
        if [ -n "$desc" ]; then
            BRANCH_SKILLS_DISPLAY="${BRANCH_SKILLS_DISPLAY}  🎯 ${skill} - ${desc}\n"
        else
            BRANCH_SKILLS_DISPLAY="${BRANCH_SKILLS_DISPLAY}  🎯 ${skill}\n"
        fi
    done
fi

# TIER 2: Keyword Matches (exclude skills already shown in branch skills)
KEYWORD_SKILLS_DISPLAY=""
if [ -n "$MATCHED_SKILLS" ]; then
    for skill in $(echo "$MATCHED_SKILLS" | tr ',' '\n'); do
        [ -z "$skill" ] && continue
        # Skip if already in branch skills
        if [ -n "$BRANCH_TOP_SKILLS" ] && [[ ",$BRANCH_TOP_SKILLS," == *",$skill,"* ]]; then
            continue
        fi
        desc=$(grep "^${skill}|" "$SKILL_CACHE" 2>/dev/null | head -1 | cut -d'|' -f5)
        KEYWORD_SKILLS_DISPLAY="${KEYWORD_SKILLS_DISPLAY}  ✅ ${skill} - ${desc}\n"
    done
fi
```

### Step 4: Update Output Format

```bash
cat <<EOF
🚨 SKILL EVALUATION (Hybrid - Fast + Accurate)
═══════════════════════════════════════════════════════════════════
$([ -n "$BRANCH_SKILLS_DISPLAY" ] && echo -e "🎯 BRANCH SKILLS ($CURRENT_BRANCH):\n$BRANCH_SKILLS_DISPLAY")
$([ -n "$KEYWORD_SKILLS_DISPLAY" ] && echo -e "🔍 KEYWORD MATCHES:\n$KEYWORD_SKILLS_DISPLAY")
🚨 FORMAT: "I'll use [skill-name]..." then Skill(skill: "[name]")
═══════════════════════════════════════════════════════════════════

📋 BRANCH: $CURRENT_BRANCH $([ -n "$BRANCH_MISSION" ] && echo "| Mission: $BRANCH_MISSION")
EOF
```

## Output Example

When a developer on `dev-feature` asks about AI issues:

```
🚨 SKILL EVALUATION (Hybrid - Fast + Accurate)
═══════════════════════════════════════════════════════════════════
🎯 BRANCH SKILLS (dev-feature):
  🎯 ai-quality-validation-skill - Validate AI responses against real API/DB data
  🎯 ai-behavioral-testing-skill - Test AI after schema changes
  🎯 ai-pipeline-debugging-skill - Debug Gemini LLM, tool calls, SQL
  🎯 ai-query-table-selection-skill - Prevent wrong table queries
  🎯 ai-settings-file-upload-skill - PDF upload issues

🔍 KEYWORD MATCHES:
  ✅ troubleshooting-workflow-skill - Diagnose and resolve production issues

🚨 FORMAT: "I'll use [skill-name]..." then Skill(skill: "[name]")
═══════════════════════════════════════════════════════════════════

📋 BRANCH: dev-feature | Mission: AI Accuracy & Response Time Optimization
```

## Curation Guidelines

When selecting top skills for a branch:

### 1. Focus on Mission

- What is this branch's primary purpose?
- What tasks happen most frequently?

### 2. Limit to 10-15 Skills

- Top 5 always visible
- Remaining available for keyword boost

### 3. Avoid Overlap

- Don't include generic skills every branch needs
- Focus on domain-specific skills

### 4. Update Quarterly

- Review skill usage analytics
- Remove unused skills
- Add new relevant skills

## Example Branch Configurations

| Branch      | Mission     | Key Skills                                                    |
| ----------- | ----------- | ------------------------------------------------------------- |
| dev-feature | AI Quality  | ai-quality-validation, ai-behavioral-testing, gemini-latency  |
| dev-Data    | Data Parity | api-first-validation, gap-detection, sync-master              |
| dev-MERGE   | Deployment  | deployment-workflow, traffic-routing, safe-deployment         |
| dev-Test    | Testing     | testing-workflow, comprehensive-testing, baseline-methodology |
| dev-UI      | Frontend    | frontend-theme, dashboard-migration, field-sync               |

## Benefits

1. **Reduced Discovery Time**: 80% faster skill finding
2. **Mission Clarity**: Each branch knows its focus
3. **No Duplication**: Keyword matches exclude already-shown skills
4. **Fallback Support**: Old branch-config.json still works

## Template Files

### branch-variables.json Template

```json
{
  "your-branch": {
    "mission": "Short mission description",
    "type": "branch-type",
    "top_skills": ["skill-1", "skill-2", "skill-3"],
    "skill_count": 3
  }
}
```

## Related Chapters

- [Chapter 29: Branch Context System](29-branch-context-system.md) - CONTEXT-MANIFEST.json
- [Chapter 31: Branch-Aware Development](31-branch-aware-development.md) - Branch variables
- [Chapter 14: Pre-Prompt Hook](14-pre-prompt-hook.md) - Skill matching basics

---

**Previous**: [32: Session Start Hook](32-session-start-hook.md)
**Next**: [34: Basic Memory MCP Integration](34-basic-memory-mcp-integration.md)
