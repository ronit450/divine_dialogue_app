import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/reading_plan.dart';
import '../../core/models/religion.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/religion_provider.dart';
import '../../providers/reading_plan_provider.dart';
import '../../services/notification_service.dart';

void showReadingPlanSetupSheet(
  BuildContext context, {
  String? preselectedTextId,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? AppColors.nightBg : AppColors.boneBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _SetupSheet(preselectedTextId: preselectedTextId),
  );
}

class _SetupSheet extends ConsumerStatefulWidget {
  const _SetupSheet({this.preselectedTextId});
  final String? preselectedTextId;

  @override
  ConsumerState<_SetupSheet> createState() => _SetupSheetState();
}

class _SetupSheetState extends ConsumerState<_SetupSheet> {
  SacredTextModel? _selectedText;
  int? _durationDays = 365;
  bool _noDeadline = false;
  bool _isCustom = false;
  final _customCtrl = TextEditingController(text: '365');
  TimeOfDay _reminderTime = const TimeOfDay(hour: 6, minute: 30);
  bool _reminderEnabled = true;

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  int get _totalUnits =>
      TextReadingMeta.totalUnits(_selectedText?.id ?? 'guru_granth_sahib');

  int get _effectiveDays {
    if (_noDeadline) return 365;
    if (_isCustom) return int.tryParse(_customCtrl.text) ?? 365;
    return _durationDays ?? 365;
  }

  int get _unitsPerDay =>
      (_totalUnits / _effectiveDays).ceil().clamp(1, _totalUnits);

  int get _estimatedMins =>
      _unitsPerDay *
      TextReadingMeta.minutesPerUnit(_selectedText?.id ?? 'guru_granth_sahib');

  String get _unitLabel =>
      TextReadingMeta.unitLabel(_selectedText?.id ?? 'guru_granth_sahib');

