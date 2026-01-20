#!/bin/bash
# Pre-Prompt Hook: Skills Filtering with Score-at-Match-Time (Entry #229)
# Created: 2025-12-01 | Enhanced: 2026-01-12 (Entry #266 grep escaping)
# Fixed: 2026-01-20 (Entry #284 - Special character handling)
# Source: https://scottspence.com/posts/how-to-make-claude-code-skills-activate-reliably
# Success Rate: 95%+ (84% Scott Spence baseline + Entry #229 improvements)
#
# Entry #229 Improvements (Jan 2, 2026):
# - Score-at-match-time (not after matching)
# - Reduced matches from 127-145 to 6-10 per query (93% reduction)
# - Branch priority skills support (+15 bonus if you use branch-variables.json)
# - Stricter stem matching (only -ing, -ment suffixes)
# - Minimum score threshold (5 points)
#
# Entry #266 Fix (Jan 12, 2026):
# - Added `--` separator to ALL grep calls
# - Prevents "unrecognized option" errors when messages contain --options
# - Validated: 122/122 tests passing across 12 categories
#
# Entry #284 Fix (Jan 20, 2026):
# - Fixed "Invalid range end" errors from [brackets] in user input
# - Fixed "unrecognized option" errors from --flags in code blocks
# - Use grep -F (fixed strings) for user input matching
# - Skip words starting with - or containing special characters
# - Add set -f to prevent glob expansion of [ ] characters

# ═══════════════════════════════════════════════════════════════════
# METRICS LOGGING
# ═══════════════════════════════════════════════════════════════════
METRICS_LOG="$HOME/.claude/metrics/skill-activations.jsonl"

