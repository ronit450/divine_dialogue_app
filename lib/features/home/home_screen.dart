import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../../providers/religion_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/reading_plan_provider.dart';
import '../../data/reading_plan_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/chat_message.dart';
import '../../data/texts_repository.dart';
import '../../shared/widgets/religion_glyph.dart';
import '../../shared/widgets/reading_plan_setup_sheet.dart';
import '../../services/assembly_ai_service.dart';
import '../chat/voice/voice_recorder.dart';

enum VoiceState { idle, recording, silenceError, processing }

final _dailyVerseProvider = FutureProvider.autoDispose.family<DailyVerse, String>(
  (ref, religionId) => TextsRepository.instance.getDailyVerse(religionId),
);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _voiceRecorder = VoiceRecorder();
  bool _chatStarted = false;
  GoRouter? _router;
  String _lastRoute = '/home';
  VoiceState _voiceState = VoiceState.idle;
  StreamSubscription<Amplitude>? _ampSub;
  Timer? _silenceTimer;
  DateTime? _lastSoundTime;

  static String _weekday(int d) =>
      const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][d - 1];
  static String _month(int m) =>
      const ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL',
             'AUG', 'SEP', 'OCT', 'NOV', 'DEC'][m - 1];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _router = GoRouter.of(context);
      _router!.routerDelegate.addListener(_onRouteChanged);
      final chatState = ref.read(chatProvider);
      if (chatState.session?.messages.isNotEmpty == true) {
        if (mounted) setState(() => _chatStarted = true);
      }
      _consumePending();
      Future.delayed(const Duration(seconds: 2), _maybeShowReadingPopup);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router?.routerDelegate.removeListener(_onRouteChanged);
    _controller.dispose();
    _scrollCtrl.dispose();
    _ampSub?.cancel();
    _silenceTimer?.cancel();
    _voiceRecorder.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkAutoReset();
  }

  void _onRouteChanged() {
    if (!mounted) return;
    final path = _router?.routerDelegate.currentConfiguration.uri.path ?? '';
    if (path == '/home' && _lastRoute != '/home') _checkAutoReset();
    if (path.isNotEmpty) _lastRoute = path;
  }

  void _checkAutoReset() {
    final session = ref.read(chatProvider).session;
    if (session == null || session.messages.isEmpty) return;
    if (DateTime.now().difference(session.updatedAt).inSeconds >= 30) {
      _startNewChat();
    }
  }

  void _consumePending() {
    final pending = ref.read(pendingMessageProvider);
    if (pending != null) {
      ref.read(pendingMessageProvider.notifier).state = null;
      if (!_chatStarted && mounted) setState(() => _chatStarted = true);
      ref.read(chatProvider.notifier).sendMessage(pending);
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    if (!_chatStarted) setState(() => _chatStarted = true);
    ref.read(chatProvider.notifier).sendMessage(text);
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  String _languageCode() {
    final religion = ref.read(religionProvider).selectedReligion;
    if (religion == null) return 'ur';
    switch (religion.id) {
      case 'islam': return 'ur';
      case 'hinduism': return 'hi';
      default: return 'ur';
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
    try { await _voiceRecorder.stop(); } catch (_) {}
  }

  Future<void> _stopAndTranscribe() async {
    _ampSub?.cancel();
    _ampSub = null;
    _silenceTimer?.cancel();
    _silenceTimer = null;
    setState(() => _voiceState = VoiceState.processing);
    try {
      final path = await _voiceRecorder.stop();
      if (path.isEmpty) { setState(() => _voiceState = VoiceState.idle); return; }
      final text = await AssemblyAiService.instance.transcribe(path, languageCode: _languageCode());
      if (mounted && text.isNotEmpty) {
        _controller.text = text;
        if (!_chatStarted) setState(() => _chatStarted = true);
        ref.read(chatProvider.notifier).sendMessage(text);
        _controller.clear();
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transcription failed: $e')),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () { Navigator.pop(context); openAppSettings(); }, child: const Text('Settings')),
        ],
      ),
    );
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

  Future<void> _maybeShowReadingPopup() async {
    if (!mounted) return;
    final religion = ref.read(religionProvider).selectedReligion;
    if (religion == null) return;
    final plans = ref.read(readingPlanProvider).plans;
    if (plans.any((p) => p.religionId == religion.id)) return;
    final repo = ReadingPlanRepository.instance;
    final should = await repo.shouldShowPopup();
    if (!should || !mounted) return;
    await repo.recordPopupShown();
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.nightBg : AppColors.boneBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ReadingPopup(
        accent: ReligionColors.accent(religion.id),
        isDark: isDark,
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
    setState(() => _chatStarted = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(pendingMessageProvider, (_, next) {
      if (next != null) _consumePending();
    });

    final chatState = ref.watch(chatProvider);
    final religionState = ref.watch(religionProvider);
    final religion = religionState.selectedReligion;
    final accent = religion != null
        ? ReligionColors.accent(religion.id)
        : AppColors.islamGreen;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.nightBg : AppColors.boneBg;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final line = isDark ? AppColors.nightLine : AppColors.boneLine;

    final userState = ref.watch(userProvider);
    final firstName = userState.user?.firstName ?? 'Friend';
    final salutation = (religion?.salutation.isNotEmpty ?? false)
        ? religion!.salutation
        : 'Hello';

    final now = DateTime.now();
    final dateLabel =
        '${_weekday(now.weekday)} · ${now.day} ${_month(now.month)}';

    final messages = chatState.session?.messages ?? [];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (messages.isNotEmpty || chatState.isStreaming || chatState.isTyping) {
        _scrollToBottom();
      }
      if (chatState.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(chatState.error!,
                style: GoogleFonts.inter(fontSize: 13)),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: bg,
      drawer: _ChatDrawer(
        accent: accent,
        isDark: isDark,
        bg: bg,
        fg: fg,
        muted: muted,
        line: line,
        onNewChat: () {
          Navigator.of(context).pop();
          _startNewChat();
        },
        onSessionTap: (session) {
          Navigator.of(context).pop();
          ref.read(chatProvider.notifier).loadSession(session);
          setState(() => _chatStarted = true);
        },
        onViewHistory: () {
          Navigator.of(context).pop();
          context.push('/history');
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            _HomeTopBar(
              dateLabel: dateLabel,
              fg: fg,
              muted: muted,
              line: line,
              chatTitle: _chatStarted ? chatState.session?.title : null,
            ),
            if (religion != null && !_chatStarted)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: _VerseCard(
                  religionId: religion.id,
                  accent: accent,
                  isDark: isDark,
                  fg: fg,
                  muted: muted,
                ),
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: _chatStarted
                    ? _MessagesList(
                        key: const ValueKey('chat'),
                        messages: messages,
                        chatState: chatState,
                        scrollCtrl: _scrollCtrl,
                        accent: accent,
                        isDark: isDark,
                        fg: fg,
                        muted: muted,
                        line: line,
                      )
                    : _IdleContent(
                        key: const ValueKey('idle'),
                        religionId: religion?.id,
                        salutation: salutation,
                        firstName: firstName,
                        accent: accent,
                        fg: fg,
                        muted: muted,
                      ),
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
              onSend: _voiceState == VoiceState.recording || _voiceState == VoiceState.silenceError
                  ? _stopAndTranscribe
                  : _send,
              isDark: isDark,
              fg: fg,
              muted: muted,
              line: line,
              bg: bg,
              voiceState: _voiceState,
              onMicTap: _startRecording,
              onVoiceCancel: _cancelVoice,
              isAiActive: chatState.isTyping || chatState.isStreaming,
              amplitudeStream: (_voiceState == VoiceState.recording ||
                      _voiceState == VoiceState.silenceError)
                  ? _voiceRecorder.amplitudeStream
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top bar ──────────────────────────────────────────────────────────────────

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({
    required this.dateLabel,
    required this.fg,
    required this.muted,
    required this.line,
    this.chatTitle,
  });

  final String dateLabel;
  final Color fg;
  final Color muted;
  final Color line;
  final String? chatTitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: line, width: 0.8),
              ),
              child: Icon(Icons.menu_rounded, size: 16, color: fg),
            ),
          ),
          Expanded(
            child: Center(
              child: chatTitle != null
                  ? Text(
                      _toTitleCase(chatTitle!),
                      style: GoogleFonts.cormorantGaramond(
                        color: fg,
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    )
                  : Text(
                      dateLabel,
                      style: GoogleFonts.jetBrainsMono(
                        color: muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.0,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 34),
        ],
      ),
    );
  }
}

// ── Idle content ─────────────────────────────────────────────────────────────

class _IdleContent extends StatelessWidget {
  const _IdleContent({
    super.key,
    required this.religionId,
    required this.salutation,
    required this.firstName,
    required this.accent,
    required this.fg,
    required this.muted,
  });

  final String? religionId;
  final String salutation;
  final String firstName;
  final Color accent;
  final Color fg;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReligionGlyph(
              religionId: religionId ?? 'islam',
              size: 36,
              color: accent.withValues(alpha: 0.55),
            ),
            const SizedBox(height: 20),
            Text(
              '$salutation,',
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                color: fg,
                fontSize: 38,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                height: 1.1,
              ),
            ),
            Text(
              firstName,
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                color: accent,
                fontSize: 38,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'What would you like to ask today?',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: muted,
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Verse card ────────────────────────────────────────────────────────────────

class _VerseCard extends ConsumerStatefulWidget {
  const _VerseCard({
    required this.religionId,
    required this.accent,
    required this.isDark,
    required this.fg,
    required this.muted,
  });

  final String religionId;
  final Color accent;
  final bool isDark;
  final Color fg;
  final Color muted;

  @override
  ConsumerState<_VerseCard> createState() => _VerseCardState();
}

class _VerseCardState extends ConsumerState<_VerseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _glare;

  @override
  void initState() {
    super.initState();
    _glare = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _scheduleGlare(const Duration(seconds: 2));
  }

  void _scheduleGlare(Duration delay) {
    Future.delayed(delay, () {
      if (!mounted) return;
      _glare.forward(from: 0).then((_) => _scheduleGlare(const Duration(seconds: 6)));
    });
  }

  @override
  void dispose() {
    _glare.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final verse = ref.watch(_dailyVerseProvider(widget.religionId));
    final cardBg = widget.isDark
        ? widget.accent.withValues(alpha: 0.20)
        : widget.accent.withValues(alpha: 0.22);
    final v = verse.valueOrNull;

    return GestureDetector(
      onTap: v?.textId != null
          ? () => context.push(
                '/read/${v!.textId}',
                extra: v.navChapter != null ? {'chapter': v.navChapter} : null,
              )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AnimatedBuilder(
          animation: _glare,
          builder: (context, child) => Stack(
            children: [
              child!,
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-2.5 + 5 * _glare.value, -1),
                        end: Alignment(-1.5 + 5 * _glare.value, 1),
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.16),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: verse.when(
              loading: () => SizedBox(
                height: 72,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation(widget.accent),
                  ),
                ),
              ),
              error: (_, _) => Text(
                'Verse unavailable',
                style: GoogleFonts.inter(color: widget.muted, fontSize: 13),
              ),
              data: (v) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ReligionGlyph(
                          religionId: widget.religionId,
                          size: 12,
                          color: widget.accent),
                      const SizedBox(width: 6),
                      Text(
                        'VERSE OF THE DAY',
                        style: GoogleFonts.jetBrainsMono(
                          color: widget.accent,
                          fontSize: 9,
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (v.originalText != null) ...[
                    Text(
                      v.originalText!,
                      textDirection: widget.religionId == 'islam'
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      style: TextStyle(
                        color: widget.fg.withValues(alpha: 0.75),
                        fontSize: widget.religionId == 'islam' ? 16 : 14,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    '"${v.text}"',
                    style: GoogleFonts.cormorantGaramond(
                      color: widget.fg,
                      fontSize: 19,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${v.source.toUpperCase()} · ${v.ref}',
                    style: GoogleFonts.jetBrainsMono(
                      color: widget.accent,
                      fontSize: 9,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Messages list ─────────────────────────────────────────────────────────────

class _MessagesList extends StatelessWidget {
  const _MessagesList({
    super.key,
    required this.messages,
    required this.chatState,
    required this.scrollCtrl,
    required this.accent,
    required this.isDark,
    required this.fg,
    required this.muted,
    required this.line,
  });

  final List<ChatMessage> messages;
  final ChatState chatState;
  final ScrollController scrollCtrl;
  final Color accent;
  final bool isDark;
  final Color fg;
  final Color muted;
  final Color line;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty && !chatState.isTyping && !chatState.isStreaming) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.08),
                  border: Border.all(color: accent.withValues(alpha: 0.2)),
                ),
                child:
                    Icon(Icons.auto_stories_rounded, color: accent, size: 24),
              ),
              const SizedBox(height: 14),
              Text(
                'Starting a new chat…',
                style: GoogleFonts.cormorantGaramond(
                  color: fg,
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final itemCount = messages.length +
        (chatState.isTyping || chatState.isStreaming ? 1 : 0);

    return ListView.builder(
      controller: scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: itemCount,
      itemBuilder: (context, i) {
        if (i == messages.length) {
          if (chatState.isStreaming) {
            return _StreamingBubble(
              text: chatState.streamingText,
              accent: accent,
              isDark: isDark,
              fg: fg,
              line: line,
            );
          }
          return _TypingIndicator(accent: accent, isDark: isDark, line: line);
        }
        return _MessageBubble(
          message: messages[i],
          accent: accent,
          isDark: isDark,
          fg: fg,
          line: line,
        );
      },
    );
  }
}

// ── Chat drawer ───────────────────────────────────────────────────────────────

class _ChatDrawer extends ConsumerStatefulWidget {
  const _ChatDrawer({
    required this.accent,
    required this.isDark,
    required this.bg,
    required this.fg,
    required this.muted,
    required this.line,
    required this.onNewChat,
    required this.onSessionTap,
    required this.onViewHistory,
  });

  final Color accent;
  final bool isDark;
  final Color bg;
  final Color fg;
  final Color muted;
  final Color line;
  final VoidCallback onNewChat;
  final ValueChanged<ChatSession> onSessionTap;
  final VoidCallback onViewHistory;

  @override
  ConsumerState<_ChatDrawer> createState() => _ChatDrawerState();
}

class _ChatDrawerState extends ConsumerState<_ChatDrawer> {
  String _query = '';

  Map<String, List<ChatSession>> _group(List<ChatSession> sessions) {
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final groups = <String, List<ChatSession>>{
      'TODAY': [],
      'YESTERDAY': [],
      'EARLIER THIS WEEK': [],
      'OLDER': [],
    };

    for (final s in sessions) {
      final d = DateUtils.dateOnly(s.updatedAt);
      if (d == today) {
        groups['TODAY']!.add(s);
      } else if (d == yesterday) {
        groups['YESTERDAY']!.add(s);
      } else if (d.isAfter(weekAgo)) {
        groups['EARLIER THIS WEEK']!.add(s);
      } else {
        groups['OLDER']!.add(s);
      }
    }
    return groups;
  }

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final d = DateUtils.dateOnly(dt);
    if (d == today) {
      final h = dt.hour;
      final m = dt.minute.toString().padLeft(2, '0');
      final period = h >= 12 ? 'PM' : 'AM';
      final displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      return '$displayH:$m $period';
    }
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (d.isAfter(today.subtract(const Duration(days: 7)))) {
      return days[dt.weekday - 1];
    }
    return '${months[dt.month - 1]} ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyProvider);
    final sessions = _query.isEmpty
        ? historyState.sessions
        : historyState.sessions
            .where((s) =>
                s.title.toLowerCase().contains(_query.toLowerCase()))
            .toList();
    final groups = _group(sessions);
    final fieldBg = widget.isDark
        ? AppColors.nightSurface
        : widget.line.withValues(alpha: 0.10);

    return Drawer(
      width: 300,
      backgroundColor: widget.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
              child: Row(
                children: [
                  ReligionGlyph(
                    religionId: 'sikhism',
                    size: 18,
                    color: widget.fg.withValues(alpha: 0.45),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Divine Chat',
                    style: GoogleFonts.cormorantGaramond(
                      color: widget.fg,
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: widget.line, width: 0.8),
                      ),
                      child: Icon(Icons.close_rounded,
                          size: 14, color: widget.muted),
                    ),
                  ),
                ],
              ),
            ),
            // New chat button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: GestureDetector(
                onTap: widget.onNewChat,
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: widget.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'New chat',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: fieldBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    Icon(Icons.search_rounded,
                        size: 16, color: widget.muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v),
                        style: GoogleFonts.inter(
                            color: widget.fg, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search chats…',
                          hintStyle: GoogleFonts.inter(
                              color: widget.muted, fontSize: 13),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Sessions list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  for (final groupKey in groups.keys)
                    if (groups[groupKey]!.isNotEmpty) ...[
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 8, 20, 6),
                        child: Text(
                          groupKey,
                          style: GoogleFonts.jetBrainsMono(
                            color: widget.muted,
                            fontSize: 9,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      for (final session in groups[groupKey]!)
                        _SessionTile(
                          session: session,
                          timeLabel: _timeLabel(session.updatedAt),
                          fg: widget.fg,
                          muted: widget.muted,
                          line: widget.line,
                          accent: widget.accent,
                          onTap: () => widget.onSessionTap(session),
                        ),
                    ],
                  if (sessions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Text(
                        _query.isEmpty
                            ? 'No conversations yet'
                            : 'No results found',
                        style: GoogleFonts.inter(
                            color: widget.muted, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _toTitleCase(String text) => text.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : '');
    }).join(' ');

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.timeLabel,
    required this.fg,
    required this.muted,
    required this.line,
    required this.accent,
    required this.onTap,
  });

  final ChatSession session;
  final String timeLabel;
  final Color fg;
  final Color muted;
  final Color line;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        child: Row(
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 15, color: muted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _toTitleCase(session.title),
                    style: GoogleFonts.cormorantGaramond(
                      color: fg,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$timeLabel · ${session.messages.length} msg',
                    style: GoogleFonts.inter(
                      color: muted,
                      fontSize: 11,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Verse banner ──────────────────────────────────────────────────────────────

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

// ── Input bar ─────────────────────────────────────────────────────────────────

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

  bool get _inVoiceMode => widget.voiceState != VoiceState.idle;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  Widget _buildInputArea() {
    if (_inVoiceMode) {
      final stream = widget.amplitudeStream;
      if (stream == null) {
        return Container(
          key: const ValueKey('processing'),
          alignment: Alignment.center,
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(widget.accent),
            ),
          ),
        );
      }
      return _VoiceWaveform(
        key: const ValueKey('waveform'),
        accent: widget.accent,
        amplitudeStream: stream,
      );
    }
    final fieldBg = widget.isDark ? AppColors.nightSurface : Colors.white;
    return Container(
      key: const ValueKey('text-field'),
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: widget.line.withValues(alpha: 0.5)),
      ),
      child: TextField(
        controller: widget.controller,
        style: GoogleFonts.inter(color: widget.fg, fontSize: 14),
        maxLines: 4,
        minLines: 1,
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => widget.onSend(),
        cursorColor: widget.accent,
        decoration: InputDecoration(
          hintText: 'Type a msg…',
          hintStyle: GoogleFonts.inter(color: widget.muted, fontSize: 14),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildRightButton() {
    if (widget.voiceState == VoiceState.processing) {
      return const SizedBox(key: ValueKey('processing-btn'), width: 44, height: 44);
    }
    if (widget.voiceState == VoiceState.recording ||
        widget.voiceState == VoiceState.silenceError) {
      return GestureDetector(
        key: const ValueKey('voice-send'),
        onTap: widget.onSend,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.accent,
            boxShadow: [BoxShadow(color: widget.accent.withValues(alpha: 0.3), blurRadius: 10)],
          ),
          child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 22),
        ),
      );
    }
    if (_hasText) {
      return GestureDetector(
        key: const ValueKey('send'),
        onTap: widget.onSend,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.accent,
            boxShadow: [BoxShadow(color: widget.accent.withValues(alpha: 0.3), blurRadius: 10)],
          ),
          child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
        ),
      );
    }
    if (!widget.isAiActive) {
      return GestureDetector(
        key: const ValueKey('mic'),
        onTap: widget.onMicTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: widget.line),
          ),
          child: Icon(Icons.mic_rounded, color: widget.accent, size: 20),
        ),
      );
    }
    return Container(
      key: const ValueKey('idle'),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: widget.line),
      ),
      child: Icon(Icons.auto_awesome_outlined, color: widget.muted, size: 18),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    final bottomPad = MediaQuery.of(ctx).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
      decoration: BoxDecoration(color: widget.bg),
      child: Row(
        children: [
          if (_inVoiceMode) ...[
            GestureDetector(
              onTap: widget.onVoiceCancel,
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.accent.withValues(alpha: 0.5)),
                ),
                child: Icon(Icons.mic_rounded, color: widget.accent, size: 18),
              ),
            ),
          ],
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: _buildInputArea(),
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

// ── Voice Waveform ────────────────────────────────────────────────────────────────

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
  static const _barCount = 35;
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
    if (!mounted) return;
    final norm = ((amp.current + 60) / 60).clamp(0.0, 1.0);
    setState(() {
      _bars.removeAt(0);
      _bars.add(norm);
    });
  }

  String get _timeLabel {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Text(
            'LISTENING · $_timeLabel',
            style: GoogleFonts.jetBrainsMono(
              color: widget.accent,
              fontSize: 9,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 32,
              child: CustomPaint(
                painter: _WaveformPainter(bars: _bars, color: widget.accent),
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
    final paint = Paint()..style = PaintingStyle.fill;
    final step = size.width / bars.length;
    const barW = 2.0;
    const minH = 2.0;
    final maxH = size.height * 0.9;
    var x = 0.0;
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


// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.accent,
    required this.isDark,
    required this.fg,
    required this.line,
  });

  final ChatMessage message;
  final Color accent;
  final bool isDark;
  final Color fg;
  final Color line;

  void _showCitationsSheet(BuildContext context) {
    final sheetBg = isDark ? AppColors.nightBg : AppColors.boneBg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CitationsSheet(
        citations: message.citations,
        accent: accent,
        isDark: isDark,
        fg: fg,
        muted: muted,
        line: line,
        sheetBg: sheetBg,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final hasCitations = !isUser && message.citations.isNotEmpty;
    final aiBg = isDark ? AppColors.nightSurface : AppColors.boneSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 8, bottom: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.12),
                    border: Border.all(
                        color: accent.withValues(alpha: 0.25), width: 0.5),
                  ),
                  child: Icon(Icons.auto_stories_rounded,
                      color: accent, size: 13),
                ),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                      maxWidth:
                          MediaQuery.of(context).size.width * 0.75),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? accent : aiBg,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border:
                        isUser ? null : Border.all(color: line, width: 1),
                  ),
                  child: Text(
                    message.text,
                    style: GoogleFonts.inter(
                      color: isUser ? Colors.white : fg,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (hasCitations) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: GestureDetector(
                onTap: () => _showCitationsSheet(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.menu_book_rounded, size: 12, color: accent),
                    const SizedBox(width: 4),
                    Text(
                      '${message.citations.length} source${message.citations.length > 1 ? 's' : ''}',
                      style: GoogleFonts.jetBrainsMono(
                        color: accent,
                        fontSize: 10,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(Icons.open_in_new_rounded, size: 9, color: accent),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Citations sheet ───────────────────────────────────────────────────────────

class _CitationsSheet extends StatelessWidget {
  const _CitationsSheet({
    required this.citations,
    required this.accent,
    required this.isDark,
    required this.fg,
    required this.muted,
    required this.line,
    required this.sheetBg,
  });

  final List<Citation> citations;
  final Color accent;
  final bool isDark;
  final Color fg;
  final Color muted;
  final Color line;
  final Color sheetBg;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                decoration: BoxDecoration(
                  color: line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.1),
                    ),
                    child: Icon(Icons.menu_book_rounded,
                        color: accent, size: 14),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'SCRIPTURE REFERENCES',
                    style: GoogleFonts.jetBrainsMono(
                      color: accent,
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${citations.length} passage${citations.length > 1 ? 's' : ''}',
                    style:
                        GoogleFonts.inter(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Divider(color: line, height: 1),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: citations.length,
                itemBuilder: (_, i) => _CitationCard(
                  citation: citations[i],
                  accent: accent,
                  isDark: isDark,
                  fg: fg,
                  line: line,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CitationCard extends StatelessWidget {
  const _CitationCard({
    required this.citation,
    required this.accent,
    required this.isDark,
    required this.fg,
    required this.line,
  });

  final Citation citation;
  final Color accent;
  final bool isDark;
  final Color fg;
  final Color line;

  @override
  Widget build(BuildContext context) {
    final cardBg =
        isDark ? AppColors.nightSurface : AppColors.boneSurface;
    final hasOriginal = citation.originalText.isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: accent.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                citation.reference.toUpperCase(),
                style: GoogleFonts.jetBrainsMono(
                  color: accent,
                  fontSize: 9,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (hasOriginal) ...[
            const SizedBox(height: 12),
            Directionality(
              textDirection: citation.isRtl
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: Text(
                citation.originalText,
                style: TextStyle(
                  color: fg,
                  fontSize: citation.isRtl ? 19 : 15,
                  height: citation.isRtl ? 2.2 : 1.7,
                  fontWeight: FontWeight.w400,
                  fontFamily: citation.isRtl ? null : 'serif',
                ),
                textAlign: citation.isRtl
                    ? TextAlign.right
                    : TextAlign.left,
              ),
            ),
            const SizedBox(height: 10),
            Divider(color: line, height: 1),
          ],
          const SizedBox(height: 10),
          Text(
            '"${citation.translation}"',
            style: GoogleFonts.cormorantGaramond(
              color: fg.withValues(alpha: 0.8),
              fontSize: 14,
              fontStyle: FontStyle.italic,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Streaming bubble ──────────────────────────────────────────────────────────

class _StreamingBubble extends StatelessWidget {
  const _StreamingBubble({
    required this.text,
    required this.accent,
    required this.isDark,
    required this.fg,
    required this.line,
  });

  final String text;
  final Color accent;
  final bool isDark;
  final Color fg;
  final Color line;

  @override
  Widget build(BuildContext context) {
    final aiBg = isDark ? AppColors.nightSurface : AppColors.boneSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8, bottom: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.12),
              border: Border.all(
                  color: accent.withValues(alpha: 0.25), width: 0.5),
            ),
            child:
                Icon(Icons.auto_stories_rounded, color: accent, size: 13),
          ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      text,
                      style: GoogleFonts.inter(
                          color: fg, fontSize: 14, height: 1.5),
                    ),
                  ),
                  const SizedBox(width: 2),
                  _BlinkingCursor(color: accent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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

class _ReadingPopup extends StatelessWidget {
  const _ReadingPopup({required this.accent, required this.isDark});
  final Color accent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: muted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.menu_book_outlined, color: accent, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'NEW · DAILY READING',
            style: GoogleFonts.jetBrainsMono(
              color: accent, fontSize: 10, letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'A little each day.',
            style: GoogleFonts.cormorantGaramond(
              color: fg, fontSize: 28,
              fontWeight: FontWeight.w500, fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Read scripture consistently. Pick any book and a time frame — we guide you to the right portion each day.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: muted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              showReadingPlanSetupSheet(context);
            },
            child: Container(
              height: 50, width: double.infinity,
              decoration: BoxDecoration(
                color: accent, borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  'Set up your plan',
                  style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              Navigator.of(context).pop();
              await ReadingPlanRepository.instance.recordMaybeLater();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Maybe later',
                style: GoogleFonts.inter(color: muted, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator(
      {required this.accent, required this.isDark, required this.line});
  final Color accent;
  final bool isDark;
  final Color line;

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiBg =
        widget.isDark ? AppColors.nightSurface : AppColors.boneSurface;
    final dotColor =
        widget.isDark ? AppColors.nightMuted : AppColors.boneMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8, bottom: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.accent.withValues(alpha: 0.12),
            ),
            child: Icon(Icons.auto_stories_rounded,
                color: widget.accent, size: 13),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: aiBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.line, width: 1),
            ),
            child: FadeTransition(
              opacity: _anim,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (i) => Container(
                    width: 6,
                    height: 6,
                    margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: dotColor),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
