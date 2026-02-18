# Zero-Downtime PostgreSQL Upgrade in Docker (PG15 to PG17 with pgvector)

**Created**: February 2026
**Source**: Production upgrade on LimorAI Docker stack
**Evidence**: ~5 seconds total downtime, zero data loss
**Method**: Parallel-run backup/restore with volume swap

---

## Overview

PostgreSQL major version upgrades in Docker require a full dump-and-restore because the on-disk data format changes between major versions. You cannot simply change the image tag from `pgvector/pgvector:pg15` to `pgvector/pgvector:pg17` and restart -- the new binary will refuse to read the old data directory.

This guide covers how to perform the upgrade with near-zero downtime by running the new version in parallel, restoring into it, verifying everything, and then performing a fast switchover.

**Total downtime**: ~5 seconds (only the stop-old/start-new swap)

---

## Prerequisites

| Requirement | Version | Notes |
|-------------|---------|-------|
| Docker & Docker Compose | 20+ | Native Docker Engine on WSL2 or Linux |
| Current PostgreSQL | 15.x | Running via `pgvector/pgvector:pg15` |
| Target PostgreSQL | 17.x | Via `pgvector/pgvector:pg17` |
| pgvector extension | 0.7+ | Included in pgvector Docker images |
| Disk space | 2x current DB size | For backup + new volume simultaneously |

---

## Phase 1: Pre-upgrade Assessment

Before touching anything, understand what you have.

### Check Current Version and Extensions

```bash
docker exec -i limor-postgres psql -U postgres -c "SELECT version();"
```

```
                                                 version
----------------------------------------------------------------------------------------------------------
 PostgreSQL 15.8 (Debian 15.8-1.pgdg120+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 12.2.0-14) ...
```

```bash
docker exec -i limor-postgres psql -U postgres -c "SELECT * FROM pg_extension;"
```

```
  oid  | extname  | extowner | extnamespace | extrelocatable | extversion | extconfig | extcondition
-------+----------+----------+--------------+----------------+------------+-----------+--------------
 13526 | plpgsql  |       10 |           11 | f              | 1.0        |           |
 16389 | vector   |       10 |         2200 | t              | 0.7.4      |           |
```

### Check Database Sizes

```bash
docker exec -i limor-postgres psql -U postgres -c "
  SELECT datname, pg_size_pretty(pg_database_size(datname))
  FROM pg_database WHERE datistemplate = false;
"
```

```
   datname   | pg_size_pretty
-------------+----------------
 postgres    | 8553 kB
 limor_prod  | 157 MB
 limor_dev   | 89 MB
```

### Record Table Row Counts (for verification later)

```bash
docker exec -i limor-postgres psql -U postgres -d limor_prod -c "
  SELECT schemaname, relname, n_live_tup
  FROM pg_stat_user_tables
  ORDER BY n_live_tup DESC;
"
```

Save this output -- you will compare it against the restored database.

### Verify pgvector Compatibility

The `pgvector/pgvector:pg17` image includes pgvector built for PG17. Confirm the image exists:

```bash
docker pull pgvector/pgvector:pg17
```

```
pg17: Pulling from pgvector/pgvector
...
Status: Downloaded newer image for pgvector/pgvector:pg17
```

---

## Phase 2: Prepare While Running (Zero Downtime)

All of the following steps happen while your production database is still running and serving traffic.

### Step 1: Full Backup with pg_dumpall

`pg_dumpall` captures every database, role, and permission in a single file:

```bash
docker exec -i limor-postgres pg_dumpall -U postgres > ~/pg15_full_backup.sql
```

Verify the backup is complete and not truncated:

```bash
ls -lh ~/pg15_full_backup.sql
tail -5 ~/pg15_full_backup.sql
```

```
-rw-r--r-- 1 ytr ytr 48M Feb 17 14:22 pg15_full_backup.sql
```

The last lines should end with PostgreSQL disconnect statements, not mid-query. A healthy backup ends with something like:

```
--
-- PostgreSQL database dump complete
--
```

### Step 2: Create a New Data Volume

Never reuse the old volume. Create a fresh one for PG17:

```bash
docker volume create limor-pg17-data
```

### Step 3: Start PG17 on an Alternate Port

