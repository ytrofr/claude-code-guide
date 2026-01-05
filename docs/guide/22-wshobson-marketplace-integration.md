# Chapter 22: wshobson Marketplace Integration (Entry #227)

**Status**: Production-Validated (Jan 1, 2026)
**Difficulty**: Beginner
**Time**: 15 minutes
**ROI**: 273 pre-built components (67 plugins, 99 agents, 107 skills)

---

## Overview

The [wshobson/agents](https://github.com/wshobson/agents) marketplace provides a curated collection of Claude Code components that integrate seamlessly with your existing setup.

### What's Included

| Component Type | Count | Examples |
|----------------|-------|----------|
| **Plugins** | 67 | backend-development, database-design, llm-application-dev |
| **Agents** | 99 | backend-architect, ai-engineer, database-optimizer |
| **Skills** | 107 | Various workflow and domain skills |

---

## Quick Setup (15 min)

### Step 1: Clone the Marketplace

```bash
cd ~/.claude
git clone https://github.com/wshobson/agents.git wshobson-agents
```

### Step 2: Link Plugins

```bash
# Create plugins directory if needed
mkdir -p ~/.claude/plugins

# Link desired plugins
ln -s ~/.claude/wshobson-agents/plugins/backend-development ~/.claude/plugins/
ln -s ~/.claude/wshobson-agents/plugins/database-design ~/.claude/plugins/
ln -s ~/.claude/wshobson-agents/plugins/llm-application-dev ~/.claude/plugins/
ln -s ~/.claude/wshobson-agents/plugins/observability-monitoring ~/.claude/plugins/
```

### Step 3: Verify Integration

```bash
# List available agents
ls ~/.claude/plugins/*/agents/

# Check agent count
find ~/.claude/plugins -name "*.md" -path "*/agents/*" | wc -l
```

---

## Key Agents

### Backend Development

| Agent | Purpose | Use When |
|-------|---------|----------|
| `backend-architect` | API design, microservices | Creating new services |
| `graphql-architect` | GraphQL federation, performance | GraphQL APIs |
| `tdd-orchestrator` | Test-driven development | Writing tests first |
| `temporal-python-pro` | Workflow orchestration | Long-running processes |

### Database Design

| Agent | Purpose | Use When |
|-------|---------|----------|
| `database-architect` | Schema modeling, tech selection | New databases |
| `sql-pro` | Query optimization, performance | SQL tuning |

### LLM Application Development

| Agent | Purpose | Use When |
|-------|---------|----------|
| `ai-engineer` | RAG systems, embeddings, agents | AI features |
| `prompt-engineer` | Prompt optimization, chain-of-thought | Improving AI |
| `vector-database-engineer` | pgvector, similarity search | Semantic search |

### Observability & Monitoring

| Agent | Purpose | Use When |
|-------|---------|----------|
| `database-optimizer` | Query performance, indexing | Slow queries |
| `network-engineer` | Cloud networking, security | Network issues |
| `observability-engineer` | Metrics, tracing, dashboards | Monitoring setup |
| `performance-engineer` | Load testing, optimization | Performance issues |

---

## Integration with Pre-prompt Hook

### Add Marketplace Agents to Triggers

Update `AUTOMATIC-TOOL-TRIGGERS.md`:

```yaml
# wshobson Marketplace Agents (Entry #227)
RAG/embeddings/prompt engineering/semantic search/vector database:
  → Use llm-application-development-skill
  → Task(subagent_type: "ai-engineer") for complex implementations
  NEVER: Build RAG without skill patterns

API design/REST/GraphQL/microservices/OpenAPI:
  → Task(subagent_type: "backend-architect")
  NEVER: Design APIs without backend-architect guidance

SQL optimization/query performance/database tuning/EXPLAIN ANALYZE:
  → Task(subagent_type: "database-optimizer")
  NEVER: Optimize queries without database-optimizer

observability/monitoring/tracing/Grafana/Prometheus/SLO:
  → Task(subagent_type: "observability-engineer")
  NEVER: Set up monitoring without observability-engineer
```

### Three-Tier Model Strategy

wshobson agents support Claude's model selection:

| Tier | Model | Use For | Agent Examples |
|------|-------|---------|----------------|
| **Opus** | Most capable | Complex architecture | backend-architect, ai-engineer |
| **Sonnet** | Balanced | Standard tasks | (default inheritance) |
| **Haiku** | Fast/cheap | Quick lookups | simple queries |

```yaml
# In agent Task() call:
Task(
  subagent_type: "backend-architect",
  model: "opus"  # For complex architectural decisions
)
```

---

## Hybrid Skills Pattern

Combine wshobson agents with your custom skills:

### Example: LLM Application Development Skill

```yaml
---
name: llm-application-development-skill
description: |
  Hybrid skill combining wshobson ai-engineer patterns with LIMOR-specific
  PostgreSQL/pgvector implementation. Use for RAG, embeddings, semantic search.
---

## When to Use

- Building RAG pipelines
- Implementing semantic search
- Adding embeddings to PostgreSQL
- Prompt engineering optimization

## wshobson Agent Integration

```bash
# For complex implementations, delegate to:
Task(subagent_type: "ai-engineer")

# For prompt optimization:
Task(subagent_type: "prompt-engineer")
```

## LIMOR-Specific Patterns

- pgvector with HNSW indexes
- Hebrew embeddings (text-multilingual-embedding-002)
- Production caching strategies
```

---

## Validation

### Check Integration (2 min)

```bash
# Verify plugins linked
ls -la ~/.claude/plugins/

# Count available agents
find ~/.claude/plugins -name "*.md" -path "*/agents/*" | wc -l
# Expected: 15-20 agents (from 4 plugins)

# Test agent availability in session
# Start Claude Code and ask:
# "What agents are available for backend development?"
```

### Test Agent Routing

Start fresh session and ask:
```
I need to design a REST API for user authentication
```

**Expected**:
- ✅ `backend-architect` agent suggested or used
- ✅ Response includes API design patterns
- ✅ References REST/microservices best practices

---

## Benefits

### Time Savings

| Task | Without Marketplace | With Marketplace | Savings |
|------|---------------------|------------------|--------|
| Design new API | 2-4 hours | 30 min | 75% |
| Set up RAG | 4-8 hours | 1 hour | 85% |
| Query optimization | 1-2 hours | 15 min | 85% |
| Monitoring setup | 4-6 hours | 1 hour | 80% |

### Quality Improvements

- **Consistent patterns**: Agents follow industry best practices
- **Fewer mistakes**: Pre-validated architectural patterns
- **Better documentation**: Agents explain their reasoning

---

## Maintenance

### Weekly Update (2 min)

```bash
cd ~/.claude/wshobson-agents
git pull origin main
```

### Add New Plugins

```bash
# Check available plugins
ls ~/.claude/wshobson-agents/plugins/

# Link new plugin
ln -s ~/.claude/wshobson-agents/plugins/NEW_PLUGIN ~/.claude/plugins/
```

---

## Troubleshooting

### Issue: Agent not found

**Check symlinks**:
```bash
ls -la ~/.claude/plugins/
# Should show -> links to wshobson-agents/
```

**Fix broken links**:
```bash
rm ~/.claude/plugins/broken-plugin
ln -s ~/.claude/wshobson-agents/plugins/correct-plugin ~/.claude/plugins/
```

### Issue: Agent not triggered

**Add to AUTOMATIC-TOOL-TRIGGERS.md**:
```yaml
your-keyword:
  → Task(subagent_type: "agent-name")
```

---

## Related Chapters

- **Chapter 21**: Pre-prompt Optimization (keyword patterns)
- **Chapter 20**: Skills Filtering (agent routing)
- **Chapter 6**: MCP Integration (tool ecosystem)

---

**Implementation Time**: 15 minutes
**Marketplace**: https://github.com/wshobson/agents
**Evidence**: LimorAI production (4 plugins, 15+ agents active)
**Last Updated**: 2026-01-05