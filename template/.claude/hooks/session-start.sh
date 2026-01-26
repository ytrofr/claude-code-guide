#!/bin/bash
# Session Start Hook - Claude Code Hook (NOT Git Hook)
# Created: 2025-12-19
# Enhanced: 2026-01-26 (Guide 35 - Dynamic @ Import Mechanism)
# Source: Anthropic blog - "How to Configure Hooks"
# Purpose: Inject project context + auto-load branch-specific files via @ imports
# Hook Type: SessionStart (runs when Claude Code session begins/resumes)
#
# CRITICAL: This hook WRITES @imports to CLAUDE.md (not just displays them!)
# The @ symbol only triggers file loading when it's IN CLAUDE.md.

# Branch info (needed early for manifest lookup)
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

# ═══════════════════════════════════════════════════════════════════
# STEP 1: DYNAMIC @ IMPORT GENERATION (Guide 35)
# CRITICAL: This WRITES to CLAUDE.md - files actually get loaded!
# ═══════════════════════════════════════════════════════════════════

if [ -f "CLAUDE.md" ]; then
    # CLEANUP: Remove old auto-loaded sections to prevent accumulation
    if grep -q "AUTO-LOADED DOMAIN FILES" CLAUDE.md 2>/dev/null; then
        sed -i '/^## 🔄 AUTO-LOADED DOMAIN FILES/,$d' CLAUDE.md
    fi
    if grep -q "AUTO-LOADED BLUEPRINTS" CLAUDE.md 2>/dev/null; then
        sed -i '/^## 📘 AUTO-LOADED BLUEPRINTS/,$d' CLAUDE.md
    fi
fi

# Check for CONTEXT-MANIFEST.json (preferred method)
MANIFEST="CURRENT/${CURRENT_BRANCH}/CONTEXT-MANIFEST.json"

if [ -f "$MANIFEST" ]; then
    # WRITE section header to CLAUDE.md
    cat >> CLAUDE.md << EOF

---

## 🔄 AUTO-LOADED DOMAIN FILES (Session-Specific)

**Branch**: $CURRENT_BRANCH
**Source**: $MANIFEST

EOF

    # Extract files from manifest and WRITE @ imports
    jq -r '.ondemand_files | to_entries[] | .value[]' "$MANIFEST" 2>/dev/null | while read file; do
        [ -z "$file" ] && continue

        # Path resolution: absolute paths use as-is, relative prepend default
        if [[ "$file" == CURRENT/* ]] || [[ "$file" == docs/* ]] || [[ "$file" == memory-bank/* ]]; then
            FULL_PATH="$file"
        else
            FULL_PATH="memory-bank/ondemand/$file"
        fi

        # Only write @import if file exists
        [ -f "$FULL_PATH" ] && echo "@$FULL_PATH" >> CLAUDE.md
    done

    echo "" >> CLAUDE.md
    echo "_Auto-generated @ imports from CONTEXT-MANIFEST.json_" >> CLAUDE.md
fi

# Fallback: Load from branch-variables.json blueprints_auto_load
BRANCH_VARS_FILE="memory-bank/always/branch-variables.json"
if [ ! -f "$MANIFEST" ] && [ -f "$BRANCH_VARS_FILE" ]; then
    BLUEPRINTS=$(jq -r ".\"$CURRENT_BRANCH\".blueprints_auto_load[]?" "$BRANCH_VARS_FILE" 2>/dev/null)
    if [ -n "$BLUEPRINTS" ]; then
        cat >> CLAUDE.md << EOF

---

## 📘 AUTO-LOADED BLUEPRINTS (Branch-Specific)

**Branch**: $CURRENT_BRANCH

EOF
        while IFS= read -r bp_name; do
            [ -z "$bp_name" ] && continue
            # Try common blueprint locations
            for loc in "memory-bank/blueprints/${bp_name}-BLUEPRINT.md" \
                       "memory-bank/blueprints/${bp_name}.md" \
                       "memory-bank/always/${bp_name}.md"; do
                [ -f "$loc" ] && echo "@$loc" >> CLAUDE.md && break
            done
        done <<< "$BLUEPRINTS"
        echo "" >> CLAUDE.md
        echo "_Auto-generated from branch-variables.json_" >> CLAUDE.md
    fi
fi

# ═══════════════════════════════════════════════════════════════════
# STEP 2: SESSION CONTEXT DISPLAY (Original functionality)
# ═══════════════════════════════════════════════════════════════════

echo "═══════════════════════════════════════════════════════════════════"
echo "📋 SESSION CONTEXT (Auto-Loaded)"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

echo "Branch: $CURRENT_BRANCH"

# Git status (short)
echo ""
echo "Git Status:"
git status --short | head -5 || echo "Not in git repository"

# Last commit
echo ""
echo "Last Commit:"
git log -1 --oneline 2>/dev/null || echo "No commits yet"

# Active blockers from system-status.json
echo ""
echo "═══ ACTIVE BLOCKERS ═══"
if [ -f "memory-bank/always/system-status.json" ]; then
    BLOCKERS=$(jq -r '.active_blockers[]?.issue // empty' memory-bank/always/system-status.json 2>/dev/null)
    if [ -n "$BLOCKERS" ]; then
        echo "$BLOCKERS"
    else
        echo "None"
    fi
else
    echo "system-status.json not found"
fi

# Recent fixes (3 most recent)
echo ""
echo "═══ RECENT FIXES (Last 3) ═══"
if [ -f "memory-bank/always/system-status.json" ]; then
    jq -r '.recent_fixes[0:3][]? | "- \(.date): \(.issue)"' memory-bank/always/system-status.json 2>/dev/null || echo "No recent fixes"
else
    echo "system-status.json not found"
fi

# Branch-specific instructions reminder
echo ""
echo "═══ BRANCH INSTRUCTIONS ═══"
BRANCH_FILE="CURRENT/${CURRENT_BRANCH}/${CURRENT_BRANCH}-Instructions.md"
if [ -f "$BRANCH_FILE" ]; then
    echo "✅ Branch instructions: $BRANCH_FILE"
else
    echo "No branch-specific instructions"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════════"
