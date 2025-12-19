#!/bin/bash
# Pre-Prompt Hook: Force Skill Evaluation Before Every Response
# Created: 2025-12-01
# Source: https://scottspence.com/posts/how-to-make-claude-code-skills-activate-reliably
# Success Rate: 84% (vs 20% passive approach)
#
# HOW IT WORKS:
# 1. User sends message to Claude Code
# 2. This hook intercepts BEFORE Claude processes it
# 3. Injects forced evaluation prompt with ALL available skills
# 4. Claude MUST evaluate each skill with YES/NO + reasoning
# 5. Claude MUST commit to using matched skills
# 6. THEN Claude responds to user request WITH skills activated
#
# ENFORCEMENT: Makes skill usage ACTIVE instead of passive documentation

# ═══════════════════════════════════════════════════════════════════
# METRICS LOGGING (NEW - Dec 11, 2025 - Context Engineering)
# ═══════════════════════════════════════════════════════════════════
METRICS_LOG="$HOME/.claude/metrics/skill-activations.jsonl"

log_skill_activation() {
    local trigger="$1"
    local skills_matched="$2"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Only log if metrics file directory exists
    if [ -d "$(dirname "$METRICS_LOG")" ]; then
        echo "{\"timestamp\":\"$timestamp\",\"trigger\":\"$trigger\",\"skills_matched\":\"$skills_matched\",\"user_message_length\":${#USER_MESSAGE}}" >> "$METRICS_LOG"
    fi
}

# Read JSON input from stdin and extract prompt field
JSON_INPUT=$(cat)
USER_MESSAGE=$(echo "$JSON_INPUT" | jq -r '.prompt // empty')

# If jq fails or prompt is empty, try parsing as plain text
if [ -z "$USER_MESSAGE" ]; then
    USER_MESSAGE="$JSON_INPUT"
fi

# Skip skill evaluation for simple continuation/acknowledgment words
# These don't need skill activation
SIMPLE_WORDS="^(continue|yes|no|ok|okay|thanks|thank you|sure|got it|understood|correct|right|yep|nope|done|finished|stop|cancel|wait|hold|pause)$"

if echo "$USER_MESSAGE" | grep -qiE "$SIMPLE_WORDS"; then
    # Just pass through without evaluation
    echo "$USER_MESSAGE"
    exit 0
fi

# Skip for short messages (< 50 chars) that don't contain critical keywords
# Critical keywords that should ALWAYS trigger skill evaluation
CRITICAL_KEYWORDS="deploy|gap|sync|database|revenue|parity|duplicate|error|bug|fix|create|implement|build|staging|production|test|testing|jest|playwright|e2e|unit test|skill"

