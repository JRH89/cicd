#!/bin/bash
set -e

echo "=== CI/CD Deployment System Installer ==="

# Check if running as root for systemd operations
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)"
   exit 1
fi

# Get current user (not root)
REAL_USER=${SUDO_USER:-$USER}
# Handle Arch Linux user detection
if [[ "$REAL_USER" == "root" ]]; then
    # For Arch, try to get actual user who ran sudo
    REAL_USER=$(logname 2>/dev/null || echo $SUDO_USER)
fi

# Use appropriate home directory for user
if [[ -d "/home/$REAL_USER" ]]; then
    WEBHOOK_DIR="/home/$REAL_USER/CI-CD/webhook-server"
    REPOS_BASE_DIR=${REPOS_BASE_DIR:-"/home/$REAL_USER"}
else
    # Fallback for different home directory structures
    WEBHOOK_DIR="$REAL_USER/CI-CD/webhook-server"
    REPOS_BASE_DIR=${REPOS_BASE_DIR:-"$REAL_USER"}
fi

SERVICE_NAME="webhook-multi-repo"

echo "Installing for user: $REAL_USER"
echo "Webhook directory: $WEBHOOK_DIR"

# Interactive choice handling
echo ""
echo "Choose installation method:"
echo "1) Webhook Deployment (GitHub/Gitea) [RECOMMENDED]"
echo "2) Local Deployment Only [NEW]"
echo "3) Both Systems (Webhook + Local) [NEW]"
echo "4) Advanced Options"
echo ""
read -p "Enter choice [1-4]: " choice

case $choice in
    1) install_webhook_system ;;
    2) install_local_system ;;
    3) install_both_systems ;;
    4) show_advanced_options ;;
    *) install_webhook_system ;; # default
esac

install_webhook_system() {
    echo "Installing webhook deployment system..."
    # Execute existing install-server.sh
    if [[ -f "webhook-server/install-server.sh" ]]; then
        chmod +x webhook-server/install-server.sh
        REPOS_BASE_DIR="$REPOS_BASE_DIR" webhook-server/install-server.sh
    else
        echo "❌ webhook-server/install-server.sh not found"
        echo "Please ensure you're in the correct directory"
        exit 1
    fi
}

install_local_system() {
    echo "Installing local deployment system..."
    # Execute local deployment setup
    if [[ -f "setup-local-deployment.sh" ]]; then
        chmod +x setup-local-deployment.sh
        REPOS_BASE_DIR="$REPOS_BASE_DIR" ./setup-local-deployment.sh
    else
        echo "❌ setup-local-deployment.sh not found"
        echo "Please ensure you're in the correct directory"
        exit 1
    fi
}

install_both_systems() {
    echo "Installing both webhook and local deployment systems..."
    # Install webhook system first
    install_webhook_system
    # Then install local system
    install_local_system
}

show_advanced_options() {
    echo ""
    echo "=== Advanced Options ==="
    echo "1) Configure webhook port"
    echo "2) Set custom repos directory"
    echo "3) View current configuration"
    echo "4) Return to main menu"
    echo ""
    read -p "Enter choice [1-4]: " adv_choice
    
    case $adv_choice in
        1) configure_webhook_port ;;
        2) set_repos_directory ;;
        3) view_current_config ;;
        4) return_to_main_menu ;;
        *) return_to_main_menu ;;
    esac
}

configure_webhook_port() {
    echo ""
    read -p "Enter webhook port (default 9001): " new_port
    if [[ -n "$new_port" ]]; then
        echo "Updating webhook port to $new_port..."
        # Update service file with new port
        sed -i "s/PORT = 9001/PORT = $new_port/g" "$WEBHOOK_DIR/webhook-multi-repo.js"
        echo "✅ Port updated to $new_port"
    else
        echo "Port remains 9001"
    fi
}

set_repos_directory() {
    echo ""
    read -p "Enter repos base directory (default $REPOS_BASE_DIR): " new_repos_dir
    if [[ -n "$new_repos_dir" ]]; then
        REPOS_BASE_DIR="$new_repos_dir"
        echo "✅ Repos directory set to $REPOS_BASE_DIR"
    else
        echo "Repos directory remains $REPOS_BASE_DIR"
    fi
}

view_current_config() {
    echo ""
    echo "=== Current Configuration ==="
    echo "User: $REAL_USER"
    echo "Webhook Directory: $WEBHOOK_DIR"
    echo "Repos Base Directory: $REPOS_BASE_DIR"
    echo "Service Name: $SERVICE_NAME"
    
    if [[ -f "$WEBHOOK_DIR/webhook-multi-repo.js" ]]; then
        current_port=$(grep "PORT = " "$WEBHOOK_DIR/webhook-multi-repo.js" | cut -d' ' ' -f3)
        echo "Current Webhook Port: ${current_port:-9001}"
    fi
    
    if systemctl is-active --quiet $SERVICE_NAME 2>/dev/null; then
        echo "Service Status: ✅ Running"
    else
        echo "Service Status: ❌ Stopped"
    fi
}

return_to_main_menu() {
    echo ""
    echo "Returning to main menu..."
    sleep 1
    # Restart the main menu
    ./install.sh
}
