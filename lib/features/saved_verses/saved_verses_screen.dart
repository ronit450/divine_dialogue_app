import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/saved_verse.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/saved_verses_provider.dart';

class SavedVersesScreen extends ConsumerWidget {
  const SavedVersesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verses = ref.watch(savedVersesProvider);

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
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: line),
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            size: 14, color: fg),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Saved Verses',
                      style: GoogleFonts.cormorantGaramond(
                        color: fg,
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Text(
                '${verses.length} verse${verses.length == 1 ? '' : 's'}',
                style: GoogleFonts.jetBrainsMono(
                    color: muted, fontSize: 10, letterSpacing: 1.0),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          if (verses.isEmpty)
            SliverFillRemaining(child: _EmptyState(fg: fg, muted: muted))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _VerseItem(
                    verse: verses[i],
                    isDark: isDark,
                    fg: fg,
                    muted: muted,
                    line: line,
                    surface: surface,
                    onTap: () => context.push(
                      '/read/${verses[i].textId}',
                      extra: _chapterFromVerse(verses[i]),
                    ),
                    onDelete: () =>
                        ref.read(savedVersesProvider.notifier).toggle(verses[i]),
                  ),
                  childCount: verses.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Map<String, int>? _chapterFromVerse(SavedVerse v) {
    // ID format: "$textId-$chapter-$verse"
    final parts = v.id.split('-');
    if (parts.length >= 2) {
      final chapter = int.tryParse(parts[parts.length - 2]);
      if (chapter != null) return {'chapter': chapter};
    }
    return null;
  }
}

// ─── Verse item tile ──────────────────────────────────────────────────────────

class _VerseItem extends StatelessWidget {
  const _VerseItem({
    required this.verse,
    required this.isDark,
    required this.fg,
    required this.muted,
    required this.line,
    required this.surface,
    required this.onTap,
    required this.onDelete,
  });

  final SavedVerse verse;
  final bool isDark;
  final Color fg, muted, line, surface;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = ReligionColors.accent(verse.religionId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: line),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3,
                height: 40,
                margin: const EdgeInsets.only(top: 2, right: 12),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verse.reference,
                      style: GoogleFonts.jetBrainsMono(
                        color: accent,
                        fontSize: 10,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      verse.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          color: fg, fontSize: 13, height: 1.5),
                    ),
                    if (verse.translation != null &&
                        verse.translation!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        verse.translation!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            color: muted, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: onDelete,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child:
                      Icon(Icons.bookmark_remove_outlined, size: 18, color: muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.fg, required this.muted});
  final Color fg, muted;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: muted.withValues(alpha: 0.08),
              border: Border.all(color: muted.withValues(alpha: 0.15)),
            ),
            child:
                Icon(Icons.bookmark_border_rounded, color: muted, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'No saved verses',
            style: GoogleFonts.cormorantGaramond(
              color: fg,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bookmark verses in the reader to save them here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
