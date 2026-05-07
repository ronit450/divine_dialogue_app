import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/religion_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/religion.dart';
import '../../shared/widgets/glass_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final religionState = ref.watch(religionProvider);
    final themeMode = ref.watch(themeModeProvider);
    final religion = religionState.selectedReligion;
    final accent = religion != null
        ? ReligionColors.accent(religion.id)
        : AppColors.islamGold;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accent.withValues(alpha: 0.12),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: Icon(Icons.person_rounded,
                                color: accent, size: 32),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            religion?.name ?? 'Guest',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            religionState.selectedText?.title ??
                                'No text selected',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _SectionLabel(label: 'TRADITION'),
                    const SizedBox(height: 10),
                    GlassCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: religionState.religions
                            .asMap()
                            .entries
                            .map((e) {
                          final r = e.value;
                          final isSelected = r.id == religion?.id;
                          final rAccent = ReligionColors.accent(r.id);
                          final isLast =
                              e.key == religionState.religions.length - 1;
                          return _ReligionRow(
                            religion: r,
                            accent: rAccent,
                            isSelected: isSelected,
                            showDivider: !isLast,
                            onTap: () => ref
                                .read(religionProvider.notifier)
                                .selectReligion(r),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel(label: 'APPEARANCE'),
                    const SizedBox(height: 10),
                    GlassCard(
                      padding: EdgeInsets.zero,
                      child: _ToggleRow(
                        icon: Icons.dark_mode_rounded,
                        label: 'Dark mode',
                        value: themeMode == ThemeMode.dark,
                        accent: accent,
                        onChanged: (_) =>
                            ref.read(themeModeProvider.notifier).toggle(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel(label: 'ABOUT'),
                    const SizedBox(height: 10),
                    GlassCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _InfoRow(label: 'Version', value: '1.0.0'),
                          const Divider(
                              height: 1, color: Color(0x1AFFFFFF)),
                          _InfoRow(
                            label: 'Traditions',
                            value:
                                '${religionState.religions.length} religions',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _ReligionRow extends StatelessWidget {
  const _ReligionRow({
    required this.religion,
    required this.accent,
    required this.isSelected,
    required this.showDivider,
    required this.onTap,
  });

  final ReligionModel religion;
  final Color accent;
  final bool isSelected;
  final bool showDivider;
  final VoidCallback onTap;

  static const _symbols = {
    'islam': '☪',
    'hinduism': '🕉',
    'sikhism': '☬',
    'christianity': '✝',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            color: Colors.transparent,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Text(
                  _symbols[religion.id] ?? '✦',
                  style: TextStyle(fontSize: 18, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    religion.name,
                    style: TextStyle(
                      color:
                          isSelected ? accent : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded,
                      color: accent, size: 18),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: Color(0x1AFFFFFF)),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style:
                    const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: accent,
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
          Text(value,
              style:
                  TextStyle(color: AppColors.textMuted, fontSize: 14)),
        ],
      ),
    );
  }
}
