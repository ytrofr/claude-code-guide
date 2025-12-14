# Minimal MCP Configuration

**Just GitHub** - The essential MCP server for any project

## What You Get

✅ **GitHub Integration**:
- Review pull requests
- Manage issues
- Search code across repositories
- View commit history
- Create branches and PRs

**Cost**: FREE (official GitHub service)
**Setup Time**: 3 minutes
**Value**: Never leave Claude to check PRs or issues

---

## Setup Instructions

### 1. Get GitHub Token

```bash
# Go to GitHub settings
open https://github.com/settings/tokens

# Click "Generate new token (classic)"

# Required scopes:
#   ☑ repo (full control of private repositories)
#   ☑ read:org (if accessing organization repos)

# Generate token and copy it
# Format: ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**Important**: Use **classic token** (not fine-grained). Fine-grained tokens have private repo access issues.

### 2. Configure MCP

```bash
# Copy this config to your project
cp mcp_servers.json ~/my-project/.claude/

# Edit and replace placeholder
cd ~/my-project
# In .claude/mcp_servers.json, replace:
# "${GITHUB_TOKEN}" → "ghp_your_actual_token_here"
```

**Or use environment variable**:
```bash
# Add to ~/.bashrc or ~/.zshrc
export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_your_token_here"

# Then you can keep ${GITHUB_TOKEN} in config
# (it will read from environment)
```

### 3. Validate

```bash
# Check JSON is valid
jq empty .claude/mcp_servers.json

# Check no placeholders remain (if not using env var)
grep '${GITHUB_TOKEN}' .claude/mcp_servers.json

# Test connection
# In Claude Code, ask:
# "List my GitHub repositories"
```

---

## Usage Examples

### In Claude Code

```
"Show me open PRs in myrepo"
→ Uses mcp__github__list_pull_requests

"What's in PR #123?"
→ Uses mcp__github__get_pull_request

"List issues labeled 'bug'"
→ Uses mcp__github__list_issues

"Search for 'authentication' in my code"
→ Uses mcp__github__search_code
```

---

## Troubleshooting

### "GitHub MCP not connecting"

**Check**:
```bash
# 1. Token format correct?
# Should start with: ghp_

# 2. Token has correct scopes?
# Go to https://github.com/settings/tokens
# Verify 'repo' scope is checked

# 3. npx available?
which npx
```

**Fix**: Use classic token (not fine-grained), verify scopes

### "403 Forbidden errors"

**Cause**: Token doesn't have required permissions

**Fix**: Regenerate token with `repo` and `read:org` scopes

---

## Next Steps

**Working?** Consider adding more MCP servers:

- **Memory Bank MCP** - Session persistence (FREE)
  → See [../essential/](../essential/)

- **PostgreSQL MCP** - Database access (FREE)
  → See [../productive/](../productive/)

- **Perplexity MCP** - AI search ($5/month)
  → See [../productive/](../productive/)

---

## Security Notes

### .gitignore

Add to your `.gitignore`:
```
.claude/mcp_servers.json
```

**Why**: Contains your GitHub token

### Alternative: Environment Variables

Instead of hardcoding tokens:
```bash
# In ~/.bashrc or ~/.zshrc
export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_your_token"

# In mcp_servers.json, keep:
"GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
```

**Benefit**: Token not in files, safer for git commits

---

**Minimal MCP**: GitHub only, 3-minute setup, immediate PR/issue value
**Next**: [Essential MCP](../essential/) adds session persistence
