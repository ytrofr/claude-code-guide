# Changelog

All notable changes to Claude Code Guide are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [5.0.3] - 2026-04-24

Patch release: CC version history catches up on releases 2.1.113 through 2.1.118.

### Added

- **Chapter 01 (CC Version History)**: Four new release entries — 2.1.118, 2.1.117, 2.1.116, 2.1.113 — covering hooks invoking MCP tools directly (`type: "mcp_tool"`), native binary spawn, `bfs`+`ugrep` replacing Glob/Grep, Opus 4.7 `/context` 1M-window fix, `cleanupPeriodDays` extended sweep, `sandbox.network.deniedDomains`, `/cost`+`/stats`→`/usage` merger, `DISABLE_UPDATES` env var, custom named themes, vim visual mode, Bash security hardening, and `/resume` performance gains.
- **Superseded features table**: `/cost` and `/stats` commands (2.1.118) → merged into `/usage` (both remain as typing shortcuts).

### Changed

- **Chapter 01 intro**: "current 2.1.111 line" → "current 2.1.118 line".
- **"(current)" label** moved from 2.1.111 to 2.1.118 in the Latest section.
- **CITATION.cff**: `CC 2.1.111+ compatible` → `CC 2.1.118+ compatible`.

## [5.0.2] - 2026-04-22

Patch release: Problem/Solution sub-section added at the top of Section 12 (TL;DR) across plan-mode docs, template rules, and the `ExitPlanMode` hook.

### Changed

- **Chapter 01 (Plan Mode)**: Section 12 now describes **five** mandatory sub-sections (was four). New 12a — "Problem / Solution" — is two one-sentence lines (`**Problem**: …` / `**Solution**: …`) that anchor why the plan exists. Remaining sub-sections reletter: 12b Overall Plan Confidence, 12c Problem (Before) / Solution (After) tables, 12d Scope, 12e KPI Dashboard.
- **Template `.claude/rules/planning/plan-checklist.md`**: Section 12 opens with Problem/Solution one-liners; Quick Validation gets a new checkbox; bumped to v9.
- **Template `.claude/hooks/plan-sections-gate.sh`**: soft-warns when `**Problem**:` or `**Solution**:` lines are missing from the plan file (non-blocking); version reference bumped to v9.

### Rationale

Every reviewer should see WHY a plan exists before reading confidence, KPIs, or per-fix tables. Section 0 preserves the raw user prompt; Section 12's new Problem/Solution distills it into one sentence each, in user-outcome terms. Writing Problem first catches scope creep: if either line spills to a second sentence, the plan is too broad or the intent isn't clear yet.

## [5.0.1] - 2026-04-21

Patch release: Section 0 (verbatim user prompt) added as first mandatory section across plan-mode docs, template rules, and the `ExitPlanMode` hook.

### Changed

- **Chapter 01 (Plan Mode)**: now describes 15 mandatory sections (was 14). New Section 0 — "Original User Prompt (verbatim, preserved)" — is the immutable, first section of every plan. Hook-enforced as blocking: `ExitPlanMode` refuses to submit without it, and soft-warns if the heading exists but no blockquote body is present.
- **Chapter 03 (Brainstorming)**: updated cross-reference from "14 sections" to "15 sections (starting with the verbatim user prompt)".
- **Template `.claude/rules/planning/plan-checklist.md`**: added Section 0 template + Quick Validation checkbox; bumped to v8.
- **Template `.claude/rules/planning/plan-link.md`**: header template now includes Section 0 blockquote immediately after metadata.
- **Template `.claude/hooks/plan-sections-gate.sh`**: detects Section 0 heading + blockquote content; `MISSING` list now `/12`; version reference bumped to v8.

### Rationale

Plans drift across revisions. The most common failure mode wasn't wrong tests or missing observability — it was paraphrased prompts. Freezing the original user prompt at the top gives every reviewer a reference point for detecting drift.

## [5.0.0] - 2026-04-21

Major release: the guide is reorganized around 6 topical Parts, installation is now manifest-driven with three tiers, and compatibility is refreshed for Claude Code 2.1.111+.

### Added

**New structure: 6 topical Parts**
- Part I — Foundation (5 chapters)
- Part II — Workflow (6 chapters)
- Part III — Extension (9 chapters)
- Part IV — Context Engineering (7 chapters)
- Part V — Advanced (7 chapters)
- Part VI — Reference (6 chapters)

