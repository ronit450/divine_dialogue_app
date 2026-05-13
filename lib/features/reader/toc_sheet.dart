import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/scripture.dart';
import '../../core/theme/app_colors.dart';

Future<int?> showTocSheet({
  required BuildContext context,
  required ScriptureTextMeta meta,
  required List<ScriptureChapter> chapters,
  required int currentChapter,
  required Color accent,
  required bool isDark,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TocSheet(
      meta: meta,
      chapters: chapters,
      currentChapter: currentChapter,
      accent: accent,
      isDark: isDark,
    ),
  );
}

Future<int?> showPagedTocSheet({
  required BuildContext context,
  required ScriptureTextMeta meta,
  required int currentPage,
  required Color accent,
  required bool isDark,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PagedTocSheet(
      meta: meta,
      currentPage: currentPage,
      accent: accent,
      isDark: isDark,
    ),
  );
}

class _TocSheet extends StatefulWidget {
  const _TocSheet({
    required this.meta,
    required this.chapters,
    required this.currentChapter,
    required this.accent,
    required this.isDark,
  });

  final ScriptureTextMeta meta;
  final List<ScriptureChapter> chapters;
  final int currentChapter;
  final Color accent;
  final bool isDark;

  @override
  State<_TocSheet> createState() => _TocSheetState();
}

class _TocSheetState extends State<_TocSheet> {
  late List<ScriptureChapter> _filtered;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _filtered = widget.chapters;
  }

  void _search(String q) {
    setState(() {
      _query = q;
      _filtered = q.isEmpty
          ? widget.chapters
          : widget.chapters
              .where((c) => c.name.toLowerCase().contains(q.toLowerCase()))
              .toList();
    });
  }

  ScriptureChapter get _currentChapter => widget.chapters.firstWhere(
        (c) => c.number == widget.currentChapter,
        orElse: () => widget.chapters.first,
      );

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? AppColors.nightBg : AppColors.boneBg;
    final fg = widget.isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = widget.isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final line = widget.isDark ? AppColors.nightLine : AppColors.boneLine;
    final soft = ReligionColors.soft(widget.meta.religionId);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _handle(line),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Index · ${widget.chapters.length} ${widget.meta.chapterLabel}s'.toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(fontSize: 9, letterSpacing: 2, color: muted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Jump to a ${widget.meta.chapterLabel.toLowerCase()}',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 24, fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic, color: fg,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _searchField(fg, muted, line, bg),
                  if (_query.isEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Currently Reading'.toUpperCase(),
                      style: GoogleFonts.jetBrainsMono(fontSize: 8, letterSpacing: 2, color: muted),
                    ),
                    const SizedBox(height: 6),
                    _currentReadingRow(fg, muted, soft),
                  ],
                ],
              ),
            ),
            Divider(height: 1, color: line),
            Expanded(
              child: ListView.separated(
                controller: controller,
                padding: EdgeInsets.zero,
                itemCount: _filtered.length,
                separatorBuilder: (_, _) => Divider(height: 1, color: line),
                itemBuilder: (_, i) => _chapterRow(_filtered[i], fg, muted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _handle(Color line) => Container(
        width: 32, height: 3,
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: line, borderRadius: BorderRadius.circular(2)),
      );

  Widget _searchField(Color fg, Color muted, Color line, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.nightSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: line),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, size: 16, color: muted),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: _search,
                style: GoogleFonts.inter(fontSize: 13, color: fg),
                decoration: InputDecoration(
                  isDense: true, border: InputBorder.none,
                  hintText: 'Search...',
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: muted),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _currentReadingRow(Color fg, Color muted, Color soft) => GestureDetector(
        onTap: () => Navigator.pop(context, widget.currentChapter),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Container(
                width: 7, height: 7,
                decoration: BoxDecoration(color: widget.accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentChapter.name,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: fg),
                    ),
                    if (_currentChapter.meta != null)
                      Text(
                        _currentChapter.meta!,
                        style: GoogleFonts.jetBrainsMono(fontSize: 8, letterSpacing: 1, color: muted),
                      ),
                  ],
                ),
              ),
              Text(
                '${widget.meta.chapterLabel} ${widget.currentChapter}',
                style: GoogleFonts.jetBrainsMono(fontSize: 9, color: widget.accent),
              ),
            ],
          ),
        ),
      );

  Widget _chapterRow(ScriptureChapter ch, Color fg, Color muted) {
    final isActive = ch.number == widget.currentChapter;
    return InkWell(
      onTap: () => Navigator.pop(context, ch.number),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '${ch.number}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10, color: isActive ? widget.accent : muted,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ch.name,
                    style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w500,
                      color: isActive ? widget.accent : fg,
                    ),
                  ),
                  if (ch.meta != null)
                    Text(
                      ch.meta!,
                      style: GoogleFonts.jetBrainsMono(fontSize: 8, letterSpacing: 1, color: muted),
                    ),
                ],
              ),
            ),
            if (ch.nameOriginal != null)
              Text(ch.nameOriginal!, style: TextStyle(fontSize: 15, color: muted)),
          ],
        ),
      ),
    );
  }
}

class _PagedTocSheet extends StatefulWidget {
  const _PagedTocSheet({
    required this.meta,
    required this.currentPage,
    required this.accent,
    required this.isDark,
  });

  final ScriptureTextMeta meta;
  final int currentPage;
  final Color accent;
  final bool isDark;

  @override
  State<_PagedTocSheet> createState() => _PagedTocSheetState();
}

class _PagedTocSheetState extends State<_PagedTocSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '${widget.currentPage}');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<int> get _quickJumps {
    final total = widget.meta.totalChapters;
    final step = (total / 8).round().clamp(1, 9999);
    final jumps = <int>[1];
    for (int v = step; v < total; v += step) { jumps.add(v); }
    if (jumps.last != total) jumps.add(total);
    return jumps;
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? AppColors.nightBg : AppColors.boneBg;
    final fg = widget.isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = widget.isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final line = widget.isDark ? AppColors.nightLine : AppColors.boneLine;
    final total = widget.meta.totalChapters;
    final label = widget.meta.chapterLabel;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
      child: SingleChildScrollView(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 32, height: 3,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: line, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$total ${label}s'.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(fontSize: 9, letterSpacing: 2, color: muted),
                ),
                const SizedBox(height: 4),
                Text(
                  'Jump to a $label',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 24, fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic, color: fg,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: widget.isDark ? AppColors.nightSurface : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: line),
                        ),
                        child: TextField(
                          controller: _ctrl,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.jetBrainsMono(fontSize: 18, color: fg),
                          decoration: InputDecoration(
                            isDense: true, border: InputBorder.none,
                            hintText: '1 – $total',
                            hintStyle: GoogleFonts.jetBrainsMono(fontSize: 18, color: muted),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        final page = int.tryParse(_ctrl.text);
                        if (page != null && page >= 1 && page <= total) {
                          Navigator.pop(context, page);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: widget.accent, borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Go →',
                          style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: line),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick jump'.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(fontSize: 8, letterSpacing: 2, color: muted),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickJumps.map((p) {
                    final isActive = p == widget.currentPage;
                    return GestureDetector(
                      onTap: () => Navigator.pop(context, p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive
                              ? widget.accent
                              : (widget.isDark ? AppColors.nightSurface : Colors.white),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isActive ? widget.accent : line),
                        ),
                        child: Text(
                          '$label $p',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10, color: isActive ? Colors.white : muted,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
        ),
      ),
    );
  }
}
