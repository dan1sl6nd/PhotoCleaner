# Legal Documents

This directory contains the legal documents for PhotoCleaner hosted on GitHub Pages.

## Files

- `index.md` - Landing page with links to legal documents
- `terms-of-use.md` - Terms of Use
- `privacy-policy.md` - Privacy Policy
- `_config.yml` - Jekyll configuration for GitHub Pages

## Setting Up GitHub Pages

1. **Create a GitHub Repository** (if not already created):
   ```bash
   # Add GitHub as a remote
   git remote add origin https://github.com/YOUR_USERNAME/PhotoCleaner.git
   ```

2. **Commit and Push**:
   ```bash
   git add docs/
   git commit -m "Add Terms of Use and Privacy Policy"
   git push -u origin main
   ```

3. **Enable GitHub Pages**:
   - Go to your repository on GitHub
   - Click "Settings" > "Pages"
   - Under "Source", select "main" branch
   - Under "Folder", select "/docs"
   - Click "Save"

4. **Access Your Pages**:
   - Your legal documents will be available at:
     - `https://YOUR_USERNAME.github.io/PhotoCleaner/`
     - `https://YOUR_USERNAME.github.io/PhotoCleaner/terms-of-use`
     - `https://YOUR_USERNAME.github.io/PhotoCleaner/privacy-policy`

## Updating Legal Documents

After making changes to the legal documents:

1. Update the "Last Updated" date in the document
2. Commit and push changes:
   ```bash
   git add docs/
   git commit -m "Update legal documents"
   git push
   ```

3. GitHub Pages will automatically rebuild (takes 1-2 minutes)

## Linking from Your App

In your PaywallView.swift, update the button actions to open these URLs:

```swift
Button("Terms of Use") {
    if let url = URL(string: "https://YOUR_USERNAME.github.io/PhotoCleaner/terms-of-use") {
        UIApplication.shared.open(url)
    }
}

Button("Privacy Policy") {
    if let url = URL(string: "https://YOUR_USERNAME.github.io/PhotoCleaner/privacy-policy") {
        UIApplication.shared.open(url)
    }
}
```

## Customization

### Change Theme

Edit `_config.yml` to use a different Jekyll theme:
- jekyll-theme-minimal
- jekyll-theme-slate
- jekyll-theme-modernist
- jekyll-theme-cayman (current)

### Add Contact Email

Replace `[Your Contact Email]` in all documents with your actual support email.

## Important Notes

- All legal documents are publicly accessible
- Changes to GitHub Pages may take a few minutes to appear
- Make sure to review and customize these templates with your specific information
- Consider consulting with a lawyer for your specific legal requirements
