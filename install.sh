#!/bin/bash
# =============================================================================
# Claude Code Best Practices Installer
# Source: https://github.com/ytrofr/claude-code-guide
#
# Installs production-tested best practices, skills, commands, hooks,
# and rules into any Claude Code project.
#
# Usage:
#   Remote (one-liner):
#     curl -sL https://raw.githubusercontent.com/ytrofr/claude-code-guide/master/install.sh | bash
#
#   Local (after cloning):
#     ./install.sh                    # Core install (rules + best practices)
#     ./install.sh --full             # Full install (+ skills, commands, all rules)
#     ./install.sh --with-hooks       # Full + hooks + settings.json
#     ./install.sh --global           # Install to ~/.claude (all projects)
#
#   Component flags (composable):
#     --skills         Install starter skills to ~/.claude/skills/
#     --commands       Install slash commands to .claude/commands/
#     --hooks          Install hooks to .claude/hooks/ + settings.json
#     --all-rules      Install all 19 rules (not just core 6)
#
#   Other options:
#     --rules-only     Only install core rules, skip everything else
#     --update         Update existing installation to latest version
#     --uninstall      Remove installed best practices
#     --help           Show this help message
# =============================================================================

set -euo pipefail

# --- Configuration ---
REPO_URL="https://github.com/ytrofr/claude-code-guide"
RAW_BASE="https://raw.githubusercontent.com/ytrofr/claude-code-guide/master"
BP_DIR="best-practices"
TEMPLATE_DIR="template"
SKILLS_LIB_DIR="skills-library"
MARKER_FILE=".claude-best-practices-installed"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# --- Helper Functions ---
info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }
header()  { echo -e "\n${BOLD}$*${NC}"; }
dim()     { echo -e "${DIM}$*${NC}"; }

usage() {
  cat <<'USAGE'
Claude Code Best Practices Installer
Source: https://github.com/ytrofr/claude-code-guide

USAGE:
  curl -sL https://raw.githubusercontent.com/ytrofr/claude-code-guide/master/install.sh | bash
  ./install.sh [OPTIONS] [TARGET_DIR]

TIERS:
  (default)        Core: 6 rules + BEST-PRACTICES.md + CLAUDE.md import
  --full           Full: Core + skills + commands + all 19 rules
  --with-hooks     Full + hooks + settings.json

COMPONENT FLAGS (composable):
  --skills         Install starter skills to ~/.claude/skills/
  --commands       Install slash commands to .claude/commands/
  --hooks          Install hooks to .claude/hooks/ + settings.json
  --all-rules      Install all 19 rules (not just core 6)

OPTIONS:
  --global         Install to ~/.claude/ (applies to all projects)
  --rules-only     Only install core rules, skip everything else
  --update         Update existing installation to latest version
  --uninstall      Remove installed best practices
  --help           Show this help message

EXAMPLES:
  ./install.sh                       # Core install in current project
  ./install.sh --full ~/my-project   # Full install in specific project
  ./install.sh --with-hooks          # Everything including hooks
  ./install.sh --skills --commands   # Core + skills + commands
  ./install.sh --global --skills     # Global rules + skills
  ./install.sh --update              # Update to latest version
  ./install.sh --uninstall           # Remove everything

WHAT GETS INSTALLED (by tier):

  Core (default):
    .claude/rules/best-practices/    6 universal rules (auto-loaded)
    .claude/best-practices/          Best practices doc + self-updater
    CLAUDE.md                        @ import added (or created)

  --skills:
    ~/.claude/skills/                3 starter skills (global, all projects)

  --commands:
    .claude/commands/                5 slash commands (/session-start, etc.)

  --all-rules:
    .claude/rules/                   All 19 rules (global, planning, quality, etc.)

  --hooks:
    .claude/hooks/                   4 hook scripts (pre-prompt, session, etc.)
    .claude/settings.json            Hook registration configuration
USAGE
  exit 0
}

# --- Detect if running from cloned repo or remote ---
detect_source() {
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
  if [ -f "$SCRIPT_DIR/best-practices/BEST-PRACTICES.md" ]; then
    SOURCE="local"
    SOURCE_DIR="$SCRIPT_DIR"
  else
    SOURCE="remote"
    SOURCE_DIR=""
  fi
}

