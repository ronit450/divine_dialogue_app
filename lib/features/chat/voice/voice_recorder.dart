import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class VoiceRecorder {
  final _recorder = AudioRecorder();
  String? _currentPath;
  // Persistent broadcast controller — same stream across multiple recordings.
  // Avoids "already listened to" from asBroadcastStream() being recreated each start().
  final _ampController = StreamController<Amplitude>.broadcast();
  StreamSubscription<Amplitude>? _recorderSub;

  Stream<Amplitude> get amplitudeStream => _ampController.stream;

  Future<void> start() async {
    final dir = await getTemporaryDirectory();
    _currentPath =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: _currentPath!,
    );
    await _recorderSub?.cancel();
    _recorderSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((amp) => _ampController.add(amp));
  }

  Future<String> stop() async {
    await _recorderSub?.cancel();
    _recorderSub = null;
    final path = await _recorder.stop();
    return path ?? _currentPath ?? '';
  }

  Future<void> dispose() async {
    await _recorderSub?.cancel();
    await _ampController.close();
    await _recorder.dispose();
  }
}