  @override
  Widget build(BuildContext context) {
    final religionState = ref.watch(religionProvider);
    final religion = religionState.selectedReligion;
    final texts = religion?.texts ?? [];

    if (_selectedText == null && texts.isNotEmpty) {
      _selectedText = widget.preselectedTextId != null
          ? texts.firstWhere(
              (t) => t.id == widget.preselectedTextId,
              orElse: () => texts.first,
            )
          : texts.first;
    }

    if (_selectedText == null) return const SizedBox(height: 200);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final line = isDark ? AppColors.nightLine : AppColors.boneLine;
    final surface = isDark ? AppColors.nightSurface : Colors.white;
    final accent = religion != null
        ? ReligionColors.accent(religion.id)
        : AppColors.sikhNavy;

    final chipSelection = _noDeadline
        ? null
        : _isCustom
            ? -1
            : _durationDays;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: muted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'NEW READING PLAN',
                  style: GoogleFonts.jetBrainsMono(
                    color: accent,
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(Icons.close_rounded, color: muted, size: 20),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
            child: Text(
              'One day at a time.',
              style: GoogleFonts.cormorantGaramond(
                color: fg,
                fontSize: 28,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('BOOK', muted),
                  const SizedBox(height: 8),
                  _BookSelector(
                    texts: texts,
                    selected: _selectedText!,
                    fg: fg,
                    muted: muted,
                    line: line,
                    surface: surface,
                    accent: accent,
                    onChanged: (t) => setState(() => _selectedText = t),
                  ),
                  const SizedBox(height: 20),
                  _sectionLabel('FINISH IN', muted),
                  const SizedBox(height: 8),
                  _DurationChips(
                    selection: chipSelection,
                    onSelect: (days, isCustom, noDeadline) => setState(() {
                      _noDeadline = noDeadline;
                      _isCustom = isCustom;
                      _durationDays = days;
                    }),
                    accent: accent,
                    fg: fg,
                    line: line,
                    surface: surface,
                  ),
                  if (_isCustom) ...[
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: line),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 2),
                      child: Row(
                        children: [
                          Text('Days:',
                              style: GoogleFonts.inter(
                                  color: muted, fontSize: 13)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _customCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              style:
                                  GoogleFonts.inter(color: fg, fontSize: 15),
                              decoration:
                                  const InputDecoration(border: InputBorder.none),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: accent.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.auto_stories_outlined,
                            color: accent, size: 16),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your daily portion',
                              style: GoogleFonts.inter(
                                  color: muted, fontSize: 11),
                            ),
                            Text(
                              '$_unitsPerDay $_unitLabel · ≈$_estimatedMins min',
                              style: GoogleFonts.inter(
                                color: fg,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sectionLabel('DAILY REMINDER', muted),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: line),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            color: muted, size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickTime(context, accent),
                            child: Text(
                              _formatTime(_reminderTime),
                              style: GoogleFonts.inter(
                                color: fg,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: _reminderEnabled,
                          onChanged: (v) =>
                              setState(() => _reminderEnabled = v),
                          activeTrackColor: accent,
                          activeThumbColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: GestureDetector(
              onTap: _submit,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Begin Day 1',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, Color muted) => Text(
        text,
        style: GoogleFonts.jetBrainsMono(
            color: muted, fontSize: 9, letterSpacing: 1.5),
      );

  String _formatTime(TimeOfDay t) {
    final h = t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour:$m $period';
  }

  Future<void> _pickTime(BuildContext context, Color accent) async {
    final result = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: accent),
          timePickerTheme: TimePickerThemeData(
            backgroundColor:
                Theme.of(ctx).brightness == Brightness.dark
                    ? AppColors.nightSurface
                    : Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (result != null) setState(() => _reminderTime = result);
  }

  Future<void> _submit() async {
    final text = _selectedText;
    final religion = ref.read(religionProvider).selectedReligion;
    if (text == null || religion == null) return;

    final existing = ref.read(readingPlanProvider).planForText(text.id);
    if (existing != null) {
      if (mounted) _showAlreadyExists(text.title, religion.id);
      return;
    }

    // Request permission while sheet is still mounted so the system dialog
    // has a valid Activity context — calling it after pop can silently fail.
    bool granted = false;
    if (_reminderEnabled) {
      granted = await NotificationService.instance.requestPermission();
    }

    final plan = ReadingPlan.create(
      textId: text.id,
      textTitle: text.title,
      religionId: religion.id,
      durationDays: _noDeadline ? null : _effectiveDays,
      unitsPerDay: _unitsPerDay,
      reminderHour: _reminderTime.hour,
      reminderMinute: _reminderTime.minute,
      reminderEnabled: _reminderEnabled,
    );

    ref.read(readingPlanProvider.notifier).addPlan(plan);

    if (_reminderEnabled && granted) {
      await NotificationService.instance.schedulePlanReminder(
        planId: plan.id,
        textTitle: plan.textTitle,
        hour: plan.reminderHour,
        minute: plan.reminderMinute,
        dayNumber: plan.dayNumber,
        durationDays: plan.durationDays,
        unitsPerDay: plan.unitsPerDay,
        unitLabel: plan.unitLabel,
        estimatedMins: plan.estimatedMinutesPerDay,
      );
      // Ask Android to exempt the app from battery optimization so
      // exact alarms fire reliably on OEM phones (Xiaomi, Samsung, etc.)
      await NotificationService.instance.requestBatteryExemption();
    }

    if (mounted) Navigator.of(context).pop();
  }

  void _showAlreadyExists(String title, String religionId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.nightBg : AppColors.boneBg;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final accent = ReligionColors.accent(religionId);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('ALREADY ACTIVE', style: GoogleFonts.jetBrainsMono(
              color: accent, fontSize: 9, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            Text('Plan already exists.', style: GoogleFonts.cormorantGaramond(
              color: fg, fontSize: 24, fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic)),
            const SizedBox(height: 6),
            Text('You already have an active reading plan for $title.',
              style: GoogleFonts.inter(color: muted, fontSize: 13)),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => Navigator.of(ctx).pop(),
              child: Container(
                width: double.infinity, height: 50,
                decoration: BoxDecoration(
                  color: accent, borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text('Got it', style: GoogleFonts.inter(
                  color: Colors.white, fontSize: 15,
                  fontWeight: FontWeight.w600))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookSelector extends StatelessWidget {
  const _BookSelector({
    required this.texts,
    required this.selected,
    required this.fg,
    required this.muted,
    required this.line,
    required this.surface,
    required this.accent,
    required this.onChanged,
  });

  final List<SacredTextModel> texts;
  final SacredTextModel selected;
  final Color fg, muted, line, surface, accent;
  final ValueChanged<SacredTextModel> onChanged;

  String _abbrev(String title) {
    final words = title.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words[0].substring(0, words[0].length.clamp(0, 3)).toUpperCase();
    }
    return words.take(2).map((w) => w[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: line),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  _abbrev(selected.title),
                  style: GoogleFonts.jetBrainsMono(
                    color: accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selected.title,
                    style: GoogleFonts.inter(
                        color: fg, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    selected.description,
                    style: GoogleFonts.inter(color: muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: muted, size: 20),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.nightBg : AppColors.boneBg;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Choose a book',
              style: GoogleFonts.cormorantGaramond(
                color: fg,
                fontSize: 22,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            ...texts.map((t) {
              final isSel = t.id == selected.id;
              return GestureDetector(
                onTap: () {
                  onChanged(t);
                  Navigator.of(ctx).pop();
                },
                child: Container(
                  width: double.infinity,
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: isSel ? 0.15 : 0.07),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            _abbrev(t.title),
                            style: GoogleFonts.jetBrainsMono(
                              color: accent,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
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
                                fontWeight: isSel
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                            Text(
                              t.description,
                              style:
                                  GoogleFonts.inter(color: muted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      if (isSel)
                        Icon(Icons.check_rounded, color: accent, size: 18),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _DurationChips extends StatelessWidget {
  const _DurationChips({
    required this.selection,
    required this.onSelect,
    required this.accent,
    required this.fg,
    required this.line,
    required this.surface,
  });

  // null = no deadline, -1 = custom, else days
  final int? selection;
  final void Function(int? days, bool isCustom, bool noDeadline) onSelect;
  final Color accent, fg, line, surface;

  @override
  Widget build(BuildContext context) {
    final options = [
      (label: '90 days', days: 90, isCustom: false, noDeadline: false),
      (label: '6 months', days: 180, isCustom: false, noDeadline: false),
      (label: '1 year', days: 365, isCustom: false, noDeadline: false),
      (label: '2 years', days: 730, isCustom: false, noDeadline: false),
      (label: 'Custom', days: -1, isCustom: true, noDeadline: false),
      (label: 'No deadline', days: null, isCustom: false, noDeadline: true),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = opt.noDeadline
            ? selection == null
            : opt.isCustom
                ? selection == -1
                : selection == opt.days;

        return GestureDetector(
          onTap: () => onSelect(opt.days, opt.isCustom, opt.noDeadline),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? accent : surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? accent : line),
            ),
            child: Text(
              opt.label,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : fg,
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
