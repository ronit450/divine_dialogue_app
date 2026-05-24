# Voice Input Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add mic button to chat input; user speaks Urdu/Hindi; AssemblyAI transcribes; text auto-sends to existing chat backend.

**Architecture:** `_ChatScreenState` owns voice lifecycle (`VoiceState`, `VoiceRecorder`, `_ampSub`). `_InputBar` is display-only, receives state + callbacks. `AssemblyAiService` is a singleton REST client. No backend changes.

**Tech Stack:** Flutter, `record` (audio capture), `permission_handler` (mic permission), `path_provider` (temp file path), `http` (already present), AssemblyAI v2 REST API.

---

## File Map

| Action | File | Responsibility |
|---|---|---|
| Create | `lib/services/assembly_ai_service.dart` | Upload audio → request transcript → poll → return text |
| Create | `lib/features/chat/voice/voice_recorder.dart` | Wrap `record` package; expose `start()`, `stop()`, `amplitudeStream` |
| Modify | `lib/features/chat/chat_screen.dart` | `VoiceState` enum; `_ChatScreenState` voice fields/methods; `_InputBar` voice UI; `_VoiceWaveform` + `_WaveformPainter` |
| Modify | `pubspec.yaml` | Add `record`, `permission_handler`, `path_provider` |
| Modify | `android/app/src/main/AndroidManifest.xml` | Add `RECORD_AUDIO` permission |
| Modify | `ios/Runner/Info.plist` | Add `NSMicrophoneUsageDescription` |
| Modify | `.env` | Add `ASSEMBLY_AI_KEY` placeholder |
| Create | `docs/backend-voice-note.md` | Backend handoff note (no changes required) |

---

## Task 1: Packages, Permissions, Env

**Files:**
- Modify: `pubspec.yaml`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/Info.plist`
- Modify: `.env`

- [ ] **Step 1: Add packages to pubspec.yaml**

In `pubspec.yaml`, add under `dependencies:` (after `share_plus`):

```yaml
  record: ^5.2.0
  permission_handler: ^11.3.1
  path_provider: ^2.1.5
```

- [ ] **Step 2: Add RECORD_AUDIO to AndroidManifest**

In `android/app/src/main/AndroidManifest.xml`, add after the existing `<uses-permission android:name="android.permission.WAKE_LOCK"/>` line:

```xml
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

- [ ] **Step 3: Add mic usage description to iOS Info.plist**

In `ios/Runner/Info.plist`, add inside the top-level `<dict>` (after the `<key>CADisableMinimumFrameDurationOnPhone</key>` block):

```xml
	<key>NSMicrophoneUsageDescription</key>
	<string>Divine Dialogue needs microphone access to accept voice questions.</string>
```

- [ ] **Step 4: Add env key placeholder**

In `.env`, add:

```
ASSEMBLY_AI_KEY=your_assemblyai_api_key_here
```

User must replace `your_assemblyai_api_key_here` with their actual AssemblyAI key.

- [ ] **Step 5: Fetch packages**

```bash
flutter pub get
```

Expected: resolves without errors. If `record` shows a version conflict, try `record: ^5.1.0`.

- [ ] **Step 6: Verify analyze clean**

```bash
dart analyze lib/
```

Expected: `No issues found!` (or only pre-existing warnings, no new errors).

- [ ] **Step 7: Commit**

```bash
git add pubspec.yaml pubspec.lock android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist .env
git commit -m "feat: add record, permission_handler, path_provider packages"
```

---

## Task 2: AssemblyAiService

**Files:**
- Create: `lib/services/assembly_ai_service.dart`

- [ ] **Step 1: Create the service file**

Create `lib/services/assembly_ai_service.dart`:

```dart
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
        'speech_model': 'best',
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
```

- [ ] **Step 2: Verify analyze clean**

```bash
dart analyze lib/services/assembly_ai_service.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/services/assembly_ai_service.dart
git commit -m "feat: add AssemblyAiService for STT transcription"
```

---

## Task 3: VoiceRecorder

**Files:**
- Create: `lib/features/chat/voice/voice_recorder.dart`

- [ ] **Step 1: Create recorder file**

Create `lib/features/chat/voice/voice_recorder.dart`:

```dart
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
```

