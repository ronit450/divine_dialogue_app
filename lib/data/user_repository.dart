import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:divine_dialogue/core/models/user_model.dart';

class UserRepository {
  UserRepository._();

  static final instance = UserRepository._();

  final _usersCollection = FirebaseFirestore.instance.collection('users');

  Future<void> createUser(UserModel user) async {
    await _usersCollection.doc(user.uid).set(user.toFirestore());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> fields) async {
    await _usersCollection.doc(uid).update(fields);
  }

  Stream<UserModel?> userStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }
}
