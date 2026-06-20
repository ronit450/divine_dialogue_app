import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../core/models/scripture.dart';
import '../core/models/quran_page_mapper.dart';

class ScriptureRepository {
  ScriptureRepository._();
  static final ScriptureRepository instance = ScriptureRepository._();

  final Map<String, List<ScriptureChapter>> _cache = {};
  final Map<String, Map<int, List<ScriptureVerse>>> _pageCache = {};
  final Map<String, Set<int>> _loadedChunks = {};
  List<ScriptureChapter>? _quranChapters;

  Future<List<ScriptureChapter>> loadChapters(String textId) async {
    if (_cache.containsKey(textId)) return _cache[textId]!;
    final chapters = switch (textId) {
      'quran'        => await _loadQuran(),
      'bhagavad_gita' => await _loadGita(),
      'bible_nrsv'   => await _loadBible(),
      _ when ScriptureTextMeta.forTextId(textId)?.type == ScriptureTextType.bani =>
          await _loadBani(textId),
      _ => <ScriptureChapter>[],
    };
    _cache[textId] = chapters;
    return chapters;
  }

  Future<List<ScriptureVerse>> loadBani(String textId) async {
    _pageCache.putIfAbsent(textId, () => {});
    if (_pageCache[textId]!.containsKey(1)) return _pageCache[textId]![1]!;
    final token = textId.replaceAll('_', '-');
    final raw = await _readFile('banis/$token.json');
    final list = jsonDecode(raw) as List<dynamic>;
    final verses = <ScriptureVerse>[];
    for (int i = 0; i < list.length; i++) {
      final v = list[i] as Map<String, dynamic>;
      verses.add(ScriptureVerse(
        number: i + 1,
        original: v['g'] as String?,
        transliteration: (v['t'] as String?)?.isNotEmpty == true ? v['t'] as String : null,
        translation: v['e'] as String? ?? '',
        sectionHeader: (v['h'] as int?) ?? 0,
        paragraph: (v['p'] as int?) ?? 0,
        isGroupStart: v.containsKey('h'),
        groupLabel: v['h']?.toString(),
      ));
    }
    _pageCache[textId]![1] = verses;
    return verses;
  }

  Future<List<ScriptureChapter>> _loadBani(String textId) async {
    final verses = await loadBani(textId);
    final meta = ScriptureTextMeta.forTextId(textId)!;
    return [ScriptureChapter(number: 1, name: meta.title, verses: verses)];
  }

  Future<List<ScriptureVerse>> loadGgsAng(int ang) async =>
      _loadPagedText('guru_granth_sahib', ang, 'ggs', 'ggs', 1430, 100);

  Future<List<ScriptureVerse>> loadDasamPage(int page) async =>
      _loadPagedText('dasam_granth', page, 'dasam', 'dasam', 1428, 100);

  Future<List<ScriptureVerse>> loadBgvVaar(int vaar) async =>
      _loadPagedText('bhai_gurdas_vaaran', vaar, 'bgv', 'bgv', 40, 10);

  Future<List<ScriptureVerse>> loadQuranPage(int page) async {
    _quranChapters ??= await loadChapters('quran');
    return QuranPageMapper.buildPageVerses(page, _quranChapters!);
  }

  Future<List<ScriptureVerse>> loadQuranSurahBreakPage(int page) async {
    _quranChapters ??= await loadChapters('quran');
    return QuranPageMapper.buildSurahBreakPageVerses(page, _quranChapters!);
  }

  Future<List<ScriptureVerse>> loadRamayanaSarga(int sarga) async =>
      _loadPagedText('valmiki_ramayana', sarga, 'valmiki_ramayana', 'ramayana', 648, 50,
          chunkLoader: _loadRamayanaChunk);

  Future<List<ScriptureVerse>> loadHadithChapter(String textId, int chapter) async {
    final dir = switch (textId) {
      'nawawi_40' => 'nawawi',
      'qudsi_40'  => 'qudsi',
      _           => textId,
    };
    return _loadPagedText(textId, chapter, dir, dir, _hadithChapterCount(textId), 10,
        chunkLoader: _loadHadithChunk);
  }

