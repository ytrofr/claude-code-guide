# Claude Code Implementation Guide

**A comprehensive, battle-tested guide for setting up Claude Code projects**

Based on proven patterns from LimorAI (97 components, 162+ documented patterns, 561-709 hours/year ROI), this guide provides everything you need to create powerful Claude Code projects for yourself and your team.

---

## 🆕 Latest Additions (January 2026)

### Context Architecture System ⭐⭐⭐ UPDATED (Jan 26, 2026)
| Guide | Description | Evidence |
|-------|-------------|----------|
| [**Branch Context System**](docs/guide/29-branch-context-system.md) | CONTEXT-MANIFEST.json + @ imports for per-branch context loading | **47-70% token savings** per branch 🏆🏆🏆 **FIXED: Dynamic @ import mechanism** |
| [Blueprint Auto-Loading](docs/guide/30-blueprint-auto-loading.md) | blueprint-registry.json for per-branch blueprint loading | Auto-load relevant blueprints |
| [Branch-Aware Development](docs/guide/31-branch-aware-development.md) | branch-variables.json, skill weighting, templates | +20 skill ranking bonus |
| [Document Automation](docs/guide/32-document-automation.md) | Pattern analysis engine with 5-type suggestions | 67% faster documentation |
| [**Branch-Specific Skill Curation**](docs/guide/33-branch-specific-skill-curation.md) | Two-tier skill display: 🎯 BRANCH SKILLS + 🔍 KEYWORD MATCHES | **80% faster skill discovery** |
| [**Basic Memory MCP Integration**](docs/guide/34-basic-memory-mcp-integration.md) | Semantic observations, relations, session-start hook, proactive triggers | **30-50h/year savings** 🆕 |

**🎯 USE THESE GUIDES** to implement proper context architecture for multi-branch projects!

**Key Features**:
- ✅ Per-branch context loading (only load what you need)
- ✅ @ import enforcement via session-start hook (**CRITICAL**: hook must WRITE to CLAUDE.md, not just display!)
- ✅ Blueprint auto-loading per branch
- ✅ Skill weighting (+20 bonus for branch-specific skills)
- ✅ /document with pattern analysis (skill/rule/blueprint suggestions)
- ✅ Branch templates (Instructions, ROADMAP, CONTEXT-MANIFEST)
- ✅ **Two-tier skill display** (curated branch skills + keyword matches)
- ✅ **Basic Memory MCP** with semantic patterns for knowledge retrieval 🆕

**Evidence**: LIMOR AI MASTER-PLAN 100% complete (8 phases) + Entry #283

---

