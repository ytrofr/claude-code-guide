# Chapter 29: Branch Context System

**Evidence**: LIMOR AI MASTER-PLAN - 47-70% token savings per branch
**Difficulty**: Intermediate
**Time**: 30 minutes setup
**ROI**: 30-50% context reduction per branch

---

## Problem

Loading ALL context files for ALL branches wastes tokens:
- dev-Data needs database patterns, not UI patterns
- dev-UI needs frontend patterns, not sync patterns
- Loading everything = 116k+ tokens (context bloat)

---

## Solution: CONTEXT-MANIFEST.json

Each branch gets a manifest defining EXACTLY what to load.

### File Location

```
CURRENT/{branch}/CONTEXT-MANIFEST.json
```

### Structure

```json
{
  "manifest_version": "3.0",
  "branch": "dev-Knowledge",
  "mission": "Skills, Context, Agents & MCP Optimization",
  "domain": "knowledge-optimization",
  
  "ondemand_files": {
    "branch_context": [
      "CURRENT/dev-Knowledge/dev-Knowledge-ROADMAP.md"
    ],
    "skills-dev": [
      "skills-dev/creation-standards.md",
      "skills-dev/trigger-keywords.md"
    ],
    "context": [
      "context/CONTEXT-SYSTEM-GUIDE-MINI.md"
    ]
  },
  
  "estimated_tokens": {
    "global_always": 64000,
    "ondemand_domain": 15000,
    "total_max": 79000
  },
  
  "should_NOT_load": {
    "deployment/ci-cd.md": "Not managing CI/CD (dev-MERGE domain)",
    "database/COMPLETE-SCHEMA.md": "Too large - using QUICK-REFERENCE instead"
  }
}
```

---

## @ Import Enforcement

The manifest powers automatic file loading via @ imports.

### How It Works

1. **Session starts** → Hook detects branch
2. **Hook reads** → `CURRENT/{branch}/CONTEXT-MANIFEST.json`
3. **Hook generates** → @ imports in CLAUDE.md
4. **Claude Code** → Auto-loads @ imported files

### Hook Logic (session-start.sh)

```bash
#!/bin/bash
# .claude/hooks/session-start.sh

current_branch=$(git branch --show-current 2>/dev/null)
manifest="CURRENT/$current_branch/CONTEXT-MANIFEST.json"

if [ -f "$manifest" ]; then
    echo ""
    echo "## 🔄 AUTO-LOADED DOMAIN FILES ($current_branch)"
    echo ""
    echo "**Auto-loaded from**: $manifest"
    echo ""
    
    # Generate @ imports from manifest
    jq -r '.ondemand_files | to_entries[] | .value[]' "$manifest" 2>/dev/null | while read file; do
        # Handle absolute vs relative paths
        if [[ "$file" == CURRENT/* ]] || [[ "$file" == memory-bank/* ]]; then
            echo "@$file"
        else
            echo "@memory-bank/ondemand/$file"
        fi
    done
fi
```

### Result in CLAUDE.md

```markdown
## 🔄 AUTO-LOADED DOMAIN FILES (Session-Specific)

**Branch**: dev-Knowledge

**Auto-loaded from**: CURRENT/dev-Knowledge/CONTEXT-MANIFEST.json

@CURRENT/dev-Knowledge/dev-Knowledge-ROADMAP.md
@memory-bank/ondemand/skills-dev/creation-standards.md
@memory-bank/ondemand/skills-dev/trigger-keywords.md
@memory-bank/ondemand/context/CONTEXT-SYSTEM-GUIDE-MINI.md
```

---

## Token Savings Results

| Branch | Before | After | Savings |
|--------|--------|-------|--------|
| dev-Knowledge | 116k | 79k | 32% |
| dev-Limor | 126k | 79k | 37% |
| dev-UI | 100k | 53k | 47% |
| dev-Data | 110k | 75k | 32% |
| **Average** | **113k** | **72k** | **37%** |

---

## Setup Steps

### Step 1: Create Branch Directory

```bash
mkdir -p CURRENT/{branch-name}
```

### Step 2: Create Manifest

```bash
cat > CURRENT/{branch-name}/CONTEXT-MANIFEST.json << 'EOF'
{
  "manifest_version": "3.0",
  "branch": "{branch-name}",
  "mission": "[One sentence mission]",
  "domain": "[domain-name]",
  
  "ondemand_files": {
    "branch_context": [
      "CURRENT/{branch-name}/{branch-name}-ROADMAP.md"
    ]
  },
  
  "estimated_tokens": {
    "global_always": 64000,
    "ondemand_domain": 10000,
    "total_max": 74000
  }
}
EOF
```

### Step 3: Add Session-Start Hook

Copy the hook logic above to `.claude/hooks/session-start.sh`

### Step 4: Validate

```bash
# Switch to branch
git checkout {branch-name}

# Run hook manually
bash .claude/hooks/session-start.sh

# Verify @ imports appear
grep "^@" CLAUDE.md
```

---

## Best Practices

### 1. Keep Manifests Focused

**DO**: 5-15 files per branch
```json
"ondemand_files": {
  "branch_context": ["...ROADMAP.md"],
  "domain": ["quick-reference.md", "patterns.md"]
}
```

**DON'T**: Load everything
```json
"ondemand_files": {
  "everything": ["file1.md", "file2.md", ... "file50.md"]
}
```

### 2. Use should_NOT_load

Document WHY certain files are excluded:

```json
"should_NOT_load": {
  "deployment/ci-cd.md": "Not managing CI/CD (dev-MERGE domain)",
  "database/COMPLETE-SCHEMA.md": "Too large (96k!) - use QUICK-REFERENCE"
}
```

### 3. Track Token Budgets

```json
"estimated_tokens": {
  "global_always": 64000,
  "ondemand_domain": 15000,
  "total_max": 79000,
  "status": "OPTIMIZED - 33k tokens saved"
}
```

---

## Validation Commands

```bash
# Check manifest exists
ls CURRENT/$(git branch --show-current)/CONTEXT-MANIFEST.json

# View loaded files
jq '.ondemand_files' CURRENT/$(git branch --show-current)/CONTEXT-MANIFEST.json

# Count files per branch
jq '[.ondemand_files | to_entries[] | .value | length] | add' CURRENT/*/CONTEXT-MANIFEST.json

# Check context usage in Claude Code
/context
```

---

## Template

See `template/CURRENT/{branch}/CONTEXT-MANIFEST.json` for a ready-to-use template.

---

**Related Chapters**:
- Chapter 12: Memory Bank Hierarchy (4-tier structure)
- Chapter 26: Claude Code Rules System (rules loading)
- Chapter 30: Blueprint Auto-Loading (per-branch blueprints)
- Chapter 31: Branch-Aware Development (branch-variables.json)

---

**Previous**: [28: Skill Optimization Patterns](28-skill-optimization-patterns.md)
**Next**: [30: Blueprint Auto-Loading](30-blueprint-auto-loading.md)