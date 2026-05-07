import 'dart:ui';
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
    final accent = selected?.accentColor ?? AppColors.islamGreen;

    return Scaffold(
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
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 12),
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
                  const SizedBox(height: 10),
                  Text(
                    'Pick a tradition — or open the dialogue across all of them.',
                    style: GoogleFonts.inter(color: muted, fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.isLoaded
                  ? _CardArea(
                      religions: religions,
                      selected: selected,
                      isDark: isDark,
                      fg: fg,
                      muted: muted,
                      onSelect: (r) => ref.read(religionProvider.notifier).selectReligion(r),
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

class _CardArea extends StatelessWidget {
  const _CardArea({
    required this.religions,
    required this.selected,
    required this.isDark,
    required this.fg,
    required this.muted,
    required this.onSelect,
  });

  final List<ReligionModel> religions;
  final ReligionModel? selected;
  final bool isDark;
  final Color fg;
  final Color muted;
  final ValueChanged<ReligionModel> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Stack(
        children: [
          if (selected != null)
            Positioned.fill(
              child: Align(
                alignment: const Alignment(0, -0.2),
                child: IgnorePointer(
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [selected!.accentColor.withValues(alpha: 0.2), Colors.transparent],
                        stops: const [0, 0.65],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Column(
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                itemCount: religions.length,
                itemBuilder: (context, i) => _GlassCard(
                  religion: religions[i],
                  isSelected: selected?.id == religions[i].id,
                  isDark: isDark,
                  fg: fg,
                  muted: muted,
                  onTap: () => onSelect(religions[i]),
                ),
              ),
              const SizedBox(height: 12),
              _AllPathsCard(religions: religions, isDark: isDark, fg: fg, muted: muted),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.religion,
    required this.isSelected,
    required this.isDark,
    required this.fg,
    required this.muted,
    required this.onTap,
  });

  final ReligionModel religion;
  final bool isSelected;
  final bool isDark;
  final Color fg;
  final Color muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = religion.accentColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.7)),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isDark
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 6))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              color: isDark
                  ? (isSelected ? Colors.white.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.06))
                  : (isSelected ? Colors.white.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.55)),
              child: Stack(
                children: [
                  // Shimmer highlight
                  Positioned(
                    top: 0, left: 0, right: 0, height: 48,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white.withValues(alpha: 0.3), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? accent
                              : (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.7)),
                        ),
                        child: Center(
                          child: ReligionGlyph(
                            religionId: religion.id,
                            size: 22,
                            color: isSelected ? Colors.white : accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        religion.name,
                        style: GoogleFonts.cormorantGaramond(
                          color: fg, fontSize: 19, fontWeight: FontWeight.w600, letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '"${religion.salutation}"',
                        style: GoogleFonts.inter(color: muted, fontSize: 11, fontStyle: FontStyle.italic, height: 1.3),
                      ),
                    ],
                  ),
                  if (isSelected)
                    Positioned(
                      top: 0, right: 0,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
                        child: const Icon(Icons.check, color: Colors.white, size: 13),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AllPathsCard extends StatelessWidget {
  const _AllPathsCard({
    required this.religions,
    required this.isDark,
    required this.fg,
    required this.muted,
  });

  final List<ReligionModel> religions;
  final bool isDark;
  final Color fg;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.55),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.7),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 32,
                child: Stack(
                  children: List.generate(religions.length, (i) => Positioned(
                    left: i * 13.0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: religions[i].accentColor,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2),
                      ),
                      child: Center(
                        child: ReligionGlyph(religionId: religions[i].id, size: 14, color: Colors.white),
                      ),
                    ),
                  )).reversed.toList(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All paths',
                      style: GoogleFonts.cormorantGaramond(color: fg, fontSize: 19, fontWeight: FontWeight.w600, letterSpacing: -0.2),
                    ),
                    Text(
                      'Compare wisdom across every tradition.',
                      style: GoogleFonts.inter(color: muted, fontSize: 12, height: 1.35),
                    ),
                  ],
                ),
              ),
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: muted, width: 1.5)),
              ),
            ],
          ),
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
