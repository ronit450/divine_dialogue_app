class ScriptureStorageMap {
  ScriptureStorageMap._();

  static List<String> filesForText(String textId) => switch (textId) {
    'quran'              => const ['quran.json'],
    'bible_nrsv'         => const ['bible.json'],
    'bhagavad_gita'      => const ['gita.json'],
    'guru_granth_sahib'  => _chunks('ggs', 'ggs', 15),
    'dasam_granth'       => _chunks('dasam', 'dasam', 15),
    'bhai_gurdas_vaaran' => _chunks('bgv', 'bgv', 4),
    'valmiki_ramayana'   => _chunks('valmiki_ramayana', 'ramayana', 13),
    'bukhari'            => _chunks('bukhari', 'bukhari', 10),
    'muslim'             => _chunks('muslim', 'muslim', 6),
    'abu_dawud'          => _chunks('abu_dawud', 'abu_dawud', 5),
    'tirmidhi'           => _chunks('tirmidhi', 'tirmidhi', 5),
    'nasai'              => _chunks('nasai', 'nasai', 6),
    'ibn_majah'          => _chunks('ibn_majah', 'ibn_majah', 4),
    _                    => const [],
  };

  static List<String> _chunks(String dir, String prefix, int count) =>
      List.generate(count, (i) => '$dir/${prefix}_${i.toString().padLeft(3, '0')}.json');

  static const List<String> allTextIds = [
    'quran', 'bible_nrsv', 'bhagavad_gita',
    'guru_granth_sahib', 'dasam_granth', 'bhai_gurdas_vaaran',
    'valmiki_ramayana', 'bukhari', 'muslim', 'abu_dawud',
    'tirmidhi', 'nasai', 'ibn_majah',
  ];
}
