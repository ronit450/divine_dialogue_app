import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/models/saved_verse.dart';

class SavedVersesRepository {
  SavedVersesRepository._();
  static final instance = SavedVersesRepository._();

  CollectionReference<Map<String, dynamic>>? _col() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('savedVerses');
  }

  Future<List<SavedVerse>> loadAll() async {
    final col = _col();
    if (col == null) return [];
    try {
      final snap = await col.orderBy('savedAt', descending: true).get();
      return snap.docs.map((d) => SavedVerse.fromJson(d.data())).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(SavedVerse verse) async {
    final col = _col();
    if (col == null) return;
    try {
      await col.doc(verse.id).set(verse.toJson());
    } catch (_) {}
  }

  Future<void> delete(String id) async {
    final col = _col();
    if (col == null) return;
    try {
      await col.doc(id).delete();
    } catch (_) {}
  }
}
