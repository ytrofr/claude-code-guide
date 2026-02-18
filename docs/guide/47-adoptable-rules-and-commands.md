---
layout: default
title: "Adoptable Rules, Commands & Configuration Templates"
description: "15 universal rules, 7 slash commands, and configuration templates that any Claude Code project can adopt. Covers agent-first workflow, validation gates, session protocol, anti-overengineering, and quality standards."
---

# Chapter 47: Adoptable Rules, Commands & Configuration Templates

This chapter provides a complete set of production-tested rules and commands that you can adopt into any Claude Code project. They enforce workflow best practices, prevent common mistakes, and establish consistent patterns across your codebase.

**Purpose**: Give any project a battle-tested Claude Code configuration in minutes
**Difficulty**: Beginner (copy and customize)
**Time**: 15-30 minutes to adopt, ongoing value
**Template**: All files available in `template/.claude/rules/` and `template/.claude/commands/`

---

## The Problem

Most Claude Code projects start with a blank `.claude/` directory and build rules ad hoc. This leads to:

- No validation workflow (Claude jumps straight to coding)
- No session protocol (context lost between sessions)
- No over-engineering prevention (simple tasks become complex solutions)
- No quality standards (mock data, skipped tests, direct execution)
- Inconsistent patterns across team members

These 15 rules and 7 commands solve all of these problems. They were developed over 14+ months of production use across 5 projects and refined through 360+ documented entries.

---

## Understanding Scope: Global vs Project

Claude Code loads rules from two locations:

```
~/.claude/rules/         <-- Global (user-level, all projects)
.claude/rules/           <-- Project (repo-level, this project only)
```

### Key Differences

| Aspect      | Global (`~/.claude/`)         | Project (`.claude/`)                |
| ----------- | ----------------------------- | ----------------------------------- |
| Scope       | ALL projects on this machine  | This repository only                |
| Shared with | Only you                      | Everyone who clones the repo        |
| Git tracked | No (personal config)          | Yes (committed to repo)             |
| Override    | Lower priority                | Higher priority (wins on conflict)  |
| Best for    | Personal workflow preferences | Team standards, project conventions |

### Where to Install

**For personal use**: Copy rules to `~/.claude/rules/`. They apply to every project you work on.

**For team adoption**: Copy rules to `.claude/rules/` inside your repo and commit them. Every collaborator gets them automatically.

**For both**: Install globally for yourself, and commit project-level copies for your team. Project rules override global ones if there is a naming conflict.

---

## The 15 Universal Rules

### Directory Structure

```
.claude/rules/
├── documentation/
│   └── versioning.md              # Version format standards
├── global/
│   ├── agent-usage.md             # Agent-first workflow
│   ├── context-checking.md        # Check before building
│   └── validation-workflow.md     # 7-step + 5-gate validation
├── mcp/
│   ├── agent-routing.md           # Agent coordination patterns
│   └── mcp-first.md               # MCP tools over npm/pip
├── planning/
│   ├── anti-overengineering.md    # 6-point validation checklist
│   ├── plan-checklist.md          # 11 mandatory plan sections
│   └── plan-link.md               # Plan file metadata
├── process/
│   ├── safety-rules.md            # WSL/VS Code protection
│   └── session-protocol.md        # Session start/end protocol
├── projects/
│   └── registry.md                # Project inventory
├── quality/
│   ├── no-mock-data.md            # No mock/fake/placeholder data
│   └── standards.md               # Accuracy and quality targets
└── technical/
    └── patterns.md                # Universal technical patterns
```

### Rule Inventory

| #   | Rule File                 | Category      | Priority | What It Enforces                                            |
| --- | ------------------------- | ------------- | -------- | ----------------------------------------------------------- |
| 1   | `agent-usage.md`          | global        | HIGH     | Always delegate to agents, never work directly              |
| 2   | `context-checking.md`     | global        | HIGH     | Search for existing solutions before building new ones      |
| 3   | `validation-workflow.md`  | global        | HIGH     | 7-step workflow + 5 pre-implementation gates                |
| 4   | `session-protocol.md`     | process       | HIGH     | Git status check at start, checkpoint at end                |
| 5   | `safety-rules.md`         | process       | HIGH     | Never kill all processes (WSL/VS Code protection)           |
| 6   | `no-mock-data.md`         | quality       | HIGH     | Zero mock, fake, stub, or placeholder data                  |
| 7   | `anti-overengineering.md` | planning      | HIGH     | 6-point check: can it be done in under 50 lines?            |
| 8   | `plan-checklist.md`       | planning      | MEDIUM   | 11 mandatory sections in every plan (incl. modularity gate) |
| 9   | `plan-link.md`            | planning      | MEDIUM   | Metadata header for plan file discoverability               |
| 10  | `mcp-first.md`            | mcp           | MEDIUM   | Prefer MCP tools over npm/pip installations                 |
| 11  | `agent-routing.md`        | mcp           | MEDIUM   | Query classification and agent budget rules                 |
| 12  | `standards.md`            | quality       | MEDIUM   | Accuracy targets and self-verification                      |
| 13  | `patterns.md`             | technical     | MEDIUM   | Format-first workflow, modular development                  |
| 14  | `versioning.md`           | documentation | LOW      | Consistent version/date/changelog format                    |
| 15  | `registry.md`             | projects      | LOW      | Project inventory with ports and paths                      |