- [ ] **Step 2: Verify analyze clean**

```bash
dart analyze lib/features/chat/voice/voice_recorder.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/chat/voice/voice_recorder.dart
git commit -m "feat: add VoiceRecorder wrapping record package"
```

---

## Task 4: VoiceState Enum + _ChatScreenState Voice Methods

**Files:**
- Modify: `lib/features/chat/chat_screen.dart`

- [ ] **Step 1: Add imports to chat_screen.dart**

At the top of `lib/features/chat/chat_screen.dart`, add after the existing imports:

```dart
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../../services/assembly_ai_service.dart';
import 'voice/voice_recorder.dart';
```

- [ ] **Step 2: Add VoiceState enum**

After the last import line, before `class ChatScreen extends ConsumerStatefulWidget`, add:

```dart
enum VoiceState { idle, recording, silenceError, processing }
```

- [ ] **Step 3: Add voice fields to _ChatScreenState**

Inside `_ChatScreenState`, after `final _scrollCtrl = ScrollController();`, add:

```dart
  VoiceState _voiceState = VoiceState.idle;
  final _voiceRecorder = VoiceRecorder();
  StreamSubscription<Amplitude>? _ampSub;
  DateTime? _recordingStart;
  DateTime? _lastSoundTime;
```

- [ ] **Step 4: Replace dispose()**

Replace the existing `dispose()` method with:

```dart
  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    _ampSub?.cancel();
    _voiceRecorder.dispose();
    super.dispose();
  }
```

- [ ] **Step 5: Replace _send()**

Replace the existing `void _send()` method with:

```dart
  Future<void> _send() async {
    if (_voiceState == VoiceState.recording ||
        _voiceState == VoiceState.silenceError) {
      await _stopAndTranscribe();
      return;
    }
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    ref.read(chatProvider.notifier).sendMessage(text);
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }
```

- [ ] **Step 6: Add voice methods after _send()**

After `_send()`, add:

```dart
  static String _languageCode(String? religionId) {
    switch (religionId) {
      case 'islam':
        return 'ur';
      case 'hinduism':
        return 'hi';
      default:
        return 'ur';
    }
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (!mounted) return;
      _showMicPermissionDialog();
      return;
    }
    await _voiceRecorder.start();
    _recordingStart = DateTime.now();
    _lastSoundTime = DateTime.now();
    if (!mounted) return;
    setState(() => _voiceState = VoiceState.recording);
    _ampSub = _voiceRecorder.amplitudeStream.listen(_onAmplitude);
  }

  void _onAmplitude(Amplitude amp) {
    if (!mounted) return;
    final isSpeaking = amp.current > -40;
    if (isSpeaking) {
      _lastSoundTime = DateTime.now();
      if (_voiceState == VoiceState.silenceError) {
        setState(() => _voiceState = VoiceState.recording);
      }
    } else {
      final silence =
          DateTime.now().difference(_lastSoundTime ?? DateTime.now());
      if (silence.inSeconds >= 10 && _voiceState == VoiceState.recording) {
        setState(() => _voiceState = VoiceState.silenceError);
      }
    }
  }

  Future<void> _cancelVoice() async {
    _ampSub?.cancel();
    await _voiceRecorder.stop();
    if (mounted) setState(() => _voiceState = VoiceState.idle);
  }

  Future<void> _stopAndTranscribe() async {
    _ampSub?.cancel();
    setState(() => _voiceState = VoiceState.processing);
    try {
      final path = await _voiceRecorder.stop();
      final religionId = ref.read(religionProvider).selectedReligion?.id;
      final lang = _languageCode(religionId);
      final text = await AssemblyAiService.instance
          .transcribe(path, languageCode: lang);
      if (!mounted) return;
      setState(() => _voiceState = VoiceState.idle);
      if (text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Couldn't hear clearly, please try again",
              style: GoogleFonts.inter(fontSize: 13)),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }
      ref.read(chatProvider.notifier).sendMessage(text);
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      if (!mounted) return;
      setState(() => _voiceState = VoiceState.idle);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', ''),
            style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _showMicPermissionDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Microphone Access',
          style: GoogleFonts.cormorantGaramond(
              color: fg, fontSize: 20, fontWeight: FontWeight.w500),
        ),
        content: Text(
          'Divine Dialogue needs microphone access to accept voice questions.',
          style: GoogleFonts.inter(color: fg, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(fontSize: 14)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('Open Settings',
                style: GoogleFonts.inter(fontSize: 14)),
          ),
        ],
      ),
    );
  }
```

