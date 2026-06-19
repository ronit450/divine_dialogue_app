import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/religion_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/font_scale_provider.dart';
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
    final authState = ref.watch(authProvider);
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
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
                          if (authState.email != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              authState.email!,
                              style: GoogleFonts.jetBrainsMono(
                                color: muted, fontSize: 11, letterSpacing: 0.3,
                              ),
                            ),
                          ],
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
                          if (authState.email != null) ...[
                            _InfoRow(
                              label: 'Signed in as',
                              value: authState.email!,
                              fg: fg,
                              muted: muted,
                            ),
                            Divider(height: 1, color: line),
                          ],
                          _ActionRow(
                            icon: Icons.person_outline_rounded,
                            label: 'Edit profile',
                            fg: fg,
                            muted: muted,
                            line: line,
                            onTap: () => context.push('/profile-setup', extra: {'edit': true}),
                          ),
                          if (FirebaseAuth.instance.currentUser?.providerData
                              .any((p) => p.providerId == 'password') ?? false) ...[
                            Divider(height: 1, color: line),
                            _ActionRow(
                              icon: Icons.lock_outline_rounded,
                              label: 'Change password',
                              fg: fg,
                              muted: muted,
                              line: line,
                              onTap: () => _showChangePasswordSheet(
                                context: context,
                                ref: ref,
                                accent: accent,
                                fg: fg,
                                muted: muted,
                                line: line,
                                surface: surface,
                                isDark: isDark,
                              ),
                            ),
                          ],
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
                      child: Column(
                        children: [
                          _ActionRow(
                            icon: Icons.bookmark_border_rounded,
                            label: 'Saved verses',
                            fg: fg,
                            muted: muted,
                            line: line,
                            onTap: () => context.push('/saved-verses'),
                          ),
                          Divider(height: 1, color: line),
                          _ActionRow(
                            icon: Icons.menu_book_rounded,
                            label: 'Reading plan',
                            fg: fg,
                            muted: muted,
                            line: line,
                            onTap: () => context.push('/reading-plans'),
                          ),
                        ],
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
                      child: Column(
                        children: [
                          _ToggleRow(
                            icon: Icons.dark_mode_rounded,
                            label: 'Dark mode',
                            value: themeMode == ThemeMode.dark,
                            accent: accent,
                            fg: fg,
                            muted: muted,
                            onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                          ),
                          Divider(height: 1, color: line),
                          _ActionRow(
                            icon: Icons.text_fields_rounded,
                            label: 'Change font',
                            fg: fg,
                            muted: muted,
                            line: line,
                            onTap: () {
                              if (!context.mounted) return;
                              _showFontSizePicker(
                                context: context,
                                accent: accent,
                                fg: fg,
                                muted: muted,
                                isDark: isDark,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel(label: 'HELP', muted: muted),
                    const SizedBox(height: 10),
                    _SurfaceCard(
                      surface: surface,
                      line: line,
                      isDark: isDark,
                      child: _ActionRow(
                        icon: Icons.auto_stories_rounded,
                        label: 'Feature Guide',
                        fg: fg,
                        muted: muted,
                        line: line,
                        onTap: () => context.push('/guide'),
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

void _showChangePasswordSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Color accent,
  required Color fg,
  required Color muted,
  required Color line,
  required Color surface,
  required bool isDark,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _ChangePasswordSheet(
      ref: ref,
      accent: accent,
      fg: fg,
      muted: muted,
      line: line,
      surface: surface,
      isDark: isDark,
    ),
  );
}

void _showFontSizePicker({
  required BuildContext context,
  required Color accent,
  required Color fg,
  required Color muted,
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
    builder: (ctx) => _FontSizeSheet(
      accent: accent,
      fg: fg,
      muted: muted,
    ),
  );
}

class _FontSizeSheet extends ConsumerWidget {
  const _FontSizeSheet({
    required this.accent,
    required this.fg,
    required this.muted,
  });

  final Color accent, fg, muted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(fontScaleProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 0, 24, MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: muted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),
          MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
            child: Text(
              'Aa',
              style: GoogleFonts.cormorantGaramond(
                color: fg,
                fontSize: 36 * current.factor,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _FontScaleTrack(
            current: current,
            accent: accent,
            muted: muted,
            fg: fg,
            onSelect: (scale) => ref.read(fontScaleProvider.notifier).set(scale),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _FontScaleTrack extends StatelessWidget {
  const _FontScaleTrack({
    required this.current,
    required this.accent,
    required this.muted,
    required this.fg,
    required this.onSelect,
  });

  final FontScale current;
  final Color accent, muted, fg;
  final ValueChanged<FontScale> onSelect;

  @override
  Widget build(BuildContext context) {
    final scales = FontScale.values;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return SizedBox(
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 0,
                right: 0,
                child: Container(
                  height: 1.5,
                  color: muted.withValues(alpha: 0.25),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: scales.asMap().entries.map((e) {
                  final scale = e.value;
                  final isActive = scale == current;
                  return GestureDetector(
                    onTap: () => onSelect(scale),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: width / scales.length,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isActive ? 14 : 10,
                            height: isActive ? 14 : 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive ? accent : Colors.transparent,
                              border: Border.all(
                                color: isActive ? accent : muted.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            scale.label,
                            style: GoogleFonts.jetBrainsMono(
                              color: isActive ? accent : muted,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet({
    required this.ref,
    required this.accent,
    required this.fg,
    required this.muted,
    required this.line,
    required this.surface,
    required this.isDark,
  });

  final WidgetRef ref;
  final Color accent, fg, muted, line, surface;
  final bool isDark;

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _success = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentCtrl.text;
    final newPw = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    if (current.isEmpty || newPw.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (newPw.length < 6) {
      setState(() => _error = 'New password must be at least 6 characters.');
      return;
    }
    if (newPw != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      await widget.ref.read(authProvider.notifier).changePassword(current, newPw);
      if (mounted) setState(() { _loading = false; _success = true; });
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _friendlyError(e.toString());
        });
      }
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('wrong-password') || raw.contains('invalid-credential')) {
      return 'Current password is incorrect.';
    }
    if (raw.contains('weak-password')) return 'New password is too weak.';
    if (raw.contains('requires-recent-login')) {
      return 'Please sign out and sign in again before changing your password.';
    }
    if (raw.contains('network-request-failed')) return 'No internet connection.';
    return raw.replaceAll('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 0, 24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: widget.muted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Change password',
            style: GoogleFonts.cormorantGaramond(
              color: widget.fg,
              fontSize: 28,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter your current password and choose a new one.',
            style: GoogleFonts.inter(color: widget.muted, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          if (_success) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: widget.accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Password updated successfully.',
                      style: GoogleFonts.inter(color: widget.fg, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ] else ...[
            _PasswordField(
              label: 'Current password',
              controller: _currentCtrl,
              obscure: _obscureCurrent,
              fg: widget.fg,
              muted: widget.muted,
              line: widget.line,
              accent: widget.accent,
              onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 4),
            _PasswordField(
              label: 'New password',
              controller: _newCtrl,
              obscure: _obscureNew,
              fg: widget.fg,
              muted: widget.muted,
              line: widget.line,
              accent: widget.accent,
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 4),
            _PasswordField(
              label: 'Confirm new password',
              controller: _confirmCtrl,
              obscure: _obscureConfirm,
              fg: widget.fg,
              muted: widget.muted,
              line: widget.line,
              accent: widget.accent,
              onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _loading ? null : _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: GoogleFonts.inter(
                  color: Colors.red.shade400,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: widget.accent,
                  shape: const StadiumBorder(),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Update password',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.fg,
    required this.muted,
    required this.line,
    required this.accent,
    required this.onToggle,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final bool obscure;
  final Color fg, muted, line, accent;
  final VoidCallback onToggle;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: line))),
      padding: const EdgeInsets.symmetric(vertical: 8),
      margin: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(
              color: muted,
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  textInputAction: textInputAction,
                  onSubmitted: onSubmitted,
                  style: GoogleFonts.inter(color: fg, fontSize: 17, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '••••••••••',
                    hintStyle: GoogleFonts.inter(
                      color: muted.withValues(alpha: 0.5),
                      fontSize: 17,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onToggle,
                child: Text(
                  obscure ? 'Show' : 'Hide',
                  style: GoogleFonts.inter(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
