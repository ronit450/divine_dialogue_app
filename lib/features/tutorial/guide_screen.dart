import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

// ── Menu ─────────────────────────────────────────────────────────────────────

class GuideMenuScreen extends StatelessWidget {
  const GuideMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.nightBg : AppColors.boneBg;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final line = isDark ? AppColors.nightLine : AppColors.boneLine;
    final surface = isDark ? AppColors.nightSurface : Colors.white;

    void openAt(int index) {
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => GuideTutorialFlow(initialIndex: index),
      ));
    }

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: line),
                            ),
                            child: Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: fg),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Feature Guide',
                          style: GoogleFonts.cormorantGaramond(
                            color: fg,
                            fontSize: 28,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 48),
                      child: Text(
                        'Everything you can do in the app',
                        style: GoogleFonts.inter(color: muted, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _MenuSection(
                      label: 'CHAT',
                      entries: [
                        _MenuEntry('01', 'Ask your tradition', 'Voice or text — AI answers from scripture', () => openAt(0)),
                        _MenuEntry('02', 'Scripture citations', 'Every answer links to exact verse references', () => openAt(1)),
                        _MenuEntry('03', 'Save a verse', 'Bookmark any cited verse to your collection', () => openAt(2)),
                      ],
                      surface: surface,
                      line: line,
                      fg: fg,
                      muted: muted,
                    ),
                    const SizedBox(height: 24),
                    _MenuSection(
                      label: 'READER',
                      entries: [
                        _MenuEntry('04', 'Reading options', 'Toggle translation and transliteration', () => openAt(3)),
                        _MenuEntry('05', 'Chapter navigation', 'Jump to any chapter via the TOC sheet', () => openAt(4)),
                        _MenuEntry('06', 'Paged navigation', 'Numeric jump for Sikh texts and Hadith', () => openAt(5)),
                      ],
                      surface: surface,
                      line: line,
                      fg: fg,
                      muted: muted,
                    ),
                    const SizedBox(height: 24),
                    _MenuSection(
                      label: 'PRACTICE',
                      entries: [
                        _MenuEntry('07', 'Switch tradition', 'Change your religion from Settings', () => openAt(6)),
                        _MenuEntry('08', 'Reading plans', 'Set a daily goal with reminders', () => openAt(7)),
                      ],
                      surface: surface,
                      line: line,
                      fg: fg,
                      muted: muted,
                    ),
                    const SizedBox(height: 24),
                    _MenuSection(
                      label: 'LIBRARY',
                      entries: [
                        _MenuEntry('09', 'Browse texts', 'Explore all texts in your tradition', () => openAt(8)),
                        _MenuEntry('10', 'Conversation history', 'Return to any past dialogue', () => openAt(9)),
                      ],
                      surface: surface,
                      line: line,
                      fg: fg,
                      muted: muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuEntry {
  const _MenuEntry(this.number, this.title, this.subtitle, this.onTap);
  final String number, title, subtitle;
  final VoidCallback onTap;
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({
    required this.label,
    required this.entries,
    required this.surface,
    required this.line,
    required this.fg,
    required this.muted,
  });

  final String label;
  final List<_MenuEntry> entries;
  final Color surface, line, fg, muted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            color: muted,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: line),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: entries.asMap().entries.map((e) {
              final entry = e.value;
              final isLast = e.key == entries.length - 1;
              return Column(
                children: [
                  GestureDetector(
                    onTap: entry.onTap,
                    child: Container(
                      color: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: muted.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                entry.number,
                                style: GoogleFonts.jetBrainsMono(
                                  color: muted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.title,
                                  style: GoogleFonts.inter(color: fg, fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  entry.subtitle,
                                  style: GoogleFonts.inter(color: muted, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: muted, size: 18),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast) Divider(height: 1, color: line),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Tutorial Flow ─────────────────────────────────────────────────────────────

class GuideTutorialFlow extends StatefulWidget {
  const GuideTutorialFlow({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<GuideTutorialFlow> createState() => _GuideTutorialFlowState();
}

class _GuideTutorialFlowState extends State<GuideTutorialFlow> {
  late final PageController _ctrl;
  int _page = 0;

  static const _count = 10;

  static const _titles = [
    'Ask your tradition',
    'Scripture citations',
    'Save a verse',
    'Reading options',
    'Chapter navigation',
    'Paged navigation',
    'Switch tradition',
    'Reading plans',
    'Browse texts',
    'Conversation history',
  ];

  static const _captions = [
    'Type or speak any question about your faith.\nYour AI companion searches the scriptures for you.',
    'Each response includes clickable citations so you\ncan read the exact verse in context.',
    'Tap the bookmark on any citation to save it.\nFind all saved verses in your Profile tab.',
    'Open the format panel while reading to toggle\ntranslation and transliteration at any time.',
    'Tap the list icon at the bottom of the reader\nto open a searchable chapter list.',
    'For longer texts like Guru Granth Sahib,\nenter a page number to jump directly.',
    'Go to Settings → Tradition to switch between\nIslam, Hinduism, Sikhism, and Christianity.',
    'Set a daily reading goal and enable reminders.\nThe app tracks your streak automatically.',
    'The Library tab shows all sacred texts for\nyour selected tradition. Tap any to start reading.',
    'All your conversations are saved. Access them\nfrom the chat drawer or the History screen.',
  ];

  @override
  void initState() {
    super.initState();
    _page = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _count - 1) {
      _ctrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.nightBg : AppColors.boneBg;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final line = isDark ? AppColors.nightLine : AppColors.boneLine;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: line),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: fg),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(_page + 1).toString().padLeft(2, '0')} / $_count',
                    style: GoogleFonts.jetBrainsMono(
                      color: muted,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _count,
                itemBuilder: (context, i) => _GuidePage(
                  index: i,
                  title: _titles[i],
                  caption: _captions[i],
                  isDark: isDark,
                  fg: fg,
                  muted: muted,
                  line: line,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_count, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: active ? 18 : 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.islamGreen
                              : muted.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.islamGreen,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        _page == _count - 1 ? 'Done' : 'Next',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
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

class _GuidePage extends StatelessWidget {
  const _GuidePage({
    required this.index,
    required this.title,
    required this.caption,
    required this.isDark,
    required this.fg,
    required this.muted,
    required this.line,
  });

  final int index;
  final String title, caption;
  final bool isDark;
  final Color fg, muted, line;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.nightSurface : Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cormorantGaramond(
              color: fg,
              fontSize: 30,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: line),
              ),
              clipBehavior: Clip.hardEdge,
              child: CustomPaint(
                painter: _DotGridPainter(dotColor: muted.withValues(alpha: 0.14)),
                child: _buildDemo(),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            caption,
            style: GoogleFonts.inter(color: muted, fontSize: 13, height: 1.65),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildDemo() {
    switch (index) {
      case 0:
        return _DemoAsk(isDark: isDark, fg: fg, muted: muted, line: line);
      case 1:
        return _DemoCitations(isDark: isDark, fg: fg, muted: muted, line: line);
      case 2:
        return _DemoSave(isDark: isDark, fg: fg, muted: muted, line: line);
      case 3:
        return _DemoToggles(isDark: isDark, fg: fg, muted: muted, line: line);
      case 4:
        return _DemoToc(isDark: isDark, fg: fg, muted: muted, line: line);
      case 5:
        return _DemoPaged(isDark: isDark, fg: fg, muted: muted, line: line);
      case 6:
        return _DemoTradition(isDark: isDark, fg: fg, muted: muted, line: line);
      case 7:
        return _DemoPlans(isDark: isDark, fg: fg, muted: muted, line: line);
      case 8:
        return _DemoLibrary(isDark: isDark, fg: fg, muted: muted, line: line);
      case 9:
        return _DemoHistory(isDark: isDark, fg: fg, muted: muted, line: line);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Dot Grid ──────────────────────────────────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter({required this.dotColor});
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor;
    const grid = 22.0;
    const r = 1.5;
    for (var row = 0.0; row <= size.height + grid; row += grid) {
      for (var col = 0.0; col <= size.width + grid; col += grid) {
        canvas.drawCircle(Offset(col, row), r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.dotColor != dotColor;
}

// ── Demo 0: Ask ───────────────────────────────────────────────────────────────

class _DemoAsk extends StatefulWidget {
  const _DemoAsk({required this.isDark, required this.fg, required this.muted, required this.line});
  final bool isDark;
  final Color fg, muted, line;

  @override
  State<_DemoAsk> createState() => _DemoAskState();
}

class _DemoAskState extends State<_DemoAsk> {
  static const _q = 'What does the Quran say about patience?';
  int _chars = 0;
  bool _showReply = false;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _loop();
  }

  void _loop() {
    _t = Timer.periodic(const Duration(milliseconds: 65), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_chars < _q.length) {
        setState(() => _chars++);
      } else {
        t.cancel();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          setState(() => _showReply = true);
          Future.delayed(const Duration(milliseconds: 2800), () {
            if (!mounted) return;
            setState(() { _chars = 0; _showReply = false; });
            _loop();
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = widget.isDark ? AppColors.nightSurface : Colors.white;
    final typed = _q.substring(0, _chars);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AnimatedOpacity(
            opacity: _showReply ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 350),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10, right: 24),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.islamGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.islamGreen.withValues(alpha: 0.2)),
              ),
              child: Text(
                '"Indeed, Allah is with the patient." — Al-Baqarah 2:153',
                style: GoogleFonts.inter(color: widget.fg, fontSize: 11, height: 1.5),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: widget.line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    typed.isEmpty ? 'Ask anything…' : typed,
                    style: GoogleFonts.inter(
                      color: typed.isEmpty ? widget.muted : widget.fg,
                      fontSize: 12,
                      height: 1.4,
                    ),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.islamGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Demo 1: Citations ─────────────────────────────────────────────────────────

class _DemoCitations extends StatefulWidget {
  const _DemoCitations({required this.isDark, required this.fg, required this.muted, required this.line});
  final bool isDark;
  final Color fg, muted, line;

  @override
  State<_DemoCitations> createState() => _DemoCitationsState();
}

class _DemoCitationsState extends State<_DemoCitations> {
  int _visible = 0;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _step();
  }

  void _step() {
    _t = Timer.periodic(const Duration(milliseconds: 900), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_visible < 2) {
        setState(() => _visible++);
      } else {
        t.cancel();
        Future.delayed(const Duration(milliseconds: 2200), () {
          if (!mounted) return;
          setState(() => _visible = 0);
          _step();
        });
      }
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'The Quran emphasizes patience in times of difficulty and hardship…',
            style: GoogleFonts.inter(color: widget.fg, fontSize: 11, height: 1.5),
          ),
          const SizedBox(height: 12),
          AnimatedOpacity(
            opacity: _visible >= 1 ? 1 : 0,
            duration: const Duration(milliseconds: 400),
            child: _CitCard(
              ref: 'Al-Baqarah 2:153',
              text: '"O you who have believed, seek help through patience and prayer."',
              accent: AppColors.islamGreen,
              fg: widget.fg,
              muted: widget.muted,
              line: widget.line,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedOpacity(
            opacity: _visible >= 2 ? 1 : 0,
            duration: const Duration(milliseconds: 400),
            child: _CitCard(
              ref: 'Az-Zumar 39:10',
              text: '"The patient will be given their reward without account."',
              accent: AppColors.islamGreen,
              fg: widget.fg,
              muted: widget.muted,
              line: widget.line,
            ),
          ),
        ],
      ),
    );
  }
}

class _CitCard extends StatelessWidget {
  const _CitCard({
    required this.ref,
    required this.text,
    required this.accent,
    required this.fg,
    required this.muted,
    required this.line,
  });
  final String ref, text;
  final Color accent, fg, muted, line;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ref,
            style: GoogleFonts.jetBrainsMono(
              color: accent,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: GoogleFonts.inter(color: fg, fontSize: 10, height: 1.5),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Demo 2: Save ──────────────────────────────────────────────────────────────

class _DemoSave extends StatefulWidget {
  const _DemoSave({required this.isDark, required this.fg, required this.muted, required this.line});
  final bool isDark;
  final Color fg, muted, line;

  @override
  State<_DemoSave> createState() => _DemoSaveState();
}

class _DemoSaveState extends State<_DemoSave> {
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _loop();
  }

  void _loop() {
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _saved = true);
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (!mounted) return;
        setState(() => _saved = false);
        _loop();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final surface = widget.isDark ? AppColors.nightSurface : Colors.white;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _saved
                  ? AppColors.islamGreen.withValues(alpha: 0.4)
                  : widget.line,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.islamGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      'Al-Imran 3:200',
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.islamGreen,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: Icon(
                      _saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      key: ValueKey(_saved),
                      color: _saved ? AppColors.islamGreen : widget.muted,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '"O you who have believed, persevere and endure and remain stationed…"',
                style: GoogleFonts.inter(color: widget.fg, fontSize: 11, height: 1.6),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                child: _saved
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppColors.islamGreen, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              'Saved to your collection',
                              style: GoogleFonts.inter(color: AppColors.islamGreen, fontSize: 10),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Demo 3: Toggles ───────────────────────────────────────────────────────────

class _DemoToggles extends StatefulWidget {
  const _DemoToggles({required this.isDark, required this.fg, required this.muted, required this.line});
  final bool isDark;
  final Color fg, muted, line;

  @override
  State<_DemoToggles> createState() => _DemoTogglesState();
}

class _DemoTogglesState extends State<_DemoToggles> {
  bool _translation = false;
  bool _translit = false;
  int _phase = 0;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 900), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_phase == 0) { _translation = true; }
        else if (_phase == 1) { _translit = true; }
        else if (_phase == 4) { _translation = false; _translit = false; _phase = -1; }
        _phase++;
      });
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = widget.isDark ? AppColors.nightSurface : Colors.white;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Text(
                  'Reading options',
                  style: GoogleFonts.cormorantGaramond(
                    color: widget.fg,
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Divider(height: 1, color: widget.line),
              _DemoToggleRow(label: 'Translation', value: _translation, fg: widget.fg, muted: widget.muted, line: widget.line),
              Divider(height: 1, color: widget.line),
              _DemoToggleRow(label: 'Transliteration', value: _translit, fg: widget.fg, muted: widget.muted, line: widget.line),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoToggleRow extends StatelessWidget {
  const _DemoToggleRow({
    required this.label,
    required this.value,
    required this.fg,
    required this.muted,
    required this.line,
  });
  final String label;
  final bool value;
  final Color fg, muted, line;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.inter(color: fg, fontSize: 13)),
          const Spacer(),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 40,
            height: 22,
            decoration: BoxDecoration(
              color: value
                  ? AppColors.islamGreen.withValues(alpha: 0.25)
                  : muted.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: value
                    ? AppColors.islamGreen.withValues(alpha: 0.6)
                    : muted.withValues(alpha: 0.3),
              ),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: value ? AppColors.islamGreen : muted.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Demo 4: TOC ───────────────────────────────────────────────────────────────

class _DemoToc extends StatefulWidget {
  const _DemoToc({required this.isDark, required this.fg, required this.muted, required this.line});
  final bool isDark;
  final Color fg, muted, line;

  @override
  State<_DemoToc> createState() => _DemoTocState();
}

class _DemoTocState extends State<_DemoToc> {
  int _sel = -1;
  int _phase = 0;
  Timer? _t;

  static const _chapters = ['Al-Fatiha', 'Al-Baqarah', 'Ali Imran', 'An-Nisa'];

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 700), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _sel = _phase % (_chapters.length + 2) - 1;
        _phase++;
      });
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = widget.isDark ? AppColors.nightSurface : Colors.white;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.line),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _chapters.asMap().entries.map((e) {
            final i = e.key;
            final ch = e.value;
            final active = i == _sel;
            final isLast = i == _chapters.length - 1;
            return Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  color: active
                      ? AppColors.islamGreen.withValues(alpha: 0.08)
                      : Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Text(
                        '${i + 1}',
                        style: GoogleFonts.jetBrainsMono(
                          color: active ? AppColors.islamGreen : widget.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          ch,
                          style: GoogleFonts.inter(
                            color: active ? AppColors.islamGreen : widget.fg,
                            fontSize: 13,
                            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (active)
                        const Icon(Icons.chevron_right_rounded, color: AppColors.islamGreen, size: 16),
                    ],
                  ),
                ),
                if (!isLast) Divider(height: 1, color: widget.line),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Demo 5: Paged ─────────────────────────────────────────────────────────────

class _DemoPaged extends StatefulWidget {
  const _DemoPaged({required this.isDark, required this.fg, required this.muted, required this.line});
  final bool isDark;
  final Color fg, muted, line;

  @override
  State<_DemoPaged> createState() => _DemoPagedState();
}

class _DemoPagedState extends State<_DemoPaged> {
  static const _digits = '245';
  int _chars = 0;
  bool _jumped = false;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _loop();
  }

  void _loop() {
    _t = Timer.periodic(const Duration(milliseconds: 220), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_chars < _digits.length) {
        setState(() => _chars++);
      } else {
        t.cancel();
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          setState(() => _jumped = true);
          Future.delayed(const Duration(milliseconds: 2200), () {
            if (!mounted) return;
            setState(() { _chars = 0; _jumped = false; });
            _loop();
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = widget.isDark ? AppColors.nightSurface : Colors.white;
    final typed = _digits.substring(0, _chars);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: widget.line),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Text(
                    'JUMP TO ANG',
                    style: GoogleFonts.jetBrainsMono(
                      color: widget.muted, fontSize: 9, letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    typed.isEmpty ? '—' : typed,
                    style: GoogleFonts.cormorantGaramond(
                      color: widget.fg,
                      fontSize: 40,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: _chars == _digits.length
                          ? AppColors.sikhNavy
                          : widget.muted.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _jumped ? 'Navigated ✓' : 'Go',
                      style: GoogleFonts.inter(
                        color: _chars == _digits.length ? Colors.white : widget.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: ['100', '200', '300', '400'].map((n) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: widget.muted.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: widget.line),
                  ),
                  child: Text(
                    n,
                    style: GoogleFonts.jetBrainsMono(
                      color: widget.muted, fontSize: 10,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Demo 6: Tradition ─────────────────────────────────────────────────────────

class _DemoTradition extends StatefulWidget {
  const _DemoTradition({required this.isDark, required this.fg, required this.muted, required this.line});
  final bool isDark;
  final Color fg, muted, line;

  @override
  State<_DemoTradition> createState() => _DemoTraditionState();
}

class _DemoTraditionState extends State<_DemoTradition> {
  int _sel = 0;
  Timer? _t;

  static const _names = ['Islam', 'Hinduism', 'Sikhism', 'Christianity'];
  static const _colors = [
    AppColors.islamGreen,
    AppColors.hinduOrange,
    AppColors.sikhNavy,
    AppColors.christianPurple,
  ];

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 1200), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _sel = (_sel + 1) % _names.length);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = widget.isDark ? AppColors.nightSurface : Colors.white;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.line),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_names.length, (i) {
            final active = i == _sel;
            final color = _colors[i];
            final isLast = i == _names.length - 1;
            return Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  color: active ? color.withValues(alpha: 0.07) : Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _names[i],
                          style: GoogleFonts.inter(
                            color: active ? color : widget.fg,
                            fontSize: 13,
                            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (active) Icon(Icons.check_circle_rounded, color: color, size: 18),
                    ],
                  ),
                ),
                if (!isLast) Divider(height: 1, color: widget.line),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ── Demo 7: Plans ─────────────────────────────────────────────────────────────

class _DemoPlans extends StatefulWidget {
  const _DemoPlans({required this.isDark, required this.fg, required this.muted, required this.line});
  final bool isDark;
  final Color fg, muted, line;

  @override
  State<_DemoPlans> createState() => _DemoPlansState();
}

class _DemoPlansState extends State<_DemoPlans> {
  double _progress = 0;
  int _day = 1;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _animate();
  }

  void _animate() {
    _t = Timer.periodic(const Duration(milliseconds: 90), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_progress >= 1.0) {
        t.cancel();
        Future.delayed(const Duration(milliseconds: 1800), () {
          if (!mounted) return;
          setState(() { _progress = 0; _day = 1; });
          _animate();
        });
      } else {
        setState(() {
          _progress = (_progress + 1 / 300).clamp(0.0, 1.0);
          _day = (_progress * 30).round().clamp(1, 30);
        });
      }
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = widget.isDark ? AppColors.nightSurface : Colors.white;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.islamGreen.withValues(alpha: 0.25)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.menu_book_rounded, color: AppColors.islamGreen, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Quran in 30 Days',
                    style: GoogleFonts.inter(
                      color: widget.fg, fontSize: 13, fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Day $_day of 30',
                style: GoogleFonts.jetBrainsMono(
                  color: widget.muted, fontSize: 10, letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: AppColors.islamGreen.withValues(alpha: 0.12),
                  valueColor: const AlwaysStoppedAnimation(AppColors.islamGreen),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    '${(_progress * 100).toInt()}% complete',
                    style: GoogleFonts.inter(color: widget.muted, fontSize: 10),
                  ),
                  const Spacer(),
                  const Icon(Icons.notifications_outlined, color: AppColors.islamGreen, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '8:00 AM',
                    style: GoogleFonts.inter(
                      color: AppColors.islamGreen, fontSize: 10, fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Demo 8: Library ───────────────────────────────────────────────────────────

class _DemoLibrary extends StatefulWidget {
  const _DemoLibrary({required this.isDark, required this.fg, required this.muted, required this.line});
  final bool isDark;
  final Color fg, muted, line;

  @override
  State<_DemoLibrary> createState() => _DemoLibraryState();
}

class _DemoLibraryState extends State<_DemoLibrary> {
  int _hi = -1;
  int _tick = 0;
  Timer? _t;

  static const _titles = ['The Quran', 'Sahih al-Bukhari', 'Sahih Muslim'];
  static const _subs = ['Quranic revelation', 'Hadith collection', 'Hadith collection'];

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 900), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _hi = _tick % (_titles.length + 1) - 1;
        _tick++;
      });
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = widget.isDark ? AppColors.nightSurface : Colors.white;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_titles.length, (i) {
          final active = i == _hi;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.islamGreen.withValues(alpha: 0.08)
                  : surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active
                    ? AppColors.islamGreen.withValues(alpha: 0.3)
                    : widget.line,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.islamGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: AppColors.islamGreen, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _titles[i],
                        style: GoogleFonts.inter(
                          color: widget.fg, fontSize: 12, fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _subs[i],
                        style: GoogleFonts.inter(color: widget.muted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: widget.muted, size: 16),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Demo 9: History ───────────────────────────────────────────────────────────

class _DemoHistory extends StatefulWidget {
  const _DemoHistory({required this.isDark, required this.fg, required this.muted, required this.line});
  final bool isDark;
  final Color fg, muted, line;

  @override
  State<_DemoHistory> createState() => _DemoHistoryState();
}

class _DemoHistoryState extends State<_DemoHistory> {
  int _hi = 0;
  Timer? _t;

  static const _titles = ['Patience in Islam', 'Gita on Karma', 'Gurbani on Forgiveness'];
  static const _times = ['2h ago', 'Yesterday', '3 days ago'];
  static const _colors = [AppColors.islamGreen, AppColors.hinduOrange, AppColors.sikhNavy];

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 1100), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _hi = (_hi + 1) % _titles.length);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = widget.isDark ? AppColors.nightSurface : Colors.white;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.line),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_titles.length, (i) {
            final active = i == _hi;
            final color = _colors[i];
            final isLast = i == _titles.length - 1;
            return Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  color: active ? color.withValues(alpha: 0.06) : Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _titles[i],
                          style: GoogleFonts.inter(
                            color: widget.fg,
                            fontSize: 12,
                            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      Text(
                        _times[i],
                        style: GoogleFonts.inter(color: widget.muted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                if (!isLast) Divider(height: 1, color: widget.line),
              ],
            );
          }),
        ),
      ),
    );
  }
}
