import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/theme/app_colors.dart';
import '../shared/widgets/share_card.dart';

Future<void> showShareSheet(
  BuildContext context, {
  required String text,
  required String reference,
  required String religionId,
  String? translation,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final bg = isDark ? AppColors.nightBg : AppColors.boneBg;
  final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
  final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
  final line = isDark ? AppColors.nightLine : AppColors.boneLine;
  final accent = ReligionColors.accent(religionId);

  final cardKey = GlobalKey();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: bg,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) {
      final maxHeight = MediaQuery.of(ctx).size.height * 0.85;
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: RepaintBoundary(
                    key: cardKey,
                    child: ShareCard(
                      text: text,
                      reference: reference,
                      religionId: religionId,
                      translation: translation,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _SheetButton(
                      label: 'Share text',
                      icon: Icons.short_text_rounded,
                      fg: fg,
                      line: line,
                      onTap: () {
                        Navigator.pop(ctx);
                        Share.share(
                            '$text\n\n— $reference\n\nShared via Divine Dialogue');
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SheetButton(
                      label: 'Share image',
                      icon: Icons.image_outlined,
                      fg: fg,
                      line: line,
                      accent: accent,
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _captureAndShare(cardKey, reference);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _captureAndShare(GlobalKey key, String filename) async {
  try {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final bytes = byteData.buffer.asUint8List();
    final dir = await getTemporaryDirectory();
    final safe = filename.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final file = await File('${dir.path}/$safe.png').writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)],
        text: 'Shared via Divine Dialogue');
  } catch (_) {}
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.icon,
    required this.fg,
    required this.line,
    required this.onTap,
    this.accent,
  });

  final String label;
  final IconData icon;
  final Color fg, line;
  final Color? accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent?.withValues(alpha: 0.5) ?? line),
          color: accent?.withValues(alpha: 0.06),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: accent ?? fg),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                  color: accent ?? fg,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
