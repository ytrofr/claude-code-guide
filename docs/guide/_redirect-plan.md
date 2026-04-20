---
layout: default
title: "Redirect Plan (internal)"
nav_exclude: true
sitemap: false
---

# Redirect Plan (internal reference)

Old numbered chapter URLs → new Part-based URLs. As each chapter is rewritten in phases B2–B7, add the corresponding `redirect_from:` array to its front matter.

**Not a user-facing page. Excluded from nav and sitemap.**

## Mapping table

| Old URL | New home | Phase |
|---|---|---|
| /docs/guide/02-minimal-setup.html | /docs/guide/part1-foundation/01-installation.html | B7 |
| /docs/guide/04-task-tracking-system.html | /docs/guide/part2-workflow/05-session-lifecycle.html | B6 |
| /docs/guide/06-mcp-integration.html | /docs/guide/part3-extension/02-mcp-integration.html | B5 |
| /docs/guide/12-memory-bank-hierarchy.html | /docs/guide/part4-context-engineering/01-memory-bank.html | B4 |
| /docs/guide/13-claude-code-hooks.html | /docs/guide/part3-extension/01-hooks.html | B5 |
| /docs/guide/14-git-vs-claude-hooks-distinction.html | /docs/guide/part3-extension/01-hooks.html#git-vs-claude | B5 |
| /docs/guide/15-progressive-disclosure.html | /docs/guide/part4-context-engineering/05-progressive-disclosure.html | B4 |
| /docs/guide/18-perplexity-cost-optimization.html | /docs/guide/part3-extension/02-mcp-integration.html#perplexity | B5 |
| /docs/guide/19-playwright-e2e-testing.html | /docs/guide/part3-extension/02-mcp-integration.html#playwright | B5 |
| /docs/guide/19b-playwright-mcp-integration.html | /docs/guide/part3-extension/02-mcp-integration.html#playwright | B5 |
| /docs/guide/22-wshobson-marketplace-integration.html | /docs/guide/part3-extension/06-plugins-and-marketplace.html | B5 |
| /docs/guide/23-session-documentation-skill.html | /docs/guide/part2-workflow/05-session-lifecycle.html | B6 |
| /docs/guide/25-best-practices-reference.html | /docs/guide/part1-foundation/02-claude-md-primer.html | B7 |
| /docs/guide/26-claude-code-rules-system.html | /docs/guide/part4-context-engineering/02-rules-system.html | B4 |
| /docs/guide/27-fast-cloud-run-deployment.html | /docs/guide/part3-extension/08-cloud-run-deploy-patterns.html | B5 |
| /docs/guide/28-skill-optimization-patterns.html | /docs/guide/part3-extension/04-skills-authoring.html | B5 |
| /docs/guide/29-branch-context-system.html | /docs/guide/part4-context-engineering/04-context-budget.html | B4 |
| /docs/guide/32-document-automation.html | /docs/guide/part2-workflow/05-session-lifecycle.html | B6 |
| /docs/guide/34-basic-memory-mcp-integration.html | /docs/guide/part4-context-engineering/03-basic-memory-mcp.html | B4 |
| /docs/guide/35-skill-optimization-maintenance.html | /docs/guide/part3-extension/05-skills-maintenance.html | B5 |
| /docs/guide/36-agents-and-subagents.html | /docs/guide/part3-extension/03-agents-and-subagents.html | B5 |
| /docs/guide/37-agent-teams.html | /docs/guide/part3-extension/03-agents-and-subagents.html#teams | B5 |
| /docs/guide/38-context-costs-and-skill-budget.html | /docs/guide/part4-context-engineering/04-context-budget.html | B4 |
| /docs/guide/39-context-separation.html | /docs/guide/part4-context-engineering/04-context-budget.html | B4 |
| /docs/guide/40-agent-orchestration-patterns.html | /docs/guide/part3-extension/03-agents-and-subagents.html | B5 |
| /docs/guide/42-session-memory-compaction.html | /docs/guide/part2-workflow/05-session-lifecycle.html | B6 |
| /docs/guide/43-claude-agent-sdk.html | /docs/guide/part3-extension/03b-claude-agent-sdk.html | B5 |
| /docs/guide/44-skill-design-principles.html | /docs/guide/part3-extension/04-skills-authoring.html | B5 |
| /docs/guide/45-plan-mode-checklist.html | /docs/guide/part2-workflow/01-plan-mode.html | B6 |
| /docs/guide/50-verification-feedback-loop.html | /docs/guide/part2-workflow/04-verify-canary.html | B6 |
| /docs/guide/51-persistent-memory-patterns.html | /docs/guide/part4-context-engineering/01-memory-bank.html | B4 |
| /docs/guide/53-pre-validation-probe.html | /docs/guide/part2-workflow/01-plan-mode.html#pre-validation | B6 |
| /docs/guide/54-claude-code-2176-new-features.html | /docs/guide/part6-reference/01-cc-version-history.html#2176 | B2 |
| /docs/guide/57-claude-code-2177-2181-features.html | /docs/guide/part6-reference/01-cc-version-history.html#2177-2181 | B2 |
| /docs/guide/58-claude-skills-cookbook-patterns.html | /docs/guide/part3-extension/04-skills-authoring.html#cookbook | B5 |
| /docs/guide/60-claude-code-2182-2183-features.html | /docs/guide/part6-reference/01-cc-version-history.html#2182-2183 | B2 |
| /docs/guide/61-stack-audit-maintenance.html | /docs/guide/part3-extension/05-skills-maintenance.html#stack-audit | B5 |
| /docs/guide/62-security-scanning.html | /docs/guide/part6-reference/06-security-checklist.html | B2 |
| /docs/guide/63-plugin-marketplace.html | /docs/guide/part3-extension/06-plugins-and-marketplace.html | B5 |
| /docs/guide/64-claude-code-2184-2186-features.html | /docs/guide/part6-reference/01-cc-version-history.html#2184-2186 | B2 |
| /docs/guide/65-cross-project-ai-knowledge-sharing.html | /docs/guide/part5-advanced/06-cross-project-knowledge.html | B3 |
| /docs/guide/66-claude-code-2187-2188-features.html | /docs/guide/part6-reference/01-cc-version-history.html#2187-2188 | B2 |
| /docs/guide/70-claude-code-2189-2192-features.html | /docs/guide/part6-reference/01-cc-version-history.html#2189-2192 | B2 |
| /docs/guide/71-claude-code-2193-2194-features.html | /docs/guide/part6-reference/01-cc-version-history.html#2193-2194 | B2 |
| /docs/guide/72-claude-code-2195-2197-features.html | /docs/guide/part6-reference/01-cc-version-history.html#2195-2197 | B2 |
| /docs/guide/73-claude-code-2198-2199-features.html | /docs/guide/part6-reference/01-cc-version-history.html#2198-2199 | B2 |
| /docs/guide/74-claude-code-monitor-tool.html | /docs/guide/part5-advanced/04-monitor-tool.html | B3 |
| /docs/guide/75-claude-code-statusline-patterns.html | /docs/guide/part5-advanced/05-statusline-patterns.html | B3 |
| /docs/guide/76-inter-agent-coordination.html | /docs/guide/part5-advanced/02-inter-agent-bus.html | B3 |
| /docs/guide/77-context-governance-system.html | /docs/guide/part4-context-engineering/06-context-governance.html | B4 |
| /docs/guide/78-self-telemetry-for-claude-code.html | /docs/guide/part5-advanced/03-self-telemetry.html | B3 |

## Pruned (no redirect — 404 or top-level /docs/guide/ index)

05, 17, 20, 21, 24, 30, 30b, 31, 31b, 33, 41, 46, 47, 48, 49, 52, 55, 56, 59, 67, 68, 69
