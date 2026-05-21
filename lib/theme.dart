import 'package:flutter/material.dart';
import 'services/palette_service.dart';
import 'widgets/sori/tokens.dart';

/// **레거시 AppColors** — 점진 마이그레이션 위해 유지.
/// 새 코드는 [SoriColors] / [SoriSurfaces] 사용. 5.7 Phase B에서 화면별로 교체.
class AppColors {
  // Brand → SoriColors
  static const primary     = SoriColors.primary;
  static const hangul      = SoriColors.hangul;
  static const success     = SoriColors.success;
  static const danger      = SoriColors.danger;
  static const warning     = SoriColors.warning;

  // Dark surface defaults (대부분 화면이 다크 모드만 가정)
  static const bg          = SoriColors.darkBg;
  static const surface     = SoriColors.darkSurface;
  static const surfaceAlt  = SoriColors.darkSurfaceAlt;
  static const text        = SoriColors.darkText;
  static const textMuted   = SoriColors.darkTextMuted;
  static const textDim     = SoriColors.darkTextDim;

  // 모듈별 컬러 (deprecated — Phase B에서 제거)
  // ignore: deprecated_member_use_from_same_package
  @Deprecated('use SoriColors.primary or SoriColors.info')
  static const vocab   = SoriColors.info;
  @Deprecated('use SoriColors.warning')
  static const grammar = SoriColors.warning;
  @Deprecated('use SoriColors.success')
  static const listen  = SoriColors.success;
}

/// Sori 테마 — 라이트/다크 + 단청/teal kill-switch variant 지원.
///
/// 기본 `.dark` / `.light` 게터는 단청 팔레트(v6.0). Teal 롤백은 [darkFor]/[lightFor]
/// 에 [PaletteVariant.teal] 전달. main.dart에서 [paletteVariantNotifier] 연결.
class AppTheme {
  static ThemeData get dark  => darkFor(PaletteVariant.dancheong);
  static ThemeData get light => lightFor(PaletteVariant.dancheong);

  static ThemeData darkFor(PaletteVariant v) => v == PaletteVariant.teal
      ? _build(SoriSurfaces.darkTeal, primary: SoriColorsTeal.primary)
      : _build(SoriSurfaces.dark,     primary: SoriColors.primary);

  static ThemeData lightFor(PaletteVariant v) => v == PaletteVariant.teal
      ? _build(SoriSurfaces.lightTeal, primary: SoriColorsTeal.primary)
      : _build(SoriSurfaces.light,     primary: SoriColors.primary);

  static ThemeData _build(SoriSurfaces s, {required Color primary}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor:  primary,
      brightness: s.brightness,
      primary:    primary,
      surface:    s.surface,
      onSurface:  s.text,
    );

    return ThemeData(
      brightness: s.brightness,
      useMaterial3: true,
      scaffoldBackgroundColor: s.bg,
      colorScheme: colorScheme,
      fontFamily: 'Pretendard',

      // ── AppBar ───────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: s.bg,
        foregroundColor: s.text,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: s.text,
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w800,
          fontSize: 18,
          letterSpacing: -0.3,
        ),
      ),

      // ── Buttons ──────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SoriRadius.lg)),
          textStyle: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: -0.2,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SoriRadius.lg)),
          foregroundColor: s.text,
          side: BorderSide(color: s.border, width: 1.5),
          textStyle: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),

      // ── Inputs ───────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: s.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border:        OutlineInputBorder(borderRadius: SoriRadius.brLg, borderSide: BorderSide(color: s.border)),
        enabledBorder: OutlineInputBorder(borderRadius: SoriRadius.brLg, borderSide: BorderSide(color: s.border)),
        focusedBorder: OutlineInputBorder(borderRadius: SoriRadius.brLg, borderSide: BorderSide(color: primary, width: 2)),
        hintStyle: TextStyle(color: s.textDim, fontWeight: FontWeight.w500),
      ),

      // ── Chips ────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: s.surface,
        selectedColor: primary,
        labelStyle: TextStyle(color: s.text, fontFamily: 'Pretendard', fontWeight: FontWeight.w600, fontSize: 12),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontFamily: 'Pretendard', fontWeight: FontWeight.w700, fontSize: 12),
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
        contentTextStyle: TextStyle(color: s.bg, fontFamily: 'Pretendard', fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: SoriRadius.brLg),
        behavior: SnackBarBehavior.floating,
      ),

      // ── ListTile ─────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        iconColor: s.textMuted,
        textColor: s.text,
        titleTextStyle: TextStyle(color: s.text, fontFamily: 'Pretendard', fontWeight: FontWeight.w600, fontSize: 15),
        subtitleTextStyle: TextStyle(color: s.textMuted, fontFamily: 'Pretendard', fontWeight: FontWeight.w500, fontSize: 12),
      ),

      // ── Typography ───────────────────────────────────────────────────
      textTheme: _buildTextTheme(s),
    );
  }

  static TextTheme _buildTextTheme(SoriSurfaces s) {
    TextStyle base(double size, FontWeight w, {double height = 1.4, double spacing = 0, Color? color}) => TextStyle(
      fontFamily: 'Pretendard',
      fontSize: size,
      fontWeight: w,
      height: height,
      letterSpacing: spacing,
      color: color ?? s.text,
    );

    return TextTheme(
      displayLarge:  base(44, FontWeight.w900, height: 1.1,  spacing: -1.5),
      displayMedium: base(36, FontWeight.w800, height: 1.1,  spacing: -1.0),
      displaySmall:  base(28, FontWeight.w800, height: 1.2,  spacing: -0.8),
      headlineLarge: base(24, FontWeight.w800, height: 1.25, spacing: -0.5),
      headlineMedium:base(20, FontWeight.w700, height: 1.3,  spacing: -0.3),
      headlineSmall: base(18, FontWeight.w700, height: 1.35, spacing: -0.2),
      titleLarge:    base(16, FontWeight.w700, height: 1.4),
      titleMedium:   base(14, FontWeight.w600, height: 1.4),
      titleSmall:    base(13, FontWeight.w600, height: 1.4, color: s.textMuted),
      bodyLarge:     base(15, FontWeight.w500, height: 1.5),
      bodyMedium:    base(14, FontWeight.w500, height: 1.5),
      bodySmall:     base(12, FontWeight.w500, height: 1.5, color: s.textMuted),
      labelLarge:    base(14, FontWeight.w700),
      labelMedium:   base(12, FontWeight.w700, color: s.textMuted),
      labelSmall:    base(11, FontWeight.w700, color: s.textMuted, spacing: 0.5),
    );
  }
}
