import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/religion_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/religion.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(religionProvider);
    final religions = state.religions;
    final selected = state.selectedReligion;

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
                      'Library',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Browse sacred texts across traditions',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _ReligionSection(
                  religion: religions[i],
                  selectedReligionId: selected?.id,
                  selectedTextId: state.selectedText?.id,
                ),
                childCount: religions.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _ReligionSection extends ConsumerStatefulWidget {
  const _ReligionSection({
    required this.religion,
    required this.selectedReligionId,
    required this.selectedTextId,
  });

  final ReligionModel religion;
  final String? selectedReligionId;
  final String? selectedTextId;

  @override
  ConsumerState<_ReligionSection> createState() => _ReligionSectionState();
}

class _ReligionSectionState extends ConsumerState<_ReligionSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.religion.id == widget.selectedReligionId;
  }

  @override
  Widget build(BuildContext context) {
    final accent = ReligionColors.accent(widget.religion.id);
    final isActiveReligion = widget.religion.id == widget.selectedReligionId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isActiveReligion
                        ? accent.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActiveReligion
                          ? accent.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _symbol(widget.religion.id),
                        style: TextStyle(fontSize: 22, color: accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.religion.name,
                              style: TextStyle(
                                color: isActiveReligion
                                    ? accent
                                    : AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${widget.religion.texts.length} texts',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_expanded)
            ...widget.religion.texts.map((text) {
              final isActive = text.id == widget.selectedTextId &&
                  widget.religion.id == widget.selectedReligionId;
              return Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: GestureDetector(
                  onTap: () {
                    ref
                        .read(religionProvider.notifier)
                        .selectReligion(widget.religion);
                    ref.read(religionProvider.notifier).selectText(text);
                    context.go('/chat');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isActive
                          ? accent.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive
                            ? accent.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          size: 16,
                          color: isActive ? accent : AppColors.textMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            text.title,
                            style: TextStyle(
                              color: isActive
                                  ? accent
                                  : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (isActive)
                          Icon(Icons.check_rounded, color: accent, size: 14),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  String _symbol(String id) => switch (id) {
    'islam' => '☪',
    'hinduism' => '🕉',
    'sikhism' => '☬',
    'christianity' => '✝',
    _ => '✦',
  };
}
