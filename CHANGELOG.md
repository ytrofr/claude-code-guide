# Changelog

All notable changes to Claude Code Guide are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [2.4.0] - 2026-02-14

### Added

- **Guide #45**: Plan Mode Quality Checklist - 8 mandatory plan sections (requirements clarification, existing code check, over-engineering prevention, best practices, modular architecture, documentation, E2E testing, observability). Two complementary approaches: rules file (passive, always in context) and user-invocable skill (on-demand). Covers the limitation of no plan mode hook event.

## [2.3.0] - 2026-02-13

### Added

- **Guide #40**: Agent Orchestration Patterns - 5 core workflow architectures (Chain, Parallel, Routing, Orchestrator-Workers, Evaluator-Optimizer), query classification, subagent budgeting
- **Guide #41**: Evaluation Patterns - Anthropic's 6 eval best practices (capability vs regression, outcome-based grading, pass^k consistency, LLM-as-judge, transcript review, saturation monitoring)
- **Guide #42**: Session Memory & Compaction - SESSION_MEMORY_PROMPT template, PreCompact hooks, 75% rule, recovery patterns
- **Guide #43**: Claude Agent SDK - Stateless vs stateful agents, tool permissions (allowed_tools vs disallowed_tools), MCP integration, plan mode
- **Guide #44**: Skill Design Principles - Degrees of freedom framework, progressive disclosure, scripts as black boxes, negative scope, anti-clutter rules

### Changed

- **Guide #13**: Added "Always Exit 0" best practice, Python hook patterns, settings.local.json configuration
- **Guide #36**: Added tool permission models (allowed_tools vs disallowed_tools distinction), query classification for agent routing, "Fresh Eyes" QA pattern
- **Guide #38**: Added "Context Window Is a Public Good" principle, three-level progressive disclosure, scripts-as-black-boxes token savings

## [2.2.0] - 2026-02-12

### Changed

- **AI Intelligence Hub**: Extracted to own repo [ytrofr/ai-intelligence-hub](https://github.com/ytrofr/ai-intelligence-hub)

### Removed

- `tools/trendradar-dashboard/` — moved to separate repository

## [2.1.0] - 2026-02-12

### Added

- **Guide #36**: Task(agent_type) restriction patterns and examples for controlled sub-agent delegation
- **Guide #38**: "When You MUST Override" section with real-world 213-skill measurement example

### Changed

- **Guide #38**: Budget measurement script updated to include project-level skills (.claude/skills/)

## [2.0.0] - 2026-02-08

### Added

- **SEO/AEO/GEO Overhaul** - Complete search engine and AI discoverability optimization
- `robots.txt` - AI crawler access (GPTBot, Claude-Web, PerplexityBot)
- `sitemap.xml` - 35 pages for search engine indexing
- `_config.yml` - Jekyll/GitHub Pages configuration with SEO tags
- `CITATION.cff` - Academic and AI discovery metadata
- `docs/index.md` - AEO-optimized landing page with FAQ structure
- `CONTRIBUTING.md` - Community contribution guidelines
- JSON-LD structured data for search engines

### Changed

- Repository renamed: `claude-code-implementation-guide` → `claude-code-guide`
- README.md major overhaul with SEO keywords and hero section
- All internal links updated to new repository URL

## [1.5.0] - 2026-02-05

### Added

- **Guide #35**: Skill Optimization Maintenance - Long-term skill health patterns
- **Guide #34**: Basic Memory MCP Integration - Persistent knowledge patterns
- **Guide #33**: Branch-Specific Skill Curation - Per-branch skill optimization

### Changed

- STATUS.md updated with current metrics

## [1.4.0] - 2026-01-20

### Added

- **Guide #32**: Document Automation - Auto-generation patterns
- **Guide #31**: Branch-Aware Development - Multi-branch workflows
- **Guide #30**: Blueprint Auto-Loading - Feature context patterns

## [1.3.0] - 2026-01-10

### Added

- **Guide #29**: Branch Context System - JSON-based branch configuration
- **Guide #29**: Comprehensive Skill Activation Testing - Validation methodology
- **Guide #28**: Skill Optimization Patterns - Maintenance workflows

## [1.2.0] - 2025-12-28

### Added

- **Guide #27**: Fast Cloud Run Deployment - GCP patterns
- **Guide #26**: Claude Code Rules System - `.claude/rules/` structure
- **Guide #25**: Best Practices Reference - Anthropic-aligned patterns

## [1.1.0] - 2025-12-20

### Added

- **Guide #24**: Skill Keyword Enhancement Methodology
- **Guide #23**: Session Documentation Skill
- **Guide #22**: wshobson Marketplace Integration
- **Guide #21**: Pre-Prompt Optimization (370x improvement)
- **Guide #20**: Skills Filtering Optimization (47-70% token savings)

### Changed

- Pre-prompt hook guide updated with 10k character limit patterns

## [1.0.0] - 2025-12-14

### Added

- Initial release with core documentation
- Quick Start Guide
- Pre-Prompt Hook Complete Guide
- Skill Activation System (88.2% accuracy)
- MCP Integration Guide
- Memory Bank Hierarchy
- 19 detailed guide documents
- Template CLAUDE.md
- Skills library with 162+ skills
- Example hooks and scripts

---

## Version History Summary

| Version | Date       | Highlights                                                           |
| ------- | ---------- | -------------------------------------------------------------------- |
| 2.4.0   | 2026-02-14 | Plan mode quality checklist (8 mandatory sections)                   |
| 2.3.0   | 2026-02-13 | 5 new chapters (orchestration, evals, compaction, SDK, skill design) |
| 2.1.0   | 2026-02-12 | Task restrictions, budget override                                   |
| 2.0.0   | 2026-02-08 | SEO/AEO/GEO overhaul, repo rename                                    |
| 1.5.0   | 2026-02-05 | Skill maintenance patterns                                           |
| 1.4.0   | 2026-01-20 | Branch-aware development                                             |
| 1.3.0   | 2026-01-10 | Context and testing systems                                          |
| 1.2.0   | 2025-12-28 | Rules and best practices                                             |
| 1.1.0   | 2025-12-20 | Pre-prompt 370x optimization                                         |
| 1.0.0   | 2025-12-14 | Initial release                                                      |
