![CI/CD System](/public/images/cover.png)

A zero-downtime webhook deployment system that works with any repository. One webhook server handles deployments for all your projects.

## Quick Start

### For New Repositories
```bash
# One-command setup
curl -sSL http://github.com/jrh89/cicd/raw/master/scripts/setup-repo.sh | bash

# Set webhook in Gitea: http://localhost:9001/deploy
```

### For Webhook Server
```bash
# Install webhook server (default repos directory: ~/)
curl -sSL http://github.com/jrh89/cicd/raw/master/webhook-server/install-server.sh | sudo bash

# Install with custom repos directory (e.g., ~/Projects)
REPOS_BASE_DIR=~/Projects curl -sSL http://github.com/jrh89/cicd/raw/master/webhook-server/install-server.sh | sudo bash
```

## How It Works

1. **Single Webhook Server**: Handles deployments for all repositories
2. **Dynamic Detection**: Extracts repo name from Gitea webhook payload
3. **Flexible Deployment**: Each repo can have its own deployment logic
4. **Zero Downtime**: Containers rebuild while serving traffic

## Directory Structure

```
CI-CD/
├── README.md                    # This file
├── webhook-server/              # Webhook server components
│   ├── webhook-multi-repo.js    # Main webhook server
│   ├── webhook-multi-repo.service # Systemd service
│   └── install-server.sh        # Installation script
├── deploy-templates/            # Deployment script templates
│   ├── sample-deploy.sh         # Multi-option template
│   ├── docker-deploy.sh         # Docker-specific template
│   ├── nodejs-deploy.sh         # Node.js template
│   └── static-deploy.sh         # Static site template
├── scripts/                     # Utility scripts
│   ├── setup-repo.sh            # One-command repo setup
│   ├── update-webhook.sh        # Update webhook server
│   └── install-deploy.sh        # Install deploy script
└── docs/                        # Additional documentation
    ├── WEBHOOK_GUIDE.md         # Webhook setup guide
    └── TROUBLESHOOTING.md       # Common issues
```

## Installation Options

### Option 1: Full Setup (Recommended)
Install webhook server once, then add any number of repositories:

```bash
# 1. Install webhook server (run once)
curl -sSL http://github.com/jrh89/cicd/raw/master/webhook-server/install-server.sh | sudo bash

# 2. Add repositories (run for each repo)
cd /path/to/your/repo
curl -sSL http://github.com/jrh89/cicd/raw/master/scripts/setup-repo.sh | bash
```

### Option 2: Repository Only
If webhook server is already installed:

```bash
cd /path/to/your/repo
curl -sSL http://github.com/jrh89/cicd/raw/master/scripts/setup-repo.sh | bash
```

## Deployment Templates

Choose the right template for your project:

- **Docker**: `docker-deploy.sh` - For containerized applications
- **Node.js**: `nodejs-deploy.sh` - For Node.js applications
- **Static**: `static-deploy.sh` - For static sites
- **Sample**: `sample-deploy.sh` - Multi-option template

## Webhook Configuration

**URL**: `http://localhost:9001/deploy`
**Method**: POST
**Content-Type**: application/json
**Events**: Push events
**Branches**: main and master

## Features

- ✅ **Zero Downtime**: Containers rebuild while serving traffic
- ✅ **Multi-Repo**: Single server handles unlimited repositories
- ✅ **Branch Filtering**: Deploys only on main/master branches
- ✅ **Auto-Install**: One-command setup for new repositories
- ✅ **Template System**: Pre-built deployment patterns
- ✅ **Error Handling**: Graceful failure with detailed logging
- ✅ **Systemd Service**: Auto-restart on failure

## Troubleshooting

### Webhook Not Responding
```bash
# Check service status
sudo systemctl status webhook-multi-repo

# Check logs
sudo journalctl -u webhook-multi-repo -f

# Restart service
sudo systemctl restart webhook-multi-repo
```

### Deployment Failed
```bash
# Check deployment logs
tail -f /var/log/webhook-deployments.log

# Test manually
curl -X POST http://localhost:9001/deploy \
  -H "Content-Type: application/json" \
  -d '{"ref":"refs/heads/main","repository":{"name":"your-repo"}}'
```

### Permission Issues
```bash
# Fix deploy script permissions
chmod +x deploy.sh

# Check service permissions
sudo systemctl status webhook-multi-repo
```

## Migration from Existing Setup

If you have an existing webhook deployment:

1. **Backup current setup**: Copy existing webhook files
2. **Install new system**: Run installation scripts
3. **Update Gitea webhooks**: Point to new endpoint (same URL)
4. **Test deployment**: Push to main branch
5. **Remove old system**: Clean up old webhook files

## Support

- **Logs**: `/home/$USER/CI-CD/webhook-server/webhook-multi-repo.log`
- **Service**: `webhook-multi-repo`
- **Port**: 9001
- **Base Directory**: `$REPOS_BASE_DIR` (default: `~/`)