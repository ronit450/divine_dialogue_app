import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/religion_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/texts_repository.dart';
import '../../shared/widgets/religion_glyph.dart';

final _dailyVerseProvider = FutureProvider.autoDispose.family<DailyVerse, String>(
  (ref, religionId) => TextsRepository.instance.getDailyVerse(religionId),
);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(religionProvider);
    final religion = state.selectedReligion;
    final accent = religion?.accentColor ?? AppColors.islamGreen;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final surface = isDark ? AppColors.nightSurface : AppColors.boneSurface;
    final line = isDark ? AppColors.nightLine : AppColors.boneLine;

    final now = DateTime.now();
    final dateLabel =
        '${_weekday(now.weekday).toUpperCase()} · ${now.day} ${_month(now.month).toUpperCase()}';

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateLabel,
                              style: GoogleFonts.jetBrainsMono(
                                color: muted, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              religion?.salutation ?? 'Welcome',
                              style: GoogleFonts.cormorantGaramond(
                                color: fg, fontSize: 24, fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => context.go('/profile'),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: religion?.accentSoft ?? AppColors.islamGreenSoft,
                            ),
                            child: Center(
                              child: Text(
                                'A',
                                style: GoogleFonts.cormorantGaramond(
                                  color: accent, fontSize: 16, fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Verse of the day
                  if (religion != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _VerseCard(religionId: religion.id, accent: accent),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Quick ask bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: () => context.go('/chat'),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: line),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.add_circle_outline_rounded, color: muted, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Ask anything…',
                                style: GoogleFonts.inter(color: muted, fontSize: 15),
                              ),
                            ),
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
                              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Suggested questions
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
                    child: Text(
                      'QUESTIONS OTHERS ARE ASKING',
                      style: GoogleFonts.jetBrainsMono(color: muted, fontSize: 10, letterSpacing: 2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: List.generate(_suggestions(religion?.id).length, (i) {
                        final q = _suggestions(religion?.id)[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onTap: () => context.go('/chat'),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: surface,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28, height: 28,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: isDark ? AppColors.nightBg : AppColors.boneBg,
                                    ),
                                    child: Center(
                                      child: Text(
                                        (i + 1).toString().padLeft(2, '0'),
                                        style: GoogleFonts.jetBrainsMono(
                                          color: muted, fontSize: 11, fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      q,
                                      style: GoogleFonts.cormorantGaramond(
                                        color: fg, fontSize: 14, fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.w500, height: 1.4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: muted),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Continue last conversation
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
                    child: Text(
                      'CONTINUE WHERE YOU LEFT',
                      style: GoogleFonts.jetBrainsMono(color: muted, fontSize: 10, letterSpacing: 2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: GestureDetector(
                      onTap: () => context.go('/chat'),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'On forgiveness after betrayal',
                              style: GoogleFonts.cormorantGaramond(
                                color: fg, fontSize: 18, fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500, letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '"When forgiveness feels impossible, the scripture offers a gentler frame…"',
                              style: GoogleFonts.inter(color: muted, fontSize: 13, height: 1.4),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text('14 MESSAGES', style: GoogleFonts.jetBrainsMono(color: muted, fontSize: 10, letterSpacing: 1)),
                                Text(' · ', style: GoogleFonts.jetBrainsMono(color: muted, fontSize: 10)),
                                Text('YESTERDAY', style: GoogleFonts.jetBrainsMono(color: muted, fontSize: 10, letterSpacing: 1)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _suggestions(String? id) => switch (id) {
    'islam' => [
      'How do I find peace when prayer feels empty?',
      'What does the Qurʼan say about doubt?',
      'Why does suffering exist if God is merciful?',
    ],
    'hinduism' => [
      'What does the Gita say about duty and desire?',
      'How do I understand karma in daily life?',
      'What is the nature of the self in Advaita?',
    ],
    'sikhism' => [
      'What does Seva mean in daily practice?',
      'How does the Guru Granth Sahib address grief?',
      'What is the significance of Naam Simran?',
    ],
    'christianity' => [
      'How do I find peace when prayer feels empty?',
      'What do the Psalms say about suffering?',
      'How does grace relate to forgiveness?',
    ],
    _ => [
      'How do I find peace when prayer feels empty?',
      'What does scripture say about doubt?',
      'Why does suffering exist if God is merciful?',
    ],
  };

  String _weekday(int d) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d - 1];
  String _month(int m) =>
      const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1];
}

class _VerseCard extends ConsumerWidget {
  const _VerseCard({required this.religionId, required this.accent});
  final String religionId;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verse = ref.watch(_dailyVerseProvider(religionId));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: accent,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24, top: -24,
            child: Opacity(
              opacity: 0.15,
              child: ReligionGlyph(religionId: religionId, size: 160, color: Colors.white),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VERSE FOR TODAY',
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              verse.when(
                loading: () => const SizedBox(
                  height: 56,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5),
                  ),
                ),
                error: (e, st) => Text(
                  'Could not load verse.',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.7), fontSize: 13,
                  ),
                ),
                data: (v) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '"${v.text}"',
                      style: GoogleFonts.cormorantGaramond(
                        color: Colors.white, fontSize: 22, fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w400, height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${v.source.toUpperCase()} · ${v.ref}',
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11, letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
