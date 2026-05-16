import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthState {
  const AuthState({this.uid, this.isGuest = false});
  final String? uid;
  final bool isGuest;
  bool get isSignedIn => uid != null || isGuest;
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (_) => AuthNotifier(),
);

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) throw Exception('Sign-in cancelled');
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await FirebaseAuth.instance.signInWithCredential(credential);
    state = AuthState(uid: result.user?.uid);
  }

  Future<void> signInAsGuest() async {
    final result = await FirebaseAuth.instance.signInAnonymously();
    state = AuthState(uid: result.user?.uid, isGuest: true);
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    state = const AuthState();
  }
}
