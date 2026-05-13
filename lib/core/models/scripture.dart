enum ScriptureTextType { quran, bible, gita, ggs }

class ScriptureVerse {
  final int number;
  final String? original;
  final String translation;
  final String? transliteration;
  final String? wordMeanings;
  final bool isGroupStart;
  final String? groupLabel;

  const ScriptureVerse({
    required this.number,
    this.original,
    required this.translation,
    this.transliteration,
    this.wordMeanings,
    this.isGroupStart = false,
    this.groupLabel,
  });
}

class ScriptureChapter {
  final int number;
  final String name;
  final String? nameOriginal;
  final String? meta;
  final List<ScriptureVerse> verses;

  const ScriptureChapter({
    required this.number,
    required this.name,
    this.nameOriginal,
    this.meta,
    required this.verses,
  });

  int get verseCount => verses.length;
}

class ScriptureTextMeta {
  final String id;
  final String title;
  final String religionId;
  final ScriptureTextType type;
  final String chapterLabel;
  final String verseLabel;
  final int totalChapters;

  const ScriptureTextMeta({
    required this.id,
    required this.title,
    required this.religionId,
    required this.type,
    required this.chapterLabel,
    required this.verseLabel,
    required this.totalChapters,
  });

  static ScriptureTextMeta? forTextId(String textId) => switch (textId) {
    'quran' => const ScriptureTextMeta(
        id: 'quran', title: 'The Qurʼan', religionId: 'islam',
        type: ScriptureTextType.quran, chapterLabel: 'Surah',
        verseLabel: 'Ayah', totalChapters: 114),
    'guru_granth_sahib' => const ScriptureTextMeta(
        id: 'guru_granth_sahib', title: 'Guru Granth Sahib', religionId: 'sikhism',
        type: ScriptureTextType.ggs, chapterLabel: 'Ang',
        verseLabel: 'Line', totalChapters: 1430),
    'bhagavad_gita' => const ScriptureTextMeta(
        id: 'bhagavad_gita', title: 'Bhagavad Gita', religionId: 'hinduism',
        type: ScriptureTextType.gita, chapterLabel: 'Chapter',
        verseLabel: 'Verse', totalChapters: 18),
    'bible_nrsv' => const ScriptureTextMeta(
        id: 'bible_nrsv', title: 'The Bible (KJV)', religionId: 'christianity',
        type: ScriptureTextType.bible, chapterLabel: 'Book',
        verseLabel: 'Verse', totalChapters: 66),
    _ => null,
  };
}
