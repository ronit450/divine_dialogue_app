import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../data/divine_api.dart';
import 'chat_provider.dart';
import 'history_provider.dart';
import 'reading_plan_provider.dart';
import 'religion_provider.dart';
import 'user_provider.dart';
import 'saved_verses_provider.dart';

class AuthState {
  const AuthState({this.uid, this.isGuest = false, this.email});
  final String? uid;
  final bool isGuest;
  final String? email;
  bool get isSignedIn => uid != null || isGuest;
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);

AuthState _stateFromCurrentUser() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const AuthState();
  return AuthState(uid: user.uid, email: user.email, isGuest: user.isAnonymous);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(_stateFromCurrentUser());

  final Ref _ref;

  Future<void> signUpWithEmail(String email, String password) async {
    final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await result.user?.sendEmailVerification();
    // uid intentionally not set — user must verify email first
  }

  Future<void> _afterSignIn(User user) async {
    await _ref.read(userProvider.notifier).loadUser(user.uid);
    final loadedUser = _ref.read(userProvider).user;
    final religionNotifier = _ref.read(religionProvider.notifier);
    if (loadedUser != null && loadedUser.firstName.isNotEmpty) {
      // Existing account — restore religion/texts from Firestore profile and skip onboarding
      final religions = _ref.read(religionProvider).religions;
      final religion = religions.where((r) => r.id == loadedUser.religionId).firstOrNull;
      if (religion != null) {
        final texts = religion.texts
            .where((t) => loadedUser.selectedTextIds.contains(t.id))
            .toList();
        religionNotifier.setReligionAndTexts(religion, texts.isNotEmpty ? texts : religion.texts.take(1).toList());
      }
      await religionNotifier.completeSignIn();
      await religionNotifier.completeOnboarding();
    } else {
      // New account — go through onboarding flow
      await religionNotifier.completeSignIn();
    }
    unawaited(_ref.read(savedVersesProvider.notifier).reload());
    unawaited(_ref.read(readingPlanProvider.notifier).reload());
    unawaited(_ref.read(historyProvider.notifier).load());
  }

  Future<void> signInWithEmail(String email, String password) async {
    final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = result.user;
    if (user == null) throw Exception('Sign-in failed');
    if (!user.emailVerified) {
      await FirebaseAuth.instance.signOut();
      throw Exception('Please verify your email before signing in. Check your inbox.');
    }
    state = AuthState(uid: user.uid, email: user.email);
    await _afterSignIn(user);
  }

  /// Reloads the Firebase user and returns true if email is now verified.
  Future<bool> checkEmailVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    await user.reload();
    final refreshed = FirebaseAuth.instance.currentUser;
    if (refreshed?.emailVerified == true) {
      state = AuthState(uid: refreshed!.uid, email: refreshed.email);
      await _afterSignIn(refreshed);
      return true;
    }
    return false;
  }

  Future<void> resendVerificationEmail() async {
    await FirebaseAuth.instance.currentUser?.sendEmailVerification();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
  }

  Future<bool> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) throw Exception('Sign-in cancelled');
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await FirebaseAuth.instance.signInWithCredential(credential);
    final isNewUser = result.additionalUserInfo?.isNewUser ?? false;
    state = AuthState(uid: result.user?.uid, email: result.user?.email);
    if (result.user != null) {
      await _afterSignIn(result.user!);
    }
    return isNewUser;
  }

  Future<void> signInAsGuest() async {
    final result = await FirebaseAuth.instance.signInAnonymously();
    state = AuthState(uid: result.user?.uid, isGuest: true);
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) throw Exception('Not signed in');
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<void> signOut() async {
    _ref.read(chatProvider.notifier).clearSession();
    _ref.read(historyProvider.notifier).clearState();
    _ref.read(readingPlanProvider.notifier).clear();
    _ref.read(userProvider.notifier).clear();
    _ref.read(savedVersesProvider.notifier).clear();
    DivineApi.instance.clearCache();
    await _ref.read(religionProvider.notifier).clearAuthState();
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    state = const AuthState();
  }
}
