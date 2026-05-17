import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class VoiceRecorder {
  final _recorder = AudioRecorder();
  String? _currentPath;
  late Stream<Amplitude> _ampBroadcast;

  // Broadcast so _ChatScreenState (silence detection) and
  // _VoiceWaveform (visualization) can both subscribe.
  Stream<Amplitude> get amplitudeStream => _ampBroadcast;

  Future<void> start() async {
    final dir = await getTemporaryDirectory();
    _currentPath =
        '${dir.path}/divine_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: _currentPath!,
    );
    _ampBroadcast = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .asBroadcastStream();
  }

  Future<String> stop() async {
    final path = await _recorder.stop();
    return path ?? _currentPath ?? '';
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
