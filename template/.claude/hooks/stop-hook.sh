#!/bin/bash
# Stop Hook - Claude Code Hook (NOT Git Hook)
# Created: 2025-12-19
# Source: Anthropic blog - "How to Configure Hooks"
# Purpose: Run when Claude finishes a response
# Hook Type: Stop (runs after Claude completes a turn)

# ═══════════════════════════════════════════════════════════════════
# TASK COMPLETION & LEARNING CAPTURE
# ═══════════════════════════════════════════════════════════════════

# Read JSON input from stdin
JSON_INPUT=$(cat)
SESSION_ID=$(echo "$JSON_INPUT" | jq -r '.session_id // empty' 2>/dev/null)

# Log session completion for metrics
METRICS_LOG="$HOME/.claude/metrics/session-completions.jsonl"
if [ -n "$SESSION_ID" ]; then
    mkdir -p "$(dirname "$METRICS_LOG")"
    TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    echo "{\"timestamp\":\"$TIMESTAMP\",\"session_id\":\"$SESSION_ID\"}" >> "$METRICS_LOG"
fi

# Output reminder for skill creation if significant work was done
# This appears in Claude's context after the response completes
cat <<EOF

═══════════════════════════════════════════════════════════════════
💡 SESSION CHECKPOINT
═══════════════════════════════════════════════════════════════════

Consider:
- /retrospective - Create skill from session learnings
- Update system-status.json if feature completed
- Commit work if at a good stopping point

EOF

exit 0
