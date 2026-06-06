import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../data/divine_api.dart';
import 'chat_provider.dart';
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

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState());

  final Ref _ref;

  Future<void> signUpWithEmail(String email, String password) async {
    final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await result.user?.sendEmailVerification();
    // uid intentionally not set — user must verify email first
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
    unawaited(_ref.read(userProvider.notifier).loadUser(user.uid));
  }

  /// Reloads the Firebase user and returns true if email is now verified.
  Future<bool> checkEmailVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    await user.reload();
    final refreshed = FirebaseAuth.instance.currentUser;
    if (refreshed?.emailVerified == true) {
      state = AuthState(uid: refreshed!.uid, email: refreshed.email);
      unawaited(_ref.read(userProvider.notifier).loadUser(refreshed.uid));
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

  Future<void> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) throw Exception('Sign-in cancelled');
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await FirebaseAuth.instance.signInWithCredential(credential);
    state = AuthState(uid: result.user?.uid, email: result.user?.email);
    if (result.user?.uid != null) {
      unawaited(_ref.read(userProvider.notifier).loadUser(result.user!.uid));
    }
  }

  Future<void> signInAsGuest() async {
    final result = await FirebaseAuth.instance.signInAnonymously();
    state = AuthState(uid: result.user?.uid, isGuest: true);
  }

  Future<void> signOut() async {
    _ref.read(chatProvider.notifier).clearSession();
    _ref.read(userProvider.notifier).clear();
    _ref.read(savedVersesProvider.notifier).clear();
    DivineApi.instance.clearCache();
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    state = const AuthState();
  }
}
