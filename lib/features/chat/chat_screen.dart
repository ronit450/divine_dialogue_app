import 'dart:async';
import 'dart:math' show sin, pi;
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../../providers/chat_provider.dart';
import '../../providers/religion_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/chat_message.dart';
import '../../services/assembly_ai_service.dart';
import 'voice/voice_recorder.dart';

enum VoiceState { idle, recording, silenceError, processing }

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _voiceRecorder = VoiceRecorder();

  VoiceState _voiceState = VoiceState.idle;
  StreamSubscription<Amplitude>? _ampSub;
  Timer? _silenceTimer;
  DateTime? _lastSoundTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _consumePending());
  }

  void _consumePending() {
    final pending = ref.read(pendingMessageProvider);
    if (pending != null) {
      ref.read(pendingMessageProvider.notifier).state = null;
      ref.read(chatProvider.notifier).sendMessage(pending);
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    _ampSub?.cancel();
    _silenceTimer?.cancel();
    _voiceRecorder.dispose();
    super.dispose();
  }

  String _languageCode() {
    final religion = ref.read(religionProvider).selectedReligion;
    if (religion == null) return 'ur';
    switch (religion.id) {
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
      if (status.isPermanentlyDenied && mounted) _showMicPermissionDialog();
      return;
    }
    try {
      await _voiceRecorder.start();
      _lastSoundTime = DateTime.now();
      _ampSub = _voiceRecorder.amplitudeStream.listen(_onAmplitude);
      _silenceTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_lastSoundTime != null &&
            DateTime.now().difference(_lastSoundTime!).inSeconds >= 10 &&
            _voiceState == VoiceState.recording) {
          setState(() => _voiceState = VoiceState.silenceError);
        }
      });
      setState(() => _voiceState = VoiceState.recording);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start recording: $e')),
        );
      }
    }
  }

  void _onAmplitude(Amplitude amp) {
    if (amp.current > -40) {
      _lastSoundTime = DateTime.now();
      if (_voiceState == VoiceState.silenceError) {
        setState(() => _voiceState = VoiceState.recording);
      }
    }
  }

  Future<void> _cancelVoice() async {
    _ampSub?.cancel();
    _ampSub = null;
    _silenceTimer?.cancel();
    _silenceTimer = null;
    setState(() => _voiceState = VoiceState.idle);
    try {
      await _voiceRecorder.stop();
    } catch (_) {}
  }

  Future<void> _stopAndTranscribe() async {
    _ampSub?.cancel();
    _ampSub = null;
    _silenceTimer?.cancel();
    _silenceTimer = null;
    setState(() => _voiceState = VoiceState.processing);
    try {
      final path = await _voiceRecorder.stop();
      final langCode = _languageCode();
      final text = await AssemblyAiService.instance
          .transcribe(path, languageCode: langCode);
      if (text.isNotEmpty && mounted) {
        ref.read(chatProvider.notifier).sendMessage(text);
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transcription failed: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _voiceState = VoiceState.idle);
    }
  }

  void _showMicPermissionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Microphone Permission'),
        content: const Text(
          'Microphone access is required for voice input. '
          'Please enable it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _startNewChat() {
    final rState = ref.read(religionProvider);
    final religion = rState.selectedReligion;
    final text = rState.selectedText;
    if (religion != null && text != null) {
      ref.read(chatProvider.notifier).startNewSession(
        religionId: religion.id,
        textId: text.id,
        textTitle: text.title,
      );
    }
  }

  void _send() {
    if (_voiceState == VoiceState.recording ||
        _voiceState == VoiceState.silenceError) {
      _stopAndTranscribe();
      return;
    }
    if (_voiceState == VoiceState.processing) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    ref.read(chatProvider.notifier).sendMessage(text);
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(pendingMessageProvider, (_, next) {
      if (next != null) _consumePending();
    });

    ref.listen<ChatState>(chatProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!, style: GoogleFonts.inter(fontSize: 13)),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      final prevCount = prev?.session?.messages.length ?? 0;
      final nextCount = next.session?.messages.length ?? 0;
      if (nextCount > prevCount || next.isStreaming || next.isTyping) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    });

    final chatState = ref.watch(chatProvider);
    final religionState = ref.watch(religionProvider);
    final religion = religionState.selectedReligion;
    final accent =
        religion != null ? ReligionColors.accent(religion.id) : AppColors.islamGreen;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.nightBg : AppColors.boneBg;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final line = isDark ? AppColors.nightLine : AppColors.boneLine;

    final messages = chatState.session?.messages ?? [];
    final isAiActive = chatState.isTyping || chatState.isStreaming;

    return Scaffold(
      backgroundColor: bg,
      appBar: _ChatAppBar(
        title: chatState.session?.title ?? 'Dialogue',
        accent: accent,
        isDark: isDark,
        fg: fg,
        line: line,
        bg: bg,
        onNewChat: _startNewChat,
        onHistory: () => context.push('/history'),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _EmptyState(
                    accent: accent,
                    religion: religion?.name,
                    fg: fg,
                    muted: muted,
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    itemCount: messages.length +
                        (chatState.isTyping || chatState.isStreaming ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == messages.length) {
                        // In-progress turn — build an ephemeral ChatMessage
                        // from streaming buffers so the agent bubble is the
                        // same widget used after `done` commits.
                        final inflight = ChatMessage(
                          id: 'streaming',
                          text: chatState.streamingText,
                          isUser: false,
                          timestamp: DateTime.now(),
                          citations: chatState.streamingPassages,
                          preamble: chatState.streamingPreamble,
                          hasToolCall: chatState.hasToolCall,
                        );
                        return _AgentBubble(
                          message: inflight,
                          isStreaming: true,
                          statusMessage: chatState.statusMessage,
                          accent: accent,
                          isDark: isDark,
                          fg: fg,
                          muted: muted,
                          line: line,
                          textId: chatState.session?.textId,
                        );
                      }
                      final m = messages[i];
                      if (m.isUser) {
                        return _UserBubble(
                          message: m,
                          accent: accent,
                        );
                      }
                      return _AgentBubble(
                        message: m,
                        isStreaming: false,
                        statusMessage: '',
                        accent: accent,
                        isDark: isDark,
                        fg: fg,
                        muted: muted,
                        line: line,
                        textId: chatState.session?.textId,
                      );
                    },
                  ),
          ),
          if (chatState.pendingVerseContext != null)
            _VerseBanner(
              verseContext: chatState.pendingVerseContext!,
              accent: accent,
              fg: fg,
              muted: muted,
              line: line,
              onDismiss: () =>
                  ref.read(chatProvider.notifier).clearPendingVerse(),
            ),
          _InputBar(
            controller: _controller,
            accent: accent,
            onSend: _send,
            isDark: isDark,
            fg: fg,
            muted: muted,
            line: line,
            bg: bg,
            voiceState: _voiceState,
            onMicTap: _startRecording,
            onVoiceCancel: _cancelVoice,
            isAiActive: isAiActive,
            amplitudeStream: (_voiceState == VoiceState.recording ||
                    _voiceState == VoiceState.silenceError)
                ? _voiceRecorder.amplitudeStream
                : null,
          ),
        ],
      ),
    );
  }
}

