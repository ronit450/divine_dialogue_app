import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/religion_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/religion.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(religionProvider);
    final religions = state.religions;
    final selectedReligion = state.selectedReligion;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.nightBg : AppColors.boneBg;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final line = isDark ? AppColors.nightLine : AppColors.boneLine;
    final surface = isDark ? AppColors.nightSurface : Colors.white;

    final activeReligion = selectedReligion ??
        (religions.isNotEmpty ? religions.first : null);

    if (activeReligion == null) {
      return Scaffold(backgroundColor: bg);
    }

    final accent = ReligionColors.accent(activeReligion.id);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.go('/home'),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: line),
                            ),
                            child: Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: fg),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LIBRARY',
                                style: GoogleFonts.jetBrainsMono(
                                  color: muted,
                                  fontSize: 10,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                activeReligion.name,
                                style: GoogleFonts.cormorantGaramond(
                                  color: fg,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: line),
                          ),
                          child: Icon(Icons.search_rounded, size: 17, color: muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap any text to begin reading.',
                      style: GoogleFonts.inter(color: muted, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // Hero card for primary text
          if (activeReligion.texts.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _HeroTextCard(
                  text: activeReligion.texts.first,
                  religion: activeReligion,
                  accent: accent,
                  isSelected: activeReligion.texts.first.id == state.selectedText?.id,
                ),
              ),
            ),

          // Other texts
          if (activeReligion.texts.length > 1) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Text(
                  'OTHER TEXTS · ${activeReligion.texts.length - 1}',
                  style: GoogleFonts.jetBrainsMono(
                    color: muted, fontSize: 9, letterSpacing: 2,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final text = activeReligion.texts[i + 1];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _TextListTile(
                        text: text,
                        accent: accent,
                        fg: fg,
                        muted: muted,
                        line: line,
                        surface: surface,
                        onTap: () => context.push('/read/${text.id}'),
                      ),
                    );
                  },
                  childCount: activeReligion.texts.length - 1,
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }
}

class _HeroTextCard extends StatelessWidget {
  const _HeroTextCard({
    required this.text,
    required this.religion,
    required this.accent,
    required this.isSelected,
  });

  final SacredTextModel text;
  final ReligionModel religion;
  final Color accent;
  final bool isSelected;

  String _watermarkGlyph(String religionId) => switch (religionId) {
    'sikhism'      => 'ਆਦਿ ਸਚੁ',
    'islam'        => 'الله',
    'hinduism'     => 'ॐ',
    'christianity' => '✝',
    _ => '✦',
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/read/${text.id}'),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              right: -16,
              top: -12,
              child: Text(
                _watermarkGlyph(religion.id),
                style: TextStyle(
                  fontSize: 90,
                  color: Colors.white.withValues(alpha: 0.08),
                  fontFamily: 'serif',
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSelected ? 'CURRENT TEXT' : 'PRIMARY TEXT',
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 9,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  text.title,
                  style: GoogleFonts.cormorantGaramond(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text.description,
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isSelected ? 'CONTINUE READING' : 'BEGIN READING',
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white,
                        fontSize: 9,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TextListTile extends StatelessWidget {
  const _TextListTile({
    required this.text,
    required this.accent,
    required this.fg,
    required this.muted,
    required this.line,
    required this.surface,
    required this.onTap,
  });

  final SacredTextModel text;
  final Color accent;
  final Color fg;
  final Color muted;
  final Color line;
  final Color surface;
  final VoidCallback onTap;

  String _abbrev(String title) {
    final words = title.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words[0].substring(0, words[0].length.clamp(0, 3)).toUpperCase();
    return words.take(2).map((w) => w[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: line),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  _abbrev(text.title),
                  style: GoogleFonts.jetBrainsMono(
                    color: accent, fontSize: 11,
                    fontWeight: FontWeight.w600, letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text.title,
                    style: GoogleFonts.inter(color: fg, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(text.description, style: GoogleFonts.inter(color: muted, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: muted, size: 20),
          ],
        ),
      ),
    );
  }
}
