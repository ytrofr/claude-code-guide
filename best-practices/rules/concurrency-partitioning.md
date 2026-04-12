# Concurrency Partitioning — Read Parallel, Write Serial

**Scope**: ALL projects with parallel tool execution or multi-agent orchestration
**Authority**: MANDATORY for agent tool dispatch

---

## Core Rule

**Read-only operations run in parallel. Write operations run serially. Context-modifying operations run alone.**

When an orchestrator dispatches multiple tools, partition them by safety tier:

| Tier | Execution | Max Parallel | Examples |
|------|-----------|-------------|---------|
| **Read-only** | Parallel batch | 10 | search, lookup, analytics, get_* |
| **Write** | Serial (one at a time) | 1 | create_*, update_*, delete_* |
| **Context-modifier** | Barrier (alone) | 1 | switch_session, clear_cache, config_change |

## Implementation

Mark each tool with `is_read_only=True` or `is_read_only=False`. Default to **False** (fail-closed).

## Why This Matters

- Parallel writes can cause race conditions, partial updates, and data corruption
- Context-modifiers (session switches, cache clears) invalidate assumptions of in-flight operations
- Read-only parallelism is safe and provides significant speedup
