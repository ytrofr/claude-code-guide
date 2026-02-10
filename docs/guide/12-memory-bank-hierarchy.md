# Chapter 12: Memory Bank Hierarchy

**Purpose**: 4-tier knowledge organization for optimal context loading
**Source**: Production validation (34% token reduction, zero functionality loss)
**Pattern**: always -> learned -> ondemand -> blueprints

---

## Why a Memory Bank?

Claude Code reads your `CLAUDE.md` and any `@`-imported files at the start of every conversation. As your project grows, you accumulate patterns, decisions, fixes, and reference docs. Without organization, you either load everything (wasting context window) or load nothing (losing knowledge).

The memory bank solves this with a 4-tier hierarchy: always-loaded essentials at the top, rarely-needed archives at the bottom. Each tier has a clear purpose, token budget, and loading strategy.

---

## 4-Tier Structure

| Tier               | Directory                 | Auto-Load             | Token Budget       | Purpose                            |
| ------------------ | ------------------------- | --------------------- | ------------------ | ---------------------------------- |
| **1. always/**     | `memory-bank/always/`     | Yes (via @ imports)   | <40k tokens        | Core patterns needed every session |
| **2. learned/**    | `memory-bank/learned/`    | No (search on demand) | 5-10k per lookup   | Solved problems, reusable patterns |
| **3. ondemand/**   | `memory-bank/ondemand/`   | No (load when needed) | 15-25k per section | Domain-specific reference docs     |
| **4. blueprints/** | `memory-bank/blueprints/` | No (rare use)         | 20-60k when needed | Full system recreation guides      |

---

## Tier 1: Always (Auto-Loaded)

These files are `@`-imported in your `CLAUDE.md` and loaded into every conversation automatically.

**What goes here**:

- Core patterns and rules (single source of truth)
- System status and health (current state of your project)
- Context routing rules (how to find other information)
- Session protocol (start/end procedures)

**Example files**:

```
memory-bank/always/
├── CORE-PATTERNS.md          # Single source of truth for all patterns
├── CONTEXT-ROUTER-MINI.md    # How to find information across tiers
├── system-status.json        # Current feature status, recent fixes
└── SESSION-PROTOCOL-MINI.md  # Session start/end commands
```

**Key rule**: Keep Tier 1 files compact. Use MINI versions (summaries) instead of full documents. Every token here is loaded in every conversation.

**@ import syntax** (in CLAUDE.md):

```markdown
@memory-bank/always/CORE-PATTERNS.md
@memory-bank/always/system-status.json
```

---

## Tier 2: Learned (On-Demand Lookup)

Entries that document solved problems, discovered patterns, and implementation decisions. Not auto-loaded, but searchable when needed.

**What goes here**:

- Bug fix documentation (what broke, why, how it was fixed)
- Implementation patterns (approaches that worked)
- Investigation results (data analysis, root cause findings)
- Decision records (why a particular approach was chosen)

**Naming convention**: `entry-NNN-descriptive-name.md`

```
memory-bank/learned/
├── entry-179-hooks-implementation.md
├── entry-296-pure-gemini-migration.md
├── entry-314-vertex-ai-cost-crisis.md
└── TIER-2-REGISTRY-BY-DOMAIN.md      # Index for finding entries
```

**How to access**: Claude searches these files with grep or reads specific entries when a topic comes up. A registry file helps navigate by domain (database, deployment, AI, etc.).

---

## Tier 3: Ondemand (Domain-Specific Reference)

Comprehensive reference documentation organized by domain. Loaded only when working in that specific area.

**What goes here**:

- Full API endpoint documentation
- Complete database schemas
- Detailed deployment procedures
- Domain-specific patterns

```
memory-bank/ondemand/
├── api/              # API endpoint details, auth patterns
├── database/         # Full schema, sync patterns, credentials
├── deployment/       # CI/CD procedures, Cloud Run guides
└── skills-dev/       # Skill creation standards
```

**Loading strategy**: Use offset+limit for large files instead of loading the entire document:

```
Read(file="api-authority.md", offset=30, limit=214)
```

---

## Tier 4: Blueprints (System Recreation)

Complete guides for recreating major systems from scratch. Only needed when rebuilding or deeply understanding architecture.

**What goes here**:

- System architecture blueprints
- Full recreation guides with step-by-step instructions
- Historical context for major design decisions

```
memory-bank/blueprints/
├── system/
│   └── COMPLETE-SYSTEM-BLUEPRINT.md
└── Library/
    └── context/
        └── CONTEXT-SYSTEM-BLUEPRINT.md
```

---

## Setting Up a Memory Bank

### Step 1: Create the directory structure

```bash
mkdir -p memory-bank/{always,learned,ondemand,blueprints}
```

### Step 2: Create your core patterns file

```markdown
# CORE-PATTERNS.md - Single Source of Truth

## Project Patterns

- Port: 8080
- Database: PostgreSQL
- API style: REST with snake_case

## Key Rules

- Always validate input before database operations
- Use environment variables for all credentials
- Test locally before deploying
```

### Step 3: Create a system status file

```json
{
  "last_updated": "2026-02-10",
  "current_sprint": "Feature X implementation",
  "system_health": {
    "production": { "status": "operational" },
    "staging": { "status": "operational" }
  },
  "recent_fixes": []
}
```

### Step 4: Add @ imports to CLAUDE.md

```markdown
## Auto-loaded Context

@memory-bank/always/CORE-PATTERNS.md
@memory-bank/always/system-status.json
```

---

## Token Budget Management

| Level                  | Budget         | Rule                                      |
| ---------------------- | -------------- | ----------------------------------------- |
| Always-loaded (Tier 1) | <40k tokens    | Every token here costs every conversation |
| Per-request (Tier 2-3) | <50k tokens    | Load only what the current task needs     |
| Session total          | <100k tokens   | Quality degrades beyond this              |
| Quality threshold      | 75% of context | Stop and checkpoint at 75% usage          |

**Estimating tokens**: Roughly 4 characters = 1 token. A 500-line markdown file is approximately 5-10k tokens.

---

## Best Practices

**Single source of truth**: Define each pattern in exactly one place (usually `CORE-PATTERNS.md`). Other files should reference it, not duplicate it. Duplication leads to contradictions when one copy is updated but not the other.

**Progressive disclosure**: Start with MINI summaries in Tier 1. When Claude needs more detail, it reads the full file from Tier 2 or 3. This keeps the always-loaded context small while making deep knowledge accessible. See [Chapter 15: Progressive Disclosure](15-progressive-disclosure.md).

**Entry numbering for cross-references**: Use stable entry numbers (`entry-179`, `entry-296`) so references remain valid when file names change. Keep a registry file that maps entry numbers to topics and file paths.

**Avoid loading everything**: Resist the temptation to `@`-import all your documentation. More context does not mean better results. Anthropic research shows that quality actually improves when you load less but more relevant context.

---

## Multi-Branch Projects

For projects with multiple branches (dev-Data, dev-UI, etc.):

See **[Chapter 29: Branch Context System](29-branch-context-system.md)** for:

- CONTEXT-MANIFEST.json per branch
- @ import enforcement
- 47-70% token savings per branch

---

**Previous**: [06: MCP Integration](06-mcp-integration.md)
**Next**: [13: Claude Code Hooks](13-claude-code-hooks.md)
