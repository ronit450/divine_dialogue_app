import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../core/models/chat_message.dart';

sealed class ApiStreamEvent {}

class ApiStreamStatus extends ApiStreamEvent {
  ApiStreamStatus(this.message);
  final String message;
}

class ApiStreamPassage extends ApiStreamEvent {
  ApiStreamPassage(this.citation);
  final Citation citation;
}

class ApiStreamChunk extends ApiStreamEvent {
  ApiStreamChunk(this.text, {this.phase = 'answer'});
  final String text;
  final String phase; // "preamble" | "answer" | "unknown" (when field is absent)
}

class ApiStreamDone extends ApiStreamEvent {
  ApiStreamDone({required this.answer, required this.citations, required this.context});
  final String answer;
  final List<Citation> citations;
  final List<dynamic> context;
}

class ApiStreamError extends ApiStreamEvent {
  ApiStreamError(this.message);
  final String message;
}

class DivineApi {
  DivineApi._();
  static final DivineApi instance = DivineApi._();

  // TODO(backend): switch to https once your backend buddy enables TLS on the ALB
  static const _baseUrl = 'http://divince-chat-ai-alb-1631994646.us-east-1.elb.amazonaws.com';

  http.Client _client = http.Client();

  String? _cachedToken;
  DateTime? _tokenExpiry;

  void clearCache() {
    _cachedToken = null;
    _tokenExpiry = null;
  }

  Future<Map<String, String>> _headers() async {
    final now = DateTime.now();
    if (_cachedToken == null || _tokenExpiry == null || now.isAfter(_tokenExpiry!)) {
      _cachedToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      _tokenExpiry = now.add(const Duration(minutes: 55));
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
      if (_cachedToken != null) 'Authorization': 'Bearer $_cachedToken',
    };
  }

  void cancelCurrentRequest() {
    _client.close();
    _client = http.Client();
  }

  Stream<ApiStreamEvent> chatStream({
    required String question,
    required String religion,
    required List<dynamic> context,
    List<String> books = const [],
  }) async* {
    final request = http.Request('POST', Uri.parse('$_baseUrl/chat/stream'));
    final headers = await _headers();
    request.headers.addAll(headers);
    request.body = jsonEncode({
      'question': question,
      'religion': religion,
      'context': context,
      'books': books,
    });

    final http.StreamedResponse sseResponse;
    try {
      sseResponse = await _client.send(request).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timed out. Please try again.'),
      );
    } catch (e) {
      throw Exception('Network error: $e');
    }

    if (sseResponse.statusCode != 200) {
      final body = await sseResponse.stream.bytesToString();
      final detail = _tryParseDetail(body);
      throw Exception(detail ?? 'HTTP ${sseResponse.statusCode}: ${sseResponse.reasonPhrase}');
    }

    final buffer = StringBuffer();
    await for (final chunk in sseResponse.stream.transform(utf8.decoder)) {
      buffer.write(chunk);
      final raw = buffer.toString();

      int start = 0;
      while (true) {
        final end = raw.indexOf('\n\n', start);
        if (end == -1) break;
        final segment = raw.substring(start, end).trim();
        start = end + 2;
        if (!segment.startsWith('data: ')) continue;
        final jsonStr = segment.substring(6).trim();
        if (jsonStr.isEmpty) continue;
        try {
          final j = jsonDecode(jsonStr) as Map<String, dynamic>;
          final event = _parseEvent(j);
          if (event != null) yield event;
        } catch (_) {}
      }

      buffer.clear();
      if (start < raw.length) buffer.write(raw.substring(start));
    }
  }

  ApiStreamEvent? _parseEvent(Map<String, dynamic> j) {
    final type = j['type'] as String?;
    switch (type) {
      case 'status':
        return ApiStreamStatus(j['message'] as String? ?? '');
      case 'passage':
        return ApiStreamPassage(_citationFromPassage(j));
      case 'text_delta':
        final text = j['text'] as String? ?? '';
        final phase = j['phase'] as String? ?? 'unknown';
        return text.isNotEmpty ? ApiStreamChunk(text, phase: phase) : null;
      case 'done':
        final raw = j['answer'] as String? ?? '';
        final answer = raw.replaceAll(RegExp(r'<answer>|</answer>'), '').trim();
        final passages = (j['passages'] as List? ?? [])
            .map((p) => _citationFromPassage(p as Map<String, dynamic>))
            .toList();
        return ApiStreamDone(
          answer: answer,
          citations: passages,
          context: (j['context'] as List?) ?? [],
        );
      case 'error':
        return ApiStreamError(j['message'] as String? ?? 'Unknown error');
      default:
        return null;
    }
  }

  Citation _citationFromPassage(Map<String, dynamic> m) => Citation(
        reference: (m['source_label'] as String?) ?? '',
        originalText: (m['original_script'] as String?) ?? '',
        translation: (m['translation_en'] as String?) ?? '',
        isRtl: (m['script_dir'] as String?) == 'rtl',
      );

  String? _tryParseDetail(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['detail'] as String?;
    } catch (_) {
      return null;
    }
  }
}
