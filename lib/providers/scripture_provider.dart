import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScripturePositions {
  final Map<String, (int chapter, int verse)> positions;
  const ScripturePositions({this.positions = const {}});

  ScripturePositions copyWith(String textId, int chapter, int verse) =>
      ScripturePositions(positions: {...positions, textId: (chapter, verse)});

  bool hasPosition(String textId) => positions.containsKey(textId);

  (int chapter, int verse) getPosition(String textId) =>
      positions[textId] ?? (1, 1);
}

class ScripturePositionNotifier extends StateNotifier<ScripturePositions> {
  ScripturePositionNotifier() : super(const ScripturePositions()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('reader_pos_'));
    final positions = <String, (int, int)>{};
    for (final key in keys) {
      final textId = key.substring('reader_pos_'.length);
      final val = prefs.getString(key) ?? '1:1';
      final parts = val.split(':');
      if (parts.length == 2) {
        positions[textId] = (
          int.tryParse(parts[0]) ?? 1,
          int.tryParse(parts[1]) ?? 1,
        );
      }
    }
    state = ScripturePositions(positions: positions);
  }

  Future<void> savePosition(String textId, int chapter, int verse) async {
    state = state.copyWith(textId, chapter, verse);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reader_pos_$textId', '$chapter:$verse');
  }
}

final scripturePositionProvider =
    StateNotifierProvider<ScripturePositionNotifier, ScripturePositions>(
  (_) => ScripturePositionNotifier(),
);
