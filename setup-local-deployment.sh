#!/bin/bash
set -e

echo "=== Setting up Local Deployment System ==="

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
    LOCAL_WEBHOOK_DIR="/home/$REAL_USER/CI-CD/local-webhook-server"
else
    # Fallback for different home directory structures
    WEBHOOK_DIR="$REAL_USER/CI-CD/webhook-server"
    REPOS_BASE_DIR=${REPOS_BASE_DIR:-"$REAL_USER"}
    LOCAL_WEBHOOK_DIR="$REAL_USER/CI-CD/local-webhook-server"
fi

SERVICE_NAME="webhook-local"
LOCAL_PORT=9002

echo "Installing for user: $REAL_USER"
echo "Local webhook directory: $LOCAL_WEBHOOK_DIR"
echo "Repos base directory: $REPOS_BASE_DIR"

# Check for Node.js with cross-platform support
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
    elif command -v pacman &> /dev/null; then
        # Arch Linux
        echo "Detected Arch Linux, installing Node.js..."
        # Update package database and install Node.js
        pacman -Sy --noconfirm nodejs npm
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

# Create local webhook directory
mkdir -p "$LOCAL_WEBHOOK_DIR"
chown -R "$REAL_USER:$REAL_USER" "$LOCAL_WEBHOOK_DIR"
chmod 755 "$LOCAL_WEBHOOK_DIR"

# Create local webhook server
echo "📥 Creating local webhook server..."
cat > "$LOCAL_WEBHOOK_DIR/webhook-local.js" << 'EOF'
const http = require('http');
const { exec } = require('child_process');
const path = require('path');

