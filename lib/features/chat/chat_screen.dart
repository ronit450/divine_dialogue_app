import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    _ensureSession();
  }

  void _ensureSession() {
    final chatState = ref.read(chatProvider);
    if (chatState.session != null) return;

    final religionState = ref.read(religionProvider);
    final religion = religionState.selectedReligion;
    final text = religionState.selectedText;

    if (religion != null && text != null) {
      ref.read(chatProvider.notifier).startNewSession(
        religionId: religion.id,
        textId: text.id,
        textTitle: text.title,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
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
      if (messages.isNotEmpty) _scrollToBottom();
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
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _EmptyState(accent: accent, religion: religion?.name, fg: fg, muted: muted)
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    itemCount: messages.length + (chatState.isTyping ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == messages.length) {
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
  });

  final String title;
  final Color accent;
  final bool isDark;
  final Color fg;
  final Color line;
  final Color bg;

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
          const SizedBox(width: 16),
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
            icon: Icon(Icons.add_comment_outlined, color: accent, size: 20),
            onPressed: () {},
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

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final aiBg = isDark ? AppColors.nightSurface : AppColors.boneSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                border: Border.all(color: accent.withValues(alpha: 0.25), width: 0.5),
              ),
              child: Icon(Icons.auto_stories_rounded, color: accent, size: 13),
            ),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: GoogleFonts.inter(
                      color: isUser ? Colors.white : fg,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  if (message.citations.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: message.citations
                          .map((c) => _CitationChip(text: c, accent: accent))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CitationChip extends StatelessWidget {
  const _CitationChip({required this.text, required this.accent});

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accent.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(color: accent, fontSize: 10, fontWeight: FontWeight.w500),
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

class _InputBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final fieldBg = isDark ? AppColors.nightSurface : Colors.white;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottomPad),
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: line, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: fieldBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: line),
              ),
              child: TextField(
                controller: controller,
                style: GoogleFonts.inter(color: fg, fontSize: 14),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Ask about the text…',
                  hintStyle: GoogleFonts.inter(color: muted, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent,
                boxShadow: [
                  BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 10),
                ],
              ),
              child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
