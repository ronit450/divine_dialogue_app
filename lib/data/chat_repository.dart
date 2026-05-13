import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/models/chat_message.dart';

class ChatRepository {
  ChatRepository._();
  static final ChatRepository instance = ChatRepository._();

  final _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _conv(String uid) =>
      _db.collection('users').doc(uid).collection('conversations');

  Future<List<ChatSession>> loadSessions() async {
    final uid = _uid;
    if (uid == null) return [];
    final snap = await _conv(uid)
        .orderBy('updatedAt', descending: true)
        .get();
    return snap.docs.map((d) => ChatSession.fromJson(d.data())).toList();
  }

  Future<void> saveSession(ChatSession session) async {
    final uid = _uid;
    if (uid == null) return;
    await _conv(uid).doc(session.id).set(session.toJson());
  }

  Future<void> deleteSession(String sessionId) async {
    final uid = _uid;
    if (uid == null) return;
    await _conv(uid).doc(sessionId).delete();
  }

  Future<void> clearAll() async {
    final uid = _uid;
    if (uid == null) return;
    final snap = await _conv(uid).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
