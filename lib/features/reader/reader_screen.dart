import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/scripture.dart';
import '../../core/theme/app_colors.dart';
import '../../data/scripture_repository.dart';
import '../../providers/scripture_provider.dart';
import 'toc_sheet.dart' show showTocSheet, showPagedTocSheet;

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
  bool _showTranslation = true;
  bool _showTranslit = true;

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

  bool get _isPagedType =>
      _meta!.type == ScriptureTextType.ggs ||
      _meta!.type == ScriptureTextType.dasam ||
      _meta!.type == ScriptureTextType.bgv ||
      _meta!.type == ScriptureTextType.hadith ||
      _meta!.type == ScriptureTextType.ramayana;

  Future<void> _load() async {
    final saved = ref.read(scripturePositionProvider).getPosition(widget.textId);
    _currentChapter = widget.initialChapter ?? saved.$1;
    try {
      if (_isPagedType) {
        _verses = await _loadPagedVerses(_currentChapter);
        _prefetch(_currentChapter);
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

  Future<List<ScriptureVerse>> _loadPagedVerses(int page) {
    return switch (_meta!.type) {
      ScriptureTextType.ggs    => _repo.loadGgsAng(page),
      ScriptureTextType.dasam  => _repo.loadDasamPage(page),
      ScriptureTextType.bgv    => _repo.loadBgvVaar(page),
      ScriptureTextType.hadith   => _repo.loadHadithChapter(widget.textId, page),
      ScriptureTextType.ramayana => _repo.loadRamayanaSarga(page),
      _ => Future.value([]),
    };
  }

  void _prefetch(int page) {
    final max = _meta!.totalChapters;
    if (page > 1) _loadPagedVerses(page - 1);
    if (page < max) _loadPagedVerses(page + 1);
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
    final max = _meta!.totalChapters;
    if (num < 1 || num > max) return;
    setState(() => _loading = true);
    _currentChapter = num;
    try {
      if (_isPagedType) {
        _verses = await _loadPagedVerses(num);
        _prefetch(num);
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
    if (_isPagedType) {
      result = await showPagedTocSheet(
        context: context, meta: _meta!, currentPage: _currentChapter,
        accent: accent, isDark: isDark,
      );
    } else {
      result = await showTocSheet(
        context: context, meta: _meta!, chapters: _chapters,
        currentChapter: _currentChapter, accent: accent, isDark: isDark,
      );
    }
    if (result != null) await _goTo(result);
  }

  void _openReadingOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.nightBg : AppColors.boneBg;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final line = isDark ? AppColors.nightLine : AppColors.boneLine;
    final accent = _meta != null ? ReligionColors.accent(_meta!.religionId) : AppColors.islamGreen;

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'READING OPTIONS',
                style: GoogleFonts.jetBrainsMono(
                  color: muted, fontSize: 9, letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              _optionRow('Translation', _showTranslation, accent, fg, line, (v) {
                setState(() => _showTranslation = v);
                setSheet(() {});
              }),
              Divider(height: 1, color: line),
              if (_meta?.hasTransliteration ?? false)
                _optionRow('Transliteration', _showTranslit, accent, fg, line, (v) {
                  setState(() => _showTranslit = v);
                  setSheet(() {});
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionRow(
    String label, bool value, Color accent, Color fg, Color line,
    ValueChanged<bool> onChanged,
  ) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(color: fg, fontSize: 14)),
            Switch.adaptive(value: value, onChanged: onChanged, activeTrackColor: accent),
          ],
        ),
      );

  String get _title {
    if (_isPagedType) return _meta!.title;
    if (_chapters.isEmpty) return _meta!.title;
    return _chapters.firstWhere(
      (c) => c.number == _currentChapter, orElse: () => _chapters.first,
    ).name;
  }

  String get _subLabel {
    if (_isPagedType) return '${_meta!.chapterLabel} $_currentChapter of ${_meta!.totalChapters}';
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
                  GestureDetector(
                    onTap: _openReadingOptions,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: accent.withValues(alpha: 0.3)),
                      ),
                      child: Icon(Icons.tune_rounded, size: 14, color: accent),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                _loading ? '' : _subLabel.toUpperCase(),
                style: GoogleFonts.jetBrainsMono(fontSize: 9, letterSpacing: 1.5, color: muted),
              ),
            ),
            Divider(height: 1, color: line),
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
                            showTranslation: _showTranslation,
                            showTranslit: _showTranslit,
                          ),
                        ),
            ),
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
                  _navBtn(
                    icon: Icons.format_list_bulleted_rounded,
                    color: muted,
                    onTap: _openToc,
                  ),
                  _navBtn(
                    icon: Icons.arrow_forward_ios_rounded,
                    color: _currentChapter < (_meta?.totalChapters ?? 1) ? fg : muted,
                    onTap: _currentChapter < (_meta?.totalChapters ?? 1) ? () => _goTo(_currentChapter + 1) : null,
                  ),
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

