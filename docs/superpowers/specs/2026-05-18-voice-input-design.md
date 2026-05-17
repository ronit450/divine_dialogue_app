# Voice Input Feature — Design Spec
Date: 2026-05-18

## Overview

Add voice input to the chat screen. User taps mic, speaks in Urdu or Hindi, taps send.
AssemblyAI transcribes audio to text. Text auto-sends to existing chat backend. No backend changes required.

---

## Architecture

### New Files

| File | Purpose |
|---|---|
| `lib/services/assembly_ai_service.dart` | AssemblyAI REST client (upload → transcript → poll) |
| `lib/features/chat/voice/voice_recorder.dart` | `record` package wrapper + amplitude stream |

### Modified Files

| File | Change |
|---|---|
| `lib/features/chat/chat_screen.dart` | `VoiceState` enum, `_ChatScreenState` voice methods, `_InputBar` voice UI |
| `pubspec.yaml` | Add `record`, `permission_handler`, `path_provider` |
| `android/app/src/main/AndroidManifest.xml` | `RECORD_AUDIO` permission |
| `ios/Runner/Info.plist` | `NSMicrophoneUsageDescription` |
| `.env` | User adds `ASSEMBLY_AI_KEY=<key>` |

### Ownership Model

```
_ChatScreenState
  ├── VoiceRecorder _voiceRecorder
  ├── VoiceState _voiceState
  ├── _startRecording()       — permission → start → listen amplitude
  ├── _stopAndTranscribe()    — stop → AssemblyAiService → sendMessage()
  └── _cancelVoice()          — stop → idle

VoiceRecorder
  ├── start(path)             — 16kHz mono AAC via record package
  ├── stop() → String         — returns file path
  └── amplitudeStream         — Stream<Amplitude> every 100ms

AssemblyAiService (singleton)
  └── transcribe(path, languageCode) → String
        ├── POST /v2/upload (raw bytes) → upload_url
        ├── POST /v2/transcript {audio_url, language_code, speech_model:"best"} → id
        └── poll GET /v2/transcript/{id} every 1s, timeout 30s

_InputBar (display only)
  — receives voiceState, onMicTap, onVoiceCancel
  — contains _VoiceWaveform (CustomPainter + amplitude history)
  — no business logic
```

---

## Voice State Machine

```
idle ──[mic tap]──────────────────► recording
recording ──[10s silence]──────────► silenceError
recording ──[amplitude detected]───► recording (stays)
silenceError ──[amplitude]─────────► recording (auto-recover)
silenceError ──[✕]─────────────────► idle
recording ──[✕]────────────────────► idle
recording ──[↑ send]───────────────► processing
silenceError ──[↑ send]────────────► processing
processing ──[done]────────────────► idle
```

---

## UI States

### Idle
```
[ Ask about the text…                        ]  [ 🎤 ghost ]
```
Mic button replaces the `auto_awesome_outlined` ghost icon (same 42×42 circle, border style).
Mic button disabled while `chatState.isStreaming || chatState.isTyping`.

### Recording
```
[ ● LISTENING · 0:18                   [✕]  ]  [ ↑ accent ]
[ ▁▂▄█▆▃▅▇▅▂▄█▃▁▆▄▂▁▅▇▆▃▄▂▁▅▃▁▄▆▇▅▃▂▁     ]
```
- Text field container replaced by waveform widget (same rounded border, same bg)
- `● LISTENING` in accent color (JetBrainsMono, caps, 10sp, letterSpacing 1.5)
- Timer `· 0:18` ticks via `Stream.periodic(1s)` from recording start
- Waveform: 35 thin vertical bars (2px wide, 3px gap) in accent color
  - `CustomPainter` draws bars from amplitude history ring buffer (last 35 samples)
  - Each new amplitude reading (100ms) appends to buffer, shifts left
  - dBFS → height: `((amp + 60) / 60).clamp(0.05, 1.0) * maxBarHeight`
  - Smooth transition via `AnimationController` lerp between frames
