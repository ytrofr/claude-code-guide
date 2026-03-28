#!/bin/bash
# PreToolUse hook: Advisory reminder when marking tasks completed
# Matches: TaskUpdate
# Mode: Advisory (exit 0) — reminds, doesn't block
# Source: claude-code-guide chapter 64

JSON_INPUT=$(timeout 2 cat 2>/dev/null || echo '{}')

NEW_STATUS=$(echo "$JSON_INPUT" | jq -r '.tool_input.status // empty' 2>/dev/null)

# Only remind on status change to "completed"
[ "$NEW_STATUS" != "completed" ] && exit 0

echo ""
echo "━━━ VERIFICATION REMINDER ━━━"
echo "Before marking complete, confirm you have:"
echo "  • Run the relevant test/curl/check (not just assumed it works)"
echo "  • Verified actual output matches expected output"
echo "  • Checked for side effects or regressions"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

exit 0
