# Dynamic Workflows -- Understanding and Capping Token Cost

**Created**: June 2026
**Source**: Production session -- real OTEL measurements
**Evidence**: 3 one-word subagents measured at 393,005 tokens (99.99% cacheCreation); model-pinning cut per-agent cost multiple-fold
**Time to Implement**: 20-30 minutes
**Difficulty**: Intermediate
**Applies to**: Claude Code 2.1.154+ (dynamic workflows shipped 2.1.154)

---

## Overview

Dynamic workflows (Claude Code 2.1.154+) let Claude orchestrate work across tens to hundreds of subagents in the background. They're powerful -- and they can consume **dramatically** more tokens than a normal session. Anthropic's own guidance: *"dynamic workflows consume meaningfully more usage than a typical Claude Code session."*

This guide explains **why** they're expensive, how to **measure** the spend precisely, and the levers that actually **cap** it. Every number here is a real measurement.

**Golden rule**: the cost is dominated by *per-agent context inheritance*, not by the work the agents do. Optimize for that and everything else follows.

---

## Why workflows are expensive: the context-inheritance tax

Every subagent a workflow spawns is a fresh context. It inherits your system prompt, your `CLAUDE.md`, your rules, and your tool schemas -- and **writes all of that into the prompt cache** on its first turn (`cacheCreation` tokens).

A measured example: a workflow with **3 subagents that each replied with a single word** consumed **393,005 tokens** -- and **~99.99% of it was `cacheCreation`**, not the actual output (which was ~16 tokens total). Three agents = three full context-writes.

The implication is blunt:

- **Fan-out is the cost.** 8 agents ≈ 8× the context-write tax, regardless of how trivial each task is.
- A large always-on rule/`CLAUDE.md` stack multiplies this -- each agent pays for it.
- The model each agent runs on multiplies it again (see levers below).

---

## Measuring workflow spend (so you can prove a change worked)

### Built-in: `/usage`

On Pro/Max/Team/Enterprise plans, `/usage` breaks down recent usage and **attributes it to skills, subagents, plugins, and MCP servers** as a percentage of total. This is the zero-setup way to see "how much went to subagents."

### Precise: OpenTelemetry metrics

Claude Code exports two counters you can capture with any OTLP backend:

- `claude_code.token.usage` (unit: tokens)
- `claude_code.cost.usage` (unit: USD)

Both carry attributes that let you split workflow spend from main-loop spend:

| Attribute | Values | Use |
|---|---|---|
| `query_source` | `main` / `subagent` / `auxiliary` | **Workflow agents report as `subagent`** -- this is the key split |
| `type` | `input` / `output` / `cacheRead` / `cacheCreation` | Confirms the cacheCreation tax |
| `model` | e.g. `claude-haiku-4-5` | Proves which model an agent actually ran on |
| `agent.name`, `skill.name`, `effort` | -- | Finer attribution |

Enable export:

```bash
# in ~/.claude/settings.json env, or your shell
CLAUDE_CODE_ENABLE_TELEMETRY=1
OTEL_METRICS_EXPORTER=otlp          # default is often "none" -- token metrics need this ON
OTEL_EXPORTER_OTLP_PROTOCOL=http/json
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
```

Telemetry env is read at **startup** -- restart Claude Code after changing it. Point the endpoint at any OTLP-compatible collector (Prometheus, the OTel Collector, or a small local receiver). Then sum `token.usage{type=output, query_source=subagent}` to see exactly what your workflows cost.

> **Two gotchas if you build your own metrics consumer.** (1) Claude Code sends token counts as OTLP `asDouble` (floats like `11414.0`), not `asInt` -- format accordingly. (2) These are **cumulative** counters: each subagent run is a *distinct* time series that can collide on the same attribute set. Discriminate series by `startTimeUnixNano` -- take the **max within a series** (collapses 60-second re-reports) but **sum across distinct series** (sums separate runs). Aggregating with a naive "max per attribute key" silently *undercounts* multi-run subagent totals.

---

## The levers that cap cost (ranked by impact)

1. **Pin cheap models per phase (biggest lever).** Workflow agents inherit your **session model by default** -- which is often the most expensive one. In your workflow script, set the model per phase: a fast/cheap model (Haiku/Sonnet) for mechanical phases (grep, read, audit) and the premium model only for the final synthesis. Measured: the same trivial agents ran multiple-fold cheaper on Haiku than on the default premium model.

2. **Fewer, leaner agents.** The context-write tax is *per agent*. Spawn 3 where 3 will do; don't fan out to 8 "to be safe."

3. **Lower the effort level on cheap phases.** Thinking is billed as output, so a high global effort multiplies every agent. Drop it for mechanical phases.

4. **Self-imposed budget guard (in-script hard ceiling).** A workflow script can read a live output-token meter (`budget.spent()`) and stop spawning once it crosses a self-set cap -- e.g. `while (budget.spent() < cap) { ...spawn... }`, with a hard max-iteration runaway guard. This halts the loop deterministically without needing any special prefix. *(Note: a per-turn `+Nk` "token target" directive is described in the Workflow tool's internal contract, but as of 2.1.158 it does not arm a ceiling -- a `+5k` prefix leaves the budget target unset. Use the in-script `budget.spent()` guard instead, and re-check the changelog on future versions.)*

5. **Account-level caps.** On Pro/Max, `/usage-credits` sets a monthly spend limit. On API billing, set a workspace spend/rate limit in the Console.

### The optimization loop

```
run workflow  →  read the `subagent` line (/usage or OTEL report)
              →  pin cheaper models / cut agent count
              →  re-run  →  confirm the subagent number dropped
```

---

## Quick checklist

- [ ] `OTEL_METRICS_EXPORTER=otlp` set + Claude Code restarted (token metrics flowing)
- [ ] Per-phase `model:` pinned in workflow scripts -- Haiku/Sonnet for mechanical phases
- [ ] Agent count scoped to the task (no defensive fan-out)
- [ ] In-script `budget.spent()` guard + runaway max-iteration cap for unbounded loops
- [ ] `/usage-credits` (Pro/Max) or workspace spend limit (API) as the account-level backstop
- [ ] Verified: a real run shows `query_source=subagent` spend, and it dropped after pinning

---

## Summary

Workflows are expensive because every subagent re-writes your full context into cache -- fan-out, not the task, is the cost. Measure it with `/usage` or the OTEL `query_source=subagent` split, then cap it with per-phase cheap-model pinning (the dominant lever), fewer agents, lower effort, an in-script `budget.spent()` guard, and an account-level credit limit. Don't rely on a `+Nk` prefix for a hard ceiling on 2.1.158 -- it isn't wired yet.
