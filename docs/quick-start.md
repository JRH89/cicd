# Quick Start Guide

## 🚀 Get Your CI/CD System Running in 5 Minutes

### Prerequisites
- Linux server (Ubuntu/Debian/CentOS/Fedora/Arch)
- Docker installed
- Git account (Gitea or GitHub)
- SSH keys set up with your Git provider

### Step 1: Install Webhook Server

Run this command on your server:

```bash
curl -sSL https://github.com/jrh89/cicd/raw/master/webhook-server/install-server.sh | sudo bash
```

**What this does:**
- ✅ Installs Node.js if missing
- ✅ Creates `/home/$USER/CI-CD/webhook-server/` directory
- ✅ Downloads and configures webhook server
- ✅ Starts systemd service on port 9001

### Step 2: Verify Installation

Check that the webhook server is running:

```bash
systemctl status webhook-multi-repo
```

You should see:
```
● webhook-multi-repo.service - Multi-Repository Gitea Webhook Deployment Server
   Loaded: loaded (/etc/systemd/system/webhook-multi-repo.service; enabled; vendor preset: enabled)
   Active: active (running) since [timestamp]
```

### Step 3: Get Your Webhook URL

The install script shows your webhook URL, or find it with:

```bash
# Get your server's IP address
hostname -I | awk '{print $1}'

# Your webhook URL will be:
http://YOUR_SERVER_IP:9001/deploy
```

### Step 4: Set Up Your Repository

For each repository you want to deploy:

```bash
cd /path/to/your/repository
curl -sSL https://github.com/jrh89/cicd/raw/master/scripts/setup-repo.sh | bash
```

This creates a `deploy.sh` script customized for your project type.

### Step 5: Configure Webhook (Gitea or GitHub)

**For Gitea:**
1. Go to your repository → Settings → Webhooks
2. Click "Add Webhook"
3. Fill in:
   - **Target URL**: `http://YOUR_SERVER_IP:9001/deploy`
   - **HTTP Method**: POST
   - **Content Type**: application/json
   - **Secret**: Leave empty (or add for security)
   - **Events**: Push events only
   - **Branch Filter**: `main` (or `master` if that's your default branch)
4. Click "Add Webhook"
5. Test it with the "Test Delivery" button

**For GitHub:**
1. Go to your repository → Settings → Webhooks
2. Click "Add webhook"
3. Fill in:
   - **Payload URL**: `http://YOUR_SERVER_IP:9001/deploy`
   - **Content type**: application/json
   - **Secret**: Leave empty (or add for security)
   - **Which events**: Just the `push` event
4. Click "Add webhook"
5. Test by pushing to your repository

### Step 6: Test Your First Deployment

1. Make a change to your code
2. Commit and push:
   ```bash
   git add .
   git commit -m "Test deployment"
   git push origin main
   ```
3. Check the webhook logs:
   ```bash
   journalctl -u webhook-multi-repo -f
   ```

You should see deployment logs indicating success!

### Step 7: Customize Deploy Script (Optional)

Edit the `deploy.sh` in your repository to match your specific needs:

```bash
# For Docker projects (default)
docker compose up -d --build --force-recreate

# For Node.js projects
npm ci --production
npm run build
pm2 restart app

# For static sites
npm run build
rsync -avz --delete dist/ /var/www/site/
```

## 🎯 You're Done!

Your CI/CD system is now:
- ✅ **Running** on port 9001
- ✅ **Listening** for webhook events
- ✅ **Auto-deploying** on pushes
- ✅ **Ready** for multiple repositories

Add more repositories by repeating Step 4-6 for each one!

## Need Help?

- 📖 **Webhook Setup Guide**: See `docs/webhook-setup.md`
- 🔧 **Troubleshooting Guide**: See `docs/troubleshooting.md`
- 🐛 **Common Issues**: Check the troubleshooting guide first
