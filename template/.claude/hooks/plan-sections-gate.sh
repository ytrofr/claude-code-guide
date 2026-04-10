#!/bin/bash
# PreToolUse hook (GLOBAL): Block ExitPlanMode if mandatory plan sections are missing
# Fires BEFORE: ExitPlanMode
# Location: ~/.claude/hooks/ (applies to ALL projects)
# Reference: ~/.claude/rules/planning/plan-checklist.md (14 mandatory sections, v5)

# Read stdin safely (hook receives tool input as JSON)
JSON_INPUT=$(timeout 2 cat 2>/dev/null || true)

# Find the most recently modified .md file in plans directory
PLANS_DIR="$HOME/.claude/plans"
if [ ! -d "$PLANS_DIR" ]; then
  echo "No plans directory found at $PLANS_DIR"
  exit 0
fi

PLAN_FILE=$(ls -t "$PLANS_DIR"/*.md 2>/dev/null | head -1)
if [ -z "$PLAN_FILE" ]; then
  echo "No plan files found in $PLANS_DIR"
  exit 0
fi

# Check for bypass comment (must be on its own line, not inside code blocks)
if grep -qE '^<!-- skip-plan-sections -->[ 	]*$' "$PLAN_FILE" 2>/dev/null; then
  echo "Plan sections check bypassed (<!-- skip-plan-sections --> found)"
  exit 0
fi

# Define sections and their detection patterns (case-insensitive)
# Section 0.1 is optional per plan-checklist.md rules
declare -A SECTIONS
SECTIONS=(
  ["1: Existing Code Check"]="existing code|reuse check|searched.*found|reuse plan"
  ["2: Over-Engineering Prevention"]="over.engineering|simplif.*alternative|complexity|can this be solved"
  ["3: Best Practices"]="best practice|KISS|DRY|SOLID|YAGNI"
  ["4: Architecture"]="architecture|routes.*controllers|layer.*separation|modular"
  ["5: Documentation Plan"]="documentation plan|/document|entry file|update.*status"
  ["6: Testing"]="testing|test plan|verification|e2e|unit test"
  ["7: Debugging & Observability"]="debug|logging|observability|monitor|health check"
  ["8: Files Affected"]="files affected|file change|files changed|action.*what"
  ["9: TL;DR"]="tl;dr|problem.*before|solution.*after"
  ["10: Modularity"]="modularity|file size.*gate|layer separation|god file|single responsibility"
  ["11: Post-Validation"]="post.validation|post.implementation.*validation|## 13"
)

MISSING=()
FOUND=()

for section in "1: Existing Code Check" "2: Over-Engineering Prevention" "3: Best Practices" \
               "4: Architecture" "5: Documentation Plan" "6: Testing" \
               "7: Debugging & Observability" "8: Files Affected" "9: TL;DR" \
               "10: Modularity" "11: Post-Validation"; do
  pattern="${SECTIONS[$section]}"
  if grep -qiE "$pattern" "$PLAN_FILE" 2>/dev/null; then
    FOUND+=("$section")
  else
    MISSING+=("$section")
  fi
done

PLAN_NAME=$(basename "$PLAN_FILE")

# --- KPI table validation ---
KPI_WARNINGS=()
if grep -qiE "kpi dashboard|kpi" "$PLAN_FILE" 2>/dev/null; then
  KPI_HEADER=$(grep -ciE '^\|.*status.*kpi.*before' "$PLAN_FILE" 2>/dev/null) || KPI_HEADER=0
  if [ "$KPI_HEADER" -eq 0 ]; then
    KPI_WARNINGS+=("KPI Dashboard must be a pipe-delimited table with columns: Status | KPI | Before | After (Target) | Source | Confidence")
  fi
else
  KPI_WARNINGS+=("No KPI Dashboard found — Section 12 TL;DR must include a KPI table")
fi

# --- Per-fix BEFORE/AFTER check (warning only) ---
FIX_WARNINGS=()
FIX_COUNT=$(grep -cE '^### Fix [0-9]' "$PLAN_FILE" 2>/dev/null) || FIX_COUNT=0
if [ "$FIX_COUNT" -gt 0 ]; then
  BEFORE_COUNT=$(grep -cE '^\*\*BEFORE\*\*:' "$PLAN_FILE" 2>/dev/null) || BEFORE_COUNT=0
  AFTER_COUNT=$(grep -cE '^\*\*AFTER\*\*:' "$PLAN_FILE" 2>/dev/null) || AFTER_COUNT=0
  if [ "$BEFORE_COUNT" -lt "$FIX_COUNT" ] || [ "$AFTER_COUNT" -lt "$FIX_COUNT" ]; then
    FIX_WARNINGS+=("Found $FIX_COUNT fixes but only $BEFORE_COUNT BEFORE and $AFTER_COUNT AFTER markers — each fix should have **BEFORE**: and **AFTER**: one-liners")
  fi
fi

ALL_WARNINGS=("${KPI_WARNINGS[@]}" "${FIX_WARNINGS[@]}")

if [ ${#MISSING[@]} -gt 0 ] || [ ${#ALL_WARNINGS[@]} -gt 0 ]; then
  echo ""
  echo "======================================================================="
  if [ ${#MISSING[@]} -gt 0 ]; then
    echo "PLAN SECTIONS GATE - BLOCKED"
  else
    echo "PLAN SECTIONS GATE - WARNINGS"
  fi
  echo "======================================================================="
  echo ""
  echo "Plan file: $PLAN_NAME"
  echo "Found: ${#FOUND[@]}/11 mandatory sections"

  if [ ${#MISSING[@]} -gt 0 ]; then
    echo ""
    echo "MISSING SECTIONS:"
    for s in "${MISSING[@]}"; do
      echo "  - Section $s"
    done
  fi

  if [ ${#ALL_WARNINGS[@]} -gt 0 ]; then
    echo ""
    echo "QUALITY WARNINGS:"
    for w in "${ALL_WARNINGS[@]}"; do
      echo "  Warning: $w"
    done
  fi

  echo ""
  echo "Reference: ~/.claude/rules/planning/plan-checklist.md (v5)"
  echo "To bypass: add <!-- skip-plan-sections --> to the plan file."
  echo "======================================================================="

  # Block on missing sections; warn-only on quality issues
  if [ ${#MISSING[@]} -gt 0 ]; then
    exit 2
  fi
  exit 0
fi

echo "Plan sections check passed (11/11 sections found in $PLAN_NAME)"
exit 0
