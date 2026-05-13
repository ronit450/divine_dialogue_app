import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/scripture.dart';
import '../../core/theme/app_colors.dart';
import '../../data/scripture_repository.dart';
import '../../providers/scripture_provider.dart';
import 'toc_sheet.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    super.key,
    required this.textId,
    this.initialChapter,
  });

  final String textId;
  final int? initialChapter;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final _repo = ScriptureRepository.instance;

  ScriptureTextMeta? _meta;
  List<ScriptureChapter> _chapters = [];
  List<ScriptureVerse> _verses = [];
  int _currentChapter = 1;
  bool _loading = true;
  String? _error;
  final Set<int> _expandedTranslit = {};

  @override
  void initState() {
    super.initState();
    _meta = ScriptureTextMeta.forTextId(widget.textId);
    if (_meta == null) {
      _error = 'Unsupported text: ${widget.textId}';
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    final saved = ref.read(scripturePositionProvider).getPosition(widget.textId);
    _currentChapter = widget.initialChapter ?? saved.$1;
    try {
      if (_meta!.type == ScriptureTextType.ggs) {
        _verses = await _repo.loadGgsAng(_currentChapter);
        if (_currentChapter > 1) _repo.loadGgsAng(_currentChapter - 1);
        if (_currentChapter < 1430) _repo.loadGgsAng(_currentChapter + 1);
      } else {
        _chapters = await _repo.loadChapters(widget.textId);
        _verses = _versesFor(_currentChapter);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
      return;
    }
    if (mounted) setState(() => _loading = false);
  }

  List<ScriptureVerse> _versesFor(int num) {
    if (_chapters.isEmpty) return [];
    final ch = _chapters.firstWhere(
      (c) => c.number == num,
      orElse: () => _chapters.first,
    );
    return ch.verses;
  }

  Future<void> _goTo(int num) async {
    final maxChapter = _meta!.type == ScriptureTextType.ggs ? 1430 : _chapters.length;
    if (num < 1 || num > maxChapter) return;
    setState(() { _loading = true; _expandedTranslit.clear(); });
    _currentChapter = num;
    try {
      if (_meta!.type == ScriptureTextType.ggs) {
        _verses = await _repo.loadGgsAng(num);
        if (num > 1) _repo.loadGgsAng(num - 1);
        if (num < 1430) _repo.loadGgsAng(num + 1);
      } else {
        _verses = _versesFor(num);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
      return;
    }
    await ref.read(scripturePositionProvider.notifier).savePosition(widget.textId, num, 1);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openToc() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ReligionColors.accent(_meta!.religionId);
    int? result;
    if (_meta!.type == ScriptureTextType.ggs) {
      result = await showGgsTocSheet(
        context: context, currentAng: _currentChapter, accent: accent, isDark: isDark,
      );
    } else {
      result = await showTocSheet(
        context: context, meta: _meta!, chapters: _chapters,
        currentChapter: _currentChapter, accent: accent, isDark: isDark,
      );
    }
    if (result != null) await _goTo(result);
  }

  String get _title {
    if (_meta!.type == ScriptureTextType.ggs) return _meta!.title;
    if (_chapters.isEmpty) return _meta!.title;
    return _chapters.firstWhere(
      (c) => c.number == _currentChapter, orElse: () => _chapters.first,
    ).name;
  }

  String get _subLabel {
    if (_meta!.type == ScriptureTextType.ggs) return 'Ang $_currentChapter of 1,430';
    if (_chapters.isEmpty) return '';
    final ch = _chapters.firstWhere(
      (c) => c.number == _currentChapter, orElse: () => _chapters.first,
    );
    if (ch.meta != null && ch.meta!.isNotEmpty) return ch.meta!;
    return '${ch.verseCount} ${_meta!.verseLabel}s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.nightBg : AppColors.boneBg;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final line = isDark ? AppColors.nightLine : AppColors.boneLine;
    final accent = _meta != null ? ReligionColors.accent(_meta!.religionId) : AppColors.islamGreen;

    if (_error != null) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(child: Text(_error!, style: GoogleFonts.inter(color: muted))),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: fg),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      _meta != null ? _title : '',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 18, fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic, color: fg,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent, borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_currentChapter',
                      style: GoogleFonts.jetBrainsMono(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            // Sub-header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _loading ? '' : _subLabel.toUpperCase(),
                      style: GoogleFonts.jetBrainsMono(fontSize: 9, letterSpacing: 1.5, color: muted),
                    ),
                  ),
                  GestureDetector(
                    onTap: _openToc,
                    child: Icon(Icons.format_list_bulleted_rounded, size: 18, color: muted),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: line),
            // Content
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(strokeWidth: 1.5, color: accent))
                  : _verses.isEmpty
                      ? Center(child: Text('No content available', style: GoogleFonts.inter(color: muted, fontSize: 13)))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
                          itemCount: _verses.length,
                          separatorBuilder: (_, _) => Divider(height: 1, color: line),
                          itemBuilder: (_, i) => _VerseCard(
                            verse: _verses[i],
                            type: _meta!.type,
                            accent: accent,
                            fg: fg,
                            muted: muted,
                            isExpanded: _expandedTranslit.contains(i),
                            onToggleTranslit: () => setState(() {
                              _expandedTranslit.contains(i)
                                  ? _expandedTranslit.remove(i)
                                  : _expandedTranslit.add(i);
                            }),
                          ),
                        ),
            ),
            // Bottom bar
            Container(
              height: 52,
              decoration: BoxDecoration(color: bg, border: Border(top: BorderSide(color: line))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navBtn(
                    icon: Icons.arrow_back_ios_rounded,
                    color: _currentChapter > 1 ? fg : muted,
                    onTap: _currentChapter > 1 ? () => _goTo(_currentChapter - 1) : null,
                  ),
                  _navBtn(icon: Icons.favorite_border_rounded, color: muted, onTap: () {}),
                  _navBtn(
                    icon: Icons.ios_share_rounded,
                    color: muted,
                    onTap: _verses.isNotEmpty
                        ? () {
                            final text = _verses.first.translation;
                            Clipboard.setData(ClipboardData(text: text));
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Copied', style: GoogleFonts.inter(fontSize: 13)),
                              duration: const Duration(seconds: 1),
                              backgroundColor: accent,
                            ));
                          }
                        : null,
                  ),
                  _navBtn(icon: Icons.arrow_forward_ios_rounded, color: fg, onTap: () => _goTo(_currentChapter + 1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navBtn({required IconData icon, required Color color, VoidCallback? onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: SizedBox(width: 48, height: 48, child: Icon(icon, size: 17, color: color)),
      );
}

// ── Verse Card ──

class _VerseCard extends StatelessWidget {
  const _VerseCard({
    required this.verse,
    required this.type,
    required this.accent,
    required this.fg,
    required this.muted,
    required this.isExpanded,
    required this.onToggleTranslit,
  });

  final ScriptureVerse verse;
  final ScriptureTextType type;
  final Color accent;
  final Color fg;
  final Color muted;
  final bool isExpanded;
  final VoidCallback onToggleTranslit;

  @override
  Widget build(BuildContext context) => switch (type) {
        ScriptureTextType.quran => _quranCard(),
        ScriptureTextType.ggs   => _ggsCard(),
        ScriptureTextType.gita  => _gitaCard(),
        ScriptureTextType.bible => _bibleCard(),
      };

  Widget _quranCard() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (verse.original != null)
              Text(
                verse.original!,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontSize: 20, height: 2.0, fontFamily: 'serif'),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 22, height: 22,
                margin: const EdgeInsets.only(top: 4, bottom: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle, border: Border.all(color: accent, width: 1.5),
                ),
                child: Center(
                  child: Text('${verse.number}',
                    style: GoogleFonts.jetBrainsMono(fontSize: 8, color: accent)),
                ),
              ),
            ),
            Text(verse.translation, style: GoogleFonts.inter(fontSize: 13, height: 1.65, color: fg)),
          ],
        ),
      );

  Widget _ggsCard() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (verse.isGroupStart && (verse.groupLabel?.isNotEmpty ?? false))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  verse.groupLabel!.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(fontSize: 8, letterSpacing: 2, color: muted),
                ),
              ),
            if (verse.original != null)
              Text(
                verse.original!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, height: 1.9, color: accent),
              ),
            const SizedBox(height: 8),
            Text(verse.translation, style: GoogleFonts.inter(fontSize: 13, height: 1.65, color: fg)),
          ],
        ),
      );

  Widget _gitaCard() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (verse.original != null)
              Text(
                verse.original!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.9, color: accent, fontFamily: 'serif'),
              ),
            const SizedBox(height: 10),
            Text(verse.translation, style: GoogleFonts.inter(fontSize: 13, height: 1.65, color: fg)),
            if (verse.transliteration != null) ...[
              const SizedBox(height: 8),
              _chip('Transliteration ▾'),
              if (isExpanded) ...[
                const SizedBox(height: 8),
                Text(
                  verse.transliteration!,
                  style: GoogleFonts.inter(fontSize: 12, height: 1.6, color: fg, fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ],
        ),
      );

  Widget _bibleCard() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              child: Text('${verse.number}',
                style: GoogleFonts.jetBrainsMono(fontSize: 9, color: muted)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(verse.translation,
              style: GoogleFonts.inter(fontSize: 13, height: 1.65, color: fg))),
          ],
        ),
      );

  Widget _chip(String label) => GestureDetector(
        onTap: onToggleTranslit,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            border: Border.all(color: muted.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label, style: GoogleFonts.jetBrainsMono(fontSize: 8, color: muted)),
        ),
      );
}
