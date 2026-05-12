import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/models/chat_message.dart';
import '../data/chat_repository.dart';
import '../data/divine_api.dart';

class ChatState {
  const ChatState({
    this.session,
    this.isTyping = false,
    this.conversationContext = const [],
    this.error,
  });
  final ChatSession? session;
  final bool isTyping;
  final List<dynamic> conversationContext;
  final String? error;

  ChatState copyWith({
    ChatSession? session,
    bool? isTyping,
    List<dynamic>? conversationContext,
    String? error,
  }) => ChatState(
    session: session ?? this.session,
    isTyping: isTyping ?? this.isTyping,
    conversationContext: conversationContext ?? this.conversationContext,
    error: error,
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
    state = state.copyWith(session: session, conversationContext: const []);
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
    state = state.copyWith(session: withUser, isTyping: true, error: null);
    await ChatRepository.instance.saveSession(withUser);

    try {
      final result = await DivineApi.instance.chat(
        question: text,
        religion: current.religionId,
        context: state.conversationContext,
      );

      final aiMsg = ChatMessage(
        id: _uuid.v4(),
        text: result.answer,
        isUser: false,
        timestamp: DateTime.now(),
        citations: result.citations,
      );

      final withAi = withUser.copyWith(
        messages: [...withUser.messages, aiMsg],
        updatedAt: DateTime.now(),
      );
      state = state.copyWith(
        session: withAi,
        isTyping: false,
        conversationContext: result.context,
      );
      await ChatRepository.instance.saveSession(withAi);
    } catch (e) {
      state = state.copyWith(
        isTyping: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}
