import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/share_card_style_provider.dart';

class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.text,
    required this.reference,
    required this.religionId,
    this.translation,
    this.template = ShareCardTemplate.midnight,
  });

  final String text;
  final String reference;
  final String religionId;
  final String? translation;
  final ShareCardTemplate template;

  static const double cardWidth = 340;
  static const double cardHeight = 425;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: switch (template) {
          ShareCardTemplate.midnight => _MidnightCard(
              text: text,
              reference: reference,
              religionId: religionId,
              translation: translation,
            ),
          ShareCardTemplate.paper => _PaperCard(
              text: text,
              reference: reference,
              religionId: religionId,
              translation: translation,
            ),
          ShareCardTemplate.garden => _GardenCard(
              text: text,
              reference: reference,
              religionId: religionId,
              translation: translation,
            ),
        },
      ),
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────

TextStyle _verseStyle(String religionId, Color color) {
  const base = 22.0;
  return switch (religionId) {
    'islam' => GoogleFonts.amiri(
        color: color, fontSize: base * 1.18, height: 1.7, fontWeight: FontWeight.w400),
    'hinduism' => GoogleFonts.notoSerifDevanagari(
        color: color, fontSize: base * 0.96, height: 1.55, fontWeight: FontWeight.w400),
    'sikhism' => GoogleFonts.notoSerifGurmukhi(
        color: color, fontSize: base, height: 1.55, fontWeight: FontWeight.w400),
    _ => GoogleFonts.cormorantGaramond(
        color: color,
        fontSize: base * 0.9,
        height: 1.55,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic),
  };
}

bool _isRtl(String religionId) => religionId == 'islam';

Color _brightAccent(String religionId) => switch (religionId) {
      'islam' => const Color(0xFF5FA98C),
      'hinduism' => const Color(0xFFDC9356),
      'sikhism' => const Color(0xFF74AACB),
      'christianity' => const Color(0xFFA795CF),
      _ => const Color(0xFF74AACB),
    };

// ── DDMark ────────────────────────────────────────────────────────────────────

class _DDMark extends StatelessWidget {
  const _DDMark({required this.color, this.size = 22});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size), painter: _DDMarkPainter(color: color));
}

