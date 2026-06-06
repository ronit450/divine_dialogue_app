# Quran 8-Ayaat Paging + Bookmarks Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Quran reader navigate by 8-ayaat pages (1–780), trigger the reading-plan end card only after scrolling to the bottom, and add verse-level (long press) and page-level (header icon) bookmarks.

**Architecture:** The Quran is moved from chapter-based (surah 1–114) to paged (page 1–780). `QuranPageMapper.buildPageVerses` slices the preloaded surah list into 8-ayaat windows, encoding surah boundaries via `ScriptureVerse.isGroupStart`/`groupLabel`. The reader's `_isPagedType` gains Quran, but the TOC retains the surah-list sheet (navigating to the page that starts the selected surah). Bookmarks reuse the existing `SavedVersesNotifier.toggle` for verse bookmarks and `SharedPreferences` for page bookmarks.

**Tech Stack:** Flutter 3.x, Dart, Riverpod (`StateNotifierProvider`), SharedPreferences, Cloud Firestore, `ScriptureVerse`, `ScriptureChapter`, `ScriptureTextMeta`, `SavedVersesNotifier`

---

## Files

| File | Change |
|---|---|
| `lib/core/models/quran_page_mapper.dart` | Add `buildPageVerses(page, surahs)` + private `_surahIndexForGlobal(g)` |
| `lib/core/models/scripture.dart` | Update quran `ScriptureTextMeta`: `chapterLabel:'Page'`, `totalChapters:780` |
| `lib/data/scripture_repository.dart` | Add `_quranChapters` cache + `loadQuranPage(int page)` |
| `lib/features/reader/reader_screen.dart` | Quran → paged; scroll-bottom end card; long-press verse action sheet; page bookmark header icon; fix `_effectiveUnitForPlan`; fix reference/share labels; TOC for Quran |
| `lib/features/library/library_screen.dart` | "Continue Plan" → pass page number directly (no surahToPage conversion for Quran) |

---

## Task 1: QuranPageMapper — `buildPageVerses`

**Files:**
- Modify: `lib/core/models/quran_page_mapper.dart`

- [ ] **Step 1: Add import for ScriptureChapter at top of file**

  ```dart
  import 'scripture.dart';
  ```

- [ ] **Step 2: Add `_surahIndexForGlobal` private helper**

  After `surahLastPage`, add:

  ```dart
  /// Returns the 0-based surah index that contains 0-based global verse [g].
  static int _surahIndexForGlobal(int g) {
    int lo = 0, hi = _verseCounts.length - 1;
    while (lo < hi) {
      final mid = (lo + hi) ~/ 2;
      if (_cumulative[mid + 1] <= g) lo = mid + 1;
      else hi = mid;
    }
    return lo;
  }
  ```

- [ ] **Step 3: Add `buildPageVerses` method**

  ```dart
  /// Slices [allSurahs] into up to [versesPerPage] verses for [page] (1-based).
  /// Sets [ScriptureVerse.isGroupStart] and [ScriptureVerse.groupLabel] at surah
  /// boundaries, and stores the surah number as a string in [ScriptureVerse.wordMeanings]
  /// so the reader can build references like "2:5".
  static List<ScriptureVerse> buildPageVerses(
      int page, List<ScriptureChapter> allSurahs) {
    final globalStart = (page - 1) * versesPerPage;
    final globalEnd = (page * versesPerPage - 1).clamp(0, totalVerses - 1);
    final result = <ScriptureVerse>[];
    int lastSurahNum = -1;

    for (int g = globalStart; g <= globalEnd; g++) {
      final surahIdx = _surahIndexForGlobal(g);
      final surahNum = surahIdx + 1;
      final verseIdx = g - _cumulative[surahIdx];
      final surah = allSurahs[surahIdx];
      final v = surah.verses[verseIdx];
      final isNewSurah = surahNum != lastSurahNum;

      result.add(ScriptureVerse(
        number: v.number,
        original: v.original,
        translation: v.translation,
        transliteration: v.transliteration,
        wordMeanings: '$surahNum',
        isGroupStart: isNewSurah,
        groupLabel: isNewSurah ? surah.name : null,
      ));
      lastSurahNum = surahNum;
    }
    return result;
  }
  ```

