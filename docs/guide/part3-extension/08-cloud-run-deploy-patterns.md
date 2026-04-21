---
layout: default
title: "Cloud Run Deploy Patterns"
parent: "Part III — Extension"
nav_order: 8
redirect_from:
  - /docs/guide/27-fast-cloud-run-deployment.html
  - /docs/guide/27-fast-cloud-run-deployment/
---

# Cloud Run Deploy Patterns

`gcloud run deploy --source .` is the most common way to deploy to Cloud Run, and also one of the slowest. This chapter covers the pre-built image pattern — deploying a Docker image you built locally instead of letting Cloud Build do it — which typically cuts deploy time from 3-5 minutes to around 1 minute.

The pattern is boring and well-understood; most of the value is in the operational details: traffic routing, credential handling on WSL, Dockerfile caching, and a safe fallback for when Docker misbehaves.

---

## Why `--source .` Is Slow

`gcloud run deploy --source .` runs five steps in sequence: upload source to Cloud Storage, trigger Cloud Build (`E2_HIGHCPU_8`), build the image from scratch, push to Artifact Registry, deploy to Cloud Run. Steps 1-4 happen on Google's infrastructure — each deploy pays upload latency plus Cloud Build startup plus a fresh build (cache hit rates are worse there than on your laptop). Total: 3-5 minutes.

The fast path: build the image locally, push it to Artifact Registry, and tell `gcloud run deploy` to use that image directly. The Cloud Build steps disappear.

---

## Comparison

| Method | Typical time | Cloud Build | Use when |
|--------|--------------|-------------|----------|
| `--source .` | 3-5 min | Yes | First-ever deploy, Docker issues locally, CI/CD without Docker |
| Pre-built image | ~1 min | No | Routine deploys during active development |

The pre-built image path pays a small one-time setup cost (Docker auth against Artifact Registry). After that, each deploy is roughly 10× faster.

---

## One-Time Setup

### Option 1: gcloud credential helper (simplest)

```bash
# Teaches Docker to auth against Artifact Registry via gcloud
gcloud auth configure-docker us-central1-docker.pkg.dev
```

This writes a credential helper entry into `~/.docker/config.json`. Works out-of-the-box on Linux and macOS.

### Option 2: Service account key (required for WSL + Docker Desktop)

On WSL2 with Docker Desktop, the gcloud credential helper fails with 302 redirects or "Unauthenticated request" errors — OAuth flow mismatch. Use a service account key instead:

```bash
# 1. Create the key
gcloud iam service-accounts keys create ~/docker-push-key.json \
    --iam-account=your-sa@your-project.iam.gserviceaccount.com

# 2. Remove "us-central1-docker.pkg.dev": "gcloud" from credHelpers in ~/.docker/config.json

# 3. Auth Docker with the key
cat ~/docker-push-key.json | docker login \
    -u _json_key --password-stdin us-central1-docker.pkg.dev
```

Keep the key file outside any git repo.

### Verify the Artifact Registry repository exists

```bash
gcloud artifacts repositories list --location=us-central1
```

