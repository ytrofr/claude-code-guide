# Contributing to Claude Code Guide

Thank you for your interest in contributing to the Claude Code Guide! This document provides guidelines for contributions.

## How to Contribute

### Reporting Issues

- Use GitHub Issues to report bugs or suggest improvements
- Check existing issues first to avoid duplicates
- Provide clear reproduction steps for bugs
- Include Claude Code version and environment details

### Suggesting Enhancements

- Open a GitHub Issue with the `enhancement` label
- Describe the problem your enhancement solves
- Include evidence or metrics if available
- Reference existing patterns where applicable

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Follow the existing structure** - Match the style of existing documentation
3. **Include evidence** - All patterns should have production metrics or test results
4. **Update the sitemap** if adding new pages
5. **Test locally** - Ensure Jekyll builds correctly

### Documentation Standards

#### File Naming

- Use kebab-case for file names: `my-new-guide.md`
- Prefix guide files with numbers for ordering: `36-new-feature.md`

#### Content Structure

```markdown
# Title

**Created**: YYYY-MM-DD
**Category**: hooks | skills | mcp | optimization

## Problem Statement

What issue does this solve?

## Solution

The approach and implementation.

## Evidence

Metrics, test results, or production data.

## Quick Reference

Key commands or patterns.
```

#### Metrics

All optimizations should include measurable results:

- Before/after comparisons
- Time savings
- Token reduction percentages
- Accuracy improvements

### Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Welcome newcomers and help them get started

## Getting Started

1. Clone the repository
2. Install Jekyll: `gem install jekyll bundler`
3. Run locally: `bundle exec jekyll serve`
4. Make your changes
5. Submit a pull request

## Questions?

Open an issue with the `question` label.

---

Thank you for helping improve Claude Code Guide!