- [ ] **Step 7: Update _InputBar call in build()**

In `_ChatScreenState.build()`, replace the `_InputBar(...)` call with:

```dart
          _InputBar(
            controller: _controller,
            accent: accent,
            onSend: () => _send(),
            isDark: isDark,
            fg: fg,
            muted: muted,
            line: line,
            bg: bg,
            voiceState: _voiceState,
            onMicTap: _startRecording,
            onVoiceCancel: _cancelVoice,
            amplitudeStream: _voiceState != VoiceState.idle
                ? _voiceRecorder.amplitudeStream
                : null,
            recordingStart: _recordingStart,
            isAiActive: chatState.isTyping || chatState.isStreaming,
          ),
```

- [ ] **Step 8: Verify analyze**

```bash
dart analyze lib/features/chat/chat_screen.dart
```

Expected: errors about `_InputBar` missing params are fine (fixed in Task 6). No other new errors.

- [ ] **Step 9: Commit**

```bash
git add lib/features/chat/chat_screen.dart
git commit -m "feat: VoiceState enum and voice methods in ChatScreenState"
```

---

## Task 5: _VoiceWaveform Widget

**Files:**
- Modify: `lib/features/chat/chat_screen.dart`

Append `_VoiceWaveform` and `_WaveformPainter` at the bottom of `chat_screen.dart` (after the last existing class).

- [ ] **Step 1: Append waveform classes**

Add to the end of `lib/features/chat/chat_screen.dart`:

```dart
class _VoiceWaveform extends StatefulWidget {
  const _VoiceWaveform({
    required this.amplitudeStream,
    required this.accent,
    required this.recordingStart,
    required this.isSilenceError,
    required this.onCancel,
  });

  final Stream<Amplitude> amplitudeStream;
  final Color accent;
  final DateTime recordingStart;
  final bool isSilenceError;
  final VoidCallback onCancel;

  @override
  State<_VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<_VoiceWaveform>
    with SingleTickerProviderStateMixin {
  static const _barCount = 35;
  final _bars = List<double>.filled(_barCount, 0.05, growable: true);
  StreamSubscription<Amplitude>? _sub;
  StreamSubscription<int>? _timerSub;
  late AnimationController _animCtrl;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    )..addListener(() => setState(() {}));
    _sub = widget.amplitudeStream.listen(_onAmp);
    _timerSub = Stream.periodic(const Duration(seconds: 1), (i) => i + 1)
        .listen((s) {
      if (mounted) setState(() => _seconds = s);
    });
  }

  @override
  void didUpdateWidget(_VoiceWaveform old) {
    super.didUpdateWidget(old);
    if (old.amplitudeStream != widget.amplitudeStream) {
      _sub?.cancel();
      _sub = widget.amplitudeStream.listen(_onAmp);
    }
  }

  void _onAmp(Amplitude amp) {
    // Map dBFS (-60..0) → normalised height (0.05..1.0).
    final normalized = ((amp.current + 60) / 60).clamp(0.05, 1.0);
    _bars.removeAt(0);
    _bars.add(normalized);
    _animCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _timerSub?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  String get _timerLabel {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final barColor =
        widget.isSilenceError ? Colors.orange.shade600 : widget.accent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: barColor),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.isSilenceError
                      ? 'NO SPEECH DETECTED — SPEAK NOW'
                      : 'LISTENING  ·  $_timerLabel',
                  style: GoogleFonts.jetBrainsMono(
                    color: barColor,
                    fontSize: 9,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: widget.onCancel,
                child: Icon(Icons.close_rounded,
                    size: 16,
                    color: barColor.withValues(alpha: 0.6)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 28,
            width: double.infinity,
            child: CustomPaint(
              painter: _WaveformPainter(
                bars: List<double>.from(_bars),
                color: barColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({required this.bars, required this.color});

  final List<double> bars;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const barW = 2.0;
    const gap = 2.5;
    final totalW = bars.length * (barW + gap) - gap;
    var x = (size.width - totalW) / 2;

    for (final h in bars) {
      final barH = (h * size.height).clamp(2.0, size.height);
      final top = (size.height - barH) / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, top, barW, barH),
          const Radius.circular(1),
        ),
        paint,
      );
      x += barW + gap;
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.bars != bars || old.color != color;
}
```