**New install tiers in `best-practices/manifest.json`**
- Core: 8 rules, 3 skills, 1 hook — newcomer-friendly
- Recommended: +22 rules, +13 skills, +6 hooks — working developer
- Full: +34 rules, +28 skills, +5 hooks + governance scaffolding — power user

**New chapters** (either brand new or synthesizing across multiple old chapters):
- Part I: 01 Installation, 02 CLAUDE.md primer, 03 Project structure, 04 First session, 05 Setup troubleshooting
- Part II: 02 TDD, 03 Brainstorming, 06 Commit and PR
- Part III: 03b Claude Agent SDK (ported+modernized from old ch.43), 07 Slash commands (commands→skills migration reference)
- Part IV: 06 Context Governance (7-layer system), 07 Skill lifecycle
- Part V: 01 AI DNA shared-layer, 07 Session-end and defrag
- Part VI: 01 CC version history (collapses 9 ship-logs), 02 CLI flags + env, 03 Hook event catalog (27 events), 04 Skill catalog, 05 MCP server catalog

**Other additions**
- `jekyll-redirect-from` plugin for URL stability across the restructure
- `best-practices/manifest.json` as authoritative tier definition
- `best-practices/test-manifest-resolve.sh` self-test (12 assertions)
- `ROADMAP-v5.md` public roadmap
- `docs/guide/_redirect-plan.md` internal redirect mapping (51 entries)

### Changed

- `install.sh` rewritten to be manifest-driven (replaces hardcoded file lists from v4.x)
- New install flags: `--recommended`, `--full`, `--dry-run`
- CC compatibility updated from 2.1.99 to 2.1.111+
- README hero metrics restated with honest counts
- All chapters verified against current CC flags, hooks (27 events), skills, MCP patterns

### Removed

Hardcoded installer flags (v4.x legacy):
- `--commands` (commands migrated to skills at CC 2.1.88)
- `--all-rules` (folded into `--recommended`)
- `--with-hooks` (folded into tier composition)

Pruned chapters (content obsolete or superseded):
- 9 version ship-logs (54, 57, 60, 64, 66, 70, 71, 72, 73) → consolidated into part6/01
- Pre-native-skill-loading content (05, 30, 30b)
- Branch-context chapters (31, 31b, 33) — replaced by path-scoped rules
- Scattered orchestration/config chapters (41, 46, 47, 48, 49) — absorbed into relevant Parts
- UI/UX rules (52) — out of CC guide scope
- Research logs (55, 56, 59, 67, 68, 69)

Absorbed + deleted with redirects:
- 02, 04, 06, 12, 13, 14, 15, 18, 19, 19b, 22, 23, 25, 26, 27, 28, 29, 32, 34, 35, 36, 37, 38, 39, 40, 42, 43, 44, 45, 50, 51, 53, 58, 61, 62, 63, 65, 74, 75, 76, 77, 78

### Fixed

- `install.sh` comments now honestly state tier counts (old comments claimed "35 rules" while installing 19)
- CC version references updated across all chapters (no more "CC 2.1.99 compatible" on chapters describing 2.1.111 features)
- Hero metrics no longer cite unsourced performance claims
- `settings.json mcpServers` myth debunked — MCP servers register via `claude mcp add` stored in `~/.claude.json`

## [4.4.0] - 2026-04-20

### Added
- Chapter 78: Self-Telemetry for Claude Code — hooks + jsonl pattern for measuring your own CC usage (tool calls, subagent dispatches, skill invocations, session KPIs) without OTEL. First-published `SubagentStart` / `SubagentStop` stdin payload schema for CC 2.1.111 (validated by live probe). Documents the FIFO correlation pattern for duration measurement without `tool_use_id`, the `grep -c ... || echo 0` double-output gotcha + `_safe_count` fix, and the `event:` discriminator convention for multi-event jsonl streams. Covers what is NOT measurable via hooks (OTEL file exporter unsupported, `PermissionGranted` event absent, no `claude metrics` CLI).

### Changed
- Ch.13 hooks: harmonized the "Use Absolute Paths for Hook Commands" example to use `$CLAUDE_PROJECT_DIR/.claude/hooks/...` instead of a hardcoded `/home/user/project/...` path, aligning with the `$CLAUDE_PROJECT_DIR` section immediately above.

## [4.3.0] - 2026-04-12