---

## The 7 Slash Commands

Commands live in `.claude/commands/` and are invoked with `/command-name` in Claude Code.

| #   | Command          | Purpose                                                         | When to Use                         |
| --- | ---------------- | --------------------------------------------------------------- | ----------------------------------- |
| 1   | `/session-start` | Initialize session: git status, feature discovery, select task  | Beginning of every session          |
| 2   | `/session-end`   | Checkpoint: verify commits, update status, create handoff       | End of every session                |
| 3   | `/retrospective` | Create a reusable skill from session learnings (guided)         | After solving a hard problem        |
| 4   | `/document`      | Full documentation workflow: Entry + Skill + Blueprint + Memory | After completing meaningful work    |
| 5   | `/advise`        | Search skills registry before starting new work                 | Before implementing anything        |
| 6   | `/blueprint`     | Generate comprehensive feature documentation templates          | When documenting complex features   |
| 7   | `/slashes`       | List all available slash commands with descriptions             | When you forget what commands exist |

### Command Details

**`/session-start`** runs `git status`, checks for incomplete features, and displays recent commits. It ensures you always know the current state before doing work.

**`/session-end`** checks for uncommitted changes, prompts you to create checkpoint commits, and verifies no features are left in an unknown state.

**`/retrospective`** walks you through 5 questions to capture session learnings as a reusable skill file. It follows the Sionic AI pattern for high-activation-rate skills.

**`/document`** is the most comprehensive command -- a 13-step workflow that creates entry files, analyzes patterns, suggests skills/rules/blueprints, updates status files, and stores memory notes.

**`/advise`** searches your skills directory for solutions that already exist before you start building from scratch. It prevents reinventing solutions.

---

## Decision Matrix: Which Rules Should You Adopt?

Not every project needs all 15 rules. Use this matrix to decide:

### Every Project Should Adopt (HIGH priority)

These provide immediate value with zero customization:

| Rule                      | Why It Matters                                                     |
| ------------------------- | ------------------------------------------------------------------ |
| `context-checking.md`     | Prevents rebuilding what already exists (saves 1-4 hours per task) |
| `validation-workflow.md`  | Ensures code quality through 5 gates before implementation         |
| `session-protocol.md`     | Never lose context between sessions                                |
| `safety-rules.md`         | Prevents crashing your development environment                     |
| `no-mock-data.md`         | Ensures all data comes from real sources                           |
| `anti-overengineering.md` | Prevents simple tasks from becoming complex projects               |

### Most Projects Should Adopt (MEDIUM priority)

These add significant value but may need light customization:

| Rule                | Customize What                                          |
| ------------------- | ------------------------------------------------------- |
| `agent-usage.md`    | Your agent routing table (which agents for which tasks) |
| `plan-checklist.md` | Project-specific sections if needed                     |
| `mcp-first.md`      | Your available MCP tools list                           |
| `standards.md`      | Your accuracy targets and self-verification commands    |
| `patterns.md`       | Your port number, format commands, file size limits     |

### Adopt If Relevant (LOW priority)

These are valuable but more situational:

| Rule               | When to Adopt                                      |
| ------------------ | -------------------------------------------------- |
| `agent-routing.md` | If you use multiple agents with budget constraints |
| `plan-link.md`     | If your team shares plan files                     |
| `versioning.md`    | If you need consistent changelog format            |
| `registry.md`      | If you manage multiple related projects            |

---

## Quick Adoption Guide

### Option 1: Copy the Full Template (Recommended)

```bash
# From the claude-code-guide repository:
cp -r template/.claude/rules/ /path/to/your-project/.claude/rules/
cp -r template/.claude/commands/ /path/to/your-project/.claude/commands/

# Then customize:
# 1. Edit projects/registry.md with YOUR projects
# 2. Edit technical/patterns.md with YOUR port/format commands
# 3. Edit quality/standards.md with YOUR accuracy targets
```

