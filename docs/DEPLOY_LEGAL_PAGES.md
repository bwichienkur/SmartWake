# Deploy Legal Pages (GitHub Pages)

SmartWake requires live Privacy Policy and Support URLs for App Store / Play Store submission.

## Option A: GitHub Pages (free)

1. Push this repo to GitHub (e.g. `yourusername/smart_wake`).
2. Go to **Repository Settings → Pages**.
3. Source: **Deploy from branch** → `main` → folder **`/docs`**.
4. After deploy, your URLs will be:
   - `https://YOUR_USERNAME.github.io/smart_wake/privacy.html`
   - `https://YOUR_USERNAME.github.io/smart_wake/terms.html`
   - `https://YOUR_USERNAME.github.io/smart_wake/support.html`
5. Update `lib/core/constants/app_constants.dart` with those URLs.

## Option B: Custom domain (smartwake.app)

1. Host the files in `docs/` on any static host (Netlify, Vercel, S3, etc.).
2. Point DNS for `smartwake.app` to your host.
3. Map `/privacy` → `privacy.html` (or use the `.html` URLs in the app).

## Files included

| File | Purpose |
|------|---------|
| `docs/index.html` | Landing page with links |
| `docs/privacy.html` | Privacy Policy (required by Apple) |
| `docs/terms.html` | Terms of Service |
| `docs/support.html` | Support / FAQ |

Replace `support@smartwake.app` with your real support email before launch.
