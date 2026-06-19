import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ShareCardTemplate { midnight, paper, garden }

extension ShareCardTemplateExt on ShareCardTemplate {
  String get displayName => switch (this) {
        ShareCardTemplate.midnight => 'Midnight',
        ShareCardTemplate.paper => 'Paper',
        ShareCardTemplate.garden => 'Garden',
      };

  String get subtitle => switch (this) {
        ShareCardTemplate.midnight => 'Refined dark — warm charcoal, soft glow',
        ShareCardTemplate.paper => 'Light — bone paper, ink, editorial',
        ShareCardTemplate.garden => 'Ornamental — gilded mandala & flourishes',
      };
}

class ShareCardStyleNotifier extends StateNotifier<ShareCardTemplate> {
  static const _key = 'share_card_style';

  ShareCardStyleNotifier() : super(ShareCardTemplate.midnight) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString(_key);
    if (val != null) {
      state = ShareCardTemplate.values.firstWhere(
        (t) => t.name == val,
        orElse: () => ShareCardTemplate.midnight,
      );
    }
  }

  Future<void> setTemplate(ShareCardTemplate template) async {
    state = template;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, template.name);
  }
}

final shareCardStyleProvider =
    StateNotifierProvider<ShareCardStyleNotifier, ShareCardTemplate>(
  (ref) => ShareCardStyleNotifier(),
);