### Added
- Chapter 71: Claude Code 2.1.93-2.1.94 features (Mantle on Bedrock, default effort high, plugin skill YAML hooks, Slack MCP)
- Chapter 72: Claude Code 2.1.95-2.1.97 features (Focus view Ctrl+O, statusline refreshInterval, workspace.git_worktree, Accept Edits safe-env, /agents running indicator)
- Chapter 73: Claude Code 2.1.98-2.1.99 features (Monitor tool, settings resilience, 6 permission bypass fixes, subagent MCP inheritance, worktree Read/Edit, PID namespace sandbox, OTEL TRACEPARENT, /agents tabbed UI, /team-onboarding, OS CA cert trust)
- Chapter 74: Claude Code Monitor Tool — standalone reference with ScheduleWakeup decision matrix
- Chapter 75: Claude Code Statusline Patterns — workspace.git_worktree, refreshInterval, 3 example scripts
- Chapter 70: Claude Code 2.1.89-2.1.92 features (bundled from WIP)
- Chapter 69: Knowledge Harvest Adoption (bundled from WIP)
- 3 new best-practices rules: concurrency-partitioning, fail-closed-defaults, source-validation (bundled from WIP)

### Changed
- Ch.13 hooks: appended 2026-04 Updates section (settings resilience, permissions.deny precedence, hook path fix, 27+ events)
- README: "25 hook events" → "27+ hook events", "60 chapters" → "65 chapters", "26 rules" → "29 rules", added "CC 2.1.99 compatible"
- CITATION.cff: bumped to v1.3.0, updated date-released, synced abstract counters (27+ hooks, 65 chapters, 29 rules)
- llms.txt: added chapters 69-75
- docs/index.md: updated TOC and stats
- 14 chapters refreshed with minor updates (bundled from WIP)

## [4.2.0] - 2026-04-01

### Added
- Chapter 69: Knowledge Harvest Adoption — validation protocol for community articles (3-step: CLI check, guide search, reject unvalidated), progressive disclosure splits (80%+ body reduction), 2 new skills (`/iterative-review`, `/fix-ci`), spec-first TDD gate
- Chapter 58: Added "Progressive Disclosure Split" cookbook recipe (Section 6) — when to split skills over 300 lines, three-level loading cost, before/after line counts

## [4.1.0] - 2026-03-28

### Added
- Chapter 64: Claude Code 2.1.84-2.1.86 features (conditional `if` hooks, skill description 250-char cap, Read compact format, paths YAML lists, idle-return prompt, system-prompt caching with ToolSearch, code intelligence plugins, verification hook pattern)
- Verification hook template: task-verification-gate.sh (advisory PreToolUse hook for TaskUpdate)
- `paths:` frontmatter added to 9 domain-specific best-practices rules for conditional loading

### Changed
- Best practices rules: Added `paths:` frontmatter to 9 domain-specific rules (api-key-hygiene, bash-filename-iteration, doctor-command, feature-toggle-principle, frontmatter-format, no-hardcoded-urls, primacy-recency, retry-circuit-breaker, test-preflight)
- Template hooks: Updated post-tool-use example with `if` conditional field
- Best practices version: 2.0.0 → 2.1.0

## [4.0.0] - 2026-03-25

### Added
- Chapter 60: Claude Code 2.1.82-2.1.83 features (CwdChanged/FileChanged hooks, TaskOutput deprecation, MEMORY.md cap, transcript search, env scrub, managed-settings.d)
- Chapter 61: Stack Audit & Maintenance Patterns (frontmatter compliance, /document v3 three-level analysis, /retrospective skill pipeline, four-area audit methodology)
- 11 new universal rules in best-practices: frontmatter-format, diagnostic-first, no-band-aids, autonomous-fixing, task-tracking, retry-circuit-breaker, test-preflight, feature-toggle-principle, api-key-hygiene, no-hardcoded-urls, bash-filename-iteration
- Debugging rules category (diagnostic-first, no-band-aids) — prevents patch-on-patch cycles
- 6 new BEST-PRACTICES.md sections (18-23): Frontmatter Format, Debugging Methodology, Task Tracking, External API Safety, Environment Hygiene, Test Preflight

### Changed
- Template commands: Fixed frontmatter format in all 7 commands (`allowed_tools` → `allowed-tools`, JSON arrays → comma-separated)
- Best practices rules: 12 → 23 universal rules
- Template rules: 24 → 35 rules across debugging/, process/, technical/ categories
- Session protocol rule: Updated for Claude Code 2.1.83 features
- Plan checklist rule: Updated to 13 mandatory sections with KPI dashboard format
- BEST-PRACTICES.md: 17 → 23 sections
- docs/index.md: Updated stats (2.1.83, 21 hooks, 23 rules, 240+ patterns)
- Best practices version: 1.2.0 → 2.0.0

