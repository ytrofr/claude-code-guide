---
layout: default
title: "Agents and Subagents"
parent: "Part III — Extension"
nav_order: 3
redirect_from:
  - /docs/guide/36-agents-and-subagents.html
  - /docs/guide/36-agents-and-subagents/
  - /docs/guide/37-agent-teams.html
  - /docs/guide/37-agent-teams/
  - /docs/guide/40-agent-orchestration-patterns.html
  - /docs/guide/40-agent-orchestration-patterns/
---

# Agents and Subagents

**Part III — Extension · Chapter 3**

Subagents are specialized Claude Code workers with their own context window, model choice, tool restrictions, and (optionally) persistent memory. The main session dispatches them via the `Task` tool. Used well, they isolate noisy work, parallelize independent investigations, and protect the orchestrator's context budget. Used badly, they multiply cost and confuse the result.

This chapter covers what a subagent is, how to author one, when to dispatch, how to delegate cleanly, how orchestration patterns compose, and the gotchas that cause subagent systems to drift.

---

## What a Subagent Is

A subagent is a Claude Code worker spawned from the main session via `Task`. Each subagent:

- Gets its own context window (fresh, not shared with the parent)
- Can use a specific model (`haiku`, `sonnet`, `opus`)
- Can be restricted to a subset of tools
- Can have persistent memory (project, user, or none)
- Returns a result to the parent when done

**Main session vs subagent**:

| Aspect | Main session | Subagent |
|---|---|---|
| Context | Full conversation history | Fresh, scoped to the task |
| Tool access | All | Restrictable via frontmatter |
| Who dispatches | User prompts | Parent via `Task` |
| Who reads results | Everyone downstream | Only the parent |
| Lifecycle | Spans the whole session | Lives for one task |

**When to use subagents**:

- Complex multi-step tasks that benefit from isolation
- Parallel execution of independent work
- Domain expertise (database, deploy, testing, review)
- Protecting the main context from large outputs (log dumps, full-file reads)

**When NOT to use subagents**:

- Simple file reads or searches — use Read/Glob/Grep directly
- Tasks that need the full conversation context
- Quick one-off operations where spawning overhead isn't justified

---

## Creating a Subagent

Subagents live as markdown files under `.claude/agents/`.

```
.claude/agents/
  deploy-agent.md
  database-agent.md
  test-engineer.md
  debug-specialist.md
```

Each file has YAML frontmatter plus a markdown body that becomes the subagent's system prompt.

### Project-level vs user-level

| Location | Scope | Use for |
|---|---|---|
| `.claude/agents/` | Current project only | Project-specific (deploy, domain experts) |
| `~/.claude/agents/` | All projects | Cross-project (code-reviewer, security-scanner) |

When both levels define an agent with the same name, **project-level wins**. Keep each agent at one level to avoid confusion.

### Full frontmatter

```yaml
---
name: deploy-agent
description: "Deployment specialist for Cloud Run. Use when deploying to staging or production."
model: sonnet                   # sonnet | opus | haiku (inherits parent if omitted)
tools: ['Read', 'Write', 'Edit', 'Bash', 'Grep', 'Glob']
memory: project                 # project | user | local (or omit for none)
maxTurns: 15                    # cap API round-trips for cost control
permissionMode: acceptEdits     # default | plan | acceptEdits | bypassPermissions
isolation: worktree             # optional: run in isolated git worktree
skills:
  - deployment-master
  - safe-deployment
---

# Deploy Agent

You are a deployment specialist...
```

### Field reference

