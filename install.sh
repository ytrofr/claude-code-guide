#!/bin/bash
# =============================================================================
# Claude Code Best Practices Installer — v5.0 (manifest-driven)
# Source: https://github.com/ytrofr/claude-code-guide
#
# Tiers:
#   (default)        Core — 8 rules, 3 skills, 1 hook
#   --recommended    Working developer — ~30 rules, 16 skills, 7 hooks
#   --full           Power user — 55+ rules, 43 skills, 12 hooks + governance
#
# Usage:
#   Remote (Core only):
#     curl -sL https://raw.githubusercontent.com/ytrofr/claude-code-guide/master/install.sh | bash
#
#   Local (required for Recommended/Full):
#     git clone https://github.com/ytrofr/claude-code-guide.git
#     cd claude-code-guide
#     ./install.sh [--recommended|--full] [--global] [--dry-run] [--rules-only]
#     ./install.sh --uninstall
#     ./install.sh --update
# =============================================================================

set -euo pipefail

REPO_URL="https://github.com/ytrofr/claude-code-guide"
RAW_BASE="https://raw.githubusercontent.com/ytrofr/claude-code-guide/master"
BP_DIR="best-practices"
TEMPLATE_DIR="template"
MARKER_FILE=".claude-best-practices-installed"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }
header()  { echo -e "\n${BOLD}$*${NC}"; }
dim()     { echo -e "${DIM}$*${NC}"; }

usage() {
  cat <<'USAGE'
Claude Code Best Practices Installer (v5.0, manifest-driven)

USAGE:
  curl -sL https://raw.githubusercontent.com/ytrofr/claude-code-guide/master/install.sh | bash
  ./install.sh [OPTIONS] [TARGET_DIR]

TIERS:
  (default)        Core (8 rules, 3 skills, 1 hook) -- newcomer-friendly
  --recommended    Working developer (30 rules, 16 skills, 7 hooks)
  --full           Power user (55+ rules, 43 skills, 12 hooks + governance)

OPTIONS:
  --global         Install to ~/.claude/ (applies to all projects)
  --rules-only     Install rules only (skip skills/hooks/docs)
  --dry-run        Print what would install; touch no files
  --update         Sync Core tier to latest
  --uninstall      Remove installed best practices (per manifest)
  --help           Show this help

REMOTE ONE-LINER LIMITATION:
  curl | bash installs ONLY the Core tier. Recommended/Full require cloning.
USAGE
  exit 0
}

# --- Source detection ---
detect_source() {
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
  if [ -f "$SCRIPT_DIR/$BP_DIR/manifest.json" ]; then
    SOURCE="local"
    SOURCE_DIR="$SCRIPT_DIR"
  else
    SOURCE="remote"
    SOURCE_DIR=""
  fi
}

# --- Fetch file (local cp or remote curl) ---
fetch_file() {
  local remote_path="$1"; local local_path="$2"
  if [ "$SOURCE" = "local" ]; then
    mkdir -p "$(dirname "$local_path")"
    cp "$SOURCE_DIR/$remote_path" "$local_path"
  elif command -v curl &>/dev/null; then
    mkdir -p "$(dirname "$local_path")"
    curl -sLf "$RAW_BASE/$remote_path" -o "$local_path"
  else
    error "Neither local source nor curl available."
    return 1
  fi
}

# --- Read manifest ---
read_manifest() {
  local manifest
  if [ "$SOURCE" = "local" ]; then
    manifest="$SOURCE_DIR/$BP_DIR/manifest.json"
  else
    manifest="$(mktemp)"
    curl -sLf "$RAW_BASE/$BP_DIR/manifest.json" -o "$manifest" \
      || { error "Could not fetch manifest.json from $RAW_BASE"; exit 1; }
  fi
  echo "$manifest"
}