// ─── App Bar ────────────────────────────────────────────────────────────────

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ChatAppBar({
    required this.title,
    required this.accent,
    required this.isDark,
    required this.fg,
    required this.line,
    required this.bg,
    required this.onNewChat,
    required this.onHistory,
  });

  final String title;
  final Color accent;
  final bool isDark;
  final Color fg;
  final Color line;
  final Color bg;
  final VoidCallback onNewChat;
  final VoidCallback onHistory;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: line, width: 0.5)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => GoRouter.of(context).go('/home'),
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: line),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: fg),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.cormorantGaramond(
                color: fg,
                fontSize: 20,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(Icons.history_rounded,
                color: fg.withValues(alpha: 0.6), size: 20),
            onPressed: onHistory,
            tooltip: 'History',
          ),
          IconButton(
            icon:
                Icon(Icons.add_comment_outlined, color: accent, size: 20),
            onPressed: onNewChat,
            tooltip: 'New chat',
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.accent,
    this.religion,
    required this.fg,
    required this.muted,
  });

  final Color accent;
  final String? religion;
  final Color fg;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.1),
                border: Border.all(color: accent.withValues(alpha: 0.2)),
              ),
              child: Icon(Icons.auto_stories_rounded, color: accent, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              religion != null
                  ? 'Ask anything about $religion'
                  : 'Start a conversation',
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                color: fg,
                fontSize: 20,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore wisdom, teachings, and stories\nfrom the sacred texts.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: muted, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── User Bubble ─────────────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.message, required this.accent});

  final ChatMessage message;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(
                message.text,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Agent Bubble (unified streaming + committed) ────────────────────────────
//
// The spec calls for ONE bubble layout used for both the in-progress streaming
// turn and every committed assistant turn — preamble (italic muted), tool-call
// block (running / done), then the answer (Markdown). Passage cards render
// outside / below the bubble. Layout must not change when `done` arrives.

class _AgentBubble extends StatelessWidget {
  const _AgentBubble({
    required this.message,
    required this.isStreaming,
    required this.statusMessage,
    required this.accent,
    required this.isDark,
    required this.fg,
    required this.muted,
    required this.line,
    this.textId,
  });

  final ChatMessage message;
  final bool isStreaming;
  final String statusMessage;
  final Color accent;
  final bool isDark;
  final Color fg;
  final Color muted;
  final Color line;
  final String? textId;

  @override
  Widget build(BuildContext context) {
    final aiBg = isDark ? AppColors.nightSurface : AppColors.boneSurface;

    final hasPreamble = message.preamble.isNotEmpty;
    final hasAnswer = message.text.isNotEmpty;
    final hasToolCall = message.hasToolCall;
    final passages = message.citations;

    // Tool-call block state:
    //   running → still streaming AND answer hasn't started
    //   done    → stream finished OR answer text has begun
    final toolRunning =
        hasToolCall && isStreaming && !hasAnswer;
    final showLoadingDots =
        isStreaming && !hasPreamble && !hasToolCall && !hasAnswer;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 8, top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.12),
                  border: Border.all(
                      color: accent.withValues(alpha: 0.25), width: 0.5),
                ),
                child: Icon(Icons.auto_stories_rounded,
                    color: accent, size: 13),
              ),
              Flexible(
                flex: 1,
                fit: isStreaming ? FlexFit.tight : FlexFit.loose,
                child: Container(
                  constraints: isStreaming
                      ? null
                      : BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.78),
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  decoration: BoxDecoration(
                    color: aiBg,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(color: line, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Layer 1 — Preamble (italic, muted; persists after done)
                      if (hasPreamble) ...[
                        Text(
                          message.preamble,
                          style: GoogleFonts.inter(
                            color: muted,
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                            height: 1.55,
                          ),
                        ),
                        if (hasToolCall || hasAnswer)
                          const SizedBox(height: 10),
                      ],

                      // Layer 2 — Tool-call block (running spinner / done check)
                      if (hasToolCall) ...[
                        _ToolCallBlock(
                          isRunning: toolRunning,
                          passageCount: passages.length,
                          statusMessage: statusMessage,
                          accent: accent,
                          isDark: isDark,
                          muted: muted,
                          line: line,
                        ),
                        if (hasAnswer) const SizedBox(height: 10),
                      ],

                      // Layer 3 — Answer (Markdown; streams in; blinking cursor
                      // while streaming).
                      if (hasAnswer)
                        _AnswerBody(
                          text: message.text,
                          fg: fg,
                          accent: accent,
                          showCursor: isStreaming,
                        ),

                      // Initial loading state — visible before any preamble arrives
                      if (showLoadingDots) _ThinkingIndicator(accent: accent, muted: muted),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Passage cards — below the bubble, indented to align with the body
          if (passages.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REFERENCED PASSAGES',
                    style: GoogleFonts.jetBrainsMono(
                      color: muted,
                      fontSize: 9,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...passages.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _PassageCard(
                        citation: p,
                        accent: accent,
                        isDark: isDark,
                        fg: fg,
                        muted: muted,
                        line: line,
                        textId: textId,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Answer body — Markdown + optional blinking cursor ───────────────────────

class _AnswerBody extends StatelessWidget {
  const _AnswerBody({
    required this.text,
    required this.fg,
    required this.accent,
    required this.showCursor,
  });

  final String text;
  final Color fg;
  final Color accent;
  final bool showCursor;

  @override
  Widget build(BuildContext context) {
    final body = MarkdownBody(
      data: text,
      softLineBreak: true,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: GoogleFonts.inter(color: fg, fontSize: 14, height: 1.55),
        strong:
            GoogleFonts.inter(color: fg, fontSize: 14, fontWeight: FontWeight.w600),
        em: GoogleFonts.inter(
            color: fg, fontSize: 14, fontStyle: FontStyle.italic),
        listBullet: GoogleFonts.inter(color: fg, fontSize: 14, height: 1.5),
        blockquote: GoogleFonts.inter(
          color: fg.withValues(alpha: 0.85),
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
        code: GoogleFonts.jetBrainsMono(color: fg, fontSize: 12.5),
      ),
    );
    if (!showCursor) return body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        body,
        Row(
          children: [
            const SizedBox(height: 14),
            _BlinkingCursor(color: accent),
          ],
        ),
      ],
    );
  }
}

// ─── Tool-call block ─────────────────────────────────────────────────────────

class _ToolCallBlock extends StatelessWidget {
  const _ToolCallBlock({
    required this.isRunning,
    required this.passageCount,
    required this.statusMessage,
    required this.accent,
    required this.isDark,
    required this.muted,
    required this.line,
  });

  final bool isRunning;
  final int passageCount;
  final String statusMessage;
  final Color accent;
  final bool isDark;
  final Color muted;
  final Color line;

  @override
  Widget build(BuildContext context) {
    final doneColor = const Color(0xFF2E9D5C);
    final blockBg = (isDark ? AppColors.nightBg : AppColors.boneBg)
        .withValues(alpha: isDark ? 0.6 : 1.0);
    final borderColor = isRunning ? line : doneColor.withValues(alpha: 0.6);
    final fgColor = isRunning ? muted : doneColor;

    final label = isRunning
        ? (statusMessage.isNotEmpty ? statusMessage : 'Searching…')
        : 'Found $passageCount passage${passageCount == 1 ? '' : 's'}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: blockBg,
        border: Border.all(color: borderColor, width: 0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRunning)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(muted),
              ),
            )
          else
            Icon(Icons.check_rounded, size: 14, color: doneColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: fgColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Passage card (rendered below the bubble) ────────────────────────────────

int? _parseChapterFromReference(String reference) {
  final match = RegExp(r'(\d+)').firstMatch(reference);
  return match != null ? int.tryParse(match.group(1)!) : null;
}

class _PassageCard extends StatelessWidget {
  const _PassageCard({
    required this.citation,
    required this.accent,
    required this.isDark,
    required this.fg,
    required this.muted,
    required this.line,
    this.textId,
  });

  final Citation citation;
  final Color accent;
  final bool isDark;
  final Color fg;
  final Color muted;
  final Color line;
  final String? textId;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.nightSurface : AppColors.boneSurface;
    final hasOriginal = citation.originalText.isNotEmpty;
    final canNavigate = textId != null;

    return GestureDetector(
      onTap: canNavigate
          ? () {
              final chapter = _parseChapterFromReference(citation.reference);
              context.push(
                '/read/$textId',
                extra: chapter != null ? {'chapter': chapter} : null,
              );
            }
          : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: cardBg,
          border: Border.all(
              color: canNavigate ? accent.withValues(alpha: 0.35) : line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 12,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    citation.reference,
                    style: GoogleFonts.jetBrainsMono(
                      color: accent,
                      fontSize: 11,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (canNavigate) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 14, color: accent),
                ],
              ],
            ),
          if (hasOriginal) ...[
            const SizedBox(height: 8),
            Directionality(
              textDirection:
                  citation.isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: Text(
                citation.originalText,
                style: TextStyle(
                  color: fg,
                  fontSize: citation.isRtl ? 18 : 14,
                  height: citation.isRtl ? 2.0 : 1.6,
                  fontWeight: FontWeight.w400,
                ),
                textAlign:
                    citation.isRtl ? TextAlign.right : TextAlign.left,
              ),
            ),
          ],
          if (citation.translation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              citation.translation,
              style: GoogleFonts.inter(
                color: muted,
                fontSize: 13,
                height: 1.55,
              ),
            ),
          ],
        ],
      ),
    ),
    );
  }
}

