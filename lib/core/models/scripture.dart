enum ScriptureTextType { quran, bible, gita, ggs, dasam, bgv, hadith, ramayana }

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

  bool get hasTransliteration => type == ScriptureTextType.quran ||
      type == ScriptureTextType.ggs ||
      type == ScriptureTextType.dasam ||
      type == ScriptureTextType.bgv ||
      type == ScriptureTextType.gita ||
      type == ScriptureTextType.ramayana;

  static ScriptureTextMeta? forTextId(String textId) => switch (textId) {
    'quran' => const ScriptureTextMeta(
        id: 'quran', title: 'The Qurʼan', religionId: 'islam',
        type: ScriptureTextType.quran, chapterLabel: 'Surah',
        verseLabel: 'Ayah', totalChapters: 114),
    'guru_granth_sahib' => const ScriptureTextMeta(
        id: 'guru_granth_sahib', title: 'Sri Guru Granth Sahib Ji', religionId: 'sikhism',
        type: ScriptureTextType.ggs, chapterLabel: 'Ang',
        verseLabel: 'Line', totalChapters: 1430),
    'dasam_granth' => const ScriptureTextMeta(
        id: 'dasam_granth', title: 'Dasam Bani', religionId: 'sikhism',
        type: ScriptureTextType.dasam, chapterLabel: 'Page',
        verseLabel: 'Line', totalChapters: 1428),
    'bhai_gurdas_vaaran' => const ScriptureTextMeta(
        id: 'bhai_gurdas_vaaran', title: 'Bhai Gurdas Ji Vaaran', religionId: 'sikhism',
        type: ScriptureTextType.bgv, chapterLabel: 'Vaar',
        verseLabel: 'Pauri', totalChapters: 40),
    'bhagavad_gita' => const ScriptureTextMeta(
        id: 'bhagavad_gita', title: 'Bhagavad Gita', religionId: 'hinduism',
        type: ScriptureTextType.gita, chapterLabel: 'Chapter',
        verseLabel: 'Verse', totalChapters: 18),
    'bible_nrsv' => const ScriptureTextMeta(
        id: 'bible_nrsv', title: 'The Bible (KJV)', religionId: 'christianity',
        type: ScriptureTextType.bible, chapterLabel: 'Book',
        verseLabel: 'Verse', totalChapters: 66),
    'valmiki_ramayana' => const ScriptureTextMeta(
        id: 'valmiki_ramayana', title: 'Valmiki Ramayana', religionId: 'hinduism',
        type: ScriptureTextType.ramayana, chapterLabel: 'Sarga',
        verseLabel: 'Verse', totalChapters: 648),
    'bukhari' => const ScriptureTextMeta(
        id: 'bukhari', title: 'Sahih al-Bukhari', religionId: 'islam',
        type: ScriptureTextType.hadith, chapterLabel: 'Chapter',
        verseLabel: 'Hadith', totalChapters: 97),
    'muslim' => const ScriptureTextMeta(
        id: 'muslim', title: 'Sahih Muslim', religionId: 'islam',
        type: ScriptureTextType.hadith, chapterLabel: 'Chapter',
        verseLabel: 'Hadith', totalChapters: 57),
    'abu_dawud' => const ScriptureTextMeta(
        id: 'abu_dawud', title: 'Sunan Abu Dawud', religionId: 'islam',
        type: ScriptureTextType.hadith, chapterLabel: 'Chapter',
        verseLabel: 'Hadith', totalChapters: 43),
    'tirmidhi' => const ScriptureTextMeta(
        id: 'tirmidhi', title: "Jami' at-Tirmidhi", religionId: 'islam',
        type: ScriptureTextType.hadith, chapterLabel: 'Chapter',
        verseLabel: 'Hadith', totalChapters: 49),
    'nasai' => const ScriptureTextMeta(
        id: 'nasai', title: 'Sunan an-Nasai', religionId: 'islam',
        type: ScriptureTextType.hadith, chapterLabel: 'Chapter',
        verseLabel: 'Hadith', totalChapters: 52),
    'ibn_majah' => const ScriptureTextMeta(
        id: 'ibn_majah', title: 'Sunan Ibn Majah', religionId: 'islam',
        type: ScriptureTextType.hadith, chapterLabel: 'Chapter',
        verseLabel: 'Hadith', totalChapters: 38),
    _ => null,
  };
}