- [ ] **Step 2: Verify analyze clean**

```bash
dart analyze lib/features/chat/chat_screen.dart
```

Expected: `No issues found!` (except `_InputBar` missing params until Task 6).

- [ ] **Step 3: Commit**

```bash
git add lib/features/chat/chat_screen.dart
git commit -m "feat: VoiceWaveform widget with CustomPainter amplitude bars"
```

---

## Task 6: _InputBar Voice UI

**Files:**
- Modify: `lib/features/chat/chat_screen.dart`

Replace `_InputBar` (both the `StatefulWidget` class and `_InputBarState`) with the voice-aware version.

- [ ] **Step 1: Replace _InputBar StatefulWidget declaration**

Find and replace the `class _InputBar extends StatefulWidget { ... }` block (the widget class only, not the state) with:

```dart
class _InputBar extends StatefulWidget {
  const _InputBar({
    required this.controller,
    required this.accent,
    required this.onSend,
    required this.isDark,
    required this.fg,
    required this.muted,
    required this.line,
    required this.bg,
    required this.voiceState,
    required this.onMicTap,
    required this.onVoiceCancel,
    required this.isAiActive,
    this.amplitudeStream,
    this.recordingStart,
  });

  final TextEditingController controller;
  final Color accent;
  final VoidCallback onSend;
  final bool isDark;
  final Color fg;
  final Color muted;
  final Color line;
  final Color bg;
  final VoiceState voiceState;
  final VoidCallback onMicTap;
  final VoidCallback onVoiceCancel;
  final bool isAiActive;
  final Stream<Amplitude>? amplitudeStream;
  final DateTime? recordingStart;

  @override
  State<_InputBar> createState() => _InputBarState();
}
```

- [ ] **Step 2: Replace _InputBarState entirely**

Replace the entire `class _InputBarState extends State<_InputBar> { ... }` block with:

```dart
class _InputBarState extends State<_InputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  Widget _buildTextField(Color fieldBg) {
    return Container(
      key: const ValueKey('text-field'),
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: widget.line),
      ),
      child: TextField(
        controller: widget.controller,
        style: GoogleFonts.inter(color: widget.fg, fontSize: 14),
        maxLines: 4,
        minLines: 1,
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => widget.onSend(),
        decoration: InputDecoration(
          hintText: 'Ask about the text…',
          hintStyle: GoogleFonts.inter(color: widget.muted, fontSize: 14),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildVoiceArea(Color fieldBg) {
    return Container(
      key: const ValueKey('voice-area'),
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: widget.line),
      ),
      child: widget.voiceState == VoiceState.processing
          ? Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: widget.muted),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Transcribing…',
                    style: GoogleFonts.inter(
                        color: widget.muted,
                        fontSize: 14,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            )
          : _VoiceWaveform(
              amplitudeStream: widget.amplitudeStream!,
              accent: widget.accent,
              recordingStart: widget.recordingStart!,
              isSilenceError: widget.voiceState == VoiceState.silenceError,
              onCancel: widget.onVoiceCancel,
            ),
    );
  }

  Widget _buildRightButton() {
    switch (widget.voiceState) {
      case VoiceState.processing:
        return Container(
          key: const ValueKey('processing'),
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: widget.line)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: CircularProgressIndicator(
                strokeWidth: 2, color: widget.accent),
          ),
        );
      case VoiceState.recording:
      case VoiceState.silenceError:
        return GestureDetector(
          key: const ValueKey('voice-send'),
          onTap: widget.onSend,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.accent,
              boxShadow: [
                BoxShadow(
                    color: widget.accent.withValues(alpha: 0.3),
                    blurRadius: 10),
              ],
            ),
            child: const Icon(Icons.arrow_upward_rounded,
                color: Colors.white, size: 20),
          ),
        );
      case VoiceState.idle:
        if (_hasText) {
          return GestureDetector(
            key: const ValueKey('send'),
            onTap: widget.onSend,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.accent,
                boxShadow: [
                  BoxShadow(
                      color: widget.accent.withValues(alpha: 0.3),
                      blurRadius: 10),
                ],
              ),
              child: const Icon(Icons.arrow_upward_rounded,
                  color: Colors.white, size: 20),
            ),
          );
        }
        return GestureDetector(
          key: const ValueKey('mic'),
          onTap: widget.isAiActive ? null : widget.onMicTap,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.isAiActive
                    ? widget.line.withValues(alpha: 0.4)
                    : widget.line,
              ),
            ),
            child: Icon(
              Icons.mic_none_rounded,
              color: widget.isAiActive
                  ? widget.muted.withValues(alpha: 0.4)
                  : widget.muted,
              size: 18,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final fieldBg = widget.isDark ? AppColors.nightSurface : Colors.white;
    final isVoiceMode = widget.voiceState != VoiceState.idle;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottomPad),
      decoration: BoxDecoration(
        color: widget.bg,
        border: Border(top: BorderSide(color: widget.line, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isVoiceMode
                  ? _buildVoiceArea(fieldBg)
                  : _buildTextField(fieldBg),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: _buildRightButton(),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Full project analyze — must be clean**

```bash
dart analyze lib/
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/chat/chat_screen.dart
git commit -m "feat: voice UI in InputBar — waveform, silence error, processing states"
```

---

## Task 7: Backend Handoff Note

**Files:**
- Create: `docs/backend-voice-note.md`

- [ ] **Step 1: Create the file**

Create `docs/backend-voice-note.md`:

```markdown
# Voice Input — Backend Note