# --- Download/copy a file from the repo ---
fetch_file() {
  local remote_path="$1"
  local local_path="$2"
  if [ "$SOURCE" = "local" ]; then
    cp "$SOURCE_DIR/$remote_path" "$local_path"
  else
    if command -v curl &>/dev/null; then
      curl -sL "$RAW_BASE/$remote_path" -o "$local_path"
    elif command -v wget &>/dev/null; then
      wget -qO "$local_path" "$RAW_BASE/$remote_path"
    else
      error "Neither curl nor wget found. Install one and retry."
      exit 1
    fi
  fi
}

# --- Copy a directory tree from the repo (local only, with remote fallback) ---
fetch_dir() {
  local remote_path="$1"
  local local_path="$2"
  if [ "$SOURCE" = "local" ]; then
    cp -r "$SOURCE_DIR/$remote_path" "$local_path"
  else
    error "Directory copy requires local clone. Clone the repo first:"
    error "  git clone $REPO_URL && cd claude-code-guide && ./install.sh --full"
    return 1
  fi
}

# --- Get current installed version ---
get_installed_version() {
  local target="$1"
  if [ -f "$target/.claude/best-practices/.version" ]; then
    cat "$target/.claude/best-practices/.version"
  else
    echo "none"
  fi
}

# --- Get latest version from source ---
get_latest_version() {
  if [ "$SOURCE" = "local" ]; then
    cat "$SOURCE_DIR/best-practices/VERSION"
  else
    if command -v curl &>/dev/null; then
      curl -sL "$RAW_BASE/best-practices/VERSION"
    else
      wget -qO- "$RAW_BASE/best-practices/VERSION"
    fi
  fi
}

# =============================================================================
# Component Installers
# =============================================================================

# --- Install core rules (6 universal, project-agnostic) ---
install_core_rules() {
  local target="$1"
  local rules_dir="$target/.claude/rules/best-practices"

  mkdir -p "$rules_dir"

  local rules=(
    "context-checking.md"
    "validation-workflow.md"
    "safety-rules.md"
    "no-mock-data.md"
    "anti-overengineering.md"
    "session-protocol.md"
  )

  for rule in "${rules[@]}"; do
    fetch_file "$BP_DIR/rules/$rule" "$rules_dir/$rule"
  done

  success "Installed ${#rules[@]} core rules to .claude/rules/best-practices/"
}

# --- Install ALL rules (19 total, preserving directory structure) ---
install_all_rules() {
  local target="$1"
  local rules_base="$target/.claude/rules"

  # Create directory structure
  mkdir -p "$rules_base"/{global,planning,process,quality,mcp,technical,documentation,domain,projects}

  # Global rules (3)
  fetch_file "$TEMPLATE_DIR/.claude/rules/global/agent-usage.md" "$rules_base/global/agent-usage.md"
  fetch_file "$TEMPLATE_DIR/.claude/rules/global/context-checking.md" "$rules_base/global/context-checking.md"
  fetch_file "$TEMPLATE_DIR/.claude/rules/global/validation-workflow.md" "$rules_base/global/validation-workflow.md"

  # Planning rules (3)
  fetch_file "$TEMPLATE_DIR/.claude/rules/planning/anti-overengineering.md" "$rules_base/planning/anti-overengineering.md"
  fetch_file "$TEMPLATE_DIR/.claude/rules/planning/plan-checklist.md" "$rules_base/planning/plan-checklist.md"
  fetch_file "$TEMPLATE_DIR/.claude/rules/planning/plan-link.md" "$rules_base/planning/plan-link.md"

  # Process rules (2)
  fetch_file "$TEMPLATE_DIR/.claude/rules/process/safety-rules.md" "$rules_base/process/safety-rules.md"
  fetch_file "$TEMPLATE_DIR/.claude/rules/process/session-protocol.md" "$rules_base/process/session-protocol.md"

  # Quality rules (2)
  fetch_file "$TEMPLATE_DIR/.claude/rules/quality/no-mock-data.md" "$rules_base/quality/no-mock-data.md"
  fetch_file "$TEMPLATE_DIR/.claude/rules/quality/standards.md" "$rules_base/quality/standards.md"

  # MCP rules (3)
  fetch_file "$TEMPLATE_DIR/.claude/rules/mcp/agent-routing.md" "$rules_base/mcp/agent-routing.md"
  fetch_file "$TEMPLATE_DIR/.claude/rules/mcp/mcp-first.md" "$rules_base/mcp/mcp-first.md"
  fetch_file "$TEMPLATE_DIR/.claude/rules/mcp/memory-usage.md" "$rules_base/mcp/memory-usage.md"

  # Technical rules (2)
  fetch_file "$TEMPLATE_DIR/.claude/rules/technical/patterns.md" "$rules_base/technical/patterns.md"
  fetch_file "$TEMPLATE_DIR/.claude/rules/src-code.md" "$rules_base/src-code.md"

  # Documentation rules (1)
  fetch_file "$TEMPLATE_DIR/.claude/rules/documentation/versioning.md" "$rules_base/documentation/versioning.md"

  # Test rules (1)
  fetch_file "$TEMPLATE_DIR/.claude/rules/tests.md" "$rules_base/tests.md"

  # Project-specific templates (2) -- as templates to customize
  fetch_file "$TEMPLATE_DIR/.claude/rules/domain/patterns.md" "$rules_base/domain/patterns.md"
  fetch_file "$TEMPLATE_DIR/.claude/rules/projects/registry.md" "$rules_base/projects/registry.md"

  success "Installed 19 rules across 9 categories to .claude/rules/"
  dim "    Customize: domain/patterns.md and projects/registry.md for your project"
}

