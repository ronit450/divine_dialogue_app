import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/reading_plan.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/reading_plan_provider.dart';
import '../../services/notification_service.dart';

class PlanDetailScreen extends ConsumerWidget {
  const PlanDetailScreen({super.key, required this.planId});
  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref
        .watch(readingPlanProvider)
        .plans
        .where((p) => p.id == planId)
        .firstOrNull;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.nightBg : AppColors.boneBg;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final line = isDark ? AppColors.nightLine : AppColors.boneLine;
    final surface = isDark ? AppColors.nightSurface : Colors.white;

    if (plan == null) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(child: Text('Plan not found', style: GoogleFonts.inter(color: muted))),
      );
    }

    final accent = ReligionColors.accent(plan.religionId);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: line)),
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            size: 14, color: fg),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Settings',
                        style: GoogleFonts.inter(color: muted, fontSize: 13)),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'READING PLAN',
                      style: GoogleFonts.jetBrainsMono(
                          color: accent, fontSize: 9, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${plan.textTitle} in ${plan.durationLabel}',
                      style: GoogleFonts.cormorantGaramond(
                        color: fg,
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Stats — clean 3-column layout, no dot grid
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: line),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _StatChip(
                                  value: '${plan.streak}',
                                  label: 'DAY\nSTREAK',
                                  icon: '🔥',
                                  accent: accent,
                                  fg: fg,
                                  muted: muted),
                              Container(
                                  width: 1,
                                  height: 40,
                                  color: line,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 8)),
                              _StatChip(
                                  value: '${plan.percentRead}%',
                                  label: 'READ',
                                  icon: null,
                                  accent: accent,
                                  fg: fg,
                                  muted: muted),
                              Container(
                                  width: 1,
                                  height: 40,
                                  color: line,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 8)),
                              _StatChip(
                                  value: plan.durationDays != null
                                      ? '${plan.totalDaysCompleted}/${plan.durationDays}'
                                      : '${plan.totalDaysCompleted}',
                                  label: 'DAYS\nDONE',
                                  icon: null,
                                  accent: accent,
                                  fg: fg,
                                  muted: muted),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: plan.progressFraction,
                              backgroundColor:
                                  accent.withValues(alpha: 0.12),
                              valueColor: AlwaysStoppedAnimation(accent),
                              minHeight: 4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Started ${_fmtDate(plan.startDate)}',
                                  style: GoogleFonts.inter(
                                      color: muted, fontSize: 11)),
                              if (plan.daysLeft >= 0)
                                Text('${plan.daysLeft} days left',
                                    style: GoogleFonts.inter(
                                        color: muted, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _sectionLabel('PLAN', muted),
                    const SizedBox(height: 8),
                    _SurfaceCard(
                      surface: surface,
                      line: line,
                      child: Column(
                        children: [
                          // Book — non-editable
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Icon(Icons.menu_book_outlined,
                                    color: muted, size: 17),
                                const SizedBox(width: 12),
                                Text('Book',
                                    style: GoogleFonts.inter(
                                        color: fg, fontSize: 14)),
                                const Spacer(),
                                Flexible(
                                  child: Text(plan.textTitle,
                                      style: GoogleFonts.inter(
                                          color: muted, fontSize: 13),
                                      textAlign: TextAlign.right),
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: line),
                          // Duration — editable
                          GestureDetector(
                            onTap: () => _showDurationPicker(
                                context, ref, plan, accent, fg, muted,
                                line, surface),
                            child: Container(
                              color: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined,
                                      color: muted, size: 17),
                                  const SizedBox(width: 12),
                                  Text('Duration',
                                      style: GoogleFonts.inter(
                                          color: fg, fontSize: 14)),
                                  const Spacer(),
                                  Text(plan.durationLabel,
                                      style: GoogleFonts.inter(
                                          color: muted, fontSize: 13)),
                                  const SizedBox(width: 4),
                                  Icon(Icons.chevron_right_rounded,
                                      color: muted, size: 16),
                                ],
                              ),
                            ),
                          ),
                          Divider(height: 1, color: line),
                          // Reminder — editable
                          GestureDetector(
                            onTap: () =>
                                _showTimePicker(context, ref, plan, accent),
                            child: Container(
                              color: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time_rounded,
                                      color: muted, size: 17),
                                  const SizedBox(width: 12),
                                  Text('Daily reminder',
                                      style: GoogleFonts.inter(
                                          color: fg, fontSize: 14)),
                                  const Spacer(),
                                  Text(plan.formattedReminderTime,
                                      style: GoogleFonts.inter(
                                          color: muted, fontSize: 13)),
                                  const SizedBox(width: 4),
                                  Icon(Icons.chevron_right_rounded,
                                      color: muted, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _sectionLabel('STREAK', muted),
                    const SizedBox(height: 8),
                    _SurfaceCard(
                      surface: surface,
                      line: line,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: Row(
                              children: [
                                Icon(Icons.shield_outlined,
                                    color: muted, size: 17),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Streak freezes',
                                          style: GoogleFonts.inter(
                                              color: fg, fontSize: 14)),
                                      Text(
                                          'Auto-skip up to 2 missed days a month',
                                          style: GoogleFonts.inter(
                                              color: muted, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Switch.adaptive(
                                  value: plan.streakFreezes,
                                  onChanged: (v) =>
                                      ref
                                          .read(readingPlanProvider.notifier)
                                          .updateStreakSettings(
                                              plan.id, v, plan.catchUpMode),
                                  activeTrackColor: accent,
                                  activeThumbColor: Colors.white,
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: line),
                          GestureDetector(
                            onTap: () =>
                                ref
                                    .read(readingPlanProvider.notifier)
                                    .updateStreakSettings(plan.id,
                                        plan.streakFreezes, !plan.catchUpMode),
                            child: Container(
                              color: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Icon(Icons.replay_rounded,
                                      color: muted, size: 17),
                                  const SizedBox(width: 12),
                                  Text('Catch-up mode',
                                      style: GoogleFonts.inter(
                                          color: fg, fontSize: 14)),
                                  const Spacer(),
                                  Text(plan.catchUpMode ? 'On' : 'Off',
                                      style: GoogleFonts.inter(
                                          color: muted, fontSize: 13)),
                                  const SizedBox(width: 4),
                                  Icon(Icons.chevron_right_rounded,
                                      color: muted, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    GestureDetector(
                      onTap: () => _confirmDelete(context, ref, plan.id, accent),
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Center(
                          child: Text('End plan',
                              style: GoogleFonts.inter(
                                color: Colors.red.shade500,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              )),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, Color muted) => Text(
        text,
        style: GoogleFonts.jetBrainsMono(
            color: muted, fontSize: 9, letterSpacing: 1.5),
      );

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  Future<void> _showDurationPicker(
    BuildContext context,
    WidgetRef ref,
    ReadingPlan plan,
    Color accent,
    Color fg,
    Color muted,
    Color line,
    Color surface,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.nightBg : AppColors.boneBg;

    final options = [
      (label: '90 days', days: 90 as int?),
      (label: '6 months', days: 180 as int?),
      (label: '1 year', days: 365 as int?),
      (label: '2 years', days: 730 as int?),
      (label: 'No deadline', days: null as int?),
    ];

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Change duration',
                style: GoogleFonts.cormorantGaramond(
                    color: fg,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic)),
            const SizedBox(height: 16),
            ...options.map((opt) {
              final isSelected = opt.days == plan.durationDays;
              return GestureDetector(
                onTap: () {
                  final days = opt.days ?? 365;
                  final upd =
                      (plan.totalUnits / days).ceil().clamp(1, plan.totalUnits);
                  ref
                      .read(readingPlanProvider.notifier)
                      .updateDuration(plan.id, opt.days, upd);
                  Navigator.of(ctx).pop();
                },
                child: Container(
                  width: double.infinity,
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(opt.label,
                            style: GoogleFonts.inter(
                              color: isSelected ? accent : fg,
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            )),
                      ),
                      if (isSelected)
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

  Future<void> _showTimePicker(
    BuildContext context,
    WidgetRef ref,
    ReadingPlan plan,
    Color accent,
  ) async {
    final result = await showTimePicker(
      context: context,
      initialTime: plan.reminderTime,
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
    if (result != null) {
      ref.read(readingPlanProvider.notifier).updateReminder(
          plan.id, result.hour, result.minute, plan.reminderEnabled);
      if (plan.reminderEnabled) {
        await NotificationService.instance.schedulePlanReminder(
          planId: plan.id,
          textTitle: plan.textTitle,
          hour: result.hour,
          minute: result.minute,
          dayNumber: plan.dayNumber,
          durationDays: plan.durationDays,
          unitsPerDay: plan.unitsPerDay,
          unitLabel: plan.unitLabel,
          estimatedMins: plan.estimatedMinutesPerDay,
        );
        await NotificationService.instance.requestBatteryExemption();
      }
    }
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, String planId, Color accent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.nightBg : AppColors.boneBg;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final surface = isDark ? AppColors.nightSurface : Colors.white;
    final line = isDark ? AppColors.nightLine : AppColors.boneLine;

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
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'END PLAN',
              style: GoogleFonts.jetBrainsMono(
                color: Colors.red.shade400,
                fontSize: 9,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Stop reading?',
              style: GoogleFonts.cormorantGaramond(
                color: fg,
                fontSize: 24,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your streak and progress will be lost.',
              style: GoogleFonts.inter(color: muted, fontSize: 13),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () async {
                // Navigate first — deletePlan triggers rebuild making context stale
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) Navigator.of(context).pop();
                await NotificationService.instance.cancelPlanReminder(planId);
                ref.read(readingPlanProvider.notifier).deletePlan(planId);
              },
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.red.shade500,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'End plan',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.of(ctx).pop(),
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: line),
                ),
                child: Center(
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      color: fg,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
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

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.value,
    required this.label,
    required this.icon,
    required this.accent,
    required this.fg,
    required this.muted,
  });

  final String value, label;
  final String? icon;
  final Color accent, fg, muted;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Text(icon!, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
              ],
              Text(value,
                  style: GoogleFonts.cormorantGaramond(
                      color: accent,
                      fontSize: 22,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.jetBrainsMono(
                  color: muted, fontSize: 8, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard(
      {required this.child, required this.surface, required this.line});
  final Widget child;
  final Color surface, line;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
      clipBehavior: Clip.hardEdge,
      child: child,
    );
  }
}
