import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/religion_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _isSignup = true;
  bool _obscurePassword = true;
  bool _loading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(religionProvider.notifier).completeIntro();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(religionProvider);
    final introSeen = state.introSeen;
    final accent = state.selectedReligion?.accentColor ?? AppColors.islamGreen;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final line = isDark ? AppColors.nightLine : AppColors.boneLine;
    final bg = isDark ? AppColors.nightBg : AppColors.boneBg;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!introSeen)
                    GestureDetector(
                      onTap: () => context.go('/onboarding/text'),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: line),
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: fg),
                      ),
                    )
                  else
                    const SizedBox(width: 36),
                  Text(
                    _isSignup ? 'NEW · ACCOUNT' : 'WELCOME · BACK',
                    style: GoogleFonts.jetBrainsMono(
                      color: muted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                _isSignup ? 'Begin your\ndialogue' : 'Welcome\nback',
                style: GoogleFonts.cormorantGaramond(
                  color: fg, fontSize: 40, fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500, height: 1.05, letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isSignup
                    ? 'A few details to start. You can ask anything after this.'
                    : 'Sign in to continue your conversations and saved verses.',
                style: GoogleFonts.inter(color: muted, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 36),
              _UnderlineField(
                label: 'Email',
                placeholder: 'you@example.com',
                fg: fg, muted: muted, line: line, accent: accent,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              _UnderlineField(
                label: 'Password',
                placeholder: '••••••••••',
                fg: fg, muted: muted, line: line, accent: accent,
                controller: _passwordController,
                obscure: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _loading ? null : _handleEmailAuth(),
                trailing: GestureDetector(
                  onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                  child: Text(
                    _obscurePassword ? 'Show' : 'Hide',
                    style: GoogleFonts.inter(color: accent, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              if (!_isSignup) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _loading ? null : _showForgotPasswordSheet,
                    child: Text(
                      'Forgot password?',
                      style: GoogleFonts.inter(color: accent, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _loading ? null : _handleEmailAuth,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    shape: const StadiumBorder(),
                  ),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          _isSignup ? 'Create account' : 'Sign in',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(color: line, thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR',
                      style: GoogleFonts.jetBrainsMono(color: muted, fontSize: 10, letterSpacing: 1.5),
                    ),
                  ),
                  Expanded(child: Divider(color: line, thickness: 1)),
                ],
              ),
              const SizedBox(height: 20),
              _SocialButton(
                label: 'Continue with Apple',
                fg: fg, line: line,
                icon: Icon(Icons.apple, color: fg, size: 20),
                onTap: _loading ? null : _handleApple,
              ),
              const SizedBox(height: 10),
              _SocialButton(
                label: 'Continue with Google',
                fg: fg, line: line,
                icon: SizedBox(
                  width: 18, height: 18,
                  child: CustomPaint(painter: _GooglePainter(bg: bg)),
                ),
                onTap: _loading ? null : _handleGoogle,
              ),
              const SizedBox(height: 10),
              _SocialButton(
                label: 'Continue as guest',
                fg: muted, line: line,
                icon: Icon(Icons.person_outline_rounded, color: muted, size: 20),
                onTap: _loading ? null : _handleGuest,
              ),
              const SizedBox(height: 28),
              Center(
                child: GestureDetector(
                  onTap: () => setState(() => _isSignup = !_isSignup),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(color: muted, fontSize: 14),
                      children: [
                        TextSpan(text: _isSignup ? 'Already with us? ' : 'New here? '),
                        TextSpan(
                          text: _isSignup ? 'Sign in' : 'Create account',
                          style: GoogleFonts.inter(
                            color: accent, fontWeight: FontWeight.w600, fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter your email and password.');
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showError('Please enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }

    setState(() => _loading = true);
    try {
      if (_isSignup) {
        await ref.read(authProvider.notifier).signUpWithEmail(email, password);
        if (mounted) context.go('/verify-email');
      } else {
        await ref.read(authProvider.notifier).signInWithEmail(email, password);
      }
    } on Exception catch (e) {
      if (mounted) _showError(_friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleGoogle() async {
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
    } on Exception catch (e) {
      if (mounted) _showError(_friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleApple() async {
    // Apple sign-in not yet implemented
    setState(() => _loading = true);
    if (mounted) context.go('/profile-setup');
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _handleGuest() async {
    setState(() => _loading = true);
    await ref.read(religionProvider.notifier).completeSignIn();
    if (mounted) context.go('/home');
    if (mounted) setState(() => _loading = false);
  }

  void _showForgotPasswordSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final line = isDark ? AppColors.nightLine : AppColors.boneLine;
    final surface = isDark ? AppColors.nightSurface : Colors.white;
    final accent = ref.read(religionProvider).selectedReligion?.accentColor ?? AppColors.islamGreen;

    final resetController = TextEditingController(text: _emailController.text);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        bool sending = false;
        bool sent = false;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                28, 28, 28,
                28 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reset password',
                    style: GoogleFonts.cormorantGaramond(
                      color: fg, fontSize: 28, fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "We'll send a reset link to your email.",
                    style: GoogleFonts.inter(color: muted, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  if (sent) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded, color: accent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Reset link sent! Check your inbox.',
                              style: GoogleFonts.inter(color: fg, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: line))),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: TextField(
                        controller: resetController,
                        keyboardType: TextInputType.emailAddress,
                        autofocus: true,
                        style: GoogleFonts.inter(color: fg, fontSize: 17, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'your@email.com',
                          hintStyle: GoogleFonts.inter(color: muted.withValues(alpha: 0.5), fontSize: 17),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: sending
                            ? null
                            : () async {
                                final email = resetController.text.trim();
                                if (email.isEmpty) return;
                                setSheetState(() => sending = true);
                                try {
                                  await ref.read(authProvider.notifier).sendPasswordResetEmail(email);
                                  setSheetState(() { sending = false; sent = true; });
                                } on Exception catch (e) {
                                  setSheetState(() => sending = false);
                                  if (mounted) _showError(_friendlyError(e.toString()));
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          shape: const StadiumBorder(),
                        ),
                        child: sending
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                'Send reset link',
                                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() => resetController.dispose());
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _friendlyError(String raw) {
    if (raw.contains('email-already-in-use')) return 'An account with this email already exists.';
    if (raw.contains('wrong-password') || raw.contains('invalid-credential')) return 'Incorrect email or password.';
    if (raw.contains('user-not-found')) return 'No account found with this email.';
    if (raw.contains('too-many-requests')) return 'Too many attempts. Please try again later.';
    if (raw.contains('network-request-failed')) return 'No internet connection.';
    if (raw.contains('weak-password')) return 'Password is too weak. Use at least 6 characters.';
    if (raw.contains('invalid-email')) return 'Invalid email address.';
    return raw.replaceAll('Exception: ', '');
  }
}

class _UnderlineField extends StatelessWidget {
  const _UnderlineField({
    required this.label,
    required this.placeholder,
    required this.fg,
    required this.muted,
    required this.line,
    required this.accent,
    required this.controller,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.trailing,
  });

  final String label;
  final String placeholder;
  final Color fg;
  final Color muted;
  final Color line;
  final Color accent;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: line))),
      padding: const EdgeInsets.symmetric(vertical: 8),
      margin: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(
              color: muted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  onSubmitted: onSubmitted,
                  style: GoogleFonts.inter(color: fg, fontSize: 17, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: placeholder,
                    hintStyle: GoogleFonts.inter(color: muted.withValues(alpha: 0.5), fontSize: 17),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.fg,
    required this.line,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Color fg;
  final Color line;
  final Widget icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: line),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text(label, style: GoogleFonts.inter(color: fg, fontSize: 15, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _GooglePainter extends CustomPainter {
  const _GooglePainter({required this.bg});
  final Color bg;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final p = Paint()..style = PaintingStyle.fill;
    const sweeps = [
      (Colors.red, -30.0, 75.0),
      (Colors.amber, 45.0, 90.0),
      (Colors.green, 135.0, 90.0),
      (Colors.blue, 225.0, 90.0),
    ];
    for (final (color, start, sweep) in sweeps) {
      p.color = color;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        start * 3.14159265 / 180,
        sweep * 3.14159265 / 180,
        true, p,
      );
    }
    p.color = bg;
    canvas.drawCircle(c, r * 0.6, p);
  }

  @override
  bool shouldRepaint(_GooglePainter old) => old.bg != bg;
}