# --- Install starter skills ---
install_skills() {
  local skills_dir="$HOME/.claude/skills"

  mkdir -p "$skills_dir"

  # Skill directories (each contains SKILL.md)
  local skill_names=(
    "troubleshooting-decision-tree-skill"
    "session-start-protocol-skill"
    "project-patterns-skill"
  )

  local count=0
  for skill in "${skill_names[@]}"; do
    local skill_target="$skills_dir/$skill"
    mkdir -p "$skill_target"
    fetch_file "$TEMPLATE_DIR/.claude/skills/starter/$skill/SKILL.md" "$skill_target/SKILL.md"
    count=$((count + 1))
  done

  success "Installed $count starter skills to ~/.claude/skills/"
  dim "    Skills are globally available -- Claude Code discovers them automatically"
}

# --- Install slash commands ---
install_commands() {
  local target="$1"
  local cmd_dir="$target/.claude/commands"

  mkdir -p "$cmd_dir"

  local commands=(
    "session-start.md"
    "session-end.md"
    "advise.md"
    "retrospective.md"
    "slashes.md"
  )

  for cmd in "${commands[@]}"; do
    fetch_file "$TEMPLATE_DIR/.claude/commands/$cmd" "$cmd_dir/$cmd"
  done

  success "Installed ${#commands[@]} slash commands to .claude/commands/"
  dim "    Available: /session-start, /session-end, /advise, /retrospective, /slashes"
}

# --- Install hooks ---
install_hooks() {
  local target="$1"
  local hooks_dir="$target/.claude/hooks"

  mkdir -p "$hooks_dir"

  # Install hook scripts
  local hooks=(
    "pre-prompt.sh"
    "session-start.sh"
    "pre-compact.sh"
    "prettier-format.sh"
  )

  for hook in "${hooks[@]}"; do
    fetch_file "$TEMPLATE_DIR/.claude/hooks/$hook" "$hooks_dir/$hook"
    chmod +x "$hooks_dir/$hook"
  done

  success "Installed ${#hooks[@]} hook scripts to .claude/hooks/"

  # Generate settings.json for hook registration
  install_settings_json "$target"
}

