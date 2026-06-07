import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/saved_verse.dart';
import '../data/saved_verses_repository.dart';
import 'auth_provider.dart';

class SavedVersesNotifier extends StateNotifier<List<SavedVerse>> {
  SavedVersesNotifier(this._ref) : super([]) {
    _load();
  }

  final Ref _ref;
  final _repo = SavedVersesRepository.instance;
  // Guards against _load() overwriting optimistic state from toggle().
  bool _localWritten = false;

  Future<void> _load() async {
    final verses = await _repo.loadAll();
    if (mounted && !_localWritten) state = verses;
  }

  bool isSaved(String id) => state.any((v) => v.id == id);

  Future<void> toggle(SavedVerse verse) async {
    // Guest users cannot persist saves — Firestore writes are blocked for them
    if (_ref.read(authProvider).isGuest) return;

    _localWritten = true;
    if (isSaved(verse.id)) {
      state = state.where((v) => v.id != verse.id).toList();
      unawaited(_repo.delete(verse.id));
    } else {
      state = [verse, ...state];
      unawaited(_repo.save(verse));
    }
  }

  void clear() {
    _localWritten = false;
    state = const [];
  }

  Future<void> reload() async {
    _localWritten = false;
    state = const [];
    await _load();
  }
}

final savedVersesProvider =
    StateNotifierProvider<SavedVersesNotifier, List<SavedVerse>>(
  (ref) => SavedVersesNotifier(ref),
);