class _DDMarkPainter extends CustomPainter {
  const _DDMarkPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(
        c,
        size.width * 0.44,
        Paint()
          ..color = color.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);
    canvas.drawCircle(
        c,
        size.width * 0.283,
        Paint()
          ..color = color.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    canvas.drawCircle(c, size.width * 0.113, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_DDMarkPainter old) => old.color != color;
}

class _DDLogo extends StatelessWidget {
  const _DDLogo({required this.color, this.scale = 1.0});
  final Color color;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DDMark(color: color, size: 22 * scale),
        SizedBox(width: 9 * scale),
        Text(
          'Divine Chat',
          style: GoogleFonts.cormorantGaramond(
            color: color,
            fontSize: 19 * scale,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.05,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MIDNIGHT
// ══════════════════════════════════════════════════════════════════════════════

class _MidnightCard extends StatelessWidget {
  const _MidnightCard(
      {required this.text,
      required this.reference,
      required this.religionId,
      this.translation});
  final String text, reference, religionId;
  final String? translation;

  @override
  Widget build(BuildContext context) {
    final accent = _brightAccent(religionId);
    const ink = Color(0xFFF3ECE0);
    final muted = ink.withValues(alpha: 0.56);

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.6, -0.85),
                radius: 1.6,
                colors: [Color(0xFF211C14), Color(0xFF14110C), Color(0xFF0B0907)],
                stops: [0.0, 0.46, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          top: -60,
          right: -45,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [accent.withValues(alpha: 0.2), Colors.transparent],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _DDLogo(color: ink),
                  Text('VERSE',
                      style: GoogleFonts.jetBrainsMono(
                          color: muted, fontSize: 10, letterSpacing: 1.8)),
                ],
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 3,
                      decoration: BoxDecoration(
                          color: accent, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      text,
                      style: _verseStyle(religionId, ink),
                      textDirection:
                          _isRtl(religionId) ? TextDirection.rtl : TextDirection.ltr,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (translation != null && translation!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        translation!,
                        style: GoogleFonts.inter(color: muted, fontSize: 14, height: 1.6),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: ink.withValues(alpha: 0.13)))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('— $reference',
                          style: GoogleFonts.jetBrainsMono(
                              color: accent, fontSize: 11, letterSpacing: 0.5)),
                    ),
                    Text('divinechat.app',
                        style: GoogleFonts.inter(
                            color: muted, fontSize: 10, letterSpacing: 0.2)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PAPER
// ══════════════════════════════════════════════════════════════════════════════

class _PaperCard extends StatelessWidget {
  const _PaperCard(
      {required this.text,
      required this.reference,
      required this.religionId,
      this.translation});
  final String text, reference, religionId;
  final String? translation;

  @override
  Widget build(BuildContext context) {
    final accent = ReligionColors.accent(religionId);
    const ink = Color(0xFF211D17);
    final muted = ink.withValues(alpha: 0.54);

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.56, -0.85),
                radius: 1.5,
                colors: [Color(0xFFFDFAF3), Color(0xFFF7F1E6), Color(0xFFF0E8D8)],
                stops: [0.0, 0.60, 1.0],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _DDLogo(color: accent),
                  Text('VERSE',
                      style: GoogleFonts.jetBrainsMono(
                          color: muted, fontSize: 10, letterSpacing: 1.8)),
                ],
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 3,
                      decoration: BoxDecoration(
                          color: accent, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      text,
                      style: _verseStyle(religionId, ink),
                      textDirection:
                          _isRtl(religionId) ? TextDirection.rtl : TextDirection.ltr,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (translation != null && translation!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        translation!,
                        style: GoogleFonts.inter(color: muted, fontSize: 14, height: 1.6),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: ink.withValues(alpha: 0.12)))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('— $reference',
                          style: GoogleFonts.jetBrainsMono(
                              color: accent, fontSize: 11, letterSpacing: 0.5)),
                    ),
                    Text('divinechat.app',
                        style: GoogleFonts.inter(
                            color: muted, fontSize: 10, letterSpacing: 0.2)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// GARDEN
// ══════════════════════════════════════════════════════════════════════════════

class _GardenCard extends StatelessWidget {
  const _GardenCard(
      {required this.text,
      required this.reference,
      required this.religionId,
      this.translation});
  final String text, reference, religionId;
  final String? translation;

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFF9A7C3C);
    const goldSoft = Color(0xFFC0A35E);
    const ink = Color(0xFF36291A);
    final muted = ink.withValues(alpha: 0.62);

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.8),
                radius: 1.4,
                colors: [Color(0xFFFBF4E2), Color(0xFFF4EAD2), Color(0xFFECDFC1)],
                stops: [0.0, 0.58, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Opacity(
              opacity: 0.16,
              child: CustomPaint(
                size: const Size(420, 420),
                painter: _RosettePainter(color: goldSoft),
              ),
            ),
          ),
        ),
        const Positioned(top: 14, left: 14, child: _Sprig(color: gold, size: 34)),
        Positioned(
          top: 14,
          right: 14,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(-1, 1, 1),
            child: const _Sprig(color: gold, size: 34),
          ),
        ),
        Positioned(
          bottom: 14,
          left: 14,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(1, -1, 1),
            child: const _Sprig(color: gold, size: 34),
          ),
        ),
        Positioned(
          bottom: 14,
          right: 14,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(-1, -1, 1),
            child: const _Sprig(color: gold, size: 34),
          ),
        ),
        Positioned(
          left: 22,
          right: 22,
          top: 22,
          bottom: 22,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: gold.withValues(alpha: 0.33)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 22),
          child: Column(
            children: [
              _DDLogo(color: gold, scale: 0.92),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _GardenDivider(color: gold),
                    const SizedBox(height: 18),
                    Text(
                      text,
                      style: _verseStyle(religionId, ink),
                      textDirection:
                          _isRtl(religionId) ? TextDirection.rtl : TextDirection.ltr,
                      textAlign: TextAlign.center,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (translation != null && translation!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        translation!,
                        style: GoogleFonts.cormorantGaramond(
                          color: muted,
                          fontSize: 17,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 18),
                    const _GardenDivider(color: gold),
                  ],
                ),
              ),
              Text(
                reference,
                style: GoogleFonts.jetBrainsMono(
                    color: gold, fontSize: 11, letterSpacing: 1.2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GardenDivider extends StatelessWidget {
  const _GardenDivider({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.transparent, color.withValues(alpha: 0.7)]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(width: 8, height: 8, color: color),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.7), Colors.transparent]),
            ),
          ),
        ),
      ],
    );
  }
}

class _Sprig extends StatelessWidget {
  const _Sprig({required this.color, this.size = 30});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size), painter: _SprigPainter(color: color));
}

class _SprigPainter extends CustomPainter {
  const _SprigPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 30;
    canvas.drawCircle(Offset(4 * s, 4 * s), 2.4 * s, Paint()..color = color);
    canvas.drawCircle(
        Offset(13 * s, 7 * s), 1.7 * s, Paint()..color = color.withValues(alpha: 0.7));
    canvas.drawCircle(
        Offset(7 * s, 13 * s), 1.7 * s, Paint()..color = color.withValues(alpha: 0.7));
    final path = Path()
      ..moveTo(19 * s, 19 * s)
      ..lineTo(22 * s, 16 * s)
      ..lineTo(25 * s, 19 * s)
      ..lineTo(22 * s, 22 * s)
      ..close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(_SprigPainter old) => old.color != color;
}

class _RosettePainter extends CustomPainter {
  const _RosettePainter({required this.color});
  final Color color;

  void _drawRing(Canvas canvas, Offset center, int count, double rx, double ry,
      double dist, double opacity, double rotOffsetDeg) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < count; i++) {
      final angle = (rotOffsetDeg + i * 360.0 / count) * math.pi / 180;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      canvas.drawOval(
          Rect.fromCenter(center: Offset(0, -dist), width: rx * 2, height: ry * 2),
          paint);
      canvas.restore();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    _drawRing(canvas, c, 16, size.width * 0.038, size.height * 0.175,
        size.height * 0.205, 0.5, 0);
    _drawRing(canvas, c, 12, size.width * 0.052, size.height * 0.125,
        size.height * 0.10, 0.7, 15);
    canvas.drawCircle(
        c, size.width * 0.058, Paint()..color = color.withValues(alpha: 0.85));
    canvas.drawCircle(c, size.width * 0.022, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RosettePainter old) => old.color != color;
}
