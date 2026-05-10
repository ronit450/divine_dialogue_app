import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/religion_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/religion.dart';
import '../../shared/widgets/religion_glyph.dart';

class OnboardingReligionScreen extends ConsumerWidget {
  const OnboardingReligionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(religionProvider);
    final religions = state.religions;
    final selected = state.selectedReligion;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final line = isDark ? AppColors.nightLine : AppColors.boneLine;
    final bg = isDark ? AppColors.nightBg : AppColors.boneBg;
    final accent = selected?.accentColor ?? AppColors.islamGreen;

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
                  _CircleBackButton(fg: fg, line: line, onTap: () => context.go('/onboarding')),
                  Text(
                    'STEP · 01 OF 02',
                    style: GoogleFonts.jetBrainsMono(
                      color: muted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Which path\nguides you?',
                    style: GoogleFonts.cormorantGaramond(
                      color: fg, fontSize: 38, fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500, height: 1.05, letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pick a tradition — or open the dialogue across all of them.',
                    style: GoogleFonts.inter(color: muted, fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.isLoaded
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Column(
                        children: [
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.88,
                            ),
                            itemCount: religions.length,
                            itemBuilder: (context, i) => _ReligionCard(
                              religion: religions[i],
                              isSelected: selected?.id == religions[i].id,
                              isDark: isDark,
                              fg: fg,
                              muted: muted,
                              line: line,
                              onTap: () => ref.read(religionProvider.notifier).selectReligion(religions[i]),
                            ),
                          ),

                        ],
                      ),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: selected == null ? null : () => context.go('/onboarding/text'),
                  style: FilledButton.styleFrom(
                    backgroundColor: selected == null
                        ? (isDark ? AppColors.nightSurface : AppColors.boneSurface)
                        : accent,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w600,
                      color: selected == null ? muted : Colors.white,
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

class _ReligionCard extends StatelessWidget {
  const _ReligionCard({
    required this.religion,
    required this.isSelected,
    required this.isDark,
    required this.fg,
    required this.muted,
    required this.line,
    required this.onTap,
  });

  final ReligionModel religion;
  final bool isSelected;
  final bool isDark;
  final Color fg;
  final Color muted;
  final Color line;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = religion.accentColor;
    final cardBg = isDark ? AppColors.nightSurface : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected
              ? (isDark ? accent.withValues(alpha: 0.12) : accent.withValues(alpha: 0.06))
              : cardBg,
          border: Border.all(
            color: isSelected ? accent : line,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isDark
              ? null
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? accent.withValues(alpha: 0.12)
                    : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF5F0EA)),
              ),
              child: Center(
                child: ReligionGlyph(religionId: religion.id, size: 30, color: accent),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              religion.name,
              style: GoogleFonts.cormorantGaramond(
                color: fg, fontSize: 18, fontWeight: FontWeight.w500, letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '"${religion.salutation}"',
              style: GoogleFonts.inter(
                color: muted, fontSize: 11, fontStyle: FontStyle.italic, height: 1.3,
              ),
              textAlign: TextAlign.center,
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
