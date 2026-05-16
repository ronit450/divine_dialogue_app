import 'dart:convert';
import 'package:flutter/services.dart';
import '../core/models/religion.dart';

class TextsRepository {
  TextsRepository._();
  static final TextsRepository instance = TextsRepository._();

  List<ReligionModel>? _religions;
  Map<String, List<DailyVerse>>? _verses;

  Future<List<ReligionModel>> loadReligions() async {
    if (_religions != null) return _religions!;
    final raw = await rootBundle.loadString('assets/data/texts_catalog.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _religions = (json['religions'] as List)
        .map((r) => ReligionModel.fromJson(r as Map<String, dynamic>))
        .toList();
    return _religions!;
  }

  Future<List<DailyVerse>> loadVerses(String religionId) async {
    if (_verses != null) return _verses![religionId] ?? [];
    final raw = await rootBundle.loadString('assets/data/daily_verses.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _verses = json.map((key, value) => MapEntry(
      key,
      (value as List)
          .map((v) => DailyVerse.fromJson(v as Map<String, dynamic>))
          .toList(),
    ));
    return _verses![religionId] ?? [];
  }

  Future<DailyVerse> getDailyVerse(String religionId) async {
    final verses = await loadVerses(religionId);
    if (verses.isEmpty) return const DailyVerse(text: '', source: '', ref: '');
    final dayIndex = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays % verses.length;
    return verses[dayIndex];
  }
}

class DailyVerse {
  const DailyVerse({
    required this.text,
    required this.source,
    required this.ref,
    this.textId,
    this.navChapter,
    this.originalText,
  });
  final String text;
  final String source;
  final String ref;
  final String? textId;
  final int? navChapter;
  final String? originalText;

  factory DailyVerse.fromJson(Map<String, dynamic> json) => DailyVerse(
    text: json['text'] as String,
    source: json['source'] as String,
    ref: json['ref'] as String,
    textId: json['textId'] as String?,
    navChapter: json['navChapter'] as int?,
    originalText: json['originalText'] as String?,
  );
}
