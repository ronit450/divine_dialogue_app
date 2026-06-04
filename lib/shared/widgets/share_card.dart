import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.text,
    required this.reference,
    required this.religionId,
    this.translation,
  });

  final String text;
  final String reference;
  final String religionId;
  final String? translation;

  @override
  Widget build(BuildContext context) {
    final accent = ReligionColors.accent(religionId);
    final symbol = _symbol(religionId);

    return Container(
      width: 340,
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(symbol, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 20),
          Container(
            width: 32,
            height: 2,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            text,
            style: GoogleFonts.cormorantGaramond(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              height: 1.55,
            ),
          ),
          if (translation != null &&
              translation!.isNotEmpty &&
              translation != text) ...[
            const SizedBox(height: 14),
            Text(
              translation!,
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 13,
                height: 1.55,
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  '— $reference',
                  style: GoogleFonts.jetBrainsMono(
                    color: accent,
                    fontSize: 11,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                'Divine Dialogue',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _symbol(String id) => switch (id) {
        'islam' => '☪',
        'hinduism' => '🕉',
        'sikhism' => '☬',
        'christianity' => '✝',
        _ => '✦',
      };
}
