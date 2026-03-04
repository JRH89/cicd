# Troubleshooting Guide

## 🔧 Common Issues and Solutions

This guide covers the most common problems you might encounter with the CI/CD system and how to fix them.

---

## 🚨 Installation Issues

### Issue: "No such file or directory" when installing
**Symptoms:**
```
cp: cannot stat '/home/user/webhook-multi-repo.js': No such file or directory
```

**Causes:**
- Script downloaded via curl but files aren't in same directory
- Network issues downloading from GitHub

**Solutions:**
1. **Check internet connection:**
   ```bash
   curl -I https://github.com/jrh89/cicd/raw/master/webhook-server/webhook-multi-repo.js
   ```

2. **Download manually:**
   ```bash
   mkdir -p ~/CI-CD/webhook-server
   cd ~/CI-CD/webhook-server
   curl -O https://github.com/jrh89/cicd/raw/master/webhook-server/webhook-multi-repo.js
   curl -O https://github.com/jrh89/cicd/raw/master/webhook-server/webhook-multi-repo.service
   ```

3. **Re-run install script:**
   ```bash
   sudo /home/jrh89/Work/cicd/webhook-server/install-server.sh
   ```

---

### Issue: "Node.js not found" or "No such file or directory"
**Symptoms:**
```
Failed to locate executable /usr/bin/node: No such file or directory
```

**Causes:**
- Node.js not installed
- Node.js installed in different location

**Solutions:**
1. **Check if Node.js exists:**
   ```bash
   which node
   node --version
   ```

2. **Install Node.js manually:**
   ```bash
   # Ubuntu/Debian
   curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
   sudo apt-get install -y nodejs
   
   # CentOS/RHEL
   curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
   sudo yum install -y nodejs
   ```

3. **Update service file manually:**
   ```bash
   # Find correct Node.js path
   which node
   
   # Update service file
   sudo sed -i "s|/usr/bin/node|$(which node)|g" /etc/systemd/system/webhook-multi-repo.service
   sudo systemctl daemon-reload
   sudo systemctl restart webhook-multi-repo
   ```

---

### Issue: Service fails to start
**Symptoms:**
```
❌ Failed to start webhook server
```

**Solutions:**
1. **Check service status:**
   ```bash
   sudo systemctl status webhook-multi-repo
   ```

2. **Check detailed logs:**
   ```bash
   sudo journalctl -u webhook-multi-repo -n 50
   ```

3. **Check file permissions:**
   ```bash
   ls -la ~/CI-CD/webhook-server/
   # Should show:
   # -rwxr-xr-x 1 user user ... webhook-multi-repo.js
   # -rw-r--r-- 1 user user ... webhook-multi-repo.service
   ```

4. **Fix permissions if needed:**
   ```bash
   sudo chown -R $USER:$USER ~/CI-CD/webhook-server/
   chmod +x ~/CI-CD/webhook-server/webhook-multi-repo.js
   ```

---

## 🔗 Webhook Issues

### Issue: Webhook not triggering deployment
**Symptoms:**
- Push to repository but no deployment happens
- Webhook test succeeds but no deployment

**Solutions:**
1. **Check webhook server is running:**
   ```bash
   sudo systemctl status webhook-multi-repo
   ```

2. **Check webhook logs:**
   ```bash
   sudo journalctl -u webhook-multi-repo -f
   ```

3. **Test webhook manually:**
   ```bash
   curl -X POST http://localhost:9001/deploy \
     -H "Content-Type: application/json" \
     -d '{"ref":"refs/heads/main","repository":{"name":"test-repo"}}'
   ```

4. **Check webhook URL accessibility:**
   ```bash
   # From another machine
   curl http://YOUR_SERVER_IP:9001/deploy
   # Should return: {"error":"Not found"}
   ```

---

### Issue: "Git pull failed" in deployment
**Symptoms:**
```
❌ Deployment failed for repo-name: fatal: could not read Username
```

**Causes:**
- SSH keys not configured
- Wrong Git remote URL
- Authentication issues

**Solutions:**
1. **Check SSH connection:**
   ```bash
   cd /path/to/your/repo
   ssh -T git@github.com    # or git@your-gitea-server.com
   ```

2. **Check remote URL:**
   ```bash
   git remote -v
   # Should show SSH URLs like: git@github.com:user/repo.git
   ```

3. **Fix remote URL if needed:**
   ```bash
   git remote set-url origin git@github.com:user/repo.git
   ```

4. **Set up SSH keys:**
   ```bash
   # Generate key
   ssh-keygen -t ed25519 -C "your-email@example.com"
   
   # Add to GitHub/Gitea
   cat ~/.ssh/id_ed25519.pub
   ```

---

### Issue: "Repository not found or no deploy.sh"
**Symptoms:**
```
❌ Repository repo-name not found or no deploy.sh at /path/to/repo
```

**Causes:**
- Wrong repos base directory
- Deploy script not created
- Wrong repository name

**Solutions:**
1. **Check repos base directory:**
   ```bash
   # Check what REPOS_BASE_DIR is set to
   systemctl show webhook-multi-repo -p Environment | grep REPOS_BASE_DIR
   ```

