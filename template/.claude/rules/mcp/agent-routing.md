# MCP Agent Ecosystem Preferences

**Scope**: Universal agent coordination patterns
**Authority**: Global routing preferences

---

## Agent Coordination

```yaml
AGENT_COORDINATION_PREFERENCES:
  Primary: MCP Professional Agents + Project-Specific Agents
  Style: Context-aware routing based on task requirements
  Routing: Task analysis -> optimal agent selection -> coordinated execution
  Transparency: Always show agent selection reasoning
  Performance: <2ms agent access, 100% functionality preservation
```

---

## Query Classification

```yaml
QUERY_CLASSIFICATION:
  Depth_First:
    When: "Multiple perspectives on same topic"
    Pattern: "3-5 parallel agents exploring different angles"
    Example: "Investigate slow queries -> DB agent + API agent + monitoring agent"

  Breadth_First:
    When: "Multiple independent sub-questions"
    Pattern: "1 agent per question, run in parallel"
    Example: "Check all environments -> staging agent + production agent + localhost"

  Straightforward:
    When: "Focused lookup or single-domain task"
    Pattern: "Single agent, <5 tool calls"
    Example: "Check row count -> database-agent only"

SUBAGENT_BUDGET:
  Simple: "1 agent, <5 tool calls"
  Standard: "2-3 agents, ~5 calls each"
  Complex: "3-5 agents, ~10 calls each"
  Very_Complex: "5-10 agents, up to 15 calls each (max 20)"
  Rule: "More subagents = more overhead. Only add when they provide distinct value."
```

---

## Specialized Agent Routing

Customize this table for your project:

| Task Type     | Primary Agent      | Secondary           |
| ------------- | ------------------ | ------------------- |
| Backend/API   | backend-engineer   | integration-agent   |
| Database      | database-architect | accuracy validation |
| Frontend/UI   | frontend-developer | ui-ux-designer      |
| Quality       | qa-engineer        | code-review         |
| Architecture  | architecture-agent | cloud-architect     |
| Documentation | technical-writer   | documentation-agent |
