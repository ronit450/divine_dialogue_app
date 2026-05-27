import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/locale_provider.dart';
import '../../providers/religion_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_strings.dart';

class OnboardingLanguageScreen extends ConsumerStatefulWidget {
  const OnboardingLanguageScreen({super.key});

  @override
  ConsumerState<OnboardingLanguageScreen> createState() =>
      _OnboardingLanguageScreenState();
}

class _OnboardingLanguageScreenState
    extends ConsumerState<OnboardingLanguageScreen> {
  String _selectedCode = 'en';

  @override
  void initState() {
    super.initState();
    _selectedCode = ref.read(localeProvider).locale.languageCode;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final line = isDark ? AppColors.nightLine : AppColors.boneLine;
    final bg = isDark ? AppColors.nightBg : AppColors.boneBg;
    final surface = isDark ? AppColors.nightSurface : Colors.white;

    final religionState = ref.watch(religionProvider);
    final selected = religionState.selectedReligion;
    final accent = selected != null
        ? ReligionColors.accent(selected.id)
        : AppColors.islamGreen;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Brand mark
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Center(
                      child: Text(
                        'D',
                        style: GoogleFonts.cormorantGaramond(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'DIVINE DIALOGUE',
                    style: GoogleFonts.jetBrainsMono(
                      color: muted,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 3-step progress bar — step 1 active
              Row(
                children: List.generate(3, (i) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                      height: 3,
                      decoration: BoxDecoration(
                        color: i == 0 ? accent : line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              Text(
                AppStrings.onboardStep1,
                style: GoogleFonts.jetBrainsMono(
                  color: accent,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                AppStrings.onboardLangTitle,
                style: GoogleFonts.cormorantGaramond(
                  color: fg,
                  fontSize: 38,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  height: 1.05,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                AppStrings.onboardLangSub,
                style: GoogleFonts.inter(color: muted, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 28),

              _LanguageCard(
                code: 'en',
                displayName: 'English',
                subtitle: 'English (US)',
                sample: 'Indeed, with hardship comes ease.',
                sampleFont: GoogleFonts.cormorantGaramond(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: fg.withValues(alpha: 0.7),
                  height: 1.6,
                ),
                isSelected: _selectedCode == 'en',
                accent: accent,
                fg: fg,
                muted: muted,
                line: line,
                surface: surface,
                textDirection: TextDirection.ltr,
                onTap: () => setState(() => _selectedCode = 'en'),
              ),
              const SizedBox(height: 12),

              _LanguageCard(
                code: 'ur',
                displayName: 'اردو',
                subtitle: 'Urdu',
                sample: 'بے شک ہر مشکل کے ساتھ آسانی ہے۔',
                sampleFont: GoogleFonts.notoNastaliqUrdu(
                  fontSize: 16,
                  color: fg.withValues(alpha: 0.7),
                  height: 1.9,
                ),
                isSelected: _selectedCode == 'ur',
                accent: accent,
                fg: fg,
                muted: muted,
                line: line,
                surface: surface,
                textDirection: TextDirection.rtl,
                onTap: () => setState(() => _selectedCode = 'ur'),
              ),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () async {
                      await ref
                          .read(localeProvider.notifier)
                          .setLocale(Locale(_selectedCode));
                      if (context.mounted) context.go('/onboarding/religion');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      shape: const StadiumBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.onboardContinue,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.code,
    required this.displayName,
    required this.subtitle,
    required this.sample,
    required this.sampleFont,
    required this.isSelected,
    required this.accent,
    required this.fg,
    required this.muted,
    required this.line,
    required this.surface,
    required this.textDirection,
    required this.onTap,
  });

  final String code;
  final String displayName;
  final String subtitle;
  final String sample;
  final TextStyle sampleFont;
  final bool isSelected;
  final Color accent, fg, muted, line, surface;
  final TextDirection textDirection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRtl = textDirection == TextDirection.rtl;
    final accentSoft = accent.withValues(alpha: 0.08);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? accentSoft : surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accent : line,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? accent : line,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    textDirection: textDirection,
                    style: isRtl
                        ? GoogleFonts.notoNastaliqUrdu(
                            fontSize: 26,
                            fontWeight: FontWeight.w500,
                            color: fg,
                            height: 1.5,
                          )
                        : GoogleFonts.cormorantGaramond(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: fg,
                            fontStyle: FontStyle.italic,
                          ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: muted,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Divider(
                    height: 1,
                    color: isSelected ? accent.withValues(alpha: 0.2) : line,
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment:
                        isRtl ? Alignment.centerRight : Alignment.centerLeft,
                    child: Text(
                      sample,
                      style: sampleFont,
                      textDirection: textDirection,
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
}
