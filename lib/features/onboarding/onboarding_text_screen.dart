import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/religion_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/religion.dart';
import '../../shared/widgets/religion_glyph.dart';

class OnboardingTextScreen extends ConsumerStatefulWidget {
  const OnboardingTextScreen({super.key});

  @override
  ConsumerState<OnboardingTextScreen> createState() => _OnboardingTextScreenState();
}

class _OnboardingTextScreenState extends ConsumerState<OnboardingTextScreen> {
  final Set<String> _selectedIds = {};
  bool _loading = false;

  void _toggle(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _continue(ReligionModel religion) async {
    if (_selectedIds.isEmpty || _loading) return;
    setState(() => _loading = true);

    final notifier = ref.read(religionProvider.notifier);
    final primary = religion.texts.firstWhere((t) => _selectedIds.contains(t.id));
    await notifier.selectText(primary);
    await notifier.completeOnboarding();

    if (mounted) context.go('/sign-in');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(religionProvider);
    final religion = state.selectedReligion;

    // Router handles redirect if religion is null — no postFrameCallback needed
    if (religion == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final line = isDark ? AppColors.nightLine : AppColors.boneLine;
    final bg = isDark ? AppColors.nightBg : AppColors.boneBg;
    final accent = religion.accentColor;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleBackButton(
                    fg: fg, line: line,
                    onTap: () => context.go('/onboarding/religion'),
                  ),
                  Text(
                    'STEP · 02 OF 02',
                    style: GoogleFonts.jetBrainsMono(
                      color: muted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ReligionGlyph(religionId: religion.id, size: 18, color: accent),
                      const SizedBox(width: 8),
                      Text(
                        religion.name.toUpperCase(),
                        style: GoogleFonts.jetBrainsMono(
                          color: accent, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'From which texts\nshall we draw?',
                    style: GoogleFonts.cormorantGaramond(
                      color: fg, fontSize: 36, fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500, height: 1.05, letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Select one or more. Answers will cite the chapter and verse.',
                    style: GoogleFonts.inter(color: muted, fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                itemCount: religion.texts.length,
                separatorBuilder: (context, i) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final text = religion.texts[i];
                  final isSel = _selectedIds.contains(text.id);
                  return _BookCard(
                    text: text,
                    accent: accent,
                    soft: religion.accentSoft,
                    isPrimary: i == 0,
                    isSelected: isSel,
                    isDark: isDark,
                    fg: fg,
                    muted: muted,
                    line: line,
                    onTap: () => _toggle(text.id),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 48),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: (_selectedIds.isEmpty || _loading) ? null : () => _continue(religion),
                  style: FilledButton.styleFrom(
                    backgroundColor: _selectedIds.isEmpty
                        ? (isDark ? AppColors.nightSurface : AppColors.boneSurface)
                        : accent,
                    shape: const StadiumBorder(),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Begin dialogue',
                          style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.w600,
                            color: _selectedIds.isEmpty ? muted : Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.text,
    required this.accent,
    required this.soft,
    required this.isPrimary,
    required this.isSelected,
    required this.isDark,
    required this.fg,
    required this.muted,
    required this.line,
    required this.onTap,
  });

  final SacredTextModel text;
  final Color accent;
  final Color soft;
  final bool isPrimary;
  final bool isSelected;
  final bool isDark;
  final Color fg;
  final Color muted;
  final Color line;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.nightSurface : Colors.white;
    final selBg = isDark ? accent.withValues(alpha: 0.12) : soft;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? accent : line, width: isSelected ? 1.5 : 1),
          color: isSelected ? selBg : cardBg,
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 44, height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isPrimary
                        ? accent
                        : (isDark ? line.withValues(alpha: 0.5) : line.withValues(alpha: 0.3)),
                  ),
                ),
                Positioned(
                  left: 4, top: 4, bottom: 4,
                  child: Container(
                    width: 1.5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1),
                      color: isPrimary
                          ? Colors.white.withValues(alpha: 0.3)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.1)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text.title,
                    style: GoogleFonts.cormorantGaramond(
                      color: isPrimary ? accent : fg,
                      fontSize: 19, fontWeight: FontWeight.w500, height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    text.description,
                    style: GoogleFonts.jetBrainsMono(color: muted, fontSize: 11, letterSpacing: 0.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 22, height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isSelected ? accent : line, width: 1.5),
                color: isSelected ? accent : Colors.transparent,
              ),
              child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 13) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.fg, required this.line, required this.onTap});
  final Color fg;
  final Color line;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: line)),
        child: Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: fg),
      ),
    );
  }
}
