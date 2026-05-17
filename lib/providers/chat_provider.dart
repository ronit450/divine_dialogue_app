import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/models/chat_message.dart';
import '../data/chat_repository.dart';
import '../data/divine_api.dart';
import 'history_provider.dart';
import 'religion_provider.dart';

final pendingMessageProvider = StateProvider<String?>((ref) => null);

class ChatState {
  const ChatState({
    this.session,
    this.isTyping = false,
    this.streamingText = '',
    this.statusMessage = '',
    this.streamingPassages = const [],
    this.conversationContext = const [],
    this.error,
    this.pendingVerseContext,
  });
  final ChatSession? session;
  final bool isTyping;
  final String streamingText;
  final String statusMessage;
  final List<Citation> streamingPassages;
  final List<dynamic> conversationContext;
  final String? error;
  final VerseContext? pendingVerseContext;

  bool get isStreaming => streamingText.isNotEmpty;

  ChatState copyWith({
    ChatSession? session,
    bool? isTyping,
    String? streamingText,
    String? statusMessage,
    List<Citation>? streamingPassages,
    List<dynamic>? conversationContext,
    String? error,
    VerseContext? pendingVerseContext,
    bool clearPendingVerse = false,
  }) => ChatState(
    session: session ?? this.session,
    isTyping: isTyping ?? this.isTyping,
    streamingText: streamingText ?? this.streamingText,
    statusMessage: statusMessage ?? this.statusMessage,
    streamingPassages: streamingPassages ?? this.streamingPassages,
    conversationContext: conversationContext ?? this.conversationContext,
    error: error,
    pendingVerseContext:
        clearPendingVerse ? null : (pendingVerseContext ?? this.pendingVerseContext),
  );
}

final chatProvider =
    StateNotifierProvider<ChatNotifier, ChatState>(
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

  Future<void> sendMessage(String rawText) async {
    final text = rawText.length > 2000 ? rawText.substring(0, 2000) : rawText;
    if (state.session == null) {
      final rState = _ref.read(religionProvider);
      final religion = rState.selectedReligion;
      final selectedText = rState.selectedText ?? religion?.texts.firstOrNull;
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
      statusMessage: '',
      streamingPassages: const [],
      error: null,
      clearPendingVerse: true,
    );
    await ChatRepository.instance.saveSession(withUser);
    _ref.read(historyProvider.notifier).load();

    try {
      final textBuffer = StringBuffer();
      List<Citation> citations = [];
      List<dynamic> newContext = [];

      // Cancel any in-flight request before starting a new one
      DivineApi.instance.cancelCurrentRequest();

      // Cap context window to last 20 items to bound memory + API payload size
      final ctx = state.conversationContext;
      final cappedContext = ctx.length > 20 ? ctx.sublist(ctx.length - 20) : ctx;

      await for (final event in DivineApi.instance.chatStream(
        question: apiQuestion,
        religion: current.religionId,
        context: cappedContext,
        books: _booksForText(current.textId),
      )) {
        if (event is ApiStreamStatus) {
          state = state.copyWith(statusMessage: event.message);
        } else if (event is ApiStreamPassage) {
          state = state.copyWith(
            streamingPassages: [...state.streamingPassages, event.citation],
          );
        } else if (event is ApiStreamChunk) {
          textBuffer.write(event.text);
          state = state.copyWith(
            isTyping: false,
            streamingText: textBuffer.toString(),
          );
        } else if (event is ApiStreamDone) {
          textBuffer.clear();
          textBuffer.write(event.answer);
          citations = event.citations;
          newContext = event.context;
        } else if (event is ApiStreamError) {
          throw Exception(event.message);
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
        statusMessage: '',
        streamingPassages: const [],
        conversationContext: newContext,
      );
      await ChatRepository.instance.saveSession(withAi);
      _ref.read(historyProvider.notifier).load();
    } catch (e) {
      state = state.copyWith(
        isTyping: false,
        streamingText: '',
        statusMessage: '',
        streamingPassages: const [],
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  static List<String> _booksForText(String textId) {
    const mapping = {
      'quran': 'quran',
      'guru_granth_sahib': 'guru_granth_sahib',
      'bible_nrsv': 'bible',
      'bhagavad_gita': 'bhagavad_gita',
    };
    final key = mapping[textId];
    return key != null ? [key] : [];
  }
}
