# Chapter 25: Best Practices Reference

**Created**: 2026-01-05
**Source**: Production Entry #189 (Best Practices Index)
**Pattern**: Research-backed patterns from Anthropic + Claude documentation
**Coverage**: 33 articles indexed, 15 fully extracted

---

## Overview

This chapter provides a comprehensive index of Anthropic best practices research, organized by category with extraction status and implementation guidance.

---

## 📊 Index Statistics

| Metric                     | Count | Status               |
| -------------------------- | ----- | -------------------- |
| **Total Articles**         | 33    | Indexed ✅           |
| **Anthropic Engineering**  | 18    | Indexed ✅           |
| **Claude.com Blog**        | 15    | Indexed ✅           |
| **Fully Extracted**        | 15    | Implementation-ready |
| **Priority 1 IMPLEMENTED** | 3     | Production patterns  |

---

## 🚀 Priority 1: Critical Patterns (Extracted & Implemented)

### Context Engineering

**Article**: [Effective Context Engineering for AI Agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
**Key Patterns**:

- Just-in-time retrieval (load context when needed, not upfront)
- Hybrid strategy (always-loaded core + on-demand details)
- Structured notes for multi-session continuity
- 34-62% token reduction with zero functionality loss

**Implementation**: See `memory-bank/always/` (always-loaded) + `memory-bank/ondemand/` (on-demand)

### Long-Running Agent Harnesses

**Article**: [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
**Key Patterns**:

- Feature list guardrails (track what's done)
- Incremental progress (one feature at a time)
- Git + progress file pairing
- Session checkpoints

**Implementation**: See `SESSION-PROTOCOL.md`, `system-status.json`

### Advanced Tool Use

**Article**: [Advanced Tool Use on Claude Developer Platform](https://www.anthropic.com/engineering/advanced-tool-use)
**Key Patterns**:

- Tool Search (51k token savings)
- Parallel Tool Calling (PTC) - 37% latency reduction
- Tool examples (+18% accuracy)
- Consolidation over proliferation

**Implementation**: See Chapter 20 (Skills Filtering), Entry #198

### Writing Effective Tools

**Article**: [Writing Effective Tools for Agents](https://www.anthropic.com/engineering/writing-tools-for-agents)
**Key Patterns**:

- Pagination defaults (LIMIT 10, not unlimited)
- Tool consolidation (733% ROI)
- Meaningful responses (not just "done")
- Error context in responses

**Implementation**: See Chapter 17-24 (skill patterns)

---

## 🤖 Skills & Agents Category

| Article                               | URL                                                                                                 | Key Takeaway                               |
| ------------------------------------- | --------------------------------------------------------------------------------------------------- | ------------------------------------------ |
| Equipping Agents with Skills          | [Link](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) | 84% activation rate with numbered triggers |
| Building Agents with Claude Agent SDK | [Link](https://www.anthropic.com/engineering/building-agents-with-the-claude-agent-sdk)             | SDK patterns for custom agents             |
| Building Effective Agents             | [Link](https://www.anthropic.com/engineering/building-effective-agents)                             | Workflow patterns vs custom agents         |
| Multi-Agent Research System           | [Link](https://www.anthropic.com/engineering/multi-agent-research-system)                           | Agent coordination patterns                |

---

## 🛠️ Context & Tools Category

| Article                       | URL                                                                                       | Key Takeaway                            |
| ----------------------------- | ----------------------------------------------------------------------------------------- | --------------------------------------- |
| Effective Context Engineering | [Link](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) | Just-in-time retrieval, hybrid strategy |
| Writing Effective Tools       | [Link](https://www.anthropic.com/engineering/writing-tools-for-agents)                    | Pagination defaults, consolidation      |
| Advanced Tool Use             | [Link](https://www.anthropic.com/engineering/advanced-tool-use)                           | Tool Search, PTC, examples              |
| The "Think" Tool              | [Link](https://www.anthropic.com/engineering/claude-think-tool)                           | Extended thinking for complex tasks     |
| Contextual Retrieval          | [Link](https://www.anthropic.com/engineering/contextual-retrieval)                        | RAG optimization patterns               |

---

## 🪝 Hooks & Configuration Category

| Article                         | URL                                                             | Key Takeaway                           |
| ------------------------------- | --------------------------------------------------------------- | -------------------------------------- |
| How to Configure Hooks          | [Link](https://claude.com/blog/how-to-configure-hooks)          | 11 hook events for workflow automation |
| Using CLAUDE.md Files           | [Link](https://claude.com/blog/using-claude-md-files)           | Project context customization          |
| Building Skills for Claude Code | [Link](https://claude.com/blog/building-skills-for-claude-code) | Skill creation workflow                |

---

## 🔌 MCP & Execution Category

| Article                 | URL                                                                   | Key Takeaway               |
| ----------------------- | --------------------------------------------------------------------- | -------------------------- |
| Code Execution with MCP | [Link](https://www.anthropic.com/engineering/code-execution-with-mcp) | MCP server patterns        |
| Desktop Extensions      | [Link](https://www.anthropic.com/engineering/desktop-extensions)      | One-click MCP installation |

---

## 💰 Cost Optimization Category

| Article                   | URL                                                                          | Key Takeaway                                     |
| ------------------------- | ---------------------------------------------------------------------------- | ------------------------------------------------ |
| Prompt Caching            | [Link](https://platform.claude.com/docs/en/build-with-claude/prompt-caching) | 90% cost reduction on repeated loads             |
| Building Effective Agents | [Link](https://www.anthropic.com/research/building-effective-agents)         | Workflow patterns (3x faster than custom agents) |

---

## 📚 Claude.com Blog Articles (15)

### Skills Category

- [Extending Claude's Capabilities](https://claude.com/blog/extending-claude-capabilities-with-skills-mcp-servers)
- [Skills for Organizations](https://claude.com/blog/organization-skills-and-directory)
- [Building Skills for Claude Code](https://claude.com/blog/building-skills-for-claude-code) ⭐
- [How to Create Skills](https://claude.com/blog/how-to-create-skills-key-steps-limitations-and-examples)
- [Skills Explained](https://claude.com/blog/skills-explained)

### Hooks & Configuration

- [How to Configure Hooks](https://claude.com/blog/how-to-configure-hooks) ⭐
- [Using CLAUDE.md Files](https://claude.com/blog/using-claude-md-files) ⭐

### Enterprise & Use Cases

- [Enterprise AI Agents in 2026](https://claude.com/blog/how-enterprises-are-building-ai-agents-in-2026)
- [Anthropic Legal Team Case Study](https://claude.com/blog/how-anthropic-uses-claude-legal)
- [YC Startups with Claude Code](https://claude.com/blog/building-companies-with-claude-code)

---

## 🎯 Extraction Workflow

When extracting patterns from new articles:

```yaml
EXTRACTION_WORKFLOW:
  Step_1: "WebFetch(url, 'Extract key patterns, rules, anti-patterns, code examples')"
  Step_2: "Pattern analysis (5 min)"
  Step_3: "Cross-reference check (3 min)"
  Step_4: "Create entry if new patterns (15 min)"
  Step_5: "Update this index with extraction status (2 min)"
  Step_6: "Update implementation guide if significant (10 min)"
```

---

## 📅 Maintenance Schedule

| Frequency     | Task                                                       |
| ------------- | ---------------------------------------------------------- |
| **Weekly**    | Check for new Anthropic blog posts                         |
| **Monthly**   | Review extraction priorities based on active work          |
| **Quarterly** | Validate existing entries still align with latest research |

---

## 🔗 Cross-Reference with Implementation Guide

| Chapter                                 | Related Research                          |
| --------------------------------------- | ----------------------------------------- |
| **Chapter 13**: Claude Code Hooks       | How to Configure Hooks                    |
| **Chapter 17**: Skill Detection         | Equipping Agents with Skills              |
| **Chapter 20**: Skills Filtering        | Advanced Tool Use, Writing Tools          |
| **Chapter 21**: Pre-prompt Optimization | Effective Context Engineering             |
| **Chapter 24**: Keyword Enhancement     | Skills patterns + context engineering     |
| **Chapter 36**: Agents and Subagents    | Building Effective Agents, Agent SDK      |
| **Chapter 37**: Agent Teams             | Multi-Agent Research System               |
| **Chapter 38**: Context Costs & Budget  | Best Practices, Skills, Features Overview |

---

## 📖 Official Documentation References

These are pages from Anthropic's official Claude Code documentation site (`code.claude.com`) that cover core concepts referenced throughout this guide:

| Documentation Page | URL                                                       | Key Topics                                                                                                                  |
| ------------------ | --------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| Best Practices     | [Link](https://code.claude.com/docs/en/best-practices)    | Context management, CLAUDE.md pruning, verification patterns, subagent best practices                                       |
| Sub-agents         | [Link](https://code.claude.com/docs/en/sub-agents)        | Agent memory (project/user), skills preloading, permission modes, hooks for agents                                          |
| Skills             | [Link](https://code.claude.com/docs/en/skills)            | Description budget (2% / `SLASH_COMMAND_TOOL_CHAR_BUDGET`), description format, `disable-model-invocation`, `context: fork` |
| Features Overview  | [Link](https://code.claude.com/docs/en/features-overview) | Context cost table (what loads when), comparison of extension points (skills vs agents vs hooks vs MCP)                     |

**Related chapters**: [Chapter 36](36-agents-and-subagents.md) (agents), [Chapter 38](38-context-costs-and-skill-budget.md) (context costs & skill budget), [Chapter 20](20-skills-filtering-optimization.md) (skill filtering)

---

## 📊 Implementation Priority Matrix

### High ROI (Implement First)

1. **Context Optimization** (34% token reduction) - Chapter 21
2. **Skill Detection** (100% accuracy) - Chapter 17, 24
3. **Tool Consolidation** (733% ROI) - Chapter 20
4. **Session Protocol** (3x continuity) - Chapter 12

### Medium ROI (Phase 2)

1. **MCP Integration** (zero-token validation)
2. **Perplexity Caching** (80% cost savings)
3. **Playwright E2E** (100% test coverage)

### Lower Priority (As-Needed)

1. Enterprise patterns
2. Slack integration
3. Advanced RAG

---

## 🎯 Quick Reference Links

**Most Important Articles** (Start Here):

1. [Effective Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) - Foundation pattern
2. [Building Skills for Claude Code](https://claude.com/blog/building-skills-for-claude-code) - Skill creation
3. [How to Configure Hooks](https://claude.com/blog/how-to-configure-hooks) - Automation
4. [Writing Effective Tools](https://www.anthropic.com/engineering/writing-tools-for-agents) - Tool design

**Implementation Guide Chapters**:

- [Chapter 17](17-skill-detection-enhancement.md) - 4-phase skill detection
- [Chapter 20](20-skills-filtering-optimization.md) - Score-at-match-time
- [Chapter 21](21-pre-prompt-optimization.md) - 68% reduction
- [Chapter 24](24-skill-keyword-enhancement-methodology.md) - Synonym expansion

---

## 📈 Success Metrics

| Metric                  | Target       | Current | Status |
| ----------------------- | ------------ | ------- | ------ |
| Articles indexed        | 30+          | 33      | ✅     |
| Priority 1 extracted    | 4            | 4       | ✅     |
| Implementation coverage | 80%          | 85%     | ✅     |
| ROI documented          | 10+ patterns | 15+     | ✅     |

---

**Research Authority**: Anthropic engineering + Claude.com blog
**Sacred Compliance**: All patterns validated against Sacred Commandments
**ROI**: 50-100h/year saved with research-backed patterns vs trial-and-error
**Updates**: Monthly review of new Anthropic publications