Run the new PostgreSQL 17 container alongside the old one, mapped to port 5433 so there is no conflict:

```bash
docker run -d \
  --name pg17-test \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=your_password_here \
  -p 5433:5432 \
  -v limor-pg17-data:/var/lib/postgresql/data \
  pgvector/pgvector:pg17
```

Wait a few seconds for it to initialize, then confirm it is running:

```bash
docker logs pg17-test 2>&1 | tail -5
```

```
PostgreSQL init process complete; ready for start up.
LOG:  database system is ready to accept connections
```

### Step 4: Restore the Backup into PG17

```bash
docker exec -i pg17-test psql -U postgres < ~/pg15_full_backup.sql
```

This will produce output as it creates roles, databases, and restores each database. You may see some harmless notices:

```
CREATE ROLE
CREATE DATABASE
...
CREATE EXTENSION
CREATE TABLE
COPY 15432
COPY 8291
...
```

**Expected warnings** (safe to ignore):
- `ERROR: role "postgres" already exists` -- the postgres superuser already exists in the fresh instance
- `WARNING: no privileges were granted for "public"` -- default schema privilege notices

### Step 5: Verify the Restored Data

This is the most critical step. Do not proceed to switchover until every check passes.

#### Check version

```bash
docker exec -i pg17-test psql -U postgres -c "SELECT version();"
```

```
                                                 version
----------------------------------------------------------------------------------------------------------
 PostgreSQL 17.2 (Debian 17.2-1.pgdg120+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 12.2.0-14) ...
```

#### Check databases exist

```bash
docker exec -i pg17-test psql -U postgres -c "\l"
```

Confirm all your databases appear: `postgres`, `limor_prod`, `limor_dev`, etc.

#### Check extensions

```bash
docker exec -i pg17-test psql -U postgres -d limor_prod -c "SELECT * FROM pg_extension;"
```

```
  oid  | extname  | extowner | extnamespace | extrelocatable | extversion
-------+----------+----------+--------------+----------------+------------
 13526 | plpgsql  |       10 |           11 | f              | 1.0
 16389 | vector   |       10 |         2200 | t              | 0.8.0
```

Note: pgvector version may upgrade automatically (0.7.4 to 0.8.0). This is expected and safe.

#### Compare row counts

```bash
docker exec -i pg17-test psql -U postgres -d limor_prod -c "
  SELECT schemaname, relname, n_live_tup
  FROM pg_stat_user_tables
  ORDER BY n_live_tup DESC;
"
```

Compare this output against the row counts you recorded in Phase 1. Every table should match.

#### Test pgvector operations

Run an actual vector similarity query to confirm pgvector works correctly on PG17:

```bash
docker exec -i pg17-test psql -U postgres -d limor_prod -c "
  SELECT id, name, embedding <-> '[0.1,0.2,0.3]'::vector AS distance
  FROM your_vector_table
  ORDER BY distance
  LIMIT 3;
"
```

If this returns results without errors, pgvector is fully operational.

#### Check database sizes

```bash
docker exec -i pg17-test psql -U postgres -c "
  SELECT datname, pg_size_pretty(pg_database_size(datname))
  FROM pg_database WHERE datistemplate = false;
"
```

Sizes should be similar to the original (minor differences are normal due to TOAST and vacuum differences).

---

## Phase 3: Switchover (~5 Seconds Downtime)

This is the only phase where the database is unavailable. It takes about 5 seconds.

### Step 1: Stop the Test Container

```bash
docker stop pg17-test && docker rm pg17-test
```

### Step 2: Back Up the Current Compose File

```bash
cp docker-compose.yml docker-compose.pg15-backup.yml
```

### Step 3: Update docker-compose.yml

Change the PostgreSQL service to use PG17 and the new volume:

```yaml
# BEFORE (PG15)
services:
  postgres:
    image: pgvector/pgvector:pg15
    container_name: limor-postgres
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:

# AFTER (PG17)
services:
  postgres:
    image: pgvector/pgvector:pg17
    container_name: limor-postgres
    volumes:
      - limor-pg17-data:/var/lib/postgresql/data

volumes:
  limor-pg17-data:
    external: true
```

