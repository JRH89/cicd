# Webhook Setup Guide

## 🔗 Configuring Webhooks for Gitea and GitHub

This guide walks you through setting up webhooks for both Gitea and GitHub to work with your CI/CD system.

---

## 🐧 Gitea Webhook Setup

### Prerequisites
- Gitea server access
- SSH keys configured with Gitea
- Repository already created in Gitea

### Step 1: Get Your Webhook URL

Find your server's IP address:
```bash
hostname -I | awk '{print $1}'
```

Your webhook URL will be: `http://YOUR_SERVER_IP:9001/deploy`

### Step 2: Add Webhook in Gitea

1. **Navigate to your repository**
   - Go to your Gitea instance
   - Select your repository

2. **Go to Webhooks settings**
   - Click **Settings** in the repository menu
   - Click **Webhooks** in the left sidebar
   - Click **Add Webhook**

3. **Configure webhook settings**
   ```
   Target URL:       http://YOUR_SERVER_IP:9001/deploy
   HTTP Method:      POST
   Content Type:     application/json
   Secret:           [Leave empty for now]
   Events:           ✅ Push Events
   Branch Filter:    main
   Active:           ✅ Yes
   ```

4. **Important Settings Explained**
   - **Target URL**: Where Gitea sends webhook data
   - **Content Type**: Must be `application/json` for our webhook server
   - **Events**: Only enable "Push Events" (don't need others)
   - **Branch Filter**: Set to your main branch (`main` or `master`)
   - **Active**: Must be checked for webhook to work

5. **Save and Test**
   - Click **Add Webhook**
   - Click the webhook name to view details
   - Click **Test Delivery** to test

### Step 3: Verify Webhook Works

After testing, check your webhook server logs:
```bash
journalctl -u webhook-multi-repo -f
```

You should see logs like:
```
Received webhook from repo: your-repo-name, branch: refs/heads/main
🚀 Triggering deployment for your-repo-name...
✅ Deployment successful for your-repo-name!
```

---

## 🐙 GitHub Webhook Setup

### Prerequisites
- GitHub account
- SSH keys configured with GitHub
- Repository already created on GitHub

### Step 1: Get Your Webhook URL

Same as Gitea - find your server IP:
```bash
hostname -I | awk '{print $1}'
```

Your webhook URL: `http://YOUR_SERVER_IP:9001/deploy`

### Step 2: Add Webhook in GitHub

1. **Navigate to your repository**
   - Go to github.com
   - Select your repository

2. **Go to Webhooks settings**
   - Click **Settings** tab
   - Click **Webhooks** in the left sidebar
   - Click **Add webhook**

3. **Configure webhook settings**
   ```
   Payload URL:      http://YOUR_SERVER_IP:9001/deploy
   Content type:     application/json
   Secret:           [Leave empty for now]
   Which events:     Just the push event
   Active:           ✅ Yes
   ```

4. **Important Settings Explained**
   - **Payload URL**: Where GitHub sends webhook data
   - **Content type**: Must be `application/json`
   - **Which events**: Select "Just the push event"
   - **Active**: Must be checked

5. **Save and Test**
   - Click **Add webhook**
   - GitHub will show you recent deliveries
   - Click on a delivery to see details

### Step 3: Verify Webhook Works

Check your webhook server logs:
```bash
journalctl -u webhook-multi-repo -f
```

---

## 🔐 SSH Setup (Required for Both)

### For Gitea:

1. **Generate SSH key** (if you don't have one):
   ```bash
   ssh-keygen -t ed25519 -C "your-email@example.com"
   ```

2. **Add SSH key to Gitea**:
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
   - Copy the output
   - Go to Gitea → Settings → SSH/GPG Keys
   - Click "Add Key"
   - Paste your public key

3. **Test connection**:
   ```bash
   ssh -T git@your-gitea-server.com
   ```

### For GitHub:

1. **Generate SSH key** (if you don't have one):
   ```bash
   ssh-keygen -t ed25519 -C "your-email@example.com"
   ```

2. **Add SSH key to GitHub**:
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
   - Copy the output
   - Go to GitHub → Settings → SSH and GPG keys
   - Click "New SSH key"
   - Paste your public key

3. **Test connection**:
   ```bash
   ssh -T git@github.com
   ```

---

## 🎯 Branch Configuration

### Determine Your Main Branch

Check your repository's default branch:

```bash
git branch -r
# Look for origin/main or origin/master
```

**Set webhook branch filter accordingly:**
- If you see `origin/main` → Use `main`
- If you see `origin/master` → Use `master`

### Update Deploy Script if Needed

Your `deploy.sh` should match your main branch:

```bash
# In your deploy.sh file
echo "=== PULLING LATEST CHANGES ==="
git pull origin main  # or git pull origin master
```

---

## 🔍 Testing Your Webhook

### Method 1: Push Test
```bash
# Make a small change
echo "test" >> test.txt
git add test.txt
git commit -m "Test webhook"
git push origin main
```

### Method 2: Manual Test
```bash
# Test webhook manually
curl -X POST http://localhost:9001/deploy \
  -H "Content-Type: application/json" \
  -d '{
    "ref": "refs/heads/main",
    "repository": {
      "name": "your-repo-name"
    }
  }'
```

### Method 3: Built-in Test
- **Gitea**: Use "Test Delivery" button in webhook settings
- **GitHub**: View recent deliveries in webhook settings

---

## 🚨 Common Webhook Issues

### Issue: "404 Not Found"
**Cause**: Wrong webhook URL
**Fix**: Verify your server IP and port 9001 is accessible

### Issue: "400 Bad Request" 
**Cause**: Wrong content type
**Fix**: Ensure "application/json" is selected

### Issue: "No deployment triggered"
**Cause**: Wrong branch filter
**Fix**: Match webhook branch filter to your actual main branch

### Issue: "Git pull failed"
**Cause**: SSH keys not configured
**Fix**: Set up SSH keys with your Git provider

---

## ✅ Success Checklist

- [ ] Webhook server running on port 9001
- [ ] Correct webhook URL configured
- [ ] SSH keys set up with Git provider
- [ ] Webhook created with correct settings
- [ ] Branch filter matches your main branch
- [ ] Test push triggers deployment
- [ ] Deployment logs show success

Your webhook is now ready! 🎉
