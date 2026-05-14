import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/chat_provider.dart';
import '../../providers/religion_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/chat_message.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();

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
    super.dispose();
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

    final chatState = ref.watch(chatProvider);
    final religionState = ref.watch(religionProvider);
    final religion = religionState.selectedReligion;
    final accent = religion != null ? ReligionColors.accent(religion.id) : AppColors.islamGreen;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.nightBg : AppColors.boneBg;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final line = isDark ? AppColors.nightLine : AppColors.boneLine;

    final messages = chatState.session?.messages ?? [];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (messages.isNotEmpty || chatState.isStreaming || chatState.isTyping) _scrollToBottom();
      if (chatState.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(chatState.error!, style: GoogleFonts.inter(fontSize: 13)),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

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
                ? _EmptyState(accent: accent, religion: religion?.name, fg: fg, muted: muted)
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    itemCount: messages.length +
                        (chatState.isTyping || chatState.isStreaming ? 1 : 0),
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
                  ),
          ),
          if (chatState.pendingVerseContext != null)
            _VerseBanner(
              verseContext: chatState.pendingVerseContext!,
              accent: accent,
              fg: fg,
              muted: muted,
              line: line,
              onDismiss: () => ref.read(chatProvider.notifier).clearPendingVerse(),
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
          ),
        ],
      ),
    );
  }
}

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
                color: fg, fontSize: 20, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(Icons.history_rounded, color: fg.withValues(alpha: 0.6), size: 20),
            onPressed: onHistory,
            tooltip: 'History',
          ),
          IconButton(
            icon: Icon(Icons.add_comment_outlined, color: accent, size: 20),
            onPressed: onNewChat,
            tooltip: 'New chat',
          ),
        ],
      ),
    );
  }
}

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
              religion != null ? 'Ask anything about $religion' : 'Start a conversation',
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                color: fg, fontSize: 20, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic,
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
                  child: Icon(Icons.auto_stories_rounded, color: accent, size: 13),
                ),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? accent : aiBg,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isUser ? null : Border.all(color: line, width: 1),
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                    child: Icon(Icons.menu_book_rounded, color: accent, size: 14),
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
                    style: GoogleFonts.inter(color: muted, fontSize: 12),
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
    final cardBg = isDark ? AppColors.nightSurface : AppColors.boneSurface;
    final hasOriginal = citation.originalText.isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.3), width: 0.8),
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
              textDirection: citation.isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: Text(
                citation.originalText,
                style: TextStyle(
                  color: fg,
                  fontSize: citation.isRtl ? 19 : 15,
                  height: citation.isRtl ? 2.2 : 1.7,
                  fontWeight: FontWeight.w400,
                  fontFamily: citation.isRtl ? null : 'serif',
                ),
                textAlign: citation.isRtl ? TextAlign.right : TextAlign.left,
              ),
            ),
            const SizedBox(height: 10),
            Divider(color: line, height: 1),
          ],
          const SizedBox(height: 10),
          Text(
            '“${citation.translation}”',
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
                    fontSize: 8, color: accent, letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  preview,
                  style: GoogleFonts.inter(fontSize: 11, color: muted, height: 1.4),
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
              border: Border.all(color: accent.withValues(alpha: 0.25), width: 0.5),
            ),
            child: Icon(Icons.auto_stories_rounded, color: accent, size: 13),
          ),
          Flexible(
            child: Container(
              constraints:
                  BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      style: GoogleFonts.inter(color: fg, fontSize: 14, height: 1.5),
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

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({required this.accent, required this.isDark, required this.line});
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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
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
    final aiBg = widget.isDark ? AppColors.nightSurface : AppColors.boneSurface;
    final dotColor = widget.isDark ? AppColors.nightMuted : AppColors.boneMuted;

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
            child: Icon(Icons.auto_stories_rounded, color: widget.accent, size: 13),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                    decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
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
  });

  final TextEditingController controller;
  final Color accent;
  final VoidCallback onSend;
  final bool isDark;
  final Color fg;
  final Color muted;
  final Color line;
  final Color bg;

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

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final fieldBg = widget.isDark ? AppColors.nightSurface : Colors.white;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottomPad),
      decoration: BoxDecoration(
        color: widget.bg,
        border: Border(top: BorderSide(color: widget.line, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
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
                  hintStyle:
                      GoogleFonts.inter(color: widget.muted, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: _hasText
                ? GestureDetector(
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
                  )
                : Container(
                    key: const ValueKey('idle'),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: widget.line),
                    ),
                    child: Icon(Icons.auto_awesome_outlined,
                        color: widget.muted, size: 18),
                  ),
          ),
        ],
      ),
    );
  }
}
