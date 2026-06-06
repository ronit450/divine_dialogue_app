import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/religion_provider.dart';
import '../../core/theme/app_colors.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  bool _checking = false;
  bool _resending = false;
  bool _resent = false;

  String get _email =>
      FirebaseAuth.instance.currentUser?.email ?? '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(religionProvider);
    final accent = state.selectedReligion?.accentColor ?? AppColors.islamGreen;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final line = isDark ? AppColors.nightLine : AppColors.boneLine;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () async {
                  final router = GoRouter.of(context);
                  await FirebaseAuth.instance.signOut();
                  router.go('/sign-in');
                },
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: line),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: fg),
                ),
              ),
              const Spacer(),
              Icon(Icons.mark_email_unread_outlined, size: 52, color: accent),
              const SizedBox(height: 24),
              Text(
                'Check your\ninbox',
                style: GoogleFonts.cormorantGaramond(
                  color: fg, fontSize: 40, fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500, height: 1.05, letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We sent a verification link to',
                style: GoogleFonts.inter(color: muted, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 2),
              Text(
                _email,
                style: GoogleFonts.inter(
                  color: fg, fontSize: 15, fontWeight: FontWeight.w600, height: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Click the link in the email, then come back here.',
                style: GoogleFonts.inter(color: muted, fontSize: 15, height: 1.5),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _checking ? null : _checkVerified,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    shape: const StadiumBorder(),
                  ),
                  child: _checking
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          "I've verified my email",
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: _resent
                    ? Text(
                        'Email resent! Check your inbox.',
                        style: GoogleFonts.inter(color: accent, fontSize: 14, fontWeight: FontWeight.w500),
                      )
                    : GestureDetector(
                        onTap: _resending ? null : _resend,
                        child: _resending
                            ? SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(color: accent, strokeWidth: 2),
                              )
                            : RichText(
                                text: TextSpan(
                                  style: GoogleFonts.inter(color: muted, fontSize: 14),
                                  children: [
                                    const TextSpan(text: "Didn't get it? "),
                                    TextSpan(
                                      text: 'Resend email',
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

  Future<void> _checkVerified() async {
    setState(() => _checking = true);
    try {
      final verified = await ref.read(authProvider.notifier).checkEmailVerified();
      if (!mounted) return;
      if (verified) {
        context.go('/profile-setup');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email not verified yet. Please click the link in your inbox first.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await ref.read(authProvider.notifier).resendVerificationEmail();
      if (mounted) setState(() { _resending = false; _resent = true; });
    } on Exception {
      if (mounted) setState(() => _resending = false);
    }
  }
}
