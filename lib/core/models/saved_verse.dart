import 'package:cloud_firestore/cloud_firestore.dart';
import 'scripture.dart';

class SavedVerse {
  const SavedVerse({
    required this.id,
    required this.textId,
    required this.reference,
    required this.text,
    this.translation,
    required this.savedAt,
  });

  // Deterministic ID: "$textId-$chapterNum-$verseNum"
  final String id;
  final String textId;
  final String reference;
  final String text;
  final String? translation;
  final DateTime savedAt;

  String get religionId => ScriptureTextMeta.forTextId(textId)?.religionId ?? '';
  String get textTitle => ScriptureTextMeta.forTextId(textId)?.title ?? textId;

  static String makeId(String textId, int chapter, int verse) =>
      '$textId-$chapter-$verse';

  Map<String, dynamic> toJson() => {
        'id': id,
        'textId': textId,
        'reference': reference,
        'text': text,
        if (translation != null) 'translation': translation,
        'savedAt': savedAt.toIso8601String(),
      };

  factory SavedVerse.fromJson(Map<String, dynamic> json) => SavedVerse(
        id: json['id'] as String,
        textId: json['textId'] as String,
        reference: json['reference'] as String,
        text: json['text'] as String,
        translation: json['translation'] as String?,
        savedAt: json['savedAt'] is Timestamp
            ? (json['savedAt'] as Timestamp).toDate()
            : DateTime.parse(json['savedAt'] as String),
      );
}
