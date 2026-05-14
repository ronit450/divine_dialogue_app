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
  }) => _chatNonStream(question: question, religion: religion, context: context);

  // Plain POST → full JSON response, then simulates word-by-word streaming for UI.
  // Switch to _chatStreamSse once backend SSE endpoint is ready.
  Stream<ApiStreamEvent> _chatNonStream({
    required String question,
    required String religion,
    required List<dynamic> context,
  }) async* {
    final http.Response response;
    try {
      response = await _client.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'question': question,
          'religion': religion,
          'context': context,
        }),
      );
    } catch (e) {
      throw Exception('Network error: $e');
    }

    if (response.statusCode != 200) {
      final detail = _tryParseDetail(response.body);
      throw Exception(detail ?? 'Server error ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final answer = ((json['answer'] ?? json['response'] ?? json['text'] ?? json['message'] ?? '') as Object).toString();
    final passages = (json['passages'] ?? json['sources'] ?? json['citations'] ?? []) as List;
    final newContext = (json['context'] ?? []) as List;

    if (answer.isEmpty) throw Exception('Empty response from server');

    for (final word in answer.split(' ')) {
      await Future.delayed(const Duration(milliseconds: 35));
      yield ApiStreamChunk('$word ');
    }

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
      context: newContext,
    );
  }

  // ignore: unused_element
  Stream<ApiStreamEvent> _chatStreamSse({
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

    final http.StreamedResponse sseResponse;
    try {
      sseResponse = await _client.send(request);
    } catch (e) {
      throw Exception('Network error: $e');
    }

    if (sseResponse.statusCode != 200) {
      final body = await sseResponse.stream.bytesToString();
      final detail = _tryParseDetail(body);
      throw Exception(detail ?? 'Server error ${sseResponse.statusCode}');
    }

    final pending = StringBuffer();
    await for (final raw in sseResponse.stream.transform(utf8.decoder)) {
      pending.write(raw);
      final text = pending.toString();
      final lines = text.split('\n');
      pending.clear();
      pending.write(lines.last);

      for (int i = 0; i < lines.length - 1; i++) {
        final line = lines[i].trim();
        if (!line.startsWith('data: ')) continue;
        final data = line.substring(6).trim();
        if (data.isEmpty || data == '[DONE]') continue;
        try {
          final j = jsonDecode(data) as Map<String, dynamic>;
          if (j['chunk'] != null) {
            yield ApiStreamChunk(j['chunk'] as String);
          } else if (j['done'] == true) {
            final passages = j['passages'] as List? ?? [];
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
              context: (j['context'] as List?) ?? [],
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
