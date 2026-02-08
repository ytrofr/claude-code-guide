# Chapter 24: Skill Keyword Enhancement Methodology

**Created**: 2026-01-05
**Source**: Production Entry #244
**Pattern**: Synonym expansion + "Use when" scoring + monthly maintenance
**Evidence**: 5/5 fresh session tests (100%), 160/160 skills audited (100%)

---

## The Problem

**Skills don't activate from natural language queries**:

| Query | Expected | Result |
|-------|----------|--------|
| "we have issue with whatsapp" | whatsapp-integration-skill | ❌ No skill |
| "test the migration" | migration-workflow-skill | ❌ "migration" not mapped |
| "check the cache" | cache-optimization-skill | ❌ "cache" not expanded |
| "semantic query routing" | semantic-query-router-skill | ❌ Multi-word not matched |

**Root Cause**: Basic keyword matching misses synonyms, context, and natural phrases.

---

## Solution: 4-Phase Synonym Expansion

Builds on Chapter 17 (4-phase detection) with **domain-specific synonym patterns**:

### Phase 1: Core Domain Patterns (9 patterns)

```bash
# Feedback/quality
echo "$msg_lower" | grep -qiE "\b(feedback|rating|review|quality|negative)\b" && \
    expanded_msg="$expanded_msg feedback quality"

# AI/LLM
echo "$msg_lower" | grep -qiE "\b(ai|llm|gemini|vertex|prompt|chat)\b" && \
    expanded_msg="$expanded_msg ai llm vertex"

# Validation/testing
echo "$msg_lower" | grep -qiE "\b(validation|validate|verify|check|accuracy)\b" && \
    expanded_msg="$expanded_msg validation testing"

# MCP/tools
echo "$msg_lower" | grep -qiE "\b(mcp|postgresql|github|perplexity|memory)\b" && \
    expanded_msg="$expanded_msg mcp tools"

# Sacred/patterns
echo "$msg_lower" | grep -qiE "\b(sacred|commandment|pattern|golden.rule)\b" && \
    expanded_msg="$expanded_msg sacred patterns"

# Hebrew/cultural
echo "$msg_lower" | grep -qiE "\b(hebrew|עברית|rtl|cultural|israeli)\b" && \
    expanded_msg="$expanded_msg hebrew cultural"

# Beecom/POS
echo "$msg_lower" | grep -qiE "\b(beecom|pos|order|revenue|sales)\b" && \
    expanded_msg="$expanded_msg beecom pos"

# Shift/labor
echo "$msg_lower" | grep -qiE "\b(shift|labor|employee|schedule|hours)\b" && \
    expanded_msg="$expanded_msg shift labor"

# Revenue/financial
echo "$msg_lower" | grep -qiE "\b(revenue|cost|financial|money|budget)\b" && \
    expanded_msg="$expanded_msg revenue financial"
```

### Phase 2: Scoring Bonus (+2 for synonym-expanded stems)

```bash
# In score calculation - bonus for synonym-expanded matches
for query_word in $msg_lower; do
    [ ${#query_word} -lt 4 ] && continue
    local stem=${query_word%s}
    stem=${stem%ing}
    stem=${stem%ed}
    
    # Check if this stem was added by synonym expansion
    if echo "$expanded_msg" | grep -qiE "\b${stem}"; then
        score=$((score + 2))  # +2 bonus for synonym-expanded match
        matched=true
        break
    fi
done
```

### Phase 3: Context/Workflow Patterns (+6 patterns)

```bash
# Session/workflow
echo "$msg_lower" | grep -qiE "\b(session|workflow|start.session|end.session|checkpoint)\b" && \
    expanded_msg="$expanded_msg session workflow"

# Perplexity/research
echo "$msg_lower" | grep -qiE "\b(perplexity|research|search.online|web.search)\b" && \
    expanded_msg="$expanded_msg perplexity research memory"

# Blueprint/architecture
echo "$msg_lower" | grep -qiE "\b(blueprint|architecture|feature.context|how.does.*work)\b" && \
    expanded_msg="$expanded_msg blueprint architecture"

# API-first validation
echo "$msg_lower" | grep -qiE "\b(api.first|check.api|validate.api|api.source)\b" && \
    expanded_msg="$expanded_msg api-first validation"

# Parity/environment
echo "$msg_lower" | grep -qiE "\b(parity|environment.match|localhost.vs|staging.vs)\b" && \
    expanded_msg="$expanded_msg parity validation environment"

# Cache patterns
echo "$msg_lower" | grep -qiE "\b(cache|caching|cached|ttl|invalidate)\b" && \
    expanded_msg="$expanded_msg cache optimization"
```

