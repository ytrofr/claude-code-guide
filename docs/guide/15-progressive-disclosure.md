# Chapter 15: Progressive Disclosure

**Purpose**: Load minimum context first, expand on demand for token efficiency
**Source**: Anthropic research (30% quality improvement with proper organization) + Production validation (53% token savings)
**Applies to**: Skills, memory bank files, documentation, any large context

---

## What is Progressive Disclosure?

Progressive disclosure means starting with a compact summary and loading more detail only when needed. Instead of dumping all your documentation into every conversation, you provide a small, high-signal overview and let Claude read deeper when a task requires it.

This matters because Claude Code's context window is finite. Loading 100k tokens of reference documentation when you only need 5k wastes capacity and can actually reduce output quality. Anthropic research shows a 30% quality improvement when context is properly organized and loaded progressively rather than all at once.

---

## The 3-Level Pattern

### Level 1: MINI Files (Always Loaded)

Compact summaries that give Claude enough to route decisions and answer common questions. These are `@`-imported in CLAUDE.md and loaded every conversation.

**Target size**: 500-2,000 tokens (30-80 lines)

```markdown
# DATABASE-PATTERNS-MINI.md

## Quick Reference

- Golden Rule: always use employee_id (never just id)
- Financial: .toFixed(2) for all monetary values
- Timezone: always cast with ::date

Full reference: memory-bank/ondemand/database/patterns.md
```

### Level 2: Full File (Read on Demand)

The complete reference document. Claude reads this when it needs more detail than the MINI provides.

**Target size**: 5,000-10,000 tokens (200-400 lines)

Claude loads this with the Read tool when a task requires detailed patterns, examples, or procedures that the MINI file only summarizes.

### Level 3: Surgical Loading (Offset + Limit)

For very large files (400+ lines), load only the relevant section rather than the entire document.

```
Read(file="COMPLETE-SCHEMA.md", offset=150, limit=50)
```

This loads lines 150-200, getting just the table definition you need without pulling in the entire schema.

---

## Creating a MINI File

Take a large document and extract only what is needed 90% of the time.

**Before** (full file, 400 lines):

```markdown
# API Integration Patterns

## Beecom POS API

Endpoint: https://api.beecommcloud.com/v2/
Auth: OAuth2 client_credentials
Content-Type: application/x-www-form-urlencoded
Token endpoint: /connect/token
... (50 more lines of auth details)
... (100 lines of endpoint inventory)
... (200 lines of error handling)
```

**After** (MINI file, 40 lines):

```markdown
# API-MINI.md

## Quick Reference

- Beecom: api.beecommcloud.com/v2/ (OAuth2, 823 products)
- ShiftOrganizer: app.shiftorganizer.com/api (user/pass, 129 employees)
- Vertex AI: gemini-2.5-flash (us-central1)

Full reference: memory-bank/ondemand/api/integrations.md
```

**Rule**: The MINI file should answer "which API do I use?" and "what are the basics?" The full file answers "how exactly do I authenticate?" and "what are all the endpoints?"

---

## Progressive Disclosure for Skills

Skills benefit especially from this pattern because Claude loads all activated skill content into the conversation.

### Skill with References

```
deployment-workflow-skill/
├── SKILL.md (2-3k) - Core workflow steps
└── references/
    ├── cloud-run.md (2k) - Cloud Run specifics
    ├── traffic-routing.md (2k) - Traffic management
    └── rollback.md (2k) - Rollback procedures
```

The main SKILL.md contains the workflow and tells Claude which reference to read based on the task. Only one reference loads per query instead of all three.

### Real Example: api-endpoint-inventory-skill

- **Before**: 8.5k tokens always loaded (every query pays the cost)
- **After**: 2.5k base + 1.5-2.6k per reference = 4-5k per query
- **Savings**: 47-53% per query
- **Validation**: 3 different questions each loaded a different reference file

---

## Anti-Patterns

**Loading everything upfront**: Importing every documentation file in CLAUDE.md. This wastes context and reduces quality.

**Duplicating content**: Having the same information in both the MINI and full file. When one is updated, the other becomes stale. The MINI should reference the full file, not copy from it.

**Skipping the MINI level**: Going straight from "nothing loaded" to "read the entire 500-line file." The summary level prevents unnecessary full loads for simple questions.

**Making MINI files too detailed**: A MINI file that is 200 lines is not a summary. Keep it under 80 lines. If Claude needs more, it will read the full file.

---

## Token Budget Guidelines

| Context Level | Budget   | Quality Impact                |
| ------------- | -------- | ----------------------------- |
| Under 50%     | Optimal  | Best code quality             |
| 50-75%        | Good     | Slight degradation            |
| 75-90%        | Degraded | Checkpoint and start fresh    |
| Over 90%      | Poor     | Errors increase significantly |

**The 75% rule**: Anthropic research indicates that code quality begins to degrade above 75% context usage. When you approach this threshold, commit your work and start a fresh session. Progressive disclosure helps you stay well below this limit.

---

## Implementation Checklist

1. Identify files that are auto-loaded but rarely needed in full
2. Create MINI versions with just the essential quick-reference content
3. Add a "Full reference: path/to/full-file.md" pointer in each MINI
4. Replace the `@` import in CLAUDE.md with the MINI version
5. For skills over 5k tokens, split into SKILL.md + references/ subdirectory
6. Monitor context usage and adjust as needed

---

**Previous**: [14: Git vs Claude Hooks](14-git-vs-claude-hooks-distinction.md)
**Next**: [16: Skills Activation Breakthrough](16-skills-activation-breakthrough.md)
