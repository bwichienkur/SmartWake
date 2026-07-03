# App Store Submission Guide — SmartWake

Complete this checklist on a **Mac with Xcode 15+** and an **Apple Developer Program** account ($99/year).

> **Bundle ID:** `com.smartwake.app`  
> **Version:** 1.0.0 (build 1)

---

## Phase 1: Apple Developer Account (Day 1)

- [ ] Enroll at [developer.apple.com/programs](https://developer.apple.com/programs/)
- [ ] Create App ID: **Certificates, Identifiers & Profiles → Identifiers → +**
  - Type: App
  - Bundle ID: `com.smartwake.app` (Explicit)
  - Capabilities: **HealthKit**
- [ ] Create app in [App Store Connect](https://appstoreconnect.apple.com):
  - Name: **SmartWake**
  - Primary language: English (U.S.)
  - Bundle ID: `com.smartwake.app`
  - SKU: `smartwake-ios-001`

---

## Phase 2: Legal Pages (Required — host before submission)

Apple requires a **Privacy Policy URL**. Host these pages (GitHub Pages, Notion, or your domain):

| Page | URL (update in `lib/core/constants/app_constants.dart`) |
|------|-----------------------------------------------------------|
| Privacy Policy | `https://smartwake.app/privacy` |
| Terms of Service | `https://smartwake.app/terms` |
| Support | `https://smartwake.app/support` |

Templates are in `store/legal/` and ready-to-host HTML is in `docs/`. See `docs/DEPLOY_LEGAL_PAGES.md`.

---

## Phase 3: In-App Purchases (App Store Connect)

Create a **Subscription Group** named `SmartWake Premium`:

| Product ID | Type | Price | Trial |
|------------|------|-------|-------|
| `smartwake_premium_monthly` | Auto-renewable | $4.99/month | None |
| `smartwake_premium_yearly` | Auto-renewable | $39.99/year | 7 days free |
| `smartwake_premium_lifetime` | Non-consumable | $79.99 once | None |

- [ ] Add subscription localizations (display name + description)
- [ ] Submit subscriptions for review **with** the app binary
- [ ] Test locally with `ios/SmartWake.storekit` in Xcode (**Product → Scheme → Edit Scheme → Run → StoreKit Configuration**)

---

## Phase 4: Xcode Setup (on Mac)

```bash
cd smart_wake
flutter pub get
dart run flutter_launcher_icons
cd ios && pod install && cd ..
open ios/Runner.xcworkspace
```

In Xcode:

1. **Signing & Capabilities** (Runner target):
   - Team: your Apple Developer team
   - Bundle Identifier: `com.smartwake.app`
   - Enable **Automatically manage signing**
   - Add capability: **HealthKit**
2. Set Team ID in `ios/Flutter/Release.xcconfig`:
   ```
   DEVELOPMENT_TEAM = YOUR_TEAM_ID
   ```
3. Replace placeholder app icon if needed:
   - Source: `assets/images/app_icon.png`
   - Run: `dart run flutter_launcher_icons`

---

## Phase 5: Build & Upload

### Option A — Xcode (recommended first time)

```bash
flutter build ipa --release
```

Or in Xcode: **Product → Archive → Distribute App → App Store Connect → Upload**

### Option B — Command line + Transporter

```bash
# From project root on Mac:
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
# Upload the .ipa via Transporter app or altool
```

Update `ios/ExportOptions.plist` with your `teamID` before using Option B.

---

## Phase 6: App Store Connect Metadata

Use `store/app_store/metadata.md` as copy-paste source.

Required assets:

| Asset | Size | Notes |
|-------|------|-------|
| App Icon | 1024×1024 | No alpha channel (generated via launcher_icons) |
| iPhone Screenshots | 6.7" (1290×2796) | Min 3 screenshots |
| iPhone Screenshots | 6.5" (1284×2778) | Optional but recommended |
| iPad Screenshots | 12.9" | If supporting iPad |

### App Information

- **Category:** Health & Fitness (primary), Lifestyle (secondary)
- **Age Rating:** 4+ (no restricted content)
- **Copyright:** © 2026 [Your Company Name]

### App Privacy (Nutrition Labels)

Declare in App Store Connect (matches `ios/Runner/PrivacyInfo.xcprivacy`):

- Health & Fitness data — App Functionality, not linked, not tracking
- Purchase History — App Functionality, linked to user

### Review Notes (paste into App Store Connect)

```
SmartWake is an alarm clock app that estimates sleep stages from Apple Health 
data and phone sensors to wake users during light sleep.

TEST ACCOUNT: Not required — app works in Guest mode without login.

HEALTHKIT: Tap Settings → enable Health Sync on first launch to grant permissions.
To test Smart Wake: create an alarm with a Smart Wake window starting ~2 minutes 
from now.

SUBSCRIPTIONS: Premium unlocks extended Smart Wake window (90 min), all wake-up 
challenges, and AI sleep insights. Use Sandbox Apple ID to test purchases.

MEDICAL DISCLAIMER: Sleep stages are estimates only, shown in-app on Alarms and 
Sleep tabs. SmartWake is not a medical device.

Alarm sounds: bundled assets in app (no external streaming required for review).
```

---

## Phase 7: Export Compliance

`ITSAppUsesNonExemptEncryption = false` is set in `Info.plist`.  
In App Store Connect, answer **No** to encryption questions (uses only standard HTTPS/TLS).

---

## Phase 8: Pre-Submission Checklist

- [ ] Privacy Policy URL live and linked in Settings
- [ ] Terms of Service URL live
- [ ] Support URL or email working
- [ ] Subscriptions created and submitted for review
- [ ] HealthKit usage strings accurate in Info.plist
- [ ] App tested on physical iPhone (alarms, notifications, IAP sandbox)
- [ ] No crash on cold start without network
- [ ] `flutter test` passes
- [ ] Version/build number incremented for resubmissions

---

## Phase 9: Submit for Review

App Store Connect → your app → **+ Version 1.0.0** → attach build → fill metadata → **Submit for Review**.

Typical review: 24–48 hours.

---

## Common Rejection Fixes

| Rejection | Fix |
|-----------|-----|
| Missing privacy policy | Host page, update URL in app_constants.dart |
| HealthKit justification | Ensure disclaimer visible; clarify estimates in review notes |
| IAP not submitted | Submit subscription products with app version |
| Guideline 2.1 — crashes | Test on device; check notification permissions |
| Missing restore purchases | Already in Settings → Restore Purchases |

---

## Google Play (bonus)

See `store/play_store/PLAY_STORE_CHECKLIST.md` for Android submission.

```bash
# Create release keystore (once):
keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Copy android/key.properties.example → key.properties and fill in
flutter build appbundle --release
```

Upload `build/app/outputs/bundle/release/app-release.aab` to Google Play Console.
