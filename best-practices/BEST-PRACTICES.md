# Claude Code Best Practices (Auto-Installed)

**Source**: [claude-code-guide](https://github.com/ytrofr/claude-code-guide) -- 226+ production-tested patterns
**Scope**: Universal -- applies to ALL projects regardless of stack or domain
**Authority**: These rules are MANDATORY in every Claude Code session

---

## 1. Check Before Building (CRITICAL)

**NEVER build anything without checking if it already exists first.**

Before implementing anything:

1. **Search codebase**: grep/glob for existing implementations
2. **Search docs**: check project documentation and learned patterns
3. **Check skills**: look in skills directory for existing solutions
4. **Ask first**: "Does this already exist?" before writing code

| Approach              | Time                    |
| --------------------- | ----------------------- |
| Checking first        | 5-10 minutes            |
| Building from scratch | 1-4 hours               |
| **Savings**           | 50-240 minutes per task |

---

## 2. Validation Workflow (MANDATORY for Every Task)

### 7-Step Workflow

1. **UNDERSTAND** -- What exactly is needed? (not more)
2. **SEARCH** -- Does a solution already exist?
3. **VALIDATE** -- Pass all 5 pre-implementation gates
4. **DESIGN** -- Simplest approach that works
5. **IMPLEMENT** -- Only after validation passes
6. **TEST** -- Verify it works as intended
7. **REFACTOR** -- Simplify if possible

### 5 Pre-Implementation Gates

| Gate | Check                  | Pass Criteria         |
| ---- | ---------------------- | --------------------- |
| 1    | Existing solution?     | Search first          |
| 2    | Complexity assessment  | Under 100 lines       |
| 3    | Modularity validation  | Single responsibility |
| 4    | Best practices check   | KISS/DRY/SOLID        |
| 5    | Performance validation | Minimal token impact  |

---

## 3. Anti-Over-Engineering (HIGH Priority)

**Before creating any plan, validate these 6 points:**

1. **Simplicity**: Can this be solved with <50 lines? Prefer simple.
2. **Reuse**: Does similar code already exist? Check before creating.
3. **Modular**: Is each piece single-responsibility?
4. **Budget**: What's the cost vs alternatives?
5. **Dependencies**: Zero new packages without justification.
6. **Best Practices**: KISS/DRY/SOLID/YAGNI compliant?

**Evidence**: 80% code reduction and 77% cost savings on real projects.

---

## 4. No Mock Data (ABSOLUTE Rule)

**NEVER use mock, fake, stub, placeholder, hardcoded, or synthetic data anywhere.**

All data MUST come from real APIs, databases, services, or user input.

**When data is unavailable**: Return honest errors, not fake data.
**When a feature is not implemented**: Say so explicitly, don't fabricate.
**When a service is not connected**: Require real connection, don't simulate.

### Chain-of-Verification (CoVe)

Before any data processing:

1. Verify the real data source exists
2. Verify the API response structure
3. Use real extraction methods
4. Handle failures honestly (never with synthetic data)

---

## 5. Process Safety

### Forbidden Commands

| Command            | Why Forbidden                 |
| ------------------ | ----------------------------- |
| `killall node`     | Kills WSL/VS Code/Claude Code |
| `pkill -f node`    | Kills ALL node processes      |
| `pkill node`       | Crashes dev environment       |
| `kill -9 -1`       | Kills all user processes      |
| `killall -9 <any>` | Forceful kill of all matching |

### Safe Alternatives

- `kill <PID>` -- Kill specific process by ID
- `pkill -f 'specific-script.js'` -- Kill specific script only
- `ps aux | grep <name>` then `kill <PID>` -- Check then kill

### Docker Safety

- NEVER use `docker system prune -a` (destroys all images/volumes)
- NEVER use `sudo service docker stop` (stops ALL containers)
- USE `docker stop <specific-container>` instead

---

## 6. Session Protocol

### Session Start

1. `git status` -- Check current branch and changes
2. Check project status -- Find incomplete work
3. Select ONE incomplete task
4. Focus on incremental progress

### Session End

1. All work committed or checkpointed
2. Status updated with progress
3. No features left in unknown state

### Key Principles

- **Incremental Progress**: One feature at a time
- **Verify Before Complete**: Test before marking done
- **75% Context Rule**: At 75% context usage, commit and start fresh session
- **Never Stop Mid-Feature**: Complete or create a checkpoint

---

## 7. Quality Standards

| Metric             | Target                |
| ------------------ | --------------------- |
| Technical Accuracy | 99.997% (never fudge) |
| Data Authenticity  | 100% (zero hardcoded) |
| Context Relevance  | 100% task alignment   |

### Self-Verification Before User Testing (MANDATORY)

Always self-test before asking the user to test:

1. **Infrastructure**: Health checks, connectivity, basic validation
2. **Integration**: API responses, data structure verification
3. **Documentation**: Document expected behavior, then hand off

---

## 8. Planning Standards

### Every Plan Must Include

1. **Requirements Clarification** -- Confirm scope before coding
2. **Existing Code Check** -- Search before building
3. **Over-Engineering Prevention** -- Simplify first
4. **Best Practices Compliance** -- KISS/DRY/SOLID/YAGNI
5. **Architecture** -- Which files affected, separation of concerns
6. **Testing Plan** -- How to verify the implementation works
7. **File Change Summary** -- Concrete list of files to create/modify
8. **TL;DR** -- Reader understands the full plan in 10 seconds

---

## 9. Technical Patterns

### Development Workflow (Format-First)

```
1. FORMAT  -- Run formatter first
2. LINT    -- Check for issues
3. TEST    -- Verify correctness
4. COMMIT  -- Only after all pass
```

### Modular Development

| Rule                  | Standard                          |
| --------------------- | --------------------------------- |
| File Size Limit       | Max 500 lines per file            |
| Single Responsibility | One clear purpose per module      |
| Extract Pattern       | Functions >50 lines get extracted |

### Principles

- **SOLID**: Single responsibility, Open-closed, Liskov, Interface segregation, Dependency inversion
- **DRY**: Don't Repeat Yourself
- **KISS**: Keep It Simple
- **YAGNI**: You Aren't Gonna Need It

---

## 10. Parallel Agent Safety (Multi-Agent)

When using `Task()` delegation or parallel agents on the same repository, follow these rules to prevent cross-agent state corruption:

### Git Safety Rules

| Action                          | Rule                                                           |
| ------------------------------- | -------------------------------------------------------------- |
| `git stash`                     | NEVER create/apply/drop unless explicitly requested            |
| `git checkout <branch>`         | NEVER switch branches unless explicitly requested              |
| `git add -A` / `git add .`      | NEVER when unrecognized files exist -- add specific files only |
| `git worktree`                  | NEVER create/modify/remove unless explicitly requested         |
| `git pull --rebase --autostash` | FORBIDDEN -- autostash can corrupt other agent's WIP           |

### Commit Scoping

| User Says    | Agent Action                                            |
| ------------ | ------------------------------------------------------- |
| "commit"     | Stage and commit ONLY files YOU changed                 |
| "commit all" | Stage everything, commit in grouped chunks by topic     |
| "push"       | May `git pull --rebase` first (no autostash), then push |

### Unrecognized Files

When you see files you didn't create: **leave them alone**. Another agent or the user may own them. Focus on your task, and only mention "other uncommitted files present" at the end if relevant.

**Source**: Battle-tested in production repos running 5+ parallel agents (OpenClaw, LIMOR AI).

---

## 11. Doctor Command Pattern

Every project with 5+ config knobs should have a self-diagnostic health check script.

### What It Does

A single `npm run doctor` (or equivalent) that checks for common misconfigurations programmatically -- replacing "the developer remembers to check" with "the machine checks automatically."

### Standard Convention

```json
{ "scripts": { "doctor": "node scripts/doctor.js" } }
```

### Requirements

| Requirement     | Detail                                      |
| --------------- | ------------------------------------------- |
| Exit code       | `0` = healthy, `1` = problems found         |
| Output          | Human-readable PASS/FAIL/WARN per check     |
| Speed           | Under 10 seconds (no heavy operations)      |
| No side effects | Read-only -- NEVER fix things automatically |

### Recommended Check Categories

1. **Environment**: Required env vars present and valid
2. **Connectivity**: DB, Redis, external APIs reachable
3. **Data Integrity**: Referential consistency, no orphaned data
4. **Config Consistency**: Feature flags don't contradict each other
5. **Lifecycle**: No stale data from disabled features

### When to Create One

- Project has 5+ environment variables or feature flags
- Project connects to external services (DB, APIs, AI providers)
- Past bugs were caused by misconfiguration, not code bugs
- You find yourself manually checking the same things each session

**Evidence**: A doctor script catching stale database entries would have prevented a multi-day investigation in a production RAG pipeline.

---

## 12. Test Profile Convention

Every project with tests should support a standard `TEST_PROFILE` environment variable for consistent test selection across projects.

### Profiles

| Profile    | Purpose                        | Duration | When                                    |
| ---------- | ------------------------------ | -------- | --------------------------------------- |
| `quick`    | Smoke tests, sanity checks     | <2 min   | During development, after small changes |
| `standard` | Core test suite                | 5-15 min | Pre-commit gate (default if not set)    |
| `full`     | Everything including heavy/E2E | 30+ min  | Pre-deploy, release gate                |

### Usage

```bash
TEST_PROFILE=quick npm test    # Fast feedback loop
TEST_PROFILE=standard npm test # Default if omitted
TEST_PROFILE=full npm test     # Exhaustive validation
```

### Implementation

Your test runner reads `process.env.TEST_PROFILE` and adjusts suite selection, timeouts, and parallelism. Default to `standard` when the variable is not set.

### Why This Matters

Working across multiple projects, a universal convention means muscle memory works everywhere -- you don't need to remember project-specific test commands.

---

## 13. Primacy-Recency Pattern for CLAUDE.md

Claude has a primacy-recency effect -- the first and last lines of CLAUDE.md are remembered best. Middle content fades when the file exceeds ~200 instructions.

### Implementation

Put your 5 most critical rules as HTML comments at the very top and bottom:

```markdown
<!-- CRITICAL RULES -- Primacy Zone (top lines remembered best) -->
<!-- 1. Your most critical rule that gets violated most often -->
<!-- 2. Your second most critical rule -->
<!-- ... up to 5 -->

# Project Title

... (normal CLAUDE.md content) ...

<!-- CRITICAL RULES -- Recency Zone (bottom lines remembered best) -->
<!-- Rules that need reinforcement -- the ones you've corrected 3+ times -->
```

**Why HTML comments**: Claude reads them, but they don't render on GitHub. They stay invisible in the README while being in context.

**When to use**: Your CLAUDE.md has >100 lines AND you've corrected the same mistake 3+ times.

---

## 14. Path-Scoped Skills with Globs

Skills can include `globs:` in their frontmatter so they only load when Claude touches matching files. This saves 30-50% tokens by not loading irrelevant skills.

### Format

```yaml
---
name: ai-pipeline-debugging-skill
description: "Debug AI pipeline issues..."
globs:
  - src/services/ai/**
  - src/prompts/tiers/**
user-invocable: false
---
```

### When to Add Globs

| Condition               | Glob Pattern                          |
| ----------------------- | ------------------------------------- |
| AI/ML-specific skill    | `src/services/ai/**`, `src/models/**` |
| Database-specific skill | `src/database/**`, `migrations/**`    |
| Frontend-specific skill | `src/components/**`, `public/**`      |
| Deploy-specific skill   | `Dockerfile`, `.github/workflows/**`  |
| Test-specific skill     | `tests/**`, `scripts/baselines/**`    |

### Impact

In a project with 180+ skills, adding globs to domain-specific skills reduced per-session token usage by ~35%. Skills without globs load every session (good for universal skills like "session-protocol").

**Rule**: Universal skills (session, git, quality) = no globs. Domain-specific skills (AI, DB, deploy) = add globs.

---

## 15. Common Anti-Patterns to Avoid

| Anti-Pattern                      | Correct Approach                        |
| --------------------------------- | --------------------------------------- |
| Building without searching first  | Search codebase, then build if needed   |
| Using mock/placeholder data       | Use real data or return honest errors   |
| Killing all processes generically | Kill by specific PID only               |
| Over-engineering simple tasks     | Start with <50 lines, expand if needed  |
| Skipping tests before completion  | Always verify before marking done       |
| Adding unnecessary dependencies   | Zero new packages without justification |
| Huge monolithic files             | Keep files under 500 lines              |
| Implementing without a plan       | Follow 7-step validation workflow       |

---

## 16. Rules System Reference

Claude Code loads rules from two locations:

```
~/.claude/rules/         <-- Global (personal, all projects)
.claude/rules/           <-- Project (repo-level, shared with team)
```

- All `.md` files in `.claude/rules/` are auto-discovered recursively
- Project rules override global rules on conflict
- Use `paths:` YAML frontmatter for conditional loading on specific file patterns

---

## 17. Context Optimization

- Keep CLAUDE.md focused and scannable (under 2 minutes to read)
- Use `@` imports for external context files instead of inlining everything
- Structure knowledge hierarchically: always-loaded core + on-demand details
- Aim for 34-62% token reduction through smart context loading

---

## Full Guide Reference

For deeper coverage of any topic, see the complete documentation:

- **Quick Start**: https://github.com/ytrofr/claude-code-guide/blob/master/docs/quick-start.md
- **Hooks (18 events)**: https://github.com/ytrofr/claude-code-guide/blob/master/docs/guide/13-claude-code-hooks.md
- **Skills System**: https://github.com/ytrofr/claude-code-guide/blob/master/docs/skill-activation-system.md
- **MCP Integration**: https://github.com/ytrofr/claude-code-guide/blob/master/docs/guide/06-mcp-integration.md
- **Rules System**: https://github.com/ytrofr/claude-code-guide/blob/master/docs/guide/26-claude-code-rules-system.md
- **Branch Context (47-70% token savings)**: https://github.com/ytrofr/claude-code-guide/blob/master/docs/guide/29-branch-context-system.md
- **Adoptable Rules & Commands**: https://github.com/ytrofr/claude-code-guide/blob/master/docs/guide/47-adoptable-rules-and-commands.md
- **Full Repository**: https://github.com/ytrofr/claude-code-guide

---

**Installed by**: [claude-code-guide installer](https://github.com/ytrofr/claude-code-guide)
**Update**: Run `.claude/best-practices/update.sh` to pull the latest version
