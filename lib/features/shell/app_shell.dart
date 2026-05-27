import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/religion_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_strings.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1.0,
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shell.currentIndex != widget.shell.currentIndex) {
      _fadeCtrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(religionProvider);
    final accent = state.selectedReligion?.accentColor ?? AppColors.islamGreen;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: widget.shell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.shell.goBranch(0);
      },
      child: Scaffold(
        body: FadeTransition(opacity: _fadeAnim, child: widget.shell),
        bottomNavigationBar: _NavBar(
          currentIndex: widget.shell.currentIndex,
          accent: accent,
          isDark: isDark,
          onTap: (i) => widget.shell.goBranch(
            i,
            initialLocation: i == widget.shell.currentIndex,
          ),
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.currentIndex,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  final int currentIndex;
  final Color accent;
  final bool isDark;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final borderColor = isDark ? AppColors.nightLine : AppColors.boneLine;
    final bgColor = isDark
        ? AppColors.nightBg.withValues(alpha: 0.88)
        : AppColors.boneBg.withValues(alpha: 0.88);
    final s = AppStrings.of(context);
    final labels = [s.tabHome, s.tabRead, s.tabSelf];

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(bottom: bottomPad),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(top: BorderSide(color: borderColor, width: 0.5)),
          ),
          child: Row(
            children: List.generate(3, (i) {
              final active = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: CustomPaint(
                            painter: _IconPainter(
                              index: i,
                              color: active ? accent : muted,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          labels[i],
                          style: s.isUrdu
                              ? GoogleFonts.notoNastaliqUrdu(
                                  fontSize: 11,
                                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                                  color: active ? accent : muted,
                                  height: 1.0,
                                )
                              : GoogleFonts.jetBrainsMono(
                                  fontSize: 9,
                                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                                  color: active ? accent : muted,
                                  letterSpacing: 0.5,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _IconPainter extends CustomPainter {
  const _IconPainter({required this.index, required this.color});
  final int index;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = size.width;
    final h = size.height;

    switch (index) {
      case 0: // Home
        final path = Path()
          ..moveTo(w * 0.15, h * 0.45)
          ..lineTo(w * 0.5, h * 0.1)
          ..lineTo(w * 0.85, h * 0.45)
          ..lineTo(w * 0.85, h * 0.9)
          ..lineTo(w * 0.6, h * 0.9)
          ..lineTo(w * 0.6, h * 0.6)
          ..lineTo(w * 0.4, h * 0.6)
          ..lineTo(w * 0.4, h * 0.9)
          ..lineTo(w * 0.15, h * 0.9)
          ..close();
        canvas.drawPath(path, p);

      case 1: // Read (open book)
        canvas.drawLine(Offset(w * 0.5, h * 0.15), Offset(w * 0.5, h * 0.85), p);
        final left = Path()
          ..moveTo(w * 0.15, h * 0.2)
          ..lineTo(w * 0.5, h * 0.3)
          ..lineTo(w * 0.5, h * 0.85)
          ..lineTo(w * 0.15, h * 0.75)
          ..close();
        canvas.drawPath(left, p);
        final right = Path()
          ..moveTo(w * 0.85, h * 0.2)
          ..lineTo(w * 0.5, h * 0.3)
          ..lineTo(w * 0.5, h * 0.85)
          ..lineTo(w * 0.85, h * 0.75)
          ..close();
        canvas.drawPath(right, p);

      case 2: // Self
        canvas.drawCircle(Offset(w * 0.5, h * 0.35), w * 0.18, p);
        final curve = Path()
          ..moveTo(w * 0.15, h * 0.9)
          ..quadraticBezierTo(w * 0.5, h * 0.58, w * 0.85, h * 0.9);
        canvas.drawPath(curve, p);
    }
  }

  @override
  bool shouldRepaint(_IconPainter old) => old.color != color || old.index != index;
}
