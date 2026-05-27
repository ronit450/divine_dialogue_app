import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/religion_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/religion.dart';
import '../../core/l10n/app_strings.dart';
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
    final s = AppStrings.of(context);

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
                          s.settings,
                          style: s.isUrdu
                              ? GoogleFonts.notoNastaliqUrdu(
                                  color: fg, fontSize: 28, fontWeight: FontWeight.w500,
                                  height: 1.5,
                                )
                              : GoogleFonts.cormorantGaramond(
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
                            displayName.isEmpty ? s.guest : displayName,
                            style: GoogleFonts.cormorantGaramond(
                              color: fg, fontSize: 22, fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            religion?.name ?? s.noTraditionSelected,
                            style: GoogleFonts.inter(color: muted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel(label: s.sectionAccount, muted: muted, isUrdu: s.isUrdu),
                    const SizedBox(height: 10),
                    _SurfaceCard(
                      surface: surface,
                      line: line,
                      isDark: isDark,
                      child: Column(
                        children: [
                          _ActionRow(
                            icon: Icons.person_outline_rounded,
                            label: s.editProfile,
                            fg: fg,
                            muted: muted,
                            line: line,
                            isUrdu: s.isUrdu,
                            onTap: () => context.go('/profile-setup'),
                          ),
                          Divider(height: 1, color: line),
                          _ActionRow(
                            icon: Icons.logout_rounded,
                            label: s.signOut,
                            fg: Colors.red.shade400,
                            muted: muted,
                            line: line,
                            isUrdu: s.isUrdu,
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
                    _SectionLabel(label: s.sectionPractice, muted: muted, isUrdu: s.isUrdu),
                    const SizedBox(height: 10),
                    _SurfaceCard(
                      surface: surface,
                      line: line,
                      isDark: isDark,
                      child: _ActionRow(
                        icon: Icons.menu_book_rounded,
                        label: s.readingPlan,
                        fg: fg,
                        muted: muted,
                        line: line,
                        isUrdu: s.isUrdu,
                        onTap: () => context.push('/reading-plans'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel(label: s.sectionTradition, muted: muted, isUrdu: s.isUrdu),
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
                            isUrdu: s.isUrdu,
                            urduName: s.religionName(r.id, r.name),
                            onTap: () => ref.read(religionProvider.notifier).changeReligion(r),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (religion != null && religion.texts.isNotEmpty) ...[
                      _SectionLabel(label: s.sectionTexts, muted: muted, isUrdu: s.isUrdu),
                      const SizedBox(height: 10),
                      _SurfaceCard(
                        surface: surface,
                        line: line,
                        isDark: isDark,
                        child: _ActionRow(
                          icon: Icons.menu_book_rounded,
                          label: s.chooseTexts,
                          fg: fg,
                          muted: muted,
                          line: line,
                          isUrdu: s.isUrdu,
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
                    _SectionLabel(label: s.sectionGeneral, muted: muted, isUrdu: s.isUrdu),
                    const SizedBox(height: 10),
                    _SurfaceCard(
                      surface: surface,
                      line: line,
                      isDark: isDark,
                      child: Column(
                        children: [
                          _ToggleRow(
                            icon: Icons.dark_mode_rounded,
                            label: s.darkMode,
                            value: themeMode == ThemeMode.dark,
                            accent: accent,
                            fg: fg,
                            muted: muted,
                            isUrdu: s.isUrdu,
                            onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                          ),
                          Divider(height: 1, color: line),
                          _ActionRow(
                            icon: Icons.language_rounded,
                            label: s.language,
                            fg: fg,
                            muted: muted,
                            line: line,
                            isUrdu: s.isUrdu,
                            trailing: s.languageCurrentValue,
                            onTap: () => _showLanguageSheet(
                              context: context,
                              accent: accent,
                              fg: fg,
                              muted: muted,
                              line: line,
                              surface: surface,
                              bg: bg,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel(label: s.sectionDeveloper, muted: muted, isUrdu: s.isUrdu),
                    const SizedBox(height: 10),
                    _SurfaceCard(
                      surface: surface,
                      line: line,
                      isDark: isDark,
                      child: Column(
                        children: [
                          _ActionRow(
                            icon: Icons.people_outline_rounded,
                            label: s.meetTheTeam,
                            fg: fg,
                            muted: muted,
                            line: line,
                            isUrdu: s.isUrdu,
                            onTap: () => context.push('/developers'),
                          ),
                          Divider(height: 1, color: line),
                          _ActionRow(
                            icon: Icons.flag_outlined,
                            label: s.reportAnIssue,
                            fg: fg,
                            muted: muted,
                            line: line,
                            isUrdu: s.isUrdu,
                            onTap: () => context.push('/report-issue'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel(label: s.sectionAbout, muted: muted, isUrdu: s.isUrdu),
                    const SizedBox(height: 10),
                    _SurfaceCard(
                      surface: surface,
                      line: line,
                      isDark: isDark,
                      child: Column(
                        children: [
                          _InfoRow(label: s.version, value: '1.0.0', fg: fg, muted: muted, isUrdu: s.isUrdu),
                          Divider(height: 1, color: line),
                          _InfoRow(
                            label: s.sectionTradition,
                            value: s.religions(religionState.religions.length),
                            fg: fg,
                            muted: muted,
                            isUrdu: s.isUrdu,
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
  const _SectionLabel({required this.label, required this.muted, this.isUrdu = false});
  final String label;
  final Color muted;
  final bool isUrdu;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: isUrdu
          ? GoogleFonts.notoNastaliqUrdu(
              color: muted, fontSize: 13, fontWeight: FontWeight.w600,
            )
          : GoogleFonts.jetBrainsMono(
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
    this.isUrdu = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final Color fg;
  final Color muted;
  final Color line;
  final VoidCallback onTap;
  final bool isUrdu;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final labelStyle = isUrdu
        ? GoogleFonts.notoNastaliqUrdu(color: fg, fontSize: 16, fontWeight: FontWeight.w500, height: 1.5)
        : GoogleFonts.inter(color: fg, fontSize: 14);
    final trailingStyle = isUrdu
        ? GoogleFonts.notoNastaliqUrdu(color: muted, fontSize: 14, height: 1.5)
        : GoogleFonts.inter(color: muted, fontSize: 13);

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
              child: Text(label, style: labelStyle),
            ),
            if (trailing != null) ...[
              Text(trailing!, style: trailingStyle),
              const SizedBox(width: 4),
            ],
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
    this.isUrdu = false,
    this.urduName,
  });

  final ReligionModel religion;
  final Color accent;
  final bool isSelected;
  final bool showDivider;
  final Color line;
  final Color fg;
  final VoidCallback onTap;
  final bool isUrdu;
  final String? urduName;

  @override
  Widget build(BuildContext context) {
    final displayName = (isUrdu && urduName != null && urduName!.isNotEmpty)
        ? urduName!
        : religion.name;
    final nameStyle = isUrdu
        ? GoogleFonts.notoNastaliqUrdu(
            color: isSelected ? accent : fg,
            fontSize: 17,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            height: 1.5,
          )
        : GoogleFonts.inter(
            color: isSelected ? accent : fg,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          );

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
                Expanded(child: Text(displayName, style: nameStyle)),
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
    this.isUrdu = false,
  });

  final IconData icon;
  final String label;
  final bool value;
  final Color accent;
  final Color fg;
  final Color muted;
  final ValueChanged<bool> onChanged;
  final bool isUrdu;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: muted, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: isUrdu
                  ? GoogleFonts.notoNastaliqUrdu(color: fg, fontSize: 16, height: 1.5)
                  : GoogleFonts.inter(color: fg, fontSize: 14),
            ),
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
    this.isUrdu = false,
  });

  final String label;
  final String value;
  final Color fg;
  final Color muted;
  final bool isUrdu;

  @override
  Widget build(BuildContext context) {
    final style = isUrdu
        ? GoogleFonts.notoNastaliqUrdu(fontSize: 15, height: 1.5)
        : GoogleFonts.inter(fontSize: 14);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style.copyWith(color: fg)),
          Text(value, style: style.copyWith(color: muted)),
        ],
      ),
    );
  }
}

void _showLanguageSheet({
  required BuildContext context,
  required Color accent,
  required Color fg,
  required Color muted,
  required Color line,
  required Color surface,
  required Color bg,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: bg,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _LanguageSheet(
      accent: accent, fg: fg, muted: muted, line: line, surface: surface, bg: bg,
    ),
  );
}

class _LanguageSheet extends ConsumerStatefulWidget {
  const _LanguageSheet({
    required this.accent,
    required this.fg,
    required this.muted,
    required this.line,
    required this.surface,
    required this.bg,
  });

  final Color accent, fg, muted, line, surface, bg;

  @override
  ConsumerState<_LanguageSheet> createState() => _LanguageSheetState();
}

class _LanguageSheetState extends ConsumerState<_LanguageSheet> {
  late String _selectedCode;

  @override
  void initState() {
    super.initState();
    _selectedCode = ref.read(localeProvider).locale.languageCode;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    final langs = [
      (
        code: 'en',
        name: 'English',
        native: 'English',
        sample: 'Indeed, with hardship comes ease.',
      ),
      (
        code: 'ur',
        name: 'Urdu',
        native: 'اردو',
        sample: 'بے شک ہر مشکل کے ساتھ آسانی ہے۔',
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 36, height: 4,
          decoration: BoxDecoration(
            color: widget.muted.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  s.chooseLanguage,
                  style: s.isUrdu
                      ? GoogleFonts.notoNastaliqUrdu(
                          color: widget.fg, fontSize: 26, fontWeight: FontWeight.w500, height: 1.5,
                        )
                      : GoogleFonts.cormorantGaramond(
                          color: widget.fg, fontSize: 24,
                          fontWeight: FontWeight.w500, fontStyle: FontStyle.italic,
                        ),
                ),
              ),
              Text(
                '2 · AVAILABLE',
                style: GoogleFonts.jetBrainsMono(
                  color: widget.muted, fontSize: 9.5, letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Text(
            s.languageSheetNote,
            style: s.isUrdu
                ? GoogleFonts.notoNastaliqUrdu(
                    color: widget.muted, fontSize: 14, height: 1.7,
                  )
                : GoogleFonts.inter(color: widget.muted, fontSize: 13, height: 1.55),
            textAlign: s.isUrdu ? TextAlign.right : TextAlign.left,
          ),
        ),
        for (final lang in langs) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCode = lang.code),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _selectedCode == lang.code
                      ? widget.accent.withValues(alpha: 0.08)
                      : widget.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _selectedCode == lang.code ? widget.accent : widget.line,
                    width: _selectedCode == lang.code ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedCode == lang.code ? widget.accent : widget.line,
                          width: 1.5,
                        ),
                      ),
                      child: _selectedCode == lang.code
                          ? Center(
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: widget.accent,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                lang.name,
                                style: GoogleFonts.inter(
                                  fontSize: 15, fontWeight: FontWeight.w600,
                                  color: widget.fg,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                lang.native,
                                style: lang.code == 'ur'
                                    ? GoogleFonts.notoNastaliqUrdu(
                                        fontSize: 18, color: widget.fg, height: 1.5,
                                      )
                                    : GoogleFonts.cormorantGaramond(
                                        fontSize: 15, color: widget.fg, fontStyle: FontStyle.italic,
                                      ),
                                textDirection: lang.code == 'ur'
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            lang.sample,
                            style: lang.code == 'ur'
                                ? GoogleFonts.notoNastaliqUrdu(
                                    fontSize: 15, color: widget.muted, height: 1.7,
                                  )
                                : GoogleFonts.cormorantGaramond(
                                    fontSize: 13.5, color: widget.muted,
                                    fontStyle: FontStyle.italic,
                                  ),
                            textDirection: lang.code == 'ur'
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        Padding(
          padding: EdgeInsets.fromLTRB(
            20, 6, 20, MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: widget.line),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    s.cancel,
                    style: s.isUrdu
                        ? GoogleFonts.notoNastaliqUrdu(color: widget.fg, fontSize: 16, height: 1.5)
                        : GoogleFonts.inter(color: widget.fg, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () async {
                    await ref.read(localeProvider.notifier).setLocale(Locale(_selectedCode));
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    s.done,
                    style: s.isUrdu
                        ? GoogleFonts.notoNastaliqUrdu(color: Colors.white, fontSize: 16, height: 1.5)
                        : GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
