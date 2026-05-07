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
            citations: ['Quran 2:238', 'Sahih Bukhari 1:2:7'],
          );
        }
        if (lower.contains('zakat') || lower.contains('charity')) {
          return const _MockResponse(
            text:
                'Zakat is the third pillar of Islam — an obligatory almsgiving of 2.5% '
                'of one\'s savings to those in need. It purifies wealth and fosters '
                'social solidarity within the Muslim community.',
            citations: ['Quran 9:60', 'Quran 2:177'],
          );
        }
        return const _MockResponse(
          text:
              'In Islam, knowledge is considered a sacred duty. The Prophet Muhammad ﷺ '
              'said: "Seeking knowledge is an obligation upon every Muslim." '
              'The Quran repeatedly calls upon believers to reflect, reason, and understand.',
          citations: ['Quran 96:1-5', 'Ibn Majah 224'],
        );

      case 'hinduism':
        if (lower.contains('karma')) {
          return const _MockResponse(
            text:
                'Karma is the law of cause and effect in Hindu philosophy. Every action '
                '(karma) generates a force that returns to the actor. The Bhagavad Gita '
                'teaches nishkama karma — acting without attachment to outcomes.',
            citations: ['Bhagavad Gita 3:19', 'Bhagavad Gita 2:47'],
          );
        }
        return const _MockResponse(
          text:
              'Dharma is one of the central concepts in Hinduism — the cosmic order, '
              'moral law, and individual duty. Living in accordance with one\'s dharma '
              'leads toward moksha (liberation). Krishna tells Arjuna in the Gita: '
              '"Better is one\'s own dharma, though imperfectly performed."',
          citations: ['Bhagavad Gita 3:35', 'Manusmriti 1:1'],
        );

      case 'sikhism':
        if (lower.contains('waheguru') || lower.contains('god')) {
          return const _MockResponse(
            text:
                'In Sikhism, Waheguru (Wondrous Lord) is the name for the one formless God. '
                'The Guru Granth Sahib begins with the Mool Mantar: "Ik Onkar" — '
                'There is One God, the Eternal Truth, Creator of all, without fear or enmity.',
            citations: ['Guru Granth Sahib, Ang 1', 'Japji Sahib, Pauri 1'],
          );
        }
        return const _MockResponse(
          text:
              'Sikh teaching emphasizes Seva (selfless service) as a path to the Divine. '
              'Guru Nanak Dev Ji taught that serving humanity is serving God. '
              'The Langar (community kitchen) embodies this principle — all sit equal, all are fed.',
          citations: ['Guru Granth Sahib, Ang 26', 'Guru Granth Sahib, Ang 349'],
        );

      case 'christianity':
        if (lower.contains('love')) {
          return const _MockResponse(
            text:
                '"Love one another as I have loved you." Jesus placed love at the heart '
                'of his teaching. The Apostle Paul writes that love is patient, kind, '
                'and never fails — the greatest of all virtues, greater even than faith and hope.',
            citations: ['John 13:34', '1 Corinthians 13:4-7', '1 Corinthians 13:13'],
          );
        }
        return const _MockResponse(
          text:
              'The Gospel message centers on salvation through grace and faith. '
              '"For God so loved the world that he gave his one and only Son, '
              'that whoever believes in him shall not perish but have eternal life."',
          citations: ['John 3:16', 'Ephesians 2:8-9', 'Romans 10:9'],
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
  final List<String> citations;
}
