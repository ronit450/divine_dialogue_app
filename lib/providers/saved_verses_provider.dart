import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/saved_verse.dart';
import '../data/saved_verses_repository.dart';

class SavedVersesNotifier extends StateNotifier<List<SavedVerse>> {
  SavedVersesNotifier() : super([]) {
    _load();
  }

  final _repo = SavedVersesRepository.instance;

  Future<void> _load() async {
    final verses = await _repo.loadAll();
    if (mounted) state = verses;
  }

  bool isSaved(String id) => state.any((v) => v.id == id);

  Future<void> toggle(SavedVerse verse) async {
    if (isSaved(verse.id)) {
      state = state.where((v) => v.id != verse.id).toList();
      unawaited(_repo.delete(verse.id));
    } else {
      state = [verse, ...state];
      unawaited(_repo.save(verse));
    }
  }
}

final savedVersesProvider =
    StateNotifierProvider<SavedVersesNotifier, List<SavedVerse>>(
  (_) => SavedVersesNotifier(),
);
