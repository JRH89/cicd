# GitHub Pages Setup

## 🌐 Configure GitHub Pages

### Step 1: Enable GitHub Pages

1. Go to your repository: https://github.com/JRH89/cicd
2. Click **Settings** tab
3. Scroll down to **Pages** section in the left sidebar
4. Under **Build and deployment**, select **Deploy from a branch**
5. **Branch**: Select `master`
6. **Folder**: Select `docs-site/` (not `/docs`)
7. Click **Save**

### Step 2: Wait for Deployment

GitHub will build and deploy your site. This takes 1-2 minutes initially.

### Step 3: Visit Your Site

Your documentation will be available at:
**https://jrh89.github.io/cicd/**

### Troubleshooting

If it still shows README.md:

1. **Check the source folder** - Make sure you selected `docs-site/` not `/docs`
2. **Wait longer** - Initial deployment can take up to 10 minutes
3. **Check Actions tab** - See if the build completed successfully
4. **Clear cache** - Hard refresh the page (Ctrl+F5)

### Custom Domain (Optional)

If you want to use a custom domain:

1. Add a `CNAME` file to `docs-site/`:
```bash
echo "your-domain.com" > docs-site/CNAME
git add docs-site/CNAME
git commit -m "Add custom domain"
git push origin master
```

2. Configure DNS in your domain provider

### Verify Setup

After deployment, you should see:
- ✅ Professional landing page with Tailwind CSS styling
- ✅ Working navigation between pages
- ✅ Mobile-responsive design
- ✅ All documentation pages accessible

The documentation site will automatically update when you push changes to the `master` branch! 🚀
