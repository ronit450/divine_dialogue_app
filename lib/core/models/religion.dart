import 'package:flutter/material.dart';

class ReligionModel {
  const ReligionModel({
    required this.id,
    required this.name,
    required this.accentColor,
    required this.accentSoft,
    required this.salutation,
    required this.texts,
  });

  final String id;
  final String name;
  final Color accentColor;
  final Color accentSoft;
  final String salutation;
  final List<SacredTextModel> texts;

  factory ReligionModel.fromJson(Map<String, dynamic> json) => ReligionModel(
    id: json['id'] as String,
    name: json['name'] as String,
    accentColor: Color(int.parse('FF${json['accentColor']}', radix: 16)),
    accentSoft: Color(int.parse('FF${json['accentSoft']}', radix: 16)),
    salutation: json['salutation'] as String? ?? '',
    texts: (json['texts'] as List)
        .map((t) => SacredTextModel.fromJson(t as Map<String, dynamic>))
        .toList(),
  );
}

class SacredTextModel {
  const SacredTextModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
  });

  final String id;
  final String title;
  final String description;
  final String category;

  factory SacredTextModel.fromJson(Map<String, dynamic> json) => SacredTextModel(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    category: json['category'] as String,
  );
}
