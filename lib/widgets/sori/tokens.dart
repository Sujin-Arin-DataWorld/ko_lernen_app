import 'package:flutter/material.dart';

/// Sori 디자인 토큰 — 색/공간/모서리/그림자 단일 소스 (6.0 단청 마이그레이션).
///
/// **v6.0 변경**: SoriColors 값이 Teal(#2AB7A9 등) → 단청 팔레트로 교체됨.
/// 변수 이름은 모두 그대로이므로 consumer 파일은 코드 변경 없이 자동 적용.
/// 원본 영감: 창덕궁 처마 4색(청금석·녹청·석간주·한지) — 채도 12% 낮춰 모던화.
/// WCAG AA 검증된 light/dark 셋. Firebase Remote Config 'palette_variant'로
/// 'teal' 선택 시 [SoriColorsTeal] 레거시 값으로 회귀(kill-switch).
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
  static const double xs = 4; // 컴포넌트 내부 미세 간격
  static const double sm = 8; // 작은 갭
  static const double md = 12; // 중간 갭
  static const double lg = 16; // 표준 카드 padding
  static const double xl = 24; // 섹션 간격
  static const double xxl = 32; // 큰 섹션 간격
  static const double xxxl = 48; // 화면 hero 간격

  static const EdgeInsets pageH = EdgeInsets.symmetric(horizontal: 18);
  static const EdgeInsets cardInner = EdgeInsets.all(16);
  static const EdgeInsets cardCompact = EdgeInsets.all(12);
}

// ─────────────────────────────────────────────────────────────────────────
// BREAKPOINTS — 반응형 콘텐츠 폭 클램프
// ─────────────────────────────────────────────────────────────────────────
/// 넓은 뷰포트(태블릿·데스크톱 웹)에서 콘텐츠 컬럼을 [content]로 클램프해
/// 듀오링고식 단일 집중 컬럼을 만든다. 카드·히어로가 360~430px서 튜닝됐으므로
/// 480은 폰엔 시각 변화 0, 넓은 화면만 가운데 정렬된다.
/// 적용은 [soriClampPadding] / [SoriContentClamp] (responsive.dart) 참조.
class SoriBreakpoints {
  /// 기본 콘텐츠 컬럼 (홈·리스트·설정).
  static const double content = 480;

  /// 2열 그리드(단어팩) 전용 — 카드가 너무 좁아지지 않게 여유.
  static const double grid = 600;

  /// 태블릿 시작점 — grid 컬럼 수 증가 등 레이아웃 분기 기준.
  static const double tablet = 720;

  /// 그리드 카드 1장 최소 목표 폭 — [soriGridColumns] 컬럼 수 산출의 분모.
  static const double gridCardMin = 150;
}

