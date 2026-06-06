import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
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

  Future<void> updateLastActive(String uid) async {
    await _usersCollection.doc(uid).update({
      'lastActiveAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProfile(String uid, {
    String? firstName,
    String? lastName,
    int? age,
    String? photoUrl,
    String? religionId,
  }) async {
    final fields = <String, dynamic>{
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (age != null) 'age': age,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (religionId != null) 'religionId': religionId,
    };
    if (fields.isEmpty) return;
    await _usersCollection.doc(uid).update(fields);
  }

  Stream<UserModel?> userStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  static const _uuid = Uuid();

  Future<void> saveVerse({
    required String textId,
    required String reference,
    required String text,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final id = _uuid.v4();
    await _usersCollection.doc(uid).collection('savedVerses').doc(id).set({
      'textId': textId,
      'reference': reference,
      'text': text,
      'savedAt': FieldValue.serverTimestamp(),
    });
  }
}
