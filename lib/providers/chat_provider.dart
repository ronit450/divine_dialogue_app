import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/models/chat_message.dart';
import '../data/chat_repository.dart';

class ChatState {
  const ChatState({this.session, this.isTyping = false});
  final ChatSession? session;
  final bool isTyping;

  ChatState copyWith({ChatSession? session, bool? isTyping}) => ChatState(
    session: session ?? this.session,
    isTyping: isTyping ?? this.isTyping,
  );
}

final chatProvider =
    StateNotifierProvider.autoDispose<ChatNotifier, ChatState>(
  (_) => ChatNotifier(),
);

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(const ChatState());

  static const _uuid = Uuid();

  void loadSession(ChatSession session) {
    state = state.copyWith(session: session);
  }

  Future<void> startNewSession({
    required String religionId,
    required String textId,
    required String textTitle,
  }) async {
    final session = ChatSession(
      id: _uuid.v4(),
      title: 'Chat about $textTitle',
      religionId: religionId,
      textId: textId,
      messages: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(session: session);
    await ChatRepository.instance.saveSession(session);
  }

  Future<void> sendMessage(String text) async {
    final current = state.session;
    if (current == null) return;

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final withUser = current.copyWith(
      messages: [...current.messages, userMsg],
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(session: withUser);
    await ChatRepository.instance.saveSession(withUser);

    state = state.copyWith(isTyping: true);
    await Future.delayed(const Duration(milliseconds: 1200));

    final mock = _mockResponse(text, current.religionId, current.textId);
    final aiMsg = ChatMessage(
      id: _uuid.v4(),
      text: mock.text,
      isUser: false,
      timestamp: DateTime.now(),
      citations: mock.citations,
    );

    final withAi = withUser.copyWith(
      messages: [...withUser.messages, aiMsg],
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(session: withAi, isTyping: false);
    await ChatRepository.instance.saveSession(withAi);
  }

  _MockResponse _mockResponse(String q, String religionId, String textId) {
    final lower = q.toLowerCase();
    switch (religionId) {
      case 'islam':
        if (lower.contains('pray') || lower.contains('salah')) {
          return const _MockResponse(
            text:
                'Prayer (Salah) is the second pillar of Islam, performed five times daily. '
                'It establishes a direct connection between the worshipper and Allah, '
                'purifying the soul and keeping one mindful of God throughout the day.',
            citations: [
              Citation(
                reference: 'Quran 2:238',
                originalText:
                    'حَافِظُوا عَلَى الصَّلَوَاتِ وَالصَّلَاةِ الْوُسْطَىٰ وَقُومُوا لِلَّهِ قَانِتِينَ',
                translation:
                    'Maintain with care the [obligatory] prayers and [in particular] the middle prayer and stand before Allah, devoutly obedient.',
                isRtl: true,
              ),
              Citation(
                reference: 'Sahih Bukhari 1:2:7',
                originalText: '',
                translation:
                    'Islam is built on five: testifying that there is no god except Allah and that Muhammad is the Messenger of Allah, establishing prayer, giving Zakat, making pilgrimage to the House, and fasting Ramadan.',
              ),
            ],
          );
        }
        if (lower.contains('zakat') || lower.contains('charity')) {
          return const _MockResponse(
            text:
                'Zakat is the third pillar of Islam — an obligatory almsgiving of 2.5% '
                'of one\'s savings to those in need. It purifies wealth and fosters '
                'social solidarity within the Muslim community.',
            citations: [
              Citation(
                reference: 'Quran 9:60',
                originalText:
                    'إِنَّمَا الصَّدَقَاتُ لِلْفُقَرَاءِ وَالْمَسَاكِينِ وَالْعَامِلِينَ عَلَيْهَا',
                translation:
                    'Zakah expenditures are only for the poor, the needy, and those employed to collect it.',
                isRtl: true,
              ),
              Citation(
                reference: 'Quran 2:177',
                originalText:
                    'وَآتَى الْمَالَ عَلَىٰ حُبِّهِ ذَوِي الْقُرْبَىٰ وَالْيَتَامَىٰ وَالْمَسَاكِينَ',
                translation:
                    'And gives wealth, in spite of love for it, to relatives, orphans, the needy, the traveler, those who ask for help, and for freeing slaves.',
                isRtl: true,
              ),
            ],
          );
        }
        return const _MockResponse(
          text:
              'In Islam, knowledge is considered a sacred duty. The Prophet Muhammad ﷺ '
              'said: "Seeking knowledge is an obligation upon every Muslim." '
              'The Quran repeatedly calls upon believers to reflect, reason, and understand.',
          citations: [
            Citation(
              reference: 'Quran 96:1–5',
              originalText:
                  'اقْرَأْ بِاسْمِ رَبِّكَ الَّذِي خَلَقَ ۝ خَلَقَ الْإِنسَانَ مِنْ عَلَقٍ ۝ اقْرَأْ وَرَبُّكَ الْأَكْرَمُ',
              translation:
                  'Read in the name of your Lord who created — created man from a clinging substance. Read, and your Lord is the most Generous.',
              isRtl: true,
            ),
            Citation(
              reference: 'Ibn Majah 224',
              originalText: '',
              translation: 'Seeking knowledge is an obligation upon every Muslim.',
            ),
          ],
        );

      case 'hinduism':
        if (lower.contains('karma')) {
          return const _MockResponse(
            text:
                'Karma is the law of cause and effect in Hindu philosophy. Every action '
                '(karma) generates a force that returns to the actor. The Bhagavad Gita '
                'teaches nishkama karma — acting without attachment to outcomes.',
            citations: [
              Citation(
                reference: 'Bhagavad Gita 3:19',
                originalText:
                    'tasmād asaktaḥ satataṁ kāryaṁ karma samācara\nasakto hy ācaran karma param āpnoti pūruṣaḥ',
                translation:
                    'Therefore, without attachment, always perform the action that should be done; for by performing action without attachment, one attains the Supreme.',
              ),
              Citation(
                reference: 'Bhagavad Gita 2:47',
                originalText:
                    'karmaṇy evādhikāras te mā phaleṣu kadācana\nmā karma-phala-hetur bhūr mā te saṅgo \'stvakarmaṇi',
                translation:
                    'You have a right to perform your prescribed duties, but you are not entitled to the fruits of your actions. Never consider yourself the cause of the results, nor be attached to inaction.',
              ),
            ],
          );
        }
        return const _MockResponse(
          text:
              'Dharma is one of the central concepts in Hinduism — the cosmic order, '
              'moral law, and individual duty. Living in accordance with one\'s dharma '
              'leads toward moksha (liberation). Krishna tells Arjuna in the Gita: '
              '"Better is one\'s own dharma, though imperfectly performed."',
          citations: [
            Citation(
              reference: 'Bhagavad Gita 3:35',
              originalText:
                  'śreyān sva-dharmo viguṇaḥ para-dharmāt sv-anuṣṭhitāt\nsva-dharme nidhanaṁ śreyaḥ para-dharmo bhayāvahaḥ',
              translation:
                  'Better is one\'s own dharma, though imperfectly performed, than the dharma of another well performed. Death in one\'s own dharma is better; the dharma of another is fraught with danger.',
            ),
          ],
        );

      case 'sikhism':
        if (lower.contains('waheguru') || lower.contains('god')) {
          return const _MockResponse(
            text:
                'In Sikhism, Waheguru (Wondrous Lord) is the name for the one formless God. '
                'The Guru Granth Sahib begins with the Mool Mantar: "Ik Onkar" — '
                'There is One God, the Eternal Truth, Creator of all, without fear or enmity.',
            citations: [
              Citation(
                reference: 'Guru Granth Sahib · Ang 1',
                originalText:
                    'ੴ ਸਤਿ ਨਾਮੁ ਕਰਤਾ ਪੁਰਖੁ ਨਿਰਭਉ ਨਿਰਵੈਰੁ ਅਕਾਲ ਮੂਰਤਿ ਅਜੂਨੀ ਸੈਭੰ ਗੁਰ ਪ੍ਰਸਾਦਿ ॥',
                translation:
                    'One Universal Creator God. The Name Is Truth. Creative Being Personified. No Fear. No Hatred. Image Of The Undying. Beyond Birth. Self-Existent. By Guru\'s Grace.',
              ),
              Citation(
                reference: 'Japji Sahib · Pauri 1',
                originalText:
                    'ਆਦਿ ਸਚੁ ਜੁਗਾਦਿ ਸਚੁ ॥ ਹੈ ਭੀ ਸਚੁ ਨਾਨਕ ਹੋਸੀ ਭੀ ਸਚੁ ॥',
                translation:
                    'True in the primal beginning. True throughout the ages. True here and now. O Nanak, forever and ever True.',
              ),
            ],
          );
        }
        return const _MockResponse(
          text:
              'Sikh teaching emphasizes Seva (selfless service) as a path to the Divine. '
              'Guru Nanak Dev Ji taught that serving humanity is serving God. '
              'The Langar (community kitchen) embodies this principle — all sit equal, all are fed.',
          citations: [
            Citation(
              reference: 'Guru Granth Sahib · Ang 26',
              originalText: 'ਸਚਹੁ ਓਰੈ ਸਭੁ ਕੋ ਉਪਰਿ ਸਚੁ ਆਚਾਰੁ ॥',
              translation: 'Truth is above everything, but higher still is truthful living.',
            ),
            Citation(
              reference: 'Guru Granth Sahib · Ang 349',
              originalText:
                  'ਵਿਚਿ ਦੁਨੀਆ ਸੇਵ ਕਮਾਈਐ ॥ ਤਾ ਦਰਗਹ ਬੈਸਣੁ ਪਾਈਐ ॥',
              translation:
                  'In the midst of this world, perform selfless service; then, you will be given a seat in the Court of the Lord.',
            ),
          ],
        );

      case 'christianity':
        if (lower.contains('love')) {
          return const _MockResponse(
            text:
                '"Love one another as I have loved you." Jesus placed love at the heart '
                'of his teaching. The Apostle Paul writes that love is patient, kind, '
                'and never fails — the greatest of all virtues, greater even than faith and hope.',
            citations: [
              Citation(
                reference: 'John 13:34',
                originalText: '',
                translation:
                    'A new command I give you: Love one another. As I have loved you, so you must love one another.',
              ),
              Citation(
                reference: '1 Corinthians 13:4–7',
                originalText: '',
                translation:
                    'Love is patient, love is kind. It does not envy, it does not boast, it is not proud. It does not dishonor others, it is not self-seeking, it is not easily angered, it keeps no record of wrongs.',
              ),
            ],
          );
        }
        return const _MockResponse(
          text:
              'The Gospel message centers on salvation through grace and faith. '
              '"For God so loved the world that he gave his one and only Son, '
              'that whoever believes in him shall not perish but have eternal life."',
          citations: [
            Citation(
              reference: 'John 3:16',
              originalText: '',
              translation:
                  'For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.',
            ),
            Citation(
              reference: 'Ephesians 2:8–9',
              originalText: '',
              translation:
                  'For it is by grace you have been saved, through faith — and this is not from yourselves, it is the gift of God — not by works, so that no one can boast.',
            ),
          ],
        );

      default:
        return const _MockResponse(
          text:
              'The sacred traditions of the world converge on timeless truths: '
              'compassion, justice, humility, and the search for meaning. '
              'What specific passage or teaching would you like to explore?',
          citations: [],
        );
    }
  }
}

class _MockResponse {
  const _MockResponse({required this.text, required this.citations});
  final String text;
  final List<Citation> citations;
}
