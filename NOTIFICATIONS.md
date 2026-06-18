# FCM Push Notifications — Activation Guide

All the code is written and waiting. This document is everything needed to go
from "dormant code" to "live FCM notifications in production."

Hand this file to Claude with: "activate FCM notifications using NOTIFICATIONS.md"

---

## What's already done

| File | Status |
|---|---|
| `lib/services/fcm_service.dart` | Complete — not imported anywhere yet |
| `lib/services/notification_service.dart` | Has `showImmediate()` ready for FCM foreground |
| `functions/src/index.ts` | Cloud Function — not deployed yet |
| `functions/package.json` + `tsconfig.json` | Ready |
| `pubspec.yaml` | `firebase_messaging: ^15.2.5` added |
| `AndroidManifest.xml` | `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` added |

---

## Prerequisites (do these first, manually)

### 1. Upgrade to Firebase Blaze plan
Scheduled Cloud Functions require pay-as-you-go. At this app's scale, cost is
effectively zero (2M free invocations/month; the function runs 720 times/month).

Firebase Console → your project → top-left plan badge → Upgrade to Blaze.

### 2. Enable Cloud Scheduler API
```
gcloud services enable cloudscheduler.googleapis.com
```

### 3. iOS: Add push notification capability in Xcode
- Open `ios/Runner.xcworkspace` in Xcode
- Runner target → Signing & Capabilities → + Capability → Push Notifications
- Also add: Background Modes → Remote notifications

### 4. iOS: Upload APNs key to Firebase
Firebase Console → Project Settings → Cloud Messaging → Apple app configuration
→ Upload APNs Auth Key (generate from Apple Developer → Certificates → Keys).

---

## Flutter activation (3 steps)

### Step 1 — Run pub get
```bash
flutter pub get
```

### Step 2 — Wire FcmService into main.dart

Find this in `lib/main.dart`:
```dart
await NotificationService.instance.init();
```

Add immediately after:
```dart
await NotificationService.instance.init();
FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler); // ADD
await FcmService.instance.init();                                           // ADD
```

Add imports at the top of `main.dart`:
```dart
import 'services/fcm_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
```

### Step 3 — Hook sign-in / sign-out

In auth flow where `completeSignIn()` is called, add:
```dart
await FcmService.instance.onSignIn();
```

In sign-out flow, add before signing out:
```dart
await FcmService.instance.onSignOut();
```

---

## Cloud Function deployment

### Step 1 — Add functions to firebase.json
Replace the current `firebase.json` content with:
```json
{
  "storage": { "rules": "storage.rules" },
  "functions": [
    {
      "source": "functions",
      "codebase": "default",
      "ignore": ["node_modules", ".git"]
    }
  ],
  "flutter": {
    "platforms": {
      "android": {
        "default": {
          "projectId": "divine-dialogue-cb2ac",
          "appId": "1:981232366558:android:b103be63f413b82cef234f",
          "fileOutput": "android/app/google-services.json"
        }
      },
      "dart": {
        "lib/firebase_options.dart": {
          "projectId": "divine-dialogue-cb2ac",
          "configurations": {
            "android": "1:981232366558:android:b103be63f413b82cef234f",
            "ios": "1:981232366558:ios:9b55d714b406c50fef234f",
            "macos": "1:981232366558:ios:9b55d714b406c50fef234f",
            "web": "1:981232366558:web:5514d63bc8e4586def234f",
            "windows": "1:981232366558:web:85e8bca86faf0700ef234f"
          }
        }
      }
    }
  }
}
```

### Step 2 — Install and deploy
```bash
cd functions
npm install
npm run build
cd ..
firebase deploy --only functions
```

### Step 3 — Verify
Firebase Console → Functions → `sendReadingReminders` should appear with a
cron schedule of "every 60 minutes". Logs: Functions → Logs.

---

## Timezone note (IMPORTANT)

The Cloud Function runs in UTC. Reading plans store `reminderHour` as a
LOCAL hour (e.g., 8 for 8 AM PKT). Before going live, verify what Firestore
actually contains:

Firestore Console → a user doc → readingPlans → any plan → check `reminderHour`.

If it stores local hour (e.g., 8 = 8 AM PKT), update `functions/src/index.ts`:
```typescript
// Change this line:
if (plan.reminderHour !== currentHour) continue;

// To this (UTC+5 for PKT):
const localHour = (currentHour + 5) % 24;
if (plan.reminderHour !== localHour) continue;
```

---

## Testing FCM manually

Get your device's token (add temporarily, remove after):
```dart
final token = await FirebaseMessaging.instance.getToken();
debugPrint('FCM token: $token');
```

Send a test message:
Firebase Console → Messaging → Send your first message → paste token → Send.

Test the Cloud Function locally:
```bash
cd functions
firebase emulators:start --only functions
```

---

## Rollback

Remove the 3 lines added to `main.dart` (Step 2). The existing local
notification system (Option A) keeps working independently. No data is lost.
