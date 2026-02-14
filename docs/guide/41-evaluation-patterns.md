---
layout: default
title: "Evaluation Patterns - Test AI Agent Quality Systematically"
description: "Implement AI agent evaluation using Anthropic's 6 best practices: capability vs regression tagging, outcome-based grading, pass^k consistency, LLM-as-judge, transcript review, and saturation monitoring."
---

# Chapter 41: Evaluation Patterns

Testing AI agents is fundamentally different from testing traditional software. Agents produce non-deterministic outputs, interact with tools in unpredictable ways, and may give correct answers in unexpected formats. This chapter covers Anthropic's 6 evaluation best practices for building reliable agent test suites.

**Purpose**: Build robust evaluation systems for AI agents and LLM-powered features
**Source**: Anthropic "Demystifying Evals for AI Agents" + evaluator_optimizer.ipynb
**Difficulty**: Intermediate
**Time**: 2-4 hours for initial implementation

---

## Why Agent Evals Are Different

Traditional test: `assert output === expected` -- binary, deterministic.

Agent test: The agent might query a database, call 3 tools, format the answer in Hebrew, and return the right number wrapped in a sentence. A strict string match fails despite a correct answer.

**Key insight**: Evaluate OUTCOMES, not exact outputs.

---

## 1. Capability vs Regression Tagging

Not all test queries are equal. Separate them into two categories:

### Regression Queries

Queries that **must always pass**. These are well-understood, stable capabilities. A failure here is a bug.

```javascript
const REGRESSION = [
  "כמה עובדים?", // Employee count -- always works
  "שלום", // Greeting -- always works
  "מה שעות העבודה?", // Work hours -- always works
];
```

### Capability Queries

Queries that **may fail sometimes**. These test emerging or complex capabilities. A failure here is informational, not a blocker.

```javascript
const CAPABILITY = [
  "פרט את העלויות לפי מחלקה", // Department breakdown -- complex
  "השווה הכנסות בין סניפים", // Branch comparison -- complex
  "למה ירדה הרווחיות?", // Why analysis -- very complex
];
```

### Why This Matters

Without tagging, you treat all failures equally. A greeting failure (critical bug) gets the same priority as a complex comparison failure (known limitation). Tagging lets you:

- **Block deployments** on regression failures only
- **Track progress** on capability queries without false alarms
- **Prioritize fixes** based on category

---

## 2. Outcome-Based Grading

Instead of matching exact strings, verify the outcome is correct.

### The Problem

```
Query: "כמה עובדים?"
Expected: "129 עובדים"
Actual: "יש 129 עובדים פעילים"
Result: FAIL (string mismatch) ← Wrong! The answer is correct.
```

### The Solution

Extract the key value and validate it against the real data source:

```javascript
async function validateEmployeeCount(response, pool) {
  // Get ground truth from database
  const { rows } = await pool.query("SELECT COUNT(*) FROM employees");
  const expected = parseInt(rows[0].count);

  // Extract number from response (any format)
  const actual = extractNumber(response);

  // Outcome check: is the number correct?
  return { pass: Math.abs(actual - expected) <= 1, expected, actual };
}
```

### Grading Strategies