Key changes:
- `image`: `pgvector/pgvector:pg15` changed to `pgvector/pgvector:pg17`
- `volumes`: Points to the new `limor-pg17-data` volume (marked `external: true` because we already created it)

### Step 4: Stop the Old Stack and Start the New One

```bash
docker compose down && docker compose up -d
```

This is where the ~5 seconds of downtime occurs.

### Step 5: Verify Everything is Running

```bash
docker compose ps
```

```
NAME              IMAGE                      STATUS          PORTS
limor-postgres    pgvector/pgvector:pg17     Up 3 seconds    0.0.0.0:5432->5432/tcp
limor-redis       redis:7-alpine             Up 3 seconds    0.0.0.0:6379->6379/tcp
```

Run the same verification checks from Phase 2:

```bash
# Version
docker exec -i limor-postgres psql -U postgres -c "SELECT version();"

# Databases
docker exec -i limor-postgres psql -U postgres -c "\l"

# Extensions
docker exec -i limor-postgres psql -U postgres -d limor_prod -c "SELECT extname, extversion FROM pg_extension;"

# Row counts
docker exec -i limor-postgres psql -U postgres -d limor_prod -c "
  SELECT relname, n_live_tup FROM pg_stat_user_tables ORDER BY n_live_tup DESC;
"

# pgvector query
docker exec -i limor-postgres psql -U postgres -d limor_prod -c "
  SELECT count(*) FROM your_vector_table;
"
```

### Step 6: Verify Application Connectivity

If your application connects to PostgreSQL, restart it and check:

```bash
# Check application logs for successful DB connection
docker logs your-app-container 2>&1 | grep -i "database\|postgres\|connected"

# Hit a health endpoint that queries the database
curl -s http://localhost:8080/health | jq .
```

---

## Phase 4: Rollback Plan

If anything goes wrong after switchover, you can revert in under 30 seconds.

### Immediate Rollback (< 30 seconds)

The old volume and backup compose file are still intact:

```bash
# Restore the PG15 compose file
cp docker-compose.pg15-backup.yml docker-compose.yml

# Restart with old config (old volume still has all data)
docker compose down && docker compose up -d
```

That is it. The old `postgres_data` volume was never deleted, so PG15 starts with all its original data.

### If You Need a Fresh Restore

In the unlikely event that the old volume was corrupted:

```bash
# The SQL backup still exists
ls -lh ~/pg15_full_backup.sql

# Create a fresh PG15 container and restore
docker volume create pg15-recovery
docker run -d --name pg15-recovery \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=your_password_here \
  -v pg15-recovery:/var/lib/postgresql/data \
  pgvector/pgvector:pg15

docker exec -i pg15-recovery psql -U postgres < ~/pg15_full_backup.sql
```

---

## Phase 5: Post-upgrade Cleanup

Only perform cleanup after the new stack has been running stably for at least 24-48 hours.

### Remove the Old Volume

```bash
# Confirm the old volume name
docker volume ls | grep postgres

# Remove it (ONLY after confirming PG17 is stable)
docker volume rm postgres_data
```

### Remove the Backup Files

```bash
rm ~/pg15_full_backup.sql
rm docker-compose.pg15-backup.yml
```

### Remove the Test Image (optional)

```bash
docker image rm pgvector/pgvector:pg15
```

### Clean Up Unused Docker Resources

```bash
# Remove only dangling images (safe)
docker image prune -f
```

---

## Complete Checklist

Use this as a runbook during the upgrade:

```
PRE-UPGRADE
  [ ] Record PG version: SELECT version();
  [ ] Record extensions: SELECT * FROM pg_extension;
  [ ] Record database sizes
  [ ] Record row counts for all tables
  [ ] Pull new image: docker pull pgvector/pgvector:pg17

PREPARE (while DB is running)
  [ ] Full backup: pg_dumpall > ~/pg15_full_backup.sql
  [ ] Verify backup file (tail, file size)
  [ ] Create new volume: docker volume create limor-pg17-data
  [ ] Start PG17 on port 5433
  [ ] Restore backup into PG17
  [ ] Verify: version, databases, extensions, row counts, pgvector queries

SWITCHOVER (~5 seconds)
  [ ] Stop test container
  [ ] Back up docker-compose.yml
  [ ] Update compose file (image + volume)
  [ ] docker compose down && docker compose up -d
  [ ] Verify all services running
  [ ] Verify application connectivity

POST-UPGRADE (after 24-48 hours stable)
  [ ] Remove old volume
  [ ] Remove backup SQL file
  [ ] Remove backup compose file
  [ ] Remove old Docker image (optional)
```

