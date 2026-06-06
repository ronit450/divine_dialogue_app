import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/reading_plan.dart';
import '../../core/models/quran_page_mapper.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/reading_plan_provider.dart';
import '../../providers/religion_provider.dart';
import '../../shared/widgets/reading_plan_setup_sheet.dart';

class ReadingPlansScreen extends ConsumerWidget {
  const ReadingPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allPlans = ref.watch(readingPlanProvider).plans;
    final religion = ref.watch(religionProvider).selectedReligion;
    final plans = religion != null
        ? allPlans.where((p) => p.religionId == religion.id).toList()
        : allPlans;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.nightBg : AppColors.boneBg;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final line = isDark ? AppColors.nightLine : AppColors.boneLine;
    final surface = isDark ? AppColors.nightSurface : Colors.white;
    final accent = ReligionColors.accent(religion?.id ?? 'sikhism');

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
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
                  Expanded(
                    child: Text(
                      'Reading plans',
                      style: GoogleFonts.cormorantGaramond(
                        color: fg,
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  if (plans.isNotEmpty)
                    GestureDetector(
                      onTap: () => showReadingPlanSetupSheet(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: line)),
                        child: Icon(Icons.add_rounded, size: 18, color: fg),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: plans.isEmpty
                  ? _EmptyState(muted: muted, fg: fg, accent: accent)
                  : _PlanList(
                      plans: plans,
                      fg: fg,
                      muted: muted,
                      line: line,
                      surface: surface,
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: plans.isEmpty
          ? FloatingActionButton(
              onPressed: () => showReadingPlanSetupSheet(context),
              backgroundColor: accent,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.muted, required this.fg, required this.accent});
  final Color muted, fg, accent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.menu_book_outlined, color: accent, size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              'DAILY READING',
              style: GoogleFonts.jetBrainsMono(color: accent, fontSize: 10, letterSpacing: 2),
            ),
            const SizedBox(height: 10),
            Text(
              'Read scripture, a little each day.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                color: fg,
                fontSize: 26,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Pick any book, choose how long you want to take, and keep a streak. We'll guide you to the right portion each day.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanList extends StatelessWidget {
  const _PlanList({
    required this.plans,
    required this.fg,
    required this.muted,
    required this.line,
    required this.surface,
  });

  final List<ReadingPlan> plans;
  final Color fg, muted, line, surface;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text(
          '${plans.length} ACTIVE',
          style: GoogleFonts.jetBrainsMono(
              color: muted, fontSize: 9, letterSpacing: 1.5),
        ),
        const SizedBox(height: 12),
        ...plans.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PlanCard(
                  plan: p, fg: fg, muted: muted, line: line, surface: surface),
            )),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.fg,
    required this.muted,
    required this.line,
    required this.surface,
  });

  final ReadingPlan plan;
  final Color fg, muted, line, surface;

  String _abbrev(String title) {
    final words = title.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words[0].substring(0, words[0].length.clamp(0, 3)).toUpperCase();
    }
    return words.take(2).map((w) => w[0].toUpperCase()).join();
  }

  String _lastReadLabel(ReadingPlan plan) {
    final unit = plan.lastReadUnit!;
    final displayUnit = plan.textId == 'quran'
        ? QuranPageMapper.surahToPage(unit)
        : unit;
    return 'LAST READ: ${plan.unitLabel.toUpperCase()} $displayUnit';
  }

  @override
  Widget build(BuildContext context) {
    final accent = ReligionColors.accent(plan.religionId);

    return GestureDetector(
      onTap: () => context.push('/reading-plans/${plan.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: line),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _abbrev(plan.textTitle),
                  style: GoogleFonts.jetBrainsMono(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          plan.textTitle,
                          style: GoogleFonts.inter(
                              color: fg,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (plan.streak > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔥',
                                  style: TextStyle(fontSize: 10)),
                              const SizedBox(width: 2),
                              Text(
                                '${plan.streak}',
                                style: GoogleFonts.jetBrainsMono(
                                    color: accent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'DAY ${plan.dayNumber}${plan.durationDays != null ? ' OF ${plan.durationDays}' : ''} · ${plan.durationLabel.toUpperCase()}',
                    style: GoogleFonts.jetBrainsMono(
                        color: muted, fontSize: 9, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: plan.progressFraction,
                      backgroundColor: accent.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(accent),
                      minHeight: 3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${plan.percentRead}% READ',
                          style: GoogleFonts.jetBrainsMono(
                              color: muted,
                              fontSize: 8,
                              letterSpacing: 0.5)),
                      Text(
                        plan.daysLeft >= 0
                            ? '${plan.daysLeft} LEFT'
                            : '${plan.totalDaysCompleted} DONE',
                        style: GoogleFonts.jetBrainsMono(
                            color: muted,
                            fontSize: 8,
                            letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  if (plan.lastReadUnit != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _lastReadLabel(plan),
                      style: GoogleFonts.jetBrainsMono(
                          color: muted, fontSize: 8, letterSpacing: 0.5),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