| Strategy              | When to Use                    | Example                              |
| --------------------- | ------------------------------ | ------------------------------------ |
| Exact match           | Structured outputs (JSON, SQL) | API response format validation       |
| Number extraction     | Numerical answers              | Employee count, revenue totals       |
| Keyword presence      | Qualitative answers            | "Contains Hebrew greeting"           |
| Database-backed       | Data accuracy                  | Compare response number to DB count  |
| LLM-as-judge (see #4) | Complex quality assessment     | "Is this a natural Hebrew response?" |

---

## 3. pass^k Consistency Testing

A query that passes 4 out of 5 times is unreliable for users. Measure consistency, not just capability.

### The Math

- **pass@k**: Probability of at least 1 success in k trials. Measures capability.
- **pass^k**: Probability of ALL k trials succeeding. Measures consistency.

```
97% pass rate:
  pass@5 = 1 - (0.03)^5 = 99.99% (almost certain to work once)
  pass^5 = (0.97)^5     = 85.9%  (only 86% chance ALL 5 work)
```

A 97% pass rate sounds great, but users experience the 14% inconsistency.

### Implementation

```javascript
async function runConsistency(queryFn, query, trials = 5) {
  const results = [];
  for (let i = 0; i < trials; i++) {
    results.push(await queryFn(query));
  }

  const passes = results.filter((r) => r.pass).length;

  return {
    pass_at_k: passes > 0, // Did it work at least once?
    pass_k: passes === trials, // Did it work EVERY time?
    consistency_rate: passes / trials,
    flaky: passes > 0 && passes < trials, // Sometimes yes, sometimes no
  };
}
```

### When to Use

- **Regression queries**: Run pass^5 monthly. Any flaky regression = investigate immediately.
- **Before deployment**: Run pass^3 on critical queries. Any failure = block deploy.
- **Capability queries**: Run pass@5 to measure improvement over time.

---

## 4. LLM-as-Judge Grading

For nuanced quality assessment beyond pass/fail, use an LLM to grade responses on a scale.

### Criteria (1-5 Scale)

| Criterion        | 1 (Poor)             | 5 (Excellent)                  |
| ---------------- | -------------------- | ------------------------------ |
| Factual Accuracy | Wrong data           | Verified correct               |
| Language Quality | Garbled/unnatural    | Natural, grammatically correct |
| Completeness     | Misses key points    | Fully answers the question     |
| Confidence       | Over/under-confident | Appropriate certainty          |

### Cost Optimization

Grading every response with an LLM is expensive. Optimize:

```javascript
const GRADE_STRATEGY = {
  failures: true, // Always grade failures (understand why)
  sample_rate: 0.1, // Grade 10% of passes (spot check)
  regression_only: false, // Grade all categories
};
```

This means: grade all failures + 10% of successes = ~20% of total queries graded.

### Example Prompt

```
Grade this AI response on 4 criteria (1-5 scale):

Query: {query}
Response: {response}
Expected outcome: {expected}

Criteria:
1. Factual Accuracy: Is the data correct?
2. Language Quality: Is the Hebrew natural?
3. Completeness: Does it fully answer the question?
4. Confidence: Is the certainty level appropriate?

Return JSON: {"accuracy": N, "language": N, "completeness": N, "confidence": N, "overall": N, "issues": ["..."]}
```

---

## 5. Transcript Review

Proactively review agent transcripts to catch issues before users report them.

### What to Look For

| Signal            | Meaning                              | Action                         |
| ----------------- | ------------------------------------ | ------------------------------ |
| Timeout (>30s)    | Query too complex or stuck           | Investigate, add optimization  |
| Zero tools called | Agent hallucinated instead of acting | Fix tool forcing, add guidance |
| Error in response | Unhandled edge case                  | Add error handling             |
| Negative feedback | User unhappy with response           | Analyze and fix pattern        |

### Weekly Review Cadence

Run a weekly review of production transcripts:

1. Filter for negative signals (timeouts, errors, zero-tool, negative feedback)
2. Categorize issues by type
3. Create action items for top 3 categories
4. Track resolution in next week's review

---

## 6. Saturation Monitoring

Automatically promote queries from "capability" to "regression" when they've proven stable.

### Graduation Flow

```
capability → saturated → regression

Graduation criteria:
  - 5+ consecutive passes
  - 7+ days observed
  - All recent runs successful

Demotion (regression → investigation):
  - Any failure in a regression query
  - Demoted until fixed and re-graduated
```

### Why This Matters

Without saturation tracking, your regression set is static. Queries you fixed 3 months ago might never get promoted. Saturation monitoring automates this:

- New queries start as "capability"
- Stable queries automatically graduate to "regression"
- Failed regression queries get demoted for investigation

---

## Evaluator-Optimizer Loop

A meta-pattern that combines generation and evaluation into an iterative improvement loop.

```
Generate → Evaluate → PASS → Done
                   → NEEDS_IMPROVEMENT → Feedback → Regenerate (max 3 iterations)
```

### Implementation

```javascript
async function evaluatorOptimizer(generateFn, evaluateFn, maxIterations = 3) {
  let output = await generateFn();

  for (let i = 0; i < maxIterations; i++) {
    const evaluation = await evaluateFn(output);

    if (evaluation.result === "PASS") {
      return { output, iterations: i + 1, status: "passed" };
    }

    // Feed evaluation feedback back into generation
    output = await generateFn({
      previousOutput: output,
      feedback: evaluation.feedback,
    });
  }

  return { output, iterations: maxIterations, status: "max_iterations" };
}
```

### Key Principles

- **Memory of previous attempts**: Each regeneration receives the evaluation feedback, so it knows what to fix.
- **Evaluator is stricter than generator**: Use different criteria (the evaluator catches what the generator misses).
- **Stop early on PASS**: Don't over-iterate. If it passes on attempt 1, return immediately.
- **Maximum 3 iterations**: Diminishing returns after 3. If it hasn't converged, the problem needs a different approach.

### Use Cases

| Use Case          | Generator           | Evaluator                       |
| ----------------- | ------------------- | ------------------------------- |
| Prompt refinement | Write system prompt | Test against 10 sample queries  |
| Code generation   | Write function      | Run tests against the function  |
| Document writing  | Draft documentation | Check completeness and accuracy |
| SQL generation    | Generate SQL query  | Validate against schema + test  |

**Source**: Anthropic evaluator_optimizer.ipynb

---

## Quick Start Checklist

- [ ] Tag existing test queries as `regression` or `capability`
- [ ] Replace string matching with outcome-based grading
- [ ] Run pass^5 on regression queries (monthly)
- [ ] Set up LLM grading for failures + 10% sample
- [ ] Schedule weekly transcript review
- [ ] Implement graduation tracking for capability → regression

---

**Previous**: [40: Agent Orchestration Patterns](40-agent-orchestration-patterns.md)
**Next**: [42: Session Memory and Compaction](42-session-memory-compaction.md)
