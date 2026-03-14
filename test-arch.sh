#!/bin/bash
# Test script for Arch Linux compatibility

echo "=== Testing Arch Linux Installation Logic ==="

# Test 1: Check if pacman command exists
if command -v pacman &> /dev/null; then
    echo "✅ pacman found: $(which pacman)"
else
    echo "❌ pacman not found"
fi

# Test 2: Check Node.js installation command
echo "Testing Node.js installation command:"
echo "pacman -Sy --noconfirm nodejs npm"

# Test 3: Check user detection logic
REAL_USER=${SUDO_USER:-$USER}
echo "Current user detection: $REAL_USER"

if [[ "$REAL_USER" == "root" ]]; then
    REAL_USER=$(logname 2>/dev/null || echo $SUDO_USER)
    echo "After logname check: $REAL_USER"
fi

# Test 4: Check home directory logic
if [[ -d "/home/$REAL_USER" ]]; then
    echo "✅ Home directory found: /home/$REAL_USER"
    WEBHOOK_DIR="/home/$REAL_USER/CI-CD/webhook-server"
else
    echo "⚠️  Home directory not found, using fallback"
    WEBHOOK_DIR="$REAL_USER/CI-CD/webhook-server"
fi

echo "Webhook directory would be: $WEBHOOK_DIR"

# Test 5: Check if Node.js is already installed
if command -v node &> /dev/null; then
    echo "✅ Node.js already installed: $(node --version)"
else
    echo "❌ Node.js not installed, would install via pacman"
fi

echo "=== Test Complete ==="