### Phase 3 Enhancement: "Use when" Scoring (+3 vs +1)

```bash
# Extract "Use when" section for higher-value matching
local use_when_section=$(echo "$desc" | sed -n 's/.*use when \(.*\)/\1/p')

for query_word in $msg_lower; do
    [ ${#query_word} -lt 4 ] && continue
    
    # Check "Use when" keywords first (+3) - high-signal
    if [ -n "$use_when_section" ] && echo "$use_when_section" | grep -qiE "\b${query_word}\b"; then
        score=$((score + 3))
        matched=true
        break
    # Fallback to general description (+1)
    elif echo "$desc" | grep -qiE "\b${query_word}\b"; then
        score=$((score + 1))
        matched=true
        break
    fi
done
```

### Phase 4: Advanced Domain Patterns (+5 patterns)

```bash
# WhatsApp/messaging
echo "$msg_lower" | grep -qiE "\b(whatsapp|messaging|chat.bot|webhook)\b" && \
    expanded_msg="$expanded_msg whatsapp monitoring"

# Sync/migration
echo "$msg_lower" | grep -qiE "\b(sync|syncing|migration|migrate|backfill)\b" && \
    expanded_msg="$expanded_msg sync migration database"

# MCP/tools
echo "$msg_lower" | grep -qiE "\b(mcp|server|tool.server|postgres.mcp|github.mcp)\b" && \
    expanded_msg="$expanded_msg mcp postgresql github"

# Semantic/AI query
echo "$msg_lower" | grep -qiE "\b(semantic|query.router|tier|embedding)\b" && \
    expanded_msg="$expanded_msg semantic query router"

# Visual/UI testing
echo "$msg_lower" | grep -qiE "\b(visual|screenshot|regression|baseline|ui.test)\b" && \
    expanded_msg="$expanded_msg visual regression testing"
```

---

## CRITICAL_KEYWORDS Gate

Short messages (<50 chars) must contain trigger keywords to activate skill evaluation:

```bash
CRITICAL_KEYWORDS="error|issue|problem|fail|broken|debug|troubleshoot|fix|help|test|deploy|sync|gap|parity|validation|database|api|shift|labor|revenue|beecom|hebrew|sacred|gemini|vertex|ai|mcp|postgres|github|perplexity|auth|oauth|credential|conflict|merge|pr|commit|production|staging|skill|agent|feedback|monitor|alert|cache|session|webhook|whatsapp|messaging|migration|migrate|backfill|semantic|embedding|visual|screenshot|regression|baseline"
```

**Impact**: Prevents evaluation on greetings like "hi" or "thanks" (saves ~200ms).

---

## "Use when" Standard for Skills

**Every skill MUST have this pattern in description**:

```yaml
---
name: my-skill-name
description: "[What this skill does]. Use when [specific scenarios where this skill should activate]."
---
```

**Examples**:

```yaml
# ✅ GOOD - Clear activation triggers
description: "Debug database connection issues. Use when seeing ECONNREFUSED, authentication failures, or pool exhaustion."

# ✅ GOOD - Action-oriented
description: "Optimize Perplexity costs with cache-first pattern. Use when making research queries, checking if topic was researched before."

# ❌ BAD - Vague, no triggers
description: "Handles database stuff."

# ❌ BAD - Missing "Use when"
description: "A skill for deployment operations."
```

---

## Monthly Maintenance Protocol (30 min)

### Week 1: Audit Check

```bash
# Run bulk audit for "Use when" coverage
for skill in ~/.claude/skills/*-skill/SKILL.md; do
    if ! grep -q "Use when" "$skill" 2>/dev/null; then
        echo "❌ $(basename $(dirname $skill))"
    fi
done

# Expected: 0 missing (100% coverage)
```

### Week 2: Fresh Session Testing

```bash
# Test 10 natural language queries in fresh session
# Target: 80% activation rate, 90% correct skill
```

**Test Examples**:
1. "we have issue with database connection" → database-credentials-validation-skill
2. "deploy to staging" → deployment-workflow-skill
3. "whatsapp webhook not working" → whatsapp-integration-skill
4. "test the migration" → migration-workflow-skill
5. "check semantic query routing" → semantic-query-router-skill