- [ ] **Step 4: Verify no analysis errors**

  ```bash
  cd /home/ronit/Ronit-Personal/Personal/divine-dialogue/codes/divine_dialogue
  dart analyze lib/core/models/quran_page_mapper.dart
  ```
  Expected: No errors.

- [ ] **Step 5: Commit**

  ```bash
  git add lib/core/models/quran_page_mapper.dart
  git commit -m "feat(quran): add buildPageVerses + _surahIndexForGlobal to QuranPageMapper"
  ```

---

## Task 2: Repository — `loadQuranPage`

**Files:**
- Modify: `lib/data/scripture_repository.dart`

- [ ] **Step 1: Add `_quranChapters` cache field**

  In `ScriptureRepository`, alongside other cache fields, add:

  ```dart
  List<ScriptureChapter>? _quranChapters;
  ```

- [ ] **Step 2: Add `loadQuranPage(int page)` method**

  ```dart
  Future<List<ScriptureVerse>> loadQuranPage(int page) async {
    _quranChapters ??= await loadChapters('quran');
    return QuranPageMapper.buildPageVerses(page, _quranChapters!);
  }
  ```

  Add import at top if not already present:
  ```dart
  import '../core/models/quran_page_mapper.dart';
  ```

- [ ] **Step 3: Verify no analysis errors**

  ```bash
  dart analyze lib/data/scripture_repository.dart
  ```
  Expected: No errors.

- [ ] **Step 4: Commit**

  ```bash
  git add lib/data/scripture_repository.dart
  git commit -m "feat(quran): add loadQuranPage with cached surah backing"
  ```

---

## Task 3: ScriptureTextMeta — update Quran to 780 pages

**Files:**
- Modify: `lib/core/models/scripture.dart` (around line 69)

- [ ] **Step 1: Update quran metadata**

  ```dart
  // BEFORE:
  'quran' => const ScriptureTextMeta(
      id: 'quran', title: 'The Qurʼan', religionId: 'islam',
      type: ScriptureTextType.quran, chapterLabel: 'Surah',
      verseLabel: 'Ayah', totalChapters: 114),

  // AFTER:
  'quran' => const ScriptureTextMeta(
      id: 'quran', title: 'The Qurʼan', religionId: 'islam',
      type: ScriptureTextType.quran, chapterLabel: 'Page',
      verseLabel: 'Ayah', totalChapters: 780),
  ```

- [ ] **Step 2: Verify and commit**

  ```bash
  dart analyze lib/core/models/scripture.dart
  git add lib/core/models/scripture.dart
  git commit -m "feat(quran): update metadata to 780 pages"
  ```

---

## Task 4: Reader — Quran paged navigation + TOC + reference fix

**Files:**
- Modify: `lib/features/reader/reader_screen.dart`

Do all sub-steps in order — they're all in the same file.

### 4a. Add Quran to `_isPagedType` (around line 114)

- [ ] **Step 1:**

  ```dart
  // BEFORE:
  bool get _isPagedType =>
      _meta!.type == ScriptureTextType.ggs ||
      _meta!.type == ScriptureTextType.dasam ||
      _meta!.type == ScriptureTextType.bgv ||
      _meta!.type == ScriptureTextType.hadith ||
      _meta!.type == ScriptureTextType.ramayana ||
      _meta!.type == ScriptureTextType.bani;

  // AFTER:
  bool get _isPagedType =>
      _meta!.type == ScriptureTextType.quran ||
      _meta!.type == ScriptureTextType.ggs ||
      _meta!.type == ScriptureTextType.dasam ||
      _meta!.type == ScriptureTextType.bgv ||
      _meta!.type == ScriptureTextType.hadith ||
      _meta!.type == ScriptureTextType.ramayana ||
      _meta!.type == ScriptureTextType.bani;
  ```

### 4b. Pre-load surah list for Quran TOC during `_load()`

Quran uses a surah-list TOC, so chapters must be loaded even in paged mode. Add this inside `_load()`, after `_currentChapter = ...` and before the `try` block:

