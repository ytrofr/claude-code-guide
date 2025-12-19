#!/bin/bash
# Session Start Hook - Claude Code Hook (NOT Git Hook)
# Created: 2025-12-19
# Source: Anthropic blog - "How to Configure Hooks"
# Purpose: Inject project context at session start
# Hook Type: SessionStart (runs when Claude Code session begins/resumes)

# ═══════════════════════════════════════════════════════════════════
# SESSION CONTEXT INJECTION
# ═══════════════════════════════════════════════════════════════════

echo "═══════════════════════════════════════════════════════════════════"
echo "📋 SESSION CONTEXT (Auto-Loaded)"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

# Branch info
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
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
