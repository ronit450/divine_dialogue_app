#!/bin/bash
set -e

FIREBASE_APP_ID="1:981232366558:android:b103be63f413b82cef234f"
TESTER_GROUP="testers"
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

RELEASE_NOTES="${1:-New build}"

echo "==> Building release APK..."
flutter build apk --release

echo "==> Uploading to Firebase App Distribution..."
firebase appdistribution:distribute "$APK_PATH" \
  --app "$FIREBASE_APP_ID" \
  --groups "$TESTER_GROUP" \
  --release-notes "$RELEASE_NOTES"

echo "==> Done! Testers will be notified."
