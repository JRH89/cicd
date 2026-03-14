#!/bin/bash
set -e

echo "=== DEPLOYMENT STARTED ==="
echo "Repository: $(basename $(pwd))"
echo "Timestamp: $(date)"
echo "Current directory: $(pwd)"

echo "=== PULLING LATEST CHANGES ==="
git pull origin main || echo "⚠️ Git pull failed, continuing with current code..."

# Add your deployment commands here
# Uncomment and modify the sections you need

# === OPTION 1: Node.js Application ===
# echo "=== INSTALLING DEPENDENCIES ==="
# npm ci --production
# 
# echo "=== BUILDING APPLICATION ==="
# npm run build
# 
# echo "=== RESTARTING APPLICATION ==="
# pm2 restart app-name || pm2 start ecosystem.config.js

# === OPTION 2: Docker Application ===
# echo "=== REBUILDING DOCKER CONTAINERS ==="
# if [ "$FORCE_CLEAN_BUILD" = "true" ]; then
#     echo "🧹 Forcing clean build (no cache)..."
#     docker compose build --no-cache
#     docker compose up -d --force-recreate
# else
#     echo "🔄 Standard rebuild (using cache)..."
#     docker compose down
#     docker compose up -d --build --force-recreate
# fi
# 
# echo "=== WAITING FOR CONTAINERS TO BE READY ==="
# sleep 10
# docker compose ps

# === OPTION 3: Static Site ===
# echo "=== BUILDING STATIC SITE ==="
# npm run build
# 
# echo "=== DEPLOYING TO WEB SERVER ==="
# rsync -avz --delete dist/ user@server:/var/www/site/

# === OPTION 4: Python Application ===
# echo "=== INSTALLING DEPENDENCIES ==="
# python -m pip install -r requirements.txt
# 
# echo "=== RUNNING MIGRATIONS ==="
# python manage.py migrate
# 
# echo "=== RESTARTING SERVICES ==="
# systemctl restart my-app.service

# === OPTION 5: Generic Commands ===
# echo "=== RUNNING CUSTOM COMMANDS ==="
# Add your custom deployment commands here

# === CLEANUP (Optional) ===
echo "=== CLEANING UP ==="
# docker image prune -f --filter "until=24h"
# npm cache clean --force

echo "=== DEPLOYMENT SUCCESSFUL ==="
echo "Completed at: $(date)"

# Health check (optional)
# echo "=== RUNNING HEALTH CHECK ==="
# curl -f http://localhost:3000/health || exit 1
