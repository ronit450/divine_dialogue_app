enum ScriptureTextType { quran, bible, gita, ggs, dasam, bgv, hadith, ramayana, bani }

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
      type == ScriptureTextType.ramayana ||
      type == ScriptureTextType.bani;

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
    'malik' => const ScriptureTextMeta(
        id: 'malik', title: 'Muwatta Imam Malik', religionId: 'islam',
        type: ScriptureTextType.hadith, chapterLabel: 'Chapter',
        verseLabel: 'Hadith', totalChapters: 61),
    'nawawi_40' => const ScriptureTextMeta(
        id: 'nawawi_40', title: '40 Hadith Nawawi', religionId: 'islam',
        type: ScriptureTextType.hadith, chapterLabel: 'Chapter',
        verseLabel: 'Hadith', totalChapters: 1),
    'qudsi_40' => const ScriptureTextMeta(
        id: 'qudsi_40', title: '40 Hadith Qudsi', religionId: 'islam',
        type: ScriptureTextType.hadith, chapterLabel: 'Chapter',
        verseLabel: 'Hadith', totalChapters: 1),
    // Nitnem
    'japji_sahib' => const ScriptureTextMeta(
        id: 'japji_sahib', title: 'Japji Sahib', religionId: 'sikhism',
        type: ScriptureTextType.bani, chapterLabel: 'Bani',
        verseLabel: 'Line', totalChapters: 1),
    'jaap_sahib' => const ScriptureTextMeta(
        id: 'jaap_sahib', title: 'Jaap Sahib', religionId: 'sikhism',
        type: ScriptureTextType.bani, chapterLabel: 'Bani',
        verseLabel: 'Line', totalChapters: 1),
    'tav_prasad_savaiye' => const ScriptureTextMeta(
        id: 'tav_prasad_savaiye', title: 'Tav Prasad Savaiye', religionId: 'sikhism',
        type: ScriptureTextType.bani, chapterLabel: 'Bani',
        verseLabel: 'Line', totalChapters: 1),
    'anand_sahib' => const ScriptureTextMeta(
        id: 'anand_sahib', title: 'Anand Sahib', religionId: 'sikhism',
        type: ScriptureTextType.bani, chapterLabel: 'Bani',
        verseLabel: 'Line', totalChapters: 1),
    'rehraas_sahib' => const ScriptureTextMeta(
        id: 'rehraas_sahib', title: 'Rehraas Sahib', religionId: 'sikhism',
        type: ScriptureTextType.bani, chapterLabel: 'Bani',
        verseLabel: 'Line', totalChapters: 1),
    'chaupai_sahib' => const ScriptureTextMeta(
        id: 'chaupai_sahib', title: 'Benatee Chaupai Sahib', religionId: 'sikhism',
        type: ScriptureTextType.bani, chapterLabel: 'Bani',
        verseLabel: 'Line', totalChapters: 1),
    'kirtan_sohila' => const ScriptureTextMeta(
        id: 'kirtan_sohila', title: 'Kirtan Sohila', religionId: 'sikhism',
        type: ScriptureTextType.bani, chapterLabel: 'Bani',
        verseLabel: 'Line', totalChapters: 1),
    'sukhmani_sahib' => const ScriptureTextMeta(
        id: 'sukhmani_sahib', title: 'Sukhmani Sahib', religionId: 'sikhism',
        type: ScriptureTextType.bani, chapterLabel: 'Bani',
        verseLabel: 'Line', totalChapters: 1),
    // Gurbani
    'aarti' => const ScriptureTextMeta(
        id: 'aarti', title: 'Aarti (Gagan Mein Thaal)', religionId: 'sikhism',
        type: ScriptureTextType.bani, chapterLabel: 'Bani',
        verseLabel: 'Line', totalChapters: 1),
    'asa_di_var' => const ScriptureTextMeta(
        id: 'asa_di_var', title: 'Asa Di Var', religionId: 'sikhism',
        type: ScriptureTextType.bani, chapterLabel: 'Bani',
        verseLabel: 'Line', totalChapters: 1),
    'dukh_bhanjani' => const ScriptureTextMeta(
        id: 'dukh_bhanjani', title: 'Dukh Bhanjani Sahib', religionId: 'sikhism',
        type: ScriptureTextType.bani, chapterLabel: 'Bani',
        verseLabel: 'Line', totalChapters: 1),
    'sidh_gosht' => const ScriptureTextMeta(
        id: 'sidh_gosht', title: 'Sidh Gosht', religionId: 'sikhism',
        type: ScriptureTextType.bani, chapterLabel: 'Bani',
        verseLabel: 'Line', totalChapters: 1),
    'shabad_hazare' => const ScriptureTextMeta(
        id: 'shabad_hazare', title: 'Shabad Hazare', religionId: 'sikhism',
        type: ScriptureTextType.bani, chapterLabel: 'Bani',
        verseLabel: 'Line', totalChapters: 1),
    'salok_mahala_9' => const ScriptureTextMeta(
        id: 'salok_mahala_9', title: 'Salok Mahala 9', religionId: 'sikhism',
        type: ScriptureTextType.bani, chapterLabel: 'Bani',
        verseLabel: 'Line', totalChapters: 1),
    'baavan_akhree' => const ScriptureTextMeta(
        id: 'baavan_akhree', title: 'Baavan Akhree', religionId: 'sikhism',
        type: ScriptureTextType.bani, chapterLabel: 'Bani',
        verseLabel: 'Line', totalChapters: 1),
    'barah_maha_manjh' => const ScriptureTextMeta(
        id: 'barah_maha_manjh', title: 'Barah Maha Manjh', religionId: 'sikhism',
        type: ScriptureTextType.bani, chapterLabel: 'Bani',
        verseLabel: 'Line', totalChapters: 1),
    // Dasam Granth banis
    'akaal_ustat' => const ScriptureTextMeta(
        id: 'akaal_ustat', title: 'Akaal Ustat', religionId: 'sikhism',
        type: ScriptureTextType.bani, chapterLabel: 'Bani',
        verseLabel: 'Line', totalChapters: 1),
    'shabad_hazare_patshahi_10' => const ScriptureTextMeta(
        id: 'shabad_hazare_patshahi_10', title: 'Shabad Hazare Patshahi 10', religionId: 'sikhism',
        type: ScriptureTextType.bani, chapterLabel: 'Bani',
        verseLabel: 'Line', totalChapters: 1),
    // Ardas
    'ardas' => const ScriptureTextMeta(
        id: 'ardas', title: 'Ardas', religionId: 'sikhism',
        type: ScriptureTextType.bani, chapterLabel: 'Bani',
        verseLabel: 'Line', totalChapters: 1),
    // Anand Karaj
    'laavan' => const ScriptureTextMeta(
        id: 'laavan', title: 'Laavan (Anand Karaj)', religionId: 'sikhism',
        type: ScriptureTextType.bani, chapterLabel: 'Bani',
        verseLabel: 'Line', totalChapters: 1),
    _ => null,
  };
}
