import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/scripture.dart';
import '../../core/models/quran_page_mapper.dart';
import '../../core/theme/app_colors.dart';
import '../../data/scripture_repository.dart';
import '../../providers/scripture_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/reading_plan_provider.dart';
import '../../core/models/reading_plan.dart';
import '../../providers/download_provider.dart';
import '../../core/models/saved_verse.dart';
import '../../providers/saved_verses_provider.dart';
import '../../providers/share_card_style_provider.dart';
import '../../services/share_service.dart';
import 'toc_sheet.dart' show showTocSheet, showPagedTocSheet;

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    super.key,
    required this.textId,
    this.initialChapter,
    this.hidePlanBanner = false,
  });

  final String textId;
  final int? initialChapter;
  final bool hidePlanBanner;

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
  bool _quranPageMode = false; // true = reading-plan paged mode; false = surah mode
  bool _browseMode = false; // true = opened via "Browse", ignore plan UI entirely
  bool _dismissedEndCard = false;
  bool _waitingForDownload = false;
  bool _searching = false;
  String _searchQuery = '';
  bool _reachedBottom = false;
  Set<int> _bookmarkedPages = {};
  String? _verseBookmark;
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _browseMode = widget.hidePlanBanner;
    _loadPrefs();
    _meta = ScriptureTextMeta.forTextId(widget.textId);
    if (_meta == null) {
      _error = 'Unsupported text: ${widget.textId}';
      _loading = false;
    } else {
      final downloadStatus = ref.read(downloadProvider)[widget.textId]?.status;
      if (downloadStatus == TextDownloadStatus.downloaded) {
        _load();
      } else {
        setState(() {
          _loading = false;
          _waitingForDownload = true;
        });
      }
    }
    _scrollCtrl.addListener(() {
      if (!_reachedBottom &&
          _scrollCtrl.hasClients &&
          _scrollCtrl.position.pixels >=
              _scrollCtrl.position.maxScrollExtent - 80) {
        setState(() => _reachedBottom = true);
      }
    });
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final bookmarkRaw = prefs.getStringList('page_bookmarks_${widget.textId}') ?? [];
    setState(() {
      _showTranslation = prefs.getBool('reader_show_translation') ?? true;
      _showTranslit = prefs.getBool('reader_show_translit') ?? true;
      _bookmarkedPages = bookmarkRaw.map(int.parse).toSet();
      _verseBookmark = prefs.getString('verse_bookmark_${widget.textId}');
    });
  }

  @override
  void dispose() {
    final plan = ref.read(readingPlanProvider).planForText(widget.textId);
    if (plan != null && !_loading && !_browseMode) {
      ref.read(readingPlanProvider.notifier).updateLastRead(plan.id, _currentChapter);
    }
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  bool get _onlyOriginal => !_showTranslation && !_showTranslit;

  int get _effectiveUnitForPlan => _currentChapter;

  List<ScriptureVerse> get _displayVerses {
    if (!_searching || _searchQuery.isEmpty) return _verses;
    final q = _searchQuery.toLowerCase();
    return _verses.where((v) =>
      v.translation.toLowerCase().contains(q) ||
      (v.original?.toLowerCase().contains(q) ?? false) ||
      (v.transliteration?.toLowerCase().contains(q) ?? false) ||
      (v.groupLabel?.toLowerCase().contains(q) ?? false)
    ).toList();
  }

  bool get _isPagedType =>
      (_meta!.type == ScriptureTextType.quran && _quranPageMode) ||
      _meta!.type == ScriptureTextType.ggs ||
      _meta!.type == ScriptureTextType.dasam ||
      _meta!.type == ScriptureTextType.bgv ||
      _meta!.type == ScriptureTextType.hadith ||
      _meta!.type == ScriptureTextType.ramayana ||
      _meta!.type == ScriptureTextType.bani;

  // Max chapter/page for the current text and mode.
  int get _maxChapter {
    if (_meta!.type == ScriptureTextType.quran) {
      return _quranPageMode ? QuranPageMapper.totalSurahBreakPages : 114;
    }
    return _meta!.totalChapters;
  }

  bool get _isSikhType =>
      _meta!.type == ScriptureTextType.ggs ||
      _meta!.type == ScriptureTextType.dasam ||
      _meta!.type == ScriptureTextType.bgv ||
      _meta!.type == ScriptureTextType.bani;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstOpen = !prefs.containsKey('reader_pos_${widget.textId}');
    final saved = ref.read(scripturePositionProvider).getPosition(widget.textId);

    if (_meta!.type == ScriptureTextType.quran) {
      _chapters = await _repo.loadChapters(widget.textId);
      final plan = ref.read(readingPlanProvider).planForText(widget.textId);
      _quranPageMode = plan != null && !_browseMode;
      final raw = widget.initialChapter ?? saved.$1;
      if (_quranPageMode) {
        _currentChapter = raw.clamp(1, QuranPageMapper.totalSurahBreakPages);
      } else {
        // Convert old page-based position (>114) to surah number.
        _currentChapter = raw > 114
            ? QuranPageMapper.pageToSurah(raw.clamp(1, QuranPageMapper.totalPages))
            : raw.clamp(1, 114);
      }
    } else {
      _currentChapter = widget.initialChapter ?? saved.$1;
    }

    try {
      if (_isPagedType) {
        _verses = await _loadPagedVerses(_currentChapter);
        _prefetch(_currentChapter);
      } else {
        if (_meta!.type != ScriptureTextType.quran) {
          _chapters = await _repo.loadChapters(widget.textId);
        }
        _verses = _versesFor(_currentChapter);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
      return;
    }
    if (mounted) {
      setState(() => _loading = false);
      if (isFirstOpen && !_isSikhType && widget.initialChapter == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openToc();
        });
      }
    }
  }

  Future<List<ScriptureVerse>> _loadPagedVerses(int page) {
    return switch (_meta!.type) {
      ScriptureTextType.quran    => _repo.loadQuranSurahBreakPage(page),
      ScriptureTextType.ggs      => _repo.loadGgsAng(page),
      ScriptureTextType.dasam    => _repo.loadDasamPage(page),
      ScriptureTextType.bgv      => _repo.loadBgvVaar(page),
      ScriptureTextType.hadith   => _repo.loadHadithChapter(widget.textId, page),
      ScriptureTextType.ramayana => _repo.loadRamayanaSarga(page),
      ScriptureTextType.bani     => _repo.loadBani(widget.textId),
      _ => Future.value([]),
    };
  }

  void _prefetch(int page) {
    if (page > 1) _loadPagedVerses(page - 1);
    if (page < _maxChapter) _loadPagedVerses(page + 1);
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
    if (num < 1 || num > _maxChapter) return;
    setState(() { _loading = true; _dismissedEndCard = false; _reachedBottom = false; });
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
    final plan = ref.read(readingPlanProvider).planForText(widget.textId);
    if (plan != null && !_browseMode) {
      await ref.read(readingPlanProvider.notifier).updateLastRead(plan.id, num);
    }
    if (mounted) {
      setState(() => _loading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(0);
      });
    }
  }

  Future<void> _openToc() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ReligionColors.accent(_meta!.religionId);
    int? result;

    if (_meta!.type == ScriptureTextType.quran) {
      result = await showTocSheet(
        context: context, meta: _meta!, chapters: _chapters,
        currentChapter: _quranPageMode
            ? QuranPageMapper.surahBreakPageToSurah(_currentChapter)
            : _currentChapter,
        accent: accent, isDark: isDark,
      );
      if (result != null) {
        await _goTo(_quranPageMode
            ? QuranPageMapper.surahToSurahBreakPage(result)
            : result);
      }
      return;
    }

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
              _optionRow('Translation', _showTranslation, accent, fg, line, (v) async {
                setState(() => _showTranslation = v);
                setSheet(() {});
                final prefs = await SharedPreferences.getInstance();
                prefs.setBool('reader_show_translation', v);
              }),
              Divider(height: 1, color: line),
              if (_meta?.hasTransliteration ?? false)
                _optionRow('Transliteration', _showTranslit, accent, fg, line, (v) async {
                  setState(() => _showTranslit = v);
                  setSheet(() {});
                  final prefs = await SharedPreferences.getInstance();
                  prefs.setBool('reader_show_translit', v);
                }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _togglePageBookmark() async {
    final page = _currentChapter;
    setState(() {
      if (_bookmarkedPages.contains(page)) {
        _bookmarkedPages.remove(page);
      } else {
        _bookmarkedPages.add(page);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'page_bookmarks_${widget.textId}',
      _bookmarkedPages.map((p) => '$p').toList(),
    );
  }

  Future<void> _toggleVerseBookmark(ScriptureVerse verse) async {
    final key = '$_currentChapter:${verse.number}';
    final removing = _verseBookmark == key;
    setState(() => _verseBookmark = removing ? null : key);
    final prefs = await SharedPreferences.getInstance();
    if (removing) {
      await prefs.remove('verse_bookmark_${widget.textId}');
    } else {
      await prefs.setString('verse_bookmark_${widget.textId}', key);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          removing ? 'Verse bookmark removed' : 'Verse bookmarked',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ));
    }
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
    if (_isPagedType) return '${_meta!.chapterLabel} $_currentChapter of $_maxChapter';
    if (_chapters.isEmpty) return '';
    final ch = _chapters.firstWhere(
      (c) => c.number == _currentChapter, orElse: () => _chapters.first,
    );
    if (ch.meta != null && ch.meta!.isNotEmpty) return ch.meta!;
    return '${ch.verseCount} ${_meta!.verseLabel}s';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Map<String, DownloadInfo>>(downloadProvider, (prev, next) {
      final prevStatus = prev?[widget.textId]?.status;
      final nextStatus = next[widget.textId]?.status;
      if (_waitingForDownload &&
          mounted &&
          prevStatus != TextDownloadStatus.downloaded &&
          nextStatus == TextDownloadStatus.downloaded) {
        setState(() => _waitingForDownload = false);
        _load();
      }
    });

    // Reading plans load async from Firestore. If _load() ran before plans
    // finished loading, _quranPageMode may be wrong — fix it here.
    ref.listen<ReadingPlanState>(readingPlanProvider, (prev, next) {
      if ((prev?.isLoading ?? true) && !next.isLoading &&
          mounted && _meta?.type == ScriptureTextType.quran && !_loading) {
        final hasPlan = next.planForText(widget.textId) != null;
        if (hasPlan != _quranPageMode && !_browseMode) {
          _quranPageMode = hasPlan;
          final target = hasPlan
              ? QuranPageMapper.surahToSurahBreakPage(_currentChapter.clamp(1, 114))
              : QuranPageMapper.surahBreakPageToSurah(
                  _currentChapter.clamp(1, QuranPageMapper.totalSurahBreakPages));
          _goTo(target);
        }
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.nightBg : AppColors.boneBg;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final line = isDark ? AppColors.nightLine : AppColors.boneLine;
    final accent = _meta != null ? ReligionColors.accent(_meta!.religionId) : AppColors.islamGreen;

    final plan = ref.watch(readingPlanProvider).planForText(widget.textId);
    final showEndCard = plan != null &&
        !_browseMode &&
        !plan.todayDone &&
        !_dismissedEndCard &&
        _reachedBottom &&
        _effectiveUnitForPlan >= plan.todayEndUnit;

    if (_error != null) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(child: Text(_error!, style: GoogleFonts.inter(color: muted))),
      );
    }

    if (_waitingForDownload) {
      final info = ref.watch(downloadProvider)[widget.textId];
      return _buildDownloadingScaffold(context, info);
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
                  if (_searching) ...[
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        autofocus: true,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: GoogleFonts.inter(fontSize: 14, color: fg),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Search verses...',
                          hintStyle: GoogleFonts.inter(fontSize: 14, color: muted),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _searching = false;
                        _searchQuery = '';
                        _searchCtrl.clear();
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        margin: const EdgeInsets.only(right: 10),
                        child: Icon(Icons.close_rounded, size: 18, color: muted),
                      ),
                    ),
                  ] else ...[
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
                      onTap: () => setState(() => _searching = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        margin: const EdgeInsets.only(right: 4),
                        child: Icon(Icons.search_rounded, size: 18, color: muted),
                      ),
                    ),
                    GestureDetector(
                      onTap: _loading ? null : _togglePageBookmark,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Icon(
                          _bookmarkedPages.contains(_currentChapter)
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          size: 18,
                          color: _bookmarkedPages.contains(_currentChapter) ? accent : muted,
                        ),
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
                  ],
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
            if (plan != null && !_loading && !widget.hidePlanBanner && !_browseMode)
              _TodayBanner(plan: plan, accent: accent, fg: fg, muted: muted),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(strokeWidth: 1.5, color: accent))
                  : _verses.isEmpty
                      ? Center(child: Text('No content available', style: GoogleFonts.inter(color: muted, fontSize: 13)))
                      : _searching && _searchQuery.isNotEmpty && _displayVerses.isEmpty
                          ? Center(child: Text('No verses found', style: GoogleFonts.inter(color: muted, fontSize: 13)))
                          : (_onlyOriginal && _isSikhType)
                              ? _buildGurbaniParagraphView(accent, fg)
                              : ListView.separated(
                                  controller: _scrollCtrl,
                                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
                                  itemCount: _displayVerses.length,
                                  separatorBuilder: (_, _) => _onlyOriginal
                                      ? const SizedBox.shrink()
                                      : Divider(height: 1, color: line),
                                  itemBuilder: (_, i) => _VerseCard(
                                    verse: _displayVerses[i],
                                    type: _meta!.type,
                                    accent: accent,
                                    fg: fg,
                                    muted: muted,
                                    showTranslation: _showTranslation,
                                    showTranslit: _showTranslit,
                                    onlyOriginal: _onlyOriginal,
                                    textId: widget.textId,
                                    currentChapter: _currentChapter,
                                    isVerseBookmarked: _verseBookmark == '$_currentChapter:${_displayVerses[i].number}',
                                    onLongPress: () => _showVerseOptions(_displayVerses[i]),
                                  ),
                                ),
            ),
            if (showEndCard)
              _EndCard(
                plan: plan,
                accent: accent,
                fg: fg,
                muted: muted,
                line: line,
                onMarkDone: () =>
                    ref.read(readingPlanProvider.notifier).markTodayDone(plan.id),
                onReadOn: () => setState(() => _dismissedEndCard = true),
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
                    color: _currentChapter < _maxChapter ? fg : muted,
                    onTap: _currentChapter < _maxChapter ? () => _goTo(_currentChapter + 1) : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadingScaffold(BuildContext context, DownloadInfo? info) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.nightBg : AppColors.boneBg;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final accent = _meta != null
        ? ReligionColors.accent(_meta!.religionId)
        : (isDark ? AppColors.nightFg : AppColors.boneFg);

    final progress = info?.progress ?? 0.0;
    final isFailed = info?.status == TextDownloadStatus.failed;
    final isDownloading = info?.status == TextDownloadStatus.downloading;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48, height: 48,
                child: isFailed
                    ? Icon(Icons.cloud_off_rounded, color: muted, size: 32)
                    : CircularProgressIndicator(
                        value: isDownloading && progress > 0 ? progress : null,
                        color: accent,
                        strokeWidth: 2,
                      ),
              ),
              const SizedBox(height: 28),
              Text(
                isFailed ? 'DOWNLOAD FAILED' : 'DOWNLOADING SCRIPTURE',
                style: GoogleFonts.jetBrainsMono(
                  color: muted,
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isFailed
                    ? 'Check your connection'
                    : isDownloading && progress > 0
                        ? '${(progress * 100).round()}%'
                        : _meta?.title ?? '',
                style: GoogleFonts.cormorantGaramond(
                  color: fg,
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (isFailed) ...[
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    setState(() => _waitingForDownload = true);
                    ref.read(downloadProvider.notifier).retryText(widget.textId);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: accent.withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'RETRY',
                      style: GoogleFonts.jetBrainsMono(
                        color: accent,
                        fontSize: 10,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _navBtn({required IconData icon, required Color color, VoidCallback? onTap}) =>
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(width: 48, height: 48, child: Icon(icon, size: 17, color: color)),
      );

  String _verseReference(ScriptureVerse verse) => switch (_meta!.type) {
    ScriptureTextType.quran    => 'Quran ${verse.wordMeanings ?? _currentChapter}:${verse.number}',
    ScriptureTextType.bible    => '${_meta!.title} $_currentChapter:${verse.number}',
    ScriptureTextType.gita     => 'Bhagavad Gita $_currentChapter.${verse.number}',
    ScriptureTextType.ggs      => 'Guru Granth Sahib Ang $_currentChapter',
    ScriptureTextType.dasam    => 'Dasam Granth Page $_currentChapter',
    ScriptureTextType.bgv      => 'Bhai Gurdas Vaaran $_currentChapter',
    ScriptureTextType.hadith   => '${_meta!.title} — ${verse.groupLabel ?? 'Chapter $_currentChapter'}',
    ScriptureTextType.ramayana => 'Valmiki Ramayana — Sarga $_currentChapter, Verse ${verse.number}',
    ScriptureTextType.bani     => '${_meta!.title} — Line ${verse.number}',
  };

  void _askAboutVerse(ScriptureVerse verse) {
    ref.read(chatProvider.notifier).startSessionFromVerse(
      reference: _verseReference(verse),
      originalText: verse.original ?? verse.transliteration ?? '',
      translation: verse.translation,
      religionId: _meta!.religionId,
      textId: widget.textId,
    );
    context.go('/home');
  }

  void _copyVerse(ScriptureVerse verse) {
    final parts = <String>[];
    if (verse.original != null) parts.add(verse.original!);
    if (verse.transliteration != null) parts.add(verse.transliteration!);
    parts.add(verse.translation);
    parts.add('— ${_verseReference(verse)}');
    Clipboard.setData(ClipboardData(text: parts.join('\n\n')));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Verse copied', style: GoogleFonts.inter(fontSize: 13)),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveVerse(ScriptureVerse verse) async {
    final id = SavedVerse.makeId(widget.textId, _currentChapter, verse.number);
    final notifier = ref.read(savedVersesProvider.notifier);
    final wasSaved = notifier.isSaved(id);
    await notifier.toggle(SavedVerse(
      id: id,
      textId: widget.textId,
      reference: _verseReference(verse),
      text: verse.original ?? verse.translation,
      translation: verse.original != null ? verse.translation : null,
      savedAt: DateTime.now(),
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasSaved ? 'Verse removed from saved' : 'Verse saved',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _shareVerse(ScriptureVerse verse) {
    showShareSheet(
      context,
      text: verse.original ?? verse.translation,
      reference: _verseReference(verse),
      religionId: _meta!.religionId,
      translation: verse.original != null ? verse.translation : null,
      template: ref.read(shareCardStyleProvider),
    );
  }

  void _showVerseOptions(ScriptureVerse verse) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.nightBg : Colors.white;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final accent = _meta != null ? ReligionColors.accent(_meta!.religionId) : AppColors.islamGreen;

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: muted.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _verseReference(verse),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.jetBrainsMono(
                      color: muted, fontSize: 10, letterSpacing: 1.2),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  verse.translation,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      color: fg.withValues(alpha: 0.7),
                      fontSize: 12,
                      height: 1.5),
                ),
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: muted.withValues(alpha: 0.15)),
              _DialogOption(
                icon: Icons.auto_awesome_rounded,
                label: 'Ask AI about this verse',
                color: accent,
                onTap: () {
                  Navigator.pop(ctx);
                  _askAboutVerse(verse);
                },
              ),
              Divider(height: 1, color: muted.withValues(alpha: 0.15)),
              _DialogOption(
                icon: Icons.copy_rounded,
                label: 'Copy verse',
                color: fg,
                onTap: () {
                  Navigator.pop(ctx);
                  _copyVerse(verse);
                },
              ),
              Divider(height: 1, color: muted.withValues(alpha: 0.15)),
              _DialogOption(
                icon: ref.watch(savedVersesProvider.select((list) => list.any(
                      (v) => v.id == SavedVerse.makeId(widget.textId, _currentChapter, verse.number),
                    )))
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                label: ref.watch(savedVersesProvider.select((list) => list.any(
                      (v) => v.id == SavedVerse.makeId(widget.textId, _currentChapter, verse.number),
                    )))
                    ? 'Remove from saved'
                    : 'Save verse',
                color: fg,
                onTap: () {
                  Navigator.pop(ctx);
                  _saveVerse(verse);
                },
              ),
              Divider(height: 1, color: muted.withValues(alpha: 0.15)),
              _DialogOption(
                icon: _verseBookmark == '$_currentChapter:${verse.number}'
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_add_outlined,
                label: _verseBookmark == '$_currentChapter:${verse.number}'
                    ? 'Remove verse bookmark'
                    : 'Bookmark this verse',
                color: _verseBookmark == '$_currentChapter:${verse.number}' ? accent : fg,
                onTap: () {
                  Navigator.pop(ctx);
                  _toggleVerseBookmark(verse);
                },
              ),
              Divider(height: 1, color: muted.withValues(alpha: 0.15)),
              _DialogOption(
                icon: Icons.ios_share_rounded,
                label: 'Share verse',
                color: fg,
                onTap: () {
                  Navigator.pop(ctx);
                  _shareVerse(verse);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // Groups flat verse list into pauri-sized chunks for paragraph rendering.
  // Splits at: section-title verses (start with ॥), isGroupStart, or pauri-end (ends ॥N॥).
  static List<List<ScriptureVerse>> _groupIntoPauris(List<ScriptureVerse> verses) {
    final groups = <List<ScriptureVerse>>[];
    var current = <ScriptureVerse>[];
    bool flushNext = false;

    for (final v in verses) {
      final isSectionTitle = v.sectionHeader != 0 || (v.original?.trimLeft().startsWith('॥') ?? false);
      final isPauriEnd = RegExp(r'॥[੦-੯]+॥\s*$').hasMatch(v.original ?? '');

      if (current.isNotEmpty && (flushNext || v.isGroupStart || isSectionTitle)) {
        groups.add(List.from(current));
        current = [];
      }

      current.add(v);
      flushNext = isPauriEnd || isSectionTitle;
    }
    if (current.isNotEmpty) groups.add(current);
    return groups;
  }

  Widget _buildGurbaniParagraphView(Color accent, Color fg) {
    final groups = _groupIntoPauris(_displayVerses);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
      itemCount: groups.length,
      itemBuilder: (_, i) {
        final verses = groups[i];
        if (verses.isEmpty) return const SizedBox.shrink();

        final first = verses.first;
        final isSectionTitle = first.sectionHeader != 0 || (first.original?.trimLeft().startsWith('॥') ?? false);

        if (isSectionTitle) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              first.original ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                height: 1.9,
                color: accent,
              ),
            ),
          );
        }

        final combined = verses
            .where((v) => v.original != null)
            .map((v) => v.original!)
            .join(' ');

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            combined,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: first.isGroupStart ? FontWeight.w700 : FontWeight.normal,
              height: 1.9,
              color: accent,
            ),
          ),
        );
      },
    );
  }
}