- [ ] **Step 2:**

  ```dart
  if (_meta!.type == ScriptureTextType.quran) {
    _chapters = await _repo.loadChapters(widget.textId);
  }
  ```

### 4c. Add Quran to `_loadPagedVerses` switch (around line 157)

- [ ] **Step 3:**

  ```dart
  Future<List<ScriptureVerse>> _loadPagedVerses(int page) {
    return switch (_meta!.type) {
      ScriptureTextType.quran    => _repo.loadQuranPage(page),
      ScriptureTextType.ggs      => _repo.loadGgsAng(page),
      ScriptureTextType.dasam    => _repo.loadDasamPage(page),
      ScriptureTextType.bgv      => _repo.loadBgvVaar(page),
      ScriptureTextType.hadith   => _repo.loadHadithChapter(widget.textId, page),
      ScriptureTextType.ramayana => _repo.loadRamayanaSarga(page),
      ScriptureTextType.bani     => _repo.loadBani(widget.textId),
      _ => Future.value([]),
    };
  }
  ```

### 4d. Fix `_effectiveUnitForPlan` (around line 96)

`_currentChapter` is now a page number for Quran — no conversion needed.

- [ ] **Step 4:**

  ```dart
  // BEFORE:
  int get _effectiveUnitForPlan {
    if (_meta?.type == ScriptureTextType.quran) {
      return QuranPageMapper.surahLastPage(_currentChapter);
    }
    return _currentChapter;
  }

  // AFTER:
  int get _effectiveUnitForPlan => _currentChapter;
  ```

### 4e. Fix `_openToc` for Quran (around line 212)

- [ ] **Step 5:**

  ```dart
  Future<void> _openToc() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ReligionColors.accent(_meta!.religionId);
    int? result;

    if (_meta!.type == ScriptureTextType.quran) {
      result = await showTocSheet(
        context: context, meta: _meta!, chapters: _chapters,
        currentChapter: QuranPageMapper.pageToSurah(_currentChapter),
        accent: accent, isDark: isDark,
      );
      if (result != null) await _goTo(QuranPageMapper.surahToPage(result));
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
  ```

### 4f. Fix Quran share label (around line 621)

- [ ] **Step 6:**

  ```dart
  // BEFORE:
  ScriptureTextType.quran => 'Quran $_currentChapter:${verse.number}',

  // AFTER:
  ScriptureTextType.quran => 'Quran ${verse.wordMeanings ?? _currentChapter}:${verse.number}',
  ```

### 4g. Show surah-change header in `_quranCard()` (around line 980)

When `verse.isGroupStart == true`, show the surah name above the verse.

- [ ] **Step 7: Replace `_quranCard()` entirely:**

  ```dart
  Widget _quranCard() => Padding(
    padding: EdgeInsets.symmetric(vertical: onlyOriginal ? 24.0 : 18.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (verse.isGroupStart && (verse.groupLabel?.isNotEmpty ?? false)) ...[
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
        ],
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
  ```

- [ ] **Step 8: Verify and commit**

  ```bash
  dart analyze lib/features/reader/reader_screen.dart
  git add lib/features/reader/reader_screen.dart
  git commit -m "feat(quran): reader paged by 8-ayaat with surah headers, TOC, reference fix"
  ```

---

## Task 5: Fix library "Continue Plan" for Quran pages

**Files:**
- Modify: `lib/features/library/library_screen.dart`

- [ ] **Step 1: Find `_showReadOrPlanSheet`** — look for `QuranPageMapper.pageToSurah` call inside it:

  ```dart
  // BEFORE (approximate — find the actual lines):
  final chapterArg = plan.textId == 'quran'
      ? QuranPageMapper.pageToSurah(plan.todayStartUnit)
      : plan.todayStartUnit;
  context.push('/read/${plan.textId}', extra: {'chapter': chapterArg});
  ```

- [ ] **Step 2: Remove the Quran conversion — pass page number directly**

  ```dart
  // AFTER:
  context.push('/read/${plan.textId}', extra: {'chapter': plan.todayStartUnit});
  ```

  Remove `QuranPageMapper.pageToSurah` usage. If `QuranPageMapper` is no longer imported elsewhere in the file, remove the import too.

