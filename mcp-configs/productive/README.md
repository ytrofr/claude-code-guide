# Productive MCP Configuration

**GitHub + Memory + PostgreSQL + Perplexity** - Full productivity stack

## What You Get

Everything from Essential PLUS:

✅ **Database Access** (3 environments):
- Query development, staging, production databases directly
- Compare data across environments
- No need to switch to database GUI
- Read-only by default (safe)

✅ **AI Search**:
- Real-time web search via Perplexity
- Current news and updates
- Technical documentation lookup

**Cost**: FREE (except Perplexity: $5/month for ~800 queries)
**Setup Time**: 10 minutes (5 min beyond essential)
**Value**: Database visibility, current information access

---

## Setup Instructions

### 1. PostgreSQL MCP Configuration

**Database credentials needed**:
- Host (localhost or cloud instance IP)
- Port (usually 5432)
- Username
- Password
- Database names (dev, staging, production)

**Configuration placeholders**:
```bash
${POSTGRES_USER}          # Database username
${POSTGRES_PASSWORD}      # Dev/staging password
${POSTGRES_PASSWORD_PROD} # Production password (separate for safety)
${POSTGRES_HOST}          # Database host (localhost or IP)
${POSTGRES_HOST_PROD}     # Production host (if different)
${POSTGRES_PORT}          # Port (usually 5432)
${POSTGRES_DB_DEV}        # Development database name
${POSTGRES_DB_STAGING}    # Staging database name
${POSTGRES_DB_PROD}       # Production database name
```

**Example** (using environment variables):
```bash
# Add to ~/.bashrc or ~/.zshrc
export POSTGRES_USER="myapp_user"
export POSTGRES_PASSWORD="dev_password_here"
export POSTGRES_PASSWORD_PROD="prod_password_here"
export POSTGRES_HOST="localhost"
export POSTGRES_HOST_PROD="34.52.230.39"
export POSTGRES_PORT="5432"
export POSTGRES_DB_DEV="myapp_dev"
export POSTGRES_DB_STAGING="myapp_staging"
export POSTGRES_DB_PROD="myapp_prod"
```

**Or hardcode** (less secure):
```json
{
  "postgres-dev": {
    "command": "npx",
    "args": [
      "-y",
      "@modelcontextprotocol/server-postgres",
      "postgresql://myuser:mypassword@localhost:5432/myapp_dev"
    ]
  }
}
```

### 2. Perplexity MCP Configuration (Optional)

**Get API key**:
```bash
# 1. Sign up at https://www.perplexity.ai/
# 2. Go to https://www.perplexity.ai/settings/api
# 3. Generate API key
# 4. Add to environment:
export PERPLEXITY_API_KEY="pplx-xxxxxx"
```

**Budget**: $5/month = ~800 queries (search: $0.005, ask: $0.006 each)

### 3. Validate

```bash
# Check MCP config
./scripts/check-mcp.sh

# Should show 5-6 servers configured:
# - github
# - memory
# - postgres-dev
# - postgres-staging
# - postgres-production
# - perplexity (if enabled)
```

---

## Usage Examples

### PostgreSQL MCP

```
"How many users in production database?"
→ Uses mcp__postgres-production__query

"Show me the schema for users table"
→ Queries information_schema

"Compare user counts across all 3 environments"
→ Queries all 3 databases

"What's the largest table in production?"
→ Queries pg_stat_user_tables
```

**Safety**: Read-only access by default (SELECT queries only)

### Perplexity MCP

```
"What's the latest news about PostgreSQL 16?"
→ Uses mcp__perplexity__search

"Current best practices for React hooks in 2025?"
→ Uses mcp__perplexity__ask

"Compare Next.js vs Remix for my use case"
→ Uses mcp__perplexity__reason
```

**Budget Awareness**: Check https://www.perplexity.ai/account/api for usage

---

## Database Safety Patterns

### Read-Only by Default

The PostgreSQL MCP provides read-only access (SELECT queries).

**Safe**:
```
"How many records in users table?"
→ SELECT COUNT(*) FROM users

"Show me recent orders"
→ SELECT * FROM orders ORDER BY created_at DESC LIMIT 10
```

**Not available**:
- INSERT, UPDATE, DELETE (use your application code)
- CREATE, DROP, ALTER (use migration tools)

**Why**: Prevents accidental data modification through Claude

### Multi-Environment Safety

**Critical**: Always know which database you're querying

```
# Good practice - specify environment
"How many users in PRODUCTION?"
→ Clear which database

"How many users?"
→ Ambiguous - Claude may ask which environment
```

**Add to CORE-PATTERNS.md**:
```yaml
DATABASE_SAFETY:
  Rule: "Always specify environment when querying databases"
  Pattern: |
    "Query PRODUCTION database for X"
    "Check DEV database for Y"
  Validation: "SELECT current_database();"
```

---

## Cost Management

### PostgreSQL MCP: FREE

No API costs - direct database connection

### Perplexity MCP: $5/month Budget

**Query costs**:
- `search`: $0.005/query (~1,000 queries/month)
- `ask`: $0.006/query (~830 queries/month)
- `reason`: $0.007/query (~710 queries/month)
- `deep_research`: $0.05/query (~100 queries/month)

**Budget strategy**:
- Use `search` for simple queries (cheapest)
- Use `ask` for explanations
- Avoid `deep_research` (50x more expensive)
- Fall back to free WebSearch when possible

**Monitor**: https://www.perplexity.ai/account/api/group

---

## Troubleshooting

### PostgreSQL Connection Issues

**Error**: "Connection refused" or "Authentication failed"

**Check**:
```bash
# 1. Database is running?
psql -h ${POSTGRES_HOST} -p ${POSTGRES_PORT} -U ${POSTGRES_USER} -c "SELECT 1"

# 2. Credentials correct?
echo $POSTGRES_USER
echo $POSTGRES_HOST

# 3. Connection string format?
# Should be: postgresql://user:password@host:port/database
```

**Fix**:
- Verify database is accessible
- Check credentials in environment variables
- Test connection outside Claude first

### Perplexity Budget Exceeded

**Error**: "Rate limit exceeded" or "Insufficient credits"

**Check**:
```bash
# Check usage
open https://www.perplexity.ai/account/api
```

**Fix**:
- Add more credits
- Use cheaper `search` instead of `reason`
- Fall back to free WebSearch

---

## Next Steps

**Working?** You now have full productivity setup:

- ✅ GitHub integration
- ✅ Session persistence
- ✅ Database visibility
- ✅ AI-powered search

**Consider**:
- Create database-specific skills
- Build query patterns in CORE-PATTERNS.md
- Document common queries as skills

→ See [../../docs/guide/04-phase-2-productive.md](../../docs/guide/04-phase-2-productive.md)

---

**Productive MCP**: 4-6 servers, full stack, 10-minute setup
**Value**: Database queries + memory + search without leaving Claude
**Next**: [Advanced MCP](../advanced/) for custom integrations
