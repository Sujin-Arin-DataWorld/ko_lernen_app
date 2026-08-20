import 'package:flutter/material.dart';
import 'services/palette_service.dart';
import 'widgets/sori/tokens.dart';

/// Sori 테마 — 라이트/다크 + 단청/teal kill-switch variant 지원.
///
/// 기본 `.dark` / `.light` 게터는 단청 팔레트(v6.0). Teal 롤백은 [darkFor]/[lightFor]
/// 에 [PaletteVariant.teal] 전달. main.dart에서 [paletteVariantNotifier] 연결.
class AppTheme {
  static ThemeData get dark => darkFor(PaletteVariant.dancheong);
  static ThemeData get light => lightFor(PaletteVariant.dancheong);

  static ThemeData darkFor(PaletteVariant v) => v == PaletteVariant.teal
      ? _build(SoriSurfaces.darkTeal, primary: SoriColorsTeal.primary)
      : _build(SoriSurfaces.dark, primary: SoriColors.primary);

  static ThemeData lightFor(PaletteVariant v) => v == PaletteVariant.teal
      ? _build(SoriSurfaces.lightTeal, primary: SoriColorsTeal.primary)
      : _build(SoriSurfaces.light, primary: SoriColors.primary);

  static ThemeData _build(SoriSurfaces s, {required Color primary}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: s.brightness,
      primary: primary,
      surface: s.surface,
      onSurface: s.text,
    );

    return ThemeData(
      brightness: s.brightness,
      useMaterial3: true,
      scaffoldBackgroundColor: s.bg,
      colorScheme: colorScheme,
      fontFamily: SoriFonts.sans,

      // ── AppBar ───────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: s.bg,
        foregroundColor: s.text,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        // 램프 h2 파생 (2026-08-19 — 두 램프 통합, Wanted Sans).
        titleTextStyle: _from(SoriTypeRamp.h2, s.text),
      ),

      // ── Buttons ──────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SoriRadius.lg),
          ),
          textStyle: const TextStyle(
            fontFamily: SoriFonts.sans,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: -0.2,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SoriRadius.lg),
          ),
          foregroundColor: s.text,
          side: BorderSide(color: s.border, width: 1.5),
          textStyle: const TextStyle(
            fontFamily: SoriFonts.sans,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontFamily: SoriFonts.sans,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),

      // ── Inputs ───────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: s.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: SoriRadius.brLg,
          borderSide: BorderSide(color: s.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: SoriRadius.brLg,
          borderSide: BorderSide(color: s.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: SoriRadius.brLg,
          borderSide: BorderSide(color: primary, width: 2),
        ),
        hintStyle: TextStyle(color: s.textDim, fontWeight: FontWeight.w500),
      ),

      // ── Chips ────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: s.surface,
        selectedColor: primary,
        labelStyle: TextStyle(
          color: s.text,
          fontFamily: SoriFonts.sans,
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontFamily: SoriFonts.sans,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
        side: BorderSide(color: s.border),
        shape: RoundedRectangleBorder(borderRadius: SoriRadius.brPill),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),

      // ── Progress ─────────────────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: s.surfaceAlt,
        linearMinHeight: 6,
      ),

      // ── Dividers ─────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(color: s.border, thickness: 1, space: 1),

      // ── Snackbar ─────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: s.text,
        contentTextStyle: TextStyle(
          color: s.bg,
          fontFamily: SoriFonts.sans,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: SoriRadius.brLg),
        behavior: SnackBarBehavior.floating,
      ),

      // ── ListTile ─────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        iconColor: s.textMuted,
        textColor: s.text,
        titleTextStyle: TextStyle(
          color: s.text,
          fontFamily: SoriFonts.sans,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        subtitleTextStyle: TextStyle(
          color: s.textMuted,
          fontFamily: SoriFonts.sans,
          fontWeight: FontWeight.w500,
          fontSize: 12.5,
        ),
      ),

      // ── NavigationBar ────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: s.surface,
        indicatorColor: primary.withValues(alpha: 0.16),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: SoriFonts.sans,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? primary : s.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? primary : s.textMuted,
            size: 22,
          );
        }),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),

      // ── Typography ───────────────────────────────────────────────────
      textTheme: _buildTextTheme(s),
    );
  }

  /// [SoriTypeRamp] 한 칸을 Material [TextStyle]로 옮긴다 — 램프가 유일한
  /// 소스이므로 여기서 값을 다시 적지 않는다.
  static TextStyle _from(SoriTypeRole r, Color color, {double? spacing}) =>
      TextStyle(
        fontFamily: SoriFonts.sans,
        fontSize: r.size,
        fontWeight: r.weight,
        height: r.height,
        letterSpacing: spacing ?? r.spacing,
        color: color,
      );

  static TextTheme _buildTextTheme(SoriSurfaces s) => TextTheme(
    displayLarge: _from(SoriTypeRamp.hero, s.text),
    displayMedium: _from(SoriTypeRamp.display, s.text),
    displaySmall: _from(SoriTypeRamp.koDisplaySm, s.text),
    headlineLarge: _from(SoriTypeRamp.h1, s.text),
    headlineMedium: _from(SoriTypeRamp.h2, s.text),
    headlineSmall: _from(SoriTypeRamp.h3, s.text),
    titleLarge: _from(SoriTypeRamp.cardTitle, s.text),
    titleMedium: _from(
      SoriTypeRamp.bodySmall,
      s.text,
    ).copyWith(fontWeight: FontWeight.w600),
    titleSmall: _from(SoriTypeRamp.label, s.textMuted),
    bodyLarge: _from(SoriTypeRamp.body, s.text),
    bodyMedium: _from(SoriTypeRamp.bodySmall, s.text),
    bodySmall: _from(SoriTypeRamp.caption, s.textMuted),
    labelLarge: _from(SoriTypeRamp.label, s.text),
    labelMedium: _from(SoriTypeRamp.meta, s.textMuted),
    labelSmall: _from(SoriTypeRamp.caption, s.textMuted, spacing: 0.3),
  );
}
