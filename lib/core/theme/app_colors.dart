import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Bone palette (light)
  static const boneBg = Color(0xFFFAFAF7);
  static const boneSurface = Color(0xFFF0EFEA);
  static const boneFg = Color(0xFF1C1C1C);
  static const boneMuted = Color(0x801C1C1C);
  static const boneLine = Color(0x1A000000);

  // Night palette (dark)
  static const nightBg = Color(0xFF15130F);
  static const nightSurface = Color(0xFF221E18);
  static const nightFg = Color(0xFFF4EDE0);
  static const nightMuted = Color(0x8CF4EDE0);
  static const nightLine = Color(0x1FF4EDE0);

  // Glass
  static const glassLight = Color(0x99FFFFFF);
  static const glassDark = Color(0x33000000);
  static const glassBorderLight = Color(0x33FFFFFF);
  static const glassBorderDark = Color(0x1A000000);

  // Religion accents (match design RELIGIONS array)
  static const islamGreen = Color(0xFF1F5D4C);
  static const islamGreenSoft = Color(0xFFE8EFE8);
  static const hinduOrange = Color(0xFFA8521B);
  static const hinduOrangeSoft = Color(0xFFF4EAD8);
  static const sikhNavy = Color(0xFF1E4D6B);
  static const sikhNavySoft = Color(0xFFDDE7EE);
  static const christianPurple = Color(0xFF5D4A8A);
  static const christianPurpleSoft = Color(0xFFEBE6F0);

  static const error = Color(0xFFB00020);

  // Legacy aliases to avoid breaking unconverted callers
  static const bg = nightBg;
  static const bgSecondary = nightSurface;
  static const surface = nightSurface;
  static const textPrimary = nightFg;
  static const textSecondary = nightMuted;
  static const textMuted = Color(0x4DF4EDE0);
  static const islamGold = islamGreen;
  static const islamGoldDim = Color(0x331F5D4C);
  static const hinduSaffron = hinduOrange;
  static const hinduSaffronDim = Color(0x33A8521B);
  static const sikhBlue = sikhNavy;
  static const sikhBlueDim = Color(0x331E4D6B);
  static const christianIndigo = christianPurple;
  static const christianIndigoDim = Color(0x335D4A8A);
  static const userBubble = Color(0xFF1A2535);
  static const aiBubble = nightSurface;
  static const glassWhite = Color(0x0FFFFFFF);
  static const glassBorder = Color(0x1AFFFFFF);
  static const glassHighlight = Color(0x26FFFFFF);
}

class ReligionColors {
  ReligionColors._();

  static Color accent(String id) => switch (id) {
    'islam' => AppColors.islamGreen,
    'hinduism' => AppColors.hinduOrange,
    'sikhism' => AppColors.sikhNavy,
    'christianity' => AppColors.christianPurple,
    _ => AppColors.islamGreen,
  };

  static Color soft(String id) => switch (id) {
    'islam' => AppColors.islamGreenSoft,
    'hinduism' => AppColors.hinduOrangeSoft,
    'sikhism' => AppColors.sikhNavySoft,
    'christianity' => AppColors.christianPurpleSoft,
    _ => AppColors.islamGreenSoft,
  };

  static Color dim(String id) => accent(id).withValues(alpha: 0.2);
}
