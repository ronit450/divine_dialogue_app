import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class DevelopersScreen extends StatelessWidget {
  const DevelopersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.nightBg : AppColors.boneBg;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final line = isDark ? AppColors.nightLine : AppColors.boneLine;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: line),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: fg),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'The Team',
                    style: GoogleFonts.cormorantGaramond(
                      color: fg, fontSize: 28, fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'THE PEOPLE BEHIND DIVINE DIALOGUE',
                style: GoogleFonts.jetBrainsMono(
                  color: muted, fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _DeveloperCard(
                    name: 'Ronit Kumar',
                    role: 'Co-Founder & Developer',
                    description: 'Description coming soon.',
                    initials: 'RK',
                    accentColor: AppColors.islamGreen,
                    isDark: isDark,
                    fg: fg,
                    muted: muted,
                  ),
                  const SizedBox(height: 16),
                  _DeveloperCard(
                    name: 'Faraz Ali',
                    role: 'Co-Founder & Developer',
                    description: 'Description coming soon.',
                    initials: 'FA',
                    accentColor: AppColors.sikhNavy,
                    isDark: isDark,
                    fg: fg,
                    muted: muted,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeveloperCard extends StatelessWidget {
  const _DeveloperCard({
    required this.name,
    required this.role,
    required this.description,
    required this.initials,
    required this.accentColor,
    required this.isDark,
    required this.fg,
    required this.muted,
  });

  final String name;
  final String role;
  final String description;
  final String initials;
  final Color accentColor;
  final bool isDark;
  final Color fg;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.nightSurface : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: accentColor.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withValues(alpha: 0.15),
                  accentColor.withValues(alpha: 0.30),
                ],
              ),
              border: Border.all(color: accentColor.withValues(alpha: 0.25), width: 1.5),
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.cormorantGaramond(
                  color: accentColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.cormorantGaramond(
                    color: fg,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    color: accentColor,
                    fontSize: 9,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    color: muted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
