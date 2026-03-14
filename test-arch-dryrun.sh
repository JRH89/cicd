#!/bin/bash
# Dry run test for Arch Linux installation

echo "=== Arch Linux Installation Dry Run ==="

# Simulate the installation logic without actually installing anything
echo "This script will show what the install script would do on Arch Linux..."

# Test OS detection
if command -v pacman &> /dev/null; then
    echo "✅ Detected Arch Linux (pacman found)"
    echo "📦 Would run: pacman -Sy --noconfirm nodejs npm"
else
    echo "❌ Not on Arch Linux (pacman not found)"
    echo "This test is designed for Arch Linux systems"
    exit 1
fi

# Test user detection
REAL_USER=${SUDO_USER:-$USER}
echo "👤 Current user: $REAL_USER"

if [[ "$REAL_USER" == "root" ]]; then
    REAL_USER=$(logname 2>/dev/null || echo $SUDO_USER)
    echo "👤 After logname check: $REAL_USER"
fi

# Test directory creation
if [[ -d "/home/$REAL_USER" ]]; then
    WEBHOOK_DIR="/home/$REAL_USER/CI-CD/webhook-server"
    REPOS_BASE_DIR="/home/$REAL_USER"
    echo "📁 Would create: $WEBHOOK_DIR"
else
    WEBHOOK_DIR="$REAL_USER/CI-CD/webhook-server"
    REPOS_BASE_DIR="$REAL_USER"
    echo "📁 Would create: $WEBHOOK_DIR (fallback path)"
fi

# Test Node.js detection
if command -v node &> /dev/null; then
    echo "✅ Node.js already installed: $(node --version)"
    echo "🔧 Would use existing Node.js at: $(which node)"
else
    echo "📦 Would install Node.js via pacman"
fi

# Test service file creation
echo "⚙️  Would create systemd service: /etc/systemd/system/webhook-multi-repo.service"
echo "🔧 Would set Node.js path to: $(which node)"
echo "🔧 Would set user to: $REAL_USER"
echo "🔧 Would set webhook directory to: $WEBHOOK_DIR"
echo "🔧 Would set repos base directory to: $REPOS_BASE_DIR"

# Test port availability
if command -v netstat &> /dev/null; then
    if netstat -tuln | grep -q ":9001 "; then
        echo "⚠️  Port 9001 is already in use"
    else
        echo "✅ Port 9001 is available"
    fi
fi

echo ""
echo "=== Summary ==="
echo "The installation would:"
echo "1. ✅ Detect Arch Linux correctly"
echo "2. 📦 Install Node.js if needed"
echo "3. 📁 Create webhook directory at: $WEBHOOK_DIR"
echo "4. ⚙️  Setup systemd service"
echo "5. 🚀 Start webhook server on port 9001"
echo ""
echo "No actual changes were made. This was a dry run test."
