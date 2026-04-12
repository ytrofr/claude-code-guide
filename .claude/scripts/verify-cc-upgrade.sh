#!/bin/bash
# claude-code-guide verify — Jekyll build + stale version scan + rule baseline
set -euo pipefail

BLU=$'\033[34m'; GRN=$'\033[32m'; RED=$'\033[31m'; YLW=$'\033[33m'; NC=$'\033[0m'
info() { printf "${BLU}INFO${NC}: %s\n" "$*"; }
pass() { printf "${GRN}PASS${NC}: %s\n" "$*"; }
warn() { printf "${YLW}WARN${NC}: %s\n" "$*"; }
fail() { printf "${RED}FAIL${NC}: %s\n" "$*"; exit 2; }

cc_ver=$(claude --version 2>/dev/null | awk '{print $1}')
info "CC version: $cc_ver"

# Rule count (target: >= 3)
rules_dir="$(pwd)/.claude/rules"
if [ -d "$rules_dir" ]; then
  count=$(find "$rules_dir" -maxdepth 1 -name '*.md' | wc -l)
  info "Rules: $count"
  [ "$count" -ge 3 ] && pass "Rule baseline met ($count >= 3)" || fail "Only $count rules (<3)"
else
  fail "No .claude/rules/ directory"
fi

# Required files check
for f in LICENSE CITATION.cff README.md robots.txt; do
  [ -f "$f" ] && pass "$f exists" || warn "$f missing"
done

# Stale CC version refs (advisory)
stale=$(grep -rn "2\.1\.[0-8][0-9]\b" docs/guide/ --include="*.md" 2>/dev/null | grep -v "^.*:.*|" | wc -l)
if [ "$stale" -gt 0 ]; then
  warn "$stale potentially stale CC version references outside tables (grep for '2.1.[0-8][0-9]' in prose)"
else
  pass "No stale CC version references in prose"
fi

# Jekyll build check (advisory — Docker fallback)
if command -v bundle &>/dev/null; then
  info "Running: bundle exec jekyll build"
  if bundle exec jekyll build --destination /tmp/jekyll-guide-build 2>&1 | tail -3; then
    pass "Jekyll build succeeded"
  else
    fail "Jekyll build failed"
  fi
elif command -v docker &>/dev/null; then
  info "No bundle — trying Docker Jekyll build"
  if docker run --rm -v "$PWD:/srv/jekyll" jekyll/jekyll:4 jekyll build 2>&1 | tail -3; then
    pass "Docker Jekyll build succeeded"
  else
    warn "Docker Jekyll build failed — verify manually before pushing"
  fi
else
  warn "Neither bundle nor docker available — cannot verify Jekyll build"
fi

pass "claude-code-guide verify complete"