// ─────────────────────────────────────────────────────────────────────────
// RADIUS — round corners scale
// ─────────────────────────────────────────────────────────────────────────
class SoriRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16; // default card
  static const double lg = 20; // hero card / large button
  static const double xl = 24;
  static const double pill = 999; // chip / pill

  static const BorderRadius brSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(lg));
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
  // ── Brand v6.0 (단청 녹청 + Tiger accent + 황 gold) ───────────────────
  // 녹청 (Korean dancheong green) — 창덕궁 처마 원본 #2D9C7C 채도 12% 낮춤.
  // 학습의 인내·집중 톤. Tiger orange와 보색 대신 family-of-warms로 조화.
  static const Color primary = Color(0xFF1F7A6B); // 녹청 600 (단청 desat)
  static const Color primarySoft = Color(0xFFDCEEE8); // 녹청 100
  static const Color primaryDark = Color(0xFF0E443B); // 녹청 800 (hover/pressed)

  // ── Cultural accents ─────────────────────────────────────────────────
  // 호랑이 마스코트 정체성 유지. 단청 적과 family-of-warms로 조화.
  static const Color tiger = Color(0xFFFF8C42); // 호랑이 (mascot primary)
  static const Color gold = Color(0xFFC99A2E); // 황 (XP/streak/갓띠 — 단청 desat)

  // ── Dancheong accent (석간주 적) — CTA secondary / 한국어 강조 ────────
  static const Color accent = Color(0xFFA0524A); // 석간주 600
  static const Color accentSoft = Color(0xFFF0D9D5); // 석간주 100

  // ── Highlight (청금석 sky) — info / 강조 highlight ────────────────────
  static const Color highlight = Color(0xFF5A7BA0); // 청금석 (Hero photo blue)

  // ── Functional ───────────────────────────────────────────────────────
  // success = primary (정답=녹청, 학습 흐름 일관). danger = 단청 적(흙빛, 핏빛 X).
  static const Color hangul = Color(0xFFA0524A); // 한국어 강조 (was pink)
  static const Color success = Color(0xFF1F7A6B); // 정답/완료 = primary 재사용
  static const Color warning = Color(0xFFD4A22E); // streak/주의 (황 lifted)
  static const Color danger = Color(0xFFC44F40); // 오답/삭제 (단청 적 lifted)
  static const Color info = Color(0xFF5A7BA0); // 정보 (청금석)

  // ── Light surfaces (한지 위에서) ─────────────────────────────────────
  static const Color lightBg = Color(0xFFFAF6EC); // 한지 cream
  static const Color lightSurface = Color(0xFFF1ECDC); // 한지 깊은 톤
  static const Color lightSurfaceAlt = Color(0xFFE5DCC4);
  static const Color lightText = Color(0xFF1A1F1D); // 먹 (warm dark)
  static const Color lightTextMuted = Color(0xFF5C6660);
  static const Color lightTextDim = Color(0xFF8B948E);
  static const Color lightBorder = Color(0xFFDAD3BE);

  // ── Dark surfaces (먹색 위에서) ──────────────────────────────────────
  // 완전 검정 회피 — 단청 정서와 어울리는 -5% 회녹 ink.
  static const Color darkBg = Color(0xFF0E1A18); // deep ink
  static const Color darkSurface = Color(0xFF1A2A26);
  static const Color darkSurfaceAlt = Color(0xFF233530);
  static const Color darkText = Color(0xFFF1E8D0); // 따뜻한 한지 크림
  static const Color darkTextMuted = Color(0xFFA0AFA8);
  static const Color darkTextDim = Color(0xFF6B7570);
  static const Color darkBorder = Color(0xFF2E443E);

  // ── Dark mode brand raises (대비 위해 light에서 한 톤 위로) ──────────
  static const Color darkPrimary = Color(0xFF4FB6A0); // 녹청 다크에서 lift
  static const Color darkAccent = Color(0xFFC77268); // 석간주 다크에서 lift

  // ── On-surface text accents (WCAG AA/AAA 보강) ──────────────────────
  // primary `#1F7A6B` on lightSurface `#F1ECDC` ≈ 5.8:1 (AA fail for <18pt).
  // primaryDark `#0E443B` on lightSurface ≈ 12.6:1 → outlined/ghost 텍스트에 사용.
  static const Color primaryOnLight = primaryDark; // alias for clarity
  static const Color primaryOnDark = darkPrimary; // dark mode text-on-surface

  // ── Celebration palette (입자/축하 모션 4색) ─────────────────────────
  // SoriCelebration._palette에서 사용. 외부 토큰화로 테마 변경 시 일관 유지.
  static const List<Color> celebrationPalette = [
    tiger, // 호랑이 주황
    gold, // 황
    accent, // 석간주 적
    primary, // 녹청
  ];
}

/// **레거시 Teal 팔레트** — Firebase Remote Config 'palette_variant=teal' 시 사용.
/// 단청 마이그레이션 실패/롤백 대비 kill-switch용 보관소.
/// 직접 참조 금지 — [PaletteService] 통해 ThemeData 빌드 시에만 사용.
class SoriColorsTeal {
  SoriColorsTeal._();

