#!/bin/bash
set -e

FIREBASE="$HOME/.nvm/versions/node/v20.20.2/bin/firebase"
FIREBASE_APP_ID="1:981232366558:android:b103be63f413b82cef234f"
TESTERS="farazali20004@gmail.com,ronit@mdstmarket.com"
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

RELEASE_NOTES="${1:-New build}"

# --- Bump build number in pubspec.yaml ---
CURRENT=$(grep "^version:" pubspec.yaml | sed 's/version: //')
VERSION_NAME=$(echo "$CURRENT" | cut -d'+' -f1)
BUILD_NUM=$(echo "$CURRENT" | cut -d'+' -f2)
NEW_BUILD=$((BUILD_NUM + 1))
NEW_VERSION="${VERSION_NAME}+${NEW_BUILD}"

sed -i "s/^version: .*/version: $NEW_VERSION/" pubspec.yaml
echo "==> Version bumped to $NEW_VERSION"

git add pubspec.yaml
git commit -m "chore: bump build to $NEW_VERSION"
git push origin main

# --- Build ---
echo "==> Building release APK ($NEW_VERSION)..."
flutter build apk --release

# --- Distribute ---
echo "==> Uploading to Firebase App Distribution..."
"$FIREBASE" appdistribution:distribute "$APK_PATH" \
  --app "$FIREBASE_APP_ID" \
  --testers "$TESTERS" \
  --release-notes "$RELEASE_NOTES ($NEW_VERSION)"

echo "==> Done! Testers notified of $NEW_VERSION."