You need a repository (commonly named `cloud-run-source-deploy`, because that's the one `--source .` creates on first use) before you can push.

---

## The Fast Deploy Script

Save as `scripts/deploy-fast.sh` and `chmod +x` it:

```bash
#!/bin/bash
# Fast Cloud Run deploy — pre-built image, no Cloud Build
set -e

# ========== CONFIG ==========
SERVICE="your-service"
REGION="us-central1"
PROJECT="your-project-id"
SERVICE_URL="https://${SERVICE}-xxxxx.${REGION}.run.app"
IMAGE="${REGION}-docker.pkg.dev/${PROJECT}/cloud-run-source-deploy/${SERVICE}"
TAG=$(date +%Y%m%d-%H%M%S)

echo "=== Fast deploy to ${SERVICE} (pre-built image) ==="
START=$(date +%s)

# ========== PREREQUISITES ==========
docker info &> /dev/null || { echo "Docker not running"; exit 1; }
gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -1 \
    &> /dev/null || { echo "Run: gcloud auth login"; exit 1; }

# ========== 1. BUILD ==========
echo ">> Building image..."
BUILD_START=$(date +%s)
docker build -t "${IMAGE}:${TAG}" -t "${IMAGE}:latest" .
echo "   Build: $(($(date +%s) - BUILD_START))s"

# ========== 2. PUSH ==========
echo ">> Pushing to Artifact Registry..."
PUSH_START=$(date +%s)
docker push "${IMAGE}:${TAG}"
docker push "${IMAGE}:latest"
echo "   Push:  $(($(date +%s) - PUSH_START))s"

# ========== 3. DEPLOY ==========
echo ">> Deploying Cloud Run revision..."
DEPLOY_START=$(date +%s)
gcloud run deploy "${SERVICE}" \
    --image "${IMAGE}:${TAG}" \
    --region "${REGION}" \
    --platform managed
echo "   Deploy: $(($(date +%s) - DEPLOY_START))s"

# ========== 4. ROUTE TRAFFIC (critical!) ==========
echo ">> Routing traffic to latest revision..."
LATEST=$(gcloud run revisions list \
    --service="${SERVICE}" --region="${REGION}" \
    --limit=1 --format='value(metadata.name)')

gcloud run services update-traffic "${SERVICE}" \
    --to-revisions "${LATEST}=100" --region="${REGION}"

SERVING=$(gcloud run services describe "${SERVICE}" \
    --region="${REGION}" \
    --format='value(status.traffic[0].revisionName)')

if [ "${SERVING}" != "${LATEST}" ]; then
    echo "ERROR: traffic not routed to ${LATEST} (serving ${SERVING})"
    exit 1
fi
echo "   Traffic -> ${LATEST}"

# ========== 5. HEALTH CHECK ==========
echo ">> Health check..."
sleep 5
STATUS=$(curl -s "${SERVICE_URL}/health" | jq -r '.status // "unknown"')
echo "   Health: ${STATUS}"

echo "=== Done in $(($(date +%s) - START))s ==="
```

For unattended runs (CI, scripted calls with confirmation prompts), hold stdin open for the life of the script — see Part II on bash deploy patterns for why `echo yes | bash deploy.sh` closes the pipe early.

---

## Traffic Routing Is Not Automatic

This is the one footgun that trips up everyone exactly once.

`gcloud run deploy` creates a new revision and — depending on service config and flags — **does not necessarily route traffic to it**. The old revision keeps serving.

Symptoms:

- You deploy successfully, but the site shows the old version
- Tests against `/version` return the old commit SHA
- You waste 30-90 minutes debugging a "deploy that didn't work"

The fix is one command, shown in the script above:

```bash
LATEST=$(gcloud run revisions list --service=SERVICE --region=REGION --limit=1 --format='value(metadata.name)')
gcloud run services update-traffic SERVICE --to-revisions "${LATEST}=100" --region=REGION
```

Or, if you always want 100% to the newest:

```bash
gcloud run services update-traffic SERVICE --to-latest --region=REGION
```

Every production deploy script must include traffic routing as an explicit step. Don't rely on a flag to do it implicitly.

### Multi-session deploy safety

If another session is running canary or replay work, pre-pin traffic before your deploy completes — `gcloud run deploy` defaults to 100% on Ready, silently shifting traffic mid-experiment. Safer sequence: pin stable with `update-traffic --to-revisions=STABLE=100`, deploy with `--no-traffic`, optionally tag a preview (`--set-tags=preview=NEW_REV`), promote with `--to-revisions=NEW_REV=100 --remove-tags=preview`.

Killing `gcloud` mid-deploy doesn't abort the underlying Cloud Build — use `gcloud builds list` to check.

---

## Dockerfile Optimization for Cached Rebuilds

The fast path depends on Docker's layer cache. Two rules make or break it:

1. Copy dependency manifests and install dependencies in their **own layer**, before copying source.
2. Never run `chown -R` after `COPY` — it rewrites every file's metadata, invalidating the cache.

A Node.js example:

```dockerfile
# Stage 1: deps
FROM node:20-alpine AS dependencies
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev --no-audit --no-fund --silent

# Stage 2: runtime
FROM node:20-alpine AS runtime
WORKDIR /app

RUN apk add --no-cache curl dumb-init \
    && addgroup -g 1001 -S nodejs \
    && adduser -S nodejs -u 1001

# Deps from Stage 1
COPY --from=dependencies /app/node_modules ./node_modules

# Create writable dirs BEFORE copying source (so this layer caches)
RUN mkdir -p logs tmp && chown nodejs:nodejs logs tmp

# Source — use COPY --chown, not a follow-up chown -R
COPY --chown=nodejs:nodejs . .

# Only chmod individual entrypoints, never chown -R
RUN chmod +x start.sh

USER nodejs
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "index.js"]
```

`COPY --chown=...` already sets ownership. A follow-up `chown -R /app` walks the entire tree, writes every inode, and poisons the layer cache — meaning the next build redoes it. Only `chown` directories you explicitly created; let `COPY --chown` handle the rest.

---

## Expected Timing Breakdown

| Step | `--source .` | Pre-built image |
|------|--------------|-----------------|
| Upload source | 10-15s | 0s (build is local) |
| Cloud Build | 2-4 min | **0s (skipped)** |
| Local Docker build | — | 20-40s (cached), 60-120s (cold) |
| Push to Artifact Registry | — | 15-20s |
| Cloud Run deploy | 30s | 30s |
| Traffic routing | 10s | 10s |
| **Total** | **3-5 min** | **~1 min** |

First build after clearing the Docker cache will be slower. Typical day-two deploys land around 60 seconds end-to-end.

---

## Fallback: Source Deploy

When Docker is broken locally, when bootstrapping a new service, or when the credential helper is misbehaving, fall back to `--source .` — slower but always works:

```bash
#!/bin/bash
# scripts/deploy-safe.sh — traditional source deploy
set -e
gcloud run deploy your-service --source . --region us-central1 --platform managed
gcloud run services update-traffic your-service --to-latest --region us-central1
```

Keep both scripts. Use fast for routine iteration; use safe when something's off.

---

## Quick Reference

```bash
# Deploy
./scripts/deploy-fast.sh                                              # pre-built image
./scripts/deploy-safe.sh                                              # source deploy

# Traffic
gcloud run services update-traffic SERVICE --to-latest --region=REGION
gcloud run services update-traffic SERVICE --to-revisions=REV=100 --region=REGION

# Inspect
gcloud run services describe SERVICE --region=REGION \
    --format='value(status.traffic[0].revisionName)'
gcloud run revisions list --service=SERVICE --region=REGION --limit=5
gcloud run services logs read SERVICE --region=REGION --limit=30

# Build diagnostics
gcloud builds list --limit=5
```

---

## Troubleshooting

### `denied: Permission denied for "us-central1-docker.pkg.dev/..."`

Your Docker session isn't authed against Artifact Registry. Re-run:

```bash
gcloud auth configure-docker us-central1-docker.pkg.dev
```

On WSL2, use the service account path from the setup section.

### WSL + Docker Desktop: 302 / Unauthenticated

gcloud's credential helper doesn't play well with WSL2 + Docker Desktop. Remove the helper entry from `~/.docker/config.json` and auth with a service-account key — see Option 2 in setup.

### Build still slow (>2 min) on a warm cache

Something in your Dockerfile is invalidating the cache every build. Usual suspects: `chown -R` after `COPY`, `COPY . .` before dependency install, or `RUN` commands that touch files with non-deterministic output (timestamps, random IDs).

### "Deploy succeeded but changes don't appear"

Traffic routing. Always. Run:

```bash
gcloud run services describe SERVICE --region=REGION \
    --format='value(status.traffic)'
```

If the serving revision isn't the one you just deployed, route traffic manually.

### Feature toggle reverts after deploy

If you flip a Cloud Run env var via `gcloud run services update --update-env-vars KEY=VALUE` outside your deploy script, the next deploy reverts it — the script ships the literal value from its config, not whatever the running revision has. Put the expected value in the script and add a post-deploy assertion (`gcloud run services describe | grep KEY`) that fails the pipeline on mismatch.

### `gcloud run services logs read` returns empty

Known issue on WSL2: exit 0 with no output even when the service is logging. Fall back to the Logging API:

```bash
gcloud logging read 'resource.labels.service_name="SERVICE" AND logName:"stdout"' \
    --project=PROJECT --limit=30 --freshness=1h --format=json
```

---

## Related Topics

- **Bash deploy stdin** — holding stdin open for long-running deploy scripts
- **gcloud named configurations** — multi-project safety
- **Cross-service feature flip** — coordinated toggle flips
- **Cloud Run source-deploy gotchas** — package manager strictness, gcloudignore, first-time pitfalls
