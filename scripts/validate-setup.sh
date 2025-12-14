#!/bin/bash

# Claude Code Setup Validation Script
# Validates project setup against minimal requirements

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
ERRORS=0
WARNINGS=0
SUCCESS=0

echo "🔍 Claude Code Setup Validation"
echo "================================"
echo ""

# Check if project path provided
PROJECT_PATH="${1:-.}"
cd "$PROJECT_PATH" || {
  echo -e "${RED}❌ Cannot access project path: $PROJECT_PATH${NC}"
  exit 1
}

echo "Validating project: $(pwd)"
echo ""

# ================================================================
# 1. DIRECTORY STRUCTURE
# ================================================================
echo "📁 Checking directory structure..."

REQUIRED_DIRS=(
  ".claude"
  "memory-bank"
  "memory-bank/always"
)

OPTIONAL_DIRS=(
  ".claude/hooks"
  ".claude/skills"
  "memory-bank/learned"
  "memory-bank/ondemand"
  "memory-bank/blueprints"
)

for dir in "${REQUIRED_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    echo -e "  ${GREEN}✅${NC} $dir"
    SUCCESS=$((SUCCESS + 1))
  else
    echo -e "  ${RED}❌ Missing: $dir${NC}"
    ERRORS=$((ERRORS + 1))
  fi
done

for dir in "${OPTIONAL_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    echo -e "  ${GREEN}✅${NC} $dir"
    SUCCESS=$((SUCCESS + 1))
  else
    echo -e "  ${YELLOW}⚠️  Optional: $dir (not created)${NC}"
    WARNINGS=$((WARNINGS + 1))
  fi
done

echo ""

# ================================================================
# 2. CORE FILES
# ================================================================
echo "📄 Checking core files..."

# Required files
if [ -f ".claude/CLAUDE.md" ]; then
  echo -e "  ${GREEN}✅${NC} .claude/CLAUDE.md"
  SUCCESS=$((SUCCESS + 1))

  # Check for @memory-bank references
  if grep -q "@memory-bank" .claude/CLAUDE.md; then
    echo -e "     ${GREEN}✓${NC} Auto-load references found"
  else
    echo -e "     ${YELLOW}⚠️${NC}  No @memory-bank auto-load references"
    WARNINGS=$((WARNINGS + 1))
  fi
else
  echo -e "  ${RED}❌ Missing: .claude/CLAUDE.md${NC}"
  ERRORS=$((ERRORS + 1))
fi

# Check memory bank core files
MEMORY_BANK_FILES=(
  "memory-bank/always/CORE-PATTERNS.md"
  "memory-bank/always/system-status.json"
)

for file in "${MEMORY_BANK_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo -e "  ${GREEN}✅${NC} $file"
    SUCCESS=$((SUCCESS + 1))

    # Validate JSON files
    if [[ "$file" == *.json ]]; then
      if jq empty "$file" 2>/dev/null; then
        echo -e "     ${GREEN}✓${NC} Valid JSON"
      else
        echo -e "     ${RED}✗${NC} Invalid JSON!"
        ERRORS=$((ERRORS + 1))
      fi
    fi
  else
    echo -e "  ${YELLOW}⚠️  Not created: $file${NC}"
    echo -e "     ${YELLOW}→${NC} Rename from .template file"
    WARNINGS=$((WARNINGS + 1))
  fi
done

echo ""

# ================================================================
# 3. MCP CONFIGURATION
# ================================================================
echo "🔌 Checking MCP configuration..."

if [ ! -f ".claude/mcp_servers.json" ]; then
  if [ -f ".claude/mcp_servers.json.template" ]; then
    echo -e "  ${YELLOW}⚠️  MCP template exists but not configured${NC}"
    echo -e "     ${YELLOW}→${NC} Copy .template to mcp_servers.json and add credentials"
    WARNINGS=$((WARNINGS + 1))
  else
    echo -e "  ${YELLOW}⚠️  No MCP configuration (optional)${NC}"
    WARNINGS=$((WARNINGS + 1))
  fi
else
  # Validate JSON
  if jq empty .claude/mcp_servers.json 2>/dev/null; then
    echo -e "  ${GREEN}✅${NC} MCP config is valid JSON"
    SUCCESS=$((SUCCESS + 1))

    # Count servers
    SERVER_COUNT=$(jq '.mcpServers | length' .claude/mcp_servers.json)
    echo -e "     ${GREEN}✓${NC} $SERVER_COUNT MCP server(s) configured"

    # Check for placeholder values
    if grep -q '\${' .claude/mcp_servers.json; then
      echo -e "     ${RED}✗${NC} Placeholders found - replace \${VARIABLES}"
      ERRORS=$((ERRORS + 1))
    fi

    # List servers
    jq -r '.mcpServers | keys[]' .claude/mcp_servers.json | while read server; do
      echo -e "     - $server"
    done
  else
    echo -e "  ${RED}❌ MCP config has invalid JSON${NC}"
    ERRORS=$((ERRORS + 1))
  fi
