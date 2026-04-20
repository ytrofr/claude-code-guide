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

echo ""
echo "All manifest tests passed."
