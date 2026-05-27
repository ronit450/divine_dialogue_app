// Converts Western Arabic digits (0-9) to Urdu-Indic numerals (۰-۹).
// Usage: '42'.urduNumerals  or  42.toUrdu()
// Only applies these in Urdu mode — check locale before calling.

extension UrduNumeralsString on String {
  String get urduNumerals {
    const w = '0123456789';
    const u = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    final buf = StringBuffer();
    for (final ch in runes) {
      final c = String.fromCharCode(ch);
      final idx = w.indexOf(c);
      buf.write(idx >= 0 ? u[idx] : c);
    }
    return buf.toString();
  }
}

extension UrduNumeralsInt on int {
  String toUrdu() => toString().urduNumerals;
}