- ✕ cancel button inside container (right side, muted color)
- Send button (accent) always shown on right

### Silence Error (10s no audio)
```
[ ⚠  No speech detected — speak now   [✕]  ]  [ 🎤 red ]
[ ▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁    ]
```
- Bars flatten to minimum height, color shifts to `Colors.orange.shade600`
- Warning text replaces LISTENING label
- Mic button on right turns warning orange (send still available)
- Auto-recovers to recording state when amplitude detected again

### Processing (STT in flight)
```
[ ○  Transcribing…                          ]  [ ⟳ ]
```
- Muted italic text, small `CircularProgressIndicator` (16px) inside container
- Right button: disabled spinner
- No interaction possible

---

## Data Flow

```
mic tap
  → permission denied: AlertDialog + Settings button
  → permission granted:
      VoiceRecorder.start(tempPath) [16kHz, mono, AAC]
      _voiceState = recording
      amplitudeStream.listen():
        amp > -40dBFS  → push to waveform buffer, reset silenceTimer
        silence ≥ 10s  → _voiceState = silenceError, flatten bars
        amp detected   → _voiceState = recording (recover)

✕ tap
  → VoiceRecorder.stop() (discard file)
  → _voiceState = idle

↑ send tap (recording or silenceError)
  → VoiceRecorder.stop() → filePath
  → _voiceState = processing
  → AssemblyAiService.transcribe(filePath, lang):
      POST /v2/upload bytes → upload_url
      POST /v2/transcript {audio_url, language_code, speech_model:"best"} → id
      poll every 1s (max 30s):
        completed → text
        error/timeout → throw
  → _voiceState = idle
  → chatProvider.sendMessage(text)   ← identical to typed message path
  → _scrollToBottom()

Language mapping:
  islam    → "ur"
  hinduism → "hi"
  *        → "ur"
```

---

## Error Handling

| Scenario | Response |
|---|---|
| Mic permission denied | `AlertDialog` — explanation + "Open Settings" button |
| 10s silence | Inline: bars flatten, warning color, "No speech detected — speak now" |
| Audio resumes after silence | Auto-recover to recording (no user action needed) |
| Empty transcription returned | Snackbar "Couldn't hear clearly, please try again" → idle |
| AssemblyAI 401 | Snackbar "Voice service config error" → idle |
| AssemblyAI 5xx / network | Snackbar "Voice transcription failed, try again" → idle |
| Poll timeout (30s) | Snackbar "Transcription timed out" → idle |
| 0-byte audio file | Treated as empty transcription → snackbar → idle |
| Mic tapped while AI streaming | Mic button disabled (grayed out) |

---

## AssemblyAI Service Detail

```
POST https://api.assemblyai.com/v2/upload
  Headers: Authorization: {ASSEMBLY_AI_KEY}
  Body: raw audio bytes
  Response: { upload_url: String }

POST https://api.assemblyai.com/v2/transcript
  Headers: Authorization: {ASSEMBLY_AI_KEY}, Content-Type: application/json
  Body: { audio_url, language_code, speech_model: "best" }
  Response: { id: String, status: "queued" }

GET https://api.assemblyai.com/v2/transcript/{id}
  Headers: Authorization: {ASSEMBLY_AI_KEY}
  Poll every 1s until status == "completed" or "error"
  Timeout: 30s
  Response: { status, text }
```

Key read from `.env`: `ASSEMBLY_AI_KEY`

---

## Packages to Add

```yaml
record: ^5.2.0
permission_handler: ^11.3.1
path_provider: ^2.1.5
```

---

## Android Permissions

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

## iOS Info.plist

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Divine Dialogue needs microphone access to accept voice questions.</string>
```

---

## Backend — No Changes Required

Transcribed text arrives at `chatProvider.sendMessage(text)` identically to typed text.
The `/chat/stream` endpoint receives the same payload structure.
No API contract changes needed.
