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
    'malik'              => _chunks('malik', 'malik', 7),
    'nawawi_40'          => _chunks('nawawi', 'nawawi', 1),
    'qudsi_40'           => _chunks('qudsi', 'qudsi', 1),
    'japji_sahib'               => const ['banis/japji-sahib.json'],
    'jaap_sahib'                => const ['banis/jaap-sahib.json'],
    'tav_prasad_savaiye'        => const ['banis/tav-prasad-savaiye.json'],
    'anand_sahib'               => const ['banis/anand-sahib.json'],
    'rehraas_sahib'             => const ['banis/rehraas-sahib.json'],
    'chaupai_sahib'             => const ['banis/chaupai-sahib.json'],
    'kirtan_sohila'             => const ['banis/kirtan-sohila.json'],
    'sukhmani_sahib'            => const ['banis/sukhmani-sahib.json'],
    'aarti'                     => const ['banis/aarti.json'],
    'asa_di_var'                => const ['banis/asa-di-var.json'],
    'dukh_bhanjani'             => const ['banis/dukh-bhanjani.json'],
    'sidh_gosht'                => const ['banis/sidh-gosht.json'],
    'shabad_hazare'             => const ['banis/shabad-hazare.json'],
    'salok_mahala_9'            => const ['banis/salok-mahala-9.json'],
    'baavan_akhree'             => const ['banis/baavan-akhree.json'],
    'barah_maha_manjh'          => const ['banis/barah-maha-manjh.json'],
    'akaal_ustat'               => const ['banis/akaal-ustat.json'],
    'shabad_hazare_patshahi_10' => const ['banis/shabad-hazare-patshahi-10.json'],
    'ardas'                     => const ['banis/ardas.json'],
    'laavan'                    => const ['banis/laavan.json'],
    _                           => const [],
  };

  static List<String> _chunks(String dir, String prefix, int count) =>
      List.generate(count, (i) => '$dir/${prefix}_${i.toString().padLeft(3, '0')}.json');

  static const List<String> allTextIds = [
    'quran', 'bible_nrsv', 'bhagavad_gita',
    'guru_granth_sahib', 'dasam_granth', 'bhai_gurdas_vaaran',
    'valmiki_ramayana', 'bukhari', 'muslim', 'abu_dawud',
    'tirmidhi', 'nasai', 'ibn_majah',
    'malik', 'nawawi_40', 'qudsi_40',
    'japji_sahib', 'jaap_sahib', 'tav_prasad_savaiye',
    'anand_sahib', 'rehraas_sahib', 'chaupai_sahib',
    'kirtan_sohila', 'sukhmani_sahib',
    'aarti', 'asa_di_var', 'dukh_bhanjani', 'sidh_gosht',
    'shabad_hazare', 'salok_mahala_9', 'baavan_akhree', 'barah_maha_manjh',
    'akaal_ustat', 'shabad_hazare_patshahi_10',
    'ardas', 'laavan',
  ];
}
