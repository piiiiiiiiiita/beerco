import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFFF59E0B);
  static const primarySoft = Color(0xFFFEF3C7);
  static const success = Color(0xFF059669);
  static const successSoft = Color(0xFFD1FAE5);
  static const successDark = Color(0xFF10B981);
  static const danger = Color(0xFFDC2626);
  static const dangerSoft = Color(0xFFFEE2E2);
  static const dangerDark = Color(0xFFEF4444);

  // Light
  static const backgroundLight = Color(0xFFF8FAFC);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const onSurfaceLight = Color(0xFF0F172A);
  static const mutedLight = Color(0xFF64748B);
  static const borderLight = Color(0xFFE2E8F0);
  static const chipLight = Color(0xFFF8FAFC);
  static const darkButton = Color(0xFF0F172A);

  // Dark
  static const backgroundDark = Color(0xFF111111);
  static const surfaceDark = Color(0xFF1E1E1E);
  static const onSurfaceDark = Color(0xFFF0F0F0);
  static const mutedDark = Color(0xFF6B6B6B);
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.onSurfaceLight,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.backgroundLight.withValues(alpha: 0.94),
        foregroundColor: AppColors.onSurfaceLight,
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.onSurfaceLight,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.chipLight,
        hintStyle: GoogleFonts.inter(
          color: AppColors.mutedLight,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkButton,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 58),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onSurfaceLight,
          backgroundColor: AppColors.surfaceLight,
          minimumSize: const Size(0, 54),
          side: const BorderSide(color: AppColors.borderLight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.darkButton,
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.onSurfaceDark,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
