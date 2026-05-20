import 'package:flutter/material.dart';

class AppColors {
  static const bg          = Color(0xFF0F1419);
  static const surface     = Color(0xFF1A1F26);
  static const surfaceAlt  = Color(0xFF2A2F36);
  static const text        = Color(0xFFF1F3F5);
  static const textMuted   = Color(0xFFADB5BD);
  static const textDim     = Color(0xFF6C757D);

  static const primary     = Color(0xFF845EF7);
  static const vocab       = Color(0xFF339AF0);
  static const grammar     = Color(0xFFF59F00);
  static const listen      = Color(0xFF51CF66);
  static const hangul      = Color(0xFFE64980);

  static const success     = Color(0xFF51CF66);
  static const danger      = Color(0xFFFA5252);
  static const warning     = Color(0xFFFAB005);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bg,
        primaryColor: AppColors.primary,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.vocab,
          surface: AppColors.surface,
          onSurface: AppColors.text,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bg,
          foregroundColor: AppColors.text,
          centerTitle: false,
          elevation: 0,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            foregroundColor: AppColors.text,
            side: const BorderSide(color: AppColors.surfaceAlt, width: 1.5),
          ),
        ),
      );
}
