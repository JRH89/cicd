#!/bin/bash
set -e

echo "=== Installing deployment script ==="

# Check if template type is specified
TEMPLATE_TYPE=${1:-sample}

# Valid template types
VALID_TEMPLATES=("sample" "docker" "nodejs" "static")

if [[ ! " ${VALID_TEMPLATES[@]} " =~ " ${TEMPLATE_TYPE} " ]]; then
    echo "❌ Invalid template type: $TEMPLATE_TYPE"
    echo "Valid options: ${VALID_TEMPLATES[*]}"
    exit 1
fi

echo "Template type: $TEMPLATE_TYPE"

# Check if deploy.sh already exists
if [ -f "deploy.sh" ]; then
    read -p "deploy.sh already exists. Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 1
    fi
    cp deploy.sh deploy.sh.backup
    echo "✅ Backed up existing deploy.sh"
fi

# Download template
CI_CD_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")"
TEMPLATE_FILE="$CI_CD_DIR/deploy-templates/${TEMPLATE_TYPE}-deploy.sh"
TEMPLATE_URL="http://192.168.254.54:3000/jrh89/cicd/raw/main/deploy-templates/${TEMPLATE_TYPE}-deploy.sh"

if [ -f "$TEMPLATE_FILE" ]; then
    cp "$TEMPLATE_FILE" deploy.sh
    echo "✅ Copied $TEMPLATE_TYPE template"
else
    echo "⬇️ Downloading template from Gitea..."
    curl -sSL "$TEMPLATE_URL" -o deploy.sh || {
        echo "❌ Failed to download template"
        exit 1
    }
    echo "✅ Downloaded $TEMPLATE_TYPE template"
fi

# Make executable
chmod +x deploy.sh

echo ""
echo "✅ Deployment script installed!"
echo "File: deploy.sh"
echo "Template: $TEMPLATE_TYPE"
echo ""
echo "Next steps:"
echo "1. Customize deploy.sh for your project"
echo "2. Test deployment: ./deploy.sh"
echo "3. Set up webhook in Gitea"
