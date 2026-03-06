#!/bin/bash
set -e

echo "=== CI/CD Deployment System Installer ==="

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)"
   exit 1
fi

REAL_USER=${SUDO_USER:-$USER}
if [[ "$REAL_USER" == "root" ]]; then
    REAL_USER=$(logname 2>/dev/null || echo $SUDO_USER)
fi

if [[ -d "/home/$REAL_USER" ]]; then
    WEBHOOK_DIR="/home/$REAL_USER/CI-CD/webhook-server"
    LOCAL_WEBHOOK_DIR="/home/$REAL_USER/CI-CD/local-webhook-server"
    REPOS_BASE_DIR=${REPOS_BASE_DIR:-"/home/$REAL_USER"}
else
    WEBHOOK_DIR="$REAL_USER/CI-CD/webhook-server"
    LOCAL_WEBHOOK_DIR="$REAL_USER/CI-CD/local-webhook-server"
    REPOS_BASE_DIR=${REPOS_BASE_DIR:-"$REAL_USER"}
fi

SERVICE_NAME="webhook-multi-repo"
LOCAL_SERVICE_NAME="webhook-local"

echo "Installing for user: $REAL_USER"
echo "Webhook directory: $WEBHOOK_DIR"
echo "Local webhook directory: $LOCAL_WEBHOOK_DIR"

# Function definitions
install_webhook_system() {
    echo "Installing webhook deployment system..."
    if [[ -f "webhook-server/install-server.sh" ]]; then
        chmod +x webhook-server/install-server.sh
        REPOS_BASE_DIR="$REPOS_BASE_DIR" webhook-server/install-server.sh
    else
        echo "webhook-server/install-server.sh not found"
        echo "Please ensure you are in the correct directory"
        exit 1
    fi
}

setup_local_deployment() {
    echo "=== Setting up Local Deployment System ==="
    echo "Installing for user: $REAL_USER"
    echo "Local webhook directory: $LOCAL_WEBHOOK_DIR"
    echo "Repos base directory: $REPOS_BASE_DIR"

    # Check for Node.js
    if ! command -v node &> /dev/null; then
        echo "❌ Node.js is not installed"
        echo "Installing Node.js..."

        # Detect OS and install Node.js
        if command -v apt &> /dev/null; then
            # Ubuntu/Debian
            curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
            apt-get install -y nodejs
        elif command -v yum &> /dev/null; then
            # CentOS/RHEL
            curl -fsSL https://rpm.nodesource.com/setup_lts.x | bash -
            yum install -y nodejs
        elif command -v dnf &> /dev/null; then
            # Fedora
            dnf install -y nodejs
        elif command -v pacman &> /dev/null; then
            # Arch Linux
            echo "Detected Arch Linux, installing Node.js..."
            # Update package database and install Node.js
            pacman -Sy --noconfirm nodejs npm
        else
            echo "❌ Unsupported OS for automatic Node.js installation"
            echo "Please install Node.js manually and run this script again"
            exit 1
        fi
    fi

    echo "✅ Node.js found: $(node --version)"

    # Create local webhook directory
    echo "📥 Creating local webhook server..."
    mkdir -p "$LOCAL_WEBHOOK_DIR"
    chown -R "$REAL_USER:$REAL_USER" "$LOCAL_WEBHOOK_DIR"

    # Create local webhook server
    cat > "$LOCAL_WEBHOOK_DIR/webhook-local.js" << 'EOF'
const http = require('http');
const { exec } = require('child_process');
const path = require('path');
const fs = require('fs');

const PORT = process.env.PORT || 9002;
const BASE_DIR = process.env.REPOS_BASE_DIR || '/home/' + process.env.USER + '/repos';

console.log('Local webhook server starting on port ' + PORT);
console.log('Base directory: ' + BASE_DIR);

const server = http.createServer((req, res) => {
    if (req.method === 'POST' && req.url === '/deploy') {
        let body = '';

        req.on('data', chunk => {
            body += chunk.toString();
        });

        req.on('end', () => {
            try {
                const data = JSON.parse(body);
                const repoName = data.repository?.name || 'unknown';

                console.log('Deployment triggered for: ' + repoName);

                // Change to repository directory
                const repoPath = path.join(BASE_DIR, repoName);

                if (!fs.existsSync(repoPath)) {
                    console.error('Repository directory not found: ' + repoPath);
                    res.writeHead(404, { 'Content-Type': 'application/json' });
                    res.end(JSON.stringify({ error: 'Repository not found', repoPath }));
                    return;
                }

                process.chdir(repoPath);

                // Run deploy script
                const deployScript = path.join(repoPath, 'deploy.sh');

                if (!fs.existsSync(deployScript)) {
                    console.error('Deploy script not found: ' + deployScript);
                    res.writeHead(404, { 'Content-Type': 'application/json' });
                    res.end(JSON.stringify({ error: 'Deploy script not found', deployScript }));
                    return;
                }

                console.log('Running: ' + deployScript);
                exec('bash ' + deployScript, (error, stdout, stderr) => {
                    if (error) {
                        console.error('Deployment failed: ' + error.message);
                        res.writeHead(500, { 'Content-Type': 'application/json' });
                        res.end(JSON.stringify({ error: error.message, stderr }));
                        return;
                    }

                    console.log('Deployment successful: ' + stdout);
                    res.writeHead(200, { 'Content-Type': 'application/json' });
                    res.end(JSON.stringify({ success: true, output: stdout }));
                });

            } catch (error) {
                console.error('Invalid JSON: ' + error.message);
                res.writeHead(400, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ error: 'Invalid JSON', details: error.message }));
            }
        });
    } else {
        res.writeHead(404, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Not found' }));
    }
});

