import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleState {
  final Locale locale;
  final bool languagePicked;
  final bool isLoaded;

  const LocaleState({
    required this.locale,
    required this.languagePicked,
    required this.isLoaded,
  });

  LocaleState copyWith({Locale? locale, bool? languagePicked, bool? isLoaded}) =>
      LocaleState(
        locale: locale ?? this.locale,
        languagePicked: languagePicked ?? this.languagePicked,
        isLoaded: isLoaded ?? this.isLoaded,
      );
}

class LocaleNotifier extends StateNotifier<LocaleState> {
  LocaleNotifier()
      : super(const LocaleState(
          locale: Locale('en'),
          languagePicked: false,
          isLoaded: false,
        )) {
    _load();
  }

  static const _key = 'app_locale';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null) {
      state = LocaleState(locale: Locale(code), languagePicked: true, isLoaded: true);
    } else {
      state = state.copyWith(isLoaded: true);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale, languagePicked: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, LocaleState>(
  (ref) => LocaleNotifier(),
);
