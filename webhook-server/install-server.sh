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

# Check for Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed"
    echo "Installing Node.js..."
    
    # Detect OS and install Node.js
    if command -v apt &> /dev/null; then
        # Ubuntu/Debian
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        apt-get install -y nodejs
    elif command -v yum &> /dev/null; then
        # CentOS/RHEL
        curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
        yum install -y nodejs
    elif command -v dnf &> /dev/null; then
        # Fedora
        dnf install -y nodejs
    else
        echo "❌ Could not detect package manager. Please install Node.js manually:"
        echo "   https://nodejs.org/en/download/"
        exit 1
    fi
    
    # Verify installation
    if ! command -v node &> /dev/null; then
        echo "❌ Node.js installation failed"
        exit 1
    fi
    
    echo "✅ Node.js installed: $(node --version)"
else
    echo "✅ Node.js found: $(node --version)"
fi

# Stop existing service if running
systemctl stop $SERVICE_NAME 2>/dev/null || true
systemctl disable $SERVICE_NAME 2>/dev/null || true

# Create webhook directory if it doesn't exist
mkdir -p "$WEBHOOK_DIR"
chown -R "$REAL_USER:$REAL_USER" "$WEBHOOK_DIR"
chmod 755 "$WEBHOOK_DIR"

# Download files from GitHub
echo "📥 Downloading webhook server files..."
curl -sSL "https://github.com/jrh89/cicd/raw/master/webhook-server/webhook-multi-repo.js" -o "$WEBHOOK_DIR/webhook-multi-repo.js" || {
    echo "❌ Failed to download webhook-multi-repo.js"
    exit 1
}
curl -sSL "https://github.com/jrh89/cicd/raw/master/webhook-server/webhook-multi-repo.service" -o "$WEBHOOK_DIR/webhook-multi-repo.service" || {
    echo "❌ Failed to download webhook-multi-repo.service"
    exit 1
}
chown "$REAL_USER:$REAL_USER" "$WEBHOOK_DIR"/*.js "$WEBHOOK_DIR"/*.service
chmod +x "$WEBHOOK_DIR"/*.js

# Update service file with correct paths
sed -i "s|__USER__|$REAL_USER|g" "$WEBHOOK_DIR/webhook-multi-repo.service"
sed -i "s|__WEBHOOK_DIR__|$WEBHOOK_DIR|g" "$WEBHOOK_DIR/webhook-multi-repo.service"
sed -i "s|/usr/bin/node|$(which node)|g" "$WEBHOOK_DIR/webhook-multi-repo.service"

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