class _VerseCard extends StatelessWidget {
  const _VerseCard({
    required this.verse,
    required this.type,
    required this.accent,
    required this.fg,
    required this.muted,
    required this.showTranslation,
    required this.showTranslit,
  });

  final ScriptureVerse verse;
  final ScriptureTextType type;
  final Color accent;
  final Color fg;
  final Color muted;
  final bool showTranslation;
  final bool showTranslit;

  @override
  Widget build(BuildContext context) => switch (type) {
        ScriptureTextType.quran  => _quranCard(),
        ScriptureTextType.ggs    => _sikhCard(),
        ScriptureTextType.dasam  => _sikhCard(),
        ScriptureTextType.bgv    => _sikhCard(),
        ScriptureTextType.gita    => _gitaCard(),
        ScriptureTextType.bible   => _bibleCard(),
        ScriptureTextType.hadith  => _hadithCard(),
        ScriptureTextType.ramayana => _gitaCard(),
      };

  Widget _hadithCard() {
    final meta = verse.wordMeanings ?? '';
    final parts = meta.split('\n');
    final narrator = parts.isNotEmpty ? parts[0].trim() : '';
    final grade = parts.length > 1 ? parts[1].trim() : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (verse.isGroupStart && (verse.groupLabel?.isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                verse.groupLabel!.toUpperCase(),
                style: GoogleFonts.jetBrainsMono(fontSize: 8, letterSpacing: 2, color: muted),
              ),
            ),
          if (verse.original != null) ...[
            Text(
              verse.original!,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontSize: 16, height: 2.0, fontFamily: 'serif'),
            ),
            const SizedBox(height: 8),
          ],
          if (showTranslation) ...[
            Text(verse.translation, style: GoogleFonts.inter(fontSize: 13, height: 1.65, color: fg)),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (narrator.isNotEmpty)
                  Expanded(
                    child: Text(
                      narrator,
                      style: GoogleFonts.inter(fontSize: 11, color: muted, fontStyle: FontStyle.italic),
                    ),
                  ),
                if (grade.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      grade,
                      style: GoogleFonts.jetBrainsMono(fontSize: 8, color: accent),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

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
            if (showTranslit && verse.transliteration != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  verse.transliteration!,
                  style: GoogleFonts.inter(fontSize: 12, height: 1.6, color: muted, fontStyle: FontStyle.italic),
                ),
              ),
            if (showTranslation)
              Text(verse.translation, style: GoogleFonts.inter(fontSize: 13, height: 1.65, color: fg)),
          ],
        ),
      );

  Widget _sikhCard() => Padding(
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
            if (showTranslit && verse.transliteration != null) ...[
              const SizedBox(height: 6),
              Text(
                verse.transliteration!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12, height: 1.6,
                  color: fg.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (showTranslation) ...[
              const SizedBox(height: 6),
              Text(verse.translation, style: GoogleFonts.inter(fontSize: 13, height: 1.65, color: fg)),
            ],
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
            if (showTranslit && verse.transliteration != null) ...[
              const SizedBox(height: 8),
              Text(
                verse.transliteration!,
                style: GoogleFonts.inter(fontSize: 12, height: 1.6, color: fg, fontStyle: FontStyle.italic),
              ),
            ],
            if (showTranslation) ...[
              const SizedBox(height: 8),
              Text(verse.translation, style: GoogleFonts.inter(fontSize: 13, height: 1.65, color: fg)),
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
}
