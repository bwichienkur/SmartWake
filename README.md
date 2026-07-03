# SmartWake

**SmartWake** is a production-ready cross-platform mobile alarm clock (Flutter) that estimates sleep stages from wearable and phone sensors, wakes you during light sleep within a Smart Wake Window, and uses wake-up challenges to ensure you're truly awake.

> **Medical disclaimer:** Sleep stages shown are **estimates** based on sensor data. SmartWake is **not** a medical device. Consult a healthcare professional for sleep disorders.

## Features

### Smart Alarm
- Earliest / latest wake time (Smart Wake Window)
- Repeat schedule, alarm sounds, volume, fade-in
- Vibration, snooze, wake-up challenges
- Light-sleep detection during window; fallback to latest wake time
- Never oversleeps past latest wake time

### Alarm Flow
1. Alarm rings and vibrates
2. After initial alert → silence
3. 15-second countdown to start challenge
4. Challenge started → alarm stays silent
5. No action → alarm resumes until challenge completed

### Wake-Up Challenges (13 types)
Barcode Scan, QR Code, Math, Memory Game, Pattern Match, Typing, Shake Phone, Step Counter, Brightness Detection, Face Verification, Smile Detection, Sliding Puzzle, Captcha

### Sleep Tracking
Duration, estimated Deep/Light/REM/Awake, sleep score, consistency, efficiency, wake quality, interactive timeline, analytics (daily/weekly/monthly/yearly), AI insights (Premium), bedtime recommendations (Premium), nap mode, relaxation sounds (Premium)

### Architecture
- **MVVM** with Riverpod
- **Repository Pattern** for data access
- **Dependency Injection** via Riverpod providers
- **Offline-first** with Hive + AES encryption (keys in flutter_secure_storage)
- **Cloud sync** support (optional account)
- Modular `lib/` structure

## Project Structure

```
lib/
├── main.dart / app.dart
├── core/           # Constants, DI, router, theme, utils
├── domain/         # Entities, repository interfaces, use cases
├── data/           # Models, datasources, repository implementations
├── services/       # Alarm engine, sleep, health, subscription, sync
└── presentation/   # Screens, widgets, viewmodels
```

## Getting Started

### Prerequisites
- Flutter 3.2+ ([install guide](https://docs.flutter.dev/get-started/install))
- Xcode (iOS) / Android Studio (Android)
- Firebase project (optional, for auth)
- App Store Connect / Google Play Console (subscriptions)

### Setup

```bash
cd smart_wake
flutter pub get
flutter run
```

### Run Tests

```bash
flutter test
flutter test integration_test/
```

## Monetization

| Feature | Free | Premium ($4.99/mo · $39.99/yr) |
|---------|------|--------------------------------|
| Alarms | Unlimited | Unlimited |
| Smart Wake window | Up to 15 min | Up to 90 min |
| Sleep history | 7 days | Unlimited |
| Challenges | Math, Shake, Barcode | All 13 + sequences |
| AI insights | — | ✓ |
| Cloud backup | — | ✓ |

Upgrade prompts appear **only** when accessing premium features — never during an active alarm.

## Platform Configuration

### iOS
- HealthKit entitlements in Xcode
- In-App Purchase capability
- Background modes: audio, fetch, processing
- See `ios/Runner/Info.plist` for permission strings

### Android
- Health Connect permissions in `AndroidManifest.xml`
- Exact alarm permission (Android 12+)
- Boot receiver for alarm persistence
- Battery optimization exemption recommended

## Health & Wearable Integration

| Platform | Integration |
|----------|-------------|
| iOS | Apple Health / HealthKit, Apple Watch |
| Android | Health Connect, Wear OS |
| Fallback | Phone accelerometer, gyroscope |

When no wearable is connected, SmartWake falls back to phone sensors automatically.

## Background Alarms

Uses `flutter_local_notifications` + `android_alarm_manager_plus` with boot/timezone receivers. Platform limitations apply — users should disable battery optimization for reliable alarms.

## App Store & Play Store Submission

**Start here:** [`docs/APP_STORE_SUBMISSION.md`](docs/APP_STORE_SUBMISSION.md) — complete step-by-step checklist.

Quick reference:
- **Bundle ID:** `com.smartwake.app`
- **IAP products:** `smartwake_premium_monthly`, `smartwake_premium_yearly`
- **Build script (Mac):** `bash scripts/build_app_store.sh`
- **Metadata copy:** `store/app_store/metadata.md`
- **Privacy policy template:** `store/legal/PRIVACY_POLICY.md`

> iOS builds require a **Mac with Xcode**. Windows can develop and test logic; archive/upload happens on macOS.

## License

Proprietary — All rights reserved.
