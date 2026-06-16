import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/religion_provider.dart';
import '../../providers/user_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key, this.isEditing = false});

  final bool isEditing;

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  int _selectedAge = 25;
  late final FixedExtentScrollController _ageScrollCtrl;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      final user = ref.read(userProvider).user;
      if (user != null) {
        _firstNameController.text = user.firstName;
        _lastNameController.text = user.lastName;
        _selectedAge = user.age;
      }
    } else {
      final displayName = FirebaseAuth.instance.currentUser?.displayName ?? '';
      if (displayName.isNotEmpty) {
        final parts = displayName.trim().split(' ');
        _firstNameController.text = parts.first;
        if (parts.length > 1) {
          _lastNameController.text = parts.sublist(1).join(' ');
        }
      }
    }
    _ageScrollCtrl = FixedExtentScrollController(initialItem: _selectedAge - 13);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageScrollCtrl.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _firstNameController.text.trim().isNotEmpty &&
        _lastNameController.text.trim().isNotEmpty;
  }

  Future<void> _handleContinue() async {
    if (!_isFormValid || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      if (widget.isEditing) {
        await ref.read(userProvider.notifier).updateUser(
              firstName: _firstNameController.text.trim(),
              lastName: _lastNameController.text.trim(),
              age: _selectedAge,
            );
        if (mounted) Navigator.of(context).pop();
      } else {
        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        final photoUrl = FirebaseAuth.instance.currentUser?.photoURL;

        await ref.read(userProvider.notifier).createUser(
              uid: uid,
              firstName: _firstNameController.text.trim(),
              lastName: _lastNameController.text.trim(),
              age: _selectedAge,
              photoUrl: photoUrl,
            );

        await ref.read(religionProvider.notifier).completeSignIn();
        if (mounted) context.go('/home');
      }
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
                    onTap: () => widget.isEditing
                        ? Navigator.of(context).pop()
                        : context.go('/sign-in'),
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
                    widget.isEditing ? 'EDIT DETAILS' : 'PROFILE · SETUP',
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
                widget.isEditing
                    ? 'Update your\ndetails.'
                    : 'Tell us about\nyourself.',
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
                widget.isEditing
                    ? 'Changes will reflect throughout the app.'
                    : 'So we can greet you properly.',
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
              // Age picker section
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: line))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'AGE',
                          style: GoogleFonts.jetBrainsMono(
                            color: muted,
                            fontSize: 10,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'OPTIONAL',
                          style: GoogleFonts.jetBrainsMono(
                            color: muted.withValues(alpha: 0.5),
                            fontSize: 9,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // center highlight
                          Center(
                            child: Container(
                              width: 52,
                              height: 80,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          RotatedBox(
                            quarterTurns: -1,
                            child: ListWheelScrollView.useDelegate(
                              controller: _ageScrollCtrl,
                              itemExtent: 52,
                              perspective: 0.002,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (i) =>
                                  setState(() => _selectedAge = i + 13),
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: 88,
                                builder: (context, i) {
                                  final age = i + 13;
                                  final isSelected = age == _selectedAge;
                                  return RotatedBox(
                                    quarterTurns: 1,
                                    child: Center(
                                      child: AnimatedDefaultTextStyle(
                                        duration:
                                            const Duration(milliseconds: 150),
                                        style: GoogleFonts.inter(
                                          fontSize: isSelected ? 22 : 15,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: isSelected
                                              ? accent
                                              : muted.withValues(alpha: 0.5),
                                        ),
                                        child: Text('$age'),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed:
                      (_isFormValid && !_isSubmitting) ? _handleContinue : null,
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
                          widget.isEditing ? 'Save Changes' : 'Continue',
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
  });

  final String label;
  final String placeholder;
  final TextEditingController controller;
  final Color fg;
  final Color muted;
  final Color line;
  final Color accent;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
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
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: line),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: accent, width: 1.5),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.only(bottom: 8),
            ),
          ),
        ],
      ),
    );
  }
}
