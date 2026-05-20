import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AssemblyAiService {
  AssemblyAiService._();
  static final instance = AssemblyAiService._();

  static const _base = 'https://api.assemblyai.com/v2';

  String get _key => dotenv.env['ASSEMBLY_AI_KEY'] ?? '';

  Future<String> transcribe(String filePath, {String languageCode = 'ur'}) async {
    final uploadUrl = await _upload(filePath);
    final transcriptId = await _requestTranscript(uploadUrl, languageCode);
    return _poll(transcriptId);
  }

  Future<String> _upload(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final response = await http.post(
      Uri.parse('$_base/upload'),
      headers: {'Authorization': _key},
      body: bytes,
    );
    if (response.statusCode != 200) {
      throw Exception('Upload failed ${response.statusCode}: ${response.body}');
    }
    return (jsonDecode(response.body) as Map<String, dynamic>)['upload_url'] as String;
  }

  Future<String> _requestTranscript(String audioUrl, String languageCode) async {
    final response = await http.post(
      Uri.parse('$_base/transcript'),
      headers: {
        'Authorization': _key,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'audio_url': audioUrl,
        'language_code': languageCode,
        'speech_models': 'best',
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Transcript request failed ${response.statusCode}: ${response.body}');
    }
    return (jsonDecode(response.body) as Map<String, dynamic>)['id'] as String;
  }

  Future<String> _poll(String transcriptId) async {
    for (var i = 0; i < 30; i++) {
      await Future.delayed(const Duration(seconds: 1));
      final response = await http.get(
        Uri.parse('$_base/transcript/$transcriptId'),
        headers: {'Authorization': _key},
      );
      if (response.statusCode != 200) {
        throw Exception('Poll failed ${response.statusCode}');
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final status = json['status'] as String;
      if (status == 'completed') return (json['text'] as String?) ?? '';
      if (status == 'error') throw Exception('Transcription error: ${json['error']}');
    }
    throw Exception('Transcription timed out after 30 seconds');
  }
}