# --- Generate settings.json with hook configuration ---
install_settings_json() {
  local target="$1"
  local settings="$target/.claude/settings.json"

  if [ -f "$settings" ]; then
    warn "settings.json already exists -- hooks not auto-registered"
    echo ""
    echo "  Add these hooks manually to your .claude/settings.json:"
    echo ""
    cat <<'HOOK_CONFIG'
  {
    "hooks": {
      "UserPromptSubmit": [
        { "hooks": [{ "type": "command", "command": ".claude/hooks/pre-prompt.sh" }] }
      ],
      "SessionStart": [
        { "hooks": [{ "type": "command", "command": ".claude/hooks/session-start.sh" }] }
      ],
      "PreCompact": [
        { "hooks": [{ "type": "command", "command": ".claude/hooks/pre-compact.sh" }] }
      ],
      "PostToolUse": [
        {
          "matcher": "Write|Edit",
          "hooks": [{ "type": "command", "command": ".claude/hooks/prettier-format.sh" }]
        }
      ]
    }
  }
HOOK_CONFIG
    echo ""
    return
  fi

  cat > "$settings" <<'SETTINGS_JSON'
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/pre-prompt.sh",
            "statusMessage": "Scanning for skill triggers..."
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/session-start.sh",
            "statusMessage": "Loading session context..."
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/pre-compact.sh",
            "statusMessage": "Backing up session..."
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/prettier-format.sh",
            "statusMessage": "Formatting..."
          }
        ]
      }
    ]
  }
}
SETTINGS_JSON

  success "Created .claude/settings.json with hook registrations"
}

# --- Install best practices document ---
install_best_practices_doc() {
  local target="$1"
  local bp_dir="$target/.claude/best-practices"

  mkdir -p "$bp_dir"

  fetch_file "$BP_DIR/BEST-PRACTICES.md" "$bp_dir/BEST-PRACTICES.md"

  local version
  version="$(get_latest_version)"
  echo "$version" > "$bp_dir/.version"

  cat > "$bp_dir/.metadata" <<EOF
installed_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
source=$SOURCE
version=$version
repo=$REPO_URL
EOF

  success "Installed BEST-PRACTICES.md (v${version})"
}

# --- Create update script ---
create_updater() {
  local target="$1"
  local updater="$target/.claude/best-practices/update.sh"

  cat > "$updater" <<'UPDATER_SCRIPT'
#!/bin/bash
# Claude Code Best Practices - Updater
# Re-downloads the latest best practices from the source repository.
# Run: bash .claude/best-practices/update.sh

set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/ytrofr/claude-code-guide/master"
TARGET_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
BP_DIR="$TARGET_DIR/.claude/best-practices"
RULES_DIR="$TARGET_DIR/.claude/rules/best-practices"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

echo -e "${BLUE}Checking for updates...${NC}"

CURRENT="none"
[ -f "$BP_DIR/.version" ] && CURRENT=$(cat "$BP_DIR/.version")

LATEST=$(curl -sL "$REPO_RAW/best-practices/VERSION" 2>/dev/null || echo "unknown")

if [ "$LATEST" = "unknown" ]; then
  echo -e "${RED}Could not reach update server. Check your network connection.${NC}"
  exit 1
fi

echo "  Current version: $CURRENT"
echo "  Latest version:  $LATEST"

if [ "$CURRENT" = "$LATEST" ]; then
  echo -e "${GREEN}Already up to date.${NC}"
  exit 0
fi

echo -e "${YELLOW}Updating from $CURRENT to $LATEST...${NC}"

# Update best practices document
curl -sL "$REPO_RAW/best-practices/BEST-PRACTICES.md" -o "$BP_DIR/BEST-PRACTICES.md"

# Update core rules
RULES=("context-checking.md" "validation-workflow.md" "safety-rules.md" "no-mock-data.md" "anti-overengineering.md" "session-protocol.md")
mkdir -p "$RULES_DIR"
for rule in "${RULES[@]}"; do
  curl -sL "$REPO_RAW/best-practices/rules/$rule" -o "$RULES_DIR/$rule"
done

echo "$LATEST" > "$BP_DIR/.version"

cat > "$BP_DIR/.metadata" <<EOF
installed_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
source=remote
version=$LATEST
repo=https://github.com/ytrofr/claude-code-guide
EOF

echo -e "${GREEN}Updated to v${LATEST} successfully.${NC}"
echo "  - BEST-PRACTICES.md updated"
echo "  - ${#RULES[@]} core rules updated"
echo ""
echo "To update skills/commands/hooks, re-run the installer:"
echo "  git -C \$(dirname \"\$0\")/../../.. pull && ./install.sh --full"
UPDATER_SCRIPT

  chmod +x "$updater"
  success "Created update script at .claude/best-practices/update.sh"
}

