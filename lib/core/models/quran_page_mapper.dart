import 'scripture.dart';

class QuranPageMapper {
  QuranPageMapper._();

  static const int versesPerPage = 8;
  static const int totalPages = 780; // ceil(6236 / 8)

  static const List<int> _verseCounts = [
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109,
    123, 111, 43, 52, 99, 128, 111, 110, 98, 135,
    112, 78, 118, 64, 77, 227, 93, 88, 69, 60,
    34, 30, 73, 54, 45, 83, 182, 88, 75, 85,
    54, 53, 89, 59, 37, 35, 38, 29, 18, 45,
    60, 49, 62, 55, 78, 96, 29, 22, 24, 13,
    14, 11, 11, 18, 12, 12, 30, 52, 52, 44,
    28, 28, 20, 56, 40, 31, 50, 40, 46, 42,
    29, 19, 36, 25, 22, 17, 19, 26, 30, 20,
    15, 21, 11, 8, 8, 19, 5, 8, 8, 11,
    11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6,
  ];

  // _cumulative[i] = total verses before surah (i+1). Length = 115.
  static final List<int> _cumulative = _buildCumulative();

  static List<int> _buildCumulative() {
    final c = <int>[0];
    for (final v in _verseCounts) {
      c.add(c.last + v);
    }
    return List.unmodifiable(c);
  }

  /// Returns the 1-based surah number that contains the first verse of [page].
  /// [page] is 1-based (1–780).
  static int pageToSurah(int page) {
    final globalVerse = ((page - 1) * versesPerPage) + 1;
    int lo = 0, hi = _verseCounts.length - 1;
    while (lo < hi) {
      final mid = (lo + hi) ~/ 2;
      if (_cumulative[mid + 1] < globalVerse) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo + 1;
  }

  /// Returns the 1-based page number on which [surah] (1-based) begins.
  static int surahToPage(int surah) {
    final globalVerseStart = _cumulative[surah - 1] + 1;
    return (globalVerseStart - 1) ~/ versesPerPage + 1;
  }

  /// Returns the 1-based page number on which [surah] (1-based) ends.
  static int surahLastPage(int surah) {
    final lastGlobalVerse = _cumulative[surah]; // total verses through this surah
    return (lastGlobalVerse - 1) ~/ versesPerPage + 1;
  }

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

  /// Slices [allSurahs] into up to [versesPerPage] verses for [page] (1-based).
  /// Sets [ScriptureVerse.isGroupStart] and [ScriptureVerse.groupLabel] at surah
  /// boundaries, and stores the surah number as a string in [ScriptureVerse.wordMeanings].
  static List<ScriptureVerse> buildPageVerses(
      int page, List<ScriptureChapter> allSurahs) {
    final globalStart = (page - 1) * versesPerPage;
    final globalEnd = (page * versesPerPage - 1).clamp(0, _cumulative.last - 1);
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
}
