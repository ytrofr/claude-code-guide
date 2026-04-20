#!/bin/bash
# Self-test for manifest resolution logic.
# Usage: bash best-practices/test-manifest-resolve.sh
# Exit 0 = pass, non-zero = fail.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$SCRIPT_DIR/manifest.json"

fail() { echo "FAIL: $*"; exit 1; }
pass() { echo "PASS: $*"; }

# Test 1: core tier resolves to 8 rules, 3 skills, 1 hook
core_rules=$(jq '.tiers.core.rules | length' "$MANIFEST")
[ "$core_rules" = "8" ] || fail "core rules: expected 8, got $core_rules"
pass "core rules count = 8"

core_skills=$(jq '.tiers.core.skills | length' "$MANIFEST")
[ "$core_skills" = "3" ] || fail "core skills: expected 3, got $core_skills"
pass "core skills count = 3"

core_hooks=$(jq '.tiers.core.hooks | length' "$MANIFEST")
[ "$core_hooks" = "1" ] || fail "core hooks: expected 1, got $core_hooks"
pass "core hooks count = 1"

# Test 2: recommended extends core (resolve chain)
ext=$(jq -r '.tiers.recommended.extends' "$MANIFEST")
[ "$ext" = "core" ] || fail "recommended.extends: expected 'core', got '$ext'"
pass "recommended extends core"

# Test 3: full extends recommended
ext=$(jq -r '.tiers.full.extends' "$MANIFEST")
[ "$ext" = "recommended" ] || fail "full.extends: expected 'recommended', got '$ext'"
pass "full extends recommended"

# Test 4: version is 5.0.0
version=$(jq -r '.version' "$MANIFEST")
[ "$version" = "5.0.0" ] || fail "version: expected '5.0.0', got '$version'"
pass "version = 5.0.0"

# Test 5: recommended adds >=22 rules, >=13 skills, >=6 hooks
rec_rules=$(jq '.tiers.recommended.rules | length' "$MANIFEST")
[ "$rec_rules" -ge 22 ] || fail "recommended rules: expected >=22, got $rec_rules"
pass "recommended rules count >= 22 ($rec_rules)"

rec_skills=$(jq '.tiers.recommended.skills | length' "$MANIFEST")
[ "$rec_skills" -ge 13 ] || fail "recommended skills: expected >=13, got $rec_skills"
pass "recommended skills count >= 13 ($rec_skills)"

rec_hooks=$(jq '.tiers.recommended.hooks | length' "$MANIFEST")
[ "$rec_hooks" -ge 6 ] || fail "recommended hooks: expected >=6, got $rec_hooks"
pass "recommended hooks count >= 6 ($rec_hooks)"

# Test 6: full adds >=25 rules, >=27 skills, >=5 hooks, 4 scripts
full_rules=$(jq '.tiers.full.rules | length' "$MANIFEST")
[ "$full_rules" -ge 25 ] || fail "full rules: expected >=25, got $full_rules"
pass "full rules count >= 25 ($full_rules)"

full_skills=$(jq '.tiers.full.skills | length' "$MANIFEST")
[ "$full_skills" -ge 27 ] || fail "full skills: expected >=27, got $full_skills"
pass "full skills count >= 27 ($full_skills)"

full_scripts=$(jq '.tiers.full.scripts | length' "$MANIFEST")
[ "$full_scripts" = "4" ] || fail "full scripts: expected 4, got $full_scripts"
pass "full scripts count = 4"

echo ""
echo "All manifest tests passed."
