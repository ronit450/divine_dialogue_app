import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/religion_provider.dart';
import 'providers/download_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    ref.listen<ReligionState>(religionProvider, (prev, next) {
      if (next.selectedReligion != null &&
          prev?.selectedReligion?.id != next.selectedReligion?.id) {
        ref
            .read(downloadProvider.notifier)
            .downloadReligion(next.selectedReligion!.texts);
      }
    });

    return MaterialApp.router(
      title: 'Divine Chat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
