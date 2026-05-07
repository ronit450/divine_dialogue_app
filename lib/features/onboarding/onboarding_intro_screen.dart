import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/religion_glyph.dart';

class OnboardingIntroScreen extends StatefulWidget {
  const OnboardingIntroScreen({super.key});

  @override
  State<OnboardingIntroScreen> createState() => _OnboardingIntroScreenState();
}

class _OnboardingIntroScreenState extends State<OnboardingIntroScreen> {
  int _page = 0;
  final _controller = PageController();

  static const _slides = [
    _Slide(
      title: 'A space to ask\nwhat\'s been unspoken',
      body: 'Every question about your faith deserves a thoughtful, sourced answer — without the fear of judgment.',
    ),
    _Slide(
      title: 'Rooted in the\ntexts you trust',
      body: 'Choose your tradition. Every answer cites the scripture, verse, or passage it draws from — so you can read further.',
    ),
    _Slide(
      title: 'Private. Patient.\nAlways with you.',
      body: 'No question is too small. Conversations stay on your device. Return to them anytime — at fajr, vespers, or 3 a.m.',
      primaryLabel: 'Begin',
    ),
  ];

  void _next() {
    if (_page < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/sign-in');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final line = isDark ? AppColors.nightLine : AppColors.boneLine;
    const accent = AppColors.islamGreen;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(_page + 1).toString().padLeft(2, '0')} / ${_slides.length.toString().padLeft(2, '0')}',
                    style: GoogleFonts.jetBrainsMono(
                      color: muted,
                      fontSize: 11,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_page < _slides.length - 1)
                    GestureDetector(
                      onTap: () => context.go('/sign-in'),
                      child: Text(
                        'Skip',
                        style: GoogleFonts.inter(
                          color: muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _slides.length,
                itemBuilder: (context, i) => _SlideView(
                  slide: _slides[i],
                  index: i,
                  accent: accent,
                  fg: fg,
                  muted: muted,
                  line: line,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 24 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: active ? accent : line,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        _slides[_page].primaryLabel,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
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

class _Slide {
  const _Slide({
    required this.title,
    required this.body,
    this.primaryLabel = 'Continue',
  });
  final String title;
  final String body;
  final String primaryLabel;
}

class _SlideView extends StatelessWidget {
  const _SlideView({
    required this.slide,
    required this.index,
    required this.accent,
    required this.fg,
    required this.muted,
    required this.line,
  });

  final _Slide slide;
  final int index;
  final Color accent;
  final Color fg;
  final Color muted;
  final Color line;

  @override
  Widget build(BuildContext context) {
    if (index == 1) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: const [
                _ReligionGlyphCard(id: 'islam', name: 'Islam', color: AppColors.islamGreen),
                _ReligionGlyphCard(id: 'hinduism', name: 'Hinduism', color: AppColors.hinduOrange),
                _ReligionGlyphCard(id: 'sikhism', name: 'Sikhism', color: AppColors.sikhNavy),
                _ReligionGlyphCard(id: 'christianity', name: 'Christianity', color: AppColors.christianPurple),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cormorantGaramond(
                    color: fg, fontSize: 36, fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500, height: 1.08, letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  slide.body,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: muted, fontSize: 16, height: 1.55),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 20, 40, 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 220,
            height: 160,
            child: CustomPaint(
              painter: _IllustrationPainter(
                index: index,
                accent: accent,
                muted: muted,
                line: line,
              ),
            ),
          ),
          const SizedBox(height: 36),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(
              color: fg,
              fontSize: 36,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              height: 1.08,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: muted,
              fontSize: 16,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReligionGlyphCard extends StatelessWidget {
  const _ReligionGlyphCard({
    required this.id,
    required this.name,
    required this.color,
  });

  final String id;
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.nightSurface : Colors.white;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final line = isDark ? AppColors.nightLine : AppColors.boneLine;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: bg,
        border: Border.all(color: line),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ReligionGlyph(religionId: id, size: 28, color: color),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.inter(color: fg, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  const _IllustrationPainter({
    required this.index,
    required this.accent,
    required this.muted,
    required this.line,
  });

  final int index;
  final Color accent;
  final Color muted;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = accent;

    switch (index) {
      case 0:
        canvas.drawCircle(Offset(size.width * 0.27, size.height * 0.44), 22, stroke);
        canvas.drawCircle(Offset(size.width * 0.73, size.height * 0.44), 22, stroke);
        _drawDashedLine(
          canvas,
          stroke..strokeWidth = 1.0,
          Offset(size.width * 0.37, size.height * 0.44),
          Offset(size.width * 0.63, size.height * 0.44),
        );
        final fill = Paint()..color = accent..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(size.width * 0.27, size.height * 0.44), 3, fill);
        canvas.drawCircle(Offset(size.width * 0.73, size.height * 0.44), 3, fill);

      case 1:
        final gridStroke = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = line;
        for (var i = 0; i < 4; i++) {
          final col = i % 2;
          final row = i ~/ 2;
          final rect = RRect.fromRectAndRadius(
            Rect.fromLTWH(
              col == 0 ? 0 : size.width / 2 + 6,
              row == 0 ? 0 : size.height / 2 + 6,
              size.width / 2 - 12,
              size.height / 2 - 12,
            ),
            const Radius.circular(12),
          );
          canvas.drawRRect(rect, gridStroke);
        }

      case 2:
        final phoneStroke = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = accent;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * 0.27, 0, size.width * 0.45, size.height),
            const Radius.circular(14),
          ),
          phoneStroke,
        );
        final linePaint = Paint()..style = PaintingStyle.fill;
        linePaint.color = accent.withValues(alpha: 0.3);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.33, size.height * 0.25, size.width * 0.26, 7), const Radius.circular(3)), linePaint);
        linePaint.color = accent.withValues(alpha: 0.5);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.33, size.height * 0.38, size.width * 0.33, 7), const Radius.circular(3)), linePaint);
        linePaint.color = accent.withValues(alpha: 0.2);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.33, size.height * 0.54, size.width * 0.18, 7), const Radius.circular(3)), linePaint);
        final dot = Paint()..color = accent..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(size.width * 0.50, size.height * 0.82), 6, dot);
    }
  }

  void _drawDashedLine(Canvas canvas, Paint paint, Offset start, Offset end) {
    const dashLen = 3.0;
    const gapLen = 4.0;
    final total = (end - start).distance;
    final dir = (end - start) / total;
    var dist = 0.0;
    var dash = true;
    while (dist < total) {
      final seg = dash ? dashLen : gapLen;
      if (dash) {
        canvas.drawLine(
          start + dir * dist,
          start + dir * (dist + seg).clamp(0, total),
          paint,
        );
      }
      dist += seg;
      dash = !dash;
    }
  }

  @override
  bool shouldRepaint(_IllustrationPainter old) =>
      old.index != index || old.accent != accent;
}
