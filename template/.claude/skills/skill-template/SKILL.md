---
name: your-skill-name-here
description: "What this skill does with action verbs. Use when [scenario 1], [scenario 2], or when user mentions [keywords]. Max 1024 chars. This IS the triggering mechanism."
Triggers: keyword1, keyword2, keyword3, exact user phrase, natural language variant
user-invocable: false
# disable-model-invocation: true  # Uncomment to prevent auto-activation (user-only via /command)
---

<!-- FRONTMATTER NOTES (delete this comment block):
  Official Anthropic fields: name, description, user-invocable, disable-model-invocation,
    allowed-tools, model, context, agent, hooks, argument-hint
  Custom fields: Triggers (for pre-prompt hook keyword matching only)
  NON-official (remove if found): priority
  Token budget: 2% of context (~15,760 chars). Override: SLASH_COMMAND_TOOL_CHAR_BUDGET=40000
  Sandbox: .claude/skills/ blocked in sandbox mode; ~/.claude/skills/ unaffected
  Ref: https://code.claude.com/docs/en/skills
-->

# Skill Name Here

**Purpose**: [One-sentence purpose]
**Created**: [YYYY-MM-DD]
**ROI**: [X hours/year saved]

---

## Usage Scenarios

**CRITICAL**: Use numbered triggers - this achieves 84% activation rate (vs 20% without)

**(1) When encountering "[exact error message or pattern]"**

- Example: "ECONNREFUSED on port 5432"
- Example: "authentication failed for user X"
- Be SPECIFIC - include error codes, numbers, exact text

**(2) When debugging [specific scenario with measurable criteria]"**

- Example: "API response time > 5 seconds"
- Example: "Test coverage < 80%"
- Include thresholds and concrete values

**(3) When seeing [observable pattern or metric]"**

- Example: "More than 3 merge conflicts"
- Example: "Build time exceeds 2 minutes"
- Be concrete and measurable

---

## Failed Attempts

**CRITICAL**: This section prevents repeating mistakes - always include it!

| Attempt                        | Why It Failed           | Lesson Learned         |
| ------------------------------ | ----------------------- | ---------------------- |
| [What you tried first]         | [Why it didn't work]    | [What to do instead]   |
| [Second approach]              | [Root cause of failure] | [Correct pattern]      |
| [Third approach if applicable] | [What went wrong]       | [Solution that worked] |

**Example**:
| Attempt | Why It Failed | Lesson Learned |
|---------|---------------|----------------|
| Manual grep search | Took 20 min, missed edge cases | Use decision tree first |
| Stack Overflow generic solution | Not project-specific | Check CORE-PATTERNS.md |

---

## Quick Start (< 5 min)

**Target**: User should get value in under 5 minutes

### Step 1: [First Action]

```bash
# Concrete command or code example
[command here]
```

**Expected Output**: [What you should see]

### Step 2: [Second Action]

```bash
# Next step
[command or code here]
```

**Validation**: [How to verify it worked]

### Step 3: [Third Action]

```bash
# Final step
[command or code here]
```

**Success**: [What success looks like]

---

## Detailed Procedure (For Complex Skills)

### Prerequisites

- [What must be installed/configured]
- [What knowledge is required]
- [What files/data are needed]

### Implementation

**Option A: [Approach Name]**

```yaml
WHEN_TO_USE: "[Specific conditions]"
STEPS: 1. [Detailed step 1]
  2. [Detailed step 2]
  3. [Detailed step 3]

CODE_EXAMPLE: |
  [Actual code that works]

VALIDATION: |
  [How to verify success]
```

**Option B: [Alternative Approach]** (if applicable)

```yaml
WHEN_TO_USE: "[Different conditions]"
TRADE_OFFS: "[Why choose this over Option A]"
```

### Troubleshooting

**If X happens**:

- Check: [What to check]
- Fix: [How to fix it]
- Prevent: [How to avoid in future]

**If Y happens**:

- Check: [What to check]
- Fix: [How to fix it]

---

## Evidence

**CRITICAL**: Include concrete numbers and dates - this builds trust and helps with activation

**Created**: YYYY-MM-DD
**Source**: [Where this pattern came from - project, research, documentation]
**Tests Run**: [X/Y] (success rate %)
**Success Rate**: [X%] (measured across N uses)
**Time Savings**: [X min/hours] per use (vs alternative approach)
**Usage Frequency**: [How often this pattern is needed]
**ROI**: [Hours saved per year] (if applicable)

**Example**:

- Created: 2025-12-14
- Tests: 15/15 (100%)
- Success Rate: 95% across 20 uses
- Time Saved: 15 min per use (vs manual debugging)
- Usage: 20 times/year
- ROI: 5 hours/year saved

---

## Integration

**Works With** (list related skills, tools, patterns):

- [Skill name] - [How they work together]
- [Pattern from CORE-PATTERNS.md] - [Relationship]
- [MCP tool] - [Integration point]

**Requires** (dependencies):

- [Skill X] must be set up first
- [Tool Y] must be installed
- [Pattern Z] must be in CORE-PATTERNS.md

**Follow-Up Skills** (what to use after this):

- [Next skill] - [When to use it]
- [Related skill] - [Sequential workflow]

---

## Success Criteria

**You've mastered this skill when**:

- [x] [Specific measurable criterion]
- [x] [Another measurable outcome]
- [x] [Third concrete success indicator]

**Example**:

- [x] Can resolve connection errors in < 5 min
- [x] Know validation commands by heart
- [x] Have used successfully 3+ times

---

## Notes

**Additional Context**:

- [Any special considerations]
- [Known limitations]
- [Future improvements planned]

**Last Updated**: YYYY-MM-DD
**Version**: 1.0
