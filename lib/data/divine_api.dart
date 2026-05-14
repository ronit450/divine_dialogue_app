import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../core/models/chat_message.dart';

sealed class ApiStreamEvent {}

class ApiStreamChunk extends ApiStreamEvent {
  ApiStreamChunk(this.text);
  final String text;
}

class ApiStreamDone extends ApiStreamEvent {
  ApiStreamDone({required this.citations, required this.context});
  final List<Citation> citations;
  final List<dynamic> context;
}

class DivineApi {
  DivineApi._();
  static final DivineApi instance = DivineApi._();

  final _client = http.Client();
  String get _baseUrl => dotenv.env['BASE_URL'] ?? '';

  Stream<ApiStreamEvent> chatStream({
    required String question,
    required String religion,
    required List<dynamic> context,
  }) async* {
    final request = http.Request('POST', Uri.parse('$_baseUrl/chat'));
    request.headers['Content-Type'] = 'application/json';
    request.headers['Accept'] = 'text/event-stream';
    request.body = jsonEncode({
      'question': question,
      'religion': religion,
      'context': context,
    });

    final http.StreamedResponse response;
    try {
      response = await _client.send(request);
    } catch (e) {
      throw Exception('Network error: $e');
    }

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      final detail = _tryParseDetail(body);
      throw Exception(detail ?? 'Server error ${response.statusCode}');
    }

    final pending = StringBuffer();
    await for (final raw in response.stream.transform(utf8.decoder)) {
      pending.write(raw);
      final text = pending.toString();
      final lines = text.split('\n');
      pending.clear();
      pending.write(lines.last); // keep incomplete line for next chunk

      for (int i = 0; i < lines.length - 1; i++) {
        final line = lines[i].trim();
        if (!line.startsWith('data: ')) continue;
        final data = line.substring(6).trim();
        if (data.isEmpty || data == '[DONE]') continue;
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          if (json['chunk'] != null) {
            yield ApiStreamChunk(json['chunk'] as String);
          } else if (json['done'] == true) {
            final passages = json['passages'] as List? ?? [];
            yield ApiStreamDone(
              citations: passages.map((p) {
                final m = p as Map<String, dynamic>;
                return Citation(
                  reference: (m['source_label'] as String?) ?? '',
                  originalText: (m['original_script'] as String?) ?? '',
                  translation: (m['translation_en'] as String?) ?? '',
                  isRtl: (m['script_dir'] as String?) == 'rtl',
                );
              }).toList(),
              context: (json['context'] as List?) ?? [],
            );
          }
        } catch (_) {}
      }
    }
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
