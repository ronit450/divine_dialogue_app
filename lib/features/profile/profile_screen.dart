import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/religion_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/religion.dart';
import '../../shared/widgets/religion_glyph.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final religionState = ref.watch(religionProvider);
    final themeMode = ref.watch(themeModeProvider);
    final userState = ref.watch(userProvider);
    final religion = religionState.selectedReligion;
    final accent = religion != null ? ReligionColors.accent(religion.id) : AppColors.islamGreen;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.nightBg : AppColors.boneBg;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final line = isDark ? AppColors.nightLine : AppColors.boneLine;
    final surface = isDark ? AppColors.nightSurface : Colors.white;

    final displayName = userState.user != null
        ? '${userState.user!.firstName} ${userState.user!.lastName}'.trim()
        : 'Guest';

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.go('/home'),
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
                          'Settings',
                          style: GoogleFonts.cormorantGaramond(
                            color: fg, fontSize: 28, fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
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
                              child: Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'G',
                                style: GoogleFonts.cormorantGaramond(
                                  color: accent, fontSize: 28, fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            displayName,
                            style: GoogleFonts.cormorantGaramond(
                              color: fg, fontSize: 22, fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            religion?.name ?? 'No tradition selected',
                            style: GoogleFonts.inter(color: muted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel(label: 'ACCOUNT', muted: muted),
                    const SizedBox(height: 10),
                    _SurfaceCard(
                      surface: surface,
                      line: line,
                      isDark: isDark,
                      child: Column(
                        children: [
                          _ActionRow(
                            icon: Icons.person_outline_rounded,
                            label: 'Edit profile',
                            fg: fg,
                            muted: muted,
                            line: line,
                            onTap: () => context.go('/profile-setup'),
                          ),
                          Divider(height: 1, color: line),
                          _ActionRow(
                            icon: Icons.logout_rounded,
                            label: 'Sign out',
                            fg: Colors.red.shade400,
                            muted: muted,
                            line: line,
                            onTap: () async {
                              await ref.read(authProvider.notifier).signOut();
                              await ref.read(religionProvider.notifier).resetSignIn();
                              if (context.mounted) context.go('/sign-in');
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel(label: 'PRACTICE', muted: muted),
                    const SizedBox(height: 10),
                    _SurfaceCard(
                      surface: surface,
                      line: line,
                      isDark: isDark,
                      child: _ActionRow(
                        icon: Icons.menu_book_rounded,
                        label: 'Reading plan',
                        fg: fg,
                        muted: muted,
                        line: line,
                        onTap: () => context.push('/reading-plans'),
                      ),
                    ),
                    const SizedBox(height: 24),
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
                            onTap: () => ref.read(religionProvider.notifier).changeReligion(r),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (religion != null && religion.texts.isNotEmpty) ...[
                      _SectionLabel(label: 'TEXTS', muted: muted),
                      const SizedBox(height: 10),
                      _SurfaceCard(
                        surface: surface,
                        line: line,
                        isDark: isDark,
                        child: _ActionRow(
                          icon: Icons.menu_book_rounded,
                          label: 'Choose texts',
                          fg: fg,
                          muted: muted,
                          line: line,
                          onTap: () => _showTextPicker(
                            context: context,
                            religion: religion,
                            accent: accent,
                            fg: fg,
                            muted: muted,
                            line: line,
                            surface: surface,
                            isDark: isDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
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
                    _SectionLabel(label: 'DEVELOPER', muted: muted),
                    const SizedBox(height: 10),
                    _SurfaceCard(
                      surface: surface,
                      line: line,
                      isDark: isDark,
                      child: Column(
                        children: [
                          _ActionRow(
                            icon: Icons.people_outline_rounded,
                            label: 'Meet the team',
                            fg: fg,
                            muted: muted,
                            line: line,
                            onTap: () => context.push('/developers'),
                          ),
                          Divider(height: 1, color: line),
                          _ActionRow(
                            icon: Icons.flag_outlined,
                            label: 'Report an issue',
                            fg: fg,
                            muted: muted,
                            line: line,
                            onTap: () => context.push('/report-issue'),
                          ),
                        ],
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

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.fg,
    required this.muted,
    required this.line,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color fg;
  final Color muted;
  final Color line;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: fg, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: GoogleFonts.inter(color: fg, fontSize: 14)),
            ),
            Icon(Icons.chevron_right_rounded, color: muted, size: 18),
          ],
        ),
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

void _showTextPicker({
  required BuildContext context,
  required ReligionModel religion,
  required Color accent,
  required Color fg,
  required Color muted,
  required Color line,
  required Color surface,
  required bool isDark,
}) {
  final bg = isDark ? AppColors.nightBg : AppColors.boneBg;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: bg,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _TextPickerSheet(
      religion: religion,
      accent: accent,
      fg: fg,
      muted: muted,
      line: line,
      surface: surface,
      bg: bg,
    ),
  );
}

class _TextPickerSheet extends ConsumerWidget {
  const _TextPickerSheet({
    required this.religion,
    required this.accent,
    required this.fg,
    required this.muted,
    required this.line,
    required this.surface,
    required this.bg,
  });

  final ReligionModel religion;
  final Color accent, fg, muted, line, surface, bg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(religionProvider).selectedTexts;
    final selectedIds = selected.map((t) => t.id).toSet();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 36, height: 4,
          decoration: BoxDecoration(
            color: muted.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Choose texts',
                  style: GoogleFonts.cormorantGaramond(
                    color: fg, fontSize: 24,
                    fontWeight: FontWeight.w500, fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await ref.read(religionProvider.notifier).saveSelectedTexts();
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Done',
                    style: GoogleFonts.inter(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: line),
                ),
                clipBehavior: Clip.hardEdge,
                child: Column(
                  children: religion.texts.asMap().entries.map((e) {
                    final t = e.value;
                    final isSel = selectedIds.contains(t.id);
                    final isLast = e.key == religion.texts.length - 1;
                    return Column(
                      children: [
                        GestureDetector(
                          onTap: () => ref.read(religionProvider.notifier).toggleText(t),
                          child: Container(
                            color: Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Icon(Icons.menu_book_rounded, color: isSel ? accent : muted, size: 18),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.title,
                                        style: GoogleFonts.inter(
                                          color: isSel ? accent : fg,
                                          fontSize: 14,
                                          fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                                        ),
                                      ),
                                      if (t.description.isNotEmpty)
                                        Text(
                                          t.description,
                                          style: GoogleFonts.inter(color: muted, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  isSel ? Icons.check_circle_rounded : Icons.circle_outlined,
                                  color: isSel ? accent : muted.withValues(alpha: 0.4),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!isLast) Divider(height: 1, color: line),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 24),
      ],
    );
  }
}