### Option 2: Install Globally (Personal Use)

```bash
# Copy rules to your global config:
cp -r template/.claude/rules/* ~/.claude/rules/

# Copy commands:
cp -r template/.claude/commands/* ~/.claude/commands/

# These now apply to ALL your projects
```

### Option 3: Cherry-Pick Individual Rules

```bash
# Just the essentials:
mkdir -p .claude/rules/global .claude/rules/process .claude/rules/quality .claude/rules/planning

# Copy only what you need:
cp template/.claude/rules/global/context-checking.md .claude/rules/global/
cp template/.claude/rules/global/validation-workflow.md .claude/rules/global/
cp template/.claude/rules/process/session-protocol.md .claude/rules/process/
cp template/.claude/rules/process/safety-rules.md .claude/rules/process/
cp template/.claude/rules/quality/no-mock-data.md .claude/rules/quality/
cp template/.claude/rules/planning/anti-overengineering.md .claude/rules/planning/
```

### Option 4: Start Minimal, Grow Incrementally

Week 1: Install the 6 HIGH priority rules. See how they change your workflow.

Week 2: Add the MEDIUM priority rules. Customize agent routing and standards.

Week 3: Add commands. `/session-start` and `/session-end` alone save significant context.

---

## Customization Guide

### Rules You Should Edit

**`projects/registry.md`** -- Replace the example projects with your own:

```markdown
| Project     | Repo         | Local Path | Tech Stack        |
| ----------- | ------------ | ---------- | ----------------- |
| My Backend  | org/backend  | ~/backend  | Node.js, Express  |
| My Frontend | org/frontend | ~/frontend | React, TypeScript |
```

**`technical/patterns.md`** -- Update with your project conventions:

```javascript
// Your port standard
const PORT = process.env.PORT || 3000;

// Your format-first workflow
npm run format       // 1. Format
npm run lint         // 2. Lint
npm test            // 3. Test
git commit          // 4. Commit
```

**`quality/standards.md`** -- Set your accuracy targets and health check URLs:

```yaml
PRE_USER_TESTING:
  Tier_1: "curl localhost:3000/health"
  Tier_2: "npm test -- --coverage"
  Tier_3: "npm run e2e"
```

### Rules You Should NOT Edit

These are universal and work as-is:

- `context-checking.md` -- The principle is universal
- `safety-rules.md` -- WSL/VS Code safety applies everywhere
- `no-mock-data.md` -- Mock data is bad in every project
- `anti-overengineering.md` -- Over-engineering is universal
- `session-protocol.md` -- Session management is universal
- `validation-workflow.md` -- The 7-step workflow applies everywhere

---

## How Rules Are Loaded

Claude Code automatically discovers and loads all `.md` files in `.claude/rules/` (recursively). No registration or configuration is needed.

```
.claude/rules/global/context-checking.md      ← Auto-loaded
.claude/rules/quality/no-mock-data.md          ← Auto-loaded
.claude/rules/planning/plan-checklist.md       ← Auto-loaded
```

### Loading Order

1. Global rules (`~/.claude/rules/`) load first
2. Project rules (`.claude/rules/`) load second and override globals
3. All `.md` files in subdirectories are included
4. Files with `paths:` frontmatter only load when editing matching files

### Path-Specific Rules

To make a rule load only when editing certain files, add `paths:` frontmatter:

```yaml
---
paths:
  - "src/database/**"
  - "scripts/*sync*"
---
# This rule only loads when editing database or sync files
```

This reduces context usage for domain-specific rules. See [Chapter 46](46-advanced-configuration-patterns.md) for details.

---

## Rule Summaries

### 1. Agent-First Workflow (`global/agent-usage.md`)

Forces Claude to delegate tasks to specialized agents rather than working directly. Defines a routing table mapping task types to primary and secondary agents.

**Key enforcement**: "ALWAYS use agents for EVERY task. NEVER work directly without agents."

### 2. Check Before Building (`global/context-checking.md`)

Before building anything, search for existing implementations. Five mandatory checks: search context, search codebase, check skills, check documentation, ask agents.

**Key enforcement**: "GATE 1: Does this already exist?"

**Evidence**: Saves 50-240 minutes per task (5-10 minutes to check vs 1-4 hours to rebuild).

### 3. Validation Workflow (`global/validation-workflow.md`)

A 7-step workflow (Understand, Search, Validate, Design, Implement, Test, Refactor) with 5 pre-implementation gates:

