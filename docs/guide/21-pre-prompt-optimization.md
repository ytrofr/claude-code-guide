# Chapter 21: Pre-prompt Optimization (Entry #228)

**Status**: Production-Validated (Jan 1, 2026)
**Difficulty**: Intermediate
**Time**: 45 minutes
**ROI**: 68% reduction (28k→9k chars)

---

## Problem

As Claude Code projects grow, the pre-prompt hook output becomes bloated:

**Symptoms**:
- Pre-prompt exceeds 25k+ characters
- Context loading slow (2-3 seconds per query)
- Skills buried under branch instructions, roadmaps, agent lists
- Duplicate content (skills + agents + context all loaded)

**Root Causes**:
1. Loading full branch instructions (1,500+ chars each)
2. Injecting entire roadmap content (2,000+ chars)
3. Agent descriptions bloated (100+ chars each × 50 agents)
4. No filtering - everything loaded regardless of relevance

---

## Solution: Skills-First Ordering

### Core Principle

> **Show ONLY matched skills FIRST, minimize everything else**

### Key Optimizations

1. **Skills-first ordering** (50% reduction)
   - Move matched skills to TOP of output
   - User message visible immediately after skills
   - Context sections AFTER skills

2. **Branch instruction condensation** (62% reduction)
   - Full instructions: 1,500+ chars → Condensed: 500 chars
   - Keep only: Mission, key skills, quick commands
   - Remove: History, detailed explanations, examples

3. **Agent description trimming** (70% reduction)
   - 100+ chars → 30 chars per agent
   - Format: `agent-name: One-line purpose`
   - Remove: Examples, detailed workflows

4. **Keyword pattern optimization** (29 patterns)
   - Add domain-specific synonyms
   - Multi-word phrase detection
   - Stem matching with constraints

---

## Implementation

### Step 1: Update pre-prompt.sh Structure

```bash
#!/bin/bash
# Pre-prompt hook - Skills-First Ordering (Entry #228)

# 1. SKILLS FIRST (most important)
echo "═══════════════════════════════════════════════"
echo "🎯 MATCHED SKILLS FOR YOUR QUERY"
echo "═══════════════════════════════════════════════"
MATCHED_SKILLS=$(match_skills "$USER_MESSAGE")
for skill in $(echo "$MATCHED_SKILLS" | tr ',' '\n'); do
    echo "  ✅ $skill"
done

# 2. USER MESSAGE (visible immediately)
echo ""
echo "Original user message:"
echo "$USER_MESSAGE"

# 3. CONDENSED BRANCH CONTEXT (minimal)
echo ""
echo "═══ BRANCH INSTRUCTIONS (Condensed) ═══"
cat "CURRENT/$BRANCH/$BRANCH-Instructions.md" | head -30
```

### Step 2: Create Condensed Branch Instructions

**Before** (1,500+ chars):
```markdown
# dev-Knowledge Branch Instructions

**Created**: 2025-12-14
**Updated**: 2026-01-01
**Mission**: Knowledge, Context, Agents, Skills & MCP Optimization
...
[Full history, examples, detailed workflows]
```

**After** (500 chars):
```markdown
# dev-Knowledge Branch Instructions

**Mission**: Skills, Context, Agents & MCP Optimization
**Phase**: wshobson Marketplace Integration

## Key Skills
- context-optimization-skill
- skills-first-ordering-skill
- entry-to-skill-conversion-skill

## Quick Commands
```bash
echo "test" | bash .claude/hooks/pre-prompt.sh | wc -c
```
```

### Step 3: Add Keyword Patterns (29 total)