// ─── Thinking indicator (initial pre-preamble state) ─────────────────────────
//
// Bouncing-dots pattern (like WhatsApp/iMessage "typing"), with "Thinking…"
// label. The bubble is forced full-width via FlexFit.tight when isStreaming,
// so this indicator fills the bubble rather than shrinking to dot width.

class _ThinkingIndicator extends StatefulWidget {
  const _ThinkingIndicator({required this.accent, required this.muted});
  final Color accent;
  final Color muted;

  @override
  State<_ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<_ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1050),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Three bouncing dots, staggered by 1/3 cycle each
              ...List.generate(3, (i) {
                final phase = (_ctrl.value - i / 3.0 + 1.0) % 1.0;
                // Smooth half-sine bounce: up in first 40% of cycle, rest idle
                final t = (phase / 0.4).clamp(0.0, 1.0);
                final bounce = sin(t * pi).clamp(0.0, 1.0);
                return Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 5.0 : 0),
                  child: Transform.translate(
                    offset: Offset(0, -bounce * 6),
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.accent
                            .withValues(alpha: 0.35 + bounce * 0.65),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 10),
              Text(
                'Thinking…',
                style: GoogleFonts.inter(
                  color: widget.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Verse Banner ────────────────────────────────────────────────────────────

class _VerseBanner extends StatelessWidget {
  const _VerseBanner({
    required this.verseContext,
    required this.accent,
    required this.fg,
    required this.muted,
    required this.line,
    required this.onDismiss,
  });

  final VerseContext verseContext;
  final Color accent;
  final Color fg;
  final Color muted;
  final Color line;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final preview = verseContext.translation.length > 70
        ? '${verseContext.translation.substring(0, 70)}…'
        : verseContext.translation;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.menu_book_rounded, size: 13, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  verseContext.reference.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 8,
                    color: accent,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  preview,
                  style: GoogleFonts.inter(
                      fontSize: 11, color: muted, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(Icons.close_rounded, size: 15, color: muted),
          ),
        ],
      ),
    );
  }
}

