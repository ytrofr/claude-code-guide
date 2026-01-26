# [YOUR_PROJECT_NAME] - Claude Code Configuration

**System**: Memory Bank + Skills + MCP Integration
**Created**: [DATE]
**Status**: [Development / Production / Testing]

---

## 🚨 CRITICAL PROJECT RULES

**Add your project's core patterns here - these will be auto-loaded in every Claude Code session**

### Rule 1: [Your First Critical Rule]
```yaml
PATTERN: "[What must always be done]"
VALIDATION: "[How to check compliance]"
ENFORCEMENT: "[Hooks/tests that enforce this]"

EXAMPLES:
  ✅ CORRECT: "[Show correct implementation]"
  ❌ WRONG: "[Show what to avoid]"
```

### Rule 2: [Your Second Critical Rule]
```yaml
PATTERN: "[Required behavior or standard]"
REASON: "[Why this matters]"
```

### Rule 3: Perplexity Cache-First Rule (Recommended)
```yaml
PATTERN: "ALWAYS check Memory MCP before Perplexity searches"
BEFORE_SEARCH: "mcp__basic-memory__search_notes('topic')"
IF_FOUND: "Use cached result (FREE!) - skip Perplexity entirely"
IF_NOT_FOUND: "Use Perplexity, then IMMEDIATELY cache results"
CACHE_LOCATION: "research-cache/ folder (global, all branches)"
MANDATORY_CACHING: "After EVERY Perplexity search → mcp__basic-memory__write_note(folder='research-cache')"
COST_SAVINGS: "$0.005 per cached query, 80%+ budget savings on repeat topics"
ROI: "Prevents $4+/month waste on duplicate searches"
```

---

## 📚 Auto-Load Context (Memory Bank)

**Files auto-loaded every session** (keep this list small - max 10-15 files):

```
@memory-bank/always/CORE-PATTERNS.md       # Single source of truth for all patterns
@memory-bank/always/CONTEXT-ROUTER.md      # Agent routing rules
@memory-bank/always/system-status.json     # Feature status tracking
```

**How to add more**:
- Prefix with `@` to auto-load
- Keep files focused and concise
- Use CORE-PATTERNS.md for patterns, not this file
- Link to detailed docs in memory-bank/learned/

**Branch-Specific Files**:
The `session-start.sh` hook automatically appends branch-specific @imports
to this file at session start. Look for the `AUTO-LOADED DOMAIN FILES`
section at the bottom (added dynamically from CONTEXT-MANIFEST.json).

---

## 🎯 Project Context

### Current Focus
- **Sprint**: [Current sprint name]
- **Priority**: [Top priority feature or task]
- **Branch**: [Active branch name]

### Technology Stack
- **Backend**: [Node.js / Python / etc.]
- **Database**: [PostgreSQL / MySQL / etc.]
- **Frontend**: [React / Vue / etc.]
- **Deployment**: [GCP / AWS / Vercel / etc.]

### API Integrations
- **[API Name]**: [Endpoint, auth method, status]

---

## 🔧 Development Workflow

### Session Protocol
```bash
# Session Start (every new Claude Code session)
git status
cat memory-bank/always/system-status.json | jq '.features[] | select(.passes == false)'

# Session End (before closing)
git add -A && git commit -m "checkpoint: [description]"
# Update system-status.json with progress
```

### Testing Standards
```bash
# Before commits
npm test
npm run lint

# Before deployments
npm run build
[your validation commands]
```

---

## 🔗 Quick References

### Core Patterns
→ See **memory-bank/always/CORE-PATTERNS.md** for all project patterns

### Feature Status
→ See **memory-bank/always/system-status.json** for current state

### Session Continuity
→ Use `/session-start` and `/session-end` commands (if configured)

---

## 📝 Customization Instructions

**To customize this template**:

1. Replace all `[PLACEHOLDERS]` with your values
2. Add your critical project rules (3-5 max)
3. List your auto-loaded context files
4. Define your development workflow
5. Update quick references

**Keep this file**:
- Focused on essentials
- Scannable in < 2 minutes
- Free of duplication (reference CORE-PATTERNS.md instead)
- Updated when project standards change

---

**Project Context Authority**: Essential project configuration for all Claude Code sessions
**Usage**: Auto-loaded every session, keep concise and actionable
**Maintenance**: Update when core patterns or workflows change