if [ ${#USER_MESSAGE} -lt 50 ]; then
    if ! echo "$USER_MESSAGE" | grep -qiE "$CRITICAL_KEYWORDS"; then
        echo "$USER_MESSAGE"
        exit 0
    fi
fi

# Get list of available skills
SKILLS_DIR="$HOME/.claude/skills"

# Extract skill names and descriptions
SKILL_LIST=""
if [ -d "$SKILLS_DIR" ]; then
    # Find all skill directories (official Claude Code format: skill-name/SKILL.md)
    for skill_dir in "$SKILLS_DIR"/*-skill/; do
        skill_file="$skill_dir/SKILL.md"
        if [ -f "$skill_file" ]; then
            skill_name=$(basename "$skill_dir" | sed 's/-skill$//')
            # Get Purpose line from skill file header
            description=$(head -10 "$skill_file" | grep -m 1 "Purpose:" | sed 's/.*Purpose.*: //')
            if [ -z "$description" ]; then
                # Fallback: get first scenario from trigger list
                description=$(grep -A 1 "^(1)" "$skill_file" | tail -1 | sed 's/^(1) //' | cut -c1-80)
            fi
            if [ -z "$description" ]; then
                # Last fallback: just use skill name
                description="[See skill file for details]"
            fi
            SKILL_LIST="${SKILL_LIST}\n- ${skill_name}-skill: ${description}"
        fi
    done
fi

# Check for implementation keywords to add context-first warning
IMPL_KEYWORDS="implement|create|build|add|write|make|new feature|refactor"
CONTEXT_WARNING=""
if echo "$USER_MESSAGE" | grep -qiE "$IMPL_KEYWORDS"; then
    CONTEXT_WARNING="
🔍 IMPLEMENTATION DETECTED - CHECK EXISTING CODE FIRST!
├─► Use Task tool with subagent_type='Explore' to search codebase
├─► Check memory-bank/learned/ for existing patterns
├─► Check UNIVERSAL-SYSTEM-MASTER.md for existing systems
├─► grep -r 'keyword' src/ to find existing code
⚠️ NEVER reinvent - ALWAYS check first!
"
fi

# Check for testing keywords (NEW - Dec 16, 2025)
TEST_KEYWORDS="test|testing|jest|run tests|unit test|e2e|playwright"
TESTING_WARNING=""
if echo "$USER_MESSAGE" | grep -qiE "$TEST_KEYWORDS"; then
    TESTING_WARNING="
🧪 TESTING REQUEST DETECTED

BEFORE running tests:
1. Use testing-workflow-skill (5Q/60Q/Guardian decision tree)
2. Check which tests to run:
   - npm run test:recent-fixes (AI date, shifts, weekend)
   - npm run test:sacred (Sacred compliance)
   - npm run test:e2e (End-to-end user flows)
   - npm run guardian:all (Pre-deployment validation)
3. Enable debug logging: DEBUG=true npm test
4. Interpret results using testing-workflow-skill patterns

NEVER: Run tests without understanding what's being tested
ALWAYS: Use appropriate test suite for the issue
"
fi

# Check for deployment keywords (NEW - Dec 16, 2025)
DEPLOY_KEYWORDS="deploy|deployment|staging|production|gcloud|cloud run"
DEPLOYMENT_WARNING=""
if echo "$USER_MESSAGE" | grep -qiE "$DEPLOY_KEYWORDS"; then
    DEPLOYMENT_WARNING="
🚀 DEPLOYMENT REQUEST DETECTED

MANDATORY PRE-DEPLOYMENT CHECKLIST:
1. Use deployment-workflow-skill (complete workflow)
2. Run pre-deployment tests:
   - npm run test:recent-fixes (validate all recent fixes)
   - bash scripts/smoke-test-staging.sh (staging validation)
3. If deploying to production:
   - Use production-deployment-checklist skill (7-phase checklist)
   - NEVER deploy without staging validation first
   - ALWAYS use post-deployment-monitoring skill (24-hour monitoring)
4. Check environment parity:
   - Use environment-parity-validation skill
   - Validate staging = production before deploying

CRITICAL RULE: NEVER deploy to production without explicit user approval
"
fi

# Check for skill creation keywords (NEW - Dec 16, 2025)
SKILL_KEYWORDS="skill|create skill|add skill|update skill|retrospective"
SKILL_WARNING=""
if echo "$USER_MESSAGE" | grep -qiE "$SKILL_KEYWORDS"; then
    SKILL_WARNING="
🚨 SKILL CREATION DETECTED! 🚨

MANDATORY SKILL FORMAT (NO EXCEPTIONS):
1. Directory structure: skill-name/SKILL.md (NOT skill-name.md)
2. YAML frontmatter:
   ---
   name: skill-name
   description: What it does + when to use it
   ---
3. Source: https://code.claude.com/docs/en/skills (saved to Memory MCP)
4. Verify: cat ~/.claude/skills/skill-name/SKILL.md

BEFORE creating skill:
- Use /advise to check if pattern already exists
- Use entry-to-skill-conversion-skill for ROI evaluation
- Read Memory MCP: 'Claude Code Skills - CORRECT Official Format'

AFTER creating skill:
- Verify directory structure exists
- Verify YAML frontmatter present
- Test activation with keyword triggers
- Add to AUTOMATIC-TOOL-TRIGGERS.md
"
fi

# ═══════════════════════════════════════════════════════════════════
# BRANCH-SPECIFIC INSTRUCTIONS AUTO-LOADING (Dynamic)
# ═══════════════════════════════════════════════════════════════════

# Get current branch dynamically
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")

# Build branch instructions file path
BRANCH_INSTRUCTIONS_FILE="CURRENT/${CURRENT_BRANCH}/${CURRENT_BRANCH}-Instructions.md"

# Load branch instructions if file exists
BRANCH_INSTRUCTIONS=""
if [ -f "$BRANCH_INSTRUCTIONS_FILE" ]; then
    BRANCH_INSTRUCTIONS=$(cat "$BRANCH_INSTRUCTIONS_FILE")
    BRANCH_CONTEXT="
═══════════════════════════════════════════════════════════════════
📋 BRANCH-SPECIFIC INSTRUCTIONS (Auto-Loaded for: $CURRENT_BRANCH)
═══════════════════════════════════════════════════════════════════

$BRANCH_INSTRUCTIONS

═══════════════════════════════════════════════════════════════════
END BRANCH INSTRUCTIONS - Continue with Skill Evaluation
═══════════════════════════════════════════════════════════════════
"
else
    BRANCH_CONTEXT=""
fi

# Log skill activation metrics
SKILL_COUNT=$(echo -e "$SKILL_LIST" | grep -c "^- " || echo "0")
log_skill_activation "hook_triggered" "$SKILL_COUNT"

# Inject forced evaluation prompt BEFORE user message
cat <<EOF
$BRANCH_CONTEXT
🚨 MANDATORY SKILL EVALUATION - ACTIVE ENFORCEMENT 🚨

You are about to respond to a user request. BEFORE implementing anything, you MUST complete this evaluation.
$CONTEXT_WARNING$TESTING_WARNING$DEPLOYMENT_WARNING$SKILL_WARNING
═══════════════════════════════════════════════════════════════════
STEP 0: CONTEXT & CODE CHECK (IF IMPLEMENTING)
═══════════════════════════════════════════════════════════════════

BEFORE implementing ANYTHING new:
1. CHECK BLUEPRINTS: Read FEATURE-CONTEXT-MAP.json → Load feature blueprint
   └─► cat memory-bank/always/FEATURE-CONTEXT-MAP.json | jq '.features["FEATURE"]'
   └─► Blueprints are LIVING DOCUMENTS with everything already built!
2. CHECK EXISTING CODE: grep -r 'keyword' src/ OR use Explore agent
3. FETCH CONTEXT: memory-bank/learned/
4. CHECK SKILLS: Does a skill already solve this?
5. CREATE /CURRENT/ WORKSPACE: /CURRENT/{BRANCH}/{THEME}/{TASK}/
   └─► Include: Work files + INDEX.md (what was done + context + routing)
   └─► Archive when done (AFTER extracting skills/context/knowledge)
⚠️ VIOLATION: Building without checking = reinventing the wheel

═══════════════════════════════════════════════════════════════════
STEP 1: EXTRACT KEYWORDS FROM USER MESSAGE
═══════════════════════════════════════════════════════════════════

User message: "$USER_MESSAGE"

Extract ALL keywords (nouns, verbs, actions):
- Keywords: [list ALL action words, technical terms, domain words]

═══════════════════════════════════════════════════════════════════
STEP 2: SCAN SKILLS & COMMIT TO USAGE
═══════════════════════════════════════════════════════════════════

🚨 SKILL-FIRST MANDATE: Use skills BEFORE writing code or manual investigation!
📚 HOW-TO: Memory MCP → "How to Use Claude Code Skills - Complete Guide"

🔥 TOP 10 CRITICAL SKILLS (Use FIRST by keyword):
┌─────────────────────────────────────────────────────────────────┐
│ KEYWORD          → SKILL TO USE                    │ ROI       │
├─────────────────────────────────────────────────────────────────┤
│ gap/missing/sync → api-first-validation-skill      │ 1,800%    │
│ connection/ECONN → database-credentials-skill      │ 10-60h/yr │
│ deploy/staging   → deployment-workflow-skill       │ 63.6%     │
│ test/jest/e2e    → testing-workflow-skill          │ 100h/yr   │
│ 0 shown/mismatch → frontend-backend-field-sync     │ P0 prev   │
│ traffic/revision → cloud-run-traffic-routing       │ 30 sec    │
│ AI wrong table   → ai-query-table-selection        │ 450%      │
│ endpoint/API     → api-endpoint-inventory-skill    │ prevent   │
│ troubleshoot     → troubleshooting-workflow-skill  │ 99.2%     │
│ UI debug/capture → developer-mode-debugging-skill  │ NEW       │
└─────────────────────────────────────────────────────────────────┘

Available Skills (97 total):
$SKILL_LIST

Available MCP Servers (prefer over manual commands):
- PostgreSQL: query dev/staging/production databases (use mcp__postgres-*)
- GitHub: fetch PRs/issues/files (use mcp__github__*)
- Memory: store/recall patterns (use mcp__basic-memory__*)
- Perplexity: real-time search ($5/month, use mcp__perplexity__search)

Evaluate quickly: Which skills OR MCPs match this request?
- List what you'll use (skills, MCPs, or both)
- Prefer MCPs over manual CLI commands when available

═══════════════════════════════════════════════════════════════════
STEP 3: EXECUTE WITH SKILLS
═══════════════════════════════════════════════════════════════════

State which skills you'll use, then proceed with user request.

Original user message:
$USER_MESSAGE
EOF