class _VerseCard extends ConsumerWidget {
  const _VerseCard({
    required this.verse,
    required this.type,
    required this.accent,
    required this.fg,
    required this.muted,
    required this.showTranslation,
    required this.showTranslit,
    required this.onlyOriginal,
    required this.textId,
    required this.currentChapter,
    this.isVerseBookmarked = false,
    this.onLongPress,
  });

  final ScriptureVerse verse;
  final ScriptureTextType type;
  final Color accent;
  final Color fg;
  final Color muted;
  final bool showTranslation;
  final bool showTranslit;
  final bool onlyOriginal;
  final String textId;
  final int currentChapter;
  final bool isVerseBookmarked;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = switch (type) {
      ScriptureTextType.quran    => _quranCard(context, ref),
      ScriptureTextType.ggs      => _sikhCard(),
      ScriptureTextType.dasam    => _sikhCard(),
      ScriptureTextType.bgv      => _sikhCard(),
      ScriptureTextType.bani     => _sikhCard(),
      ScriptureTextType.gita     => _gitaCard(),
      ScriptureTextType.bible    => _bibleCard(),
      ScriptureTextType.hadith   => _hadithCard(),
      ScriptureTextType.ramayana => _gitaCard(),
    };
    return GestureDetector(
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: isVerseBookmarked
          ? Container(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: accent, width: 3)),
              ),
              padding: const EdgeInsets.only(left: 10),
              child: card,
            )
          : card,
    );
  }

  Widget _hadithCard() {
    final meta = verse.wordMeanings ?? '';
    final parts = meta.split('\n');
    final narrator = parts.isNotEmpty ? parts[0].trim() : '';
    final grade = parts.length > 1 ? parts[1].trim() : '';
    return Padding(
      padding: EdgeInsets.symmetric(vertical: onlyOriginal ? 20.0 : 14.0),
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

  Widget _quranCard(BuildContext context, WidgetRef ref) {
    final chNum = int.tryParse(verse.wordMeanings ?? '') ?? currentChapter;
    final id = SavedVerse.makeId(textId, chNum, verse.number);
    final isSaved = ref.watch(savedVersesProvider).any((sv) => sv.id == id);

    // Number circle widget — placed inline at the end of the Arabic text.
    Widget numberCircle = Container(
      width: 22,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accent, width: 1.5),
      ),
      child: Center(
        child: Text('${verse.number}',
            style: GoogleFonts.jetBrainsMono(fontSize: 8, color: accent)),
      ),
    );

    if (isSaved) {
      numberCircle = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bookmark, size: 14, color: accent),
          const SizedBox(width: 2),
          numberCircle,
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: onlyOriginal ? 24.0 : 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (verse.isGroupStart && (verse.groupLabel?.isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 4),
              child: Text(
                verse.groupLabel!,
                textAlign: TextAlign.center,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  color: accent,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          if (verse.original != null)
            RichText(
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              text: TextSpan(
                style: TextStyle(
                    fontSize: 20, height: 2.0, fontFamily: 'serif', color: fg),
                children: [
                  TextSpan(text: verse.original!),
                  // WidgetSpan appended after last Arabic word → sits at the
                  // left end of the final line in RTL flow.
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: numberCircle,
                  ),
                ],
              ),
            ),
          if (showTranslit && verse.transliteration != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 6),
              child: Text(
                verse.transliteration!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.6,
                    color: muted,
                    fontStyle: FontStyle.italic),
              ),
            ),
          if (showTranslation)
            Text(
              verse.translation,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, height: 1.65, color: fg),
            ),
        ],
      ),
    );
  }

  Widget _sikhCard() {
    // GGS uses heuristic (starts with ॥); other types use BaniDB sectionHeader field.
    final isSectionTitle = type == ScriptureTextType.ggs
        ? (verse.original?.trimLeft().startsWith('॥') ?? false)
        : verse.sectionHeader != 0;

    // Pauri-end verse: Gurmukhi ends with ॥<Gurmukhi numeral(s)>॥ e.g. ॥੧॥
    final isPauriEnd = type != ScriptureTextType.ggs &&
        RegExp(r'॥[੦-੯]+॥\s*$').hasMatch(verse.original ?? '');

    // First verse of a new pauri that isn't itself a section title → bold Gurmukhi
    final isNewPauriStart =
        type != ScriptureTextType.ggs && verse.isGroupStart && !isSectionTitle;

    return Padding(
      padding: EdgeInsets.only(
        top: isSectionTitle ? 16.0 : (onlyOriginal ? 4.0 : 8.0),
        bottom: isPauriEnd ? 20.0 : (onlyOriginal ? 4.0 : 8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // GGS only: small muted ang/pauri label
          if (type == ScriptureTextType.ggs &&
              verse.isGroupStart &&
              (verse.groupLabel?.isNotEmpty ?? false))
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
              style: TextStyle(
                fontSize: isSectionTitle ? 19.0 : 17.0,
                fontWeight: (isSectionTitle || isNewPauriStart)
                    ? FontWeight.w700
                    : FontWeight.normal,
                height: 1.9,
                color: accent,
              ),
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
  }

  Widget _gitaCard() => Padding(
        padding: EdgeInsets.symmetric(vertical: onlyOriginal ? 22.0 : 16.0),
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

class _TodayBanner extends StatelessWidget {
  const _TodayBanner({
    required this.plan,
    required this.accent,
    required this.fg,
    required this.muted,
  });

  final ReadingPlan plan;
  final Color accent, fg, muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.today_rounded, color: accent, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TODAY · DAY ${plan.dayNumber}',
                  style: GoogleFonts.jetBrainsMono(
                      color: accent, fontSize: 8, letterSpacing: 1.5),
                ),
                Text(
                  '${plan.unitLabel.toUpperCase()} ${plan.todayStartUnit}–${plan.todayEndUnit}',
                  style: GoogleFonts.inter(
                      color: fg, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          if (plan.todayDone)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '✓ DONE',
                style: GoogleFonts.jetBrainsMono(color: accent, fontSize: 8),
              ),
            ),
        ],
      ),
    );
  }
}

class _EndCard extends StatelessWidget {
  const _EndCard({
    required this.plan,
    required this.accent,
    required this.fg,
    required this.muted,
    required this.line,
    required this.onMarkDone,
    required this.onReadOn,
  });

  final ReadingPlan plan;
  final Color accent, fg, muted, line;
  final VoidCallback onMarkDone, onReadOn;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        border: Border(top: BorderSide(color: accent.withValues(alpha: 0.2))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            "Today's portion complete",
            style: GoogleFonts.cormorantGaramond(
              color: fg, fontSize: 18,
              fontWeight: FontWeight.w500, fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Day ${plan.dayNumber} · ${plan.unitLabel} ${plan.todayStartUnit}–${plan.todayEndUnit}',
            style: GoogleFonts.jetBrainsMono(color: muted, fontSize: 9, letterSpacing: 0.8),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onReadOn,
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      border: Border.all(color: line),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'Read on →',
                        style: GoogleFonts.inter(color: fg, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: onMarkDone,
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '✓ Mark Day ${plan.dayNumber}',
                        style: GoogleFonts.inter(
                          color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DialogOption extends StatelessWidget {
  const _DialogOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 14),
            Text(label,
                style: GoogleFonts.inter(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
