import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/religion_provider.dart';
import '../../providers/user_provider.dart';
import '../../data/report_repository.dart';

const _kCategories = [
  (id: 'inaccurate', label: 'Inaccurate answer'),
  (id: 'disrespect', label: 'Disrespectful response'),
  (id: 'inappropriate', label: 'Inappropriate content'),
  (id: 'translation', label: 'Translation error'),
  (id: 'bug', label: 'Bug or crash'),
  (id: 'account', label: 'Account / billing'),
  (id: 'other', label: 'Other'),
];

class ReportIssueScreen extends ConsumerStatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  ConsumerState<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends ConsumerState<ReportIssueScreen> {
  String _category = 'bug';
  final _descController = TextEditingController();
  final _emailController = TextEditingController();
  bool _anonymous = false;
  bool _includeDevInfo = true;
  bool _isSubmitting = false;
  bool _submitted = false;
  String? _reportRef;
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _appVersion = info.version);
    });
  }

  @override
  void dispose() {
    _descController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _descController.text.trim().length >= 10 && !_isSubmitting;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _isSubmitting = true);

    final uid = ref.read(userProvider).user?.uid;

    try {
      final refId = await ReportRepository.instance.submitReport(
        category: _category,
        description: _descController.text.trim(),
        anonymous: _anonymous,
        includeDevInfo: _includeDevInfo,
        contactEmail: _anonymous ? null : _emailController.text.trim(),
        uid: _anonymous ? null : uid,
        appVersion: _appVersion,
        platform: Platform.isIOS ? 'iOS' : 'Android',
      );
      if (mounted) setState(() { _submitted = true; _reportRef = refId; });
    } catch (_) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final religion = ref.watch(religionProvider).selectedReligion;
    final accent = religion != null
        ? ReligionColors.accent(religion.id)
        : AppColors.islamGreen;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.nightBg : AppColors.boneBg;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final line = isDark ? AppColors.nightLine : AppColors.boneLine;
    final surface = isDark ? AppColors.nightSurface : Colors.white;

    if (_submitted) {
      return _SuccessScreen(
        accent: accent, bg: bg, fg: fg, muted: muted, line: line,
        surface: surface, reportRef: _reportRef,
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          _Header(fg: fg, line: line),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IntroCard(accent: accent, fg: fg, muted: muted),
                  const SizedBox(height: 24),
                  _FieldLabel('What kind of issue?', muted: muted),
                  const SizedBox(height: 8),
                  _CategoryChips(
                    selected: _category,
                    accent: accent,
                    fg: fg,
                    line: line,
                    surface: surface,
                    onSelect: (id) => setState(() => _category = id),
                  ),
                  const SizedBox(height: 24),
                  _FieldLabel('Tell us what happened', muted: muted),
                  const SizedBox(height: 4),
                  Text(
                    'Specifics help — what you asked, what came back, what felt wrong.',
                    style: GoogleFonts.inter(
                      color: muted, fontSize: 11.5,
                      fontStyle: FontStyle.italic, height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _DescriptionField(
                    controller: _descController,
                    fg: fg, muted: muted, line: line, surface: surface,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 24),
                  _FieldLabel("What we'll include", muted: muted),
                  const SizedBox(height: 8),
                  _DevInfoCard(
                    includeDevInfo: _includeDevInfo,
                    accent: accent, bg: bg, fg: fg, muted: muted,
                    line: line, surface: surface,
                    onChanged: (v) => setState(() => _includeDevInfo = v),
                  ),
                  const SizedBox(height: 24),
                  _FieldLabel('How should we follow up?', muted: muted),
                  const SizedBox(height: 8),
                  _FollowUpCard(
                    anonymous: _anonymous,
                    emailController: _emailController,
                    accent: accent, fg: fg, muted: muted,
                    line: line, surface: surface,
                    onAnonChanged: (v) => setState(() => _anonymous = v),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'We only use this to reply about your report — never for marketing.',
                      style: GoogleFonts.inter(
                        color: muted, fontSize: 11.5,
                        fontStyle: FontStyle.italic, height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          _Footer(
            canSubmit: _canSubmit,
            isSubmitting: _isSubmitting,
            accent: accent, fg: fg, muted: muted, line: line, bg: bg,
            onCancel: () => Navigator.of(context).pop(),
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// Header
// ──────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.fg, required this.line});
  final Color fg, line;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
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
            Text(
              'Report an issue',
              style: GoogleFonts.cormorantGaramond(
                color: fg, fontSize: 26, fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────
// Intro card
// ──────────────────────────────────────────

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.accent, required this.fg, required this.muted});
  final Color accent, fg, muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [accent.withValues(alpha: 0.08), accent.withValues(alpha: 0.03)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
            child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We hear you.',
                  style: GoogleFonts.cormorantGaramond(
                    color: fg, fontSize: 19, fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic, height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Something didn't feel right? Tell us what happened. We read every report personally.",
                  style: GoogleFonts.inter(color: muted, fontSize: 12.5, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// Category chips
// ──────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.selected,
    required this.accent,
    required this.fg,
    required this.line,
    required this.surface,
    required this.onSelect,
  });
  final String selected;
  final Color accent, fg, line, surface;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: _kCategories.map((c) {
        final active = selected == c.id;
        return GestureDetector(
          onTap: () => onSelect(c.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: active ? accent : line),
              color: active ? accent : surface,
            ),
            child: Text(
              c.label,
              style: GoogleFonts.inter(
                color: active ? Colors.white : fg,
                fontSize: 12.5,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ──────────────────────────────────────────
// Description field
// ──────────────────────────────────────────

class _DescriptionField extends StatelessWidget {
  const _DescriptionField({
    required this.controller,
    required this.fg,
    required this.muted,
    required this.line,
    required this.surface,
    required this.onChanged,
  });
  final TextEditingController controller;
  final Color fg, muted, line, surface;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: controller,
            maxLines: 6,
            maxLength: 2000,
            onChanged: (_) => onChanged(),
            style: GoogleFonts.inter(color: fg, fontSize: 14, height: 1.5),
            decoration: InputDecoration(
              hintText: 'Describe what happened in your own words…',
              hintStyle: GoogleFonts.inter(color: muted, fontSize: 14),
              border: InputBorder.none,
              counterText: '',
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          Text(
            '${controller.text.length} / 2000',
            style: GoogleFonts.jetBrainsMono(color: muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// Device info card
// ──────────────────────────────────────────

class _DevInfoCard extends StatelessWidget {
  const _DevInfoCard({
    required this.includeDevInfo,
    required this.accent,
    required this.bg,
    required this.fg,
    required this.muted,
    required this.line,
    required this.surface,
    required this.onChanged,
  });
  final bool includeDevInfo;
  final Color accent, bg, fg, muted, line, surface;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: bg,
            ),
            child: Icon(Icons.info_outline_rounded, color: muted, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App version & device',
                  style: GoogleFonts.inter(
                    color: fg, fontSize: 13.5, fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'v1.0.0 · ${Platform.isIOS ? 'iOS' : 'Android'}',
                  style: GoogleFonts.jetBrainsMono(
                    color: muted, fontSize: 10.5, height: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Helps us reproduce the issue. No personal data is shared.',
                  style: GoogleFonts.inter(
                    color: muted, fontSize: 11.5,
                    fontStyle: FontStyle.italic, height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: includeDevInfo,
            onChanged: onChanged,
            activeThumbColor: accent,
            activeTrackColor: accent.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// Follow-up card (anonymous checkbox + email)
// ──────────────────────────────────────────

class _FollowUpCard extends StatelessWidget {
  const _FollowUpCard({
    required this.anonymous,
    required this.emailController,
    required this.accent,
    required this.fg,
    required this.muted,
    required this.line,
    required this.surface,
    required this.onAnonChanged,
  });
  final bool anonymous;
  final TextEditingController emailController;
  final Color accent, fg, muted, line, surface;
  final ValueChanged<bool> onAnonChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          GestureDetector(
            onTap: () => onAnonChanged(!anonymous),
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Send anonymously',
                          style: GoogleFonts.inter(
                            color: fg, fontSize: 14, fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "We won't see your name or account.",
                          style: GoogleFonts.inter(color: muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Checkbox(
                    value: anonymous,
                    onChanged: (v) => onAnonChanged(v ?? false),
                    activeColor: accent,
                    side: BorderSide(color: line, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: line),
          AnimatedOpacity(
            opacity: anonymous ? 0.4 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONTACT EMAIL (OPTIONAL)',
                    style: GoogleFonts.jetBrainsMono(
                      color: muted, fontSize: 9, letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: emailController,
                    enabled: !anonymous,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.inter(color: fg, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'you@example.com',
                      hintStyle: GoogleFonts.inter(color: muted, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// Sticky footer
// ──────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer({
    required this.canSubmit,
    required this.isSubmitting,
    required this.accent,
    required this.fg,
    required this.muted,
    required this.line,
    required this.bg,
    required this.onCancel,
    required this.onSubmit,
  });
  final bool canSubmit, isSubmitting;
  final Color accent, fg, muted, line, bg;
  final VoidCallback onCancel, onSubmit;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottomPad + 16),
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: line)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onCancel,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: line),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: fg, fontSize: 14, fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: canSubmit ? onSubmit : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: canSubmit ? accent : line,
                  boxShadow: canSubmit
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Send report',
                          style: GoogleFonts.inter(
                            color: canSubmit ? Colors.white : muted,
                            fontSize: 14, fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// Success screen
// ──────────────────────────────────────────

class _SuccessScreen extends StatelessWidget {
  const _SuccessScreen({
    required this.accent,
    required this.bg,
    required this.fg,
    required this.muted,
    required this.line,
    required this.surface,
    this.reportRef,
  });
  final Color accent, bg, fg, muted, line, surface;
  final String? reportRef;

  @override
  Widget build(BuildContext context) {
    final refDisplay = reportRef != null
        ? 'DD-${reportRef!.substring(0, 8).toUpperCase()}'
        : null;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: line),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded, size: 14, color: fg,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96, height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.1),
                    ),
                    child: Center(
                      child: Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, color: accent,
                        ),
                        child: const Icon(
                          Icons.check_rounded, color: Colors.white, size: 30,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Thank you\nfor telling us.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cormorantGaramond(
                      color: fg, fontSize: 30, fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic, height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      "We've received your report. A real person will read it. "
                      "If you shared your email, we'll get back to you there.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: muted, fontSize: 14, height: 1.6,
                      ),
                    ),
                  ),
                  if (refDisplay != null) ...[
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: surface,
                        border: Border.all(color: line),
                      ),
                      child: Text(
                        'REF · $refDisplay',
                        style: GoogleFonts.jetBrainsMono(
                          color: muted, fontSize: 10, letterSpacing: 1.6,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: accent,
                  ),
                  child: Center(
                    child: Text(
                      'Done',
                      style: GoogleFonts.inter(
                        color: Colors.white, fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
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

// ──────────────────────────────────────────
// Shared field label
// ──────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {required this.muted});
  final String text;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.jetBrainsMono(
        color: muted, fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w500,
      ),
    );
  }
}
