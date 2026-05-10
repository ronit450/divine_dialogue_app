import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/religion_provider.dart';
import '../../providers/user_provider.dart';
import '../../core/theme/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _progress;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0, 0.4, curve: Curves.easeIn),
    );
    _progress = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.2, 0.85, curve: Curves.easeInOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _navigate(ReligionState state) {
    if (_navigated) return;
    _navigated = true;

    if (state.signInDone) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        ref.read(userProvider.notifier).loadUser(uid);
      }
    }

    final delay = (state.signInDone && state.onboardingDone)
        ? const Duration(milliseconds: 600)
        : const Duration(milliseconds: 2600);
    Future.delayed(delay, () {
      if (!mounted) return;
      if (state.onboardingDone) {
        context.go('/home');
      } else {
        context.go('/onboarding');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(religionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    const accent = AppColors.islamGreen;

    if (state.isLoaded) _navigate(state);

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: MediaQuery.of(context).size.height * 0.32 - 260,
            left: MediaQuery.of(context).size.width / 2 - 260,
            child: Container(
              width: 520,
              height: 520,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accent.withValues(alpha: 0.09),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.6],
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: _fade,
            child: Column(
              children: [
                const Spacer(),
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CustomPaint(painter: _RingsPainter(accent: accent)),
                ),
                const SizedBox(height: 32),
                Text(
                  'Divine Chat',
                  style: GoogleFonts.cormorantGaramond(
                    color: fg,
                    fontSize: 44,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.5,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'A CONVERSATION WITH FAITH',
                  style: GoogleFonts.jetBrainsMono(
                    color: muted,
                    fontSize: 10,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(60, 0, 60, 60),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: AnimatedBuilder(
                          animation: _progress,
                          builder: (context, child) => LinearProgressIndicator(
                            value: _progress.value,
                            backgroundColor: accent.withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation(accent),
                            minHeight: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'PREPARING SACRED TEXTS',
                        style: GoogleFonts.jetBrainsMono(
                          color: muted,
                          fontSize: 10,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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

class _RingsPainter extends CustomPainter {
  const _RingsPainter({required this.accent});
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final fill = Paint()
      ..color = accent
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    const r = 42.0;

    canvas.drawCircle(Offset(cx - 14, cy), r, stroke);
    canvas.drawCircle(Offset(cx + 14, cy), r, stroke);
    canvas.drawCircle(Offset(cx, cy), 6, fill);
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.accent != accent;
}
