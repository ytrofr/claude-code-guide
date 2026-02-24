#!/bin/bash
# PostToolUse hook: Warn when edited files GROW past thresholds
# Fires AFTER: Write|Edit
# Purpose: Detect files growing toward god-file territory
# Rule: Max 500 lines per source file
#
# DESIGN: Only warns on files in the 300-500 range (approaching limit).
# Files already >500 lines are NOT flagged every time (too noisy with 250+
# existing violations). They only get flagged if they GREW by 20+ lines
# in this edit, tracked via /tmp/.claude-file-sizes cache.

# Read JSON from stdin (same pattern as prettier-format.sh)
JSON_INPUT=$(timeout 2 cat 2>/dev/null || true)

# Extract file path from tool input
FILE_PATH=$(echo "$JSON_INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

# No file path or file doesn't exist -- exit silently
if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Only check source code files (skip docs, configs, generated files)
case "$FILE_PATH" in
  *.js|*.jsx|*.ts|*.tsx|*.py|*.sh)
    ;; # Check these
  *)
    exit 0 ;; # Skip non-source files
esac

# Skip test files, scripts, and generated files
case "$FILE_PATH" in
  */node_modules/*|*/dist/*|*package-lock*|*/tests/*|*/scripts/baselines/*)
    exit 0 ;;
esac

LINE_COUNT=$(wc -l < "$FILE_PATH" 2>/dev/null || echo "0")
BASENAME=$(basename "$FILE_PATH")

# --- Growth detection for already-large files ---
CACHE_DIR="/tmp/.claude-file-sizes"
mkdir -p "$CACHE_DIR" 2>/dev/null
CACHE_KEY=$(echo "$FILE_PATH" | md5sum | cut -d' ' -f1)
CACHE_FILE="$CACHE_DIR/$CACHE_KEY"

PREV_SIZE=0
if [ -f "$CACHE_FILE" ]; then
  PREV_SIZE=$(cat "$CACHE_FILE" 2>/dev/null || echo "0")
fi

# Update cache with current size
echo "$LINE_COUNT" > "$CACHE_FILE"

GROWTH=$((LINE_COUNT - PREV_SIZE))

# --- Warning logic ---

if [ "$LINE_COUNT" -gt 500 ]; then
  # Already a god file. Only warn if it GREW significantly (20+ lines)
  if [ "$GROWTH" -ge 20 ] && [ "$PREV_SIZE" -gt 0 ]; then
    echo ""
    echo "-----------------------------------------------------------------------"
    echo "GROWING: $BASENAME grew +${GROWTH} lines -> now $LINE_COUNT lines"
    echo "-----------------------------------------------------------------------"
    echo "File: $FILE_PATH"
    echo "This file is already over 500L. Consider extracting the new code"
    echo "into a separate module instead of adding to this file."
    echo "-----------------------------------------------------------------------"
  fi
  # Existing >500L files with no growth: SILENT (avoids noise)
  exit 0

elif [ "$LINE_COUNT" -gt 400 ]; then
  echo ""
  echo "-----------------------------------------------------------------------"
  echo "WARNING: $BASENAME is $LINE_COUNT lines (approaching 500 limit)"
  echo "-----------------------------------------------------------------------"
  echo "File: $FILE_PATH"
  echo "Consider splitting before it grows further."
  echo "-----------------------------------------------------------------------"
  exit 0

elif [ "$LINE_COUNT" -gt 300 ]; then
  # Only note if it grew past 300 this edit (not every time)
  if [ "$PREV_SIZE" -le 300 ] && [ "$PREV_SIZE" -gt 0 ]; then
    echo "NOTE: $BASENAME crossed 300 lines ($PREV_SIZE -> $LINE_COUNT). Monitor growth."
  fi
  exit 0
fi

exit 0
