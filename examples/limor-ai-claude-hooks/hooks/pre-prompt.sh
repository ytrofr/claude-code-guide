#!/bin/bash
# Pre-Prompt Hook: HYBRID VERSION
# Keeps original's synonym expansion (85% accuracy) + adds caching (fast)
# Created: 2026-01-12
#
# APPROACH:
# 1. Use original's 70+ synonym patterns (PROVEN to work)
# 2. Cache skill metadata once (rebuild hourly)
# 3. Use bash built-ins instead of grep in tight loops

set -o pipefail

SKILLS_DIR="$HOME/.claude/skills"
SKILL_CACHE="$HOME/.claude/cache/skill-index-hybrid.txt"
CACHE_MAX_AGE=3600

# ═══════════════════════════════════════════════════════════════════
# UTILITY: Escape regex special characters
# ═══════════════════════════════════════════════════════════════════
escape_regex() {
    echo "$1" | sed 's/[][\ ^$.*+?{}()|]/\\&/g'
}

# ═══════════════════════════════════════════════════════════════════
# BUILD SKILL CACHE (Run once per hour)
# Format: skill-name|keyword1 keyword2 keyword3|description_words
# ═══════════════════════════════════════════════════════════════════
build_skill_cache() {
    mkdir -p "$(dirname "$SKILL_CACHE")"

    for skill_dir in "$SKILLS_DIR"/*-skill/; do
        [ -d "$skill_dir" ] || continue

        local skill_name=$(basename "$skill_dir")
        local skill_file="$skill_dir/SKILL.md"

        # Keywords from skill name (e.g., database-credentials-validation -> database credentials validation)
        local keywords=$(echo "$skill_name" | sed 's/-skill$//' | tr '-' ' ')

        # Extract description and "use when" keywords
        local desc_words=""
        if [ -f "$skill_file" ]; then
            # Get important words from description (4+ chars, lowercase)
            desc_words=$(head -20 "$skill_file" | grep -iE "description:|purpose:|use when" | \
                        tr '[:upper:]' '[:lower:]' | tr -cs 'a-z' ' ' | \
                        tr ' ' '\n' | awk 'length >= 4' | sort -u | tr '\n' ' ')
        fi

        echo "${skill_name}|${keywords}|${desc_words}"
    done > "$SKILL_CACHE"
}

ensure_skill_cache() {
    if [ ! -f "$SKILL_CACHE" ]; then
        build_skill_cache
        return
    fi
    local cache_age=$(($(date +%s) - $(stat -c %Y "$SKILL_CACHE" 2>/dev/null || echo 0)))
    if [ $cache_age -gt $CACHE_MAX_AGE ]; then
        build_skill_cache
    fi
}

# ═══════════════════════════════════════════════════════════════════
# SYNONYM EXPANSION (Ported from original - ALL 70+ patterns!)
# This is the KEY to 85% accuracy
# ═══════════════════════════════════════════════════════════════════
expand_message() {
    local msg="$1"
    local expanded="$msg"

    # GitHub operations
    [[ "$msg" =~ (^|[^a-z])pr($|[^a-z]) ]] && expanded="$expanded github pull request"
    [[ "$msg" == *"pull"*"request"* ]] && expanded="$expanded github pr"
    [[ "$msg" == *"issue"* ]] && expanded="$expanded github"
    [[ "$msg" == *"fork"* ]] && expanded="$expanded github repository"

    # Authentication
    [[ "$msg" == *"403"* ]] && expanded="$expanded oauth2 authentication beecom"
    [[ "$msg" == *"401"* ]] && expanded="$expanded authentication unauthorized"
    [[ "$msg" == *"auth"*"error"* ]] && expanded="$expanded authentication oauth2"

    # Database - CRITICAL patterns
    [[ "$msg" =~ (^|[^a-z])(db|database|postgres|postgresql|sql)($|[^a-z]) ]] && expanded="$expanded database"
    [[ "$msg" == *"econnrefused"* ]] && expanded="$expanded credentials database connection"
    [[ "$msg" == *"connection"*"refused"* ]] && expanded="$expanded database credentials"
    [[ "$msg" == *"connection"*"error"* ]] && expanded="$expanded database credentials troubleshooting"
    [[ "$msg" == *"database"*"error"* ]] && expanded="$expanded database troubleshooting credentials"

    # Gaps & Sync - CRITICAL
    [[ "$msg" == *"gap"* ]] && expanded="$expanded gap-detection sync parity"
    [[ "$msg" == *"missing"*"data"* ]] && expanded="$expanded gap sync parity api-first"
    [[ "$msg" == *"missing"* ]] && expanded="$expanded gap detection"

    # Deployment
    [[ "$msg" =~ (^|[^a-z])(deploy|deployment|deploying|release)($|[^a-z]) ]] && expanded="$expanded deployment"
    [[ "$msg" == *"staging"* ]] && expanded="$expanded deployment environment staging"
    [[ "$msg" == *"production"* ]] && expanded="$expanded deployment environment production"
    [[ "$msg" == *"traffic"* ]] && expanded="$expanded cloud-run traffic routing"
    [[ "$msg" == *"cloud"*"run"* ]] && expanded="$expanded cloud-run deployment traffic"

    # Testing - CRITICAL
    [[ "$msg" =~ (^|[^a-z])(test|testing|tests|spec)($|[^a-z]) ]] && expanded="$expanded testing"
    [[ "$msg" == *"jest"* ]] && expanded="$expanded testing unit"
    [[ "$msg" == *"playwright"* ]] && expanded="$expanded testing e2e visual"
    [[ "$msg" == *"baseline"* ]] && expanded="$expanded baseline testing methodology"
    [[ "$msg" == *"60q"* || "$msg" == *"comprehensive"*"test"* ]] && expanded="$expanded comprehensive testing baseline"

    # GitHub
    [[ "$msg" =~ (^|[^a-z])(git|github|repo|repository)($|[^a-z]) ]] && expanded="$expanded github"
    [[ "$msg" == *"conflict"* ]] && expanded="$expanded merge pr-merge validation"
    [[ "$msg" == *"merge"* ]] && expanded="$expanded pr-merge validation github"

    # Troubleshooting - CRITICAL
    [[ "$msg" =~ (troubleshoot|debug|error|problem|fail|bug) ]] && expanded="$expanded troubleshooting workflow"

    # Context optimization
    [[ "$msg" =~ (context|memory|optimi) ]] && expanded="$expanded context optimization"
    [[ "$msg" == *"token"* ]] && expanded="$expanded context optimization"

    # RAG/Embeddings
    [[ "$msg" =~ (^|[^a-z])(rag|retrieval|vector|embeddings?)($|[^a-z]) ]] && expanded="$expanded rag embeddings llm-application semantic vector"
    [[ "$msg" =~ (pgvector|hnsw|catalog.items) ]] && expanded="$expanded rag database ai"

    # Prompt engineering
    [[ "$msg" =~ (prompt.engineer|system.prompt|llm.prompt) ]] && expanded="$expanded prompt-engineering llm-application"

    # API design
    [[ "$msg" =~ (api.design|rest.api|graphql|openapi) ]] && expanded="$expanded api-design backend architecture"
    [[ "$msg" =~ (api.first|check.api|validate.api|api.source) ]] && expanded="$expanded api-first validation"
    [[ "$msg" == *"api"* ]] && expanded="$expanded api endpoint"

    # Tracing/Observability
    [[ "$msg" =~ (tracing|distributed.trace|opentelemetry|jaeger) ]] && expanded="$expanded distributed-tracing observability"
    [[ "$msg" =~ (grafana|prometheus|metrics|dashboard.monitor) ]] && expanded="$expanded grafana prometheus observability monitoring"

    # SQL optimization
    [[ "$msg" =~ (sql.optimi|query.optimi|index.optimi|explain.analyze) ]] && expanded="$expanded sql-optimization database postgresql"

    # Multi-word patterns
    [[ "$msg" == *"403"*"error"* ]] && expanded="$expanded oauth2 authentication beecom"
    [[ "$msg" == *"auth"*"fail"* ]] && expanded="$expanded authentication oauth2 beecom"
    [[ "$msg" == *"deploy"*"staging"* ]] && expanded="$expanded deployment environment staging"
    [[ "$msg" == *"deploy"*"production"* ]] && expanded="$expanded deployment environment production safety"
    [[ "$msg" == *"create"*"pr"* ]] && expanded="$expanded github pull-request merge"
    [[ "$msg" == *"merge"*"conflict"* ]] && expanded="$expanded pr-merge validation troubleshooting"

    # Phase 2 patterns
    [[ "$msg" =~ (^|[^a-z])(feedback|review|rating|thumbs)($|[^a-z]) ]] && expanded="$expanded feedback"
    [[ "$msg" =~ (^|[^a-z])(ai|llm|gemini|vertex|model)($|[^a-z]) ]] && expanded="$expanded ai llm"
    [[ "$msg" == *"ai"*"accuracy"* || "$msg" == *"ai"*"wrong"* || "$msg" == *"validate"*"ai"* ]] && expanded="$expanded ai quality validation"
    [[ "$msg" == *"ai"*"response"* || "$msg" == *"ai"*"data"* ]] && expanded="$expanded ai quality validation"
    [[ "$msg" =~ (^|[^a-z])(validate|validation|verify|check|confirm)($|[^a-z]) ]] && expanded="$expanded validation"
    [[ "$msg" =~ (^|[^a-z])(mcp|tool.server)($|[^a-z]) ]] && expanded="$expanded mcp"
    [[ "$msg" =~ (^|[^a-z])(sacred|golden.?rule|commandment|compliance)($|[^a-z]) ]] && expanded="$expanded sacred commandments"
    [[ "$msg" == *"golden"*"rule"* ]] && expanded="$expanded database patterns employee_id"
    [[ "$msg" =~ (^|[^a-z])(hebrew|עברית|rtl|israeli)($|[^a-z]) ]] && expanded="$expanded hebrew preservation encoding"
    [[ "$msg" =~ (^|[^a-z])(beecom|pos|orders?|products?|restaurant)($|[^a-z]) ]] && expanded="$expanded beecom"
    [[ "$msg" =~ (^|[^a-z])(shift|schedule|labor|employee.hours)($|[^a-z]) ]] && expanded="$expanded shift labor status"
    [[ "$msg" =~ (^|[^a-z])(revenue|sales|income)($|[^a-z]) ]] && expanded="$expanded revenue calculation"

    # Phase 3 patterns
    [[ "$msg" =~ (^|[^a-z])(session|workflow|start.session|end.session|checkpoint)($|[^a-z]) ]] && expanded="$expanded session workflow start protocol"
    [[ "$msg" =~ (^|[^a-z])(perplexity|research|search.online|web.search)($|[^a-z]) ]] && expanded="$expanded perplexity research memory"
    [[ "$msg" =~ (^|[^a-z])(blueprint|architecture|feature.context|how.does.*work)($|[^a-z]) ]] && expanded="$expanded blueprint architecture"
    [[ "$msg" =~ (^|[^a-z])(parity|environment.match|localhost.vs|staging.vs)($|[^a-z]) ]] && expanded="$expanded parity validation environment"
    [[ "$msg" =~ (^|[^a-z])(cache|caching|cached|ttl|invalidate)($|[^a-z]) ]] && expanded="$expanded cache optimization"

    # Phase 4 patterns
    [[ "$msg" =~ (^|[^a-z])(whatsapp|messaging|chat.bot|webhook)($|[^a-z]) ]] && expanded="$expanded whatsapp monitoring"
    [[ "$msg" =~ (^|[^a-z])(sync|syncing|migration|migrate|backfill)($|[^a-z]) ]] && expanded="$expanded sync migration database"
    [[ "$msg" =~ (^|[^a-z])(semantic|query.router|tier|embedding)($|[^a-z]) ]] && expanded="$expanded semantic query router"
    [[ "$msg" =~ (^|[^a-z])(visual|screenshot|regression|baseline|ui.test)($|[^a-z]) ]] && expanded="$expanded visual regression testing"

    # Response time / performance
    [[ "$msg" == *"slow"* || "$msg" == *"latency"* ]] && expanded="$expanded response time optimization performance"
    [[ "$msg" == *"response"*"time"* ]] && expanded="$expanded response time optimization"

    # Skills
    [[ "$msg" =~ (^|[^a-z])(skill|create.skill|add.skill|update.skill|retrospective)($|[^a-z]) ]] && expanded="$expanded skill maintenance creation"

    # MCP / PostgreSQL
    [[ "$msg" == *"postgresql"* || "$msg" == *"postgres"*"mcp"* ]] && expanded="$expanded postgresql mcp database"
    [[ "$msg" == *"query"*"database"* ]] && expanded="$expanded postgresql mcp database sql"

    echo "$expanded"
}

# ═══════════════════════════════════════════════════════════════════
# FAST SKILL MATCHING (Uses cache + bash built-ins)
# Scoring: +10 first keyword, +5 each additional, +3 desc, +5 branch
# ═══════════════════════════════════════════════════════════════════
match_skills_hybrid() {
    local expanded_msg="$1"
    local branch_priority="$2"
    local original_msg="$3"  # NEW: Pass original message for bonus

    ensure_skill_cache

    local matched=""

    while IFS='|' read -r skill_name keywords desc_words; do
        [ -z "$skill_name" ] && continue

        local score=0
        local keyword_matches=0

        # Check EACH keyword (don't break after first!)
        for kw in $keywords; do
            [ ${#kw} -lt 3 ] && continue
            if [[ "$expanded_msg" == *"$kw"* ]]; then
                if [ $keyword_matches -eq 0 ]; then
                    score=$((score + 10))  # First match: +10
                else
                    score=$((score + 5))   # Additional matches: +5 each
                fi
                keyword_matches=$((keyword_matches + 1))

                # BONUS: If keyword in ORIGINAL message (not just expanded), +3
                if [ -n "$original_msg" ] && [[ "$original_msg" == *"$kw"* ]]; then
                    score=$((score + 3))
                fi
            fi
        done

        # Description matching (if low score)
        if [ $score -lt 10 ] && [ -n "$desc_words" ]; then
            for dw in $desc_words; do
                [ ${#dw} -lt 4 ] && continue
                if [[ "$expanded_msg" == *"$dw"* ]]; then
                    score=$((score + 3))
                    break
                fi
            done
        fi

        # Branch priority boost
        if [ $score -gt 0 ] && [ -n "$branch_priority" ] && [[ ",$branch_priority," == *",$skill_name,"* ]]; then
            score=$((score + 5))
        fi

        # Threshold
        if [ $score -ge 3 ]; then
            matched="${matched}${score}:${skill_name}\n"
        fi
    done < "$SKILL_CACHE"

    # Sort and return top 10
    echo -e "$matched" | sort -t: -k1 -rn | head -10 | cut -d: -f2 | tr '\n' ',' | sed 's/,$//'
}

# ═══════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════

JSON_INPUT=$(timeout 2 cat)
USER_MESSAGE=$(echo "$JSON_INPUT" | jq -r '.prompt // empty' 2>/dev/null)
[ -z "$USER_MESSAGE" ] && USER_MESSAGE="$JSON_INPUT"

# SKIP: Task notifications
if [[ "$USER_MESSAGE" == *"<task-notification>"* ]]; then
    echo "$USER_MESSAGE"
    exit 0
fi

# SKIP: Simple words
if [[ "$USER_MESSAGE" =~ ^(continue|yes|no|ok|okay|thanks|sure|done|stop|got\ it)$ ]]; then
    echo "$USER_MESSAGE"
    exit 0
fi

# Process message
USER_MESSAGE_LOWER=$(echo "$USER_MESSAGE" | tr '[:upper:]' '[:lower:]')

# Expand synonyms (THE KEY TO ACCURACY!)
EXPANDED_MSG=$(expand_message "$USER_MESSAGE_LOWER")

# Get branch info
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
BRANCH_VARS="memory-bank/always/branch-variables.json"
BRANCH_PRIORITY=""
[ -f "$BRANCH_VARS" ] && BRANCH_PRIORITY=$(jq -r ".[\"$CURRENT_BRANCH\"].skills_required // [] | .[]" "$BRANCH_VARS" 2>/dev/null | tr '\n' ',' | sed 's/,$//')

# Match skills (pass original message for bonus scoring)
MATCHED_SKILLS=$(match_skills_hybrid "$EXPANDED_MSG" "$BRANCH_PRIORITY" "$USER_MESSAGE_LOWER")

# Format output with ✅ prefix
SKILLS_DISPLAY=""
if [ -n "$MATCHED_SKILLS" ]; then
    for skill in $(echo "$MATCHED_SKILLS" | tr ',' '\n'); do
        [ -z "$skill" ] && continue
        skill_file="$SKILLS_DIR/${skill}/SKILL.md"
        if [ -f "$skill_file" ]; then
            desc=$(head -10 "$skill_file" | grep -iE "description:|purpose:" | head -1 | sed 's/.*: *//' | tr -d '"' | cut -c1-100)
            SKILLS_DISPLAY="${SKILLS_DISPLAY}  ✅ ${skill} - ${desc}\n"
        else
            SKILLS_DISPLAY="${SKILLS_DISPLAY}  ✅ ${skill}\n"
        fi
    done
else
    SKILLS_DISPLAY="  ⚠️ No skills matched\n"
fi

# Warnings
WARNINGS=""
[[ "$USER_MESSAGE" == *deploy* ]] && WARNINGS+="🚀 DEPLOYMENT: Use deployment-workflow-skill\n"
[[ "$USER_MESSAGE" == *test* ]] && WARNINGS+="🧪 TESTING: Use testing-workflow-skill\n"
[[ "$USER_MESSAGE" == *implement* || "$USER_MESSAGE" == *create* || "$USER_MESSAGE" == *build* ]] && WARNINGS+="🔍 CHECK EXISTING: Use Explore agent first\n"

# Load branch context (truncated)
BRANCH_FILE="CURRENT/${CURRENT_BRANCH}/${CURRENT_BRANCH}-Instructions.md"
BRANCH_CONTEXT=""
[ -f "$BRANCH_FILE" ] && BRANCH_CONTEXT=$(head -40 "$BRANCH_FILE")

# Output
cat <<EOF
🚨 SKILL EVALUATION (Hybrid - Fast + Accurate)
$([ -n "$WARNINGS" ] && echo -e "$WARNINGS")
═══════════════════════════════════════════════════════════════════
MATCHED SKILLS:
$(echo -e "$SKILLS_DISPLAY")
🚨 FORMAT: "I'll use [skill-name]..." then Skill(skill: "[name]")
═══════════════════════════════════════════════════════════════════

📋 BRANCH: $CURRENT_BRANCH
$([ -n "$BRANCH_CONTEXT" ] && echo "$BRANCH_CONTEXT" | head -25)

User message:
$USER_MESSAGE
EOF
