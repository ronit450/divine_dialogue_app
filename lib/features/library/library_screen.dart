import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/religion_provider.dart';
import '../../providers/reading_plan_provider.dart';
import '../../providers/download_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/religion.dart';
import '../../core/models/reading_plan.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  bool _searching = false;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _closeSearch() {
    setState(() {
      _searching = false;
      _searchQuery = '';
      _searchCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(religionProvider);
    final religions = state.religions;
    final selectedReligion = state.selectedReligion;
    final planState = ref.watch(readingPlanProvider);
    final downloadState = ref.watch(downloadProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.nightBg : AppColors.boneBg;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final line = isDark ? AppColors.nightLine : AppColors.boneLine;
    final surface = isDark ? AppColors.nightSurface : Colors.white;

    final activeReligion = selectedReligion ??
        (religions.isNotEmpty ? religions.first : null);

    if (activeReligion == null) {
      return Scaffold(backgroundColor: bg);
    }

    final accent = ReligionColors.accent(activeReligion.id);

    final filteredTexts = _searching && _searchQuery.isNotEmpty
        ? activeReligion.texts.where((t) {
            final q = _searchQuery.toLowerCase();
            return t.title.toLowerCase().contains(q) ||
                t.description.toLowerCase().contains(q);
          }).toList()
        : <SacredTextModel>[];

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
                    Row(
                      children: [
                        if (_searching) ...[
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                color: surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: line),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.search_rounded, size: 16, color: muted),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchCtrl,
                                      autofocus: true,
                                      onChanged: (v) => setState(() => _searchQuery = v),
                                      style: GoogleFonts.inter(fontSize: 14, color: fg),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        border: InputBorder.none,
                                        hintText: 'Search texts...',
                                        hintStyle: GoogleFonts.inter(fontSize: 14, color: muted),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _closeSearch,
                            child: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: line),
                              ),
                              child: Icon(Icons.close_rounded, size: 16, color: fg),
                            ),
                          ),
                        ] else ...[
                          GestureDetector(
                            onTap: () => context.go('/home'),
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'LIBRARY',
                                  style: GoogleFonts.jetBrainsMono(
                                    color: muted,
                                    fontSize: 10,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  activeReligion.name,
                                  style: GoogleFonts.cormorantGaramond(
                                    color: fg,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _searching = true),
                            child: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: line),
                              ),
                              child: Icon(Icons.search_rounded, size: 17, color: muted),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (!_searching) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Tap any text to begin reading.',
                        style: GoogleFonts.inter(color: muted, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // Search results
          if (_searching && _searchQuery.isNotEmpty) ...[
            if (filteredTexts.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'No texts found.',
                    style: GoogleFonts.inter(color: muted, fontSize: 14),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final text = filteredTexts[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _TextListTile(
                          text: text,
                          accent: accent,
                          fg: fg,
                          muted: muted,
                          line: line,
                          surface: surface,
                          onTap: () => context.push('/read/${text.id}'),
                          plan: planState.planForText(text.id),
                          downloadInfo: downloadState[text.id],
                        ),
                      );
                    },
                    childCount: filteredTexts.length,
                  ),
                ),
              ),
          ] else ...[
            // Hero card for primary text
            if (activeReligion.texts.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Builder(builder: (context) {
                    final primaryText = activeReligion.texts.first;
                    final plan = planState.planForText(primaryText.id);
                    if (plan != null) {
                      return _PlanHeroCard(
                        plan: plan,
                        text: primaryText,
                        religion: activeReligion,
                        accent: accent,
                        fg: fg,
                        muted: muted,
                      );
                    }
                    return _HeroTextCard(
                      text: primaryText,
                      religion: activeReligion,
                      accent: accent,
                      isSelected: primaryText.id == state.selectedText?.id,
                      downloadInfo: downloadState[primaryText.id],
                    );
                  }),
                ),
              ),

            // Other texts
            if (activeReligion.texts.length > 1) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Text(
                    'OTHER TEXTS · ${activeReligion.texts.length - 1}',
                    style: GoogleFonts.jetBrainsMono(
                      color: muted, fontSize: 9, letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final text = activeReligion.texts[i + 1];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _TextListTile(
                          text: text,
                          accent: accent,
                          fg: fg,
                          muted: muted,
                          line: line,
                          surface: surface,
                          onTap: () => context.push('/read/${text.id}'),
                          plan: planState.planForText(text.id),
                          downloadInfo: downloadState[text.id],
                        ),
                      );
                    },
                    childCount: activeReligion.texts.length - 1,
                  ),
                ),
              ),
            ],
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }
}

class _HeroTextCard extends StatelessWidget {
  const _HeroTextCard({
    required this.text,
    required this.religion,
    required this.accent,
    required this.isSelected,
    this.downloadInfo,
  });

  final SacredTextModel text;
  final ReligionModel religion;
  final Color accent;
  final bool isSelected;
  final DownloadInfo? downloadInfo;