  static const Color primary = Color(0xFF2AB7A9);
  static const Color primarySoft = Color(0xFFD8F1EE);
  static const Color primaryDark = Color(0xFF1F8F84);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF7F8FA);
  static const Color lightSurfaceAlt = Color(0xFFEEF0F4);
  static const Color lightText = Color(0xFF0F1419);
  static const Color lightTextMuted = Color(0xFF677081);
  static const Color lightTextDim = Color(0xFF9CA3AF);
  static const Color lightBorder = Color(0xFFE5E7EB);

  static const Color darkBg = Color(0xFF0B0E12);
  static const Color darkSurface = Color(0xFF171B22);
  static const Color darkSurfaceAlt = Color(0xFF252A33);
  static const Color darkText = Color(0xFFF4F6F8);
  static const Color darkTextMuted = Color(0xFFA3ACB8);
  static const Color darkTextDim = Color(0xFF6B7280);
  static const Color darkBorder = Color(0xFF2E343D);
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
    bg: SoriColors.lightBg,
    surface: SoriColors.lightSurface,
    surfaceAlt: SoriColors.lightSurfaceAlt,
    text: SoriColors.lightText,
    textMuted: SoriColors.lightTextMuted,
    textDim: SoriColors.lightTextDim,
    border: SoriColors.lightBorder,
    brightness: Brightness.light,
  );

  static const dark = SoriSurfaces._(
    bg: SoriColors.darkBg,
    surface: SoriColors.darkSurface,
    surfaceAlt: SoriColors.darkSurfaceAlt,
    text: SoriColors.darkText,
    textMuted: SoriColors.darkTextMuted,
    textDim: SoriColors.darkTextDim,
    border: SoriColors.darkBorder,
    brightness: Brightness.dark,
  );

  // ── 레거시 Teal 팔레트용 surfaces (kill-switch 용도) ────────────────
  static const lightTeal = SoriSurfaces._(
    bg: SoriColorsTeal.lightBg,
    surface: SoriColorsTeal.lightSurface,
    surfaceAlt: SoriColorsTeal.lightSurfaceAlt,
    text: SoriColorsTeal.lightText,
    textMuted: SoriColorsTeal.lightTextMuted,
    textDim: SoriColorsTeal.lightTextDim,
    border: SoriColorsTeal.lightBorder,
    brightness: Brightness.light,
  );

  static const darkTeal = SoriSurfaces._(
    bg: SoriColorsTeal.darkBg,
    surface: SoriColorsTeal.darkSurface,
    surfaceAlt: SoriColorsTeal.darkSurfaceAlt,
    text: SoriColorsTeal.darkText,
    textMuted: SoriColorsTeal.darkTextMuted,
    textDim: SoriColorsTeal.darkTextDim,
    border: SoriColorsTeal.darkBorder,
    brightness: Brightness.dark,
  );

  static SoriSurfaces of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

// ─────────────────────────────────────────────────────────────────────────
// MOTION — spring/curve presets
// ─────────────────────────────────────────────────────────────────────────
class SoriMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration verySlow = Duration(milliseconds: 600);

  /// Spring-like press scale (Duolingo feel).
  static const Curve press = Curves.easeOut;
  static const Curve release = Curves.elasticOut;

  /// Page transition / Hero.
  static const Curve emphasis = Curves.easeOutCubic;
  static const Curve gentle = Curves.easeOutQuart;

  /// Success bounce.
  static const Curve celebrate = Curves.elasticOut;

  /// Scale targets.
  static const double pressScale = 0.96;
  static const double bounceUp = 1.15;

  /// 사용자 시스템 "동작 줄이기(Reduce Motion)" 켜져 있는지.
  ///
  /// 켜져 있으면 Ken Burns·매화 입자·flying magpie·celebration 등
  /// 장식 모션은 정적으로 떨어진다. WCAG 2.3.3 / iOS·Android 시스템 설정 존중.
  static bool reduceMotion(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  /// reduceMotion 시 Duration.zero, 아니면 [d] 그대로.
  /// `SoriEntrance(duration: SoriMotion.respect(ctx, slow))` 같은 패턴.
  static Duration respect(BuildContext context, Duration d) =>
      reduceMotion(context) ? Duration.zero : d;
}

// ─────────────────────────────────────────────────────────────────────────
// TEXT — Pretendard 중앙 TextStyle 토큰
// ─────────────────────────────────────────────────────────────────────────
/// 앱 폰트 패밀리 상수 — 한 곳에서 교체 가능.
/// - [sans] Pretendard: 본문·UI·모든 한국어(가독성).
/// - [serif] GowunBatang(고운바탕 명조, 라틴 서브셋): 디스플레이/제목/큰 숫자
///   — 에디토리얼 대비. 한글 글리프 없음 → serif TextStyle은 항상 [sans] 폴백.
class SoriFonts {
  SoriFonts._();
  static const String sans = 'Pretendard';
  static const String serif = 'GowunBatang';
  static const List<String> serifFallback = [sans];
}

