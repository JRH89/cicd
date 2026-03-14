#!/bin/bash
set -e

echo "=== DOCKER DEPLOYMENT STARTED ==="
echo "Repository: $(basename $(pwd))"
echo "Timestamp: $(date)"
echo "Current directory: $(pwd)"

echo "=== PULLING LATEST CHANGES ==="
git pull origin main || echo "⚠️ Git pull failed, continuing with current code..."

echo "=== REBUILDING DOCKER CONTAINERS ==="
if [ "$FORCE_CLEAN_BUILD" = "true" ]; then
    echo "🧹 Forcing clean build (no cache)..."
    docker compose build --no-cache
    docker compose up -d --force-recreate
else
    echo "🔄 Standard rebuild (using cache)..."
    docker compose down
    docker compose up -d --build --force-recreate
fi

echo "=== WAITING FOR CONTAINERS TO BE READY ==="
sleep 10
docker compose ps

echo "=== CLEANING UP OLD IMAGES ==="
docker image prune -f --filter "until=24h"

echo "=== DEPLOYMENT SUCCESSFUL ==="
echo "Completed at: $(date)"

# Health check
echo "=== RUNNING HEALTH CHECK ==="
# Add your health check URL here
# curl -f http://localhost:3000/health || exit 1