# --- Add @ import to CLAUDE.md ---
add_claude_md_import() {
  local target="$1"
  local claude_md="$target/CLAUDE.md"
  local import_line="@.claude/best-practices/BEST-PRACTICES.md"
  local import_comment="# Claude Code Best Practices (auto-installed from claude-code-guide)"

  if [ -f "$claude_md" ]; then
    if grep -qF "$import_line" "$claude_md"; then
      info "CLAUDE.md already imports best practices (skipping)"
      return
    fi

    {
      echo ""
      echo "---"
      echo ""
      echo "$import_comment"
      echo "$import_line"
    } >> "$claude_md"

    success "Added best practices import to existing CLAUDE.md"
  else
    cat > "$claude_md" <<EOF
# Project Configuration

$import_comment
$import_line

---

## Project-Specific Rules

Add your project-specific instructions below. Claude Code reads this file
at the start of every session.

<!-- Customize this section for your project -->
EOF

    success "Created CLAUDE.md with best practices import"
  fi
}

# --- Write install marker ---
write_marker() {
  local target="$1"
  local version
  version="$(get_latest_version)"
  echo "$version" > "$target/.claude/$MARKER_FILE"
}

# =============================================================================
# Main Operations
# =============================================================================

# --- Uninstall ---
do_uninstall() {
  local target="$1"

  header "Uninstalling Claude Code Best Practices..."

  # Remove core rules
  if [ -d "$target/.claude/rules/best-practices" ]; then
    rm -rf "$target/.claude/rules/best-practices"
    success "Removed .claude/rules/best-practices/"
  fi

  # Remove all-rules (check each category)
  local rule_dirs=("global" "planning" "process" "quality" "mcp" "technical" "documentation" "domain" "projects")
  for dir in "${rule_dirs[@]}"; do
    if [ -d "$target/.claude/rules/$dir" ]; then
      rm -rf "$target/.claude/rules/$dir"
    fi
  done
  # Remove root-level rules
  rm -f "$target/.claude/rules/src-code.md" "$target/.claude/rules/tests.md"
  if [ -d "$target/.claude/rules" ] && [ -z "$(ls -A "$target/.claude/rules" 2>/dev/null)" ]; then
    rmdir "$target/.claude/rules" 2>/dev/null || true
  fi
  success "Removed installed rules"

  # Remove best practices directory
  if [ -d "$target/.claude/best-practices" ]; then
    rm -rf "$target/.claude/best-practices"
    success "Removed .claude/best-practices/"
  fi

  # Remove commands
  if [ -d "$target/.claude/commands" ]; then
    local cmds=("session-start.md" "session-end.md" "advise.md" "retrospective.md" "slashes.md")
    for cmd in "${cmds[@]}"; do
      rm -f "$target/.claude/commands/$cmd"
    done
    if [ -z "$(ls -A "$target/.claude/commands" 2>/dev/null)" ]; then
      rmdir "$target/.claude/commands" 2>/dev/null || true
    fi
    success "Removed installed commands"
  fi

  # Remove hooks
  if [ -d "$target/.claude/hooks" ]; then
    local hooks=("pre-prompt.sh" "session-start.sh" "pre-compact.sh" "prettier-format.sh")
    for hook in "${hooks[@]}"; do
      rm -f "$target/.claude/hooks/$hook"
    done
    if [ -z "$(ls -A "$target/.claude/hooks" 2>/dev/null)" ]; then
      rmdir "$target/.claude/hooks" 2>/dev/null || true
    fi
    success "Removed installed hooks"
  fi

  # Remove marker
  rm -f "$target/.claude/$MARKER_FILE"

  # Remove import from CLAUDE.md
  if [ -f "$target/CLAUDE.md" ]; then
    if grep -qF "@.claude/best-practices/BEST-PRACTICES.md" "$target/CLAUDE.md"; then
      grep -vF "@.claude/best-practices/BEST-PRACTICES.md" "$target/CLAUDE.md" \
        | grep -v "# Claude Code Best Practices (auto-installed from claude-code-guide)" \
        > "$target/CLAUDE.md.tmp"
      mv "$target/CLAUDE.md.tmp" "$target/CLAUDE.md"
      success "Removed best practices import from CLAUDE.md"
    fi
  fi

  # Note about skills (user-level, not auto-removed)
  echo ""
  warn "Skills in ~/.claude/skills/ were NOT removed (they're user-level)."
  echo "  To remove manually: rm -rf ~/.claude/skills/{troubleshooting-decision-tree,session-start-protocol,project-patterns}-skill"
  echo ""
  success "Uninstall complete."
}

