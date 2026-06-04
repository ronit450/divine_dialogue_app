import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FontScale { small, medium, large, xl, xxl }

extension FontScaleX on FontScale {
  double get factor => switch (this) {
    FontScale.small  => 0.85,
    FontScale.medium => 1.0,
    FontScale.large  => 1.15,
    FontScale.xl     => 1.3,
    FontScale.xxl    => 1.5,
  };

  String get label => switch (this) {
    FontScale.small  => 'S',
    FontScale.medium => 'M',
    FontScale.large  => 'L',
    FontScale.xl     => 'XL',
    FontScale.xxl    => 'XXL',
  };
}

final fontScaleProvider = StateNotifierProvider<FontScaleNotifier, FontScale>(
  (_) => FontScaleNotifier(),
);

class FontScaleNotifier extends StateNotifier<FontScale> {
  FontScaleNotifier() : super(FontScale.medium) { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('font_scale');
    if (saved != null) {
      state = FontScale.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => FontScale.medium,
      );
    }
  }

  Future<void> set(FontScale scale) async {
    state = scale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('font_scale', scale.name);
  }
}
