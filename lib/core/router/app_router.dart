import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/religion_provider.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_intro_screen.dart';
import '../../features/onboarding/onboarding_religion_screen.dart';
import '../../features/onboarding/onboarding_text_screen.dart';
import '../../features/auth/sign_in_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/home/home_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/library/library_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/profile/profile_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // Only watch routing-relevant fields — prevents router rebuild on every card tap
  final (:isLoaded, :signInDone, :onboardingDone) = ref.watch(
    religionProvider.select(
      (s) => (isLoaded: s.isLoaded, signInDone: s.signInDone, onboardingDone: s.onboardingDone),
    ),
  );

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      if (!isLoaded) return null;
      final loc = state.matchedLocation;
      if (loc == '/splash') return null;

      if (!signInDone) {
        const preAuthPaths = ['/onboarding', '/sign-in'];
        final allowed = preAuthPaths.any((p) => loc.startsWith(p));
        if (!allowed) return '/onboarding';
        return null;
      }

      if (!onboardingDone) {
        const onboardingPaths = ['/onboarding/religion', '/onboarding/text'];
        final allowed = onboardingPaths.any((p) => loc.startsWith(p));
        if (!allowed) return '/onboarding/religion';
        return null;
      }

      const preAuthPaths = ['/onboarding', '/sign-in'];
      if (preAuthPaths.any((p) => loc.startsWith(p))) return '/home';

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingIntroScreen(),
      ),
      GoRoute(
        path: '/onboarding/religion',
        builder: (context, state) => const OnboardingReligionScreen(),
      ),
      GoRoute(
        path: '/onboarding/text',
        builder: (context, state) => const OnboardingTextScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      // History navigated to from profile tab — outside shell so it pushes on top
      GoRoute(
        path: '/history',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const HistoryScreen(),
      ),
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootKey,
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                builder: (context, state) => const ChatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                builder: (context, state) => const LibraryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