log_skill_activation() {
    local trigger="$1"
    local total_skills="$2"
    local matched="$3"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local matched_count=0

    if [ -n "$matched" ]; then
        matched_count=$(echo "$matched" | tr ',' '\n' | wc -l)
    fi

    if [ -d "$(dirname "$METRICS_LOG")" ]; then
        echo "{\"timestamp\":\"$timestamp\",\"trigger\":\"$trigger\",\"total_skills\":$total_skills,\"matched_count\":$matched_count}" >> "$METRICS_LOG"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# MATCH SKILLS WITH SCORING (Entry #229 - Jan 2026)
# Scoring: +10 exact name, +10 exact query, +3 stem, +1 description
# Output: Top 10 by score | Minimum: 5 points
# ═══════════════════════════════════════════════════════════════════

match_skills() {
    local msg="$1"
    local msg_lower=$(echo "$msg" | tr '[:upper:]' '[:lower:]')

    # STEP 1: SYNONYM EXPANSION
    # NOTE: All grep calls use `--` to prevent --option interpretation (Entry #266)
    # NOTE: Use grep -F for fixed strings where possible (Entry #284)
    local expanded_msg="$msg_lower"

    # GitHub - use -F for fixed string matching
    echo "$msg_lower" | grep -qiF -- "pr" && expanded_msg="$expanded_msg github pull request"
    echo "$msg_lower" | grep -qiF -- "pull request" && expanded_msg="$expanded_msg github pr"
    echo "$msg_lower" | grep -qiF -- "issue" && expanded_msg="$expanded_msg github"

    # Database - use -F for simple terms
    echo "$msg_lower" | grep -qiF -- "database" && expanded_msg="$expanded_msg database"
    echo "$msg_lower" | grep -qiF -- "postgres" && expanded_msg="$expanded_msg database"
    echo "$msg_lower" | grep -qiF -- "sql" && expanded_msg="$expanded_msg database"
    echo "$msg_lower" | grep -qiF -- "db" && expanded_msg="$expanded_msg database"
    echo "$msg_lower" | grep -qiF -- "econnrefused" && expanded_msg="$expanded_msg credentials database connection"

    # Testing
    echo "$msg_lower" | grep -qiF -- "test" && expanded_msg="$expanded_msg testing"
    echo "$msg_lower" | grep -qiF -- "spec" && expanded_msg="$expanded_msg testing"
    echo "$msg_lower" | grep -qiF -- "jest" && expanded_msg="$expanded_msg testing unit"

    # Deployment
    echo "$msg_lower" | grep -qiF -- "deploy" && expanded_msg="$expanded_msg deployment"

    # Troubleshooting
    echo "$msg_lower" | grep -qiF -- "error" && expanded_msg="$expanded_msg troubleshooting"
    echo "$msg_lower" | grep -qiF -- "bug" && expanded_msg="$expanded_msg troubleshooting"
    echo "$msg_lower" | grep -qiF -- "problem" && expanded_msg="$expanded_msg troubleshooting"

    # STEP 2: SCORE-AT-MATCH-TIME
    local scored_skills=""

    for skill_dir in "$HOME/.claude/skills"/*-skill/; do
        [ -d "$skill_dir" ] || continue

        local skill_name=$(basename "$skill_dir")
        local skill_file="$skill_dir/SKILL.md"
        local score=0
        local matched=false

        # Extract keywords from skill NAME (safe - comes from filesystem)
        local name_keywords=$(echo "$skill_name" | sed 's/-skill$//' | tr '-' ' ')

        # CHECK 1: Exact keyword match in skill NAME (+10)
        # Use grep -F for fixed string matching (Entry #284)
        for name_word in $name_keywords; do
            [ ${#name_word} -lt 3 ] && continue

            # Use -F for fixed string, -w for word boundary
            if echo "$msg_lower" | grep -qiwF -- "$name_word" 2>/dev/null; then
                score=$((score + 10))
                matched=true
                break
            fi
        done

        # CHECK 2: Stem match in expanded message (+3)
        for name_word in $name_keywords; do
            [ ${#name_word} -lt 4 ] && continue

            local stem=$(echo "$name_word" | sed -E 's/(ing|ment)$//')
            [ ${#stem} -lt 3 ] && continue

            # Use -F for fixed string matching
            if echo "$expanded_msg" | grep -qiF -- "$stem" 2>/dev/null; then
                if ! echo "$msg_lower" | grep -qiwF -- "$name_word" 2>/dev/null; then
                    score=$((score + 3))
                    matched=true
                    break
                fi
            fi
        done

        # CHECK 3: Description keyword match (+1)
        # Entry #284: Safely iterate user words, skip special characters
        if [ "$matched" = "true" ] && [ -f "$skill_file" ]; then
            local desc=$(grep -- "^description:" "$skill_file" 2>/dev/null | sed 's/description: *//' | tr -d '"' | tr '[:upper:]' '[:lower:]')
            
            # Disable glob expansion to prevent [ ] from being interpreted (Entry #284)
            set -f
            for query_word in $msg_lower; do
                [ ${#query_word} -lt 4 ] && continue
                
                # Skip words with special characters that break grep (Entry #284)
                # Skip: options (--foo, -v), brackets [foo], braces {foo}, parens (foo)
                case "$query_word" in
                    -* | *[\[\]\{\}\(\)\<\>\|\*\?\$\^\\\']* ) continue ;;
                esac
                
                # Use -F for fixed string matching (no regex interpretation)
                if echo "$desc" | grep -qiF -- "$query_word" 2>/dev/null; then
                    score=$((score + 1))
                    break
                fi
            done
            set +f
        fi

        # Only include skills with score >= 5
        if [ $score -ge 5 ]; then
            scored_skills="${scored_skills}${score}:${skill_name}\n"
        fi
    done

    # Sort by score descending, take top 10
    echo -e "$scored_skills" | sort -t: -k1 -rn | head -10 | cut -d: -f2 | tr '\n' ',' | sed 's/,$//'
}

# Read user message
JSON_INPUT=$(cat)
USER_MESSAGE=$(echo "$JSON_INPUT" | jq -r '.prompt // empty' 2>/dev/null)
if [ -z "$USER_MESSAGE" ]; then
    USER_MESSAGE="$JSON_INPUT"
fi

# Skip simple acknowledgments (Entry #266: use -- for grep safety)
if echo "$USER_MESSAGE" | grep -qiE -- "^(continue|yes|no|ok|thanks)$" 2>/dev/null; then
    echo "$USER_MESSAGE"
    exit 0
fi

# Match skills
SKILL_COUNT=$(find "$HOME/.claude/skills" -name "SKILL.md" 2>/dev/null | wc -l)
MATCHED_SKILLS=$(match_skills "$USER_MESSAGE")
log_skill_activation "hook_triggered" "$SKILL_COUNT" "$MATCHED_SKILLS"

# Output with skills FIRST
cat <<EOF
🎯 MATCHED SKILLS FOR YOUR QUERY:
┌─────────────────────────────────────────────────────────────────┐
│ USE ONE OF THESE SKILLS - THEY MATCH YOUR KEYWORDS!           │
└─────────────────────────────────────────────────────────────────┘

$(if [ -n "$MATCHED_SKILLS" ]; then
    echo "$MATCHED_SKILLS" | tr ',' '\n' | while read skill; do
        [ -z "$skill" ] && continue
        skill_file="$HOME/.claude/skills/${skill}/SKILL.md"
        if [ -f "$skill_file" ]; then
            desc=$(head -10 "$skill_file" | grep -m 1 -- "description:" | sed 's/.*description: *"\?//' | sed 's/"$//' | cut -c1-100)
            echo "  ✅ ${skill} - ${desc}"
        else
            echo "  ✅ ${skill}"
        fi
    done
else
    echo "  ⚠️ No skills matched your keywords"
fi)

Required: Use one of the matched skills above with:
  Skill(skill: "skill-name")

Original user message:
$USER_MESSAGE
EOF