```bash
# In match_skills() function, add synonym expansions:

# RAG/AI patterns
echo "$msg_lower" | grep -qiE "\b(rag|embedding|vector)\b" && \
    expanded_msg="$expanded_msg rag embedding vector semantic"

# Deployment patterns
echo "$msg_lower" | grep -qiE "\b(deploy|staging|production)\b" && \
    expanded_msg="$expanded_msg deploy deployment gcp cloud"

# Database patterns
echo "$msg_lower" | grep -qiE "\b(db|database|postgres|sql)\b" && \
    expanded_msg="$expanded_msg database postgres sql query"

# Testing patterns
echo "$msg_lower" | grep -qiE "\b(test|spec|jest|playwright)\b" && \
    expanded_msg="$expanded_msg testing test e2e unit"

# Add your domain-specific patterns here...
```

---

## Evidence

### Before Fix (Dec 2025)
```bash
echo "test query" | bash .claude/hooks/pre-prompt.sh | wc -c
# Output: 28,432 characters
```

### After Fix (Jan 1, 2026)
```bash
echo "test query" | bash .claude/hooks/pre-prompt.sh | wc -c
# Output: 9,127 characters (68% reduction!)
```

### Test Results

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Pre-prompt size | 28k chars | 9k chars | **68% reduction** |
| Skills position | Buried | **FIRST** | Instant visibility |
| Branch instructions | 1,500 chars | 500 chars | 67% reduction |
| Agent descriptions | 5,000 chars | 1,500 chars | 70% reduction |
| Keyword patterns | 12 | 29 | 142% more coverage |

---

## Validation

### Quick Test (2 min)

```bash
# Check current size
echo "test" | bash .claude/hooks/pre-prompt.sh | wc -c

# Target: <12,000 characters
# If >15,000: Apply optimizations above
```

### Skills-First Verification

```bash
# Skills should appear in first 50 lines
echo "database query" | bash .claude/hooks/pre-prompt.sh | head -50 | grep -i skill

# Expected: Multiple skill matches visible
```

### Activation Test

Start fresh session and ask:
```
How do I optimize my context files?
```

**Expected**:
- ✅ `context-optimization-skill` matched FIRST
- ✅ Claude says "I'll use context-optimization-skill..."
- ✅ Response uses skill patterns

---

## Troubleshooting

### Issue: Pre-prompt still >15k chars

**Check branch instructions size**:
```bash
wc -c CURRENT/$BRANCH/$BRANCH-Instructions.md
# Target: <600 chars
```

**Condense if needed**:
- Remove history sections
- Remove examples (keep in skill files)
- Keep only: Mission, skills, quick commands

### Issue: Skills not appearing first

**Check hook output order**:
```bash
echo "test" | bash .claude/hooks/pre-prompt.sh | head -20
```

**Expected first lines**:
```
═══════════════════════════════════════════════
🎯 MATCHED SKILLS FOR YOUR QUERY
```

### Issue: Wrong skills matched

**Add more keyword patterns** for your domain:
```bash
# In pre-prompt.sh match_skills():
echo "$msg_lower" | grep -qiF "your-keyword" && \
    expanded_msg="$expanded_msg related terms"
```

---

## Monitoring

### Weekly Check (5 min)

```bash
# Check pre-prompt size trend
for i in 1 2 3; do
    echo "Query $i:" && echo "test $i" | bash .claude/hooks/pre-prompt.sh | wc -c
done

# All should be <12,000 chars
```

### Monthly Review

- [ ] Pre-prompt size <12k chars
- [ ] Skills appear in first 50 lines
- [ ] Activation rate >80%
- [ ] No bloated branch instructions

---

## Success Metrics

| Metric | Target | How to Check |
|--------|--------|--------------|
| Pre-prompt size | <12k chars | `wc -c` on hook output |
| Skills position | First section | `head -50` shows skills |
| Branch instructions | <600 chars | `wc -c` on Instructions.md |
| Activation rate | >80% | Claude uses skills-first |

---

## Related Chapters

- **Chapter 20**: Skills Filtering Optimization (score-at-match-time)
- **Chapter 17**: Skill Detection Enhancement (4-phase matching)
- **Chapter 13**: Claude Code Hooks (hook basics)

---

**Implementation Time**: 45 minutes
**Evidence**: LimorAI production (28k→9k chars, 68% reduction)
**Last Updated**: 2026-01-05