  Widget _downloadTrailing() {
    final info = downloadInfo;
    if (info?.status == TextDownloadStatus.downloading) {
      return SizedBox(
        width: 32, height: 32,
        child: Center(
          child: SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(
              value: info!.progress > 0 ? info.progress : null,
              color: Colors.white,
              strokeWidth: 1.5,
            ),
          ),
        ),
      );
    }
    if (info?.status == TextDownloadStatus.notDownloaded) {
      return Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.cloud_download_outlined, color: Colors.white, size: 16),
      );
    }
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
    );
  }

  String _watermarkGlyph(String religionId) => switch (religionId) {
    'sikhism'      => 'ਆਦਿ ਸਚੁ',
    'islam'        => 'الله',
    'hinduism'     => 'ॐ',
    'christianity' => '✝',
    _ => '✦',
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/read/${text.id}'),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              right: -16,
              top: -12,
              child: Text(
                _watermarkGlyph(religion.id),
                style: TextStyle(
                  fontSize: 90,
                  color: Colors.white.withValues(alpha: 0.08),
                  fontFamily: 'serif',
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSelected ? 'CURRENT TEXT' : 'PRIMARY TEXT',
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 9,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  text.title,
                  style: GoogleFonts.cormorantGaramond(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text.description,
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isSelected ? 'CONTINUE READING' : 'BEGIN READING',
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white,
                        fontSize: 9,
                        letterSpacing: 1.5,
                      ),
                    ),
                    _downloadTrailing(),
                  ],
                ),
                if (downloadInfo case final di? when di.status == TextDownloadStatus.downloading) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: di.progress > 0 ? di.progress : null,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                      minHeight: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'DOWNLOADING · ${(di.progress * 100).round()}%',
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 8,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanHeroCard extends StatelessWidget {
  const _PlanHeroCard({
    required this.plan,
    required this.text,
    required this.religion,
    required this.accent,
    required this.fg,
    required this.muted,
  });

  final ReadingPlan plan;
  final SacredTextModel text;
  final ReligionModel religion;
  final Color accent, fg, muted;

  String _watermarkGlyph(String id) => switch (id) {
    'sikhism'      => 'ਆਦਿ ਸਚੁ',
    'islam'        => 'الله',
    'hinduism'     => 'ॐ',
    'christianity' => '✝',
    _ => '✦',
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        '/read/${text.id}',
        extra: {'chapter': plan.todayStartUnit},
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              right: -16, top: -12,
              child: Text(
                _watermarkGlyph(religion.id),
                style: TextStyle(
                  fontSize: 90,
                  color: Colors.white.withValues(alpha: 0.08),
                  fontFamily: 'serif',
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'ACTIVE PLAN',
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 9, letterSpacing: 2,
                      ),
                    ),
                    if (plan.streak > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 9)),
                            const SizedBox(width: 2),
                            Text(
                              '${plan.streak}',
                              style: GoogleFonts.jetBrainsMono(
                                color: Colors.white,
                                fontSize: 9, fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  text.title,
                  style: GoogleFonts.cormorantGaramond(
                    color: Colors.white, fontSize: 26,
                    fontWeight: FontWeight.w500, fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: plan.progressFraction,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                    minHeight: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      plan.todayDone
                          ? 'DAY ${plan.dayNumber} DONE ✓'
                          : 'TODAY · ${plan.unitLabel.toUpperCase()} ${plan.todayStartUnit}–${plan.todayEndUnit}',
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 9, letterSpacing: 1.2,
                      ),
                    ),
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TextListTile extends StatelessWidget {
  const _TextListTile({
    required this.text,
    required this.accent,
    required this.fg,
    required this.muted,
    required this.line,
    required this.surface,
    required this.onTap,
    this.plan,
    this.downloadInfo,
  });

  final SacredTextModel text;
  final Color accent;
  final Color fg;
  final Color muted;
  final Color line;
  final Color surface;
  final VoidCallback onTap;
  final ReadingPlan? plan;
  final DownloadInfo? downloadInfo;

  Widget _tileTrailing() {
    final info = downloadInfo;
    if (info?.status == TextDownloadStatus.downloading) {
      return SizedBox(
        width: 20, height: 20,
        child: CircularProgressIndicator(
          value: info!.progress > 0 ? info.progress : null,
          color: accent,
          strokeWidth: 1.5,
        ),
      );
    }
    if (info?.status == TextDownloadStatus.notDownloaded) {
      return Icon(Icons.cloud_download_outlined, color: muted, size: 20);
    }
    if (info?.status == TextDownloadStatus.failed) {
      return Icon(Icons.refresh_rounded, color: muted, size: 20);
    }
    return Icon(Icons.chevron_right_rounded, color: muted, size: 20);
  }

  String _abbrev(String title) {
    final words = title.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words[0].substring(0, words[0].length.clamp(0, 3)).toUpperCase();
    return words.take(2).map((w) => w[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: line),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  _abbrev(text.title),
                  style: GoogleFonts.jetBrainsMono(
                    color: accent, fontSize: 11,
                    fontWeight: FontWeight.w600, letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text.title,
                    style: GoogleFonts.inter(color: fg, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(text.description, style: GoogleFonts.inter(color: muted, fontSize: 12)),
                  if (plan != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: plan!.progressFraction,
                        backgroundColor: accent.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation(accent),
                        minHeight: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'DAY ${plan!.dayNumber} · ${plan!.percentRead}% READ',
                      style: GoogleFonts.jetBrainsMono(
                        color: muted, fontSize: 8, letterSpacing: 0.5),
                    ),
                  ],
                ],
              ),
            ),
            _tileTrailing(),
          ],
        ),
      ),
    );
  }
}
