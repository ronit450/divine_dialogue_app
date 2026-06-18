// FCM push notification service.
// NOT wired into the app yet — follow NOTIFICATIONS.md to activate.
//
// Activation checklist (do NOT touch until ready):
//   1. Run `flutter pub get` after adding firebase_messaging to pubspec.yaml
//   2. Follow NOTIFICATIONS.md iOS & Android native setup steps
//   3. Add the three FcmService calls to main.dart (marked in NOTIFICATIONS.md)
//   4. Deploy the Cloud Function in functions/

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_service.dart';

// Top-level handler — runs in a background isolate when app is terminated.
// Must be top-level (not a method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // FCM delivers the notification to the system tray automatically.
  // Nothing extra needed here unless you want to handle data-only messages.
}

class FcmService {
  FcmService._();
  static final instance = FcmService._();

  final _fcm = FirebaseMessaging.instance;

  /// Call once from main.dart AFTER Firebase.initializeApp() and AFTER
  /// NotificationService.init() has been called.
  Future<void> init() async {
    // Register background handler before anything else.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission (required on iOS and Android 13+).
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Save initial token so the Cloud Function can reach this device.
    final token = await _fcm.getToken();
    if (token != null) await _saveToken(token);

    // Keep token fresh — Firebase rotates it occasionally.
    _fcm.onTokenRefresh.listen(_saveToken);

    // Show a local heads-up notification when FCM message arrives in foreground
    // (system tray is suppressed while app is open by default).
    FirebaseMessaging.onMessage.listen(_handleForeground);
  }

  Future<void> _saveToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'fcmToken': token});
    } catch (_) {
      // Silently ignore — token will be saved on next successful write.
    }
  }

  Future<void> _handleForeground(RemoteMessage message) async {
    final title = message.notification?.title;
    final body = message.notification?.body;
    if (title == null && body == null) return;
    await NotificationService.instance.showImmediate(
      title: title ?? 'Divine Dialogue',
      body: body ?? '',
    );
  }

  /// Call after sign-in to link the current token to the new user account.
  Future<void> onSignIn() async {
    final token = await _fcm.getToken();
    if (token != null) await _saveToken(token);
  }

  /// Call before sign-out to unlink the token so the signed-out user no longer
  /// receives notifications on this device.
  Future<void> onSignOut() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'fcmToken': FieldValue.delete()});
      await _fcm.deleteToken();
    } catch (_) {}
  }
}