| Gate | Check              | Pass Criteria          |
| ---- | ------------------ | ---------------------- |
| 1    | Existing solution? | Via agents             |
| 2    | Complexity?        | Under 100 lines        |
| 3    | Modularity?        | Single responsibility  |
| 4    | Best practices?    | KISS/DRY/SOLID         |
| 5    | Performance?       | Under 1k tokens impact |

### 4. Session Protocol (`process/session-protocol.md`)

At session start: `git status`, check features, select ONE task. At session end: update status, checkpoint commit, never stop mid-feature. At 75% context: commit and start fresh.

### 5. Safety Rules (`process/safety-rules.md`)

Never use `killall node`, `pkill -f node`, or similar blanket kill commands. These crash WSL, VS Code, and Claude Code. Always kill by specific PID.

### 6. No Mock Data (`quality/no-mock-data.md`)

All data must come from real APIs, databases, or services. When data is unavailable, return honest errors. When a feature is not implemented, say so. Never insert placeholder data.

**Includes**: Chain-of-Verification (CoVe) -- before any data processing, verify the real source exists.

### 7. Anti-Over-Engineering (`planning/anti-overengineering.md`)

Six checks before any plan: Simplicity (under 50 lines?), Reuse (already exists?), Modular (single responsibility?), Budget (cost vs alternatives?), Dependencies (zero new packages?), Best Practices (KISS/DRY/SOLID/YAGNI?).

**Evidence**: 80% code reduction, 77% cost savings on a cron migration.

### 8. Plan Checklist (`planning/plan-checklist.md`)

Every plan must include 11 sections: Requirements Clarification, Existing Code Check, Over-Engineering Prevention, Best Practices, Architecture, Documentation Plan, Testing Plan, Debugging and Logging, File Change Summary, TL;DR, and Modularity Enforcement (blocking gate with 4 sub-checks: file size, layer separation, extraction, god file prevention).

### 9. Plan Metadata (`planning/plan-link.md`)

Plan files get random names. This rule requires a metadata header with: plan file path, branch + timestamp, topic summary, and searchable keywords.

### 10. MCP-First (`mcp/mcp-first.md`)

Before installing any tool via npm/pip, check if an MCP equivalent exists. Common MCP tools: Playwright for browser automation, PostgreSQL MCP for database queries, Perplexity for web search.

### 11. Agent Routing (`mcp/agent-routing.md`)

Query classification (depth-first, breadth-first, straightforward) with budget controls. Simple tasks get 1 agent with under 5 tool calls. Complex tasks get 3-5 agents with up to 10 calls each.

### 12. Quality Standards (`quality/standards.md`)

Accuracy targets (99.997% technical accuracy) and mandatory self-verification before asking users to test. Three tiers: infrastructure check, integration check, documentation.

### 13. Technical Patterns (`technical/patterns.md`)

Format-first development workflow (format, lint, test, commit). Modular development rules (max 500 lines per file, single responsibility). SOLID/DRY/KISS/YAGNI enforcement.

### 14. Versioning (`documentation/versioning.md`)

`v{MAJOR}.{MINOR}.{PATCH}` format. ISO 8601 dates. Supersession tracking for deprecated files. Changelog format with Added/Changed/Deprecated/Removed/Fixed/Security sections.

### 15. Project Registry (`projects/registry.md`)

Inventory of all your projects with repo URLs, local paths, tech stacks, and port numbers. Prevents port conflicts and gives Claude instant context about your workspace.

---

## Verification

After adopting rules, verify they are being loaded:

```bash
# Count rule files in your project
find .claude/rules -name "*.md" | wc -l
# Expected: 15 (or however many you adopted)

# Verify directory structure
ls -R .claude/rules/

# Test that Claude sees them (in a Claude Code session)
# Ask: "What rules are you loading from .claude/rules/?"
```

After adopting commands:

```bash
# List available commands
ls .claude/commands/*.md

# Test in Claude Code session:
# Type: /session-start
# Type: /slashes
```

---

## References

- [Chapter 26: Rules System](26-claude-code-rules-system.md) -- How rules work in Claude Code
- [Chapter 45: Plan Mode Quality Checklist](45-plan-mode-checklist.md) -- Deep dive on plan checklist
- [Chapter 46: Advanced Configuration Patterns](46-advanced-configuration-patterns.md) -- Global vs project scope, path-specific rules
- [Official Rules Docs](https://docs.anthropic.com/en/docs/claude-code/memory#rules) -- Anthropic's rules documentation
- Template directory: `template/.claude/rules/` and `template/.claude/commands/`
