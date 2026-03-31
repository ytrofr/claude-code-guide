---
layout: default
title: "Adopting Battle-Tested Patterns from Claude Code Source"
parent: Guide
nav_order: 68
---

# Adopting Battle-Tested Patterns from Claude Code Source

*A practical guide to mining and adopting patterns from the CC v2.1.88 source*

## Overview

Claude Code's 1,884-file TypeScript codebase contains patterns refined through production use at scale. Not all of them are relevant to every project, but many solve problems that every Claude Code power user eventually encounters. This chapter classifies 25 patterns into adoption tiers, documents the rules and skills created from them, and provides a checklist for your own adoption.

---

## The 25 Patterns

Each pattern is classified by adoption tier:

- **Tier 1 (Adopt Now)**: Directly applicable, low effort, immediate ROI
- **Tier 2 (Experiment)**: Requires adaptation, moderate effort, context-dependent ROI
- **Tier 3 (Reference)**: Informational, high effort to adopt, useful as mental models

### Tier 1 -- Adopt Now

| # | Pattern | Source | What to Do |
|---|---------|--------|------------|
| 1 | **Fail-closed tool defaults** | buildTool() in Tool.ts | Default every new tool/action to "requires permission". Opt out explicitly. |
| 2 | **Partitioned concurrency** | Tool executor | Separate read (parallel) and write (serial) operations in your pipelines. |
| 3 | **Write-once registry** | Skill, tool, hook registration | Use "first registration wins" for plugin/extension systems. Eliminates ordering bugs. |
| 4 | **Static/dynamic prompt split** | Context management | Put stable content first in prompts for cache hits. Move volatile content to the end. |
| 5 | **MEMORY.md size cap** | 200 lines / 25KB | Cap any auto-growing context file. Unbounded injection = unbounded costs. |
| 6 | **Hook `if` conditions** | Hook matcher system | Filter hook execution BEFORE spawning the process. Reduces overhead by 80%+. |
| 7 | **Source-priority resolution** | Hook/settings priority chain | User > Project > Plugin for all overridable behaviors. |
| 8 | **AbortController hierarchy** | Task system | Parent cancellation cascades to children. No orphaned processes. |
| 9 | **O_NOFOLLOW on file ops** | Task system file I/O | Treat symlinks as a security boundary in file operations. |
| 10 | **Skill dedup via realpath** | Skill registry | Resolve symlinks before registration to prevent double-loading. |

### Tier 2 -- Experiment

| # | Pattern | Source | What to Do |
|---|---------|--------|------------|
| 11 | **Separate classifier model** | Auto-mode classifier | Use a cheaper model (Flash/Haiku) for classification/routing decisions, not the main model. |
| 12 | **Post-compact file restoration** | Context management | After context eviction, proactively reload the most relevant items using LLM scoring. |
| 13 | **LLM-powered relevance selection** | Memory injection | Use a small model call to score which memory entries are relevant before injecting them. |
| 14 | **Cache-preserving fork** | Task system | When branching execution, share the prompt cache prefix to avoid cold starts. |
| 15 | **Distributed file-based cron lock** | Cron tasks | Use O_EXCL file creation as a lightweight distributed lock for scheduled tasks. |
| 16 | **Token budget estimation** | Skill system | Estimate context cost of each extension upfront. Enforce a global budget. |
| 17 | **Conditional skill activation** | `paths:` frontmatter | Only load domain knowledge when working in relevant directories. |
| 18 | **Workspace trust verification** | Hook system | Verify trust before executing project-provided code. |
| 19 | **Message capping (UI)** | Task display | Cap displayed items for UI performance. Keep full history for the API. |
| 20 | **Jitter for scheduled tasks** | Cron system | Add random delay to prevent thundering herd when multiple instances exist. |

### Tier 3 -- Reference Only

| # | Pattern | Source | Why Reference Only |
|---|---------|--------|--------------------|
| 21 | **Streaming tool executor** | Tool execution pipeline | Requires deep integration with your rendering layer. |
| 22 | **AsyncLocalStorage isolation** | Task system | Node.js specific. Other languages use different request-scoping mechanisms. |
| 23 | **Permission rule syntax parser** | Hook `if` conditions | The grammar is specific to Claude Code's tool model. Adapt the concept, not the syntax. |
| 24 | **27-event hook lifecycle** | Hook system | Most projects need 3-5 events, not 27. Adopt the lifecycle concept, not the full catalog. |
| 25 | **God file pragmatism** | state.ts (1,758 lines) | Sometimes one large file is better than circular dependencies. Know when to break the rule. |

---

## Rules Created from Source Analysis

Seven new rules were created based on patterns discovered in the CC source:

