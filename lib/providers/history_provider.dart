import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/chat_message.dart';
import '../data/chat_repository.dart';

class HistoryState {
  const HistoryState({this.sessions = const [], this.isLoaded = false});
  final List<ChatSession> sessions;
  final bool isLoaded;

  HistoryState copyWith({List<ChatSession>? sessions, bool? isLoaded}) =>
      HistoryState(
        sessions: sessions ?? this.sessions,
        isLoaded: isLoaded ?? this.isLoaded,
      );
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>(
  (_) => HistoryNotifier(),
);

class HistoryNotifier extends StateNotifier<HistoryState> {
  HistoryNotifier() : super(const HistoryState()) {
    load();
  }

  Future<void> load() async {
    final sessions = await ChatRepository.instance.loadSessions();
    state = state.copyWith(sessions: sessions, isLoaded: true);
  }

  Future<void> deleteSession(String sessionId) async {
    await ChatRepository.instance.deleteSession(sessionId);
    state = state.copyWith(
      sessions: state.sessions.where((s) => s.id != sessionId).toList(),
    );
  }

  Future<void> clearAll() async {
    await ChatRepository.instance.clearAll();
    state = state.copyWith(sessions: []);
  }
}
