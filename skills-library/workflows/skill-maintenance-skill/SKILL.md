---
name: skill-maintenance-skill
description: "Monthly skill library maintenance with audit scripts and gap detection. Use when auditing skills for 'Use when' patterns, checking activation rates, or maintaining skill quality."
---

# Skill Maintenance Skill

Systematic monthly maintenance for skill libraries to ensure 100% activation rate.

## Quick Start

```bash
# Run monthly audit (Week 1)
for skill in ~/.claude/skills/*-skill/SKILL.md; do
    if ! grep -q "Use when" "$skill" 2>/dev/null; then
        echo "❌ $(basename $(dirname $skill))"
    fi
done | tee /tmp/skill-audit.txt

# Count results
echo "Missing 'Use when': $(cat /tmp/skill-audit.txt | wc -l)"
```

## Monthly Schedule

### Week 1: Audit Check
- Run bulk audit script
- Target: 0 skills missing "Use when"
- Fix any gaps immediately

### Week 2: Fresh Session Testing
Test 10 natural language queries:
1. "we have issue with [domain]"
2. "test the [feature]"
3. "check [system] status"
4. "deploy to [environment]"
5. "[domain] not working"

**Target**: 80% activation rate, 90% correct skill

### Week 3: Gap Analysis
If targets not met:
1. Identify failing patterns
2. Add synonym expansion to pre-prompt.sh
3. Update CRITICAL_KEYWORDS if needed
4. Create missing skills

### Week 4: Documentation
- Update test guide with new tests
- Log results in roadmap
- Create Entry if significant changes

## "Use when" Standard

**Every skill MUST have**:
```yaml
description: "[What]. Use when [scenarios]."
```

**Examples**:
```yaml
# ✅ GOOD
description: "Debug database issues. Use when seeing ECONNREFUSED, auth failures, or pool exhaustion."

# ❌ BAD
description: "Database skill."
```

## Audit Script (Full)

```bash
#!/bin/bash
# skill-audit.sh - Monthly skill library audit

echo "=== SKILL LIBRARY AUDIT ==="
echo "Date: $(date)"
echo ""

TOTAL=0
MISSING=0

for skill in ~/.claude/skills/*-skill/SKILL.md; do
    [ -f "$skill" ] || continue
    TOTAL=$((TOTAL + 1))
    
    if ! grep -q "Use when" "$skill" 2>/dev/null; then
        MISSING=$((MISSING + 1))
        echo "❌ $(basename $(dirname $skill))"
    fi
done

echo ""
echo "=== SUMMARY ==="
echo "Total skills: $TOTAL"
echo "With 'Use when': $((TOTAL - MISSING))"
echo "Missing: $MISSING"
echo "Coverage: $(( (TOTAL - MISSING) * 100 / TOTAL ))%"

if [ $MISSING -eq 0 ]; then
    echo "✅ 100% coverage - audit passed!"
else
    echo "⚠️ Fix $MISSING skills to reach 100%"
fi
```

## Fresh Session Test Script

```bash
#!/bin/bash
# test-skill-activation.sh - Fresh session activation test

TESTS=(
    "issue with database connection"
    "deploy to staging"
    "test the migration"
    "whatsapp webhook"
    "semantic query routing"
    "check cache status"
    "pr review needed"
    "sync gap detected"
    "visual regression test"
    "mcp postgres server"
)

echo "=== FRESH SESSION SKILL ACTIVATION TEST ==="
echo ""

for test in "${TESTS[@]}"; do
    echo "Query: \"$test\""
    result=$(echo "$test" | bash ~/.claude/hooks/pre-prompt.sh 2>/dev/null | grep -i skill | head -3)
    if [ -n "$result" ]; then
        echo "✅ Skills: $result"
    else
        echo "❌ No skills matched"
    fi
    echo ""
done
```

## Gap Detection

When skill doesn't activate:

1. **Check synonym expansion**:
   ```bash
   grep -i "[keyword]" ~/.claude/hooks/pre-prompt.sh
   ```

2. **Check CRITICAL_KEYWORDS**:
   ```bash
   grep "CRITICAL_KEYWORDS" ~/.claude/hooks/pre-prompt.sh
   ```

3. **Create missing skill if needed**:
   ```bash
   mkdir -p ~/.claude/skills/[domain]-skill
   # Create SKILL.md with proper "Use when" pattern
   ```

## Success Metrics

| Metric | Target | Action if Below |
|--------|--------|-----------------|
| "Use when" coverage | 100% | Fix immediately |
| Activation rate | 80% | Add synonyms |
| Correct skill | 90% | Refine patterns |

## References

- Chapter 17: Skill Detection Enhancement
- Chapter 24: Skill Keyword Enhancement Methodology
- Entry #244: Phases 3+4 implementation
