#!/bin/bash
set -e

echo "=== Installing Universal Webhook Server ==="

# Check if running as root for systemd operations
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)"
   exit 1
fi

# Get current user (not root)
REAL_USER=${SUDO_USER:-$USER}
WEBHOOK_DIR="/home/$REAL_USER/CI-CD/webhook-server"
SERVICE_NAME="webhook-multi-repo"
REPOS_BASE_DIR=${REPOS_BASE_DIR:-"/home/$REAL_USER"}

echo "Installing for user: $REAL_USER"
echo "Webhook directory: $WEBHOOK_DIR"

# Stop existing service if running
systemctl stop $SERVICE_NAME 2>/dev/null || true
systemctl disable $SERVICE_NAME 2>/dev/null || true

# Create webhook directory if it doesn't exist
mkdir -p "$WEBHOOK_DIR"
chown -R "$REAL_USER:$REAL_USER" "$WEBHOOK_DIR"
chmod 755 "$WEBHOOK_DIR"

# Copy files (assuming script is run from cicd directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/webhook-multi-repo.js" "$WEBHOOK_DIR/"
cp "$SCRIPT_DIR/webhook-multi-repo.service" "$WEBHOOK_DIR/"
chown "$REAL_USER:$REAL_USER" "$WEBHOOK_DIR"/*.js "$WEBHOOK_DIR"/*.service
chmod +x "$WEBHOOK_DIR"/*.js

# Update service file with correct paths
sed -i "s|__USER__|$REAL_USER|g" "$WEBHOOK_DIR/webhook-multi-repo.service"
sed -i "s|__WEBHOOK_DIR__|$WEBHOOK_DIR|g" "$WEBHOOK_DIR/webhook-multi-repo.service"

# Add REPOS_BASE_DIR environment variable to service
sed -i "/\[Service\]/a Environment=REPOS_BASE_DIR=$REPOS_BASE_DIR" "$WEBHOOK_DIR/webhook-multi-repo.service"

# Install systemd service
cp "$WEBHOOK_DIR/webhook-multi-repo.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable $SERVICE_NAME

# Start the service
systemctl start $SERVICE_NAME

# Wait a moment and check status
sleep 2
if systemctl is-active --quiet $SERVICE_NAME; then
    echo "✅ Webhook server installed and running successfully!"
    echo ""
    echo "Service Details:"
    echo "- Name: $SERVICE_NAME"
    echo "- Port: 9001"
    echo "- Logs: journalctl -u $SERVICE_NAME -f"
    echo "- Status: systemctl status $SERVICE_NAME"
    echo ""
    echo "Webhook URL: http://$(hostname -I | awk '{print $1}'):9001/deploy"
    echo ""
    echo "Next steps:"
    echo "1. Add this webhook URL to your Gitea repositories"
    echo "2. Use setup-repo.sh to configure individual repositories"
else
    echo "❌ Failed to start webhook server"
    echo "Check logs: journalctl -u $SERVICE_NAME -n 20"
    exit 1
fi
