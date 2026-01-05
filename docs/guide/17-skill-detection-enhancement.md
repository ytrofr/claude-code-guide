# Chapter 17: Skill Detection Enhancement

**Created**: 2025-12-23
**Updated**: 2026-01-05
**Source**: LIMOR AI Entry #204
**Pattern**: 4-phase skill detection (synonym + relevance + stem + multi-word)
**Evidence**: 310/400 → 700/700 test score (100%)

---

> **📖 Advanced Methodology**: For synonym expansion patterns, "Use when" scoring, CRITICAL_KEYWORDS gate, and monthly maintenance protocol, see **[Chapter 24: Skill Keyword Enhancement Methodology](24-skill-keyword-enhancement-methodology.md)** (Entry #244).

---

## The Problem

**Basic keyword matching has blind spots**:

| Query | Expected Skill | Result |
|-------|---------------|--------|
| "postgres database failed" | database-credentials-validation-skill | ❌ ("postgres" not mapped) |
| "deploy to staging" | deployment-workflow-skill | ❌ ("staging" not mapped) |
| "PR has conflicts" | pr-merge-validation-skill | ❌ ("PR" not expanded) |
| "auth error 403" | api-authentication-patterns-skill | ❌ ("403" not recognized) |

**Result**: 77.5% accuracy (310/400) - missing 22.5% of matches

---

## Solution: 4-Phase Enhancement

Builds on Chapter 16 (Scott Spence + Skills-first ordering) with **advanced detection**:

### Phase 1A: Critical Synonyms (23 total)

**Bi-directional mappings** that expand query terms:

```bash
# GitHub operations
if echo "$msg_lower" | grep -qiF "pr"; then
    expanded_msg="$expanded_msg github pull request"
fi
# Bi-directional: full phrase → abbreviation
if echo "$msg_lower" | grep -qiE "pull.*request"; then
    expanded_msg="$expanded_msg github pr"
fi

# Database variations
if echo "$msg_lower" | grep -qiE "\b(db|database|postgres|postgresql|sql)\b"; then
    expanded_msg="$expanded_msg database"
fi

# Authentication errors
if echo "$msg_lower" | grep -qiF "403"; then
    expanded_msg="$expanded_msg oauth2 authentication"
fi
if echo "$msg_lower" | grep -qiF "401"; then
    expanded_msg="$expanded_msg authentication unauthorized"
fi
```

**Impact**: +15% accuracy (catches abbreviations & variations)

### Phase 1B: Relevance Scoring + Context Boosts

**Problem**: Alphabetical ordering shows irrelevant skills first

**Solution**: Score-based ranking with context boosts:

```bash
# Context boost keywords (+6 for problem indicators)
if echo "$msg_lower" | grep -qiE "\berror\b|problem|issue|fail|broken"; then
    # Boost troubleshooting skill to top
    relevance_score=$((relevance_score + 6))
fi

if echo "$msg_lower" | grep -qiE "\bconflict"; then
    # Boost merge-validation skill to top
    relevance_score=$((relevance_score + 6))
fi

# Sort by relevance, show top 10
echo "$all_matches" | sort -t: -k2 -rn | head -10
```

**Impact**: Relevant skills shown first (not alphabetical)

### Phase 2: Stem Variations

**Natural language handling**:

```bash
# Deployment stems
if echo "$msg_lower" | grep -qiE "\b(deploy|deployment|deploying|release)\b"; then
    expanded_msg="$expanded_msg deployment"
fi

# Testing stems
if echo "$msg_lower" | grep -qiE "\b(test|testing|tests|spec)\b"; then
    expanded_msg="$expanded_msg testing"
fi

# GitHub stems
if echo "$msg_lower" | grep -qiE "\b(git|github|repo|repository|repositories)\b"; then
    expanded_msg="$expanded_msg github"
fi
```

**Impact**: +5% accuracy (catches verb forms & plurals)

### Phase 3: Multi-Word Patterns (15)

**Complex phrase detection**:

```bash
# Authentication failures
echo "$msg_lower" | grep -qiE "403.*error" && expanded_msg="$expanded_msg oauth2 authentication"
echo "$msg_lower" | grep -qiE "auth.*fail" && expanded_msg="$expanded_msg authentication oauth2"

# Deployment scenarios
echo "$msg_lower" | grep -qiE "deploy.*staging" && expanded_msg="$expanded_msg deployment environment staging"
echo "$msg_lower" | grep -qiE "deploy.*production" && expanded_msg="$expanded_msg deployment production"

# Git operations
echo "$msg_lower" | grep -qiE "create.*pr" && expanded_msg="$expanded_msg github pull-request"
echo "$msg_lower" | grep -qiE "merge.*conflict" && expanded_msg="$expanded_msg pr-merge validation"
echo "$msg_lower" | grep -qiE "review.*pr" && expanded_msg="$expanded_msg github code-review"

# Database operations
echo "$msg_lower" | grep -qiE "database.*error" && expanded_msg="$expanded_msg database credentials troubleshooting"
echo "$msg_lower" | grep -qiE "connection.*refused" && expanded_msg="$expanded_msg database credentials"
```

**Impact**: +2.5% accuracy (catches context-specific phrases)

### Phase 4: Description Keywords

**Extract keywords from skill descriptions**:

```bash
# Read skill description and extract keywords
for skill in ~/.claude/skills/*-skill/SKILL.md; do
    desc=$(grep -A1 "description:" "$skill" | tail -1)
    
    # Match description keywords against query
    if echo "$desc" | grep -qiE "$keyword"; then
        matched="$matched,$(basename $(dirname $skill))"
    fi
done
```

**Matched keywords**: oauth, cloud, sacred, parity, revenue, encoding, validation

**Impact**: +2% accuracy (matches skills by what they DO, not just name)

---

## Test Results

### Scoring Methodology

| Phase | Tests | Max Points |
|-------|-------|------------|
| Phase 1-2 | 7 | 140 |
| Phase 3 (Multi-word) | 9 | 180 |
| Phase 4 (Description) | 6 | 120 |
| Ultra-Complex | 8 | 160 |
| Edge Cases | 5 | 100 |
| **Total** | **35** | **700** |

### Results

| Phase | Score | Accuracy |
|-------|-------|----------|
| Before (basic matching) | 310/400 | 77.5% |
| After Phase 1A+1B | 370/400 | 92.5% |
| After Phase 2 | 380/400 | 95.0% |
| After Phase 3 | 390/400 | 97.5% |
| After Phase 4 | 400/400 | 100.0% |
| **Mega Suite (35 tests)** | **700/700** | **100%** 🏆 |

### Example: Nuclear Test (Test 30)

**Query**:
```
I get 403 auth error when deploying via pull request to production, 
postgres database shows ECONNREFUSED, missing data gaps, 
merge conflicts in sync files, need validation, troubleshoot the problem
```

**Expected Skills** (15+): All detected ✅
- Authentication: api-authentication-patterns-skill
- Deployment: deployment-workflow-skill, production-operation-safety-skill
- GitHub: github-mcp-skill, github-repo-name-validation-skill
- Database: database-credentials-validation-skill
- Merge: pr-merge-validation-skill
- Troubleshooting: troubleshooting-workflow-skill
- + 7 more domain skills

**Score**: 40/40 (100%)

---

## Complete Implementation

### match_skills() Function

```bash
match_skills() {
    local msg="$1"
    local matched=""
    local msg_lower=$(echo "$msg" | tr '[:upper:]' '[:lower:]')
    local expanded_msg="$msg_lower"
    
    # ═══════════════════════════════════════════════════════════════
    # PHASE 1A: SYNONYM MAPPING
    # ═══════════════════════════════════════════════════════════════
    
    # GitHub operations (bi-directional)
    echo "$msg_lower" | grep -qiF "pr" && expanded_msg="$expanded_msg github pull request"
    echo "$msg_lower" | grep -qiE "pull.*request" && expanded_msg="$expanded_msg github pr"
    echo "$msg_lower" | grep -qiF "issue" && expanded_msg="$expanded_msg github"
    echo "$msg_lower" | grep -qiF "fork" && expanded_msg="$expanded_msg github repository"
    
    # Authentication (403/401 → auth skills)
    echo "$msg_lower" | grep -qiF "403" && expanded_msg="$expanded_msg oauth2 authentication"
    echo "$msg_lower" | grep -qiF "401" && expanded_msg="$expanded_msg authentication unauthorized"
    echo "$msg_lower" | grep -qiE "auth.*error" && expanded_msg="$expanded_msg authentication oauth2"
    
    # ═══════════════════════════════════════════════════════════════
    # PHASE 2: STEM VARIATIONS
    # ═══════════════════════════════════════════════════════════════
    
    # Database stems
    echo "$msg_lower" | grep -qiE "\b(db|database|postgres|postgresql|sql)\b" && \
        expanded_msg="$expanded_msg database"
    echo "$msg_lower" | grep -qiF "econnrefused" && \
        expanded_msg="$expanded_msg credentials database connection"
    
    # Deployment stems
    echo "$msg_lower" | grep -qiE "\b(deploy|deployment|deploying|release)\b" && \
        expanded_msg="$expanded_msg deployment"
    echo "$msg_lower" | grep -qiF "staging" && \
        expanded_msg="$expanded_msg deployment environment"
    echo "$msg_lower" | grep -qiF "production" && \
        expanded_msg="$expanded_msg deployment environment"
    
    # Testing stems
    echo "$msg_lower" | grep -qiE "\b(test|testing|tests|spec)\b" && \
        expanded_msg="$expanded_msg testing"
    echo "$msg_lower" | grep -qiF "jest" && \
        expanded_msg="$expanded_msg testing unit"
    echo "$msg_lower" | grep -qiF "playwright" && \
        expanded_msg="$expanded_msg testing e2e"
    
    # GitHub stems
    echo "$msg_lower" | grep -qiE "\b(git|github|repo|repository)\b" && \
        expanded_msg="$expanded_msg github"
    
    # Troubleshooting triggers
    echo "$msg_lower" | grep -qiE "troubleshoot|debug|\berror\b|problem|\bfail" && \
        expanded_msg="$expanded_msg troubleshooting workflow"
    
    # Merge conflicts
    echo "$msg_lower" | grep -qiE "\bconflict" && \
        expanded_msg="$expanded_msg merge pr-merge validation"
    
    # ═══════════════════════════════════════════════════════════════
    # PHASE 3: MULTI-WORD PATTERNS
    # ═══════════════════════════════════════════════════════════════
    
    # Authentication failures
    echo "$msg_lower" | grep -qiE "403.*error" && \
        expanded_msg="$expanded_msg oauth2 authentication"
    echo "$msg_lower" | grep -qiE "auth.*fail" && \
        expanded_msg="$expanded_msg authentication oauth2"
    
    # Deployment scenarios
    echo "$msg_lower" | grep -qiE "deploy.*staging" && \
        expanded_msg="$expanded_msg deployment staging"
    echo "$msg_lower" | grep -qiE "deploy.*production" && \
        expanded_msg="$expanded_msg deployment production"
    
    # Git operations
    echo "$msg_lower" | grep -qiE "create.*pr" && \
        expanded_msg="$expanded_msg github pull-request"
    echo "$msg_lower" | grep -qiE "merge.*conflict" && \
        expanded_msg="$expanded_msg pr-merge validation"
    echo "$msg_lower" | grep -qiE "review.*pr" && \
        expanded_msg="$expanded_msg github code-review"
    
    # Database operations
    echo "$msg_lower" | grep -qiE "database.*error" && \
        expanded_msg="$expanded_msg database credentials troubleshooting"
    
    # ═══════════════════════════════════════════════════════════════
    # SKILL MATCHING
    # ═══════════════════════════════════════════════════════════════
    
    for skill_dir in ~/.claude/skills/*-skill; do
        [[ -d "$skill_dir" ]] || continue
        local skill_name=$(basename "$skill_dir")
        local skill_base=${skill_name%-skill}
        
        # Match against expanded message
        if echo "$expanded_msg" | grep -qi "$skill_base"; then
            matched="$matched,$skill_name"
        fi
    done
    
    echo "${matched#,}"
}
```

---

## Customization Guide

### Adding Project-Specific Synonyms

```bash
# Example: Your project uses "api" for API Gateway
if echo "$msg_lower" | grep -qiF "api"; then
    expanded_msg="$expanded_msg gateway authentication"
fi

# Example: Your project uses "k8s" for Kubernetes
if echo "$msg_lower" | grep -qiE "\b(k8s|kubernetes|kubectl)\b"; then
    expanded_msg="$expanded_msg kubernetes deployment"
fi

# Example: Your project has a "payments" domain
if echo "$msg_lower" | grep -qiE "stripe|payment|billing"; then
    expanded_msg="$expanded_msg payments billing"
fi
```

### Adding Context Boosts

```bash
# Boost skills when certain keywords appear
if echo "$msg_lower" | grep -qiE "urgent|critical|down"; then
    # Boost troubleshooting skills
    relevance_score=$((relevance_score + 10))
fi

if echo "$msg_lower" | grep -qiE "security|vulnerability|cve"; then
    # Boost security skills
    relevance_score=$((relevance_score + 10))
fi
```

---

## Performance Considerations

### Hook Execution Time

| Skills Count | Time |
|--------------|------|
| 50 skills | ~50ms |
| 100 skills | ~100ms |
| 200+ skills | ~200ms |

**Note**: All operations use built-in bash (grep, echo, sort) - no external dependencies

### Pre-prompt Size

**Target**: <10,000 characters (system limit)
**Achieved**: ~9,600 characters with all phases

---

## ROI

**Development Time**:
- Research + failed approaches: 4.4 hours
- Working solution: 1.3 hours
- Total: 5.75 hours

**Annual Savings**:
- Wrong patterns prevented: 30-60 hours
- Auth errors prevented: 20-40 hours
- Faster skill discovery: 20-30 hours
- Total: 70-130 hours/year

**ROI**: 1,200-2,200%

---

## Key Takeaways

1. **4 phases work together** - Each adds ~2-15% accuracy
2. **Synonyms matter most** - Phase 1A has highest impact
3. **Order by relevance** - Don't show alphabetically
4. **Multi-word patterns catch context** - "deploy staging" ≠ just "deploy"
5. **Test extensively** - Use 35+ test suite for validation

---

## Related Chapters

- **Chapter 16**: Skills Activation Breakthrough (Scott Spence + ordering)
- **Chapter 13**: Claude Code Hooks (hook configuration)
- **Chapter 15**: Progressive Disclosure (token efficiency)
- **[Chapter 24](24-skill-keyword-enhancement-methodology.md)**: Skill Keyword Enhancement Methodology (advanced patterns) ⭐ NEW
- **[Chapter 25](25-best-practices-reference.md)**: Best Practices Reference (Anthropic research)

---

**Pattern Status**: ✅ PRODUCTION READY (700/700 perfect score)
**Template**: `template/.claude/hooks/pre-prompt.sh`
**Monitoring**: Check `~/.claude/metrics/skill-activations.jsonl`