### Pre-Prompt Hook Complete Guide ⭐⭐⭐ (Jan 15, 2026)
| Guide | Description | Evidence |
|-------|-------------|----------|
| [**Pre-Prompt Hook Complete Guide**](docs/pre-prompt-hook-complete-guide.md) | **COMPLETE step-by-step implementation** - Architecture, setup, cache management, testing, monitoring, troubleshooting | **370x optimization** (50s → 136ms), **88.2% accuracy** (Entry #271 + #272) 🏆🏆🏆 |

### Skill Optimization Patterns ⭐ (Jan 8, 2026)
| Guide | Description | Evidence |
|-------|-------------|----------|
| [Skill Optimization Patterns](docs/guide/28-skill-optimization-patterns.md) | context:fork, agent: routing, user-invocable:false, wildcard permissions | 171 skills optimized 🏆 |

### Fast Cloud Run Deployment (Jan 7, 2026)
| Guide | Description | Evidence |
|-------|-------------|------------|
| [Fast Cloud Run Deployment](docs/guide/27-fast-cloud-run-deployment.md) | Pre-built image deployment, 78% faster (3-5 min → ~1 min) | Entry #248, #251 🏆 |

### Claude Code Rules System (Jan 6, 2026)
| Guide | Description | Evidence |
|-------|-------------|------------|
| [Claude Code Rules System](docs/guide/26-claude-code-rules-system.md) | `.claude/rules/` hierarchy, path-specific rules, context optimization | Entry #245, #247 🏆 |
| [Rules Template](template/.claude/rules/) | Ready-to-use rules directory with examples | Official docs ✅ |

**Official Docs**: https://code.claude.com/docs/en/memory

### Skill Enhancement & Best Practices (Jan 5, 2026)
| Guide | Description | Evidence |
|-------|-------------|------------|
| [Skill Keyword Enhancement](docs/guide/24-skill-keyword-enhancement-methodology.md) | 20+ synonym patterns, "Use when" scoring, monthly maintenance | Entry #244 🏆 |
| [Best Practices Reference](docs/guide/25-best-practices-reference.md) | 33 Anthropic articles indexed, extraction workflow | Entry #189 |
| [skill-maintenance-skill](skills-library/workflows/skill-maintenance-skill/) | Monthly audit templates, gap detection scripts | 100% coverage |

### Pre-prompt Optimization
| Guide | Description | Evidence |
|-------|-------------|------------|
| [Pre-prompt Optimization](docs/guide/21-pre-prompt-optimization.md) | 68% reduction (28k→9k chars), skills-first ordering | Entry #228 🏆 |
| [wshobson Marketplace](docs/guide/22-wshobson-marketplace-integration.md) | 67 plugins, 99 agents, 107 skills integration | Entry #227 |
| [Session Documentation](docs/guide/23-session-documentation-skill.md) | Automates Entry + roadmap + status (67% faster) | NEW |

### December 2025
| Guide | Description | Evidence |
|-------|-------------|------------|
| [Skills Filtering Optimization](docs/guide/20-skills-filtering-optimization.md) | Score-at-match-time, 93% noise reduction | Entry #229 🏆 |
| [Playwright E2E Testing](docs/guide/19-playwright-e2e-testing.md) | Browser automation + E2E test patterns | 176/176 tests passing 🏆 |
| [Perplexity Cost Optimization](docs/guide/18-perplexity-cost-optimization.md) | Cache-first pattern for 80%+ savings | 10+ cached results, $4+/mo saved |
| [Skill Detection Enhancement](docs/guide/17-skill-detection-enhancement.md) | 4-phase synonym/stem/multi-word matching | 310→700/700 (100%) 🏆 |
| [Claude Code Hooks](docs/guide/13-claude-code-hooks.md) | 8 hook types for workflow automation | 96% validation, 6-8h/year ROI |
| [Progressive Disclosure](docs/guide/15-progressive-disclosure.md) | Skills with references/ for token efficiency | 53% savings confirmed |
| [Git vs Claude Hooks](docs/guide/14-git-vs-claude-hooks-distinction.md) | Clear distinction guide | Prevent confusion |
| [MCP Integration](docs/guide/06-mcp-integration.md) | Essential MCPs (PostgreSQL, GitHub, Memory) | Zero-token validation |
| [Memory Bank Hierarchy](docs/guide/12-memory-bank-hierarchy.md) | 4-tier knowledge organization | 34% token reduction |

**Source**: [Anthropic hooks blog](https://claude.com/blog/how-to-configure-hooks) + [Building skills blog](https://claude.com/blog/building-skills-for-claude-code)

**Templates**: `template/.claude/hooks/` (4 scripts) | **Example**: `examples/limor-ai-claude-hooks/`

---

## Quick Navigation

### 🚀 Getting Started (Choose Your Path)

**New User? Start Here**:
- [30-Minute Quick Start](docs/quick-start.md) - Get productive immediately
- [**Pre-Prompt Hook Complete Guide**](docs/pre-prompt-hook-complete-guide.md) 🏆 - Implement skill activation system
- [Interactive Checklist](web/index.html) - Track your setup progress
- [Clone Template](template/) - Pre-configured starter project

**Experienced User?**:
- [Complete Guide](docs/guide/) - In-depth documentation
- [Skills Library](skills-library/) - 20+ proven workflow patterns
- [MCP Configurations](mcp-configs/) - Ready-to-use MCP setups

**Multi-Branch Projects?**:
- [**Branch Context System**](docs/guide/29-branch-context-system.md) 🏆 - Per-branch context loading
- [Blueprint Auto-Loading](docs/guide/30-blueprint-auto-loading.md) - Per-branch blueprints
- [Branch-Aware Development](docs/guide/31-branch-aware-development.md) - Skill weighting
- [**Branch-Specific Skill Curation**](docs/guide/33-branch-specific-skill-curation.md) - Two-tier skill display
- [**Basic Memory MCP Integration**](docs/guide/34-basic-memory-mcp-integration.md) 🆕 - Semantic knowledge retrieval

---

## The 4-Format System

This guide uses **4 coordinated formats** that work together:

### 1. Living Markdown Guide 📚
**Location**: [docs/guide/](docs/guide/)

Complete reference documentation covering setup, patterns, and advanced topics.

| Guide | Purpose |
|-------|---------|
| [02-minimal-setup.md](docs/guide/02-minimal-setup.md) | Core setup (START HERE) |
| [04-task-tracking-system.md](docs/guide/04-task-tracking-system.md) | Roadmap/task management |
| [05-developer-mode-ui-feedback-system.md](docs/guide/05-developer-mode-ui-feedback-system.md) | Visual UI debugging |
| [17-skill-detection-enhancement.md](docs/guide/17-skill-detection-enhancement.md) | 4-phase skill detection (100% accuracy) |
| [18-perplexity-cost-optimization.md](docs/guide/18-perplexity-cost-optimization.md) | 80%+ cost savings |
| [19-playwright-e2e-testing.md](docs/guide/19-playwright-e2e-testing.md) | Browser automation & E2E |
| [20-skills-filtering-optimization.md](docs/guide/20-skills-filtering-optimization.md) | 93% noise reduction |
| [21-pre-prompt-optimization.md](docs/guide/21-pre-prompt-optimization.md) | 68% pre-prompt reduction |
| [22-wshobson-marketplace-integration.md](docs/guide/22-wshobson-marketplace-integration.md) | Agent marketplace |
| [23-session-documentation-skill.md](docs/guide/23-session-documentation-skill.md) | Automated documentation |
| [24-skill-keyword-enhancement-methodology.md](docs/guide/24-skill-keyword-enhancement-methodology.md) | Synonym expansion |
| [25-best-practices-reference.md](docs/guide/25-best-practices-reference.md) | 33 Anthropic articles |
| [26-claude-code-rules-system.md](docs/guide/26-claude-code-rules-system.md) | `.claude/rules/` hierarchy |
| [27-fast-cloud-run-deployment.md](docs/guide/27-fast-cloud-run-deployment.md) | 78% faster deployments |
| [28-skill-optimization-patterns.md](docs/guide/28-skill-optimization-patterns.md) | context:fork, agent:, wildcards |
| [29-branch-context-system.md](docs/guide/29-branch-context-system.md) | CONTEXT-MANIFEST + @ imports |
| [30-blueprint-auto-loading.md](docs/guide/30-blueprint-auto-loading.md) | Per-branch blueprints |
| [31-branch-aware-development.md](docs/guide/31-branch-aware-development.md) | Skill weighting + templates |
| [32-document-automation.md](docs/guide/32-document-automation.md) | Pattern analysis engine |
| [33-branch-specific-skill-curation.md](docs/guide/33-branch-specific-skill-curation.md) | Two-tier skill display |
| [34-basic-memory-mcp-integration.md](docs/guide/34-basic-memory-mcp-integration.md) | Semantic observations & relations 🆕 |

**Best For**: Understanding concepts, deep dives, team onboarding

### 2. Skills Library 🎯
**Location**: [skills-library/](skills-library/)

Executable workflow patterns organized by phase:
- **starter/** - 3 essential skills (Day 1)
- **troubleshooting/** - 5-10 debugging skills (Week 1)
- **workflows/** - 8-12 procedure skills (Week 2-3)
  - **perplexity-cache-skill/** - Cache-first pattern for cost optimization
  - **playwright-e2e-skill/** - Browser automation & E2E testing
  - **session-documentation-skill/** - Automated session docs
  - **skill-maintenance-skill/** - Monthly audit templates
  - **basic-memory-semantic-patterns-skill/** - Semantic observations & relations 🆕
- **specialized/** - Domain-specific skills (Month 2+)

**Best For**: Active troubleshooting, instant workflow access
**Activation Rate**: 84% when using numbered triggers pattern

### 3. Template Repository 📦
**Location**: [template/](template/)

Clone-and-go starter kit with pre-configured:
- `.claude/CLAUDE.md` - Project context (includes Perplexity cache-first rule)
- `.claude/mcp_servers.json.template` - MCP configuration
- `.claude/rules/` - Auto-discovered rules (path-specific patterns)
  - `mcp/memory-usage.md` - Basic Memory proactive triggers 🆕
- `memory-bank/always/` - Core files (CORE-PATTERNS, system-status)
- `memory-bank/always/branch-variables.json` - Branch-specific skill curation
- `memory-bank/blueprints/blueprint-registry.json` - Blueprint auto-loading
- `.claude/hooks/` - Automation hooks (4 scripts including pre-prompt.sh)
- `.claude/skills/starter/` - 3 essential skills
  - `basic-memory-semantic-patterns-skill/` - Semantic patterns 🆕
- `CURRENT/branch-template/` - Branch structure templates

**Best For**: Starting new projects, team standardization
**Setup Time**: 30 minutes to working system

### 4. Interactive Checklist ✅
**Location**: [web/index.html](web/index.html)

Web-based progress tracker with:
- Phase 0-3 checklists (30 min → full ecosystem)
- Validation status indicators
- localStorage progress persistence
- Direct links to documentation

**Best For**: Tracking setup progress, ensuring nothing is missed
**Technology**: Pure HTML/CSS/JS (no build step)

---

## What You'll Learn

### Core Concepts
- **CLAUDE.md Power** - Auto-loaded project context
- **Rules System** - `.claude/rules/` for path-specific patterns
- **Memory Bank Hierarchy** - 4-tier knowledge organization (always → learned → ondemand → blueprints)
- **Branch Context System** - CONTEXT-MANIFEST.json + @ imports (47-70% savings)
- **Blueprint Auto-Loading** - Per-branch blueprint loading via registry
- **Branch-Aware Development** - Skill weighting, branch templates
- **Branch-Specific Skill Curation** - Two-tier display (🎯 BRANCH + 🔍 KEYWORD)
- **Basic Memory MCP** - Semantic observations, relations, knowledge retrieval 🆕
- **Skills Activation** - 84% activation rate with numbered triggers
- **Pre-Prompt Hook System** - 370x optimization + 88.2% accuracy (COMPLETE GUIDE!) 🏆
- **Skill Detection Enhancement** - 4-phase matching for 100% accuracy
- **Skill Keyword Enhancement** - 20+ synonym patterns, "Use when" scoring
- **Skill Optimization** - context:fork, agent:, user-invocable: patterns
- **Pre-prompt Optimization** - 68% reduction with skills-first ordering
- **MCP Integration** - GitHub, Memory Bank, PostgreSQL, Perplexity, Playwright
- **wshobson Marketplace** - 273 pre-built components
- **Entry Numbering** - Stable cross-referencing across sessions
- **Perplexity Cost Optimization** - 80%+ savings with cache-first pattern
- **Playwright E2E Testing** - Browser automation with 100% test success
- **Session Documentation** - Automated Entry + roadmap + status
- **Document Automation** - Pattern analysis with 5-type suggestions
- **Best Practices Reference** - 33 Anthropic articles indexed
- **Context Optimization** - 75% threshold, cross-reference patterns
- **Fast Deployment** - 78% faster Cloud Run deploys with pre-built images

### Proven Patterns
- **Anthropic Best Practices** - Session protocol, incremental progress, JSON feature tracking
- **Skills Framework** - YAML frontmatter, Failed Attempts tables, evidence-based design
- **Pre-Prompt Hook Architecture** - Hybrid cache, scoring algorithm, proactive recommendations 🏆
- **Branch Context Architecture** - Manifest-driven loading, @ imports, per-branch optimization
- **Two-Tier Skill Display** - Curated branch skills + dynamic keyword matches
- **Basic Memory Semantic Patterns** - [decision], [technique], [issue] observations 🆕
- **Skill Frontmatter** - context:fork, agent:, user-invocable: for optimization
- **Rules Hierarchy** - User → Project rules priority, path-specific targeting
- **4-Tier Context** - 34-62% token reduction with zero functionality loss
- **Validation First** - Scripts prevent 90% of common setup errors
- **Team Collaboration** - Shared vs personal configuration patterns
- **Research Caching** - Never pay twice for the same Perplexity query
- **E2E Testing** - Automated browser testing with Playwright
- **Monthly Maintenance** - 30 min/month keeps 100% skill coverage
- **Pre-built Images** - Skip Cloud Build for 78% faster deployments

---

## Quick Start (30 Minutes)

```bash
# 1. Clone the template
cp -r template/ ~/my-new-project/.claude
cd ~/my-new-project

# 2. Validate structure
./scripts/validate-setup.sh

# 3. Customize core patterns
edit memory-bank/always/CORE-PATTERNS.md

# 4. Configure GitHub MCP
cp .claude/mcp_servers.json.template .claude/mcp_servers.json
# Add your GitHub token

# 5. Set up pre-prompt hook (RECOMMENDED)
# Follow: docs/pre-prompt-hook-complete-guide.md
cp template/.claude/hooks/pre-prompt.sh .claude/hooks/
chmod +x .claude/hooks/pre-prompt.sh

# 6. Create first skill
cp template/.claude/skills/starter/session-start-protocol-skill.md \
   ~/.claude/skills/

# 7. Set up branch context (OPTIONAL - for multi-branch projects)
# Follow: docs/guide/29-branch-context-system.md
mkdir -p CURRENT/$(git branch --show-current)
cp template/CURRENT/branch-template/CONTEXT-MANIFEST.json \
   CURRENT/$(git branch --show-current)/

# 8. Set up branch-specific skills (OPTIONAL - for multi-branch projects)
# Follow: docs/guide/33-branch-specific-skill-curation.md
cp template/memory-bank/always/branch-variables.json \
   memory-bank/always/

# 9. Set up Basic Memory (OPTIONAL - for knowledge retrieval)
# Follow: docs/guide/34-basic-memory-mcp-integration.md
cp template/.claude/rules/mcp/memory-usage.md .claude/rules/mcp/
mkdir -p ~/basic-memory/{patterns,fixes,decisions}

# 10. Start Claude Code
claude-code
```

**Validation**: All checks pass in `validate-setup.sh`

---

## Phased Growth Path

### Phase 0: Minimal (30 min)
- ✅ CLAUDE.md + CORE-PATTERNS
- ✅ 3 starter skills
- ✅ GitHub MCP only
- ✅ Basic validation

**Value**: Consistent responses, safe git operations, basic troubleshooting

### Phase 1: Essential (Week 1, 2-3 hours)
- ➕ Memory Bank MCP (session persistence)
- ➕ **Basic Memory MCP** (semantic knowledge retrieval) 🆕
- ➕ 5 troubleshooting skills
- ➕ **Pre-prompt hook** (84% activation + 4-phase detection + 68% reduction) 🏆
- ➕ TIER-2-REGISTRY setup
- ➕ Perplexity MCP with cache-first rule
- ➕ `.claude/rules/` directory

**Value**: 3x faster debugging, institutional knowledge capture, 100% skill detection, 80%+ research cost savings, **30-50h/year knowledge retrieval savings** 🆕

### Phase 2: Productive (Week 2-3, 4-6 hours)
- ➕ PostgreSQL MCP (3 databases)
- ➕ Playwright MCP (browser automation)
- ➕ wshobson marketplace (273 components)
- ➕ 8 workflow skills
- ➕ Feature blueprints
- ➕ Domain authorities
- ➕ Fast deployment scripts
- ➕ Skill optimization (context:fork, agent:)
- ➕ **Branch context system** (CONTEXT-MANIFEST + @ imports)
- ➕ **Branch-specific skill curation** (two-tier display)

**Value**: Database visibility, E2E testing, agent marketplace, system recreation, 50%+ time savings, 78% faster deployments, **47-70% token savings per branch**, **80% faster skill discovery**

### Phase 3: Advanced (Month 2+, organic)
- ➕ Custom MCP servers
- ➕ 20-30 skill library
- ➕ Full agent ecosystem
- ➕ Complete 4-tier memory bank
- ➕ Session documentation skill
- ➕ Monthly skill maintenance
- ➕ **Blueprint auto-loading** (per-branch blueprints)
- ➕ **Document automation** (pattern analysis engine)
- ➕ **Basic Memory semantic patterns** (knowledge graph) 🆕

**Value**: 561-709 hours/year ROI, enterprise automation

---

## Repository Contents

```
claude-code-implementation-guide/
├── README.md                    # This file
├── LICENSE.md                   # MIT License
├── docs/
│   ├── quick-start.md          # 30-minute minimal path
│   ├── setup-checklist.md      # Text-based checklist
│   ├── pre-prompt-hook-complete-guide.md  🏆🏆🏆 COMPLETE IMPLEMENTATION GUIDE
│   ├── skill-activation-system.md  # Architecture overview
│   └── guide/                  # Living documentation
│       ├── 02-minimal-setup.md          ⭐ START HERE
│       ├── 04-task-tracking-system.md   Task/roadmap management
│       ├── 05-developer-mode-ui-feedback-system.md  Visual debugging
│       ├── 17-skill-detection-enhancement.md  🏆 100% skill detection
│       ├── 18-perplexity-cost-optimization.md  80%+ cost savings
│       ├── 19-playwright-e2e-testing.md  Browser automation & E2E
│       ├── 20-skills-filtering-optimization.md  93% noise reduction
│       ├── 21-pre-prompt-optimization.md  68% reduction
│       ├── 22-wshobson-marketplace-integration.md  273 components
│       ├── 23-session-documentation-skill.md  Automated docs
│       ├── 24-skill-keyword-enhancement-methodology.md  Synonym expansion
│       ├── 25-best-practices-reference.md  33 Anthropic articles
│       ├── 26-claude-code-rules-system.md  Rules hierarchy
│       ├── 27-fast-cloud-run-deployment.md  78% faster deploys
│       ├── 28-skill-optimization-patterns.md  context:fork, agent:
│       ├── 29-branch-context-system.md  CONTEXT-MANIFEST + @ imports
│       ├── 30-blueprint-auto-loading.md  Per-branch blueprints
│       ├── 31-branch-aware-development.md  Skill weighting
│       ├── 32-document-automation.md  Pattern analysis engine
│       ├── 33-branch-specific-skill-curation.md  Two-tier skill display
│       └── 34-basic-memory-mcp-integration.md  🆕 Semantic knowledge retrieval
├── template/                    # Clone-and-go starter
│   ├── .claude/
│   │   ├── CLAUDE.md           # Includes cache-first rule
│   │   ├── mcp_servers.json.template
│   │   ├── rules/              Auto-discovered rules
│   │   │   ├── README.md
│   │   │   ├── src-code.md     # Path-specific
│   │   │   ├── tests.md        # Path-specific
│   │   │   ├── mcp/
│   │   │   │   └── memory-usage.md  🆕 Basic Memory proactive triggers
│   │   │   └── domain/
│   │   │       └── patterns.md
│   │   ├── skills/starter/
│   │   │   └── basic-memory-semantic-patterns-skill/  🆕 Semantic patterns
│   │   └── hooks/
│   │       ├── session-start.sh
│   │       ├── pre-compact.sh
│   │       ├── stop-hook.sh
│   │       └── pre-prompt.sh   🏆 4-phase skill detection + 68% reduction
│   ├── memory-bank/
│   │   ├── always/
│   │   │   └── branch-variables.json  Branch-specific skill curation
│   │   └── blueprints/
│   │       └── blueprint-registry.json  Blueprint auto-loading
│   └── CURRENT/
│       └── branch-template/    Branch structure templates
│           ├── CONTEXT-MANIFEST.json
│           ├── branch-template-Instructions.md
│           └── branch-template-ROADMAP.md
├── skills-library/              # Complete skills reference
│   ├── starter/                 # 3 essential (Phase 0)
│   ├── troubleshooting/         # 5-10 skills (Phase 1)
│   ├── workflows/               # 8-12 skills (Phase 2)
│   │   ├── perplexity-cache-skill/  Cost optimization
│   │   ├── playwright-e2e-skill/    Browser automation
│   │   ├── session-documentation-skill/  Automated docs
│   │   ├── skill-maintenance-skill/  Monthly audits
│   │   └── basic-memory-semantic-patterns-skill/  🆕 Semantic knowledge
│   └── specialized/             # Domain-specific (Phase 3)
├── mcp-configs/                 # MCP server configurations
│   ├── minimal/                 # GitHub only
│   ├── essential/               # +Memory Bank
│   ├── productive/              # +PostgreSQL, +Perplexity, +Playwright
│   └── advanced/                # +Custom servers
├── scripts/                     # Validation & setup tools
│   ├── validate-setup.sh        ⭐ Master validator
│   ├── check-mcp.sh
│   └── setup-wizard.sh
├── examples/                    # Real-world examples
│   ├── minimal-project/
│   ├── team-setup/
│   └── migration-scenarios/
└── web/                         # Interactive checklist
    ├── index.html
    ├── checklist.js
    └── styles.css
```

---

## For Team Members

**Setting Up Your First Project**:
1. Read [Quick Start Guide](docs/quick-start.md) (10 min)
2. **Read [Pre-Prompt Hook Complete Guide](docs/pre-prompt-hook-complete-guide.md)** (20 min) 🏆
3. Clone [Template](template/) to your project
4. Run [Setup Wizard](scripts/setup-wizard.sh)
5. Track progress with [Interactive Checklist](web/index.html)

**For Multi-Branch Projects**:
1. Read [Branch Context System](docs/guide/29-branch-context-system.md) (15 min)
2. Read [Branch-Specific Skill Curation](docs/guide/33-branch-specific-skill-curation.md) (10 min)
3. Read [Basic Memory MCP Integration](docs/guide/34-basic-memory-mcp-integration.md) (15 min) 🆕
4. Create CONTEXT-MANIFEST.json per branch
5. Set up branch-variables.json for skill curation
6. Set up Basic Memory for knowledge retrieval 🆕

**Contributing to This Guide**:
- See CONTRIBUTING.md (coming soon)
- All improvements welcome
- Follow the established patterns

---

## Success Metrics

### Minimal Setup (Phase 0):
- ⏱️ Time to value: < 30 minutes
- ✅ Validation: `./scripts/validate-setup.sh` passes
- 🎯 Outcome: Working Claude Code with pattern compliance

### Full Implementation (Phase 3):
- ⏱️ Setup time: 8-12 hours total
- ✅ Components: 20+ skills, 5 MCPs, complete memory bank
- 🎯 ROI: 50-500+ hours/year saved (scales with usage)
- 🏆 **Pre-Prompt Hook: 88.2% accuracy + 370x performance** (Entry #271 + #272)
- 🏆 Skill Detection: 100% accuracy with 4-phase enhancement
- 🏆 **Branch Context: 47-70% token savings per branch** (Entry #282)
- 🏆 **Skill Curation: 80% faster skill discovery** (two-tier display)
- 🏆 **Basic Memory: 30-50h/year knowledge retrieval** (Entry #283) 🆕
- 💰 Perplexity: 80%+ cost savings with cache-first pattern
- 🧪 E2E Testing: 100% pass rate with Playwright
- 📦 Marketplace: 273 pre-built components available
- 📝 Documentation: 67% faster with session skill
- 🔄 Maintenance: 30 min/month for 100% skill coverage
- 📏 Rules: Path-specific patterns for context efficiency
- 🚀 Deployment: 78% faster with pre-built images
- ⚡ Skill Optimization: context:fork, agent:, wildcards

---

## What Makes This Guide Different

**Battle-Tested**: Based on 162+ documented patterns from real production system
**Research-Backed**: Incorporates Anthropic best practices + Sionic AI skills research
**Proven ROI**: 561-709 hours/year savings validated in source project
**Team-Ready**: Clear separation of personal vs shared configurations
**Phased Approach**: Value in 30 minutes, full power over time
**Validation-First**: Scripts catch 90% of common mistakes before they happen
**Pre-Prompt Hook System**: Complete implementation guide (370x faster, 88.2% accurate) 🏆
**Branch Context System**: 47-70% token savings with CONTEXT-MANIFEST + @ imports
**Two-Tier Skill Display**: 80% faster skill discovery with branch curation
**Basic Memory MCP**: 30-50h/year knowledge retrieval with semantic patterns 🆕
**100% Skill Detection**: 4-phase enhancement achieves perfect matching (Chapter 17)
**93% Noise Reduction**: Score-at-match-time filtering (Chapter 20)
**68% Pre-prompt Reduction**: Skills-first ordering (Chapter 21)
**20+ Synonym Patterns**: Natural language skill activation (Chapter 24)
**33 Articles Indexed**: Anthropic best practices reference (Chapter 25)
**Rules Hierarchy**: Path-specific patterns with user/project priority (Chapter 26)
**Cost-Optimized**: Perplexity caching saves 80%+ on research costs (Chapter 18)
**E2E Testing**: Playwright automation with 176/176 tests passing (Chapter 19)
**Agent Marketplace**: 273 pre-built components from wshobson (Chapter 22)
**Automated Documentation**: 67% faster session docs (Chapter 23)
**Document Automation**: Pattern analysis with 5-type suggestions (Chapter 32)
**Monthly Maintenance**: 30 min/month keeps skills at 100% coverage
**Fast Deployment**: 78% faster Cloud Run deploys with pre-built images (Chapter 27)
**Skill Optimization**: context:fork, agent:, wildcards for advanced skills (Chapter 28)
**Blueprint Auto-Loading**: Per-branch blueprint registry (Chapter 30)

---

## Credits

**Source Project**: LimorAI - Hebrew business intelligence system
**Patterns**: 97+ components (22 skills, 39 agents, 30 MCP tools, 6 plugins)
**Research**: Anthropic Claude 4 Best Practices + Sionic AI Skills Framework
**Marketplace**: [wshobson/agents](https://github.com/wshobson/agents) - 273 components
**Official Docs**: https://code.claude.com/docs/en/memory
**Created**: December 2025
**Updated**: January 2026

---

## License

MIT License - See [LICENSE.md](LICENSE.md)

---

## Quick Links

- [30-Minute Quick Start](docs/quick-start.md) ⭐ START HERE
- [**Pre-Prompt Hook Complete Guide**](docs/pre-prompt-hook-complete-guide.md) 🏆🏆🏆 **FULL IMPLEMENTATION**
- [**Branch Context System**](docs/guide/29-branch-context-system.md) 47-70% token savings
- [**Branch-Specific Skill Curation**](docs/guide/33-branch-specific-skill-curation.md) Two-tier display
- [**Basic Memory MCP Integration**](docs/guide/34-basic-memory-mcp-integration.md) 🆕 Semantic patterns
- [Interactive Checklist](web/index.html)
- [Complete Guide](docs/guide/02-minimal-setup.md)
- [Blueprint Auto-Loading](docs/guide/30-blueprint-auto-loading.md) Per-branch blueprints
- [Branch-Aware Development](docs/guide/31-branch-aware-development.md) Skill weighting
- [Document Automation](docs/guide/32-document-automation.md) Pattern analysis
- [Skill Optimization Patterns](docs/guide/28-skill-optimization-patterns.md) context:fork, agent:, wildcards
- [Fast Cloud Run Deployment](docs/guide/27-fast-cloud-run-deployment.md) 78% faster deploys
- [Claude Code Rules System](docs/guide/26-claude-code-rules-system.md) Path-specific patterns
- [Skill Keyword Enhancement](docs/guide/24-skill-keyword-enhancement-methodology.md) 20+ patterns
- [Best Practices Reference](docs/guide/25-best-practices-reference.md) 33 articles
- [Pre-prompt Optimization](docs/guide/21-pre-prompt-optimization.md) 68% reduction
- [wshobson Marketplace](docs/guide/22-wshobson-marketplace-integration.md) 273 components
- [Session Documentation](docs/guide/23-session-documentation-skill.md) 67% faster
- [Skills Filtering](docs/guide/20-skills-filtering-optimization.md) 93% reduction
- [Playwright E2E Testing](docs/guide/19-playwright-e2e-testing.md) 🧪
- [Perplexity Cost Optimization](docs/guide/18-perplexity-cost-optimization.md) 💰
- [Skill Detection Enhancement](docs/guide/17-skill-detection-enhancement.md) 🏆
- [Task Tracking System](docs/guide/04-task-tracking-system.md)
- [Developer Mode UI Feedback](docs/guide/05-developer-mode-ui-feedback-system.md)
- [Template Repository](template/)
- [Skills Library](skills-library/)
