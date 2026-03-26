---
layout: default
title: "Security Scanning for Claude Code Configurations"
parent: Guide
nav_order: 62
---

# Security Scanning for Claude Code Configurations

*How to detect secrets, permission gaps, and injection risks in your `~/.claude/` setup*

Your Claude Code configuration is an attack surface. Skills can contain prompt injection, hooks can exfiltrate data, MCP servers can inherit secrets, and overly broad permissions let Claude run arbitrary commands. This chapter covers automated scanning to catch these issues before they become incidents.

## Why Scan Your Config?

A March 2026 scan of a mature setup (47 rules, 42 skills, 16 hooks) scored **56/100** with 14 high-severity findings — despite the maintainer being security-conscious. The most common issues:

- **Overly broad Bash permissions**: `Bash(docker *)`, `Bash(node *)`, `Bash(curl *)` allow arbitrary execution
- **Missing deny lists**: No explicit blocks for `chmod 777`, `ssh`, or device file writes
- **Hook scripts with dangerous operations**: `rm -f`, `git config --global`, output suppression via `>/dev/null`
- **MCP servers inheriting full environment**: All env vars (including API keys) passed to MCP subprocesses
- **Unversioned MCP packages**: `@package/name@latest` auto-updates could introduce supply chain attacks

## AgentShield: Automated Config Scanner

[AgentShield](https://github.com/affaan-m/agentshield) is a free, MIT-licensed scanner with 102 rules across 5 categories. It runs via npx with zero installation.

### Quick Start

```bash
# Scan your config (zero install)
npx ecc-agentshield scan ~/.claude/

# Save results to a log
npx ecc-agentshield scan ~/.claude/ | tee ~/.claude/logs/agentshield-$(date +%Y-%m-%d).log

# Auto-fix findings (review first!)
npx ecc-agentshield scan ~/.claude/ --fix
```

### What It Scans

| Category | Rules | What It Checks |
|----------|-------|---------------|
| **Secrets** | 10 | API keys, tokens, hardcoded passwords, connection strings in CLAUDE.md, settings, skills |
| **Permissions** | 10 | Wildcard `Bash(*)`, missing deny lists, dangerous flags like `--no-verify` |
| **Hooks** | 34 | Command injection, data exfiltration patterns, reverse shells, credential harvesting, container escape |
| **MCP Servers** | 23 | Supply chain risks (`@latest`), remote transport, auto-approve, env inheritance |
| **Agent Config** | 25 | Prompt injection surfaces, hidden directives, URL execution, time bombs, jailbreak patterns |

### Interpreting Results

AgentShield produces an overall score (0-100) and per-category scores:

```
Overall Grade: D (56/100)
  Secrets:     100/100  ← No hardcoded credentials found
  Permissions:  13/100  ← Broad allow rules, no deny list
  Hooks:         0/100  ← rm -f, git config --global, output suppression
  MCP Servers:  85/100  ← One unversioned package, env inheritance
  Agents:       81/100  ← Minor: missing observation hooks in commands
```

**Priority triage:**
1. **Critical (score 0-25)**: Fix immediately — active security risk
2. **High (score 25-50)**: Fix this week — latent vulnerability
3. **Medium (score 50-75)**: Fix this month — best practice gap
4. **Low (score 75-100)**: Acknowledge — minimal risk

### Common Findings and Fixes

#### Overly Broad Permissions

```json
// BEFORE (flagged as HIGH)
"Bash(docker *)"
"Bash(node *)"
"Bash(curl *)"

// AFTER (scoped)
"Bash(docker ps *)"
"Bash(docker logs *)"
"Bash(docker restart *)"
"Bash(node scripts/*)"
"Bash(curl -sf localhost:*)"
```

#### Missing Deny List

```json
// Add to settings.json under "deny"
"deny": [
  "Bash(chmod 777 *)",
  "Bash(rm -rf /)",
  "Bash(> /dev/*)",
  "Bash(ssh *)"
]
```

#### MCP Environment Inheritance

```json
// BEFORE (inherits ALL env vars including secrets)
"mcpServers": {
  "my-server": {
    "command": "npx",
    "args": ["-y", "@package/server"]
  }
}

// AFTER (explicit env whitelist)
"mcpServers": {
  "my-server": {
    "command": "npx",
    "args": ["-y", "@package/server@1.2.3"],
    "env": {
      "NODE_ENV": "development"
    }
  }
}
```

#### Unversioned MCP Packages

```json
// BEFORE (supply chain risk)
"args": ["-y", "@remotion/mcp@latest"]

// AFTER (pinned version)
"args": ["-y", "@remotion/mcp@4.0.293"]
```

## Scan Cadence

| When | Action |
|------|--------|
| **Monthly** | Full scan, triage new findings |
| **After adding skills/hooks** | Quick scan to catch injection patterns |
| **After installing community plugins** | Scan for malicious skill patterns |
| **After upgrading Claude Code** | Check if new features affect security posture |

## Malicious Skill Patterns to Watch For

The [claude-code-ultimate-guide](https://github.com/FlorianBruniaux/claude-code-ultimate-guide) catalogues 655 known malicious skill patterns and 24 CVE-mapped vulnerabilities. Key patterns:

| Pattern | Risk | Detection |
|---------|------|-----------|
| Skills that `curl` to external URLs | Data exfiltration | Grep for `curl`, `wget`, `fetch` in SKILL.md |
| Hidden directives in long skill text | Prompt injection | AgentShield agent-config rules detect these |
| Skills requesting `Bash(*)` permission | Arbitrary code execution | Check `allowed-tools` in all SKILL.md files |
| Hooks that pipe to external services | Credential theft | Review all hook scripts for network calls |

## Integration with Stack Audits

Add security scanning as a fifth area in your [monthly stack audit](61-stack-audit-maintenance):

```markdown
### 5. Security Scan
- [ ] Run `npx ecc-agentshield scan ~/.claude/`
- [ ] All critical/high findings resolved
- [ ] No new MCP servers using `@latest`
- [ ] Deny list covers dangerous operations
- [ ] Hook scripts reviewed for output suppression
```

---

*Previous: [Chapter 61 — Stack Audit & Maintenance Patterns](61-stack-audit-maintenance)*
