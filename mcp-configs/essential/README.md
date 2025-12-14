# Essential MCP Configuration

**GitHub + Memory Bank** - Session persistence added

## What You Get

Everything from Minimal PLUS:

✅ **Session Persistence**:
- Remember facts across sessions ("remember that our API uses OAuth2")
- Recall project decisions ("what did I tell you about the database schema?")
- Persistent notes and patterns
- Search across all stored memories

**Cost**: FREE (both MCPs)
**Setup Time**: 5 minutes (2 min beyond minimal)
**Value**: Never repeat yourself, build institutional knowledge

---

## Setup Instructions

### Prerequisites

- Minimal MCP setup complete (GitHub configured)
- Node.js + npx installed

### 1. Update MCP Config

```bash
# Copy this config to your project
cp mcp_servers.json ~/my-project/.claude/

# Or add memory section to existing config
```

### 2. Configure Memory Bank MCP

**No credentials needed!** Memory Bank MCP is self-hosted.

**Configuration**:
```json
"memory": {
  "command": "npx",
  "args": ["-y", "@joshuarileydev/mcp-server-basic-memory"],
  "env": {
    "MEMORY_PROJECT": "main",           // Project name
    "MEMORY_PATH": "${HOME}/.basic-memory"  // Storage location
  }
}
```

**Customization**:
- `MEMORY_PROJECT`: Use your project name (or keep "main" for shared memory)
- `MEMORY_PATH`: Where memories are stored (default is fine)

### 3. Validate

```bash
# Run MCP validator
./scripts/check-mcp.sh

# Should show:
# ✅ Configured: 2
# - github
# - memory
```

---

## Usage Examples

### Storing Information

```
"Remember that our authentication uses JWT tokens with 24-hour expiration"
→ Uses mcp__basic-memory__write_note

"Remember: Database password is in .env file, never hardcode"
→ Stores as persistent note

"Save this rule: Always run tests before deploying"
→ Creates memory note
```

### Recalling Information

```
"What did I tell you about authentication?"
→ Uses mcp__basic-memory__search_notes
→ Returns: "JWT tokens with 24-hour expiration"

"Recall our database rules"
→ Searches memories for "database"
→ Returns all database-related notes

"What notes do I have?"
→ Uses mcp__basic-memory__list_directory
→ Shows all stored notes
```

---

## Memory Organization

**Default structure** (in ~/.basic-memory/main/):
```
notes/
  ├── authentication.md       # Auth patterns
  ├── database-rules.md       # Database patterns
  ├── deployment.md           # Deployment procedures
  └── coding-standards.md     # Code conventions
```

**Tips**:
- Create topic-based notes
- Use clear, searchable titles
- Reference from skills when appropriate
- Backup periodically (just markdown files)

---

## Benefits

**With Memory Bank MCP**:
- ✅ Never repeat project setup instructions
- ✅ Build institutional knowledge automatically
- ✅ New team members get instant context
- ✅ Cross-session learning (patterns accumulate)
- ✅ Searchable project knowledge base

**Time Saved**: 35-65 hours/year (from not repeating instructions)

---

## Troubleshooting

### "Memory MCP not connecting"

**Check**:
```bash
# 1. npx available?
which npx

# 2. Memory directory created?
ls ~/.basic-memory/

# 3. Project configured?
# In mcp_servers.json, check MEMORY_PROJECT is set
```

**Fix**: Run `npx @joshuarileydev/mcp-server-basic-memory` manually to test

### "Can't find my notes"

**Check**:
```bash
# List all notes
ls ~/.basic-memory/main/notes/

# Search in files
grep -r "keyword" ~/.basic-memory/main/
```

**Fix**: Notes are stored as markdown files, you can read them directly

---

## Next Steps

**Working?** Consider adding database access:

- **PostgreSQL MCP** - Direct database queries (FREE)
  → See [../productive/](../productive/)

---

**Essential MCP**: GitHub + Memory, session persistence, 5-minute setup
**Next**: [Productive MCP](../productive/) adds database access