---

## Timing Reference

| Step | Duration | DB Available? |
|------|----------|---------------|
| pg_dumpall (250 MB total) | ~30 seconds | Yes |
| Pull PG17 image | ~60 seconds | Yes |
| Create volume | < 1 second | Yes |
| Start PG17 test container | ~5 seconds | Yes |
| Restore into PG17 | ~45 seconds | Yes |
| Verification checks | ~5 minutes | Yes |
| **Switchover (compose down/up)** | **~5 seconds** | **No** |
| Post-switchover verification | ~5 minutes | Yes |
| **Total procedure** | **~15 minutes** | **99.4% uptime** |

---

## Troubleshooting

### pg_dumpall Produces Empty or Truncated File

**Symptom**: Backup file is 0 bytes or missing the final `dump complete` line.

**Cause**: Disk full, or the container name is wrong.

**Fix**:
```bash
# Check disk space
df -h ~

# Verify container name
docker ps --format '{{.Names}}' | grep postgres

# Re-run with correct container name
docker exec -i CORRECT_CONTAINER_NAME pg_dumpall -U postgres > ~/pg15_full_backup.sql
```

### Restore Fails with "role already exists"

**Symptom**: `ERROR: role "postgres" already exists`

**This is expected and harmless.** The `pg_dumpall` output includes `CREATE ROLE postgres` but the role already exists in the fresh container. The restore continues past this error.

### pgvector Extension Not Found After Restore

**Symptom**: `ERROR: could not open extension control file "/usr/share/postgresql/17/extension/vector.control"`

**Cause**: Using a plain `postgres:17` image instead of `pgvector/pgvector:pg17`.

**Fix**: Always use the pgvector image:
```bash
docker run -d --name pg17-test ... pgvector/pgvector:pg17
```

### Application Cannot Connect After Switchover

**Symptom**: Connection refused on port 5432.

**Fix**:
```bash
# Check the container is running and healthy
docker compose ps

# Check port mapping
docker port limor-postgres

# Check PostgreSQL is accepting connections
docker exec -i limor-postgres pg_isready -U postgres
```

If `pg_isready` reports "accepting connections," the issue is in the application config, not PostgreSQL.

### Row Count Mismatch After Restore

**Symptom**: `pg_stat_user_tables.n_live_tup` shows different numbers.

**Note**: `n_live_tup` is an estimate updated by autovacuum/analyze. After a fresh restore, run:

```bash
docker exec -i pg17-test psql -U postgres -d limor_prod -c "ANALYZE;"
```

Then re-check the counts. For exact counts, use:

```bash
docker exec -i pg17-test psql -U postgres -d limor_prod -c "
  SELECT 'table_name' AS tbl, count(*) FROM table_name;
"
```

---

## Key Takeaways

1. **Never change the PG image tag in-place.** Major version upgrades require dump-and-restore because the on-disk format is incompatible.

2. **Run the new version in parallel first.** Port 5433 lets you verify everything without touching production.

3. **Keep the old volume until you are certain.** The rollback is instant if you preserve it.

4. **pg_dumpall over pg_dump.** `pg_dumpall` captures roles, permissions, and all databases in one shot. `pg_dump` only captures a single database and misses cluster-level objects.

5. **pgvector upgrades transparently.** The extension version may bump (0.7.4 to 0.8.0) but this is handled automatically during restore. No manual extension upgrade is needed.

6. **The actual downtime is just the compose restart.** Everything else -- backup, restore, verification -- happens while the old database is still serving traffic.

---

**Validated**: February 2026 -- PG15 to PG17 upgrade on LimorAI Docker stack
**Result**: Zero data loss, ~5 seconds downtime, pgvector 0.7.4 upgraded to 0.8.0 automatically
**Rollback tested**: Old volume preserved, one-command revert confirmed working