// ─── Blinking Cursor ─────────────────────────────────────────────────────────

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor({required this.color});
  final Color color;

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 2,
        height: 14,
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

// ─── Input Bar ───────────────────────────────────────────────────────────────

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

  @override
  State<_InputBar> createState() => _InputBarState();
}

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

  bool get _inVoiceMode => widget.voiceState != VoiceState.idle;
  bool get _isProcessing => widget.voiceState == VoiceState.processing;
  bool get _isSilenceError => widget.voiceState == VoiceState.silenceError;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final surface = widget.isDark ? AppColors.nightSurface : Colors.white;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottomPad),
      decoration: BoxDecoration(
        color: widget.bg,
        border: Border(top: BorderSide(color: widget.line, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: _inVoiceMode
                ? _buildRecordingPill(surface)
                : _buildTextPill(surface),
          ),
          if (_inVoiceMode && !_isProcessing) ...[
            const SizedBox(height: 8),
            _buildCaption(),
          ],
        ],
      ),
    );
  }

  Widget _buildTextPill(Color surface) {
    return AnimatedContainer(
      key: const ValueKey('text-pill'),
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: widget.line),
        boxShadow: _hasText
            ? [
                BoxShadow(
                  color: widget.accent.withValues(alpha: 0.33),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 18),
              child: TextField(
                controller: widget.controller,
                style: GoogleFonts.inter(color: widget.fg, fontSize: 15),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => widget.onSend(),
                decoration: InputDecoration(
                  hintText: 'Ask anything…',
                  hintStyle:
                      GoogleFonts.inter(color: widget.muted, fontSize: 15),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 5, 5, 5),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: _hasText
                  ? _pillButton(
                      key: const ValueKey('send'),
                      onTap: widget.onSend,
                      icon: Icons.arrow_upward_rounded,
                    )
                  : _pillButton(
                      key: const ValueKey('mic'),
                      onTap: widget.onMicTap,
                      icon: Icons.mic_rounded,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillButton({
    required Key key,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return _PressButton(
      key: key,
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.accent,
          boxShadow: [
            BoxShadow(
              color: widget.accent.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildRecordingPill(Color surface) {
    return Container(
      key: const ValueKey('recording-pill'),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _isSilenceError ? Colors.orange.shade400 : widget.line,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.accent.withValues(alpha: 0.20),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          // Trash cancel
          GestureDetector(
            onTap: _isProcessing ? null : widget.onVoiceCancel,
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.fromLTRB(8, 8, 0, 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isProcessing
                    ? widget.line.withValues(alpha: 0.5)
                    : (widget.isDark
                        ? const Color(0xFFff5a50).withValues(alpha: 0.16)
                        : const Color(0xFFfbeaea)),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                size: 16,
                color: _isProcessing
                    ? widget.muted
                    : (widget.isDark
                        ? const Color(0xFFff8a82)
                        : const Color(0xFFc0392b)),
              ),
            ),
          ),
          // Center: waveform / silence warning / spinner
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildRecordingCenter(),
            ),
          ),
          // Send
          GestureDetector(
            onTap: _isProcessing ? null : widget.onSend,
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.fromLTRB(0, 6, 6, 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isProcessing ? widget.line : widget.accent,
                boxShadow: _isProcessing
                    ? []
                    : [
                        BoxShadow(
                          color: widget.accent.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: const Icon(
                Icons.arrow_upward_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingCenter() {
    if (_isProcessing) {
      return Padding(
        key: const ValueKey('processing'),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(widget.accent),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Transcribing…',
              style: GoogleFonts.inter(color: widget.muted, fontSize: 12),
            ),
          ],
        ),
      );
    }
    if (_isSilenceError) {
      return Padding(
        key: const ValueKey('silence'),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(Icons.mic_off_rounded, size: 14, color: Colors.orange.shade400),
            const SizedBox(width: 6),
            Text(
              'Speak or tap send',
              style: GoogleFonts.inter(
                color: Colors.orange.shade400,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
    return _VoiceWaveform(
      key: const ValueKey('waveform'),
      accent: widget.accent,
      amplitudeStream: widget.amplitudeStream!,
    );
  }

  Widget _buildCaption() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.delete_outline_rounded, size: 11, color: widget.muted),
        const SizedBox(width: 4),
        Text(
          'Recording — tap trash to cancel · max 5:00',
          style: GoogleFonts.inter(
            color: widget.muted,
            fontSize: 11,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ─── Voice Waveform ──────────────────────────────────────────────────────────

class _VoiceWaveform extends StatefulWidget {
  const _VoiceWaveform({
    super.key,
    required this.accent,
    required this.amplitudeStream,
  });

  final Color accent;
  final Stream<Amplitude> amplitudeStream;

  @override
  State<_VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<_VoiceWaveform> {
  static const _barCount = 32;
  final List<double> _bars = List.filled(_barCount, 0.0);
  StreamSubscription<Amplitude>? _ampSub;
  StreamSubscription<int>? _timerSub;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _ampSub = widget.amplitudeStream.listen(_onAmplitude);
    _timerSub = Stream.periodic(const Duration(seconds: 1), (i) => i + 1)
        .listen((s) {
      if (mounted) setState(() => _seconds = s);
    });
  }

  @override
  void dispose() {
    _ampSub?.cancel();
    _timerSub?.cancel();
    super.dispose();
  }

  void _onAmplitude(Amplitude amp) {
    final normalized = ((amp.current + 60) / 60).clamp(0.0, 1.0);
    if (mounted) {
      setState(() {
        _bars.removeAt(0);
        _bars.add(normalized);
      });
    }
  }

  String get _timeLabel {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          const _PulsingDot(),
          const SizedBox(width: 8),
          Text(
            _timeLabel,
            style: GoogleFonts.jetBrainsMono(
              color: widget.accent,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CustomPaint(
              painter:
                  _WaveformPainter(bars: List.of(_bars), color: widget.accent),
              size: const Size(double.infinity, 28),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pulsing Dot ─────────────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final t = Curves.easeOut.transform(_ctrl.value);
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFd44545),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFd44545).withValues(alpha: (1 - t) * 0.55),
                blurRadius: 8 * t,
                spreadRadius: 4 * t,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PressButton extends StatefulWidget {
  const _PressButton({super.key, required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;
  @override
  State<_PressButton> createState() => _PressButtonState();
}

class _PressButtonState extends State<_PressButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110));
    _scale = Tween<double>(begin: 1.0, end: 0.86)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// ─── Waveform Painter ────────────────────────────────────────────────────────

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({required this.bars, required this.color});

  final List<double> bars;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const barW = 2.0;
    const gap = 2.5;
    const step = barW + gap;
    final minH = size.height * 0.12;
    final maxH = size.height;
    final paint = Paint()..strokeCap = StrokeCap.round;

    final totalW = bars.length * step - gap;
    var x = (size.width - totalW) / 2;

    for (final bar in bars) {
      final h = minH + bar * (maxH - minH);
      final top = (size.height - h) / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barW, h),
        const Radius.circular(1),
      );
      paint.color = color.withValues(alpha: 0.25 + bar * 0.75);
      canvas.drawRRect(rect, paint);
      x += step;
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) => true;
}
