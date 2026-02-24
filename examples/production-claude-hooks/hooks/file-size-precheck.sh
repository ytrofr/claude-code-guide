#!/bin/bash
# PreToolUse hook: Check Write content size BEFORE file is created
# Fires BEFORE: Write (not Edit -- edits are usually small changes)
# Purpose: Catch new god files BEFORE they're written to disk
# Rule: Max 500 lines per source file
#
# DESIGN: Non-blocking (exit 0 always). Claude sees the warning and
# can self-correct by splitting the file before the next write.

# Read JSON from stdin
JSON_INPUT=$(timeout 2 cat 2>/dev/null || true)

# Extract file path
FILE_PATH=$(echo "$JSON_INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

# No file path -- exit silently
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Only check source code files
case "$FILE_PATH" in
  *.js|*.jsx|*.ts|*.tsx|*.py|*.sh)
    ;; # Check these
  *)
    exit 0 ;; # Skip non-source files
esac

# Skip test files and scripts
case "$FILE_PATH" in
  */node_modules/*|*/dist/*|*package-lock*|*/tests/*|*/scripts/baselines/*)
    exit 0 ;;
esac

# For Write tool, content is in tool_input.content
# Count lines in the content being written
CONTENT_LINES=$(echo "$JSON_INPUT" | jq -r '.tool_input.content // empty' 2>/dev/null | wc -l)

# If content is empty or small, allow
if [ "$CONTENT_LINES" -le 300 ]; then
  exit 0
fi

BASENAME=$(basename "$FILE_PATH")

# Check if this is a NEW file (doesn't exist yet) vs overwriting existing
if [ ! -f "$FILE_PATH" ]; then
  FILE_STATUS="NEW file"
else
  FILE_STATUS="overwriting existing"
fi

if [ "$CONTENT_LINES" -gt 500 ]; then
  echo ""
  echo "======================================================================="
  echo "FILE SIZE: $BASENAME will be $CONTENT_LINES lines ($FILE_STATUS)"
  echo "======================================================================="
  echo "File: $FILE_PATH"
  echo ""
  echo "This file exceeds the 500-line limit. Consider splitting into:"
  echo "  - Main module: core logic (<400 lines)"
  echo "  - Helper module: extracted functions"
  echo ""
  echo "Allowing write -- but please split this file next."
  echo "======================================================================="
  # Non-blocking: exit 0 allows write, shows warning
  exit 0
elif [ "$CONTENT_LINES" -gt 400 ]; then
  echo ""
  echo "-----------------------------------------------------------------------"
  echo "WARNING: $BASENAME will be $CONTENT_LINES lines ($FILE_STATUS)"
  echo "-----------------------------------------------------------------------"
  echo "Approaching 500-line limit. Plan extraction now."
  echo "-----------------------------------------------------------------------"
  exit 0
fi

exit 0
