import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/religion.dart';
import '../data/texts_repository.dart';

class ReligionState {
  const ReligionState({
    this.religions = const [],
    this.selectedReligion,
    this.selectedText,
    this.isLoaded = false,
    this.signInDone = false,
    this.onboardingDone = false,
  });

  final List<ReligionModel> religions;
  final ReligionModel? selectedReligion;
  final SacredTextModel? selectedText;
  final bool isLoaded;
  final bool signInDone;
  final bool onboardingDone;

  ReligionState copyWith({
    List<ReligionModel>? religions,
    ReligionModel? selectedReligion,
    SacredTextModel? selectedText,
    bool? isLoaded,
    bool? signInDone,
    bool? onboardingDone,
  }) => ReligionState(
    religions: religions ?? this.religions,
    selectedReligion: selectedReligion ?? this.selectedReligion,
    selectedText: selectedText ?? this.selectedText,
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
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    final signInDone = prefs.getBool('sign_in_done') ?? false;

    ReligionModel? selectedReligion;
    SacredTextModel? selectedText;

    if (savedReligionId != null) {
      try {
        selectedReligion = religions.firstWhere((r) => r.id == savedReligionId);
        if (savedTextId != null) {
          selectedText = selectedReligion.texts.firstWhere(
            (t) => t.id == savedTextId,
            orElse: () => selectedReligion!.texts.first,
          );
        }
      } catch (_) {
        selectedReligion = null;
      }
    }

    state = state.copyWith(
      religions: religions,
      selectedReligion: selectedReligion,
      selectedText: selectedText,
      isLoaded: true,
      signInDone: signInDone,
      onboardingDone: onboardingDone,
    );
  }

  Future<void> selectReligion(ReligionModel religion) async {
    state = state.copyWith(selectedReligion: religion, selectedText: null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_religion', religion.id);
    await prefs.remove('selected_text');
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

  Future<void> completeOnboarding() async {
    state = state.copyWith(onboardingDone: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
  }
}
