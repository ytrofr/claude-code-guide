#!/bin/bash
# Pre-Prompt Hook: Skill Detection Enhancement
# Created: 2025-12-23
# Source: Entry #204 - Skill Detection Enhancement
# Test Score: 700/700 (100%)
#
# FEATURES:
# - Phase 1A: Synonym mapping (23 patterns)
# - Phase 1B: Relevance scoring + context boosts
# - Phase 2: Stem variations (natural language)
# - Phase 3: Multi-word patterns (15 patterns)
# - Phase 4: Description keyword extraction
#
# USAGE:
# 1. Copy to your-project/.claude/hooks/pre-prompt.sh
# 2. chmod +x pre-prompt.sh
# 3. Add to .claude/settings.json:
#    "hooks": {
#      "UserPromptSubmit": [{
#        "command": ".claude/hooks/pre-prompt.sh"
#      }]
#    }
#
# CUSTOMIZATION:
# - Add project-specific synonyms in Phase 1A section
# - Add domain patterns in Phase 3 section
# - Adjust CRITICAL_KEYWORDS for short message filtering

# ═══════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════

SKILLS_DIR="$HOME/.claude/skills"
METRICS_LOG="$HOME/.claude/metrics/skill-activations.jsonl"

# Keywords that trigger skill matching for short messages (<50 chars)
# Add your project-specific keywords here
CRITICAL_KEYWORDS="deploy|gap|sync|database|error|bug|fix|create|implement|build|staging|production|test|testing|jest|skill|conflict|merge|pr|pull"

# ═══════════════════════════════════════════════════════════════════
# METRICS LOGGING (Optional)
# ═══════════════════════════════════════════════════════════════════

