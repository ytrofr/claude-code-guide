# Source Validation — Verify Before Adopting

**Scope**: ALL projects
**Authority**: MANDATORY when adopting patterns from community articles, blog posts, or LLM outputs

---

## Core Rule

**Before adopting ANY feature or pattern from a community source, verify it exists in official documentation.**

Community articles (Builder.io, LinkedIn, Medium, Substack) fabricate features, misquote creators, and conflate unreleased previews with GA features. Treat all community claims as unvalidated until proven.

## 3-Step Validation Protocol

1. **CLI check**: `claude --help | grep <feature>` -- is the flag real?
2. **Docs check**: Search official documentation for the feature
3. **Memory check**: Have you validated this before?

If not found in any of these 3 sources: **do not adopt**. Label as "unvalidated community claim."

## When to Apply

- Evaluating community blog posts or LinkedIn tips
- Processing external LLM analysis (ChatGPT, Gemini audits)
- Reviewing plugin/skill recommendations from third parties
- Adopting patterns from trending GitHub repos
