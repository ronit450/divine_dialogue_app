import 'dart:convert';
import 'package:flutter/services.dart';
import '../core/models/scripture.dart';

class ScriptureRepository {
  ScriptureRepository._();
  static final ScriptureRepository instance = ScriptureRepository._();

  final Map<String, List<ScriptureChapter>> _cache = {};
  final Map<String, Map<int, List<ScriptureVerse>>> _pageCache = {};
  final Map<String, Set<int>> _loadedChunks = {};

  Future<List<ScriptureChapter>> loadChapters(String textId) async {
    if (_cache.containsKey(textId)) return _cache[textId]!;
    final chapters = switch (textId) {
      'quran' => await _loadQuran(),
      'bhagavad_gita' => await _loadGita(),
      'bible_nrsv' => await _loadBible(),
      _ => <ScriptureChapter>[],
    };
    _cache[textId] = chapters;
    return chapters;
  }

  Future<List<ScriptureVerse>> loadGgsAng(int ang) async =>
      _loadPagedText('guru_granth_sahib', ang, 'ggs', 'ggs', 1430, 100);

  Future<List<ScriptureVerse>> loadDasamPage(int page) async =>
      _loadPagedText('dasam_granth', page, 'dasam', 'dasam', 1428, 100);

  Future<List<ScriptureVerse>> loadBgvVaar(int vaar) async =>
      _loadPagedText('bhai_gurdas_vaaran', vaar, 'bgv', 'bgv', 40, 10);

  Future<List<ScriptureVerse>> _loadPagedText(
    String textId, int page, String dir, String prefix, int maxPage, int pagesPerChunk,
  ) async {
    _pageCache.putIfAbsent(textId, () => {});
    _loadedChunks.putIfAbsent(textId, () => {});

    final cache = _pageCache[textId]!;
    final loaded = _loadedChunks[textId]!;

    if (cache.containsKey(page)) return cache[page]!;

    final chunkIdx = ((page - 1) ~/ pagesPerChunk).clamp(0, (maxPage ~/ pagesPerChunk) + 1);
    if (!loaded.contains(chunkIdx)) {
      await _loadChunk(dir, prefix, chunkIdx, cache);
      loaded.add(chunkIdx);
    }
    return cache[page] ?? [];
  }

  Future<void> _loadChunk(
    String dir, String prefix, int idx,
    Map<int, List<ScriptureVerse>> cache,
  ) async {
    final label = idx.toString().padLeft(3, '0');
    final raw = await rootBundle.loadString('assets/data/scripture/$dir/${prefix}_$label.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    data.forEach((pageStr, lines) {
      final page = int.parse(pageStr);
      final lineList = lines as List<dynamic>;
      int lastShabadId = -1;
      final verses = <ScriptureVerse>[];
      for (int i = 0; i < lineList.length; i++) {
        final l = lineList[i] as Map<String, dynamic>;
        final shabadId = l['s'] as int? ?? 0;
        final isGroupStart = shabadId != lastShabadId;
        verses.add(ScriptureVerse(
          number: i + 1,
          original: l['g'] as String?,
          translation: l['e'] as String? ?? '',
          transliteration: l['t'] as String?,
          isGroupStart: isGroupStart,
          groupLabel: isGroupStart ? (l['a'] as String?) : null,
        ));
        lastShabadId = shabadId;
      }
      cache[page] = verses;
    });
  }

  Future<List<ScriptureChapter>> _loadQuran() async {
    final raw = await rootBundle.loadString('assets/data/scripture/quran.json');
    final surahs = jsonDecode(raw) as List<dynamic>;
    return surahs.map((s) {
      final sm = s as Map<String, dynamic>;
      final ayat = sm['ayat'] as int? ?? 0;
      final place = sm['place'] as String? ?? '';
      final verses = (sm['verses'] as List<dynamic>).map((v) {
        final vm = v as Map<String, dynamic>;
        return ScriptureVerse(
          number: vm['n'] as int,
          original: vm['ar'] as String?,
          translation: vm['en'] as String? ?? '',
        );
      }).toList();
      return ScriptureChapter(
        number: sm['n'] as int,
        name: sm['name'] as String,
        nameOriginal: sm['nameAr'] as String?,
        meta: '$ayat ayat · $place',
        verses: verses,
      );
    }).toList();
  }

  Future<List<ScriptureChapter>> _loadGita() async {
    final raw = await rootBundle.loadString('assets/data/scripture/gita.json');
    final chapters = jsonDecode(raw) as List<dynamic>;
    return chapters.map((c) {
      final cm = c as Map<String, dynamic>;
      final verses = (cm['verses'] as List<dynamic>).map((v) {
        final vm = v as Map<String, dynamic>;
        return ScriptureVerse(
          number: vm['n'] as int,
          original: vm['sa'] as String?,
          translation: vm['en'] as String? ?? '',
          transliteration: vm['tr'] as String?,
          wordMeanings: vm['wm'] as String?,
        );
      }).toList();
      return ScriptureChapter(
        number: cm['n'] as int,
        name: cm['name'] as String,
        meta: cm['meaning'] as String?,
        verses: verses,
      );
    }).toList();
  }

  Future<List<ScriptureChapter>> _loadBible() async {
    final raw = await rootBundle.loadString('assets/data/scripture/bible.json');
    final books = jsonDecode(raw) as List<dynamic>;
    final chapters = <ScriptureChapter>[];
    int chapterIndex = 1;
    for (final book in books) {
      final bm = book as Map<String, dynamic>;
      final bookName = bm['name'] as String;
      for (final ch in bm['chapters'] as List<dynamic>) {
        final cm = ch as Map<String, dynamic>;
        final verses = (cm['verses'] as List<dynamic>).map((v) {
          final vm = v as Map<String, dynamic>;
          return ScriptureVerse(
            number: vm['n'] as int,
            translation: vm['en'] as String? ?? '',
          );
        }).toList();
        chapters.add(ScriptureChapter(
          number: chapterIndex++,
          name: '$bookName ${cm['n']}',
          meta: bookName,
          verses: verses,
        ));
      }
    }
    return chapters;
  }
}
