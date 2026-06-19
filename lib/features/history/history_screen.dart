import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/history_provider.dart';
import '../../providers/chat_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/chat_message.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchController = TextEditingController();
  bool _showSearch = false;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChatSession> _filtered(List<ChatSession> sessions) {
    if (_query.isEmpty) return sessions;
    final q = _query.toLowerCase();
    return sessions.where((s) => s.title.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.nightBg : AppColors.boneBg;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final line = isDark ? AppColors.nightLine : AppColors.boneLine;
    final surface = isDark ? AppColors.nightSurface : Colors.white;

    final filtered = _filtered(state.sessions);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: line),
                            ),
                            child: Icon(Icons.arrow_back_ios_new_rounded,
                                size: 14, color: fg),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'History',
                            style: GoogleFonts.cormorantGaramond(
                              color: fg,
                              fontSize: 28,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showSearch = !_showSearch;
                              if (!_showSearch) {
                                _searchController.clear();
                                _query = '';
                              }
                            });
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: line),
                              color: _showSearch
                                  ? fg.withValues(alpha: 0.08)
                                  : Colors.transparent,
                            ),
                            child: Icon(
                              _showSearch
                                  ? Icons.search_off_rounded
                                  : Icons.search_rounded,
                              size: 16,
                              color: fg,
                            ),
                          ),
                        ),
                        if (state.sessions.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _confirmClearAll(
                                context, isDark, fg, muted, surface),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red.shade400
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.red.shade400
                                        .withValues(alpha: 0.25)),
                              ),
                              child: Text(
                                'Clear all',
                                style: GoogleFonts.inter(
                                  color: Colors.red.shade400,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (_showSearch) ...[
                      const SizedBox(height: 12),
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: line),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 10),
                            Icon(Icons.search_rounded,
                                size: 16, color: muted),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                style: GoogleFonts.inter(
                                    color: fg, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Search conversations…',
                                  hintStyle: GoogleFonts.inter(
                                      color: muted, fontSize: 13),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (v) =>
                                    setState(() => _query = v.trim()),
                              ),
                            ),
                            if (_query.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(Icons.close_rounded,
                                      size: 14, color: muted),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Text(
                _query.isNotEmpty
                    ? '${filtered.length} result${filtered.length == 1 ? '' : 's'}'
                    : '${state.sessions.length} conversation${state.sessions.length == 1 ? '' : 's'}',
                style: GoogleFonts.jetBrainsMono(
                    color: muted, fontSize: 10, letterSpacing: 1.0),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          if (!state.isLoaded)
            _SkeletonList(line: line, surface: surface)
          else if (state.sessions.isEmpty)
            SliverFillRemaining(child: _EmptyState(fg: fg, muted: muted))
          else if (filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'No results for "$_query"',
                  style: GoogleFonts.inter(color: muted, fontSize: 13),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _SessionTile(
                    session: filtered[i],
                    isDark: isDark,
                    fg: fg,
                    muted: muted,
                    line: line,
                    surface: surface,
                    onTap: () {
                      ref
                          .read(chatProvider.notifier)
                          .loadSession(filtered[i]);
                      context.go('/chat');
                    },
                    onDelete: () => ref
                        .read(historyProvider.notifier)
                        .deleteSession(filtered[i].id),
                    onPin: () => ref
                        .read(historyProvider.notifier)
                        .pinSession(filtered[i].id),
                    onRename: (title) => ref
                        .read(historyProvider.notifier)
                        .renameSession(filtered[i].id, title),
                    onExport: () => _exportSession(filtered[i]),
                  ),
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, bool isDark, Color fg,
      Color muted, Color surface) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        title: Text('Clear all history?',
            style:
                GoogleFonts.cormorantGaramond(color: fg, fontSize: 20)),
        content: Text('This will permanently delete all conversations.',
            style: GoogleFonts.inter(color: muted, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('Cancel', style: GoogleFonts.inter(color: muted)),
          ),
          TextButton(
            onPressed: () {
              ref.read(historyProvider.notifier).clearAll();
              Navigator.pop(ctx);
            },
            child: Text('Delete all',
                style: GoogleFonts.inter(
                    color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }

  void _exportSession(ChatSession session) {
    final buf = StringBuffer();
    buf.writeln('=== Divine Chat ===');
    buf.writeln('Title: ${session.title}');
    buf.writeln('Religion: ${session.religionId}');
    buf.writeln(
        'Date: ${_fmtFull(session.createdAt)}');
    buf.writeln('');
    for (final msg in session.messages) {
      buf.writeln(msg.isUser ? '[You]' : '[AI]');
      buf.writeln(msg.text);
      if (!msg.isUser && msg.citations.isNotEmpty) {
        buf.writeln('Sources:');
        for (final c in msg.citations) {
          buf.writeln('  • ${c.reference}');
        }
      }
      buf.writeln('');
    }
    Share.share(buf.toString(), subject: session.title);
  }

  String _fmtFull(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.fg, required this.muted});
  final Color fg;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: muted.withValues(alpha: 0.08),
              border: Border.all(color: muted.withValues(alpha: 0.15)),
            ),
            child: Icon(Icons.history_rounded, color: muted, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: GoogleFonts.cormorantGaramond(
              color: fg,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text('Start chatting to see your history here.',
              style: GoogleFonts.inter(color: muted, fontSize: 13)),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.isDark,
    required this.fg,
    required this.muted,
    required this.line,
    required this.surface,
    required this.onTap,
    required this.onDelete,
    required this.onPin,
    required this.onRename,
    required this.onExport,
  });

  final ChatSession session;
  final bool isDark;
  final Color fg;
  final Color muted;
  final Color line;
  final Color surface;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onPin;
  final void Function(String) onRename;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final accent = ReligionColors.accent(session.religionId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: {
          TapGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
            () => TapGestureRecognizer(),
            (i) => i.onTap = onTap,
          ),
          LongPressGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
            () => LongPressGestureRecognizer(
                duration: const Duration(milliseconds: 300)),
            (i) => i.onLongPressStart =
                (d) => _showContextMenu(context, d.globalPosition),
          ),
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: session.isPinned
                  ? fg.withValues(alpha: 0.3)
                  : line,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.12),
                ),
                child: Center(
                  child: Text(_symbol(session.religionId),
                      style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          color: fg,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          '${_formatDate(session.updatedAt)} • ${session.messages.length} msg${session.messages.length == 1 ? '' : 's'} • ',
                          style: GoogleFonts.inter(
                              color: muted,
                              fontSize: 11),
                        ),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _religionName(session.religionId),
                          style: GoogleFonts.inter(
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (session.isPinned) ...[
                Icon(Icons.push_pin_rounded, size: 12, color: muted),
                const SizedBox(width: 6),
              ],
              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: muted),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 1, 1),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: surface,
      elevation: 8,
      items: [
        PopupMenuItem(
          value: 'rename',
          child: _MenuRow(Icons.edit_outlined, 'Rename', fg),
        ),
        PopupMenuItem(
          value: 'pin',
          child: _MenuRow(
            session.isPinned
                ? Icons.push_pin_rounded
                : Icons.push_pin_outlined,
            session.isPinned ? 'Unpin' : 'Pin to top',
            fg,
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: _MenuRow(
              Icons.delete_outline_rounded, 'Delete', Colors.red.shade400),
        ),
      ],
    ).then((value) {
      if (!context.mounted) return;
      switch (value) {
        case 'rename':
          _showRenameDialog(context);
        case 'pin':
          onPin();
        case 'delete':
          _showDeleteDialog(context);
      }
    });
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: session.title);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        title: Text('Rename',
            style: GoogleFonts.cormorantGaramond(
                color: fg, fontSize: 20, fontWeight: FontWeight.w500)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.inter(color: fg, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Conversation title',
            hintStyle: GoogleFonts.inter(color: muted, fontSize: 14),
          ),
          onSubmitted: (v) {
            final t = v.trim();
            if (t.isNotEmpty) {
              Navigator.pop(ctx);
              onRename(t);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: muted)),
          ),
          TextButton(
            onPressed: () {
              final t = controller.text.trim();
              if (t.isNotEmpty) {
                Navigator.pop(ctx);
                onRename(t);
              }
            },
            child: Text('Save',
                style: GoogleFonts.inter(
                    color: fg, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        title: Text('Delete conversation?',
            style: GoogleFonts.cormorantGaramond(
                color: fg, fontSize: 20, fontWeight: FontWeight.w500)),
        content: Text('This conversation will be permanently deleted.',
            style: GoogleFonts.inter(color: muted, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: GoogleFonts.inter(
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) onDelete();
    });
  }

  String _symbol(String id) => switch (id) {
        'islam' => '☪',
        'hinduism' => '🕉',
        'sikhism' => '☬',
        'christianity' => '✝',
        _ => '✦',
      };

  String _formatDate(DateTime dt) {
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

  String _religionName(String id) => switch (id) {
    'islam' => 'Islam',
    'hinduism' => 'Hinduism',
    'sikhism' => 'Sikhism',
    'christianity' => 'Christianity',
    _ => id,
  };
}

class _MenuRow extends StatelessWidget {
  const _MenuRow(this.icon, this.label, this.color);
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 12),
        Text(label,
            style: GoogleFonts.inter(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _SkeletonList extends StatefulWidget {
  const _SkeletonList({required this.line, required this.surface});
  final Color line;
  final Color surface;

  @override
  State<_SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<_SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => AnimatedBuilder(
            animation: _ctrl,
            builder: (_, _) => Opacity(
              opacity: 0.3 + _ctrl.value * 0.4,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SkeletonTile(
                  surface: widget.surface,
                  line: widget.line,
                ),
              ),
            ),
          ),
          childCount: 5,
        ),
      ),
    );
  }
}

class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile({required this.surface, required this.line});
  final Color surface;
  final Color line;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmer = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: line),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle, color: shimmer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 13,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: shimmer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: 120,
                  decoration: BoxDecoration(
                    color: shimmer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
