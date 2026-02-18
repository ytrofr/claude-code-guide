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

| Gate | Check                   | Pass Criteria         |
| ---- | ----------------------- | --------------------- |
| 1    | Existing solution?      | Search first          |
| 2    | Complexity assessment   | Under 100 lines       |
| 3    | Modularity validation   | Single responsibility |
| 4    | Best practices check    | KISS/DRY/SOLID        |
| 5    | Performance validation  | Minimal token impact  |

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

| Command            | Why Forbidden                        |
| ------------------ | ------------------------------------ |
| `killall node`     | Kills WSL/VS Code/Claude Code       |
| `pkill -f node`    | Kills ALL node processes             |
| `pkill node`       | Crashes dev environment              |
| `kill -9 -1`       | Kills all user processes             |
| `killall -9 <any>` | Forceful kill of all matching        |

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

| Metric             | Target                  |
| ------------------ | ----------------------- |
| Technical Accuracy | 99.997% (never fudge)  |
| Data Authenticity  | 100% (zero hardcoded)  |
| Context Relevance  | 100% task alignment    |

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

| Rule                  | Standard                           |
| --------------------- | ---------------------------------- |
| File Size Limit       | Max 500 lines per file             |
| Single Responsibility | One clear purpose per module       |
| Extract Pattern       | Functions >50 lines get extracted  |

### Principles

- **SOLID**: Single responsibility, Open-closed, Liskov, Interface segregation, Dependency inversion
- **DRY**: Don't Repeat Yourself
- **KISS**: Keep It Simple
- **YAGNI**: You Aren't Gonna Need It

---

## 10. Common Anti-Patterns to Avoid

| Anti-Pattern                      | Correct Approach                         |
| --------------------------------- | ---------------------------------------- |
| Building without searching first  | Search codebase, then build if needed    |
| Using mock/placeholder data       | Use real data or return honest errors    |
| Killing all processes generically | Kill by specific PID only                |
| Over-engineering simple tasks     | Start with <50 lines, expand if needed   |
| Skipping tests before completion  | Always verify before marking done        |
| Adding unnecessary dependencies   | Zero new packages without justification  |
| Huge monolithic files             | Keep files under 500 lines               |
| Implementing without a plan       | Follow 7-step validation workflow        |

---

## 11. Rules System Reference

Claude Code loads rules from two locations:

```
~/.claude/rules/         <-- Global (personal, all projects)
.claude/rules/           <-- Project (repo-level, shared with team)
```

- All `.md` files in `.claude/rules/` are auto-discovered recursively
- Project rules override global rules on conflict
- Use `paths:` YAML frontmatter for conditional loading on specific file patterns

---

## 12. Context Optimization

- Keep CLAUDE.md focused and scannable (under 2 minutes to read)
- Use `@` imports for external context files instead of inlining everything
- Structure knowledge hierarchically: always-loaded core + on-demand details
- Aim for 34-62% token reduction through smart context loading

---

## Full Guide Reference

For deeper coverage of any topic, see the complete documentation:

- **Quick Start**: https://github.com/ytrofr/claude-code-guide/blob/master/docs/quick-start.md
- **Hooks (14 events)**: https://github.com/ytrofr/claude-code-guide/blob/master/docs/guide/13-claude-code-hooks.md
- **Skills System**: https://github.com/ytrofr/claude-code-guide/blob/master/docs/skill-activation-system.md
- **MCP Integration**: https://github.com/ytrofr/claude-code-guide/blob/master/docs/guide/06-mcp-integration.md
- **Rules System**: https://github.com/ytrofr/claude-code-guide/blob/master/docs/guide/26-claude-code-rules-system.md
- **Branch Context (47-70% token savings)**: https://github.com/ytrofr/claude-code-guide/blob/master/docs/guide/29-branch-context-system.md
- **Adoptable Rules & Commands**: https://github.com/ytrofr/claude-code-guide/blob/master/docs/guide/47-adoptable-rules-and-commands.md
- **Full Repository**: https://github.com/ytrofr/claude-code-guide

---

**Installed by**: [claude-code-guide installer](https://github.com/ytrofr/claude-code-guide)
**Update**: Run `.claude/best-practices/update.sh` to pull the latest version