- [ ] **Step 3: Verify and commit**

  ```bash
  dart analyze lib/features/library/library_screen.dart
  git add lib/features/library/library_screen.dart
  git commit -m "fix(library): quran continue plan passes page number directly"
  ```

---

## Task 6: End card — trigger only after scrolling to bottom

**Files:**
- Modify: `lib/features/reader/reader_screen.dart`

- [ ] **Step 1: Add `_reachedBottom` field** (near `_dismissedEndCard`):

  ```dart
  bool _reachedBottom = false;
  ```

- [ ] **Step 2: Add scroll listener in `initState`** (after `_loadPrefs()`):

  ```dart
  _scrollCtrl.addListener(() {
    if (!_reachedBottom &&
        _scrollCtrl.hasClients &&
        _scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 80) {
      setState(() => _reachedBottom = true);
    }
  });
  ```

- [ ] **Step 3: Reset in `_goTo`** — update the existing setState call:

  ```dart
  // BEFORE:
  setState(() { _loading = true; _dismissedEndCard = false; });

  // AFTER:
  setState(() { _loading = true; _dismissedEndCard = false; _reachedBottom = false; });
  ```

- [ ] **Step 4: Add `_reachedBottom` to `showEndCard` condition** (around line 334):

  ```dart
  // BEFORE:
  final showEndCard = plan != null &&
      !plan.todayDone &&
      !_dismissedEndCard &&
      _effectiveUnitForPlan >= plan.todayEndUnit;

  // AFTER:
  final showEndCard = plan != null &&
      !plan.todayDone &&
      !_dismissedEndCard &&
      _reachedBottom &&
      _effectiveUnitForPlan >= plan.todayEndUnit;
  ```

- [ ] **Step 5: Verify and commit**

  ```bash
  dart analyze lib/features/reader/reader_screen.dart
  git add lib/features/reader/reader_screen.dart
  git commit -m "fix: show reading plan end card only after scrolling to bottom"
  ```

---

## Task 7: Verse bookmark — long-press action sheet

**Files:**
- Modify: `lib/features/reader/reader_screen.dart`

### 7a. Add `_showVerseActionSheet`

Place this method near `_openReadingOptions`:

- [ ] **Step 1:**

  ```dart
  void _showVerseActionSheet(ScriptureVerse v) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.nightBg : AppColors.boneBg;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final accent = ReligionColors.accent(_meta!.religionId);

    final chapterNum = _meta!.type == ScriptureTextType.quran
        ? (int.tryParse(v.wordMeanings ?? '') ?? _currentChapter)
        : _currentChapter;

    final verseId = SavedVerse.makeId(widget.textId, chapterNum, v.number);
    final alreadySaved = ref.read(savedVersesProvider).isSaved(verseId);

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.share_outlined, color: fg),
                title: Text('Share verse',
                    style: GoogleFonts.inter(color: fg)),
                onTap: () {
                  Navigator.pop(context);
                  ShareService.instance.shareVerse(
                    context: context,
                    verse: v,
                    textId: widget.textId,
                    chapterNum: chapterNum,
                    meta: _meta!,
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  alreadySaved ? Icons.bookmark : Icons.bookmark_border,
                  color: alreadySaved ? accent : fg,
                ),
                title: Text(
                  alreadySaved ? 'Remove bookmark' : 'Bookmark verse',
                  style: GoogleFonts.inter(color: fg),
                ),
                onTap: () {
                  Navigator.pop(context);
                  final saved = SavedVerse(
                    id: verseId,
                    textId: widget.textId,
                    reference: '$chapterNum:${v.number}',
                    text: v.original ?? v.translation,
                    translation: v.original != null ? v.translation : null,
                    savedAt: DateTime.now(),
                  );
                  ref.read(savedVersesProvider.notifier).toggle(saved);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  ```

  Note: If the existing share functionality uses a different method signature on `ShareService`, find the correct call by searching for existing share invocations in the file and match the parameter names exactly.

### 7b. Wire up long press in the verse list

