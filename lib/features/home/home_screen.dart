import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/religion_provider.dart';
import '../../providers/user_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/texts_repository.dart';
import '../../shared/widgets/religion_glyph.dart';

final _dailyVerseProvider = FutureProvider.autoDispose.family<DailyVerse, String>(
  (ref, religionId) => TextsRepository.instance.getDailyVerse(religionId),
);

const _kTopics = [
  'Finding peace',
  'Working through doubt',
  'Grief & loss',
  'Purpose',
  'Family',
  'Daily prayer',
];

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final religionState = ref.watch(religionProvider);
    final religion = religionState.selectedReligion;
    final accent = religion?.accentColor ?? AppColors.islamGreen;
    final accentSoft = religion?.accentSoft ?? AppColors.islamGreenSoft;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final line = isDark ? AppColors.nightLine : AppColors.boneLine;

    final userState = ref.watch(userProvider);
    final firstName = userState.user?.firstName ?? 'Friend';

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top bar ──────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar circle — first initial
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accentSoft,
                          ),
                          child: Center(
                            child: Text(
                              firstName.isNotEmpty
                                  ? firstName[0].toUpperCase()
                                  : 'F',
                              style: GoogleFonts.cormorantGaramond(
                                color: accent,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        // Religion pill
                        GestureDetector(
                          onTap: () => context.go('/onboarding/religion'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: line),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (religion != null) ...[
                                  ReligionGlyph(
                                    religionId: religion.id,
                                    size: 14,
                                    color: accent,
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  religion?.name ?? 'Choose Religion',
                                  style: GoogleFonts.inter(
                                    color: fg,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 14,
                                  color: muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Greeting ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, $firstName.',
                          style: GoogleFonts.cormorantGaramond(
                            color: fg,
                            fontSize: 36,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "What's on your heart today?",
                          style: GoogleFonts.inter(
                            color: muted,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Input card ───────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: () => context.go('/chat'),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Type a question, or tap a topic below…',
                              style: GoogleFonts.inter(
                                color: muted,
                                fontSize: 15,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  color: muted,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.mic_none_rounded,
                                  color: muted,
                                  size: 22,
                                ),
                                const Spacer(),
                                Container(
                                  width: 48,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    color: accent,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Ask →',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Topic chips ──────────────────────────────────────────
                  SizedBox(
                    height: 40,
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        scrollbars: false,
                      ),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _kTopics.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          return GestureDetector(
                            onTap: () => context.go('/chat'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: line),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: accent,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _kTopics[i],
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: fg,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Pick up where you left ───────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PICK UP WHERE YOU LEFT',
                          style: GoogleFonts.jetBrainsMono(
                            color: muted,
                            fontSize: 11,
                            letterSpacing: 1.5,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/history'),
                          child: Text(
                            'See all',
                            style: GoogleFonts.inter(
                              color: accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Conversation card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: () => context.go('/chat'),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: line),
                        ),
                        child: Row(
                          children: [
                            // Religion glyph circle
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accentSoft,
                              ),
                              child: Center(
                                child: ReligionGlyph(
                                  religionId: religion?.id ?? 'islam',
                                  size: 18,
                                  color: accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Title + meta
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'On forgiveness after betrayal',
                                    style: GoogleFonts.cormorantGaramond(
                                      color: fg,
                                      fontSize: 16,
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '14 MESSAGES · YESTERDAY',
                                    style: GoogleFonts.jetBrainsMono(
                                      color: muted,
                                      fontSize: 10,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Forward arrow
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accent,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── A line for today ─────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                    child: Text(
                      'A LINE FOR TODAY',
                      style: GoogleFonts.jetBrainsMono(
                        color: muted,
                        fontSize: 11,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),

                  if (religion != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      child: _VerseCard(
                        religionId: religion.id,
                        accent: accent,
                        line: line,
                        fg: fg,
                        muted: muted,
                      ),
                    )
                  else
                    const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  String _weekday(int d) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d - 1];
  // ignore: unused_element
  String _month(int m) =>
      const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m - 1];
}

class _VerseCard extends ConsumerWidget {
  const _VerseCard({
    required this.religionId,
    required this.accent,
    required this.line,
    required this.fg,
    required this.muted,
  });

  final String religionId;
  final Color accent;
  final Color line;
  final Color fg;
  final Color muted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verse = ref.watch(_dailyVerseProvider(religionId));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: line),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Watermark glyph
          Positioned(
            right: -10,
            top: -10,
            child: Opacity(
              opacity: 0.07,
              child: ReligionGlyph(
                religionId: religionId,
                size: 140,
                color: accent,
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              verse.when(
                loading: () => const SizedBox(
                  height: 60,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                ),
                error: (e, st) => Text(
                  'Could not load verse.',
                  style: GoogleFonts.inter(color: muted, fontSize: 13),
                ),
                data: (v) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '“${v.text}”',
                      style: GoogleFonts.cormorantGaramond(
                        color: fg,
                        fontSize: 20,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w400,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${v.source.toUpperCase()} · ${v.ref}',
                      style: GoogleFonts.jetBrainsMono(
                        color: accent,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => context.go('/chat'),
                        child: Text(
                          'Ask about this →',
                          style: GoogleFonts.inter(
                            color: accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
