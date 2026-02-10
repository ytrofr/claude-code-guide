#!/bin/bash
# Subagent Monitor Hook - tracks agent lifecycle
# Triggers: SubagentStart, SubagentStop

JSON_INPUT=$(timeout 2 cat 2>/dev/null || echo '{}')
EVENT_TYPE=$(echo "$JSON_INPUT" | jq -r '.event // "unknown"' 2>/dev/null)
AGENT_NAME=$(echo "$JSON_INPUT" | jq -r '.agent_name // "unknown"' 2>/dev/null)

# Log agent activity
echo "[$(date -u +%H:%M:%S)] $EVENT_TYPE: $AGENT_NAME" >> .claude/agent-activity.log
