import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static TextTheme _buildTextTheme({required bool dark}) {
    final fg = dark ? AppColors.nightFg : AppColors.boneFg;
    final muted = dark ? AppColors.nightMuted : AppColors.boneMuted;
    final ultraMuted = dark ? const Color(0x4DF4EDE0) : const Color(0x4D1C1C1C);

    final display = GoogleFonts.cormorantGaramond(
      color: fg,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w500,
    );
    final mono = GoogleFonts.jetBrainsMono(
      color: muted,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.1,
    );

    // Geist not in google_fonts catalog — Inter is the closest clean UI sans-serif
    TextStyle ui(double size, FontWeight weight, {Color? color, double? height}) =>
        GoogleFonts.inter(color: color ?? fg, fontSize: size, fontWeight: weight, height: height);

    return TextTheme(
      displayLarge: display.copyWith(fontSize: 48, height: 1.1),
      displayMedium: display.copyWith(fontSize: 36, height: 1.15),
      displaySmall: display.copyWith(fontSize: 28, height: 1.2),
      headlineLarge: ui(24, FontWeight.w600),
      headlineMedium: ui(20, FontWeight.w600),
      headlineSmall: ui(17, FontWeight.w600),
      titleLarge: ui(16, FontWeight.w500),
      titleMedium: ui(14, FontWeight.w500),
      titleSmall: ui(12, FontWeight.w500, color: muted),
      bodyLarge: ui(15, FontWeight.w400, height: 1.6),
      bodyMedium: ui(13, FontWeight.w400, height: 1.55),
      bodySmall: ui(11, FontWeight.w400, color: muted, height: 1.5),
      labelLarge: mono.copyWith(fontSize: 11),
      labelMedium: mono.copyWith(fontSize: 10),
      labelSmall: mono.copyWith(fontSize: 9, color: ultraMuted),
    );
  }

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.boneBg,
    colorScheme: const ColorScheme.light(
      primary: AppColors.islamGreen,
      surface: AppColors.boneSurface,
      onSurface: AppColors.boneFg,
      onPrimary: Colors.white,
      outline: AppColors.boneLine,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      titleTextStyle: GoogleFonts.inter(
        color: AppColors.boneFg,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: AppColors.boneFg),
    ),
    textTheme: _buildTextTheme(dark: false),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      border: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.boneLine),
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.boneLine),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.islamGreen, width: 1.5),
      ),
      hintStyle: GoogleFonts.inter(color: AppColors.boneMuted, fontSize: 15),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.nightBg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.islamGreen,
      surface: AppColors.nightSurface,
      onSurface: AppColors.nightFg,
      onPrimary: Colors.white,
      outline: AppColors.nightLine,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: GoogleFonts.inter(
        color: AppColors.nightFg,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: AppColors.nightFg),
    ),
    textTheme: _buildTextTheme(dark: true),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      border: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.nightLine),
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.nightLine),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.islamGreen, width: 1.5),
      ),
      hintStyle: GoogleFonts.inter(color: AppColors.nightMuted, fontSize: 15),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