const PORT = process.env.LOCAL_WEBHOOK_PORT || 9002;
const BASE_DIR = process.env.REPOS_BASE_DIR || \`/home/\${process.env.USER || require('os').userInfo().username}\`;

const server = http.createServer((req, res) => {
    if (req.method === 'POST' && req.url === '/local-deploy') {
        let body = '';
        
        req.on('data', chunk => {
            body += chunk.toString();
        });
        
        req.on('end', () => {
            try {
                const payload = JSON.parse(body);
                const repoName = payload.repository?.name || 'unknown';
                
                console.log(\`🚀 Local deployment triggered for repo: \${repoName}\`);
                
                // Send response immediately
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ 
                    status: 'local_deployment_started',
                    repository: repoName,
                    type: 'local'
                }));
                
                // Check if repo directory and deploy script exist
                const repoPath = path.join(BASE_DIR, repoName);
                const deployScript = path.join(repoPath, 'deploy.sh');
                
                exec(\`test -d "\${repoPath}" && test -f "\${deployScript}"\`, (error) => {
                    if (error) {
                        console.error(\`❌ Repository \${repoName} not found or no deploy.sh at \${repoPath}\`);
                        return;
                    }
                    
                    console.log(\`🔄 Starting local deployment for \${repoName}...\`);
                    
                    // Run deployment in background
                    exec(\`cd "\${repoPath}" && ./deploy.sh\`, (error, stdout, stderr) => {
                        if (error) {
                            console.error(\`❌ Local deployment failed for \${repoName}:\`, stderr);
                        } else {
                            console.log(\`✅ Local deployment completed for \${repoName}\`);
                        }
                    });
                });
            } catch (error) {
                console.error('❌ Invalid JSON payload:', error.message);
                res.writeHead(400, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ error: 'Invalid JSON payload' }));
            }
        });
    } else {
        res.writeHead(404, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Not found' }));
    }
});

server.listen(PORT, () => {
    console.log(\`🌐 Local webhook server running on port \${PORT}\`);
    console.log(\`📁 Repos base directory: \${BASE_DIR}\`);
    console.log(\`🔗 Local deployment endpoint: http://localhost:\${PORT}/local-deploy\`);
});
EOF

chown "$REAL_USER:$REAL_USER" "$LOCAL_WEBHOOK_DIR"/*.js
chmod +x "$LOCAL_WEBHOOK_DIR"/*.js

# Create systemd service for local webhook
echo "⚙️ Creating systemd service..."
cat > "/etc/systemd/system/$SERVICE_NAME.service" << EOF
[Unit]
Description=Local CI/CD Deployment Webhook Server
After=network.target

[Service]
Type=simple
User=$REAL_USER
WorkingDirectory=$LOCAL_WEBHOOK_DIR
Environment=NODE_ENV=production
Environment=LOCAL_WEBHOOK_PORT=$LOCAL_PORT
Environment=REPOS_BASE_DIR=$REPOS_BASE_DIR
ExecStart=/usr/bin/node $LOCAL_WEBHOOK_DIR/webhook-local.js
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=$SERVICE_NAME

[Install]
WantedBy=multi-user.target
EOF

# Install and enable systemd service
systemctl daemon-reload
systemctl enable $SERVICE_NAME

# Start the local webhook service
systemctl start $SERVICE_NAME

# Wait a moment and check status
sleep 2
if systemctl is-active --quiet $SERVICE_NAME; then
    echo "✅ Local webhook server installed and running successfully!"
    echo ""
    echo "Local Service Details:"
    echo "- Name: $SERVICE_NAME"
    echo "- Port: $LOCAL_PORT"
    echo "- Logs: journalctl -u $SERVICE_NAME -f"
    echo "- Status: systemctl status $SERVICE_NAME"
    echo ""
    echo "Local deployment endpoint: http://localhost:$LOCAL_PORT/local-deploy"
    echo ""
    echo "Next steps:"
    echo "1. Navigate to your repository directory"
    echo "2. Run: ./deploy-local.sh [repo-name]"
    echo "3. Or use the CLI tool for one-click deployments"
else
    echo "❌ Failed to start local webhook server"
    echo "Check logs: journalctl -u $SERVICE_NAME -n 20"
    exit 1
fi

# Create local deployment CLI tool
echo "🛠️ Creating local deployment CLI tool..."
cat > "$REPOS_BASE_DIR/deploy-local.sh" << 'EOF'
#!/bin/bash
set -e

# Configuration
LOCAL_WEBHOOK_PORT=\${LOCAL_WEBHOOK_PORT:-9002}
REPO_NAME=\${1:-\$(basename "\$(pwd)")}

# Help function
show_help() {
    echo "Local Deployment CLI Tool"
    echo ""
    echo "Usage: ./deploy-local.sh [options] [repo-name]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -p, --port     Set webhook port (default: 9002)"
    echo "  -r, --repo     Set repository name"
    echo ""
    echo "Examples:"
    echo "  ./deploy-local.sh                    # Deploy current directory"
    echo "  ./deploy-local.sh my-repo             # Deploy specific repo"
    echo "  ./deploy-local.sh -p 9003 my-repo    # Deploy with custom port"
    echo ""
    echo "Current webhook server: http://localhost:\$LOCAL_WEBHOOK_PORT/local-deploy"
}

# Parse command line arguments
while [[ \$# -gt 0 ]]; do
    case \$1 in
        -h|--help) show_help; exit 0 ;;
        -p|--port) LOCAL_WEBHOOK_PORT="\$2"; shift 2 ;;
        -r|--repo) REPO_NAME="\$2"; shift 2 ;;
        *) break ;;
    esac
    shift
done

# Validate repository name
if [[ "\$REPO_NAME" == "." || "\$REPO_NAME" == ".." || "\$REPO_NAME" == "" ]]; then
    echo "❌ Invalid repository name: \$REPO_NAME"
    echo "Use a valid repository name or navigate to the repository directory"
    exit 1
fi

echo "🚀 Triggering local deployment for: \$REPO_NAME"
echo "🌐 Sending request to: http://localhost:\$LOCAL_WEBHOOK_PORT/local-deploy"

# Send deployment request to local webhook server
response=\$(curl -s -X POST \\
    -H "Content-Type: application/json" \\
    -d "{\"repository\":{\"name\":\"\$REPO_NAME\"}}" \\
    "http://localhost:\$LOCAL_WEBHOOK_PORT/local-deploy" \\
    2>/dev/null || echo "REQUEST_FAILED")

if [[ "\$response" == "REQUEST_FAILED" ]]; then
    echo "❌ Failed to connect to local webhook server"
    echo "Make sure the local webhook server is running:"
    echo "  systemctl status webhook-local"
    echo "  journalctl -u webhook-local -f"
    exit 1
else
    echo "✅ Local deployment triggered successfully!"
    echo "📋 Check deployment logs with: journalctl -u webhook-local -f"
fi
EOF

chmod +x "$REPOS_BASE_DIR/deploy-local.sh"
chown "$REAL_USER:$REAL_USER" "$REPOS_BASE_DIR/deploy-local.sh"

echo ""
echo "✅ Local deployment system setup complete!"
echo ""
echo "Commands created:"
echo "- Local webhook server: $SERVICE_NAME"
echo "- CLI tool: deploy-local.sh"
echo ""
echo "Usage examples:"
echo "  ./deploy-local.sh                    # Deploy current directory"
echo "  ./deploy-local.sh my-repo             # Deploy specific repo"
