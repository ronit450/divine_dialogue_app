import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../core/models/chat_message.dart';

class ApiChatResult {
  const ApiChatResult({
    required this.answer,
    required this.citations,
    required this.context,
  });

  final String answer;
  final List<Citation> citations;
  final List<dynamic> context;
}

class DivineApi {
  DivineApi._();
  static final DivineApi instance = DivineApi._();

  final _client = http.Client();
  String get _baseUrl => dotenv.env['BASE_URL'] ?? '';

  Future<ApiChatResult> chat({
    required String question,
    required String religion,
    required List<dynamic> context,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'question': question,
        'religion': religion,
        'context': context,
      }),
    );

    if (response.statusCode != 200) {
      final detail = _tryParseDetail(response.body);
      throw Exception(detail ?? 'Server error ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final passages = (json['passages'] as List? ?? []);
    final citations = passages.map((p) {
      final map = p as Map<String, dynamic>;
      return Citation(
        reference: (map['source_label'] as String?) ?? '',
        originalText: (map['original_script'] as String?) ?? '',
        translation: (map['translation_en'] as String?) ?? '',
        isRtl: (map['script_dir'] as String?) == 'rtl',
      );
    }).toList();

    return ApiChatResult(
      answer: (json['answer'] as String?) ?? '',
      citations: citations,
      context: (json['context'] as List?) ?? [],
    );
  }

  String? _tryParseDetail(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['detail'] as String?;
    } catch (_) {
      return null;
    }
  }
}