fi

echo ""

# ================================================================
# 4. SKILLS SYSTEM
# ================================================================
echo "🎯 Checking skills system..."

SKILLS_DIR="$HOME/.claude/skills"
if [ ! -d "$SKILLS_DIR" ]; then
  echo -e "  ${YELLOW}⚠️  No skills directory: $SKILLS_DIR${NC}"
  echo -e "     ${YELLOW}→${NC} Create with: mkdir -p ~/.claude/skills"
  WARNINGS=$((WARNINGS + 1))
else
  SKILL_COUNT=$(find "$SKILLS_DIR" -name "*.md" -type f 2>/dev/null | wc -l)
  if [ "$SKILL_COUNT" -eq 0 ]; then
    echo -e "  ${YELLOW}⚠️  Skills directory exists but no skills found${NC}"
    echo -e "     ${YELLOW}→${NC} Copy starter skills: cp .claude/skills/starter/*.md ~/.claude/skills/"
    WARNINGS=$((WARNINGS + 1))
  else
    echo -e "  ${GREEN}✅${NC} Found $SKILL_COUNT skill(s)"
    SUCCESS=$((SUCCESS + 1))

    # Check YAML frontmatter
    SKILLS_WITH_YAML=0
    for skill in "$SKILLS_DIR"/*.md; do
      if grep -q "^---$" "$skill" 2>/dev/null; then
        SKILLS_WITH_YAML=$((SKILLS_WITH_YAML + 1))
      fi
    done
    echo -e "     ${GREEN}✓${NC} $SKILLS_WITH_YAML skill(s) have YAML frontmatter"
  fi

  # Check hook
  if [ -f ".claude/hooks/pre-prompt.sh" ]; then
    if [ -x ".claude/hooks/pre-prompt.sh" ]; then
      echo -e "  ${GREEN}✅${NC} Skills activation hook is executable"
      SUCCESS=$((SUCCESS + 1))
    else
      echo -e "  ${RED}❌ Hook exists but not executable${NC}"
      echo -e "     ${RED}→${NC} Run: chmod +x .claude/hooks/pre-prompt.sh"
      ERRORS=$((ERRORS + 1))
    fi
  else
    echo -e "  ${YELLOW}⚠️  Skills hook not configured (optional but recommended)${NC}"
    echo -e "     ${YELLOW}→${NC} Enable for 84% activation rate"
    WARNINGS=$((WARNINGS + 1))
  fi
fi

echo ""

# ================================================================
# 5. PLACEHOLDERS CHECK
# ================================================================
echo "🔧 Checking for unconfigured placeholders..."

PLACEHOLDER_FILES=(
  ".claude/CLAUDE.md"
  "memory-bank/always/CORE-PATTERNS.md"
  "memory-bank/always/system-status.json"
)

FOUND_PLACEHOLDERS=false
for file in "${PLACEHOLDER_FILES[@]}"; do
  if [ -f "$file" ]; then
    if grep -q '\[YOUR_\|${' "$file" 2>/dev/null; then
      echo -e "  ${YELLOW}⚠️  Placeholders in $file${NC}"
      echo -e "     ${YELLOW}→${NC} Replace [YOUR_*] and \${*} with actual values"
      WARNINGS=$((WARNINGS + 1))
      FOUND_PLACEHOLDERS=true
    fi
  fi
done

if [ "$FOUND_PLACEHOLDERS" = false ]; then
  echo -e "  ${GREEN}✅${NC} No unconfigured placeholders found"
  SUCCESS=$((SUCCESS + 1))
fi

echo ""

# ================================================================
# SUMMARY
# ================================================================
echo "================================"
echo "Validation Summary"
echo "================================"
echo -e "${GREEN}✅ Passed:${NC} $SUCCESS"
echo -e "${YELLOW}⚠️  Warnings:${NC} $WARNINGS"
echo -e "${RED}❌ Errors:${NC} $ERRORS"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  echo -e "${GREEN}🎉 Perfect setup! All validations passed.${NC}"
  echo ""
  echo "Next steps:"
  echo "  1. Start Claude Code: claude-code"
  echo "  2. Test: Ask Claude about your core patterns"
  echo "  3. Expand: Add more skills and MCP servers as needed"
  exit 0
elif [ $ERRORS -eq 0 ]; then
  echo -e "${GREEN}✅ Setup is functional!${NC}"
  echo ""
  echo "You have $WARNINGS warning(s) - these are optional improvements:"
  echo "  - Enable MCP servers for enhanced capabilities"
  echo "  - Add skills activation hook for 84% activation rate"
  echo "  - Complete placeholder customization"
  echo ""
  echo "You can start using Claude Code now:"
  echo "  claude-code"
  exit 0
else
  echo -e "${RED}❌ Found $ERRORS error(s) that must be fixed.${NC}"
  echo ""
  echo "Please address the errors above and run validation again:"
  echo "  ./scripts/validate-setup.sh"
  exit 1
fi
