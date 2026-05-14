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
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
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
    buf.writeln('=== Divine Dialogue ===');
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
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final accent = ReligionColors.accent(session.religionId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: Key(session.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red.shade400.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.delete_outline_rounded,
              color: Colors.red.shade400, size: 22),
        ),
        child: GestureDetector(
          onTap: onTap,
          onLongPress: () => _showOptions(context),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: line),
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
                      Text(
                        '${session.messages.length} msg${session.messages.length == 1 ? '' : 's'} · ${_formatDate(session.updatedAt)}',
                        style: GoogleFonts.jetBrainsMono(
                            color: muted,
                            fontSize: 10,
                            letterSpacing: 0.3),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: muted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: muted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                session.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    color: fg,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 16),
            _OptionTile(
              icon: Icons.open_in_new_rounded,
              label: 'Open conversation',
              color: fg,
              onTap: () {
                Navigator.pop(ctx);
                onTap();
              },
            ),
            _OptionTile(
              icon: Icons.ios_share_rounded,
              label: 'Export conversation',
              color: fg,
              onTap: () {
                Navigator.pop(ctx);
                onExport();
              },
            ),
            _OptionTile(
              icon: Icons.delete_outline_rounded,
              label: 'Delete conversation',
              color: Colors.red.shade400,
              onTap: () {
                Navigator.pop(ctx);
                onDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _symbol(String id) => switch (id) {
        'islam' => '☪',
        'hinduism' => '🕉',
        'sikhism' => '☬',
        'christianity' => '✝',
        _ => '✦',
      };

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        label,
        style: GoogleFonts.inter(
            color: color, fontSize: 14, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}
