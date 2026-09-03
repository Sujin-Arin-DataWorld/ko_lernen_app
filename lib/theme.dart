import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
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

      // ── Page transitions §B1(2026-09-03) ────────────────────────────
      // 플랫폼 네이티브 전환 — Android predictive-back, iOS/macOS
      // Cupertino 슬라이드, 그 외(Windows/Linux/Fuchsia)는 fade-upwards.
      // `SoriTransitions.page`(`SoriPageRoute`, 표준 MaterialPageRoute
      // 서브타입)를 쓰는 모든 라우트가 이 테마를 통해 애니메이션을 받는다.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
        },
      ),

      // ── AppBar ───────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: s.bg,
        foregroundColor: s.text,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: s.text,
          // §W-A2 b (2026-09-03): SoriAppBar 의 chromeTitle 과 동일 스펙으로
          // 수렴 — SoriTypeSpecs.chromeTitle 단일 원천(20/w700/-0.2).
          fontFamily: SoriFonts.sans,
          fontWeight: SoriTypeSpecs.chromeTitle.weight,
          fontSize: SoriTypeSpecs.chromeTitle.size,
          letterSpacing: SoriTypeSpecs.chromeTitle.letterSpacing,
        ),
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
          fontSize: 13.5,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontFamily: SoriFonts.sans,
          fontWeight: FontWeight.w700,
          fontSize: 13.5,
        ),
        side: BorderSide(color: s.border),
        shape: RoundedRectangleBorder(borderRadius: SoriRadius.brPill),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          fontSize: 13.5,
        ),
      ),

      // ── NavigationBar ────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: s.surface,
        indicatorColor: primary.withValues(alpha: 0.22),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: SoriFonts.sans,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? primary : s.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? primary : s.textMuted,
            size: 24,
          );
        }),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),

      // ── Typography ───────────────────────────────────────────────────
      textTheme: _buildTextTheme(s),
    );
  }

  static TextTheme _buildTextTheme(SoriSurfaces s) {
    // 2026-09-03 단일 원천화(§A4): displayLarge~headlineSmall 은
    // SoriTextTheme 값을 그대로 재사용해 스케일이 갈라지지 못하게 한다.
    // titleLarge~labelSmall 은 SoriTextTheme 에 대응 토큰이 없는 Material
    // 전용 역할이라 여기서만 값을 정의한다.
    final tt = SoriTextTheme.forSurfaces(s);

    TextStyle base(
      double size,
      FontWeight w, {
      double height = 1.4,
      double spacing = 0,
      Color? color,
    }) => TextStyle(
      fontFamily: SoriFonts.sans,
      fontSize: size,
      fontWeight: w,
      height: height,
      letterSpacing: spacing,
      color: color ?? s.text,
    );

    return TextTheme(
      displayLarge: tt.hero,
      displayMedium: tt.display,
      displaySmall: tt.h1,
      headlineLarge: tt.h1,
      headlineMedium: tt.h2,
      headlineSmall: tt.h3,
      titleLarge: base(18, FontWeight.w700, height: 1.4),
      titleMedium: base(16, FontWeight.w600, height: 1.4),
      titleSmall: base(14, FontWeight.w600, height: 1.4, color: s.textMuted),
      bodyLarge: base(17, FontWeight.w500, height: 1.5),
      bodyMedium: base(16, FontWeight.w500, height: 1.5),
      bodySmall: base(14, FontWeight.w500, height: 1.5, color: s.textMuted),
      labelLarge: base(15, FontWeight.w700),
      labelMedium: base(13.5, FontWeight.w700, color: s.textMuted),
      labelSmall: base(13, FontWeight.w700, color: s.textMuted, spacing: 0.5),
    );
  }
}