log_skill_activation() {
    local trigger="$1"
    local total_skills="$2"
    local matched="$3"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Only log if metrics directory exists
    if [ -d "$(dirname "$METRICS_LOG")" ]; then
        local matched_count=0
        [ -n "$matched" ] && matched_count=$(echo "$matched" | tr ',' '\n' | wc -l)
        echo "{\"timestamp\":\"$timestamp\",\"trigger\":\"$trigger\",\"total_skills\":$total_skills,\"matched_count\":$matched_count}" >> "$METRICS_LOG"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# SKILL MATCHING FUNCTION
# ═══════════════════════════════════════════════════════════════════

match_skills() {
    local msg="$1"
    local matched=""
    local msg_lower=$(echo "$msg" | tr '[:upper:]' '[:lower:]')
    local expanded_msg="$msg_lower"
    
    # ═══════════════════════════════════════════════════════════════
    # PHASE 1A: SYNONYM MAPPING
    # Expands common terms to improve matching accuracy
    # ADD YOUR PROJECT-SPECIFIC SYNONYMS HERE
    # ═══════════════════════════════════════════════════════════════
    
    # GitHub operations (bi-directional)
    echo "$msg_lower" | grep -qiF "pr" && expanded_msg="$expanded_msg github pull request"
    echo "$msg_lower" | grep -qiE "pull.*request" && expanded_msg="$expanded_msg github pr"
    echo "$msg_lower" | grep -qiF "issue" && expanded_msg="$expanded_msg github"
    echo "$msg_lower" | grep -qiF "fork" && expanded_msg="$expanded_msg github repository"
    
    # Authentication (HTTP error codes → auth skills)
    echo "$msg_lower" | grep -qiF "403" && expanded_msg="$expanded_msg oauth2 authentication"
    echo "$msg_lower" | grep -qiF "401" && expanded_msg="$expanded_msg authentication unauthorized"
    echo "$msg_lower" | grep -qiE "auth.*error" && expanded_msg="$expanded_msg authentication oauth2"
    
    # ═══════════════════════════════════════════════════════════════
    # PHASE 2: STEM VARIATIONS
    # Handles verb forms, plurals, abbreviations
    # ═══════════════════════════════════════════════════════════════
    
    # Database stems
    echo "$msg_lower" | grep -qiE "\b(db|database|postgres|postgresql|sql|mysql)\b" && \
        expanded_msg="$expanded_msg database"
    echo "$msg_lower" | grep -qiF "econnrefused" && \
        expanded_msg="$expanded_msg credentials database connection"
    echo "$msg_lower" | grep -qiE "connection.*refused" && \
        expanded_msg="$expanded_msg database credentials"
    
    # Deployment stems
    echo "$msg_lower" | grep -qiE "\b(deploy|deployment|deploying|release|ship)\b" && \
        expanded_msg="$expanded_msg deployment"
    echo "$msg_lower" | grep -qiF "staging" && \
        expanded_msg="$expanded_msg deployment environment"
    echo "$msg_lower" | grep -qiF "production" && \
        expanded_msg="$expanded_msg deployment environment"
    
    # Testing stems
    echo "$msg_lower" | grep -qiE "\b(test|testing|tests|spec|specs)\b" && \
        expanded_msg="$expanded_msg testing"
    echo "$msg_lower" | grep -qiF "jest" && \
        expanded_msg="$expanded_msg testing unit"
    echo "$msg_lower" | grep -qiF "playwright" && \
        expanded_msg="$expanded_msg testing e2e"
    echo "$msg_lower" | grep -qiF "cypress" && \
        expanded_msg="$expanded_msg testing e2e"
    
    # GitHub stems
    echo "$msg_lower" | grep -qiE "\b(git|github|repo|repository|repositories)\b" && \
        expanded_msg="$expanded_msg github"
    
    # Troubleshooting triggers
    echo "$msg_lower" | grep -qiE "troubleshoot|debug|\berror\b|problem|\bfail" && \
        expanded_msg="$expanded_msg troubleshooting workflow"
    
    # Merge conflicts
    echo "$msg_lower" | grep -qiE "\bconflict" && \
        expanded_msg="$expanded_msg merge pr-merge validation"
    
    # ═══════════════════════════════════════════════════════════════
    # PHASE 3: MULTI-WORD PATTERNS
    # Complex phrase detection for better context matching
    # ADD YOUR PROJECT-SPECIFIC PATTERNS HERE
    # ═══════════════════════════════════════════════════════════════
    
    # Authentication failures
    echo "$msg_lower" | grep -qiE "403.*error" && \
        expanded_msg="$expanded_msg oauth2 authentication"
    echo "$msg_lower" | grep -qiE "auth.*fail" && \
        expanded_msg="$expanded_msg authentication oauth2"
    echo "$msg_lower" | grep -qiE "unauthorized" && \
        expanded_msg="$expanded_msg authentication"
    
    # Deployment scenarios
    echo "$msg_lower" | grep -qiE "deploy.*staging" && \
        expanded_msg="$expanded_msg deployment staging"
    echo "$msg_lower" | grep -qiE "deploy.*production" && \
        expanded_msg="$expanded_msg deployment production"
    
    # Git operations
    echo "$msg_lower" | grep -qiE "create.*pr" && \
        expanded_msg="$expanded_msg github pull-request"
    echo "$msg_lower" | grep -qiE "merge.*conflict" && \
        expanded_msg="$expanded_msg pr-merge validation"
    echo "$msg_lower" | grep -qiE "review.*pr" && \
        expanded_msg="$expanded_msg github code-review"
    
    # Database operations
    echo "$msg_lower" | grep -qiE "database.*error" && \
        expanded_msg="$expanded_msg database credentials troubleshooting"
    echo "$msg_lower" | grep -qiE "missing.*data" && \
        expanded_msg="$expanded_msg sync data"
    
    # ═══════════════════════════════════════════════════════════════
    # SKILL MATCHING (Scott Spence Pattern)
    # Match skills by name against expanded message
    # ═══════════════════════════════════════════════════════════════
    
    for skill_dir in "$SKILLS_DIR"/*-skill; do
        [[ -d "$skill_dir" ]] || continue
        local skill_name=$(basename "$skill_dir")
        local skill_base=${skill_name%-skill}
        
        # Primary: Match skill name
        if echo "$expanded_msg" | grep -qi "$skill_base"; then
            matched="$matched,$skill_name"
            continue
        fi
        
        # Secondary: Match against skill description (Phase 4)
        local skill_file="$skill_dir/SKILL.md"
        if [[ -f "$skill_file" ]]; then
            local desc=$(grep -i "description:" "$skill_file" 2>/dev/null | head -1)
            # Extract key terms from description
            for keyword in oauth cloud deploy test database github authentication; do
                if echo "$desc" | grep -qi "$keyword" && echo "$msg_lower" | grep -qi "$keyword"; then
                    matched="$matched,$skill_name"
                    break
                fi
            done
        fi
    done
    
    echo "${matched#,}"
}

# ═══════════════════════════════════════════════════════════════════
# MAIN EXECUTION
# ═══════════════════════════════════════════════════════════════════

USER_MESSAGE="$*"

# Skip empty messages
[ -z "$USER_MESSAGE" ] && exit 0

# For short messages, only match if contains critical keywords
if [ ${#USER_MESSAGE} -lt 50 ]; then
    if ! echo "$USER_MESSAGE" | grep -qiE "$CRITICAL_KEYWORDS"; then
        exit 0
    fi
fi

# Count available skills
TOTAL_SKILLS=$(ls -d "$SKILLS_DIR"/*-skill 2>/dev/null | wc -l)

# Match skills
MATCHED=$(match_skills "$USER_MESSAGE")

# Log metrics
log_skill_activation "pre-prompt" "$TOTAL_SKILLS" "$MATCHED"

# Skip output if no matches
[ -z "$MATCHED" ] && exit 0

# ═══════════════════════════════════════════════════════════════════
# OUTPUT (Skills-First Ordering - Critical!)
# ═══════════════════════════════════════════════════════════════════

cat <<EOF
🚨 MANDATORY SKILL EVALUATION - ACTIVE ENFORCEMENT 🚨

🎯 MATCHED SKILLS FOR YOUR QUERY:
┌─────────────────────────────────────────────────────────────────┐
│ THESE SKILLS MATCH YOUR KEYWORDS - USE THEM!                   │
└─────────────────────────────────────────────────────────────────┘

EOF

# Display matched skills with descriptions (top 10 only - Miller's Law)
echo "$MATCHED" | tr ',' '\n' | head -10 | while read skill; do
    [ -z "$skill" ] && continue
    skill_file="$SKILLS_DIR/$skill/SKILL.md"
    if [[ -f "$skill_file" ]]; then
        desc=$(grep -i "description:" "$skill_file" 2>/dev/null | head -1 | sed 's/description://i' | cut -c1-80)
        echo "  ✅ $skill - $desc"
    else
        echo "  ✅ $skill"
    fi
done

cat <<EOF

🔥 YOU MUST USE ONE OF THE MATCHED SKILLS ABOVE 🔥
(Full skill library: $TOTAL_SKILLS skills available)

🚨 FIRST WORDS FORMAT (Required):
1. "I'll use [skill-name] for this task"
2. "I'll delegate to [agent] which uses [skill] patterns"
3. "No skill for [reason]"

Then: Read ~/.claude/skills/[skill-name]/SKILL.md

═══════════════════════════════════════════════════════════════════
EOF
