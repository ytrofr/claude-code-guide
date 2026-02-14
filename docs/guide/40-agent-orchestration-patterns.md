---
layout: default
title: "Agent Orchestration Patterns - 5 Core Workflow Architectures"
description: "Master the 5 agent orchestration patterns from Anthropic's cookbook: Chain, Parallel, Routing, Orchestrator-Workers, and Evaluator-Optimizer. Includes query classification and subagent budgeting."
---

# Chapter 40: Agent Orchestration Patterns

Claude Code's `Task()` tool gives you access to powerful multi-agent orchestration. But spawning agents without a clear pattern leads to wasted tokens and confused results. This chapter covers the 5 core orchestration patterns from Anthropic's cookbook, when to use each, and how to implement them in Claude Code.

**Purpose**: Choose the right multi-agent workflow pattern for any task
**Source**: Anthropic claude-cookbooks (orchestrator_workers.ipynb, research_lead_agent.md)
**Difficulty**: Intermediate to Advanced
**Time**: 1 hour to understand patterns, ongoing application

---

## The 5 Core Patterns

### 1. Chain Pattern

Tasks flow sequentially through agents, each building on the previous output.

```
Agent A → Agent B → Agent C → Final Result
```

**When to use**: Multi-step workflows where each step depends on the previous one.

**Claude Code implementation**:

```
// Step 1: Research
result1 = Task(subagent_type: "Explore", prompt: "Find all API endpoints in src/routes/")

// Step 2: Analyze (depends on step 1 result)
result2 = Task(subagent_type: "code-reviewer", prompt: "Review these endpoints for security: {result1}")

// Step 3: Report (depends on step 2 result)
result3 = Task(subagent_type: "technical-writer", prompt: "Write a security report based on: {result2}")
```

**Strengths**: Clear data flow, easy to debug, each step is focused.
**Weaknesses**: Slow (sequential), single point of failure at each step.

---

### 2. Parallel Pattern

Independent tasks run simultaneously, results are combined.

```
          → Agent A →
Input  →  → Agent B →  → Combine Results
          → Agent C →
```

**When to use**: Independent sub-tasks that don't depend on each other.

**Claude Code implementation**:

```
// Launch all three in a single message (Claude Code runs them in parallel):
Task(subagent_type: "database-agent", prompt: "Check staging DB health")
Task(subagent_type: "database-agent", prompt: "Check production DB health")
Task(subagent_type: "database-agent", prompt: "Check localhost DB health")
```

**Strengths**: Fast (wall-clock time of slowest agent), maximizes throughput.
**Weaknesses**: Cannot share intermediate results, higher total token cost.

---

### 3. Routing Pattern

A classifier directs the query to the most appropriate specialist agent.

```
Input → Classifier → Agent A (if type X)
                   → Agent B (if type Y)
                   → Agent C (if type Z)
```

**When to use**: Different query types need different expertise.

**Claude Code implementation**: Claude Code does this naturally based on agent descriptions. The model reads all agent descriptions and routes to the best match:

```yaml
# .claude/agents/database-agent.md
description: "Database operations. Use when querying tables, checking schema, or debugging SQL."

# .claude/agents/deploy-agent.md
description: "Deployment operations. Use when deploying to Cloud Run or checking traffic routing."

# .claude/agents/test-engineer.md
description: "Testing operations. Use when running tests or validating code changes."
```

The model reads the user's query, matches it against descriptions, and spawns the right agent. **Good descriptions are the routing mechanism.**

**Strengths**: Simple, leverages Claude's natural language understanding.
**Weaknesses**: Depends on description quality, can misroute ambiguous queries.

---

### 4. Orchestrator-Workers Pattern

A central orchestrator decomposes the task and delegates to specialized workers.

```
Input → Orchestrator → Worker A → Result A ↘
                     → Worker B → Result B → Orchestrator → Final
                     → Worker C → Result C ↗
```

**When to use**: Complex tasks that need decomposition and synthesis.

**Claude Code implementation**: The main Claude Code session acts as the orchestrator:

```
// Orchestrator (main context) decomposes the task:
"I need to investigate this performance issue. Let me check three areas:"

// Workers (subagents) investigate independently:
Task(subagent_type: "database-agent", prompt: "Check for slow queries in the last hour")
Task(subagent_type: "Explore", prompt: "Find any recent changes to src/services/ai/")
Task(subagent_type: "test-engineer", prompt: "Run the performance benchmark suite")

// Orchestrator synthesizes results:
"Based on the three investigations:
 - Database: 3 slow queries found (>5s)
 - Code changes: prompt-section-selector.js was modified yesterday
 - Benchmarks: 40% regression in AI response time
 Conclusion: The prompt selector change likely caused the regression."
```

