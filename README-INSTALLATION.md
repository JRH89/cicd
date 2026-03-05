# CI/CD Deployment System - Installation Guide

## Quick Start

### Option 1: Webhook Deployment (Original System)
```bash
sudo ./install.sh
# Choose option 1
```

### Option 2: Local Deployment Only (New)
```bash
sudo ./install.sh
# Choose option 2
```

### Option 3: Both Systems (Webhook + Local)
```bash
sudo ./install.sh
# Choose option 3
```

## Installation Methods

### Webhook Deployment
- **Purpose**: Deploy via GitHub/Gitea webhook pushes
- **Components**: Webhook server + repository setup scripts
- **Usage**: Original workflow with remote repositories

### Local Deployment Only
- **Purpose**: Deploy directly from local machine without pushing
- **Components**: Local webhook server + CLI deployment tool
- **Usage**: One-click local deployments

### Both Systems
- **Purpose**: Maximum flexibility for all workflows
- **Components**: Webhook server + local webhook server + CLI tools
- **Usage**: Choose deployment method per project

## Post-Installation

### Webhook Deployment
```bash
# Set webhook in Gitea: http://localhost:9001/deploy
# Use setup-repo.sh for each repository
```

### Local Deployment
```bash
# Deploy current directory
./deploy-local.sh

# Deploy specific repository
./deploy-local.sh my-repo

# Check local webhook status
systemctl status webhook-local
```

## Cross-Platform Support

✅ **Arch Linux** - pacman package manager
✅ **Ubuntu/Debian** - apt package manager  
✅ **CentOS/RHEL** - yum package manager
✅ **Fedora** - dnf package manager

## Troubleshooting

### Local Deployment Issues
```bash
# Check if local webhook server is running
systemctl status webhook-local

# View local deployment logs
journalctl -u webhook-local -f

# Test local deployment manually
curl -X POST http://localhost:9002/local-deploy \
  -H "Content-Type: application/json" \
  -d '{"repository":{"name":"your-repo"}}'
```

### Service Management
```bash
# Restart local webhook server
sudo systemctl restart webhook-local

# Stop local webhook server
sudo systemctl stop webhook-local

# Enable/disable on boot
sudo systemctl enable webhook-local
sudo systemctl disable webhook-local
```

## Configuration

### Environment Variables
- `LOCAL_WEBHOOK_PORT`: Local webhook server port (default: 9002)
- `REPOS_BASE_DIR`: Base directory for repositories

### Ports
- **Webhook Server**: 9001 (default)
- **Local Webhook Server**: 9002 (default)

### File Locations
- **Main Installer**: `./install.sh`
- **Local Setup**: `./setup-local-deployment.sh`
- **Local CLI**: `~/deploy-local.sh`
- **Local Server**: `~/CI-CD/local-webhook-server/`
