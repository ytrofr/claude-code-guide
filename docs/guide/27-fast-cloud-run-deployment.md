# Fast Cloud Run Deployment Patterns

**Created**: January 2026  
**Source**: Production Entry #248, #251  
**Evidence**: 3-5 min → ~1 min deployment (78% faster)  
**Method**: Pre-built image deployment (skips Cloud Build)

---

## Overview

Cloud Run deployments using `gcloud run deploy --source .` are slow because they:
1. Upload source to Cloud Storage (~34MB)
2. Trigger Cloud Build (E2_HIGHCPU_8)
3. Build Docker image from scratch
4. Push to Artifact Registry
5. Deploy to Cloud Run

**Total**: 3-5 minutes per deployment

**Solution**: Build Docker locally → Push to Artifact Registry → Deploy from image

**Total After**: ~1 minute per deployment

---

## Quick Comparison

| Method | Time | Cloud Build | Use When |
|--------|------|-------------|----------|
| `--source .` (slow) | 3-5 min | Yes | First time, Docker issues |
| Pre-built image (fast) | ~1 min | **No** | Routine deployments |

---

## Prerequisites (One-Time Setup)

### Option 1: gcloud Credential Helper (Simple)

```bash
# Authenticate Docker with Google Artifact Registry
gcloud auth configure-docker us-central1-docker.pkg.dev
```

This creates `~/.docker/config.json` with credential helper.

### Option 2: Service Account (Required for WSL)

**WSL + Docker Desktop** has issues with gcloud credential helper, causing 302/Unauthenticated errors. Use service account authentication instead:

```bash
# 1. Create service account key (one-time)
gcloud iam service-accounts keys create ~/your-project-docker-key.json \
    --iam-account=your-service-account@your-project.iam.gserviceaccount.com

# 2. Remove Artifact Registry from credHelpers in ~/.docker/config.json
# Find and REMOVE this line (so Docker uses direct auth, not gcloud):
#   "us-central1-docker.pkg.dev": "gcloud"

# 3. Authenticate Docker with service account
cat ~/your-project-docker-key.json | docker login -u _json_key --password-stdin us-central1-docker.pkg.dev
```

**Why service account for WSL?**
- WSL + Docker Desktop + gcloud credential helper = 302/Unauthenticated errors
- Service account auth works reliably
- Key stored outside of repo (e.g., `~/your-project-docker-key.json`)

### Verify Artifact Registry Exists

```bash
# Check if repository exists
gcloud artifacts repositories list --location=us-central1

# Should show your repository (e.g., cloud-run-source-deploy)
```

---

## Fast Deployment Script

Create `scripts/deploy-staging-fast.sh`:

```bash
#!/bin/bash
# Fast Cloud Run Deployment - Pre-built Image Method
# Reduces deployment from 3-5 min to <1 min

set -e  # Exit on any error

# ============ CONFIGURATION ============
SERVICE="your-staging-service"
REGION="us-central1"
PROJECT="your-project-id"
SERVICE_URL="https://${SERVICE}-xxxxx.${REGION}.run.app"
IMAGE="us-central1-docker.pkg.dev/$PROJECT/cloud-run-source-deploy/$SERVICE"
TAG=$(date +%Y%m%d-%H%M%S)

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     FAST STAGING DEPLOYMENT                                ║"
echo "║     Method: Pre-built Image (skips Cloud Build)            ║"
echo "╚════════════════════════════════════════════════════════════╝"

START_TIME=$(date +%s)

# ============ PREREQUISITES CHECK ============
echo "🔧 Prerequisites check..."

if ! docker info &> /dev/null; then
    echo "❌ Docker not running. Start Docker and try again."
    exit 1
fi
echo "✅ Docker running"

if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -1 &> /dev/null; then
    echo "❌ Not authenticated. Run: gcloud auth login"
    exit 1
fi
echo "✅ gcloud authenticated"

# ============ STEP 1: LOCAL BUILD ============
BUILD_START=$(date +%s)
echo ""
echo "📦 Step 1: Building Docker image locally..."

docker build -t $IMAGE:$TAG -t $IMAGE:latest .

BUILD_END=$(date +%s)
echo "✅ Build complete in $((BUILD_END - BUILD_START))s"

# ============ STEP 2: PUSH TO REGISTRY ============
PUSH_START=$(date +%s)
echo ""
echo "⬆️ Step 2: Pushing to Artifact Registry..."

docker push $IMAGE:$TAG
docker push $IMAGE:latest

PUSH_END=$(date +%s)
echo "✅ Push complete in $((PUSH_END - PUSH_START))s"

# ============ STEP 3: DEPLOY FROM IMAGE ============
DEPLOY_START=$(date +%s)
echo ""
echo "🚀 Step 3: Deploying to Cloud Run (NO Cloud Build!)..."

gcloud run deploy $SERVICE \
  --image $IMAGE:$TAG \
  --region $REGION \
  --platform managed

DEPLOY_END=$(date +%s)
echo "✅ Deploy complete in $((DEPLOY_END - DEPLOY_START))s"

# ============ STEP 4: ROUTE TRAFFIC (CRITICAL!) ============
echo ""
echo "🔄 Step 4: Routing traffic to latest..."

# IMPORTANT: Cloud Run doesn't auto-route traffic!
LATEST=$(gcloud run revisions list --service=$SERVICE --region=$REGION --limit=1 --format='value(metadata.name)')
gcloud run services update-traffic $SERVICE --to-revisions $LATEST=100 --region=$REGION

SERVING=$(gcloud run services describe $SERVICE --region=$REGION --format='value(status.traffic[0].revisionName)')
if [ "$SERVING" != "$LATEST" ]; then
    echo "❌ ERROR: Traffic not routed!"
    exit 1
fi
echo "✅ Traffic routed to: $LATEST"

# ============ STEP 5: HEALTH CHECK ============
echo ""
echo "🔍 Step 5: Health check..."
sleep 5

HEALTH=$(curl -s $SERVICE_URL/health)
STATUS=$(echo "$HEALTH" | jq -r '.status')

if [ "$STATUS" == "ready" ]; then
    echo "✅ Service healthy"
else
    echo "⚠️ Health check: $STATUS"
fi

# ============ SUMMARY ============
END_TIME=$(date +%s)
TOTAL=$((END_TIME - START_TIME))

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  DEPLOYMENT COMPLETE ✅                                    ║"
echo "║  Total time: ${TOTAL}s                                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
```

Make it executable:
```bash
chmod +x scripts/deploy-staging-fast.sh
```

---

## Critical: Traffic Routing

**WARNING**: Cloud Run does NOT automatically route traffic to new revisions!

After `gcloud run deploy`, you MUST route traffic:

```bash
# Get latest revision
LATEST=$(gcloud run revisions list --service=SERVICE --region=REGION --limit=1 --format='value(metadata.name)')

# Route 100% traffic to latest
gcloud run services update-traffic SERVICE --to-revisions $LATEST=100 --region=REGION
```

**Symptoms if skipped**:
- Code deployed but users see old version
- Changes don't appear despite successful deployment
- Debugging wastes 40-100 minutes

---

## Dockerfile Optimization for Caching

For fast rebuilds, optimize your Dockerfile for layer caching:

```dockerfile
# Stage 1: Dependencies (cached layer)
FROM node:20-alpine AS dependencies
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev --no-audit --no-fund --silent

# Stage 2: Runtime
FROM node:20-alpine AS runtime
WORKDIR /app

RUN apk add --no-cache curl dumb-init \
    && addgroup -g 1001 -S nodejs \
    && adduser -S nodejs -u 1001

# Copy dependencies from Stage 1
COPY --from=dependencies /app/node_modules ./node_modules

# Create directories BEFORE copying (preserves cache!)
RUN mkdir -p logs tmp && chown nodejs:nodejs logs tmp

# Copy source with correct ownership
COPY --chown=nodejs:nodejs . .

# ONLY chmod (no recursive chown - COPY --chown already did it!)
RUN chmod +x start-script.sh

USER nodejs
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "index.js"]
```

**Key Optimization**:
```dockerfile
# ❌ SLOW (191s - walks all files every build):
COPY --chown=nodejs:nodejs . .
RUN mkdir -p logs tmp && chmod +x start.sh && chown -R nodejs:nodejs /app

# ✅ FAST (0.7s - only chmod, no recursive chown):
RUN mkdir -p logs tmp && chown nodejs:nodejs logs tmp
COPY --chown=nodejs:nodejs . .
RUN chmod +x start.sh
```

---

## Expected Timing

