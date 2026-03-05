#!/bin/bash
set -e

echo "=== CI/CD Deployment System Installer ==="

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)"
   exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REAL_USER=${SUDO_USER:-$USER}
if [[ "$REAL_USER" == "root" ]]; then
    REAL_USER=$(logname 2>/dev/null || echo $SUDO_USER)
fi

if [[ -d "/home/$REAL_USER" ]]; then
    WEBHOOK_DIR="/home/$REAL_USER/CI-CD/webhook-server"
    REPOS_BASE_DIR=${REPOS_BASE_DIR:-"/home/$REAL_USER"}
else
    WEBHOOK_DIR="$REAL_USER/CI-CD/webhook-server"
    REPOS_BASE_DIR=${REPOS_BASE_DIR:-"$REAL_USER"}
fi

SERVICE_NAME="webhook-multi-repo"

echo "Installing for user: $REAL_USER"
echo "Webhook directory: $WEBHOOK_DIR"
echo "Script directory: $SCRIPT_DIR"

install_webhook_system() {
    echo "Installing webhook deployment system..."
    if [[ -f "$SCRIPT_DIR/webhook-server/install-server.sh" ]]; then
        chmod +x "$SCRIPT_DIR/webhook-server/install-server.sh"
        REPOS_BASE_DIR="$REPOS_BASE_DIR" "$SCRIPT_DIR/webhook-server/install-server.sh"
    else
        echo "Downloading install-server.sh..."
        curl -sSL https://raw.githubusercontent.com/jrh89/cicd/install-fix/webhook-server/install-server.sh -o install-server.sh
        chmod +x install-server.sh
        REPOS_BASE_DIR="$REPOS_BASE_DIR" ./install-server.sh
    fi
}

install_local_system() {
    echo "Installing local deployment system..."
    echo "Looking for: $SCRIPT_DIR/setup-local-deployment.sh"
    if [[ -f "$SCRIPT_DIR/setup-local-deployment.sh" ]]; then
        echo "Found local file, using it..."
        chmod +x "$SCRIPT_DIR/setup-local-deployment.sh"
        REPOS_BASE_DIR="$REPOS_BASE_DIR" "$SCRIPT_DIR/setup-local-deployment.sh"
    else
        echo "Local file not found, downloading..."
        curl -sSL https://raw.githubusercontent.com/jrh89/cicd/install-fix/setup-local-deployment.sh -o setup-local-deployment.sh
        chmod +x setup-local-deployment.sh
        REPOS_BASE_DIR="$REPOS_BASE_DIR" ./setup-local-deployment.sh
    fi
}

install_both_systems() {
    echo "Installing both webhook and local deployment systems..."
    install_webhook_system
    install_local_system
}

echo ""
echo "Choose installation method:"
echo "1) Webhook Deployment (GitHub/Gitea)"
echo "2) Local Deployment Only"
echo "3) Both Systems (Webhook + Local)"
echo ""
read -p "Enter choice [1-3]: " choice

case $choice in
    1) install_webhook_system ;;
    2) install_local_system ;;
    3) install_both_systems ;;
    *) install_webhook_system ;;
esac