| # | Rule File | Description |
|---|-----------|-------------|
| 1 | `rules/technical/fail-closed-defaults.md` | Every new tool, endpoint, or action defaults to "denied". Explicit opt-in required. |
| 2 | `rules/technical/partitioned-concurrency.md` | Separate read and write concurrency limits in all pipeline designs. |
| 3 | `rules/technical/write-once-registry.md` | First registration wins for extension systems. No overwrite, no ordering bugs. |
| 4 | `rules/technical/prompt-cache-optimization.md` | Static content first, dynamic content last in system prompts for cache hits. |
| 5 | `rules/technical/context-budget-caps.md` | Auto-growing context files MUST have line/byte caps. Track injection cost per turn. |
| 6 | `rules/technical/abort-hierarchy.md` | Parent cancellation MUST cascade to all child tasks. No orphaned processes. |
| 7 | `rules/technical/symlink-security.md` | File operations MUST use O_NOFOLLOW or equivalent. Symlinks are a security boundary. |

---

## Existing Rules Updated

Five existing rules were enhanced with patterns validated by the CC source analysis:

| # | Rule File | What Was Added |
|---|-----------|----------------|
| 1 | `rules/process/session-protocol.md` | Post-compact file restoration behavior (5 files, 50K tokens, Sonnet selection) |
| 2 | `rules/mcp/agent-routing.md` | Classifier overhead awareness -- broader allow rules reduce Sonnet calls |
| 3 | `rules/technical/patterns.md` | Write-once registry as a universal pattern for extension systems |
| 4 | `rules/process/safety-rules.md` | O_NOFOLLOW rationale and symlink security boundary |
| 5 | `rules/planning/delegation-rule.md` | Cache-preserving fork pattern for subagent delegation |

---

## New Skill: `/cc-source-patterns`

A reference skill was created at `~/.claude/skills/cc-source-patterns/SKILL.md` as a quick-lookup for the 25 patterns. It is a background skill (`user-invocable: false`) that Claude loads when working on Claude Code configuration, hook development, or skill authoring.

The skill contains:
- The 25-pattern table with tier classifications
- Quick decision trees for choosing the right pattern
- Links to the 7 new rules and 5 updated rules

---

## What NOT to Adopt

Some patterns in the CC source are highly specific to Claude Code's implementation and should not be adopted into your own projects:

| Pattern | Location | Why Skip |
|---------|----------|----------|
| **Vim-style FSM input handling** | Input/editor subsystem | Specific to terminal UI. Use your framework's input system. |
| **Custom Ink renderer** | UI layer | React Ink is already a niche choice. Building a custom renderer on top is extreme. |
| **Feature gating via env vars** | Various | CC uses dozens of `CLAUDE_CODE_*` env vars. For your projects, use proper feature flag systems (LaunchDarkly, Vercel Flags, etc.). |
| **Deferred tool loading** | ToolSearch system | Solves a specific problem (MCP servers with 100+ tools hitting context limits). Most projects have <20 tools. |
| **Triple-layer settings merge** | Settings system | User + project + plugin settings merge is complex. Most projects need 1-2 layers. |

### The Decision Rule

Adopt a pattern from CC source when:
1. You have the same problem it solves (not a theoretical future problem)
2. The pattern is simpler than your current approach
3. You can implement it in <50 lines for your use case

Do NOT adopt when:
1. The pattern solves a scale problem you do not have
2. It requires significant infrastructure you have not built
3. A simpler standard solution exists (e.g., feature flags)

---

## Adoption Checklist

Use this template when evaluating CC source patterns for your own setup:

### Step 1: Identify Applicable Patterns

```
[ ] Review Tier 1 patterns (all 10) -- which problems do I actually have?
[ ] Review Tier 2 patterns -- which am I likely to need within 3 months?
[ ] Skip Tier 3 unless working on a similar system
```

### Step 2: Create Rules

```
[ ] For each adopted pattern, create a rule in .claude/rules/ or project rules
[ ] Include: what the pattern does, when to apply, anti-patterns
[ ] Link to this chapter for background context
```

### Step 3: Update Existing Configuration

```
[ ] Review hook configurations -- add `if` conditions to reduce overhead
[ ] Review CLAUDE.md -- move stable content before volatile content
[ ] Review skills -- add `paths:` to domain-specific skills
[ ] Review MEMORY.md -- check size, prune if over 150 lines
```

### Step 4: Validate

```
[ ] Run one session with changes -- check /stats for cost impact
[ ] Verify hooks fire correctly with `if` conditions
[ ] Verify skills load/unload based on `paths:` conditions
[ ] Check prompt cache hit rate (if available in /stats)
```

### Step 5: Document

```
[ ] Record which patterns were adopted and why
[ ] Record which were skipped and why (prevents re-evaluation)
[ ] Update project CLAUDE.md if architectural patterns changed
```

---

## Summary

The CC source is a rich mine of production patterns, but selective adoption matters more than comprehensive adoption. Start with Tier 1 (10 patterns, all low-effort), experiment with Tier 2 as needs arise, and treat Tier 3 as mental models rather than implementation guides.

The key insight from this analysis: Claude Code's architecture optimizes aggressively for **API cost reduction** (prompt caching, memory caps, classifier cost separation) and **safety defaults** (fail-closed permissions, O_NOFOLLOW, workspace trust). These two concerns -- cost and safety -- are worth prioritizing in any AI-powered tool.

---

*Previous: [Chapter 67 -- Claude Code Internal Architecture](67-cc-source-architecture)*

*Updated: 2026-04-01*
