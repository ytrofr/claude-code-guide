#!/bin/bash
# =============================================================================
# Claude Code Best Practices Installer
# Source: https://github.com/ytrofr/claude-code-guide
#
# Usage:
#   Remote (one-liner):
#     curl -sL https://raw.githubusercontent.com/ytrofr/claude-code-guide/master/install.sh | bash
#
#   Local (after cloning):
#     ./install.sh                    # Install into current project
#     ./install.sh /path/to/project   # Install into specific project
#     ./install.sh --global           # Install into ~/.claude (all projects)
#
#   Options:
#     --global          Install to ~/.claude/ (applies to all projects)
#     --rules-only      Only install rules, skip BEST-PRACTICES.md
#     --update          Update existing installation to latest version
#     --uninstall       Remove installed best practices
#     --help            Show this help message
# =============================================================================

set -euo pipefail

# --- Configuration ---
REPO_URL="https://github.com/ytrofr/claude-code-guide"
RAW_BASE="https://raw.githubusercontent.com/ytrofr/claude-code-guide/master"
BP_DIR="best-practices"
MARKER_FILE=".claude-best-practices-installed"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# --- Helper Functions ---
info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }
header()  { echo -e "\n${BOLD}$*${NC}"; }

usage() {
  cat <<'USAGE'
Claude Code Best Practices Installer
Source: https://github.com/ytrofr/claude-code-guide

USAGE:
  curl -sL https://raw.githubusercontent.com/ytrofr/claude-code-guide/master/install.sh | bash
  ./install.sh [OPTIONS] [TARGET_DIR]

OPTIONS:
  --global       Install to ~/.claude/ (applies to all projects)
  --rules-only   Only install rules (skip BEST-PRACTICES.md import)
  --update       Update existing installation to latest version
  --uninstall    Remove installed best practices
  --help         Show this help message

EXAMPLES:
  ./install.sh                       # Install in current project
  ./install.sh ~/my-project          # Install in specific project
  ./install.sh --global              # Install globally for all projects
  ./install.sh --update              # Update to latest version
  ./install.sh --uninstall           # Remove installation

WHAT GETS INSTALLED:
  .claude/rules/best-practices/      # 6 universal rules (auto-loaded by Claude Code)
  .claude/best-practices/            # Best practices document + updater
  CLAUDE.md                          # @ import added (or created)
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

# --- Download a file from the repo ---
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

# --- Install rules ---
install_rules() {
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

  success "Installed ${#rules[@]} universal rules to .claude/rules/best-practices/"
}

# --- Install best practices document ---
install_best_practices_doc() {
  local target="$1"
  local bp_dir="$target/.claude/best-practices"

  mkdir -p "$bp_dir"

  # Copy main document
  fetch_file "$BP_DIR/BEST-PRACTICES.md" "$bp_dir/BEST-PRACTICES.md"

  # Write version file
  local version
  version="$(get_latest_version)"
  echo "$version" > "$bp_dir/.version"

  # Write install metadata
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

# Get current and latest versions
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

# Update rules
RULES=("context-checking.md" "validation-workflow.md" "safety-rules.md" "no-mock-data.md" "anti-overengineering.md" "session-protocol.md")
mkdir -p "$RULES_DIR"
for rule in "${RULES[@]}"; do
  curl -sL "$REPO_RAW/best-practices/rules/$rule" -o "$RULES_DIR/$rule"
done

# Update version
echo "$LATEST" > "$BP_DIR/.version"

# Update metadata
cat > "$BP_DIR/.metadata" <<EOF
installed_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
source=remote
version=$LATEST
repo=https://github.com/ytrofr/claude-code-guide
EOF

echo -e "${GREEN}Updated to v${LATEST} successfully.${NC}"
echo "  - BEST-PRACTICES.md updated"
echo "  - ${#RULES[@]} rules updated"
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

  # If CLAUDE.md exists, check if import is already there
  if [ -f "$claude_md" ]; then
    if grep -qF "$import_line" "$claude_md"; then
      info "CLAUDE.md already imports best practices (skipping)"
      return
    fi

    # Append import to existing CLAUDE.md
    {
      echo ""
      echo "---"
      echo ""
      echo "$import_comment"
      echo "$import_line"
    } >> "$claude_md"

    success "Added best practices import to existing CLAUDE.md"
  else
    # Create minimal CLAUDE.md with import
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

# --- Uninstall ---
do_uninstall() {
  local target="$1"

  header "Uninstalling Claude Code Best Practices..."

  # Remove rules
  if [ -d "$target/.claude/rules/best-practices" ]; then
    rm -rf "$target/.claude/rules/best-practices"
    success "Removed .claude/rules/best-practices/"
  fi

  # Remove best practices directory
  if [ -d "$target/.claude/best-practices" ]; then
    rm -rf "$target/.claude/best-practices"
    success "Removed .claude/best-practices/"
  fi

  # Remove marker
  rm -f "$target/.claude/$MARKER_FILE"

  # Remove import from CLAUDE.md (if present)
  if [ -f "$target/CLAUDE.md" ]; then
    if grep -qF "@.claude/best-practices/BEST-PRACTICES.md" "$target/CLAUDE.md"; then
      # Remove the import line and comment using grep -v (avoids sed delimiter issues)
      grep -vF "@.claude/best-practices/BEST-PRACTICES.md" "$target/CLAUDE.md" \
        | grep -v "# Claude Code Best Practices (auto-installed from claude-code-guide)" \
        > "$target/CLAUDE.md.tmp"
      mv "$target/CLAUDE.md.tmp" "$target/CLAUDE.md"
      success "Removed best practices import from CLAUDE.md"
    fi
  fi

  echo ""
  success "Uninstall complete."
}

# --- Main install ---
do_install() {
  local target="$1"
  local rules_only="${2:-false}"

  header "Installing Claude Code Best Practices"
  echo "  Target: $target"
  echo "  Source: $SOURCE"
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

  # Create .claude directory
  mkdir -p "$target/.claude"

  # Step 1: Install rules
  info "Installing universal rules..."
  install_rules "$target"

  # Step 2: Install best practices document
  if [ "$rules_only" = "false" ]; then
    info "Installing best practices document..."
    install_best_practices_doc "$target"

    # Step 3: Create updater
    info "Creating update script..."
    create_updater "$target"

    # Step 4: Add CLAUDE.md import
    info "Configuring CLAUDE.md..."
    add_claude_md_import "$target"
  fi

  # Step 5: Write marker
  write_marker "$target"

  # Summary
  echo ""
  header "Installation Complete"
  echo ""
  echo "  What was installed:"
  echo "    .claude/rules/best-practices/  -- 6 universal rules (auto-loaded)"
  if [ "$rules_only" = "false" ]; then
    echo "    .claude/best-practices/        -- Best practices document + updater"
    echo "    CLAUDE.md                      -- @ import added"
  fi
  echo ""
  echo "  Claude Code will now automatically apply these best practices"
  echo "  in every session for this project."
  echo ""
  echo "  Next steps:"
  echo "    1. Review .claude/best-practices/BEST-PRACTICES.md"
  echo "    2. Customize CLAUDE.md with project-specific rules"
  echo "    3. Run 'bash .claude/best-practices/update.sh' to check for updates"
  echo ""
  echo "  Full guide: $REPO_URL"
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

  install_rules "$target"
  install_best_practices_doc "$target"
  create_updater "$target"
  write_marker "$target"

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
      do_install "$target_dir" "$rules_only"
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
