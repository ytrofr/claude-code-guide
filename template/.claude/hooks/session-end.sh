#!/bin/bash
# Session End Hook - runs when Claude Code session ends
# Use for: cleanup, final commits, session summaries

# Read hook input from stdin
JSON_INPUT=$(timeout 2 cat 2>/dev/null || echo '{}')

# Example: Log session end
echo "Session ended at $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> .claude/session.log

# Example: Remind about uncommitted changes
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  echo '{"decision": "allow", "reason": "Reminder: You have uncommitted changes"}'
fi