**Strengths**: Handles complex multi-domain problems, good synthesis.
**Weaknesses**: Orchestrator context grows with each result, higher total cost.

---

### 5. Evaluator-Optimizer Pattern

Generate output, evaluate it, feed evaluation back to improve, repeat.

```
Generate → Evaluate → Pass? → Done
                    → Fail? → Feedback → Regenerate → Evaluate → ...
```

**When to use**: Quality-critical outputs that benefit from iterative refinement.

**Claude Code implementation**:

```
// Step 1: Generate
Task(subagent_type: "code-reviewer",
  prompt: "Write a migration script for adding the 'status' column to employees table")

// Step 2: Evaluate (fresh eyes -- different agent)
Task(subagent_type: "database-agent",
  prompt: "Review this migration script for correctness, rollback safety, and Sacred compliance: {script}")

// Step 3: If evaluation found issues, regenerate with feedback
Task(subagent_type: "code-reviewer",
  prompt: "Fix these issues in the migration script: {evaluation_feedback}")
```

**Key principle**: The evaluator should be stricter than the generator. Stop early on PASS -- don't over-iterate. Maximum 3 iterations is usually sufficient.

**Strengths**: Catches errors that single-pass misses, produces higher quality output.
**Weaknesses**: 2-3x more expensive, slower due to multiple rounds.

**Source**: Anthropic evaluator_optimizer.ipynb

---

## Decision Tree: Which Pattern?

```
Start → What kind of task?

Sequential steps (A then B then C)?
  → Chain Pattern

Independent sub-tasks (A and B and C)?
  → Parallel Pattern

One question, multiple possible handlers?
  → Routing Pattern

Complex problem needing decomposition?
  → Orchestrator-Workers Pattern

Quality-critical output needing refinement?
  → Evaluator-Optimizer Pattern
```

### Combining Patterns

Real-world tasks often combine patterns:

```
Orchestrator-Workers + Parallel:
  Orchestrator decomposes → Workers run in parallel → Orchestrator synthesizes

Chain + Evaluator-Optimizer:
  Generate → Evaluate → Fix → Evaluate → Deploy (chain of evaluated steps)

Routing + Parallel:
  Classify query → Route to 2-3 specialists in parallel → Combine
```

---

## Query Classification

Before spawning agents, classify the query to determine the right pattern and budget:

### Depth-First

**When**: Multiple perspectives needed on the same topic.

```
"Why are AI queries slow?"
  → 3-5 agents exploring different angles of ONE problem
  → database (query plans), AI (prompt size), infra (memory/CPU)
```

### Breadth-First

**When**: Multiple independent sub-questions.

```
"Check all environments are healthy"
  → 1 agent per question, run in parallel
  → staging check, production check, localhost check
```

### Straightforward

**When**: Focused lookup or single-domain task.

```
"How many employees are in the database?"
  → Single agent, <5 tool calls
```

---

## Subagent Budgeting

More agents = more overhead. Use the minimum number of agents that provides distinct value.

| Complexity   | Agents | Calls Each | Total Budget | Example                    |
| ------------ | ------ | ---------- | ------------ | -------------------------- |
| Simple       | 1      | <5         | ~5 calls     | "Check DB connection"      |
| Standard     | 2-3    | ~5 each    | ~15 calls    | "Review and test this PR"  |
| Complex      | 3-5    | ~10 each   | ~50 calls    | "Investigate perf issue"   |
| Very Complex | 5-10   | up to 15   | ~100 calls   | "Full system health audit" |

**Budget rule**: Each additional agent adds ~2k tokens of overhead (description loading, context setup, result summarization). Only add agents when they provide distinct expertise that the existing agents lack.

---

## Anti-Patterns

1. **Over-orchestration**: Using 5 agents for a task that 1 agent can handle. If a single Read + Grep solves it, don't spawn agents.

2. **Duplicate work**: Orchestrator searches for files, then spawns an agent that searches for the same files. Delegate OR do it yourself, not both.

3. **Sequential when parallel works**: Spawning Agent A, waiting for results, then spawning Agent B, when A and B are independent. Send both Task() calls in the same message.

4. **Missing synthesis**: Spawning 5 agents but not combining their results into a coherent answer. The orchestrator must synthesize.

5. **Agent for everything**: Using `Task()` to read a single file. Use `Read()` directly -- it's faster and cheaper.

---

**Previous**: [39: Context Separation](39-context-separation.md)
**Next**: [41: Evaluation Patterns](41-evaluation-patterns.md)
