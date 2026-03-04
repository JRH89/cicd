# Documentation

Complete documentation for the CI/CD Deployment System.

## 📚 Quick Links

- **[Quick Start Guide](quick-start.md)** - Get running in 5 minutes
- **[Webhook Setup Guide](webhook-setup.md)** - Configure Gitea/GitHub webhooks
- **[Troubleshooting Guide](troubleshooting.md)** - Fix common issues

## 🚀 Quick Start

New to the system? Start with the [Quick Start Guide](quick-start.md) to get up and running immediately.

## 🔗 Webhook Configuration

Need to set up webhooks? The [Webhook Setup Guide](webhook-setup.md) covers:
- Gitea webhook configuration
- GitHub webhook configuration  
- SSH key setup
- Branch configuration
- Testing procedures

## 🔧 Troubleshooting

Having problems? The [Troubleshooting Guide](troubleshooting.md) includes:
- Installation issues
- Webhook problems
- Docker issues
- Permission problems
- Debugging tools

## 📋 System Overview

### What It Does
- **Multi-repository support**: Deploy any number of repositories
- **Zero downtime**: Docker-based deployments with no service interruption
- **Automatic**: Triggers on git pushes to main/master branches
- **Universal**: Works with any user, any directory structure

### Architecture
```
Git Push → Gitea/GitHub → Webhook Server → Deploy Script → Docker
```

### Components
- **Webhook Server**: Node.js app listening on port 9001
- **Deploy Scripts**: Customizable per-repository deployment logic
- **Systemd Service**: Manages webhook server as a system service
- **Docker**: Container-based deployments

## 🛠️ Installation Requirements

### Server Requirements
- Linux (Ubuntu/Debian/CentOS/Fedora)
- Docker and Docker Compose
- Git (with SSH keys configured)
- Internet connection for downloads

### What Gets Installed
- Node.js (if not present)
- Webhook server in `~/CI-CD/webhook-server/`
- Systemd service `webhook-multi-repo`
- Log files in `~/CI-CD/webhook-server/webhook-multi-repo.log`

## 📁 Directory Structure

```
~/CI-CD/webhook-server/
├── webhook-multi-repo.js    # Main webhook server
├── webhook-multi-repo.service # Systemd service file
└── webhook-multi-repo.log   # Log file

/path/to/your/repo/
└── deploy.sh                 # Deployment script (auto-generated)
```

## 🔄 Workflow

1. **Developer pushes** code to repository
2. **Git provider sends** webhook to your server
3. **Webhook server receives** and validates the request
4. **Deploy script runs** in the repository directory
5. **Docker builds and deploys** the new version
6. **Logs are written** for monitoring and debugging

## 🎯 Features

### Universal Installation
- Works for any username
- Configurable repository base directory
- No hardcoded paths or values

### Smart Project Detection
- Automatically detects project type:
  - Docker projects (docker-compose.yml)
  - Node.js projects (package.json)
  - Static sites (index.html)
- Generates appropriate deploy script

### Clean Builds
- Forces Docker rebuild without cache
- Pulls latest git changes before building
- Zero-downtime deployments

### Robust Error Handling
- Continues deployment even if git pull fails
- Clear error messages and logging
- Automatic service restart on failure

## 🔐 Security Considerations

### Webhook Security
- Consider adding webhook secrets for production
- Use HTTPS URLs if available
- Restrict webhook events to push only

### System Security
- Service runs as non-root user
- Files owned by the correct user
- Minimal permissions required

## 📊 Monitoring

### Log Locations
- **Webhook logs**: `~/CI-CD/webhook-server/webhook-multi-repo.log`
- **System logs**: `sudo journalctl -u webhook-multi-repo -f`

### Health Checks
```bash
# Check service status
sudo systemctl status webhook-multi-repo

# Check recent activity
sudo journalctl -u webhook-multi-repo -n 20

# Monitor in real-time
sudo journalctl -u webhook-multi-repo -f
```

## 🚀 Advanced Usage

### Custom Deploy Scripts
Edit the `deploy.sh` in your repository to customize:
- Build commands
- Environment variables
- Health checks
- Rollback procedures

### Environment Variables
Set these in your deploy script:
- `FORCE_CLEAN_BUILD=true` - Force rebuild without cache
- Custom environment variables for your application

### Multiple Environments
Create different webhook endpoints:
- `http://server:9001/deploy` - Production
- `http://server:9002/deploy` - Staging
- Configure different webhooks for each environment

## 🤝 Contributing

Found an issue or want to improve the system?

1. **Test thoroughly** - Make sure changes work across different setups
2. **Document updates** - Update relevant documentation
3. **Submit pull request** - Include clear description of changes

## 📞 Support

Need help?
1. **Check troubleshooting guide** - Most issues are covered there
2. **Review logs** - Check webhook and system logs
3. **Test manually** - Use curl to test webhook directly
4. **Provide details** - Include error messages and system info when asking for help

---

**Happy deploying! 🚀**
