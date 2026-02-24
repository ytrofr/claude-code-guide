---
title: "Advanced Configuration Patterns"
description: "Path-specific rules, agent memory, skills preloading, dynamic injection, prompt hooks, and global vs project scope"
---

# Chapter 46: Advanced Configuration Patterns

This chapter documents advanced Claude Code configuration patterns discovered through a comprehensive audit of official documentation (Entry #363). These patterns go beyond basic setup to optimize context loading, agent intelligence, skill efficiency, and code quality enforcement.

---

## 1. Path-Specific Rules

Rules files support YAML frontmatter with `paths:` glob patterns for conditional loading. Instead of loading ALL rules for every operation, rules only load when you're editing files that match their patterns.

### Syntax

```yaml
# .claude/rules/database/patterns.md
---
paths:
  - "src/database/**"
  - "src/sync/**"
  - "scripts/*sync*"
---
# (rule content follows)
```

### When to Use Conditional vs Unconditional

| Rule Type                   | Use `paths:` | Example                                  |
| --------------------------- | ------------ | ---------------------------------------- |
| Domain-specific code rules  | Yes          | Database patterns, API integration rules |
| Deployment rules            | Yes          | Only when editing Dockerfile, \*.yml     |
| UI/encoding rules           | Yes          | Only when editing public/**, prompts/**  |
| Git safety rules            | No           | Always applies regardless of file        |
| Project structure reference | No           | Needed for all code work                 |
| MCP usage patterns          | No           | Always relevant                          |

### Impact

Without `paths:`, a project with 13 rule files loads ALL of them on every message. With `paths:` on domain-specific rules, only relevant rules load — reducing per-message context by 20-40%.

### Glob Pattern Reference

| Pattern           | Matches                                  |
| ----------------- | ---------------------------------------- |
| `src/**`          | All files under src/ recursively         |
| `*.yml`           | YAML files in root                       |
| `scripts/deploy*` | Files starting with "deploy" in scripts/ |
| `src/**/*.js`     | All .js files under src/                 |
| `public/**`       | All frontend files                       |

---

## 2. Agent Memory Persistence

Agents support `memory:` for persistent learning across sessions. Without memory, agents start fresh every time they're spawned.

### Memory Options

| Option            | Scope             | Persists Across              | Best For                  |
| ----------------- | ----------------- | ---------------------------- | ------------------------- |
| `memory: project` | This project only | All sessions in this project | Project-specific patterns |
| `memory: local`   | This machine only | All sessions on this machine | Machine-specific config   |
| `memory: user`    | All projects      | All sessions everywhere      | Universal patterns        |
| (none)            | No persistence    | Nothing                      | Stateless agents          |

### Syntax

```yaml
---
name: database-agent
description: "Database operations specialist"
memory: project
---
```

### What Agents Remember

With memory enabled, agents learn across sessions:

- Past mistakes and corrections
- Project-specific conventions discovered during work
- Preferences expressed by the user
- Patterns that worked or failed

### Recommended Memory Assignment

```yaml
# Project-specific agents → memory: project
database-agent:       memory: project   # Learns schema patterns
test-engineer:        memory: project   # Learns test conventions
deploy-agent:         memory: project   # Learns deploy patterns

# Cross-project agents → memory: user
architecture-agent:   memory: user      # Architecture is universal
security-agent:       memory: user      # Security rules apply everywhere
debug-specialist:     memory: user      # Debugging methodology is universal
```

---

## 3. Agent Skills Preloading

The `skills:` field tells agents which skills to load immediately on spawn, rather than discovering them during operation.

### Syntax

```yaml
---
name: database-agent
description: "Database operations specialist"
memory: project
skills:
  - database-master-skill
  - database-column-standards-skill
---
```

### Benefits

- **Faster startup**: Agent has domain knowledge immediately
- **Higher accuracy**: Follows established patterns from first tool call
- **Less context waste**: No exploratory reads to discover patterns

### Matching Skills to Agents

| Agent            | Preload Skills                             | Rationale                 |
| ---------------- | ------------------------------------------ | ------------------------- |
| database-agent   | database-master, column-standards          | Schema + naming patterns  |
| deploy-agent     | deployment-master, safe-deployment         | Deploy checklist + safety |
| test-engineer    | testing-master, baseline-methodology       | Test patterns + metrics   |
| accuracy-agent   | parity-master, field-mapping               | Data validation patterns  |
| debug-specialist | troubleshooting-master, pipeline-debugging | Debug methodology         |

**Rule**: Only preload skills directly relevant to the agent's domain. Cross-domain skills waste context.

---

## 4. Agent Permission Modes

The `permissionMode:` field controls how agents handle permission prompts.

### Available Modes

| Mode                | Behavior                                | When to Use                   |
| ------------------- | --------------------------------------- | ----------------------------- |
| (default)           | Inherits parent session mode            | Most agents                   |
| `plan`              | Read-only — can explore but never write | Navigators, monitors, scouts  |
| `acceptEdits`       | Auto-accepts file edits                 | Code-writing agents           |
| `bypassPermissions` | No permission prompts                   | Fully trusted automation only |

### Syntax

```yaml
---
name: knowledge-navigator
description: "Search and navigate project knowledge"
permissionMode: plan
---
```

### Safety Guidelines

- Use `plan` for any agent that should NEVER modify files
- Use `acceptEdits` for agents that write code as their core function
- NEVER use `bypassPermissions` for agents that interact with external services
- When in doubt, use the default (inherit from parent)

---

## 5. Skills Dynamic Injection

Two mechanisms inject dynamic content into skills: `!`command``for live system state and`$ARGUMENTS` for user parameters.

### Dynamic State with !`command`

```markdown
## Database Health

!`docker exec my-postgres psql -U user -d mydb -c "SELECT current_database(), pg_size_pretty(pg_database_size(current_database()))" 2>/dev/null || echo "Not running"`

## Last Test Results

!`ls -t tests/results/*.json 2>/dev/null | head -1 | xargs cat 2>/dev/null | jq '{total, passed, failed}' 2>/dev/null || echo "No results"`

## Current Git State

!`git log --oneline -3 2>/dev/null || echo "Not a git repo"`
```

**Rules**:

- Commands run when the skill is loaded (not on every message)
- ALWAYS include `2>/dev/null || echo "fallback"` for graceful failure
- Keep commands fast (<2 seconds)
- Never use commands with side effects (writes, deletes, API calls)

### User Parameters with $ARGUMENTS

For user-invocable skills:

```yaml
---
name: deploy-skill
user-invocable: true
argument-hint: "[environment]"
---

Deploy to $ARGUMENTS:
1. Run tests for $ARGUMENTS environment
2. Build for $ARGUMENTS
3. Push to $ARGUMENTS
```

User types `/deploy staging` → `$ARGUMENTS` becomes "staging".

Use `$ARGUMENTS[0]`, `$ARGUMENTS[1]` for positional arguments.

---

## 6. Prompt-Based Hooks

Beyond shell script hooks (`type: "command"`), Claude Code supports LLM-powered hooks (`type: "prompt"`) for intelligent validation.

### Syntax

```json
{
  "PreToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [
        {
          "type": "prompt",
          "prompt": "Check if this code follows project patterns: (1) Uses employee_id not id, (2) No hardcoded data, (3) UTF-8 encoding. If the file is NOT in src/, always allow. Output JSON: {\"decision\":\"allow\"} or {\"decision\":\"block\",\"reason\":\"...\"}"
        }
      ]
    }
  ]
}
```

### When to Use Prompt Hooks vs Command Hooks

| Aspect       | Command Hook                       | Prompt Hook                      |
| ------------ | ---------------------------------- | -------------------------------- |
| Speed        | Fast (ms)                          | Slower (seconds)                 |
| Cost         | Free                               | Uses LLM tokens                  |
| Intelligence | Pattern matching only              | Semantic understanding           |
| Best for     | Formatting, logging, simple checks | Code quality, pattern validation |

### Async Hooks

For non-critical background operations, add `"async": true`:

```json
{
  "PostToolUseFailure": [
    {
      "hooks": [
        {
          "type": "command",
          "command": ".claude/hooks/tool-failure-logger.sh",
          "async": true
        }
      ]
    }
  ]
}
```

**Rule**: Use `async: true` for logging and monitoring. Keep synchronous for validation and blocking.

---

## 7. Global vs Project Scope

Claude Code configuration exists at two levels with clear precedence rules.

### Scope Comparison

| Scope       | Location                | Available To      | Persists Across |
| ----------- | ----------------------- | ----------------- | --------------- |
| **Project** | `.claude/` (in repo)    | This project only | Git branches    |
| **Global**  | `~/.claude/` (home dir) | ALL projects      | All projects    |

### What Goes Where

| Component | Project (`.claude/`)        | Global (`~/.claude/`)      |
| --------- | --------------------------- | -------------------------- |
| Rules     | Domain-specific patterns    | Universal coding standards |
| Agents    | Project-specific agents     | Cross-project agents       |
| Skills    | Project-specific workflows  | Universal workflows        |
| Hooks     | Project-specific validation | Session management         |
| Memory    | Project knowledge           | Cross-project knowledge    |

### Override Behavior

When both project and global have the same named file, **project wins**:

```
~/.claude/agents/security-agent.md     ← Generic (for other projects)
.claude/agents/security-agent.md       ← Project-specific (WINS in this project)
```

### Decision Matrix

Ask: "Does this apply to ALL my projects, or just this one?"

- **All projects** → Global (`~/.claude/`)
  - Architecture patterns, security rules, debugging methodology
  - Session start/end protocols, documentation standards

- **This project only** → Project (`.claude/`)
  - Domain-specific rules (Sacred Commandments, Hebrew encoding)
  - Project-specific agents (database-agent with schema knowledge)
  - Project-specific skills (revenue-calculation, parity-validation)

---

## 8. Skills Model and Tool Restrictions

Two fields optimize skill cost and safety.

### model: — Cost Optimization

```yaml
---
name: blueprint-discovery-skill
model: haiku # Cheap + fast for simple lookups
allowed-tools: [Read, Grep, Glob] # Read-only safety
---
```

| Model     | Use For                                    | Typical Count    |
| --------- | ------------------------------------------ | ---------------- |
| `haiku`   | Navigation, reference, lookups             | ~30 skills (40%) |
| `sonnet`  | Validation, workflows, integration         | ~30 skills (40%) |
| `opus`    | Architecture, debugging, complex reasoning | ~10 skills (15%) |
| (default) | Inherits session model                     | Remaining skills |

### allowed-tools: — Safety Restriction

```yaml
allowed-tools: [Read, Grep, Glob]    # Read-only skill
allowed-tools: [Read, Write, Edit, Bash]  # Full access skill
```

Combine both for maximum efficiency:

```yaml
---
name: sacred-commandments-skill
description: "Navigate Sacred Commandments..."
model: haiku
allowed-tools: [Read, Grep, Glob]
---
```

This creates a fast, cheap, read-only reference skill.

---

## 9. Permission Precedence (v2.1.27+)

Content-level `ask` now overrides tool-level `allow`:

```json
{
  "permissions": {
    "allow": ["Bash"],
    "ask": ["Bash(rm *)"]
  }
}
```

**Result**: All Bash commands auto-allowed EXCEPT `rm *` which prompts the user. Previously, `allow: ["Bash"]` would override all `ask` rules.

**Precedence order**: ask > acceptEdits > plan > default

---

## Verification Checklist

After implementing these patterns, verify your setup:

```bash
# Path-specific rules
grep -rl "^paths:" .claude/rules/ | wc -l

# Agent features
grep -rl "^memory:" .claude/agents/*.md | wc -l
grep -rl "^skills:" .claude/agents/*.md | wc -l
grep -rl "^permissionMode:" .claude/agents/*.md | wc -l

# Skill features
grep -rl "^model:" .claude/skills/*/SKILL.md | wc -l
grep -rl "^allowed-tools:" .claude/skills/*/SKILL.md | wc -l

# Hook features
grep -c '"type": "prompt"' .claude/settings.json
grep -c '"async": true' .claude/settings.json

# Global agents
ls ~/.claude/agents/*.md 2>/dev/null | wc -l
```

---

## References

- [Official Skills Docs](https://code.claude.com/docs/en/skills)
- [Official Sub-Agents Docs](https://code.claude.com/docs/en/sub-agents)
- [Official Hooks Guide](https://code.claude.com/docs/en/hooks-guide)
- [Official Memory Docs](https://code.claude.com/docs/en/memory)
- Entry #363: Claude Code Best Practices Audit (comprehensive audit methodology)
- Chapter 13: Claude Code Hooks (hook event reference)
- Chapter 36: Agents and Subagents (agent patterns)
- Chapter 44: Skill Design Principles (skill best practices)
