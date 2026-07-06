import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.slate950,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColors.slate100,
        displayColor: AppColors.slate100,
      ),
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.indigo600,
        surface: AppColors.slate900,
        onSurface: AppColors.slate100,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.slate900,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: _inputTheme(
        fill: AppColors.slate950.withOpacity(0.8),
        border: AppColors.white10,
        hint: AppColors.slate400,
      ),
      dividerColor: AppColors.white10,
    );
  }

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.lightBg,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColors.lightText,
        displayColor: AppColors.lightText,
      ),
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.indigo600,
        surface: Colors.white,
        onSurface: AppColors.lightText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.lightText,
      ),
      inputDecorationTheme: _inputTheme(
        fill: Colors.white,
        border: const Color(0x1A0F172A),
        hint: AppColors.slate500,
      ),
      dividerColor: const Color(0x1A0F172A),
    );
  }

  static InputDecorationTheme _inputTheme({
    required Color fill,
    required Color border,
    required Color hint,
  }) {
    OutlineInputBorder side(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c),
        );
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      hintStyle: GoogleFonts.inter(color: hint, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: side(border),
      enabledBorder: side(border),
      focusedBorder: side(AppColors.indigo500),
    );
  }
}