- [ ] **Step 2: Find the `ListView.separated` itemBuilder in `build()`**

  Search for `itemBuilder:` — each verse is built with a call like `_buildVerseCard(v)` or a switch on type. Wrap the outermost widget returned per verse with:

  ```dart
  GestureDetector(
    onLongPress: () => _showVerseActionSheet(verse),
    child: /* existing verse card widget */,
  )
  ```

  If a `GestureDetector` already exists per item (for tap-to-share), add `onLongPress` to that existing detector instead of nesting.

### 7c. Show bookmark indicator on Quran verse number

- [ ] **Step 3: In `_quranCard()`, replace the `Align` containing the verse-number circle** with a `Row` that also shows a bookmark icon when saved:

  ```dart
  Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Builder(builder: (_) {
        final chNum = int.tryParse(verse.wordMeanings ?? '') ?? _currentChapter;
        final id = SavedVerse.makeId(widget.textId, chNum, verse.number);
        final saved = ref.watch(savedVersesProvider).isSaved(id);
        return saved
            ? Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.bookmark, size: 14, color: accent),
              )
            : const SizedBox.shrink();
      }),
      Container(
        width: 22, height: 22,
        margin: const EdgeInsets.only(top: 4, bottom: 8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: accent, width: 1.5),
        ),
        child: Center(
          child: Text('${verse.number}',
            style: GoogleFonts.jetBrainsMono(fontSize: 8, color: accent)),
        ),
      ),
    ],
  ),
  ```

- [ ] **Step 4: Verify and commit**

  ```bash
  dart analyze lib/features/reader/reader_screen.dart
  git add lib/features/reader/reader_screen.dart
  git commit -m "feat: verse bookmark via long press with indicator on saved verses"
  ```

---

## Task 8: Page bookmark — header icon

**Files:**
- Modify: `lib/features/reader/reader_screen.dart`

- [ ] **Step 1: Add `_bookmarkedPages` field** (near other state fields):

  ```dart
  Set<int> _bookmarkedPages = {};
  ```

- [ ] **Step 2: Load bookmarks in `_loadPrefs()`**

  Add inside `_loadPrefs()`, after existing pref reads:

  ```dart
  final bookmarkRaw = prefs.getStringList('page_bookmarks_${widget.textId}') ?? [];
  _bookmarkedPages = bookmarkRaw.map(int.parse).toSet();
  ```

- [ ] **Step 3: Add `_togglePageBookmark()` method**

  ```dart
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
  ```

- [ ] **Step 4: Add bookmark icon to AppBar**

  Find the AppBar's trailing `Row` / `actions` list in `build()` (it contains the tune/options button). Add before the tune icon:

  ```dart
  IconButton(
    icon: Icon(
      _bookmarkedPages.contains(_currentChapter)
          ? Icons.bookmark
          : Icons.bookmark_border,
      color: _bookmarkedPages.contains(_currentChapter) ? accent : fg,
      size: 22,
    ),
    onPressed: _loading ? null : _togglePageBookmark,
    tooltip: 'Bookmark page',
  ),
  ```

- [ ] **Step 5: Verify and commit**

  ```bash
  dart analyze lib/features/reader/reader_screen.dart
  git add lib/features/reader/reader_screen.dart
  git commit -m "feat: page bookmark icon in reader header"
  ```

---

## Self-Review

**Spec coverage:**
1. ✅ Quran reader navigates by 8-ayaat pages (1–780) — Tasks 1–4
2. ✅ End card only shows after scrolling to bottom — Task 6
3. ✅ Verse bookmark via long press → Share/Bookmark sheet — Task 7
4. ✅ Page bookmark via header icon — Task 8
5. ✅ Library "Continue Plan" passes page number directly — Task 5

**Placeholder scan:** None found.

**Type consistency:**
- `buildPageVerses(int page, List<ScriptureChapter> allSurahs)` → called as `QuranPageMapper.buildPageVerses(page, _quranChapters!)` ✓
- `loadQuranPage(int page)` → called in `_loadPagedVerses` switch ✓
- `SavedVerse.makeId(textId, chapterNum, verseNum)` — matches existing `makeId(String, int, int)` ✓
- `_reachedBottom` defined at class level, reset in `_goTo`, checked in `showEndCard` ✓
- `_bookmarkedPages` defined at class level, persisted via SharedPreferences key `page_bookmarks_{textId}` ✓