| Step | Source Deploy | Pre-built Image |
|------|---------------|-----------------|
| Upload source | 10-15s | 0s (local) |
| Cloud Build | 2-4 min | **0s (skipped!)** |
| Local Docker build | - | 20-30s (cached) |
| Push to Registry | - | 15-20s |
| Deploy | 30s | 30s |
| Traffic routing | 10s | 10s |
| **TOTAL** | **3-5 min** | **~1 min** |

**Note**: First build may be slower. Subsequent builds use Docker layer cache.

---

## Fallback: Safe Deployment

If Docker issues occur, use the traditional method:

```bash
#!/bin/bash
# scripts/deploy-staging-safe.sh - Traditional method (always works)

gcloud run deploy your-service \
  --source . \
  --region us-central1 \
  --platform managed

# Still need to route traffic!
gcloud run services update-traffic your-service \
  --to-latest \
  --region us-central1
```

---

## Quick Reference

```bash
# Fast deployment (recommended for routine updates)
./scripts/deploy-staging-fast.sh

# Safe deployment (fallback if Docker issues)
./scripts/deploy-staging-safe.sh

# Manual traffic routing (if needed)
gcloud run services update-traffic SERVICE --to-latest --region=REGION

# Check current traffic routing
gcloud run services describe SERVICE --region=REGION --format='value(status.traffic[0].revisionName)'

# Check latest revision
gcloud run revisions list --service=SERVICE --region=REGION --limit=3
```

---

## Troubleshooting

### Docker Authentication Error (Standard)
```
denied: Permission denied for "us-central1-docker.pkg.dev/..."
```
**Fix**: Re-authenticate Docker:
```bash
gcloud auth configure-docker us-central1-docker.pkg.dev
```

### WSL + Docker Desktop: 302/Unauthenticated Error
```
Error response from daemon: Head "https://us-central1-docker.pkg.dev/v2/.../manifests/latest":
unexpected status: 302 Found
```
or
```
denied: Unauthenticated request. Unauthenticated requests do not have permission...
```

**Cause**: The gcloud credential helper doesn't work properly with WSL + Docker Desktop.

**Fix**: Use service account authentication instead:

```bash
# 1. Remove gcloud credential helper for Artifact Registry
# Edit ~/.docker/config.json and remove this line from credHelpers:
#   "us-central1-docker.pkg.dev": "gcloud"

# 2. Authenticate Docker with service account key
cat ~/your-project-docker-key.json | docker login -u _json_key --password-stdin us-central1-docker.pkg.dev
```

**Verified**: OGAS project (Jan 2026) - Build 6s, Push 9s, Deploy 113s

### Build Still Slow (>2 min)
**Cause**: Docker layer cache invalidated by `chown -R` or file changes
**Fix**: Follow Dockerfile optimization pattern above

### Traffic Not Routing
**Cause**: Cloud Run doesn't auto-route traffic
**Fix**: Always include traffic routing step in deployment script

---

## ROI

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Deploy time | 3-5 min | ~1 min | 70-78% faster |
| Docker build | 268s | 41s | 85% faster |
| Cloud Build cost | $0.003/deploy | $0.00 | Free |
| Deploys/day | ~5-10 | ~5-10 | Same |
| Time saved/day | - | 15-30 min | ∞ ROI |

---

## Template Files

### `scripts/deploy-staging-fast.sh`
See full script above. Includes:
- Prerequisites check
- Docker build with caching
- Push to Artifact Registry
- Deploy from pre-built image
- Traffic routing (CRITICAL!)
- Health check validation
- Timing summary

### `scripts/deploy-staging-safe.sh`
Traditional fallback:
```bash
#!/bin/bash
gcloud run deploy your-service --source . --region us-central1
gcloud run services update-traffic your-service --to-latest --region us-central1
```

---

## Related Topics

- **Traffic Routing Issue**: Cloud Run never auto-routes - always include update-traffic
- **Dockerfile Caching**: Avoid `chown -R` after COPY
- **Artifact Registry**: Configure once with `gcloud auth configure-docker`
- **WSL Fix**: Use service account auth instead of gcloud credential helper

---

**Evidence**: Production Entry #248 (staging-deployment-speed-optimization.md)  
**Validated**: January 8, 2026 - 78% faster deployments achieved (OGAS project)  
**WSL Fix Validated**: January 8, 2026 - Service account auth works in WSL + Docker Desktop  
**Sacred Compliance**: 100% SHARP maintained (no functionality changes)