  int _hadithChapterCount(String textId) => switch (textId) {
    'bukhari'   => 97,
    'muslim'    => 57,
    'abu_dawud' => 43,
    'tirmidhi'  => 49,
    'nasai'     => 52,
    'ibn_majah' => 38,
    _ => 1,
  };

  Future<List<ScriptureVerse>> _loadPagedText(
    String textId, int page, String dir, String prefix, int maxPage, int pagesPerChunk, {
    Future<void> Function(String, String, int, Map<int, List<ScriptureVerse>>)? chunkLoader,
  }) async {
    _pageCache.putIfAbsent(textId, () => {});
    _loadedChunks.putIfAbsent(textId, () => {});

    final cache = _pageCache[textId]!;
    final loaded = _loadedChunks[textId]!;

    if (cache.containsKey(page)) return cache[page]!;

    final chunkIdx = ((page - 1) ~/ pagesPerChunk).clamp(0, (maxPage ~/ pagesPerChunk) + 1);
    if (!loaded.contains(chunkIdx)) {
      await (chunkLoader ?? _loadChunk)(dir, prefix, chunkIdx, cache);
      loaded.add(chunkIdx);
    }
    return cache[page] ?? [];
  }

  Future<String> _readFile(String relativePath) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/scripture/$relativePath').readAsString();
  }

  Future<void> _loadChunk(
    String dir, String prefix, int idx,
    Map<int, List<ScriptureVerse>> cache,
  ) async {
    final label = idx.toString().padLeft(3, '0');
    final raw = await _readFile('$dir/${prefix}_$label.json');
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

  Future<void> _loadRamayanaChunk(
    String dir, String prefix, int idx,
    Map<int, List<ScriptureVerse>> cache,
  ) async {
    final label = idx.toString().padLeft(3, '0');
    final raw = await _readFile('$dir/${prefix}_$label.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    data.forEach((sargaStr, verses) {
      final sarga = int.parse(sargaStr);
      final verseList = verses as List<dynamic>;
      final result = <ScriptureVerse>[];
      for (int i = 0; i < verseList.length; i++) {
        final v = verseList[i] as Map<String, dynamic>;
        final kanda = v['kanda'] as String?;
        final sargaNum = v['sarga'] as int?;
        result.add(ScriptureVerse(
          number: (v['n'] as num).toInt(),
          original: (v['sa'] as String?)?.isNotEmpty == true ? v['sa'] as String : null,
          translation: v['e'] as String? ?? '',
          transliteration: (v['t'] as String?)?.isNotEmpty == true ? v['t'] as String : null,
          isGroupStart: i == 0,
          groupLabel: i == 0 && kanda != null ? '$kanda · Sarga $sargaNum' : null,
        ));
      }
      cache[sarga] = result;
    });
  }

  Future<void> _loadHadithChunk(
    String dir, String prefix, int idx,
    Map<int, List<ScriptureVerse>> cache,
  ) async {
    final label = idx.toString().padLeft(3, '0');
    final raw = await _readFile('$dir/${prefix}_$label.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    data.forEach((chStr, hadiths) {
      final ch = int.parse(chStr);
      final hadithList = hadiths as List<dynamic>;
      final verses = <ScriptureVerse>[];
      for (int i = 0; i < hadithList.length; i++) {
        final h = hadithList[i] as Map<String, dynamic>;
        verses.add(ScriptureVerse(
          number: int.tryParse(h['n'] as String? ?? '') ?? (i + 1),
          original: (h['a'] as String?)?.isNotEmpty == true ? h['a'] as String : null,
          translation: h['e'] as String? ?? '',
          wordMeanings: '${h['nr'] ?? ''}\n${h['gr'] ?? ''}',
          isGroupStart: i == 0,
          groupLabel: i == 0 ? h['ch'] as String? : null,
        ));
      }
      cache[ch] = verses;
    });
  }

  Future<List<ScriptureChapter>> _loadQuran() async {
    final raw = await _readFile('quran.json');
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
          transliteration: vm['tr'] as String?,
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
    final raw = await _readFile('gita.json');
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
    final raw = await _readFile('bible.json');
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
