#!/bin/bash
# PreToolUse hook (GLOBAL): Block ExitPlanMode if mandatory plan sections are missing
# Fires BEFORE: ExitPlanMode
# Location: ~/.claude/hooks/ (applies to ALL projects)
# Reference: ~/.claude/rules/planning/plan-checklist.md

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
if grep -qP '^<!-- skip-plan-sections -->\s*$' "$PLAN_FILE" 2>/dev/null; then
  echo "Plan sections check bypassed (<!-- skip-plan-sections --> found)"
  exit 0
fi

# Define sections and their detection patterns (case-insensitive)
# Section 0 is optional per plan-checklist.md rules
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
  ["9: TL;DR"]="tl;dr|before.*after|summary"
  ["10: Modularity"]="modularity|file size.*gate|layer separation|god file|single responsibility"
)

MISSING=()
FOUND=()

for section in "1: Existing Code Check" "2: Over-Engineering Prevention" "3: Best Practices" \
               "4: Architecture" "5: Documentation Plan" "6: Testing" \
               "7: Debugging & Observability" "8: Files Affected" "9: TL;DR" \
               "10: Modularity"; do
  pattern="${SECTIONS[$section]}"
  if grep -qiE "$pattern" "$PLAN_FILE" 2>/dev/null; then
    FOUND+=("$section")
  else
    MISSING+=("$section")
  fi
done

PLAN_NAME=$(basename "$PLAN_FILE")

if [ ${#MISSING[@]} -gt 0 ]; then
  echo ""
  echo "======================================================================="
  echo "PLAN SECTIONS GATE - BLOCKED"
  echo "======================================================================="
  echo ""
  echo "Plan file: $PLAN_NAME"
  echo "Found: ${#FOUND[@]}/10 mandatory sections"
  echo ""
  echo "MISSING SECTIONS:"
  for s in "${MISSING[@]}"; do
    echo "  - Section $s"
  done
  echo ""
  echo "Add the missing sections to your plan before submitting."
  echo "Reference: ~/.claude/rules/planning/plan-checklist.md"
  echo ""
  echo "To bypass: add <!-- skip-plan-sections --> to the plan file."
  echo "======================================================================="
  exit 2
fi

echo "Plan sections check passed (10/10 sections found in $PLAN_NAME)"
exit 0
