import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/religion_provider.dart';
import '../../providers/user_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final ageText = _ageController.text.trim();
    if (firstName.isEmpty || lastName.isEmpty || ageText.isEmpty) return false;
    final age = int.tryParse(ageText);
    return age != null && age >= 13 && age <= 120;
  }

  Future<void> _handleContinue() async {
    if (!_isFormValid || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final photoUrl = FirebaseAuth.instance.currentUser?.photoURL;

      await ref.read(userProvider.notifier).createUser(
            uid: uid,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            age: int.parse(_ageController.text.trim()),
            photoUrl: photoUrl,
          );

      if (mounted) context.go('/onboarding/religion');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(religionProvider);
    final accent = state.selectedReligion?.accentColor ?? AppColors.islamGreen;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final line = isDark ? AppColors.nightLine : AppColors.boneLine;
    final bg = isDark ? AppColors.nightBg : AppColors.boneBg;

    return Scaffold(
      backgroundColor: bg,
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
                  GestureDetector(
                    onTap: () => context.go('/sign-in'),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: line),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 14,
                        color: fg,
                      ),
                    ),
                  ),
                  Text(
                    'PROFILE · SETUP',
                    style: GoogleFonts.jetBrainsMono(
                      color: muted,
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Tell us about\nyourself.',
                style: GoogleFonts.cormorantGaramond(
                  color: fg,
                  fontSize: 38,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  height: 1.05,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'So we can greet you properly.',
                style: GoogleFonts.inter(
                  color: muted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),
              _ProfileField(
                label: 'First Name',
                placeholder: 'e.g. Sarah',
                controller: _firstNameController,
                fg: fg,
                muted: muted,
                line: line,
                accent: accent,
                onChanged: (_) => setState(() {}),
              ),
              _ProfileField(
                label: 'Last Name',
                placeholder: 'e.g. Al-Rashid',
                controller: _lastNameController,
                fg: fg,
                muted: muted,
                line: line,
                accent: accent,
                onChanged: (_) => setState(() {}),
              ),
              _ProfileField(
                label: 'Age',
                placeholder: 'e.g. 28',
                controller: _ageController,
                fg: fg,
                muted: muted,
                line: line,
                accent: accent,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: (_isFormValid && !_isSubmitting)
                      ? _handleContinue
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _isFormValid
                        ? accent
                        : (isDark
                            ? AppColors.nightSurface
                            : AppColors.boneSurface),
                    shape: const StadiumBorder(),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Continue',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _isFormValid ? Colors.white : muted,
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
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.placeholder,
    required this.controller,
    required this.fg,
    required this.muted,
    required this.line,
    required this.accent,
    required this.onChanged,
    this.keyboardType,
    this.inputFormatters,
  });

  final String label;
  final String placeholder;
  final TextEditingController controller;
  final Color fg;
  final Color muted;
  final Color line;
  final Color accent;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: line)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      margin: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(
              color: muted,
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            style: GoogleFonts.inter(
              color: fg,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: GoogleFonts.inter(
                color: muted,
                fontSize: 17,
                fontWeight: FontWeight.w400,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
