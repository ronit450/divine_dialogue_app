import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ReligionGlyph extends StatelessWidget {
  const ReligionGlyph({
    super.key,
    required this.religionId,
    this.size = 28,
    this.color,
  });

  final String religionId;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    final hex = '#${c.toARGB32().toRadixString(16).substring(2)}';
    return SvgPicture.string(
      _svgFor(religionId, hex),
      width: size,
      height: size,
    );
  }

  static String _svgFor(String id, String color) {
    switch (id) {
      case 'islam':
        return '<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">'
            '<path d="M16 2 L20 12 L30 16 L20 20 L16 30 L12 20 L2 16 L12 12 Z" stroke="$color" stroke-width="1.4" stroke-linejoin="round"/>'
            '<path d="M16 6 L18.5 13.5 L26 16 L18.5 18.5 L16 26 L13.5 18.5 L6 16 L13.5 13.5 Z" stroke="$color" stroke-width="1" stroke-linejoin="round" opacity="0.6"/>'
            '</svg>';
      case 'hinduism':
        return '<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">'
            '<circle cx="16" cy="16" r="13" stroke="$color" stroke-width="1.2"/>'
            '<circle cx="16" cy="16" r="8" stroke="$color" stroke-width="1" opacity="0.6"/>'
            '<circle cx="16" cy="16" r="3" stroke="$color" stroke-width="1.2"/>'
            '<line x1="16" y1="3" x2="16" y2="29" stroke="$color" stroke-width="0.7" opacity="0.4"/>'
            '<line x1="3" y1="16" x2="29" y2="16" stroke="$color" stroke-width="0.7" opacity="0.4"/>'
            '<line x1="6.69" y1="6.69" x2="25.31" y2="25.31" stroke="$color" stroke-width="0.7" opacity="0.4"/>'
            '<line x1="25.31" y1="6.69" x2="6.69" y2="25.31" stroke="$color" stroke-width="0.7" opacity="0.4"/>'
            '</svg>';
      case 'sikhism':
        return '<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">'
            '<circle cx="16" cy="16" r="13" stroke="$color" stroke-width="1.2"/>'
            '<line x1="16" y1="5" x2="16" y2="27" stroke="$color" stroke-width="1.4"/>'
            '<path d="M9 12 Q16 16 9 20" stroke="$color" stroke-width="1" fill="none" opacity="0.7"/>'
            '<path d="M23 12 Q16 16 23 20" stroke="$color" stroke-width="1" fill="none" opacity="0.7"/>'
            '</svg>';
      case 'christianity':
      default:
        return '<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">'
            '<circle cx="16" cy="16" r="13" stroke="$color" stroke-width="1.2" opacity="0.6"/>'
            '<line x1="16" y1="6" x2="16" y2="26" stroke="$color" stroke-width="1.4"/>'
            '<line x1="10" y1="14" x2="22" y2="14" stroke="$color" stroke-width="1.4"/>'
            '</svg>';
    }
  }
}