## Summary

No backend changes required for the voice input feature.

## How It Works

1. User speaks → Flutter records audio locally on device
2. Flutter uploads audio to AssemblyAI → receives transcribed text
3. Transcribed text is sent to the existing chat endpoint — identical payload to typed text

## Request Contract (unchanged)

Voice transcriptions arrive at the backend as normal chat messages.
No new fields, no new endpoints, no contract changes needed.

## Optional Future Enhancement

To track voice-originated messages for analytics, add:

    { "question": "...", "source": "voice" }

The frontend can add this field at any time. The backend can safely ignore unknown
JSON fields, so no coordination is needed until the backend wants to consume it.
```

- [ ] **Step 2: Commit**

```bash
git add docs/backend-voice-note.md
git commit -m "docs: backend handoff note — no changes required for voice input"
```

---

## Task 8: Manual Smoke Test

Feature requires physical mic. Test on a real Android or iOS device.

- [ ] **Step 1: Add real API key to .env**

Replace `your_assemblyai_api_key_here` in `.env` with the actual AssemblyAI key.

- [ ] **Step 2: Run on device**

```bash
flutter run
```

- [ ] **Step 3: Idle state**

Navigate to chat. Verify mic icon (`mic_none_rounded`) appears instead of the old sparkle icon when text field is empty. Verify it grays out while AI is responding.

- [ ] **Step 4: Permission flow**

Tap mic on first run. Verify OS permission dialog appears. Deny → verify AlertDialog with "Open Settings" appears. Grant → recording should start.

- [ ] **Step 5: Recording state**

Tap mic. Verify:
- Input area transforms to waveform view (same rounded border)
- `● LISTENING · 0:00` label in accent color, timer increments each second
- Waveform bars animate when speaking into mic
- Send button (↑ accent) appears on right
- ✕ inside waveform area cancels

- [ ] **Step 6: Silence error**

Tap mic, stay silent for 10 seconds. Verify:
- Bars flatten + turn orange
- Label: `NO SPEECH DETECTED — SPEAK NOW`
- Speaking again auto-recovers to `LISTENING` state

- [ ] **Step 7: Cancel**

While recording, tap ✕. Verify returns to idle (text field + mic). No crash or stuck state.

- [ ] **Step 8: Transcribe and send**

Tap mic, speak a question in Urdu or Hindi, tap ↑. Verify:
- Input area shows `Transcribing…` with spinner (~5–10 seconds)
- User bubble appears with transcribed text in Urdu/Hindi script
- AI responds normally

- [ ] **Step 9: Final commit**

```bash
git add .
git commit -m "feat: voice input complete — AssemblyAI STT in chat screen"
```
