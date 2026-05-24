import 'dart:async';
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
    this.streamingPreamble = '',
    this.streamingText = '',
    this.hasToolCall = false,
    this.statusMessage = '',
    this.streamingPassages = const [],
    this.conversationContext = const [],
    this.error,
    this.pendingVerseContext,
  });
  final ChatSession? session;
  // True from the moment the user sends until the `done` event arrives.
  final bool isTyping;
  // Phase-1 acknowledgment text (italic, muted in UI).
  final String streamingPreamble;
  // Phase-2 answer text (Markdown body in UI).
  final String streamingText;
  // Set true on the first `status` event whose message starts with "Searching".
  final bool hasToolCall;
  final String statusMessage;
  final List<Citation> streamingPassages;
  final List<dynamic> conversationContext;
  final String? error;
  final VerseContext? pendingVerseContext;

  /// True while *anything* is in-flight in the agent bubble — preamble,
  /// tool-call, or answer text. Used by screens to decide whether to render
  /// the in-progress bubble or the static typing dots.
  bool get isStreaming =>
      streamingText.isNotEmpty || streamingPreamble.isNotEmpty || hasToolCall;

  ChatState copyWith({
    ChatSession? session,
    bool? isTyping,
    String? streamingPreamble,
    String? streamingText,
    bool? hasToolCall,
    String? statusMessage,
    List<Citation>? streamingPassages,
    List<dynamic>? conversationContext,
    String? error,
    VerseContext? pendingVerseContext,
    bool clearPendingVerse = false,
  }) => ChatState(
    session: session ?? this.session,
    isTyping: isTyping ?? this.isTyping,
    streamingPreamble: streamingPreamble ?? this.streamingPreamble,
    streamingText: streamingText ?? this.streamingText,
    hasToolCall: hasToolCall ?? this.hasToolCall,
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
      streamingPreamble: '',
      streamingText: '',
      hasToolCall: false,
      streamingPassages: const [],
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
      streamingPreamble: '',
      streamingText: '',
      hasToolCall: false,
      streamingPassages: const [],
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
      streamingPreamble: '',
      streamingText: '',
      hasToolCall: false,
      statusMessage: '',
      streamingPassages: const [],
      error: null,
      clearPendingVerse: true,
    );
    // Fire save concurrently — don't block stream start
    unawaited(ChatRepository.instance.saveSession(withUser));
    _ref.read(historyProvider.notifier).load();

    try {
      final preambleBuffer = StringBuffer();
      final answerBuffer = StringBuffer();
      List<Citation> citations = [];
      List<dynamic> newContext = [];
      var lastRender = DateTime.now();

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
          final msg = event.message;
          // Per spec: any status starting with "Searching" marks the tool-call
          // block as visible for the rest of this turn (and after `done`).
          final flipTool = msg.startsWith('Searching') && !state.hasToolCall;
          state = state.copyWith(
            statusMessage: msg,
            hasToolCall: flipTool ? true : null,
          );
        } else if (event is ApiStreamPassage) {
          state = state.copyWith(
            streamingPassages: [...state.streamingPassages, event.citation],
          );
        } else if (event is ApiStreamChunk) {
          if (event.phase == 'preamble') {
            preambleBuffer.write(event.text);
            // Preamble arrives in ~600ms — paint each delta immediately so the
            // bubble feels responsive.
            state = state.copyWith(
              isTyping: false,
              streamingPreamble: preambleBuffer.toString(),
            );
          } else {
            answerBuffer.write(event.text);
            final now = DateTime.now();
            if (now.difference(lastRender).inMilliseconds >= 50) {
              lastRender = now;
              state = state.copyWith(
                isTyping: false,
                streamingText: answerBuffer.toString(),
              );
            } else if (state.isTyping) {
              state = state.copyWith(isTyping: false);
            }
          }
        } else if (event is ApiStreamDone) {
          answerBuffer
            ..clear()
            ..write(event.answer);
          citations = event.citations;
          newContext = event.context;
        } else if (event is ApiStreamError) {
          throw Exception(event.message);
        }
      }

      // Commit the full in-progress state to history — preamble + hasToolCall
      // ride along so the bubble layout doesn't shift after `done`.
      final aiMsg = ChatMessage(
        id: _uuid.v4(),
        text: answerBuffer.toString(),
        isUser: false,
        timestamp: DateTime.now(),
        citations: citations,
        preamble: preambleBuffer.toString(),
        hasToolCall: state.hasToolCall,
      );

      final withAi = withUser.copyWith(
        messages: [...withUser.messages, aiMsg],
        updatedAt: DateTime.now(),
      );
      state = state.copyWith(
        session: withAi,
        isTyping: false,
        streamingPreamble: '',
        streamingText: '',
        hasToolCall: false,
        statusMessage: '',
        streamingPassages: const [],
        conversationContext: newContext,
      );
      await ChatRepository.instance.saveSession(withAi);
      _ref.read(historyProvider.notifier).load();
    } catch (e) {
      state = state.copyWith(
        isTyping: false,
        streamingPreamble: '',
        streamingText: '',
        hasToolCall: false,
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
