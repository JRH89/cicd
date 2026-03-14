#!/bin/bash
set -e

echo "=== NODE.JS DEPLOYMENT STARTED ==="
echo "Repository: $(basename $(pwd))"
echo "Timestamp: $(date)"
echo "Current directory: $(pwd)"

echo "=== INSTALLING DEPENDENCIES ==="
npm ci --production

echo "=== BUILDING APPLICATION ==="
npm run build

echo "=== RESTARTING APPLICATION ==="
if command -v pm2 &> /dev/null; then
    pm2 restart $(basename $(pwd)) || pm2 start ecosystem.config.js
else
    echo "PM2 not found, using systemctl"
    sudo systemctl restart $(basename $(pwd)).service
fi

echo "=== CLEANING UP ==="
npm cache clean --force

echo "=== DEPLOYMENT SUCCESSFUL ==="
echo "Completed at: $(date)"

# Health check
echo "=== RUNNING HEALTH CHECK ==="
curl -f http://localhost:3000/health || exit 1