server.listen(PORT, () => {
    console.log('Server running at http://localhost:' + PORT);
    console.log('Ready to receive deployment requests...');
});
EOF

    # Create systemd service for local webhook
    echo "⚙️ Creating systemd service for local webhook..."
    cat > "/etc/systemd/system/$LOCAL_SERVICE_NAME.service" << EOF
[Unit]
Description=Local CI/CD Deployment Webhook Server
After=network.target

[Service]
Type=simple
User=$REAL_USER
WorkingDirectory=$LOCAL_WEBHOOK_DIR
Environment=PORT=9002
Environment=REPOS_BASE_DIR=$REPOS_BASE_DIR
ExecStart=/usr/bin/node $LOCAL_WEBHOOK_DIR/webhook-local.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    # Install and enable systemd service
    systemctl daemon-reload
    systemctl enable "$LOCAL_SERVICE_NAME"
    systemctl start "$LOCAL_SERVICE_NAME"

    # Wait a moment and check status
    sleep 2
    if systemctl is-active --quiet "$LOCAL_SERVICE_NAME"; then
        echo "✅ Local webhook server started successfully"
    else
        echo "❌ Failed to start local webhook server"
        echo "Check logs: journalctl -u $LOCAL_SERVICE_NAME -n 20"
        exit 1
    fi

    # Create local deployment CLI tool
    echo "🛠️ Creating local deployment CLI tool..."
    cat > "/usr/local/bin/deploy-local" << EOF
#!/bin/bash

# Local CI/CD Deployment Tool
# Usage: deploy-local <repo-name>

if [ \$# -ne 1 ]; then
    echo "Usage: deploy-local <repo-name>"
    echo "Example: deploy-local my-website"
    exit 1
fi

REPO_NAME="\$1"
PORT=9002

echo "Triggering deployment for repository: \$REPO_NAME"

# Send POST request to local webhook server
curl -X POST http://localhost:\$PORT/deploy \\
     -H "Content-Type: application/json" \\
     -d "{\\"repository\\": {\\"name\\": \\"\$REPO_NAME\\"}}" \\
     --silent --show-error

if [ \$? -eq 0 ]; then
    echo "✅ Deployment request sent successfully"
else
    echo "❌ Failed to send deployment request"
    exit 1
fi
EOF

    chmod +x "/usr/local/bin/deploy-local"

    echo "✅ Local deployment system installed successfully!"
    echo ""
    echo "Usage:"
    echo "  deploy-local <repo-name>    # Trigger deployment for a repository"
    echo ""
    echo "Example:"
    echo "  deploy-local my-website"
    echo ""
    echo "The local webhook server is running on port 9002"
}

install_local_system() {
    echo "Installing local deployment system..."
    setup_local_deployment
}

install_both_systems() {
    echo "Installing both webhook and local deployment systems..."
    install_webhook_system
    install_local_system
}

# Interactive choice handling
echo ""
echo "Choose installation method:"
echo "1) Webhook Deployment (GitHub/Gitea)"
echo "2) Local Deployment Only"
echo "3) Both Systems (Webhook + Local)"
echo ""
read -p "Enter choice [1-3]: " choice

# Execute choice
case $choice in
    1) install_webhook_system ;;
    2) install_local_system ;;
    3) install_both_systems ;;
    *) install_webhook_system ;;
esac
