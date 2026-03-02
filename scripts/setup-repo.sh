#!/bin/bash
set -e

echo "=== Setting up repository for CI/CD deployment ==="

# Get repository name from current directory
REPO_NAME=$(basename "$(pwd)")
echo "Repository: $REPO_NAME"

# Check if deploy.sh already exists
if [ -f "deploy.sh" ]; then
    echo "⚠️  deploy.sh already exists. Backing up to deploy.sh.backup"
    cp deploy.sh deploy.sh.backup
fi

# Determine project type and select appropriate template
TEMPLATE_TYPE="sample"

if [ -f "package.json" ]; then
    if grep -q "docker-compose.yml" . 2>/dev/null || [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ]; then
        TEMPLATE_TYPE="docker"
    else
        TEMPLATE_TYPE="nodejs"
    fi
elif [ -f "Dockerfile" ] || [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ]; then
    TEMPLATE_TYPE="docker"
elif [ -f "index.html" ] || [ -f "src/index.html" ]; then
    TEMPLATE_TYPE="static"
fi

echo "Detected project type: $TEMPLATE_TYPE"
echo "Using template: ${TEMPLATE_TYPE}-deploy.sh"

# Download the appropriate template
TEMPLATE_URL="http://192.168.254.54:3000/jrh89/cicd/raw/main/deploy-templates/${TEMPLATE_TYPE}-deploy.sh"

# For now, copy from local CI-CD directory
CI_CD_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")"
if [ -f "$CI_CD_DIR/deploy-templates/${TEMPLATE_TYPE}-deploy.sh" ]; then
    cp "$CI_CD_DIR/deploy-templates/${TEMPLATE_TYPE}-deploy.sh" deploy.sh
    echo "✅ Copied deployment template"
else
    echo "⬇️ Downloading template from Gitea..."
    curl -sSL "$TEMPLATE_URL" -o deploy.sh || {
        echo "❌ Failed to download template"
        exit 1
    }
fi

# Make it executable
chmod +x deploy.sh

echo ""
echo "✅ Repository setup complete!"
echo ""
echo "Next steps:"
echo "1. Review and customize deploy.sh for your specific needs"
echo "2. Add webhook to Gitea:"
echo "   URL: http://192.168.254.54:9001/deploy"
echo "   Events: Push events"
echo "   Branches: main, master"
echo "3. Push to main branch to test deployment"
echo ""
echo "Deployment script: deploy.sh"
echo "Template used: $TEMPLATE_TYPE"
echo "Repository name: $REPO_NAME"
