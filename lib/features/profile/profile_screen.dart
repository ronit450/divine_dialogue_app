import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/religion_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/religion.dart';
import '../../shared/widgets/religion_glyph.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final religionState = ref.watch(religionProvider);
    final themeMode = ref.watch(themeModeProvider);
    final religion = religionState.selectedReligion;
    final accent = religion != null ? ReligionColors.accent(religion.id) : AppColors.islamGreen;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.nightBg : AppColors.boneBg;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final line = isDark ? AppColors.nightLine : AppColors.boneLine;
    final surface = isDark ? AppColors.nightSurface : Colors.white;

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
                    Text(
                      'Self',
                      style: GoogleFonts.cormorantGaramond(
                        color: fg, fontSize: 32, fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accent.withValues(alpha: 0.1),
                              border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.5),
                            ),
                            child: Center(
                              child: religion != null
                                  ? ReligionGlyph(religionId: religion.id, size: 30, color: accent)
                                  : Icon(Icons.person_outline_rounded, color: accent, size: 32),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            religion?.name ?? 'Guest',
                            style: GoogleFonts.cormorantGaramond(
                              color: fg, fontSize: 20, fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            religionState.selectedText?.title ?? 'No text selected',
                            style: GoogleFonts.inter(color: muted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _SectionLabel(label: 'TRADITION', muted: muted),
                    const SizedBox(height: 10),
                    _SurfaceCard(
                      surface: surface,
                      line: line,
                      isDark: isDark,
                      child: Column(
                        children: religionState.religions.asMap().entries.map((e) {
                          final r = e.value;
                          final isSelected = r.id == religion?.id;
                          final rAccent = ReligionColors.accent(r.id);
                          final isLast = e.key == religionState.religions.length - 1;
                          return _ReligionRow(
                            religion: r,
                            accent: rAccent,
                            isSelected: isSelected,
                            showDivider: !isLast,
                            line: line,
                            fg: fg,
                            onTap: () => ref.read(religionProvider.notifier).selectReligion(r),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel(label: 'APPEARANCE', muted: muted),
                    const SizedBox(height: 10),
                    _SurfaceCard(
                      surface: surface,
                      line: line,
                      isDark: isDark,
                      child: _ToggleRow(
                        icon: Icons.dark_mode_rounded,
                        label: 'Dark mode',
                        value: themeMode == ThemeMode.dark,
                        accent: accent,
                        fg: fg,
                        muted: muted,
                        onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel(label: 'ABOUT', muted: muted),
                    const SizedBox(height: 10),
                    _SurfaceCard(
                      surface: surface,
                      line: line,
                      isDark: isDark,
                      child: Column(
                        children: [
                          _InfoRow(label: 'Version', value: '1.0.0', fg: fg, muted: muted),
                          Divider(height: 1, color: line),
                          _InfoRow(
                            label: 'Traditions',
                            value: '${religionState.religions.length} religions',
                            fg: fg,
                            muted: muted,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    required this.surface,
    required this.line,
    required this.isDark,
  });

  final Widget child;
  final Color surface;
  final Color line;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      clipBehavior: Clip.hardEdge,
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.muted});
  final String label;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.jetBrainsMono(
        color: muted, fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 1.5,
      ),
    );
  }
}

class _ReligionRow extends StatelessWidget {
  const _ReligionRow({
    required this.religion,
    required this.accent,
    required this.isSelected,
    required this.showDivider,
    required this.line,
    required this.fg,
    required this.onTap,
  });

  final ReligionModel religion;
  final Color accent;
  final bool isSelected;
  final bool showDivider;
  final Color line;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                ReligionGlyph(religionId: religion.id, size: 18, color: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    religion.name,
                    style: GoogleFonts.inter(
                      color: isSelected ? accent : fg,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: accent, size: 18),
              ],
            ),
          ),
        ),
        if (showDivider) Divider(height: 1, color: line),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.fg,
    required this.muted,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final Color accent;
  final Color fg;
  final Color muted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: muted, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: GoogleFonts.inter(color: fg, fontSize: 14)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: accent,
            activeTrackColor: accent.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.fg,
    required this.muted,
  });

  final String label;
  final String value;
  final Color fg;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: fg, fontSize: 14)),
          Text(value, style: GoogleFonts.inter(color: muted, fontSize: 14)),
        ],
      ),
    );
  }
}
