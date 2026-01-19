# Chapter 30: Blueprint Auto-Loading

**Evidence**: LIMOR AI MASTER-PLAN Phase 3
**Difficulty**: Intermediate
**Time**: 20 minutes setup
**ROI**: Auto-load relevant blueprints per branch

---

## Problem

Large projects have many blueprints (system architecture docs):
- Loading ALL blueprints = context bloat
- Manually remembering which blueprints to read = errors
- Different branches need different blueprints

---

## Solution: blueprint-registry.json

Central registry defining which blueprints load for which branch.

### File Location

```
memory-bank/blueprints/blueprint-registry.json
```

### Structure

```json
{
  "blueprints": {
    "CONTEXT-SYSTEM": {
      "location": "Library/context/CONTEXT-SYSTEM-BLUEPRINT.md",
      "type": "domain",
      "branches": ["dev-Knowledge"],
      "auto_load": true,
      "size_tokens": 2500
    },
    "TRUE-AI-SYSTEM": {
      "location": "system/TRUE-AI-SYSTEM-BLUEPRINT.md",
      "type": "core",
      "branches": ["dev-Limor", "dev-MERGE"],
      "auto_load": true,
      "size_tokens": 5400
    },
    "DATABASE-SCHEMA": {
      "location": "core/DATABASE-SCHEMA-BLUEPRINT.md",
      "type": "core",
      "branches": ["dev-Data", "dev-Limor", "dev-MERGE"],
      "auto_load": true,
      "size_tokens": 3200
    }
  },
  "branch_blueprints": {
    "dev-Knowledge": ["CONTEXT-SYSTEM", "SKILLS-SYSTEM"],
    "dev-Limor": ["TRUE-AI-SYSTEM", "DATABASE-SCHEMA"],
    "dev-Data": ["DATABASE-SCHEMA", "GAP-SYSTEM"],
    "dev-MERGE": ["DEPLOYMENT", "MULTI-BRANCH"],
    "dev-UI": ["UI-THEME", "DASHBOARD-PATTERNS"]
  }
}
```

---

## Hook Enhancement

Add to `.claude/hooks/session-start.sh`:

```bash
load_branch_blueprints() {
    local current_branch=$(git branch --show-current 2>/dev/null)
    local registry="memory-bank/blueprints/blueprint-registry.json"

    if [ ! -f "$registry" ]; then
        return 0
    fi

    local blueprints=$(jq -r ".branch_blueprints[\"$current_branch\"][]?" "$registry" 2>/dev/null)

    if [ -z "$blueprints" ]; then
        return 0
    fi

    echo ""
    echo "## 📘 AUTO-LOADED BLUEPRINTS ($current_branch)"
    echo ""

    while IFS= read -r bp_name; do
        local bp_path=$(jq -r ".blueprints[\"$bp_name\"].location" "$registry")
        echo "@memory-bank/blueprints/$bp_path"
    done <<< "$blueprints"
    
    echo ""
}

# Call in hook output
load_branch_blueprints
```

---

## Blueprint Organization

Recommended directory structure:

```
memory-bank/blueprints/
├── blueprint-registry.json      # Central registry
├── core/                         # System-wide
│   ├── DATABASE-SCHEMA-BLUEPRINT.md
│   └── TRUE-AI-SYSTEM-BLUEPRINT.md
├── features/                     # Feature-specific
│   ├── LABOR-COST-BLUEPRINT.md
│   └── FEEDBACK-SYSTEM-BLUEPRINT.md
├── infrastructure/               # Infrastructure
│   ├── MULTI-BRANCH-BLUEPRINT.md
│   └── DEPLOYMENT-BLUEPRINT.md
└── Library/                      # Domain patterns
    ├── context/
    ├── database/
    └── testing/
```

---

## CONTEXT-MANIFEST Integration

Add blueprints to your branch manifest:

```json
{
  "ondemand_files": {
    "branch_context": ["...ROADMAP.md"],
    "blueprints": [
      "memory-bank/blueprints/Library/context/CONTEXT-SYSTEM-BLUEPRINT.md"
    ]
  }
}
```

This generates:
```markdown
@memory-bank/blueprints/Library/context/CONTEXT-SYSTEM-BLUEPRINT.md
```

---

## Setup Steps

### Step 1: Create Registry

```bash
mkdir -p memory-bank/blueprints
cat > memory-bank/blueprints/blueprint-registry.json << 'EOF'
{
  "blueprints": {},
  "branch_blueprints": {}
}
EOF
```

### Step 2: Add Blueprints

For each blueprint:
```json
"BLUEPRINT-NAME": {
  "location": "path/to/BLUEPRINT.md",
  "type": "core|feature|domain",
  "branches": ["branch1", "branch2"],
  "auto_load": true,
  "size_tokens": 2500
}
```

### Step 3: Map to Branches

```json
"branch_blueprints": {
  "your-branch": ["BLUEPRINT-1", "BLUEPRINT-2"]
}
```

### Step 4: Add to CONTEXT-MANIFEST

Reference blueprints in your branch manifest.

---

## Blueprint Types

| Type | Purpose | Example |
|------|---------|--------|
| **core** | System-wide, multiple branches need | DATABASE-SCHEMA |
| **feature** | Feature-specific, recreatable | LABOR-COST |
| **domain** | Domain patterns | TESTING-BLUEPRINT |
| **infrastructure** | DevOps/deployment | DEPLOYMENT |

---

## Validation

```bash
# List all blueprints in registry
jq '.blueprints | keys[]' memory-bank/blueprints/blueprint-registry.json

# Check blueprints for current branch
jq ".branch_blueprints[\"$(git branch --show-current)\"]" \
    memory-bank/blueprints/blueprint-registry.json

# Verify blueprint file exists
for bp in $(jq -r '.blueprints[].location' memory-bank/blueprints/blueprint-registry.json); do
    [ -f "memory-bank/blueprints/$bp" ] && echo "✅ $bp" || echo "❌ $bp MISSING"
done
```

---

**Related Chapters**:
- Chapter 29: Branch Context System (CONTEXT-MANIFEST)
- Chapter 12: Memory Bank Hierarchy
- Chapter 31: Branch-Aware Development

---

**Previous**: [29: Branch Context System](29-branch-context-system.md)
**Next**: [31: Branch-Aware Development](31-branch-aware-development.md)