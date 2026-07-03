#!/usr/bin/env bash
# Build SmartWake for App Store upload. Run on macOS with Xcode installed.
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Flutter pub get"
flutter pub get

echo "==> Generate app icons"
dart run flutter_launcher_icons

echo "==> Run tests"
flutter test

echo "==> Install iOS pods"
cd ios && pod install && cd ..

echo "==> Build IPA"
flutter build ipa --release

echo ""
echo "Done! Upload build/ios/ipa/*.ipa via Transporter or Xcode Organizer."
echo "See docs/APP_STORE_SUBMISSION.md for App Store Connect steps."
