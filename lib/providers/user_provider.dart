import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/user_model.dart';
import '../data/user_repository.dart';
import 'religion_provider.dart';

class UserState {
  const UserState({this.user, this.isLoading = false});

  final UserModel? user;
  final bool isLoading;

  bool get hasProfile => user != null;

  UserState copyWith({UserModel? user, bool? isLoading}) => UserState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
      );
}

class UserNotifier extends StateNotifier<UserState> {
  UserNotifier(this._ref) : super(const UserState());

  final Ref _ref;

  Future<void> loadUser(String uid) async {
    state = state.copyWith(isLoading: true);
    final user = await UserRepository.instance.getUser(uid);
    state = UserState(user: user, isLoading: false);
  }

  Future<void> createUser({
    required String uid,
    required String firstName,
    required String lastName,
    required int age,
    String? photoUrl,
    String? religionId,
  }) async {
    state = state.copyWith(isLoading: true);

    final resolvedReligionId = religionId ??
        _ref.read(religionProvider).selectedReligion?.id ??
        '';

    final now = DateTime.now();
    final user = UserModel(
      uid: uid,
      firstName: firstName,
      lastName: lastName,
      age: age,
      religionId: resolvedReligionId,
      selectedTextIds: const [],
      createdAt: now,
      lastActiveAt: now,
      photoUrl: photoUrl,
    );

    await UserRepository.instance.createUser(user);
    state = UserState(user: user, isLoading: false);
  }

  Future<void> updateUser(Map<String, dynamic> fields) async {
    final current = state.user;
    if (current == null) return;

    state = state.copyWith(isLoading: true);
    await UserRepository.instance.updateUser(current.uid, fields);

    final updated = await UserRepository.instance.getUser(current.uid);
    state = UserState(user: updated, isLoading: false);
  }

  void clear() {
    state = const UserState();
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>(
  (ref) => UserNotifier(ref),
);
