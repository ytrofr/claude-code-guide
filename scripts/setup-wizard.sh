#!/bin/bash

# Claude Code Setup Wizard
# Interactive setup experience for new projects

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║        Claude Code Setup Wizard                           ║"
echo "║        Interactive Project Configuration                  ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

PROJECT_PATH="${1:-.}"
cd "$PROJECT_PATH" || {
  echo -e "${RED}❌ Cannot access project path: $PROJECT_PATH${NC}"
  exit 1
}

echo -e "${BLUE}Project:${NC} $(pwd)"
echo ""
echo "This wizard will guide you through setting up Claude Code for your project."
echo "Estimated time: 10-15 minutes"
echo ""
read -p "Press Enter to begin..."

# ================================================================
# STEP 1: Project Information
# ================================================================
clear
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Step 1/5: Project Information                             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

read -p "Project name: " PROJECT_NAME
read -p "Main database name (if any): " DB_NAME
read -p "Primary programming language (Node.js/Python/etc.): " PRIMARY_LANG

echo ""
echo -e "${GREEN}✓${NC} Project information collected"
echo ""
read -p "Press Enter to continue..."

# ================================================================
# STEP 2: Directory Structure
# ================================================================
clear
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Step 2/5: Directory Structure                             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo "Creating directory structure..."

mkdir -p .claude/hooks
mkdir -p memory-bank/{always,learned,ondemand,blueprints}
mkdir -p ~/.claude/skills

echo -e "${GREEN}✅${NC} Directories created:"
echo "  - .claude/hooks"
echo "  - memory-bank/always"
echo "  - memory-bank/learned"
echo "  - memory-bank/ondemand"
echo "  - memory-bank/blueprints"
echo "  - ~/.claude/skills (user-level)"
echo ""
read -p "Press Enter to continue..."

# ================================================================
# STEP 3: Core Files
# ================================================================
clear
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Step 3/5: Core Files                                      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if running from guide repo
GUIDE_TEMPLATE="../claude-code-guide/template"
if [ ! -d "$GUIDE_TEMPLATE" ]; then
  GUIDE_TEMPLATE="./template"
fi

if [ -d "$GUIDE_TEMPLATE" ]; then
  echo "Copying template files..."

  # Copy templates and customize
  cp "$GUIDE_TEMPLATE/memory-bank/always/CORE-PATTERNS.md.template" \
     "memory-bank/always/CORE-PATTERNS.md"

  cp "$GUIDE_TEMPLATE/memory-bank/always/system-status.json.template" \
     "memory-bank/always/system-status.json"

  cp "$GUIDE_TEMPLATE/memory-bank/always/CONTEXT-ROUTER.md.template" \
     "memory-bank/always/CONTEXT-ROUTER.md"

  cp "$GUIDE_TEMPLATE/.claude/CLAUDE.md" \
     ".claude/CLAUDE.md"

  # Customize with user's input
  sed -i "s/\[YOUR_PROJECT_NAME\]/$PROJECT_NAME/g" memory-bank/always/CORE-PATTERNS.md
  sed -i "s/\[DATE\]/$(date +%Y-%m-%d)/g" memory-bank/always/CORE-PATTERNS.md
  sed -i "s/\[YOUR_PROJECT_NAME\]/$PROJECT_NAME/g" memory-bank/always/CONTEXT-ROUTER.md
  sed -i "s/\[DATE\]/$(date +%Y-%m-%d)/g" memory-bank/always/CONTEXT-ROUTER.md

  # Update system-status.json
  sed -i "s/\[DATE\]/$(date +%Y-%m-%d)/g" memory-bank/always/system-status.json
  sed -i "s/\[Sprint or phase description\]/Initial setup/g" memory-bank/always/system-status.json

  # Update CLAUDE.md
  sed -i "s/\[YOUR_PROJECT_NAME\]/$PROJECT_NAME/g" .claude/CLAUDE.md
  sed -i "s/\[DATE\]/$(date +%Y-%m-%d)/g" .claude/CLAUDE.md

  echo -e "${GREEN}✅${NC} Core files created and customized"
else
  echo -e "${YELLOW}⚠️  Template not found - creating minimal files${NC}"

  # Create minimal CORE-PATTERNS.md
  cat > memory-bank/always/CORE-PATTERNS.md << EOF
# CORE-PATTERNS - Single Source of Truth

**Project**: $PROJECT_NAME
**Created**: $(date +%Y-%m-%d)

## YOUR PROJECT PATTERNS

Add your core patterns here.
EOF

  # Create minimal system-status.json
  cat > memory-bank/always/system-status.json << EOF
{
  "last_updated": "$(date +%Y-%m-%d)",
  "branch": "main",
  "features": []
}
EOF

  echo -e "${GREEN}✅${NC} Minimal core files created"
fi

echo ""
echo "Files created:"
echo "  - memory-bank/always/CORE-PATTERNS.md"
echo "  - memory-bank/always/system-status.json"
echo "  - memory-bank/always/CONTEXT-ROUTER.md"
echo "  - .claude/CLAUDE.md"
echo ""
read -p "Press Enter to continue..."

# ================================================================
# STEP 4: MCP Servers (Optional)
# ================================================================
clear
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Step 4/5: MCP Servers (Optional)                          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo "MCP servers provide enhanced capabilities:"
echo "  1. GitHub - PR reviews, issue management, code search"
echo "  2. Memory - Session persistence across conversations"
echo "  3. PostgreSQL - Direct database access"
echo "  4. Perplexity - AI-powered search (\$5/month)"
echo ""
read -p "Do you want to configure MCP servers? (y/n): " SETUP_MCP