2. **Find your repository:**
   ```bash
   find /home -name "your-repo-name" -type d 2>/dev/null
   ```

3. **Create deploy script if missing:**
   ```bash
   cd /path/to/your/repo
   curl -sSL https://github.com/jrh89/cicd/raw/master/scripts/setup-repo.sh | bash
   ```

4. **Update REPOS_BASE_DIR if needed:**
   ```bash
   # Edit service file
   sudo nano /etc/systemd/system/webhook-multi-repo.service
   # Change: Environment=REPOS_BASE_DIR=/correct/path
   sudo systemctl daemon-reload
   sudo systemctl restart webhook-multi-repo
   ```

---

## 🐳 Docker Issues

### Issue: Docker build fails
**Symptoms:**
```
docker compose build --no-cache fails
```

**Solutions:**
1. **Check Docker is running:**
   ```bash
   sudo systemctl status docker
   ```

2. **Check Docker permissions:**
   ```bash
   sudo usermod -aG docker $USER
   # Logout and login again
   ```

3. **Check Docker Compose file:**
   ```bash
   cd /path/to/your/repo
   docker compose config
   ```

4. **Build manually to see errors:**
   ```bash
   cd /path/to/your/repo
   docker compose build --no-cache
   ```

---

### Issue: "Permission denied" with Docker
**Symptoms:**
```
permission denied while trying to connect to the Docker daemon socket
```

**Solutions:**
1. **Add user to docker group:**
   ```bash
   sudo usermod -aG docker $USER
   newgrp docker
   ```

2. **Or run with sudo in deploy script:**
   ```bash
   # In deploy.sh, change:
   docker compose up -d --build --force-recreate
   # To:
   sudo docker compose up -d --build --force-recreate
   ```

---

## 📁 File and Permission Issues

### Issue: "Permission denied" accessing files
**Symptoms:**
```
Permission denied: /home/user/CI-CD/webhook-server/
```

**Solutions:**
1. **Check ownership:**
   ```bash
   ls -la ~/CI-CD/
   ```

2. **Fix ownership:**
   ```bash
   sudo chown -R $USER:$USER ~/CI-CD/
   ```

3. **Fix permissions:**
   ```bash
   chmod 755 ~/CI-CD/webhook-server/
   chmod +x ~/CI-CD/webhook-server/webhook-multi-repo.js
   ```

---

### Issue: Deploy script not executable
**Symptoms:**
```
./deploy.sh: Permission denied
```

**Solutions:**
1. **Make executable:**
   ```bash
   chmod +x deploy.sh
   ```

2. **Check if it's actually a script:**
   ```bash
   file deploy.sh
   head -1 deploy.sh
   ```

---

## 🔍 Debugging Tools

### Check System Status
```bash
# Webhook server status
sudo systemctl status webhook-multi-repo

# Recent webhook logs
sudo journalctl -u webhook-multi-repo -n 50

# Follow logs in real-time
sudo journalctl -u webhook-multi-repo -f

# Check port is listening
sudo netstat -tlnp | grep 9001
```

### Test Webhook Manually
```bash
# Test with correct payload
curl -X POST http://localhost:9001/deploy \
  -H "Content-Type: application/json" \
  -d '{
    "ref": "refs/heads/main",
    "repository": {
      "name": "your-repo-name"
    }
  }'
```

### Check Repository Setup
```bash
# Check if deploy script exists
ls -la /path/to/repo/deploy.sh

# Check git remote
cd /path/to/repo && git remote -v

# Test git pull
cd /path/to/repo && git pull origin main
```

### Check Docker Setup
```bash
# Check Docker status
sudo systemctl status docker

# Test Docker access
docker ps

# Check compose file
cd /path/to/repo && docker compose config
```

---

## 🆘 Getting Help

### Collect Debug Information
```bash
# System info
uname -a
cat /etc/os-release

# Node.js info
which node
node --version
npm --version

# Docker info
docker --version
docker compose version

# Service status
sudo systemctl status webhook-multi-repo
sudo journalctl -u webhook-multi-repo -n 20

# Network info
hostname -I
sudo netstat -tlnp | grep 9001
```

### Common Log Locations
- **Webhook logs**: `sudo journalctl -u webhook-multi-repo -f`
- **Deployment logs**: `~/CI-CD/webhook-server/webhook-multi-repo.log`
- **System logs**: `/var/log/syslog` or `/var/log/messages`

### When to Ask for Help
If you've tried the solutions above and still have issues, provide:
1. **Error messages** (full output)
2. **System info** (OS version, Node.js version)
3. **Service status** (webhook service logs)
4. **What you've tried** (steps taken so far)

---

## ✅ Prevention Tips

1. **Regular updates**: Keep Node.js and Docker updated
2. **Monitor logs**: Check webhook logs weekly
3. **Backup configs**: Save working deploy scripts
4. **Test changes**: Test in development first
5. **Document setup**: Keep notes on your specific configuration

This should resolve most common issues! 🎯