# --- Resolve tier (walk extends chain), print JSON of resolved artifacts ---
resolve_tier() {
  local manifest="$1"; local tier="$2"
  jq --arg t "$tier" '
    def resolve(name):
      .tiers[name] as $t
      | (if ($t.extends // null) then resolve($t.extends) else {rules: [], skills: [], hooks: [], scripts: [], docs: [], templates: [], mcp_config_templates: []} end) as $parent
      | {
          rules: ($parent.rules + ($t.rules // [])),
          skills: ($parent.skills + ($t.skills // [])),
          hooks: ($parent.hooks + ($t.hooks // [])),
          scripts: ($parent.scripts + ($t.scripts // [])),
          docs: ($parent.docs + ($t.docs // [])),
          templates: ($parent.templates + ($t.templates // [])),
          mcp_config_templates: ($parent.mcp_config_templates + ($t.mcp_config_templates // []))
        };
    resolve($t)
  ' "$manifest"
}

# --- Dry-run summary ---
dry_run_summary() {
  local resolved="$1"; local tier="$2"; local target="$3"
  header "DRY RUN — tier: $tier, target: $target"
  echo "  Rules:   $(echo "$resolved" | jq '.rules | length')"
  echo "  Skills:  $(echo "$resolved" | jq '.skills | length')"
  echo "  Hooks:   $(echo "$resolved" | jq '.hooks | length')"
  echo "  Scripts: $(echo "$resolved" | jq '.scripts | length')"
  echo ""
  echo "  Would install to: $target/.claude/"
  echo ""
  dim "  Rule files:"
  echo "$resolved" | jq -r '.rules[]' | sed 's/^/    /'
  dim "  Skills:"
  echo "$resolved" | jq -r '.skills[]' | sed 's/^/    /'
  dim "  Hooks:"
  echo "$resolved" | jq -r '.hooks[] | "    \(.event): \(.script)"'
}

# --- Install from resolved manifest ---
install_tier() {
  local resolved="$1"; local tier="$2"; local target="$3"
  local rules_only="${4:-false}"

  header "Installing tier: $tier"
  echo "  Target: $target"

  # Rules
  local rules_dir="$target/.claude/rules"
  mkdir -p "$rules_dir"
  local rule_count=0
  while IFS= read -r rule; do
    [ -z "$rule" ] && continue
    fetch_file "$TEMPLATE_DIR/.claude/rules/$rule" "$rules_dir/$rule"
    rule_count=$((rule_count + 1))
  done < <(echo "$resolved" | jq -r '.rules[]')
  success "Installed $rule_count rules to $rules_dir/"

  [ "$rules_only" = "true" ] && return 0

  # Skills (always installed to ~/.claude/skills/ — global)
  local skills_dir="$HOME/.claude/skills"
  mkdir -p "$skills_dir"
  local skill_count=0
  while IFS= read -r skill; do
    [ -z "$skill" ] && continue
    local skill_src="$TEMPLATE_DIR/.claude/skills/$skill/SKILL.md"
    local skill_dst="$skills_dir/$skill/SKILL.md"
    fetch_file "$skill_src" "$skill_dst"
    skill_count=$((skill_count + 1))
  done < <(echo "$resolved" | jq -r '.skills[]')
  success "Installed $skill_count skills to $skills_dir/"

  # Hooks
  local hooks_dir="$target/.claude/hooks"
  mkdir -p "$hooks_dir"
  local hook_count=0
  while IFS= read -r hook_line; do
    [ -z "$hook_line" ] && continue
    local script
    script=$(echo "$hook_line" | jq -r '.script')
    fetch_file "$TEMPLATE_DIR/.claude/hooks/$script" "$hooks_dir/$script"
    chmod +x "$hooks_dir/$script"
    hook_count=$((hook_count + 1))
  done < <(echo "$resolved" | jq -c '.hooks[]')
  success "Installed $hook_count hooks to $hooks_dir/"

  # Write marker
  local manifest_version
  manifest_version=$(jq -r '.version' "$(read_manifest)")
  cat > "$target/.claude/$MARKER_FILE" <<EOF
version=$manifest_version
tier=$tier
installed_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
source=$SOURCE
rules=$rule_count
skills=$skill_count
hooks=$hook_count
EOF

  success "Install complete (tier: $tier, version: $manifest_version)"
}

# --- Uninstall using marker + manifest ---
do_uninstall() {
  local target="$1"
  local marker="$target/.claude/$MARKER_FILE"

  if [ ! -f "$marker" ]; then
    error "No install marker found at $marker. Nothing to uninstall."
    exit 1
  fi

  local tier
  tier=$(grep '^tier=' "$marker" | cut -d= -f2)
  info "Uninstalling tier: $tier"

  local manifest
  manifest=$(read_manifest)
  local resolved
  resolved=$(resolve_tier "$manifest" "$tier")

  # Remove rules
  while IFS= read -r rule; do
    [ -z "$rule" ] && continue
    rm -f "$target/.claude/rules/$rule"
  done < <(echo "$resolved" | jq -r '.rules[]')
  success "Removed rule files"

  # Remove hooks
  while IFS= read -r hook_line; do
    [ -z "$hook_line" ] && continue
    local script
    script=$(echo "$hook_line" | jq -r '.script')
    rm -f "$target/.claude/hooks/$script"
  done < <(echo "$resolved" | jq -c '.hooks[]')
  success "Removed hook scripts"

  # Skills are user-level; warn but don't remove
  warn "Skills in ~/.claude/skills/ NOT removed (shared across projects)."

  rm -f "$marker"
  success "Uninstall complete."
}

# --- Main ---
main() {
  local tier="core"
  local target_dir=""
  local global_install=false
  local rules_only=false
  local dry_run=false
  local mode="install"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h) usage ;;
      --global|-g) global_install=true; shift ;;
      --recommended) tier="recommended"; shift ;;
      --full) tier="full"; shift ;;
      --rules-only) rules_only=true; shift ;;
      --dry-run) dry_run=true; shift ;;
      --update) mode="update"; shift ;;
      --uninstall|--remove) mode="uninstall"; shift ;;
      -*) error "Unknown option: $1"; exit 1 ;;
      *) target_dir="$1"; shift ;;
    esac
  done

  if [ "$global_install" = true ]; then target_dir="$HOME"
  elif [ -z "$target_dir" ]; then target_dir="$(pwd)"; fi
  target_dir="$(cd "$target_dir" && pwd)"

  detect_source

  # Remote + non-core requires clone
  if [ "$SOURCE" = "remote" ] && [ "$tier" != "core" ]; then
    error "Tier '$tier' requires cloning the repo. Run:"
    error "  git clone $REPO_URL && cd claude-code-guide && ./install.sh --$tier"
    exit 1
  fi

  # Require jq
  command -v jq &>/dev/null || { error "jq required. Install with your package manager."; exit 1; }

  case "$mode" in
    install)
      local manifest; manifest=$(read_manifest)
      local resolved; resolved=$(resolve_tier "$manifest" "$tier")
      if [ "$dry_run" = true ]; then
        dry_run_summary "$resolved" "$tier" "$target_dir"
      else
        install_tier "$resolved" "$tier" "$target_dir" "$rules_only"
      fi
      ;;
    uninstall)
      do_uninstall "$target_dir"
      ;;
    update)
      # Minimal update: rerun install (idempotent, overwrites)
      local manifest; manifest=$(read_manifest)
      local existing_tier="core"
      [ -f "$target_dir/.claude/$MARKER_FILE" ] && \
        existing_tier=$(grep '^tier=' "$target_dir/.claude/$MARKER_FILE" | cut -d= -f2)
      local resolved; resolved=$(resolve_tier "$manifest" "$existing_tier")
      install_tier "$resolved" "$existing_tier" "$target_dir" false
      ;;
  esac
}

main "$@"
