import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/religion_provider.dart';
import '../../providers/locale_provider.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_intro_screen.dart';
import '../../features/onboarding/onboarding_language_screen.dart';
import '../../features/onboarding/onboarding_religion_screen.dart';
import '../../features/onboarding/onboarding_text_screen.dart';
import '../../features/auth/sign_in_screen.dart';
import '../../features/profile_setup/profile_setup_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/home/home_screen.dart';
import '../../features/library/library_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/developers/developers_screen.dart';
import '../../features/report_issue/report_issue_screen.dart';
import '../../features/reader/reader_screen.dart';
import '../../features/reading_plans/reading_plans_screen.dart';
import '../../features/reading_plans/plan_detail_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // Only watch routing-relevant fields — prevents router rebuild on every card tap
  final (:isLoaded, :signInDone, :onboardingDone) = ref.watch(
    religionProvider.select(
      (s) => (isLoaded: s.isLoaded, signInDone: s.signInDone, onboardingDone: s.onboardingDone),
    ),
  );
  final localeState = ref.watch(localeProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      if (!isLoaded || !localeState.isLoaded) return null;
      final loc = state.matchedLocation;
      if (loc == '/splash') return null;

      if (!signInDone) {
        const preAuthPaths = ['/onboarding', '/sign-in', '/profile-setup'];
        final allowed = preAuthPaths.any((p) => loc.startsWith(p));
        if (!allowed) return '/onboarding';
        return null;
      }

      if (!onboardingDone) {
        const onboardingPaths = [
          '/onboarding/language',
          '/onboarding/religion',
          '/onboarding/text',
          '/profile-setup',
          '/sign-in',
        ];
        final allowed = onboardingPaths.any((p) => loc.startsWith(p));
        if (!allowed) {
          return localeState.languagePicked
              ? '/onboarding/religion'
              : '/onboarding/language';
        }
        return null;
      }

      // Allow text reselection from profile settings even when fully authenticated
      if (loc == '/onboarding/text') return null;
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
        path: '/onboarding/language',
        builder: (context, state) => const OnboardingLanguageScreen(),
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
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/history',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/developers',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const DevelopersScreen(),
      ),
      GoRoute(
        path: '/report-issue',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const ReportIssueScreen(),
      ),
      GoRoute(
        path: '/reading-plans',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const ReadingPlansScreen(),
      ),
      GoRoute(
        path: '/reading-plans/:planId',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => PlanDetailScreen(
          planId: state.pathParameters['planId']!,
        ),
      ),
      GoRoute(
        path: '/read/:textId',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => ReaderScreen(
          textId: state.pathParameters['textId']!,
          initialChapter: state.extra is Map
              ? (state.extra as Map)['chapter'] as int?
              : null,
        ),
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