### Removed
- Archived 7 deprecated pre-prompt hook chapters to docs/archive/ (16, 17, 20, 21, 24, 29b, pre-prompt-hook-complete-guide)
- Pre-prompt hook skill matching system fully superseded by Claude Code native skill loading (v2.1.76+)

## [3.5.0] - 2026-03-06

### Changed

- Updated hook events from 18 to 19 (added InstructionsLoaded)
- Updated TeammateIdle and TaskCompleted hooks to document `{"continue": false, "stopReason": "..."}` JSON output support for stopping teammates
- Updated model documentation with effort levels (low/medium/high) and "ultrathink" keyword for high effort

### Added

- Chapter 13: InstructionsLoaded hook event (fires when CLAUDE.md or .claude/rules/*.md files are loaded), agent_id/agent_type fields in hook event data, worktree field in status line hooks
- Chapter 38: Effort levels section (Opus 4.6 defaults to medium effort), includeGitInstructions and sandbox.enableWeakerNetworkIsolation settings
- Skill Activation System: `${CLAUDE_SKILL_DIR}` variable documentation, description field requirement clarification, colon-in-description fix note

## [3.4.0] - 2026-03-03

### Added

- **Guide #53**: Pre-Validation Probe — A 2-minute practice that catches fundamentally wrong plans before implementation begins. Every plan rests on assumptions about reality; the probe verifies those assumptions with real evidence (grep, curl, file reads, test runs, screenshots — any tool counts) during plan mode, before approving. Includes assumption test table, feasibility checks, go/no-go verdict, examples across 12 project types (frontend, backend, performance, security, CI/CD, etc.), anti-patterns, and real-world wins. Integrates as Section 0.1 in the Plan Mode Checklist.
- **Template**: `~/.claude/rules/planning/pre-validation.md` — adoptable rule file for pre-validation probe enforcement

### Changed

- **Guide #45**: Plan Mode Checklist updated from 12 to 13 mandatory sections (added Section 0.1: Pre-Validation Probe as a blocking gate between TL;DR and Requirements)
- **Template**: `plan-checklist.md` updated with Section 0.1 and Quick Validation checklist additions
- **Best Practices**: `validation-workflow.md` updated from 5 to 6 Pre-Implementation Gates (added Gate 0: Pre-Validation Probe)

## [3.3.0] - 2026-02-24

### Changed

- Updated hook events from 14 to 18 (added Setup, ConfigChange, WorktreeCreate, WorktreeRemove)
- Updated installation instructions: npm deprecated, now uses `claude install` / `curl` installer
- Fixed PreToolUse "approve" → "allow" in example settings
- Added prompt-based and agent-based hook types to Chapter 13
- Added 1M context window documentation across guide
- Updated model references to Opus 4.6, Sonnet 4.6, Haiku 4.5

### Added

- Chapter 13: 4 new hook events, prompt/agent hook types, additionalContext, frontmatter hooks
- Chapter 36: Worktree isolation, `claude agents` CLI
- Chapter 38: 1M context window, fast mode, updated pricing
- Chapter 4: Native TaskCreate/TaskUpdate/TaskList/TaskGet documentation
- Chapter 45: plansDirectory configuration
- Chapter 46: Permission precedence (ask overrides allow)
- README/index: Updated metrics, installation, SEO keywords

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
| 5.0.0   | 2026-04-21 | 6 topical Parts (~42 chapters), manifest-driven install (Core/Recommended/Full), CC 2.1.111+ |
| 4.4.0   | 2026-04-20 | Ch.78 self-telemetry, SubagentStart/Stop payload schema, hook path harmonization |
| 4.3.0   | 2026-04-12 | CC 2.1.93-2.1.99 features, Monitor tool, statusline patterns, 3 new rules   |
| 4.2.0   | 2026-04-01 | Knowledge harvest adoption: validation protocol, progressive disclosure splits, 2 new skills |
| 3.3.0   | 2026-02-24 | 1M context, Opus 4.6/Sonnet 4.6/Haiku 4.5, 18 hooks, task mgmt, agents      |
| 3.2.0   | 2026-02-24 | File size/modularity enforcement hooks (PreToolUse + PostToolUse paired)    |
| 3.1.0   | 2026-02-23 | Persistent memory patterns (auto-observation, session summary, taxonomy)    |
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
