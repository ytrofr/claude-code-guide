#!/bin/bash

# MCP Server Connection Validator
# Tests MCP server configurations and connectivity

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_PATH="${1:-.}"
MCP_CONFIG="$PROJECT_PATH/.claude/mcp_servers.json"

echo "🔌 MCP Server Connection Validator"
echo "===================================="
echo ""

# Check if config exists
if [ ! -f "$MCP_CONFIG" ]; then
  echo -e "${RED}❌ No MCP configuration found${NC}"
  echo ""
  echo "Expected location: $MCP_CONFIG"
  echo ""
  if [ -f "$PROJECT_PATH/.claude/mcp_servers.json.template" ]; then
    echo -e "${YELLOW}Found template file.${NC} To configure:"
    echo "  1. cp $PROJECT_PATH/.claude/mcp_servers.json.template $MCP_CONFIG"
    echo "  2. Edit $MCP_CONFIG and replace \${VARIABLES}"
    echo "  3. Run this script again"
  else
    echo "Create MCP config at: $MCP_CONFIG"
  fi
  exit 1
fi

# Validate JSON
echo "Validating JSON syntax..."
if ! jq empty "$MCP_CONFIG" 2>/dev/null; then
  echo -e "${RED}❌ Invalid JSON in $MCP_CONFIG${NC}"
  echo ""
  echo "Fix JSON syntax errors and try again."
  exit 1
fi
echo -e "${GREEN}✅ JSON syntax valid${NC}"
echo ""

# Extract server names
SERVERS=$(jq -r '.mcpServers | keys[]' "$MCP_CONFIG" 2>/dev/null)

if [ -z "$SERVERS" ]; then
  echo -e "${YELLOW}⚠️  No MCP servers configured${NC}"
  echo ""
  echo "Add MCP servers to: $MCP_CONFIG"
  exit 0
fi

SERVER_COUNT=$(echo "$SERVERS" | wc -l)
echo "Found $SERVER_COUNT MCP server(s)"
echo ""

# Validate each server
SERVERS_OK=0
SERVERS_WARN=0
SERVERS_ERR=0

while IFS= read -r server; do
  echo "Testing: $server"
  echo "────────────────────────────────────────"

  # Extract command
  COMMAND=$(jq -r ".mcpServers[\"$server\"].command" "$MCP_CONFIG")

  # Check command exists
  if command -v "$COMMAND" &> /dev/null; then
    echo -e "  ${GREEN}✅${NC} Command '$COMMAND' found"

    # Check version for npx
    if [ "$COMMAND" = "npx" ]; then
      NPM_VERSION=$(npm --version 2>/dev/null || echo "not found")
      echo -e "     ${GREEN}✓${NC} npm version: $NPM_VERSION"
    fi
  else
    echo -e "  ${RED}❌ Command '$COMMAND' not found${NC}"
    echo -e "     ${RED}→${NC} Install Node.js and npm"
    SERVERS_ERR=$((SERVERS_ERR + 1))
    echo ""
    continue
  fi

  # Extract and check environment variables
  ENV_VARS=$(jq -r ".mcpServers[\"$server\"].env | keys[]" "$MCP_CONFIG" 2>/dev/null)

  if [ -n "$ENV_VARS" ]; then
    echo "  Environment variables:"

    HAS_PLACEHOLDER=false
    while IFS= read -r var; do
      VALUE=$(jq -r ".mcpServers[\"$server\"].env[\"$var\"]" "$MCP_CONFIG")

      # Check for placeholder syntax
      if [[ "$VALUE" == \$\{*\} ]]; then
        echo -e "     ${YELLOW}⚠️${NC}  $var: ${YELLOW}needs configuration${NC} ($VALUE)"
        HAS_PLACEHOLDER=true
      else
        # Don't show actual values (security)
        echo -e "     ${GREEN}✓${NC} $var: configured"
      fi
    done <<< "$ENV_VARS"

    if [ "$HAS_PLACEHOLDER" = true ]; then
      SERVERS_WARN=$((SERVERS_WARN + 1))
    else
      SERVERS_OK=$((SERVERS_OK + 1))
    fi
  else
    echo -e "  ${GREEN}✓${NC} No environment variables required"
    SERVERS_OK=$((SERVERS_OK + 1))
  fi

  # Extract args
  ARGS_COUNT=$(jq ".mcpServers[\"$server\"].args | length" "$MCP_CONFIG")
  if [ "$ARGS_COUNT" -gt 0 ]; then
    echo -e "  ${GREEN}✓${NC} $ARGS_COUNT argument(s) configured"
  fi

  echo ""
done <<< "$SERVERS"

# ================================================================
# SUMMARY
# ================================================================
echo "===================================="
echo "MCP Validation Summary"
echo "===================================="
echo -e "${GREEN}✅ Configured:${NC} $SERVERS_OK"
echo -e "${YELLOW}⚠️  Needs config:${NC} $SERVERS_WARN"
echo -e "${RED}❌ Errors:${NC} $SERVERS_ERR"
echo ""

if [ $SERVERS_ERR -gt 0 ]; then
  echo -e "${RED}❌ MCP setup has errors${NC}"
  echo ""
  echo "Fix the errors above and run again:"
  echo "  ./scripts/check-mcp.sh"
  exit 1
elif [ $SERVERS_WARN -gt 0 ]; then
  echo -e "${YELLOW}⚠️  MCP servers need configuration${NC}"
  echo ""
  echo "Configure placeholders in: $MCP_CONFIG"
  echo "Then run: ./scripts/check-mcp.sh"
  exit 0
else
  echo -e "${GREEN}✅ All MCP servers ready!${NC}"
  echo ""
  echo "Test in Claude Code:"
  echo "  1. Start Claude Code: claude-code"
  echo "  2. Ask: 'List available MCP servers'"
  echo "  3. Try a server-specific command"
  exit 0
fi
