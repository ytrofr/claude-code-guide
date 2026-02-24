# Changelog

All notable changes to Claude Code Guide are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [3.2.0] - 2026-02-24

### Added

- **Guide #13**: File Size / Modularity Enforcement Hooks -- new production example showing how to pair PreToolUse + PostToolUse hooks for code quality enforcement. PreToolUse catches new oversized files before they hit disk (reads `tool_input.content` line count). PostToolUse detects growth in existing files using a `/tmp` cache with md5sum keys (only warns on >500L files if they grew by 20+ lines, avoiding noise on legacy violations). Both hooks are non-blocking (exit 0 always). Includes complete scripts, settings.json config, design decisions table, and practical usage examples.
- **Examples**: Added `file-size-precheck.sh` and `file-size-warning.sh` to `examples/production-claude-hooks/hooks/`

## [3.1.0] - 2026-02-23

### Added

- **Guide #51**: Persistent Memory Patterns — Inspired by claude-mem (30K+ stars). Four patterns that automatically persist session knowledge to Basic Memory MCP with zero manual effort: (1) Auto-Observation PostToolUse hook — selective JSONL capture of file edits and significant Bash commands, async <50ms, no AI processing; (2) Auto Session Summary SessionEnd hook — reads git log (2h window) + JSONL observations → writes structured Basic Memory note; (3) Progressive Disclosure Search — 3-layer workflow (search IDs → search_notes preview → fetch full) with 10x token savings vs loading all results; (4) Observation Taxonomy — 6 standardized types ([bugfix]/[feature]/[refactor]/[change]/[discovery]/[decision]) + 5 concepts (#how-it-works/#problem-solution/#gotcha/#pattern/#trade-off). All patterns are global (`~/.claude/`) not project-specific. Includes design comparison: hook approach vs claude-mem worker service.

## [3.0.0] - 2026-02-23

### Added

- **Guide #50**: Verification Feedback Loop - Boris Cherny's insight that giving Claude a way to verify its work 2-3x the quality. Three components: (1) /verify command with $! dynamic context injection for zero-round-trip verification, (2) verify-app agent with 3-tier verification (static/health/tests) and tech stack auto-detection, (3) Stop hook that detects source code changes and nudges verification. Includes global vs project scope explanation and adoptable templates.

## [2.9.0] - 2026-02-23

### Added

- **Guide #49**: Workflow Resilience Patterns - four production-tested patterns for handling common session failure modes. (1) Autonomous Fixing: fix/ask decision framework for when Claude breaks something vs when to ask the user. (2) Correction Capture: persist user corrections to Basic Memory MCP or `.claude/rules/` so they're never repeated. (3) Task Tracking Conventions: when and how to use TaskCreate/TaskUpdate with 6 hygiene rules. (4) Sideways Detection: 3-strike rule, scope creep, wrong assumptions, and blocked triggers for mid-execution re-planning. Each pattern includes an adoptable rule template.

## [2.8.0] - 2026-02-19

### Added

- **Guide #48**: Lean Orchestrator Pattern - new chapter on defeating context rot during multi-task plan execution. Covers delegation decision matrix (when to spawn subagents vs work inline), parallel execution for independent tasks, context budget targets (<20% orchestrator), filesystem verification patterns, and common mistakes. Inspired by GSD project analysis. Includes adoptable rule template.

## [2.7.0] - 2026-02-18

### Changed

- **Guide #45**: Plan Mode Quality Checklist expanded from 10 to 11 mandatory sections. Added Section 10 (Modularity Enforcement - blocking gate with 4 sub-checks: File Size Gate, Layer Separation Gate, Extraction Gate, God File Prevention). Updated template, Chapter 47 references, and design decisions.
- **Guide #26**: Added "Global vs Project Rule Deduplication" section. Best practice for preventing double-loading when identical rules exist in both `~/.claude/rules/` and `.claude/rules/`. Includes audit workflow and token savings evidence (~1,139 lines saved).

## [2.6.0] - 2026-02-17

### Changed

- **Guide #18**: Expanded from "Perplexity Cost Optimization" to "MCP Cost Control" with hook enforcement. Added PreToolUse/PostToolUse two-hook sandwich pattern, global settings placement (user-level), generalizable MCP cost control table, and updated validation checklist.

## [2.5.0] - 2026-02-16

### Changed

- **Guide #45**: Plan Mode Quality Checklist expanded from 8 to 10 mandatory sections. Added Section 8 (File Change Summary - table of affected files with action and description) and Section 9 (Plan Summary TL;DR - 3-5 bullet points). Added Plan File Metadata section (branch, timestamp, topic, keywords for discoverability). Updated design decisions and takeaways.
- **index.md**: Fixed stale metrics (Skills 162+ → 226+, Chapters 37+ → 42, Agent Patterns 3 → 5). Added Planning & Quality navigation section. Added missing Advanced Topics links (chapters 38-44).

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

| Version | Date       | Highlights                                                                  |
| ------- | ---------- | --------------------------------------------------------------------------- |
| 3.0.0   | 2026-02-23 | Verification feedback loop: /verify command, verify-app agent, Stop hook    |
| 2.9.0   | 2026-02-23 | Workflow resilience: autonomous fixing, correction capture, tasks, sideways |
| 2.8.0   | 2026-02-19 | Lean orchestrator: context rot prevention via subagent delegation           |
| 2.7.0   | 2026-02-18 | Plan mode: 11 sections + modularity gate + rule deduplication guide         |
| 2.6.0   | 2026-02-17 | MCP cost control hooks (PreToolUse/PostToolUse sandwich pattern)            |
| 2.5.0   | 2026-02-16 | Plan mode: 10 sections + file metadata (branch, timestamp, keywords)        |
| 2.4.0   | 2026-02-14 | Plan mode quality checklist (8 mandatory sections)                          |
| 2.3.0   | 2026-02-13 | 5 new chapters (orchestration, evals, compaction, SDK, skill design)        |
| 2.1.0   | 2026-02-12 | Task restrictions, budget override                                          |
| 2.0.0   | 2026-02-08 | SEO/AEO/GEO overhaul, repo rename                                           |
| 1.5.0   | 2026-02-05 | Skill maintenance patterns                                                  |
| 1.4.0   | 2026-01-20 | Branch-aware development                                                    |
| 1.3.0   | 2026-01-10 | Context and testing systems                                                 |
| 1.2.0   | 2025-12-28 | Rules and best practices                                                    |
| 1.1.0   | 2025-12-20 | Pre-prompt 370x optimization                                                |
| 1.0.0   | 2025-12-14 | Initial release                                                             |
