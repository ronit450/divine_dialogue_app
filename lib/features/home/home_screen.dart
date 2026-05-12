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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static String _weekday(int d) =>
      const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][d - 1];
  static String _month(int m) =>
      const ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'][m - 1];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final religionState = ref.watch(religionProvider);
    final religion = religionState.selectedReligion;
    final accent = religion?.accentColor ?? AppColors.islamGreen;
    final accentSoft = religion?.accentSoft ?? AppColors.islamGreenSoft;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.nightBg : AppColors.boneBg;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final line = isDark ? AppColors.nightLine : AppColors.boneLine;

    final userState = ref.watch(userProvider);
    final firstName = userState.user?.firstName ?? 'Friend';
    final salutation = (religion?.salutation.isNotEmpty ?? false)
        ? religion!.salutation
        : 'Hello';

    final now = DateTime.now();
    final dateLabel =
        '${_weekday(now.weekday)} · ${now.day} ${_month(now.month)}';

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              dateLabel: dateLabel,
              fg: fg,
              muted: muted,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (religion != null)
                      _VerseHero(
                        religionId: religion.id,
                        accent: accent,
                        accentSoft: accentSoft,
                        isDark: isDark,
                        fg: fg,
                        muted: muted,
                        onTap: () => context.go('/chat'),
                      ),
                    const SizedBox(height: 20),
                    _GreetingSection(
                      salutation: salutation,
                      firstName: firstName,
                      fg: fg,
                      muted: muted,
                    ),
                    const SizedBox(height: 16),
                    _MoodSection(
                      accent: accent,
                      fg: fg,
                      muted: muted,
                      line: line,
                      onTap: (_) => context.go('/chat'),
                    ),
                    const SizedBox(height: 24),
                    if (religion != null)
                      _QuickStartSection(
                        religionId: religion.id,
                        accent: accent,
                        fg: fg,
                        muted: muted,
                        line: line,
                        onTap: () => context.go('/chat'),
                      ),
                    const Spacer(),
                    _BeginDialogueButton(
                      accent: accent,
                      fg: fg,
                      bg: bg,
                      onTap: () => context.go('/chat'),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top bar ────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.dateLabel,
    required this.fg,
    required this.muted,
  });

  final String dateLabel;
  final Color fg;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Text(
            dateLabel,
            style: GoogleFonts.jetBrainsMono(
              color: muted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Verse hero ─────────────────────────────────────────────────────────────────

class _VerseHero extends ConsumerWidget {
  const _VerseHero({
    required this.religionId,
    required this.accent,
    required this.accentSoft,
    required this.isDark,
    required this.fg,
    required this.muted,
    required this.onTap,
  });

  final String religionId;
  final Color accent;
  final Color accentSoft;
  final bool isDark;
  final Color fg;
  final Color muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verse = ref.watch(_dailyVerseProvider(religionId));
    final cardBg = isDark ? accent.withValues(alpha: 0.10) : accentSoft;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: verse.when(
          loading: () => SizedBox(
            height: 80,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
          ),
          error: (_, _) => Text(
            'Verse unavailable',
            style: GoogleFonts.inter(color: muted, fontSize: 13),
          ),
          data: (v) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ReligionGlyph(religionId: religionId, size: 13, color: accent),
                  const SizedBox(width: 6),
                  Text(
                    'VERSE OF THE DAY',
                    style: GoogleFonts.jetBrainsMono(
                      color: accent,
                      fontSize: 9,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '"${v.text}"',
                style: GoogleFonts.cormorantGaramond(
                  color: fg,
                  fontSize: 22,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  letterSpacing: -0.2,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${v.source.toUpperCase()} · ${v.ref}',
                      style: GoogleFonts.jetBrainsMono(
                        color: accent,
                        fontSize: 10,
                        letterSpacing: 0.8,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Discuss',
                        style: GoogleFonts.inter(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.arrow_forward_rounded, color: accent, size: 12),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Greeting section ───────────────────────────────────────────────────────────

class _GreetingSection extends StatelessWidget {
  const _GreetingSection({
    required this.salutation,
    required this.firstName,
    required this.fg,
    required this.muted,
  });

  final String salutation;
  final String firstName;
  final Color fg;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$salutation, $firstName.',
          style: GoogleFonts.cormorantGaramond(
            color: fg,
            fontSize: 36,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
            height: 1.1,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'BEGIN YOUR JOURNEY',
          style: GoogleFonts.jetBrainsMono(
            color: muted,
            fontSize: 10,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Mood section ───────────────────────────────────────────────────────────────

class _MoodSection extends StatelessWidget {
  const _MoodSection({
    required this.accent,
    required this.fg,
    required this.muted,
    required this.line,
    required this.onTap,
  });

  final Color accent;
  final Color fg;
  final Color muted;
  final Color line;
  final ValueChanged<String> onTap;

  static const _moods = ['Grateful', 'Restless', 'Searching', 'Heavy'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HOW IS YOUR HEART TODAY?',
          style: GoogleFonts.jetBrainsMono(
            color: muted,
            fontSize: 10,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _moods.map((mood) {
            return GestureDetector(
              onTap: () => onTap(mood),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: line),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      mood,
                      style: GoogleFonts.inter(
                        color: fg,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Quick-start prompts ────────────────────────────────────────────────────────

class _QuickStartSection extends StatelessWidget {
  const _QuickStartSection({
    required this.religionId,
    required this.accent,
    required this.fg,
    required this.muted,
    required this.line,
    required this.onTap,
  });

  final String religionId;
  final Color accent;
  final Color fg;
  final Color muted;
  final Color line;
  final VoidCallback onTap;

  static const _prompts = <String, List<String>>{
    'islam': [
      'What are the five pillars of Islam?',
      'How do I strengthen my Salah?',
      'What does the Quran say about patience?',
    ],
    'hinduism': [
      'What is the meaning of dharma?',
      'How do I practice karma yoga?',
      'What is the path to moksha?',
    ],
    'sikhism': [
      'What is the Mool Mantar?',
      'How do I practice Seva in daily life?',
      'What does Gurbani say about the soul?',
    ],
    'christianity': [
      'What is the greatest commandment?',
      'How do I practice forgiveness?',
      'What does Jesus say about love?',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final questions = _prompts[religionId] ?? _prompts['islam']!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EXPLORE',
          style: GoogleFonts.jetBrainsMono(
            color: muted,
            fontSize: 10,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        ...questions.map(
          (q) => GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: line, width: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.arrow_forward_ios_rounded, size: 10, color: accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      q,
                      style: GoogleFonts.inter(
                        color: fg,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Begin Dialogue button ──────────────────────────────────────────────────────

class _BeginDialogueButton extends StatelessWidget {
  const _BeginDialogueButton({
    required this.accent,
    required this.fg,
    required this.bg,
    required this.onTap,
  });

  final Color accent;
  final Color fg;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Begin Dialogue',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