if [ "$SETUP_MCP" = "y" ]; then
  echo ""
  echo "Which MCP servers do you want?"
  echo "  [1] GitHub (recommended for all projects)"
  echo "  [2] Memory (recommended for session persistence)"
  echo "  [3] PostgreSQL (if you have a database)"
  echo "  [4] Perplexity (if you need AI search)"
  echo ""
  read -p "Select (comma-separated, e.g., 1,2): " SELECTED_SERVERS

  # Create basic config
  echo '{' > .claude/mcp_servers.json
  echo '  "mcpServers": {' >> .claude/mcp_servers.json

  FIRST=true
  IFS=',' read -ra SERVERS_ARRAY <<< "$SELECTED_SERVERS"
  for server in "${SERVERS_ARRAY[@]}"; do
    server=$(echo "$server" | tr -d ' ')

    if [ "$FIRST" = false ]; then
      echo ',' >> .claude/mcp_servers.json
    fi
    FIRST=false

    case "$server" in
      1)
        cat >> .claude/mcp_servers.json << 'EOF'
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      }
    }
EOF
        ;;
      2)
        cat >> .claude/mcp_servers.json << 'EOF'
    "memory": {
      "command": "npx",
      "args": ["-y", "@joshuarileydev/mcp-server-basic-memory"],
      "env": {
        "MEMORY_PROJECT": "main",
        "MEMORY_PATH": "${HOME}/.basic-memory"
      }
    }
EOF
        ;;
      3)
        cat >> .claude/mcp_servers.json << 'EOF'
    "postgres-dev": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-postgres",
        "postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}"
      ]
    }
EOF
        ;;
      4)
        cat >> .claude/mcp_servers.json << 'EOF'
    "perplexity": {
      "command": "npx",
      "args": ["-y", "@joshuarileydev/mcp-server-perplexity"],
      "env": {
        "PERPLEXITY_API_KEY": "${PERPLEXITY_API_KEY}"
      }
    }
EOF
        ;;
    esac
  done

  echo '' >> .claude/mcp_servers.json
  echo '  }' >> .claude/mcp_servers.json
  echo '}' >> .claude/mcp_servers.json

  echo ""
  echo -e "${GREEN}✅${NC} MCP config created at: .claude/mcp_servers.json"
  echo ""
  echo -e "${YELLOW}⚠️  IMPORTANT:${NC} Replace \${VARIABLES} with your actual credentials"
  echo ""
  echo "Edit: .claude/mcp_servers.json"
  echo ""
else
  echo ""
  echo -e "${YELLOW}⚠️  Skipping MCP configuration${NC}"
  echo "You can add MCP servers later - see docs/guide/07-mcp-integration.md"
fi

echo ""
read -p "Press Enter to continue..."

# ================================================================
# STEP 5: Starter Skills (Optional)
# ================================================================
clear
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Step 5/5: Starter Skills (Optional)                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo "Starter skills provide immediate troubleshooting and workflow value."
echo ""
read -p "Do you want to install the 3 starter skills? (y/n): " SETUP_SKILLS

if [ "$SETUP_SKILLS" = "y" ]; then
  if [ -d "$GUIDE_TEMPLATE/.claude/skills/starter" ]; then
    # Copy starter skills
    cp "$GUIDE_TEMPLATE/.claude/skills/starter"/*.md ~/.claude/skills/ 2>/dev/null || {
      echo -e "${RED}❌ Failed to copy starter skills${NC}"
    }

    SKILL_COUNT=$(find ~/.claude/skills/ -name "*.md" -type f | wc -l)
    echo -e "${GREEN}✅${NC} Installed $SKILL_COUNT skill(s) to ~/.claude/skills/"
    echo ""
    echo "Skills installed:"
    ls ~/.claude/skills/*.md 2>/dev/null | xargs -n1 basename
  else
    echo -e "${YELLOW}⚠️  Starter skills not found in template${NC}"
    echo "You can create skills manually - see docs/guide/06-skills-framework.md"
  fi
else
  echo ""
  echo -e "${YELLOW}⚠️  Skipping skills installation${NC}"
  echo "You can add skills later - copy from template/.claude/skills/starter/"
fi

echo ""
read -p "Press Enter to validate setup..."

# ================================================================
# FINAL VALIDATION
# ================================================================
clear
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Final Validation                                          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Run validation script
if [ -f "../claude-code-guide/scripts/validate-setup.sh" ]; then
  bash ../claude-code-guide/scripts/validate-setup.sh "$PROJECT_PATH"
elif [ -f "./scripts/validate-setup.sh" ]; then
  bash ./scripts/validate-setup.sh "$PROJECT_PATH"
else
  echo -e "${YELLOW}⚠️  Validation script not found${NC}"
  echo ""
  echo "Manual validation:"
  echo "  1. Check .claude/CLAUDE.md exists"
  echo "  2. Check memory-bank/always/ has core files"
  echo "  3. Verify JSON files are valid"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Setup Complete!                                           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}✅ Claude Code is configured for your project${NC}"
echo ""
echo "Next steps:"
echo "  1. Review and customize:"
echo "     - memory-bank/always/CORE-PATTERNS.md (add your patterns)"
echo "     - .claude/mcp_servers.json (if configured - add credentials)"
echo ""
echo "  2. Start Claude Code:"
echo "     claude-code"
echo ""
echo "  3. Test the setup:"
echo "     - Ask: 'What are my core patterns?'"
echo "     - Ask: 'What's the current feature status?'"
echo ""
echo "Documentation:"
echo "  - Quick Start: docs/quick-start.md"
echo "  - Complete Guide: docs/guide/"
echo "  - Troubleshooting: docs/guide/10-troubleshooting.md"
echo ""
