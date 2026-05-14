import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/models/chat_message.dart';
import '../data/chat_repository.dart';
import '../data/divine_api.dart';
import 'history_provider.dart';
import 'religion_provider.dart';

class ChatState {
  const ChatState({
    this.session,
    this.isTyping = false,
    this.streamingText = '',
    this.conversationContext = const [],
    this.error,
    this.pendingVerseContext,
  });
  final ChatSession? session;
  final bool isTyping;
  final String streamingText;
  final List<dynamic> conversationContext;
  final String? error;
  final VerseContext? pendingVerseContext;

  bool get isStreaming => streamingText.isNotEmpty;

  ChatState copyWith({
    ChatSession? session,
    bool? isTyping,
    String? streamingText,
    List<dynamic>? conversationContext,
    String? error,
    VerseContext? pendingVerseContext,
    bool clearPendingVerse = false,
  }) => ChatState(
    session: session ?? this.session,
    isTyping: isTyping ?? this.isTyping,
    streamingText: streamingText ?? this.streamingText,
    conversationContext: conversationContext ?? this.conversationContext,
    error: error,
    pendingVerseContext:
        clearPendingVerse ? null : (pendingVerseContext ?? this.pendingVerseContext),
  );
}

final chatProvider =
    StateNotifierProvider.autoDispose<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(ref),
);

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this._ref) : super(const ChatState());

  final Ref _ref;
  static const _uuid = Uuid();

  void loadSession(ChatSession session) {
    state = state.copyWith(
      session: session,
      conversationContext: const [],
      streamingText: '',
      clearPendingVerse: true,
    );
  }

  void startNewSession({
    required String religionId,
    required String textId,
    required String textTitle,
  }) {
    final session = ChatSession(
      id: _uuid.v4(),
      title: 'New conversation',
      religionId: religionId,
      textId: textId,
      messages: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(
      session: session,
      conversationContext: const [],
      streamingText: '',
      clearPendingVerse: true,
    );
  }

  void startSessionFromVerse({
    required String reference,
    required String originalText,
    required String translation,
    required String religionId,
    required String textId,
  }) {
    final session = ChatSession(
      id: _uuid.v4(),
      title: 'About $reference',
      religionId: religionId,
      textId: textId,
      messages: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    state = ChatState(
      session: session,
      pendingVerseContext: VerseContext(
        reference: reference,
        originalText: originalText,
        translation: translation,
        religionId: religionId,
        textId: textId,
      ),
    );
  }

  void clearPendingVerse() {
    state = state.copyWith(clearPendingVerse: true);
  }

  Future<void> sendMessage(String text) async {
    if (state.session == null) {
      final rState = _ref.read(religionProvider);
      final religion = rState.selectedReligion;
      final selectedText = rState.selectedText;
      if (religion == null || selectedText == null) return;
      startNewSession(
        religionId: religion.id,
        textId: selectedText.id,
        textTitle: selectedText.title,
      );
    }
    final current = state.session;
    if (current == null) return;

    // Prepend verse context to API question on first message
    final verseCtx = state.pendingVerseContext;
    final apiQuestion = verseCtx != null
        ? 'I am reading ${verseCtx.reference}.\n\nOriginal: ${verseCtx.originalText}\nTranslation: ${verseCtx.translation}\n\nMy question: $text'
        : text;

    final isFirst = current.messages.isEmpty;
    final title = isFirst
        ? (text.length > 45 ? '${text.substring(0, 45)}…' : text)
        : current.title;

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final withUser = current.copyWith(
      title: title,
      messages: [...current.messages, userMsg],
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(
      session: withUser,
      isTyping: true,
      streamingText: '',
      error: null,
      clearPendingVerse: true,
    );
    await ChatRepository.instance.saveSession(withUser);
    _ref.read(historyProvider.notifier).load();

    try {
      final textBuffer = StringBuffer();
      List<Citation> citations = [];
      List<dynamic> newContext = [];

      await for (final event in DivineApi.instance.chatStream(
        question: apiQuestion,
        religion: current.religionId,
        context: state.conversationContext,
      )) {
        if (event is ApiStreamChunk) {
          textBuffer.write(event.text);
          state = state.copyWith(
            isTyping: false,
            streamingText: textBuffer.toString(),
          );
        } else if (event is ApiStreamDone) {
          citations = event.citations;
          newContext = event.context;
        }
      }

      final aiMsg = ChatMessage(
        id: _uuid.v4(),
        text: textBuffer.toString(),
        isUser: false,
        timestamp: DateTime.now(),
        citations: citations,
      );

      final withAi = withUser.copyWith(
        messages: [...withUser.messages, aiMsg],
        updatedAt: DateTime.now(),
      );
      state = state.copyWith(
        session: withAi,
        isTyping: false,
        streamingText: '',
        conversationContext: newContext,
      );
      await ChatRepository.instance.saveSession(withAi);
      _ref.read(historyProvider.notifier).load();
    } catch (e) {
      state = state.copyWith(
        isTyping: false,
        streamingText: '',
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}
