import 'package:flutter/material.dart';

/// Sori 디자인 토큰 — 색/공간/모서리/그림자 단일 소스 (5.7 디자인 리프레시).
///
/// 사용:
/// ```dart
/// padding: const EdgeInsets.all(Spacing.lg),
/// borderRadius: BorderRadius.circular(SoriRadius.md),
/// color: SoriColors.primary,
/// final s = SoriSurfaces.of(context);  // bg / surface / text 자동
/// ```

// ─────────────────────────────────────────────────────────────────────────
// SPACING — 8px-grid (modular scale)
// ─────────────────────────────────────────────────────────────────────────
class Spacing {
  static const double xs   = 4;    // 컴포넌트 내부 미세 간격
  static const double sm   = 8;    // 작은 갭
  static const double md   = 12;   // 중간 갭
  static const double lg   = 16;   // 표준 카드 padding
  static const double xl   = 24;   // 섹션 간격
  static const double xxl  = 32;   // 큰 섹션 간격
  static const double xxxl = 48;   // 화면 hero 간격

  static const EdgeInsets pageH       = EdgeInsets.symmetric(horizontal: 18);
  static const EdgeInsets cardInner   = EdgeInsets.all(16);
  static const EdgeInsets cardCompact = EdgeInsets.all(12);
}

// ─────────────────────────────────────────────────────────────────────────
// RADIUS — round corners scale
// ─────────────────────────────────────────────────────────────────────────
class SoriRadius {
  static const double xs    = 8;
  static const double sm    = 12;
  static const double md    = 16;   // default card
  static const double lg    = 20;   // hero card / large button
  static const double xl    = 24;
  static const double pill  = 999;  // chip / pill

  static const BorderRadius brSm   = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brMd   = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brLg   = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius brPill = BorderRadius.all(Radius.circular(pill));
}

// ─────────────────────────────────────────────────────────────────────────
// ELEVATION — subtle shadows (light mode visible; dark mode invisible OK)
// ─────────────────────────────────────────────────────────────────────────
class SoriElevation {
  /// Resting card.
  static const List<BoxShadow> low = [
    BoxShadow(color: Color(0x0F000000), offset: Offset(0, 1), blurRadius: 3),
  ];

  /// Hovered / pressed card.
  static const List<BoxShadow> medium = [
    BoxShadow(color: Color(0x14000000), offset: Offset(0, 4), blurRadius: 12),
  ];

  /// Hero / floating / modal.
  static const List<BoxShadow> high = [
    BoxShadow(color: Color(0x1F000000), offset: Offset(0, 8), blurRadius: 24),
  ];
}

// ─────────────────────────────────────────────────────────────────────────
// COLORS — brand + light + dark
// ─────────────────────────────────────────────────────────────────────────
class SoriColors {
  // ── Brand v3 (Indigo + Tiger + Gold) ─────────────────────────────────
  // 단청 청 (Korean indigo) — replaces Sori Purple. 다른 한국어 학습 앱의
  // 보라색과 차별화 + 호랑이(orange) 마스코트와 보색 조합.
  static const Color primary     = Color(0xFF2C3E94);  // 단청 청 (남색)
  static const Color primarySoft = Color(0xFFDBE4FF);  // 옅은 indigo tint
  static const Color primaryDark = Color(0xFF1E2D7A);  // hover/press

  // ── Cultural accent ──────────────────────────────────────────────────
  static const Color tiger    = Color(0xFFFF8C42);   // 호랑이 (mascot primary)
  static const Color gold     = Color(0xFFD4A92F);   // 갓끈 / XP / 별 (gat band)

  // ── Functional accent ────────────────────────────────────────────────
  static const Color hangul   = Color(0xFFEC4899);   // 한국어 강조
  static const Color success  = Color(0xFF22C55E);   // 정답/완료
  static const Color warning  = Color(0xFFF59E0B);   // streak/주의
  static const Color danger   = Color(0xFFEF4444);   // 오답/삭제
  static const Color info     = Color(0xFF3B82F6);   // 정보 (vocab 등)

  // ── Light surfaces & text ───────────────────────────────────────────
  static const Color lightBg          = Color(0xFFFFFFFF);
  static const Color lightSurface     = Color(0xFFF7F8FA);
  static const Color lightSurfaceAlt  = Color(0xFFEEF0F4);
  static const Color lightText        = Color(0xFF0F1419);
  static const Color lightTextMuted   = Color(0xFF677081);
  static const Color lightTextDim     = Color(0xFF9CA3AF);
  static const Color lightBorder      = Color(0xFFE5E7EB);

  // ── Dark surfaces & text ────────────────────────────────────────────
  static const Color darkBg          = Color(0xFF0B0E12);
  static const Color darkSurface     = Color(0xFF171B22);
  static const Color darkSurfaceAlt  = Color(0xFF252A33);
  static const Color darkText        = Color(0xFFF4F6F8);
  static const Color darkTextMuted   = Color(0xFFA3ACB8);
  static const Color darkTextDim     = Color(0xFF6B7280);
  static const Color darkBorder      = Color(0xFF2E343D);
}

// ─────────────────────────────────────────────────────────────────────────
// SURFACES — brightness-aware bundle
// ─────────────────────────────────────────────────────────────────────────
class SoriSurfaces {
  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color text;
  final Color textMuted;
  final Color textDim;
  final Color border;
  final Brightness brightness;

  const SoriSurfaces._({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.text,
    required this.textMuted,
    required this.textDim,
    required this.border,
    required this.brightness,
  });

  static const light = SoriSurfaces._(
    bg:         SoriColors.lightBg,
    surface:    SoriColors.lightSurface,
    surfaceAlt: SoriColors.lightSurfaceAlt,
    text:       SoriColors.lightText,
    textMuted:  SoriColors.lightTextMuted,
    textDim:    SoriColors.lightTextDim,
    border:     SoriColors.lightBorder,
    brightness: Brightness.light,
  );

  static const dark = SoriSurfaces._(
    bg:         SoriColors.darkBg,
    surface:    SoriColors.darkSurface,
    surfaceAlt: SoriColors.darkSurfaceAlt,
    text:       SoriColors.darkText,
    textMuted:  SoriColors.darkTextMuted,
    textDim:    SoriColors.darkTextDim,
    border:     SoriColors.darkBorder,
    brightness: Brightness.dark,
  );

  static SoriSurfaces of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

// ─────────────────────────────────────────────────────────────────────────
// MOTION — spring/curve presets
// ─────────────────────────────────────────────────────────────────────────
class SoriMotion {
  static const Duration fast     = Duration(milliseconds: 150);
  static const Duration medium   = Duration(milliseconds: 250);
  static const Duration slow     = Duration(milliseconds: 400);
  static const Duration verySlow = Duration(milliseconds: 600);

  /// Spring-like press scale (Duolingo feel).
  static const Curve press   = Curves.easeOut;
  static const Curve release = Curves.elasticOut;

  /// Page transition / Hero.
  static const Curve emphasis  = Curves.easeOutCubic;
  static const Curve gentle    = Curves.easeOutQuart;

  /// Success bounce.
  static const Curve celebrate = Curves.elasticOut;

  /// Scale targets.
  static const double pressScale = 0.96;
  static const double bounceUp   = 1.15;
}