# --- Main install ---
do_install() {
  local target="$1"
  local rules_only="$2"
  local install_skills="$3"
  local install_commands="$4"
  local install_hooks="$5"
  local install_all_rules_flag="$6"

  header "Installing Claude Code Best Practices"
  echo "  Target:     $target"
  echo "  Source:     $SOURCE"

  # Show what will be installed
  echo "  Components:"
  if [ "$rules_only" = "true" ]; then
    echo "    - Core rules (6)"
  else
    if [ "$install_all_rules_flag" = "true" ]; then
      echo "    - All rules (19 across 9 categories)"
    else
      echo "    - Core rules (6)"
    fi
    echo "    - BEST-PRACTICES.md"
    echo "    - CLAUDE.md import"
    [ "$install_skills" = "true" ] && echo "    - Starter skills (3) -> ~/.claude/skills/"
    [ "$install_commands" = "true" ] && echo "    - Slash commands (5)"
    [ "$install_hooks" = "true" ] && echo "    - Hooks (4) + settings.json"
  fi
  echo ""

  # Check if already installed
  local installed_version
  installed_version="$(get_installed_version "$target")"
  if [ "$installed_version" != "none" ]; then
    warn "Best practices already installed (v${installed_version})"
    warn "Use --update to update, or --uninstall first."
    echo ""
    read -r -p "Continue and overwrite? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[Yy] ]]; then
      info "Aborted."
      exit 0
    fi
  fi

  # Create base directory
  mkdir -p "$target/.claude"

  # --- Core: Rules ---
  if [ "$install_all_rules_flag" = "true" ]; then
    info "Installing all 19 rules..."
    install_all_rules "$target"
  else
    info "Installing core rules..."
    install_core_rules "$target"
  fi

  # --- Core: Best practices doc + updater + CLAUDE.md ---
  if [ "$rules_only" = "false" ]; then
    info "Installing best practices document..."
    install_best_practices_doc "$target"

    info "Creating update script..."
    create_updater "$target"

    info "Configuring CLAUDE.md..."
    add_claude_md_import "$target"
  fi

  # --- Skills ---
  if [ "$install_skills" = "true" ]; then
    info "Installing starter skills..."
    install_skills
  fi

  # --- Commands ---
  if [ "$install_commands" = "true" ]; then
    info "Installing slash commands..."
    install_commands "$target"
  fi

  # --- Hooks ---
  if [ "$install_hooks" = "true" ]; then
    info "Installing hooks..."
    install_hooks "$target"
  fi

  # Write marker
  write_marker "$target"

  # --- Summary ---
  echo ""
  header "Installation Complete"
  echo ""
  echo "  What was installed:"
  if [ "$install_all_rules_flag" = "true" ]; then
    echo "    .claude/rules/               -- 19 rules across 9 categories (auto-loaded)"
  else
    echo "    .claude/rules/best-practices/ -- 6 core rules (auto-loaded)"
  fi
  if [ "$rules_only" = "false" ]; then
    echo "    .claude/best-practices/       -- Best practices document + updater"
    echo "    CLAUDE.md                     -- @ import added"
  fi
  [ "$install_skills" = "true" ] && \
    echo "    ~/.claude/skills/             -- 3 starter skills (global)"
  [ "$install_commands" = "true" ] && \
    echo "    .claude/commands/             -- 5 slash commands"
  [ "$install_hooks" = "true" ] && \
    echo "    .claude/hooks/                -- 4 hooks + settings.json"

  echo ""
  echo "  Claude Code will now automatically apply best practices"
  echo "  in every session for this project."
  echo ""
  echo "  Next steps:"
  [ "$rules_only" = "false" ] && \
    echo "    1. Review CLAUDE.md and add project-specific instructions"
  [ "$install_commands" = "true" ] && \
    echo "    2. Try: /session-start, /advise, /slashes"
  [ "$install_all_rules_flag" = "true" ] && \
    echo "    3. Customize: .claude/rules/domain/patterns.md (your business rules)"
  echo "    - Update: bash .claude/best-practices/update.sh"
  echo "    - Full guide: $REPO_URL"
  echo ""
}

