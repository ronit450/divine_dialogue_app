import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/religion.dart';
import '../data/texts_repository.dart';

class ReligionState {
  const ReligionState({
    this.religions = const [],
    this.selectedReligion,
    this.selectedText,
    this.selectedTexts = const [],
    this.isLoaded = false,
    this.signInDone = false,
    this.onboardingDone = false,
  });

  final List<ReligionModel> religions;
  final ReligionModel? selectedReligion;
  final SacredTextModel? selectedText;
  final List<SacredTextModel> selectedTexts;
  final bool isLoaded;
  final bool signInDone;
  final bool onboardingDone;

  ReligionState copyWith({
    List<ReligionModel>? religions,
    ReligionModel? selectedReligion,
    SacredTextModel? selectedText,
    List<SacredTextModel>? selectedTexts,
    bool? isLoaded,
    bool? signInDone,
    bool? onboardingDone,
  }) => ReligionState(
    religions: religions ?? this.religions,
    selectedReligion: selectedReligion ?? this.selectedReligion,
    selectedText: selectedText ?? this.selectedText,
    selectedTexts: selectedTexts ?? this.selectedTexts,
    isLoaded: isLoaded ?? this.isLoaded,
    signInDone: signInDone ?? this.signInDone,
    onboardingDone: onboardingDone ?? this.onboardingDone,
  );
}

final religionProvider = StateNotifierProvider<ReligionNotifier, ReligionState>(
  (_) => ReligionNotifier(),
);

class ReligionNotifier extends StateNotifier<ReligionState> {
  ReligionNotifier() : super(const ReligionState()) {
    _init();
  }

  Future<void> _init() async {
    final religions = await TextsRepository.instance.loadReligions();
    final prefs = await SharedPreferences.getInstance();
    final savedReligionId = prefs.getString('selected_religion');
    final savedTextId = prefs.getString('selected_text');
    final savedTextIdsStr = prefs.getString('selected_texts');
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    final signInDone = prefs.getBool('sign_in_done') ?? false;

    ReligionModel? selectedReligion;
    SacredTextModel? selectedText;
    List<SacredTextModel> selectedTexts = [];

    if (savedReligionId != null) {
      try {
        selectedReligion = religions.firstWhere((r) => r.id == savedReligionId);
        if (savedTextIdsStr != null && savedTextIdsStr.isNotEmpty) {
          for (final id in savedTextIdsStr.split(',')) {
            try {
              selectedTexts.add(selectedReligion.texts.firstWhere((t) => t.id == id));
            } catch (_) {}
          }
        } else if (savedTextId != null) {
          try {
            final t = selectedReligion.texts.firstWhere((t) => t.id == savedTextId);
            selectedTexts = [t];
            selectedText = t;
          } catch (_) {}
        }
        selectedText ??= selectedTexts.firstOrNull;
        // Fallback: always have a text selected when religion is set
        if (selectedText == null && selectedReligion.texts.isNotEmpty) {
          selectedText = selectedReligion.texts.first;
          selectedTexts = [selectedText];
        }
      } catch (_) {
        selectedReligion = null;
      }
    }

    // Safety net: if onboarding is done but religion couldn't be restored, default to first
    if (onboardingDone && selectedReligion == null && religions.isNotEmpty) {
      selectedReligion = religions.first;
      if (selectedReligion.texts.isNotEmpty) {
        selectedText = selectedReligion.texts.first;
        selectedTexts = [selectedText];
      }
    }

    state = state.copyWith(
      religions: religions,
      selectedReligion: selectedReligion,
      selectedText: selectedText,
      selectedTexts: selectedTexts,
      isLoaded: true,
      signInDone: signInDone,
      onboardingDone: onboardingDone,
    );
  }

  void selectReligion(ReligionModel religion) {
    state = state.copyWith(selectedReligion: religion, selectedTexts: []);
  }

  Future<void> changeReligion(ReligionModel religion) async {
    // Use constructor directly — copyWith cannot null out selectedText,
    // and leaving the old religion's text causes "no books selected" errors
    // when the old textId is not in the backend's book mapping.
    state = ReligionState(
      religions: state.religions,
      selectedReligion: religion,
      selectedText: null,
      selectedTexts: const [],
      isLoaded: state.isLoaded,
      signInDone: state.signInDone,
      onboardingDone: state.onboardingDone,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_religion', religion.id);
    await prefs.remove('selected_texts');
    await prefs.remove('selected_text');
  }

  Future<void> saveSelectedTexts() async {
    final texts = state.selectedTexts;
    final prefs = await SharedPreferences.getInstance();
    if (texts.isEmpty) {
      await prefs.remove('selected_texts');
      return;
    }
    await prefs.setString('selected_texts', texts.map((t) => t.id).join(','));
    final primary = texts.first;
    state = state.copyWith(selectedText: primary, selectedTexts: texts);
    await prefs.setString('selected_text', primary.id);
  }

  void toggleText(SacredTextModel text) {
    final current = List<SacredTextModel>.from(state.selectedTexts);
    final idx = current.indexWhere((t) => t.id == text.id);
    if (idx >= 0) {
      current.removeAt(idx);
    } else {
      current.add(text);
    }
    state = state.copyWith(selectedTexts: current);
  }

  Future<void> selectText(SacredTextModel text) async {
    state = state.copyWith(selectedText: text);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_text', text.id);
  }

  Future<void> completeSignIn() async {
    state = state.copyWith(signInDone: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sign_in_done', true);
  }

  Future<void> resetSignIn() async {
    state = state.copyWith(signInDone: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sign_in_done', false);
  }

  Future<void> completeOnboarding() async {
    final primary = state.selectedTexts.firstOrNull ?? state.selectedText;
    state = state.copyWith(
      onboardingDone: true,
      selectedText: primary,
    );
    final prefs = await SharedPreferences.getInstance();
    if (state.selectedReligion != null) {
      await prefs.setString('selected_religion', state.selectedReligion!.id);
    }
    if (primary != null) {
      await prefs.setString('selected_text', primary.id);
    }
    await prefs.setBool('onboarding_done', true);
  }
}