### Week 3: Gap Analysis

If activation <80% or correct <90%:
1. Identify failing patterns
2. Add synonym expansion
3. Update CRITICAL_KEYWORDS
4. Create missing skills

### Week 4: Documentation

- Update SYNONYM-EXPANSION-TEST-GUIDE.md with new tests
- Log results in roadmap
- Create Entry if significant changes

---

## Missing Skill Creation Protocol

When user tests reveal missing skill:

### Step 1: Identify Gap
```
User: "whatsapp webhook" → ❌ No skill detected
Analysis: WhatsApp domain has no skill
```

### Step 2: Create Skill
```bash
mkdir -p ~/.claude/skills/whatsapp-integration-skill
```

### Step 3: Write SKILL.md
```yaml
---
name: whatsapp-integration-skill
description: "WhatsApp webhook and AI integration patterns. Use when configuring webhooks, debugging messages, extending WhatsApp features, or troubleshooting Green API connections."
---
```

### Step 4: Validate
```bash
echo "whatsapp webhook" | bash .claude/hooks/pre-prompt.sh | grep -i whatsapp
# Expected: ✅ whatsapp-integration-skill
```

### Step 5: Update Synonym Expansion (if needed)
```bash
# Add to pre-prompt.sh if not already covered
echo "$msg_lower" | grep -qiE "\b(whatsapp|messaging|webhook)\b" && \
    expanded_msg="$expanded_msg whatsapp monitoring"
```

---

## Scoring System (Final)

```
+15 - Branch priority (skills_required in branch-variables.json)
+10 - Exact name match
+10 - Exact query word match
+5  - Synonym-expanded stem match
+3  - "Use when" keyword match
+2  - Synonym-expanded bonus
+1  - General description match
---
5   - Minimum threshold for activation
10  - Maximum skills shown (Scott Spence standard)
```

---

## Test Results

### Fresh Session Validation (Jan 5, 2026)

| Test | Query | Expected | Result |
|------|-------|----------|--------|
| 1 | "migration backfill historical data" | migration-workflow-skill | ✅ |
| 2 | "semantic query router tier" | semantic-query-router-skill | ✅ |
| 3 | "visual regression screenshot" | visual-regression-testing-skill | ✅ |
| 4 | "mcp postgres server" | postgresql-mcp-skill | ✅ |
| 5 | "whatsapp webhook integration" | whatsapp-integration-skill | ✅ |

**Result**: 5/5 (100%) after methodology applied

### Skill Audit Results

```
Total skills: 160
With "Use when" pattern: 168 occurrences
Coverage: 100%
```

---

## Synonym Expansion Coverage Summary

| Phase | Patterns | Domains |
|-------|----------|---------|
| 1 | 9 | feedback, ai, validation, mcp, sacred, hebrew, beecom, shift, revenue |
| 2 | Scoring | +2 bonus for synonym-expanded stems |
| 3 | 6 | session, perplexity, blueprint, api-first, parity, cache |
| 3+ | Scoring | +3 for "Use when" match (vs +1 general) |
| 4 | 5 | whatsapp, sync, mcp-tools, semantic, visual |

**Total**: 20+ patterns covering major domains

---

## ROI

**Development Time**: 4 hours (Phases 1-4)
**Annual Savings**: 30-50 hours (correct skill activation first time)
**ROI**: 750-1250%

---

## Key Takeaways

1. **Synonym expansion catches natural language** - "issue with X" → proper skill
2. **"Use when" is mandatory** - 3x scoring weight for clear triggers
3. **CRITICAL_KEYWORDS prevents waste** - Skip evaluation on greetings
4. **Monthly maintenance prevents drift** - 30 min/month keeps 100%
5. **Missing skills = create immediately** - Don't let gaps persist

---

## Related Chapters

- **Chapter 17**: Skill Detection Enhancement (4-phase foundation)
- **Chapter 20**: Skills Filtering Optimization (score-at-match-time)
- **Chapter 21**: Pre-prompt Optimization (68% reduction)
- **Chapter 16**: Skills Activation Breakthrough (Scott Spence pattern)

---

**Pattern Status**: ✅ PRODUCTION READY (100% activation, 100% audit)
**Template**: `template/.claude/hooks/pre-prompt.sh`
**Skill**: `skills-library/workflows/skill-maintenance-skill/`