# --- Update existing installation ---
do_update() {
  local target="$1"
  local installed_version
  installed_version="$(get_installed_version "$target")"

  if [ "$installed_version" = "none" ]; then
    error "No existing installation found. Run without --update to install."
    exit 1
  fi

  header "Updating Claude Code Best Practices"
  echo "  Current version: $installed_version"

  local latest_version
  latest_version="$(get_latest_version)"
  echo "  Latest version:  $latest_version"
  echo ""

  if [ "$installed_version" = "$latest_version" ]; then
    success "Already up to date (v${latest_version})"
    exit 0
  fi

  info "Updating from v${installed_version} to v${latest_version}..."

  # Update core components
  install_core_rules "$target"
  install_best_practices_doc "$target"
  create_updater "$target"
  write_marker "$target"

  # Update all rules if they were installed
  if [ -d "$target/.claude/rules/global" ]; then
    info "Updating all rules..."
    install_all_rules "$target"
  fi

  # Update commands if they were installed
  if [ -d "$target/.claude/commands" ]; then
    info "Updating commands..."
    install_commands "$target"
  fi

  # Update hooks if they were installed
  if [ -d "$target/.claude/hooks/pre-prompt.sh" ] || [ -f "$target/.claude/hooks/pre-prompt.sh" ]; then
    info "Updating hooks..."
    local hooks=("pre-prompt.sh" "session-start.sh" "pre-compact.sh" "prettier-format.sh")
    for hook in "${hooks[@]}"; do
      if [ -f "$target/.claude/hooks/$hook" ]; then
        fetch_file "$TEMPLATE_DIR/.claude/hooks/$hook" "$target/.claude/hooks/$hook"
        chmod +x "$target/.claude/hooks/$hook"
      fi
    done
    success "Updated hook scripts"
  fi

  # Update skills if they were installed
  if [ -d "$HOME/.claude/skills/troubleshooting-decision-tree-skill" ]; then
    info "Updating skills..."
    install_skills
  fi

  echo ""
  success "Updated to v${latest_version}"
}

# =============================================================================
# Main Entry Point
# =============================================================================

main() {
  local mode="install"
  local target_dir=""
  local global_install=false
  local rules_only=false
  local opt_skills=false
  local opt_commands=false
  local opt_hooks=false
  local opt_all_rules=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h)
        usage
        ;;
      --global|-g)
        global_install=true
        shift
        ;;
      --rules-only)
        rules_only=true
        shift
        ;;
      --skills)
        opt_skills=true
        shift
        ;;
      --commands)
        opt_commands=true
        shift
        ;;
      --hooks)
        opt_hooks=true
        shift
        ;;
      --all-rules)
        opt_all_rules=true
        shift
        ;;
      --full)
        opt_skills=true
        opt_commands=true
        opt_all_rules=true
        shift
        ;;
      --with-hooks)
        opt_skills=true
        opt_commands=true
        opt_all_rules=true
        opt_hooks=true
        shift
        ;;
      --update|-u)
        mode="update"
        shift
        ;;
      --uninstall|--remove)
        mode="uninstall"
        shift
        ;;
      -*)
        error "Unknown option: $1"
        echo "Run with --help for usage."
        exit 1
        ;;
      *)
        target_dir="$1"
        shift
        ;;
    esac
  done

  # Determine target directory
  if [ "$global_install" = true ]; then
    target_dir="$HOME"
  elif [ -z "$target_dir" ]; then
    target_dir="$(pwd)"
  fi

  # Resolve to absolute path
  target_dir="$(cd "$target_dir" && pwd)"

  # Detect source (local clone vs remote)
  detect_source

  # Execute mode
  case "$mode" in
    install)
      do_install "$target_dir" "$rules_only" "$opt_skills" "$opt_commands" "$opt_hooks" "$opt_all_rules"
      ;;
    update)
      do_update "$target_dir"
      ;;
    uninstall)
      do_uninstall "$target_dir"
      ;;
  esac
}

main "$@"
