import 'dart:async';
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
    state = state.copyWith(sessions: _sorted(sessions), isLoaded: true);
  }

  void clearState() {
    state = const HistoryState();
  }

  void deleteSession(String sessionId) {
    state = state.copyWith(
      sessions: state.sessions.where((s) => s.id != sessionId).toList(),
    );
    unawaited(ChatRepository.instance.deleteSession(sessionId));
  }

  void pinSession(String sessionId) {
    final updated = state.sessions.map((s) {
      return s.id == sessionId ? s.copyWith(isPinned: !s.isPinned) : s;
    }).toList();
    state = state.copyWith(sessions: _sorted(updated));
    final target = updated.firstWhere((s) => s.id == sessionId);
    unawaited(ChatRepository.instance.saveSession(target));
  }

  void renameSession(String sessionId, String newTitle) {
    final updated = state.sessions.map((s) {
      return s.id == sessionId ? s.copyWith(title: newTitle) : s;
    }).toList();
    state = state.copyWith(sessions: updated);
    final target = updated.firstWhere((s) => s.id == sessionId);
    unawaited(ChatRepository.instance.saveSession(target));
  }

  Future<void> clearAll() async {
    state = state.copyWith(sessions: []);
    unawaited(ChatRepository.instance.clearAll());
  }

  static List<ChatSession> _sorted(List<ChatSession> sessions) {
    final list = [...sessions];
    list.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return list;
  }
}
