# GitHub Pages Configuration

## 🌐 Enabling GitHub Pages

### Automatic Deployment

Your `docs-site/` directory will automatically deploy to GitHub Pages when you push to the `master` branch.

### Setup Instructions

1. **Enable GitHub Pages:**
   - Go to your repository → Settings → Pages
   - Source: Deploy from a branch
   - Branch: `master`
   - Folder: `/docs-site`
   - Save

2. **Wait for deployment:**
   - GitHub will build and deploy your site
   - Takes 1-2 minutes initially
   - URL: `https://jrh89.github.io/cicd/`

### Custom Domain (Optional)

```bash
# Add custom CNAME file
echo "your-domain.com" > docs-site/CNAME
```

### Site Structure

```
docs-site/
├── index.html          # Landing page
├── quick-start.md       # Quick start guide
├── webhook-setup.md     # Webhook configuration
├── troubleshooting.md     # Troubleshooting guide
└── README.md           # Documentation overview
```

### Local Testing

```bash
# Serve locally for testing
cd docs-site
python3 -m http.server 8000
# Or
npx serve docs-site
```

### Features

- ✅ **Responsive design** - Works on mobile and desktop
- ✅ **Modern styling** - Clean, professional appearance
- ✅ **Easy navigation** - Quick access to all documentation
- ✅ **GitHub Pages** - Free hosting, automatic deployment
- ✅ **Fast loading** - Optimized HTML and CSS

### Benefits

- 🌐 **Public documentation** - Anyone can access your guides
- 📱 **Mobile friendly** - Works on all devices
- 🚀 **Professional appearance** - Clean, modern design
- 🔄 **Auto-updates** - Changes deploy with git push

Your CI/CD system now has professional documentation! 🎉