/// 모든 Sori 컴포넌트가 따르는 TextStyle 프리셋.
///
/// 기존 컴포넌트는 `TextStyle(fontFamily: 'Pretendard', ...)` 하드코딩.
/// 점진 마이그레이션 — 신규 텍스트는 [SoriTextTheme.of(ctx).body] 등 사용.
///
/// 색은 surface 기반 — `s.text` (default), `s.textMuted`, `s.textDim`.
/// 사이즈·weight·letter-spacing·height 만 중앙화.
///
/// 타이포 보이스(한지 에디토리얼): 큰 제목(display/h1/h2)은 명조 serif,
/// 본문·라벨은 산세리프 — serif↔sans 대비가 '범용 AI' 느낌을 걷어낸다.
class SoriTextTheme {
  final SoriSurfaces _s;

  const SoriTextTheme._(this._s);

  static SoriTextTheme of(BuildContext context) =>
      SoriTextTheme._(SoriSurfaces.of(context));

  // ── Display / Heading (명조 serif — 에디토리얼) ───────────────────────
  // GowunBatang은 400/700만 번들 → w700 사용(w800은 합성볼드라 회피).
  TextStyle get display => _base(
    fontSize: 32,
    weight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.2,
    serif: true,
  );
  TextStyle get h1 => _base(
    fontSize: 24,
    weight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.25,
    serif: true,
  );
  TextStyle get h2 => _base(
    fontSize: 20,
    weight: FontWeight.w700,
    letterSpacing: -0.1,
    height: 1.3,
    serif: true,
  );

  /// 히어로용 대형 명조 (온보딩·결과 헤드라인).
  TextStyle get serifDisplay => _base(
    fontSize: 40,
    weight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.1,
    serif: true,
  );

  /// 큰 통계 숫자 — 명조 + tabular(자릿수 정렬). 스트릭·XP 히어로 수치.
  TextStyle get numeral => _base(
    fontSize: 30,
    weight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.1,
    serif: true,
    tabular: true,
  );
  TextStyle get h3 => _base(
    fontSize: 17,
    weight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.3,
  );

  // ── Body ─────────────────────────────────────────────────────────────
  TextStyle get body => _base(
    fontSize: 15,
    weight: FontWeight.w500,
    letterSpacing: -0.1,
    height: 1.45,
  );
  TextStyle get bodySmall => _base(
    fontSize: 13.5,
    weight: FontWeight.w500,
    letterSpacing: -0.05,
    height: 1.4,
    color: _s.textMuted,
  );

  // ── Caption / Label ──────────────────────────────────────────────────
  TextStyle get caption => _base(
    fontSize: 12,
    weight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.35,
    color: _s.textMuted,
  );
  TextStyle get label => _base(
    fontSize: 12.5,
    weight: FontWeight.w700,
    letterSpacing: 0.2,
    height: 1.2,
  );

  // ── Card (앱 최빈 패턴 — 카드 제목/부제. B-2 타이포 통일 2026-06-12) ──
  TextStyle get cardTitle => _base(
    fontSize: 14,
    weight: FontWeight.w800,
    letterSpacing: -0.2,
    height: 1.3,
  );
  TextStyle get cardSubtitle => _base(
    fontSize: 11.5,
    weight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.35,
    color: _s.textMuted,
  );

  TextStyle _base({
    required double fontSize,
    required FontWeight weight,
    required double letterSpacing,
    required double height,
    Color? color,
    bool serif = false,
    bool tabular = false,
  }) => TextStyle(
    fontFamily: serif ? SoriFonts.serif : SoriFonts.sans,
    // serif엔 한글 글리프가 없다 → 한국어는 Pretendard로 자동 폴백(두부 방지).
    fontFamilyFallback: serif ? SoriFonts.serifFallback : null,
    fontSize: fontSize,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    height: height,
    color: color ?? _s.text,
    fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
  );
}
