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
        .limit(20)
        .get();
    return snap.docs.map((d) => ChatSession.fromJson(d.data())).toList();
  }

  Future<void> saveSession(ChatSession session) async {
    final uid = _uid;
    if (uid == null) return;
    // Firestore doc limit is 1MB — cap at 200 messages to stay well within it
    final toSave = session.messages.length > 200
        ? session.copyWith(messages: session.messages.sublist(session.messages.length - 200))
        : session;
    await _conv(uid).doc(session.id).set(toSave.toJson());
  }

  Future<void> deleteSession(String sessionId) async {
    final uid = _uid;
    if (uid == null) return;
    await _conv(uid).doc(sessionId).delete();
  }

  Future<void> clearAll() async {
    final uid = _uid;
    if (uid == null) return;
    // Paginated deletion — avoids loading all docs into memory at once
    QuerySnapshot snap;
    do {
      snap = await _conv(uid).limit(20).get();
      if (snap.docs.isEmpty) break;
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } while (snap.docs.length == 20);
  }
}
