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
        // Smooth 4-pointed compass star, hollow centre
        return '<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">'
            '<path d="M16 2 C16 2 13.5 11 11 13.5 C8.5 16 2 16 2 16 C2 16 8.5 16 11 18.5 C13.5 21 16 30 16 30 C16 30 18.5 21 21 18.5 C23.5 16 30 16 30 16 C30 16 23.5 16 21 13.5 C18.5 11 16 2 16 2 Z" stroke="$color" stroke-width="1.3" stroke-linejoin="round"/>'
            '</svg>';
      case 'hinduism':
        // Dharma wheel: outer ring + hub circle + 8 spokes
        return '<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">'
            '<circle cx="16" cy="16" r="13.5" stroke="$color" stroke-width="1.3"/>'
            '<circle cx="16" cy="16" r="3.5" stroke="$color" stroke-width="1.3"/>'
            '<line x1="16" y1="3" x2="16" y2="12.5" stroke="$color" stroke-width="1.1"/>'
            '<line x1="16" y1="19.5" x2="16" y2="29" stroke="$color" stroke-width="1.1"/>'
            '<line x1="3" y1="16" x2="12.5" y2="16" stroke="$color" stroke-width="1.1"/>'
            '<line x1="19.5" y1="16" x2="29" y2="16" stroke="$color" stroke-width="1.1"/>'
            '<line x1="6.57" y1="6.57" x2="13.52" y2="13.52" stroke="$color" stroke-width="1.1"/>'
            '<line x1="18.48" y1="18.48" x2="25.43" y2="25.43" stroke="$color" stroke-width="1.1"/>'
            '<line x1="25.43" y1="6.57" x2="18.48" y2="13.52" stroke="$color" stroke-width="1.1"/>'
            '<line x1="13.52" y1="18.48" x2="6.57" y2="25.43" stroke="$color" stroke-width="1.1"/>'
            '</svg>';
      case 'sikhism':
        // Khanda simplified: outer circle + central blade + two curved quillons
        return '<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">'
            '<circle cx="16" cy="16" r="13.5" stroke="$color" stroke-width="1.3"/>'
            '<line x1="16" y1="6" x2="16" y2="26" stroke="$color" stroke-width="1.4" stroke-linecap="round"/>'
            '<path d="M10 11 C10 11 13 14 13 16 C13 18 10 21 10 21" stroke="$color" stroke-width="1.2" fill="none" stroke-linecap="round"/>'
            '<path d="M22 11 C22 11 19 14 19 16 C19 18 22 21 22 21" stroke="$color" stroke-width="1.2" fill="none" stroke-linecap="round"/>'
            '</svg>';
      case 'christianity':
      default:
        // Latin cross inside circle
        return '<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">'
            '<circle cx="16" cy="16" r="13.5" stroke="$color" stroke-width="1.3"/>'
            '<line x1="16" y1="7" x2="16" y2="25" stroke="$color" stroke-width="1.4" stroke-linecap="round"/>'
            '<line x1="10" y1="13" x2="22" y2="13" stroke="$color" stroke-width="1.4" stroke-linecap="round"/>'
            '</svg>';
    }
  }
}