| Field | Required | Values | Purpose |
|---|---|---|---|
| `name` | Yes | kebab-case | Identifier for `Task(subagent_type: ...)` |
| `description` | Yes | Short + "Use when..." | Routing guidance (see below) |
| `model` | No | `sonnet` / `opus` / `haiku` | Override model (default: parent's) |
| `tools` | No | Array | Restrict to listed tools only |
| `memory` | No | `project` / `user` / `local` | Persistent memory scope |
| `maxTurns` | No | Integer | Max API round-trips |
| `permissionMode` | No | See table below | Permission handling |
| `isolation` | No | `worktree` | Run in isolated git worktree |
| `skills` | No | Array of skill names | Preload skills at startup |

Use valid model IDs only (`sonnet`, `opus`, `haiku`) or fully-pinned IDs like `claude-sonnet-4-5-20250929`. Arbitrary strings like `sonnet-4` or `claude-sonnet` fail silently.

### Description is the routing mechanism

Claude decides which subagent to spawn by reading the `description` field. Vague descriptions route badly; specific ones route correctly:

```yaml
# Weak — Claude will misroute half the time
description: "Handles data stuff"

# Strong — Claude routes correctly
description: "Database operations — schema, migrations, queries, data integrity. Use when working with Postgres or SQL."
```

Always include a "Use when..." trigger.

### Memory persistence

| Value | Scope | Use for |
|---|---|---|
| `project` | Current project | Most agents (deploy, db, test) — learns project patterns |
| `local` | Your machine, not committed | Personal workflow, experiments |
| `user` | Cross-project, all yours | Architecture, coding style, debug methodology |
| (omitted) | None | Stateless utility agents |

### Permission modes

| Mode | Behavior | Use for |
|---|---|---|
| (default) | Inherits parent session mode | Most agents |
| `plan` | Read/explore only, cannot write | Navigators, monitors, fresh-eyes reviewers |
| `acceptEdits` | Auto-accepts edits, prompts others | Code-writing agents |
| `bypassPermissions` | No prompts at all | Fully trusted automation — avoid for anything touching external systems |

### Model selection

| Model | Use for | Cost |
|---|---|---|
| `haiku` | Quick searches, simple verification | Lowest |
| `sonnet` | Most tasks (default) | Medium |
| `opus` | Complex reasoning, planning | Highest |

Pair `haiku` with `maxTurns: 5-10` for scout agents. Reserve `opus` for architecture and hard debugging.

### Worktree isolation

Setting `isolation: worktree` runs the subagent in a temporary git worktree. Useful when parallel subagents might touch overlapping files — each gets its own branch and the parent reconciles. If no changes are made, the worktree auto-cleans.

### Skills preloading

`skills: [...]` loads listed skills immediately on spawn instead of during operation. Domain-align these to the agent's purpose — a database agent shouldn't preload deployment skills.

### Listing agents

```bash
claude agents
```

Lists all agents from both scopes with their descriptions and model settings.

---

## Dispatching via the Task Tool

The parent session dispatches subagents with `Task`:

```
Task(
  subagent_type: "deploy-agent",
  description: "Deploy to staging",
  prompt: "Deploy the current branch to staging and verify health",
  model: "sonnet"   // optional override
)
```

### Parallel dispatch

Issue multiple `Task` calls in a single message and they run in parallel:

```
Task(subagent_type: "test-engineer",   prompt: "Run all tests")
Task(subagent_type: "database-agent",  prompt: "Check schema consistency")
Task(subagent_type: "deploy-agent",    prompt: "Verify staging health")
```

**Cap parallelism at 3 per turn.** Beyond that, context explosion on convergence outweighs the latency win. For 4+ independent tasks, batch into groups of 3 dispatched sequentially.

### Background tasks

```
Task(
  subagent_type: "database-agent",
  prompt: "Run comprehensive data validation",
  run_in_background: true
)
```

Check progress later by reading the task's output file.

### Restricting which subagents a parent can spawn

Use `Task(agent_type)` in the `tools` field to lock delegation targets:

```yaml
tools: ['Read', 'Write', 'Edit', 'Bash', 'Task(shifts-agent)', 'Task(beecom-agent)']
```

This parent can only spawn those two subagents. Useful for coordinator agents that should only route to known specialists. Avoid when the parent genuinely needs flexibility.

---

## Delegation Patterns

When executing a plan with 3+ tasks that touch different files or domains, delegate each to a fresh subagent and keep the main context as a lean orchestrator.

### When to delegate

| Condition | Action |
|---|---|
| Plan has 3+ tasks across different files | Delegate each task |
| Tasks span different domains (DB + API + UI) | Delegate per domain |
| A single task involves >100 lines of changes | Delegate that task |
| Main context approaching 50% | Delegate remaining tasks |

### When to stay inline

| Condition | Action |
|---|---|
| 1-2 small tasks | Inline |
| Tasks share the same file | Inline (avoid merge conflicts) |
| Each task is <50 lines | Inline |
| Tight dependency chain | Inline sequentially |
| Debugging / exploration | Inline (need accumulated context) |

### The lean orchestrator

The orchestrator should:

1. Read the plan
2. Dispatch each task via `Task` — passing **file paths**, not file contents
3. Collect results and verify on the filesystem (`git log`, file existence, grep)
4. Move to the next task

The orchestrator should NOT:

- Read source files itself
- Write code directly
- Accumulate task outputs in its own context

Target: orchestrator stays under 20% context. Each subagent gets a fresh window.

### File-boundary discipline (MANDATORY)

Every subagent prompt that edits files MUST include explicit boundaries:

```
You may ONLY create/edit these files: [list exact paths]
Do NOT modify, rename, move, or delete any other files.
If you think another file should change, report it back — do not act on it.
```

Without this, subagents autonomously expand scope to "related" sibling files in the same directory. A "condense file A" task becomes "reorganize the directory" — 15 tool calls instead of 3, and sibling files clobbered.

### Result offloading

When a subagent returns large output (>50 lines):

1. **Summarize**: "Generated 150-line auth module at `src/auth.js`"
2. **Write** the full output to a file if persistent storage is needed
3. **Reference** the path in main context, never the full content

10x token savings on multi-agent coordination. The orchestrator needs the summary, not the implementation.

### Delegation prompt template

Each subagent prompt should include:

- Exact file paths to edit
- A verification command (grep, read) the subagent runs to confirm success
- "Do NOT commit" (the orchestrator commits everything)
- "Do NOT modify any other files" boundary
- Expected return format (summary line + list of changed paths)

---

## Parallel vs Sequential Dispatch

### Parallel

Independent subagents in a single message. Wall-clock time = slowest agent.

```
Task(subagent_type: "db-agent",   prompt: "Check staging DB health")
Task(subagent_type: "db-agent",   prompt: "Check production DB health")
Task(subagent_type: "db-agent",   prompt: "Check localhost DB health")
```

**Cap at 3 per turn.** Validated by real-world multi-agent frameworks and Claude Code source itself — beyond 3, convergence inflates the parent's context and wins evaporate.

### Sequential

Each step depends on the previous output.

```
# Step 1: Research
result1 = Task(subagent_type: "Explore", prompt: "Find all API endpoints in src/routes/")

# Step 2: Analyze (uses result1)
result2 = Task(subagent_type: "code-reviewer", prompt: "Review these endpoints for security: {result1}")

# Step 3: Report (uses result2)
result3 = Task(subagent_type: "technical-writer", prompt: "Write a security report based on: {result2}")
```

Slower but cleaner for chained workflows.

### Sticky subagent state

Claude Code implements a parent-child abort hierarchy — aborting the parent cascades to all children automatically. Each child gets its own `AbortController` linked to the parent. Never share a single controller across independent subagents.

In-memory message arrays are capped at 50 entries per subagent to prevent OOM under concurrency. Full transcripts persist to disk.

When forking a subagent, Claude Code copies the exact parent message history — enabling prompt-cache reuse across parallel children. Significant cost savings on fan-out.

---

## Agent Teams

Agent teams are an experimental Claude Code feature where a lead agent coordinates teammates running in parallel with a shared task list and mailbox.

**Key difference from subagents**:

- **Subagents**: the main conversation spawns them via `Task`. They can't spawn other agents.
- **Agent teams**: a lead agent coordinates teammates who work independently and communicate with each other.

### Enabling

```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
claude --agent
```

Research preview. Token usage is significantly higher because each teammate receives full context.

### How it works

- **Lead agent**: main-thread coordinator. In default mode it uses tools AND coordinates. In delegate mode it only coordinates.
- **Teammates**: independent agents sharing a task list and a mailbox. Parallel execution, own context windows.
- **Communication**: shared task list (create/claim/complete), mailbox messages, and lifecycle hook events.

Team definitions live in `.claude/agent-teams/`:

```markdown
# Deployment Team

## Lead: deploy-agent
Coordinates the deployment pipeline.

## Teammates
### test-engineer
Runs pre-deployment tests and validates coverage.

### monitoring-agent
Monitors logs and health checks after deployment.

## Workflow
1. Lead receives deployment request
2. test-engineer runs the suite in parallel
3. Lead deploys after tests pass
4. monitoring-agent watches logs for 10 minutes
5. Lead reports final status
```

### Team hook events

| Hook | Trigger | Use for |
|---|---|---|
| `TeammateIdle` | Teammate finishes its task | Assign new work |
| `TaskCompleted` | Shared task marked done | Check dependencies |

Wire them like any hook (see chapter 1 of this Part). `TeammateIdle` is especially useful for routing queued work to whichever teammate frees up first.

### `--channels` for async approval forwarding

The `--channels` flag (GA since Claude Code 2.1.81) lets subagents forward approval requests asynchronously rather than blocking on stdin. Essential for team workflows where the lead might not be the one approving — approvals flow through a channel the human can reach later.

### Teams vs subagents

| Scenario | Subagents | Teams |
|---|---|---|
| Simple parallel tasks | Yes | No |
| Agents need to talk to each other | No | Yes |
| Cost-sensitive work | Yes | No |
| Complex multi-phase workflows | Maybe | Yes |
| Single coordinator needed | Yes | Yes |
| Agents share state | No | Yes |

**Rule of thumb**: start with subagents. Move to teams only when agents genuinely need to communicate.

---

## Orchestration Patterns

Five composable patterns, adapted from Anthropic's multi-agent cookbook.

### 1. Chain

Tasks flow through agents in sequence. See the sequential example above. Clear data flow, easy to debug. Slow; one weak link breaks the chain.

### 2. Parallel

Independent sub-tasks in parallel, results combined. See the parallel example above. Fast; higher total token cost; cannot share intermediate results.

### 3. Routing

A classifier directs each query to the best specialist. In Claude Code this is automatic — the model reads agent descriptions and routes.

```yaml
# .claude/agents/database-agent.md
description: "Database operations. Use when querying tables, checking schema, or debugging SQL."

# .claude/agents/deploy-agent.md
description: "Deployment. Use when deploying to Cloud Run or checking traffic routing."
```

Good descriptions ARE the routing logic.

### 4. Orchestrator-workers

The main session decomposes a problem, workers investigate in parallel, orchestrator synthesizes:

```
# Orchestrator decomposes:
"Investigate this performance issue across three axes."

# Workers in parallel:
Task(subagent_type: "db-agent",       prompt: "Check for slow queries in the last hour")
Task(subagent_type: "Explore",        prompt: "Find recent changes to src/services/ai/")
Task(subagent_type: "test-engineer",  prompt: "Run the perf benchmark suite")

# Orchestrator synthesizes:
"DB has 3 slow queries > 5s. A prompt selector changed yesterday. Benchmarks show 40%
 regression. Likely cause: the prompt selector change."
```

Handles complex multi-domain problems. Orchestrator context grows with each result — use result offloading aggressively.

### 5. Evaluator-optimizer

Generate, evaluate with a different agent, feed feedback back, regenerate:

```
# Step 1: Generate
Task(subagent_type: "code-reviewer",
     prompt: "Write a migration adding 'status' column to employees")

# Step 2: Evaluate (fresh eyes — different agent)
Task(subagent_type: "database-agent",
     prompt: "Review this migration for correctness and rollback safety: {script}")

# Step 3: Fix if the evaluator found issues
Task(subagent_type: "code-reviewer",
     prompt: "Fix these issues in the migration: {evaluation_feedback}")
```

The evaluator should be stricter than the generator. Cap at 3 iterations — beyond that you're not converging, you're oscillating.

### Combining patterns

Real work usually combines them:

- **Orchestrator-workers + parallel**: decompose → workers in parallel → synthesize
- **Chain + evaluator-optimizer**: generate → evaluate → fix → evaluate → deploy
- **Routing + parallel**: classify → route to 2-3 specialists in parallel → combine

---

## Query Classification for Budgeting

Before spawning, classify the query to size the subagent budget.

### Depth-first

Multiple perspectives on one problem.

```
"Investigate slow AI queries"
  → db-agent (query plans)
  + ai-agent (prompt size)
  + infra-agent (CPU/memory)
  = 3 agents exploring DIFFERENT ANGLES of ONE problem
```

### Breadth-first

Multiple independent sub-questions.

```
"Check all environments are healthy"
  → staging-agent
  + production-agent
  + localhost-agent
  = 1 agent PER QUESTION, running in parallel
```

### Straightforward

Single-domain focused lookup.

```
"How many employees in the database?"
  → database-agent only
  = SINGLE agent, <5 tool calls
```

### Budget guide

| Complexity | Agents | Calls each | Total |
|---|---|---|---|
| Simple | 1 | <5 | ~5 |
| Standard | 2-3 | ~5 | ~15 |
| Complex | 3-5 | ~10 | ~50 |
| Very complex | 5-10 | up to 15 | ~100 |

Each additional agent adds roughly 2k tokens of overhead (description loading, context setup, result summarization). Only add agents when they provide distinct expertise the existing set lacks.

---

## Two-Stage Review Pattern

After any non-trivial implementation, review in two stages. **Order matters** — spec first, then quality.

### Stage 1: spec compliance

Does the code match what was planned?

| Check | Question |
|---|---|
| Requirements | Are ALL planned requirements implemented? |
| Architecture | Does the implementation match the designed approach? |
| Scope | Did implementation drift beyond what was planned? |
| Missing | Are planned items skipped or deferred? |

If Stage 1 fails, fix spec drift BEFORE polishing code quality. Reviewing quality on a half-implemented spec wastes effort.

### Stage 2: code quality

Is the code clean and maintainable?

| Check | Question |
|---|---|
| SOLID/DRY/KISS | Principles followed? |
| Security | OWASP top-10 considered? |
| Performance | Acceptable for the use case? |
| Patterns | Matches existing conventions? |

### Fresh-eyes QA

After generating complex output, spawn a verification subagent with fresh context. The generating agent sees what it expects; a fresh agent catches what's actually there.

```
Task(
  subagent_type: "Explore",
  prompt: "Verify the changes in src/auth/ are consistent and follow project patterns.
           Check typos, missing imports, logic errors.",
  model: "haiku"
)
```

Apply after multi-file refactoring, generated test suites, deploy config changes — anything hard to manually review.

---

## Monitoring Subagents

Wire `SubagentStart` and `SubagentStop` hooks for lifecycle visibility:

```json
{
  "hooks": {
    "SubagentStart": [
      {
        "hooks": [
          { "type": "command", "command": ".claude/hooks/subagent-monitor.sh" }
        ]
      }
    ],
    "SubagentStop": [
      {
        "hooks": [
          { "type": "command", "command": ".claude/hooks/subagent-monitor.sh" }
        ]
      }
    ]
  }
}
```

Useful for cost tracking, lifecycle metrics, or emitting trace spans. See the hooks chapter for event schemas and stdin payload format.

---

## Tool Permission Models

Claude Code has two distinct tool permission mechanisms. Mixing them up is the most common agent configuration bug.

### `tools:` (frontmatter / settings)

**Restricts** the agent to ONLY the listed tools. Everything else is unavailable.

```yaml
---
name: read-only-agent
tools: ["Read", "Grep", "Glob"]   # Can ONLY use these 3
---
```

### `allowed_tools` (Agent SDK)

**Auto-approves** listed tools (no prompt). Other tools remain available — they just require approval.

### `disallowed_tools` (Agent SDK)

**Removes** listed tools from the agent's context entirely.

| Mechanism | Where | Effect |
|---|---|---|
| `tools` (list) | Agent frontmatter | Agent can ONLY use listed tools |
| `allowed_tools` | Agent SDK | Auto-approve (no prompt), others still available |
| `disallowed_tools` | Agent SDK | Tools removed entirely from agent |

In frontmatter, `tools: [...]` RESTRICTS. In the SDK, `allowed_tools` AUTO-APPROVES but does NOT restrict. The names look similar but the behaviors differ. The SDK is covered in chapter 3b.

---

## Design Patterns (Cheat Sheet)

### Domain expert

Knows one domain deeply.

```yaml
name: database-agent
description: "Database operations specialist. Use when working with schemas, migrations, queries, or data integrity."
tools: ["Read", "Bash", "Grep"]
memory: project
```

### Lightweight scout

Fast, cheap exploration.

```yaml
name: codebase-explorer
description: "Fast codebase exploration. Use when searching for files, patterns, or understanding structure."
model: haiku
tools: ["Read", "Grep", "Glob"]
maxTurns: 10
```

### Expensive expert

High-quality reasoning for critical tasks.

```yaml
name: architecture-agent
description: "System architecture decisions. Use when planning major refactors or new features."
model: opus
memory: user       # cross-project architectural knowledge
maxTurns: 15
```

---

## Anti-Patterns

1. **Over-orchestration** — spawning 5 agents for work a single `Read + Grep` solves. If you can do it inline, do it inline.
2. **Duplicate work** — the orchestrator searches for files, then spawns an agent that searches for the same files. Delegate OR do it yourself, never both.
3. **Sequential when parallel works** — issuing Task A, waiting, then Task B, when A and B are independent. Issue both in the same message.
4. **Missing synthesis** — spawning 5 agents but never combining their results. The orchestrator must synthesize.
5. **Agent for everything** — using `Task` to read a single file. Use `Read` directly — faster and cheaper.
6. **Forgetting file-boundary discipline** — subagents autonomously expand scope. Always list the exact files they may touch.
7. **No result offloading** — pulling 500-line subagent outputs back into the orchestrator context. Summarize + reference a file instead.

---

## Common Gotchas

- **Subagents can't read another session's transcripts.** Each session is a sealed context. Pass what the subagent needs in the prompt or write it to disk first.
- **Model IDs fail silently.** Only `sonnet`, `opus`, `haiku`, or fully-pinned IDs work. `sonnet-4`, `claude-sonnet`, etc. — the subagent falls back to a default without warning.
- **Project-level agents override user-level.** If a subagent behaves unexpectedly, check whether a same-named file exists at `.claude/agents/` — it wins over `~/.claude/agents/`.
- **`bypassPermissions` + external systems = pain.** Never use it for agents that touch databases, APIs, or deploys. `acceptEdits` is the safe ceiling.
- **3-agent parallel cap.** 4+ parallel subagents explode the parent's context on convergence. Batch into groups of 3.
- **Token multiplier with teams.** Each teammate gets a full context window. Use `haiku` for simple teammates and `maxTurns` on everyone.
- **Worktree cleanup.** `isolation: worktree` auto-cleans on no-op runs, but failures can leave stale worktrees. List with `git worktree list` and prune with `git worktree prune`.

---

## Preparing for Teams (Do Now)

Even without enabling teams:

1. **Standardize frontmatter** — valid models, memory fields, maxTurns
2. **Add monitoring hooks** — `SubagentStart` / `SubagentStop` for visibility
3. **Design team groupings** — document which agents work together
4. **Keep agents focused** — one clear responsibility per agent

This groundwork makes team adoption seamless when the feature stabilizes.
