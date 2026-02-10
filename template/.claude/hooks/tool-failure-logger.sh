#!/bin/bash
# Tool Failure Logger - logs tool execution failures
# Trigger: PostToolUseFailure

JSON_INPUT=$(timeout 2 cat 2>/dev/null || echo '{}')
TOOL_NAME=$(echo "$JSON_INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null)
ERROR=$(echo "$JSON_INPUT" | jq -r '.error // "unknown"' 2>/dev/null)

# Log failure for debugging
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] FAIL: $TOOL_NAME - $ERROR" >> .claude/tool-failures.log
