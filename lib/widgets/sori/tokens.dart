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

  /// 표준 페이지 패딩 (2026-08-13 UI 개편 Phase 1).
  /// SoriStage 화면들이 손으로 쓰던 `fromLTRB(20, 20, 20, 48)` 리터럴의 토큰화 —
  /// 위 20 = 헤더 위 숨, 아래 48 = 스크롤 끝 여유. 새 화면은 이걸 쓴다.
  static const EdgeInsets page = EdgeInsets.fromLTRB(20, 20, 20, 48);
}

// ─────────────────────────────────────────────────────────────────────────
// BREAKPOINTS — 반응형 콘텐츠 폭 클램프
// ─────────────────────────────────────────────────────────────────────────
/// 넓은 뷰포트(태블릿·데스크톱 웹)에서 콘텐츠 컬럼을 [content]로 클램프해
/// 듀오링고식 단일 집중 컬럼을 만든다. 카드·히어로가 360~430px서 튜닝됐으므로
/// 480은 폰엔 시각 변화 0, 넓은 화면만 가운데 정렬된다.
/// 적용은 [soriClampPadding] / [SoriContentClamp] (responsive.dart) 참조.
class SoriBreakpoints {
  /// Mission chrome stacks its label and progress before either phrase wraps
  /// into an unreadably narrow side-by-side column.
  static const double missionHeaderStack = 280;

  /// Deck judgment labels become full-width rows at this component width.
  static const double contentActionStack = 320;

  /// Very narrow phone content where two comparison panels must stack.
  static const double narrowPhone = 360;

  /// 기본 콘텐츠 컬럼 (홈·리스트·설정).
  static const double content = 480;

  /// 2열 그리드(단어팩) 전용 — 카드가 너무 좁아지지 않게 여유.
  static const double grid = 600;

  /// Medium Android tablets and unfolded devices use a navigation rail from
  /// 600dp. The browsing column and comfort scale can continue to grow until
  /// [tablet], so compact tablets do not suddenly look oversized.
  static const double navigationRail = 600;

  /// 태블릿 시작점 — grid 컬럼 수 증가 등 레이아웃 분기 기준.
  static const double tablet = 720;

  /// 그리드 카드 1장 최소 목표 폭 — [soriGridColumns] 컬럼 수 산출의 분모.
  static const double gridCardMin = 150;

  /// Tablet browsing surfaces retain a readable line length without looking
  /// undersized on 8--13 inch Android tablets.
  static const double tabletContent = 640;

  /// Maximum visual enlargement for app-controlled type and touch targets.
  /// [SoriTypeScale] multiplies this once into the ambient [TextScaler] —
  /// it is not applied a second time anywhere else.
  static const double tabletComfortScale = 1.10;

  /// A wide tablet in landscape can afford an expanded navigation rail.
  static const double wideTablet = 1024;
}

/// Returns the small, device-width-driven visual enlargement used above the
/// large-phone breakpoint. This deliberately does not read [TextScaler] —
/// [SoriTypeScale] is the single place that multiplies it into the ambient
/// TextScaler, once, so it composes with the OS accessibility scale.
double soriComfortScale(double width) {
  final progress =
      ((width - SoriBreakpoints.grid) /
              (SoriBreakpoints.tablet - SoriBreakpoints.grid))
          .clamp(0.0, 1.0)
          .toDouble();
  return 1 + (SoriBreakpoints.tabletComfortScale - 1) * progress;
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
  static const Color info = Color(0xFF57799E); // 정보 (청금석, white 4.53:1)

  /// Content-player CTA — 녹청. Jin 2026-08-19: listening blue is not the
  /// filled button. Level chips keep [info]; XP/streak keep [gold].
  static const Color contentCta = primary;

  /// Text/icon on [contentCta]. White — not a new pigment.
  static const Color contentCtaOn = Color(0xFFFFFFFF);

  /// Like/heart fill — same pigment as [accent] (석간주). Not Instagram pink.
  static const Color like = accent;

  // ── Light surfaces (한지 위에서) ─────────────────────────────────────
  static const Color lightBg = Color(0xFFFAF6EC); // 한지 cream
  static const Color lightSurface = Color(0xFFF1ECDC); // 한지 깊은 톤
  static const Color lightSurfaceAlt = Color(0xFFE5DCC4);

  /// 크림 배경(`lightBg`) 위에서 **떠올라야 하는** 카드 바탕.
  ///
  /// `lightSurface` #F1ECDC 는 `lightBg` 대비 1.09:1 — 수치상 같은 색이라
  /// 어떤 레이아웃을 짜도 카드가 배경에서 분리되지 않았다("답답하다"의 실제 원인).
  /// 종이보다 한 톤 밝은 흰 한지로 올리면 `lightBorderStrong` 테두리 대비가
  /// 2.81:1 → **3.27:1** 로 올라 SC 1.4.11 을 여유 있게 넘긴다.
  static const Color lightSurfaceRaised = Color(0xFFFFFDF8);
  static const Color lightText = Color(0xFF1A1F1D); // 먹 (warm dark)
  static const Color lightTextMuted = Color(0xFF5C6660);
  static const Color lightTextDim = Color(0xFF8B948E);
  static const Color lightBorder = Color(0xFFDAD3BE);

  /// 한지 cream(`lightBg`) 위에서 카드/선택지 경계를 확실히 분리하는 강한 테두리.
  /// `lightBorder`(1.2:1)는 cream 배경과 거의 구분되지 않아 선택 UI에는 부적합.
  /// `#978C73` on `#FAF6EC` ≈ 3.1:1 → WCAG 2.1 SC 1.4.11 (non-text contrast) 충족.
  static const Color lightBorderStrong = Color(0xFF978C73);

  // ── Dark surfaces (먹색 위에서) ──────────────────────────────────────
  // 완전 검정 회피 — 단청 정서와 어울리는 -5% 회녹 ink.
  static const Color darkBg = Color(0xFF0E1A18); // deep ink
  static const Color darkSurface = Color(0xFF1A2A26);
  static const Color darkSurfaceAlt = Color(0xFF233530);
  static const Color darkText = Color(0xFFF1E8D0); // 따뜻한 한지 크림
  static const Color darkTextMuted = Color(0xFFA0AFA8);
  static const Color darkTextDim = Color(0xFF6B7570);
  static const Color darkBorder = Color(0xFF2E443E);

  /// 다크 카드 경계. `darkBorder` #2E443E 는 `darkSurface` #1A2A26 대비
  /// **1.43:1** 로 라이트의 `lightBorder` 문제를 그대로 갖고 있다.
  /// 앱이 `themeMode.light` 고정이라 지금은 안 드러나지만, 다크를 켜는 순간
  /// 같은 결함이 나온다. #6E8A82 on darkSurface ≈ 3.4:1.
  static const Color darkBorderStrong = Color(0xFF6E8A82);

  // ── Dark mode brand raises (대비 위해 light에서 한 톤 위로) ──────────
  static const Color darkPrimary = Color(0xFF4FB6A0); // 녹청 다크에서 lift
  static const Color darkAccent = Color(0xFFC77268); // 석간주 다크에서 lift

  // ── On-surface text accents (WCAG AA/AAA 보강) ──────────────────────
  // primary `#1F7A6B` on lightSurface `#F1ECDC` ≈ 5.8:1 (AA fail for <18pt).
  // primaryDark `#0E443B` on lightSurface ≈ 12.6:1 → outlined/ghost 텍스트에 사용.
  static const Color primaryOnLight = primaryDark; // alias for clarity
  static const Color primaryOnDark = darkPrimary; // dark mode text-on-surface

  /// `gold`·`tiger`는 **밝은** 계열이라 크림 배경 위 텍스트로 쓸 수 없다
  /// (`gold` 2.4:1, `tiger` 2.1:1 — AA 4.5 미달). 아이콘/텍스트에는 아래
  /// 다크 변형을, 채움(fill)에는 원래 색을 쓴다.
  /// `#7A5810` on `lightBg` = 6.0:1, `#A8490B` on `lightBg` = 5.4:1.
  static const Color goldOnLight = Color(0xFF7A5810);
  static const Color tigerOnLight = Color(0xFFA8490B);

  /// 반대로 `gold`·`tiger`를 **채움**으로 쓸 땐 그 위에 흰 글씨를 얹지 않는다
  /// (흰 on tiger = 2.3:1). 먹색을 얹으면 7.2:1.
  static const Color onTigerFill = lightText;
  static const Color onGoldFill = lightText;

  // ── 대비 자동 판정 (WCAG 2.1) ────────────────────────────────────────
  // 위 두 규칙("밝은 채움 위엔 먹색", "채움이 배경과 3:1 미만이면 테두리")을
  // 사람이 매번 지키는 대신 계산으로 강제한다. accent 색이 새로 추가돼도
  // 호출측 수정 없이 올바른 글자색·테두리가 자동으로 나온다.
  // (2026-07-31: 홈 주 CTA가 `tiger` 채움 + 흰 글씨 2.31:1로 이 규칙을
  //  위반하고 있었다 — 규칙을 문서가 아니라 코드로 옮긴 이유.)

  /// 두 색의 WCAG 2.1 명도 대비비 (1.0 ~ 21.0).
  static double contrastRatio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  /// [fill] 채움 위에 얹을 글자·아이콘 색 — 흰색/먹색 중 대비가 큰 쪽. SC 1.4.3.
  ///
  /// `primary`·`accent`·`danger`·`info` → 흰색(기존 동작 유지),
  /// `tiger`(7.22:1)·`gold`(6.48:1)·`warning`(7.16:1) → 먹색.
  static Color onFill(Color fill) =>
      contrastRatio(Colors.white, fill) >= contrastRatio(lightText, fill)
      ? Colors.white
      : lightText;

  /// [fill] 채움이 [bg] 배경에서 3:1로 분리되지 않을 때 필요한 보강 테두리 색.
  /// 이미 충분히 분리되면 `null`. SC 1.4.11.
  ///
  /// 채움을 먹색 쪽으로 단계적으로 눌러 최초로 3:1을 넘는 색을 고른다 —
  /// 색상(hue)이 유지되므로 브랜드 인상은 그대로다.
  /// 예) `tiger` #FF8C42 → #AF6635 (배경 대비 4.08:1).
  static Color? fillOutline(Color fill, Color bg) {
    if (contrastRatio(fill, bg) >= 3.0) return null;
    for (final a in const [0.25, 0.35, 0.45, 0.55, 0.65]) {
      final c = Color.alphaBlend(lightText.withValues(alpha: a), fill);
      if (contrastRatio(c, bg) >= 3.0) return c;
    }
    return lightText;
  }

  // ── Celebration palette (입자/축하 모션 4색) ─────────────────────────
  // SoriCelebration._palette에서 사용. 외부 토큰화로 테마 변경 시 일관 유지.
  static const List<Color> celebrationPalette = [
    tiger, // 호랑이 주황
    gold, // 황
    accent, // 석간주 적
    primary, // 녹청
  ];
}

/// Semantic activity palette used by Sori Stage.
///
/// These roles sit on top of [SoriColors]; they do not replace the established
/// brand tokens. Every production surface pairs the color with a label, icon,
/// or progress affordance so meaning never depends on color alone.
abstract final class SoriActivityColors {
  static const Color listening = Color(0xFF79CFC0);
  static const Color listeningStrong = SoriColors.primary;
  static const Color speaking = SoriColors.tiger;
  static const Color review = Color(0xFFE48A78);
  static const Color completion = SoriColors.primaryDark;
  static const Color reward = SoriColors.gold;
  static const Color collaboration = SoriColors.highlight;
  static const Color hanji = SoriColors.lightBg;
  static const Color hanokStage = Color(0xFF173D36);

  static const Color onListening = SoriColors.lightText;
  static const Color onSpeaking = SoriColors.onTigerFill;
  static const Color onReview = SoriColors.lightText;
  static const Color onCompletion = Colors.white;
  static const Color onReward = SoriColors.onGoldFill;
  static const Color onCollaboration = Colors.white;
  static const Color onHanokStage = Color(0xFFFFF7E4);
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

  // ── Sori Deck 3.0 — 카드 제스처 물리 (2026-08-18) ──────────────────────
  //
  // 덱 카드는 손가락에서 이어지는 "물건"이라 트윈+커브가 아니라 **스프링
  // 시뮬레이션**으로 복귀한다. [release](elasticOut)는 250ms 안에 여러 번
  // 오버슛해 카드가 붕붕대 보였다 — 덱에서는 쓰지 않는다.
  //
  // damping ratio = damping / (2·√(mass·stiffness)) = 32 / (2·√380) ≈ 0.82
  // → 미세 언더댐프. 오버슛이 1회 미만이라 "탄력 있지만 흔들리지 않는" 지점.
  // 정착 ≈ 250ms 로 medium 과 체감이 맞는다.

  /// 카드 스프링백 — 임계 미달 복귀·축 잠금 정리·저장(↑) 제자리 복귀 공용.
  static const SpringDescription deckSpring = SpringDescription(
    mass: 1,
    stiffness: 380,
    damping: 32,
  );

  /// 퇴장(좌/우/아래)은 플링 속도를 승계한다 — 세게 던지면 빨리 나간다.
  /// 진입(스프링백 ≈250ms)의 ~75% 를 중앙값으로 두고 이 범위로 clamp.
  static const Duration deckExitMin = Duration(milliseconds: 120);
  static const Duration deckExitMax = Duration(milliseconds: 220);

  /// 지배축 확정 임계. 잠금 **전에도 카드는 손가락을 따라간다** — 예전 12px
  /// 은 그 구간 표시 오프셋을 버려서 "안 따라오다 갑자기 붙는" 데드존이었다.
  static const double deckAxisLock = 4;

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
// TEXT — Wanted Sans 중앙 TextStyle 토큰
// ─────────────────────────────────────────────────────────────────────────
/// 앱 폰트 패밀리 상수 — 역할로만 선택한다.
/// - [sans] Wanted Sans: UI·DE/EN·학습 본문·숫자의 기본 폰트.
/// - [culture] Maru Buri: 짧은 한국어 문화 제목과 특별한 완료 순간 전용.
///   버튼·메뉴·긴 본문에는 사용하지 않는다.
///
/// **2026-08-19 교체**: 이전 PretendardStd 는 라틴 전용 서브셋이라 한글 글리프가
/// 0개였다. 한국어는 전부 OS 폴백(맑은 고딕·제조사 기본·Apple SD Gothic)으로
/// 그려져 한·독 혼용 줄에서 서체·굵기·베이스라인이 갈렸다. "단일 폰트" 전제가
/// 한글에서 처음으로 성립한다. `test/font_bundle_guard_test.dart` 가 번들 폰트의
/// 한글·독일어 글리프를 검사해 재발을 막는다.
class SoriFonts {
  SoriFonts._();
  static const String sans = 'WantedSans';
  static const String culture = 'MaruBuri';
}

/// 모든 Sori 컴포넌트가 따르는 TextStyle 프리셋.
///
/// 기존 컴포넌트는 `TextStyle(fontFamily: SoriFonts.sans, ...)` 하드코딩.
/// 점진 마이그레이션 — 신규 텍스트는 [SoriTextTheme.of(ctx).body] 등 사용.
///
/// 색은 surface 기반 — `s.text` (default), `s.textMuted`, `s.textDim`.
/// 사이즈·weight·letter-spacing·height 만 중앙화.
///
/// **타이포 보이스(2026-08-20)**: 현대적 학습 UI 80 + 한국적 문화 정체성 20.
/// 기본 위계는 Wanted Sans의 크기·굵기로 만들고, 검증된 한국어 문화 맥락에만
/// Maru Buri를 제한적으로 사용한다.
class SoriTextTheme {
  final SoriSurfaces _s;

  const SoriTextTheme._(this._s);

  static SoriTextTheme of(BuildContext context) =>
      SoriTextTheme._(SoriSurfaces.of(context));

  // ── Display / Heading (Pretendard ExtraBold — 통일) ───────────────────
  // 위계는 크기·굵기로만. Pretendard w800 번들 → 합성볼드 아닌 진짜 ExtraBold.
  TextStyle get display => _base(
    fontSize: 32,
    weight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.15,
  );

  /// 페이지 대형 헤드라인 (2026-08-13 UI 개편 Phase 1).
  /// Vocabulary급 "화면당 1메시지" 위계의 앵커 — [eyebrow] 와 짝으로 쓴다.
  /// [display](32) 는 컴팩트 맥락용으로 유지.
  TextStyle get hero => _base(
    fontSize: 38,
    weight: FontWeight.w800,
    letterSpacing: -0.8,
    height: 1.08,
  );

  /// 헤드라인 위의 소형 대문자 라벨 (자간 넓힘, 기본 석간주).
  /// `SoriStageRootHeader` 가 손으로 쓰던 패턴의 토큰화 — 호출부에서
  /// `.toUpperCase()` 는 직접 한다 (독일어 ß 등 로케일 정책은 호출부 소관).
  TextStyle get eyebrow => _base(
    fontSize: 12,
    weight: FontWeight.w700,
    letterSpacing: 1.4,
    height: 1.2,
    color: SoriColors.accent,
  );
  TextStyle get h1 => _base(
    fontSize: 24,
    weight: FontWeight.w800,
    letterSpacing: -0.4,
    height: 1.25,
  );
  TextStyle get h2 => _base(
    fontSize: 20,
    weight: FontWeight.w800,
    letterSpacing: -0.3,
    height: 1.3,
  );

  /// 한국어 문화 오프닝·완료 순간용 대형 제목.
  TextStyle get cultureDisplay => _base(
    fontSize: 40,
    weight: FontWeight.w600,
    letterSpacing: -0.8,
    height: 1.2,
    fontFamily: SoriFonts.culture,
  );

  /// 문화 카드 안의 짧은 한국어 표제.
  TextStyle get cultureTitle => _base(
    fontSize: 21,
    weight: FontWeight.w600,
    letterSpacing: -0.35,
    height: 1.35,
    fontFamily: SoriFonts.culture,
  );

  /// 큰 통계 숫자 — tabular(자릿수 정렬). 스트릭·XP 히어로 수치.
  TextStyle get numeral => _base(
    fontSize: 30,
    weight: FontWeight.w800,
    letterSpacing: -0.2,
    height: 1.1,
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
    fontSize: 14,
    weight: FontWeight.w500,
    letterSpacing: -0.05,
    height: 1.4,
    color: _s.textMuted,
  );

  // ── Caption / Label ──────────────────────────────────────────────────
  TextStyle get caption => _base(
    fontSize: 12.5,
    weight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.35,
    color: _s.textMuted,
  );

  /// Content-player Korean hero. Hierarchy is size/weight only — no new font.
  TextStyle get koDisplay => _base(
    fontSize: 28,
    weight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.25,
  );

  /// Content-player DE/EN gloss under the Korean word.
  TextStyle get gloss => _base(
    fontSize: 17,
    weight: FontWeight.w500,
    letterSpacing: -0.1,
    height: 1.4,
    color: _s.textMuted,
  );

  /// Content-player chrome (progress `3 / 12`, hints). Do not go below 12.5.
  TextStyle get meta => _base(
    fontSize: 12.5,
    weight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.35,
    color: _s.textMuted,
  );
  TextStyle get label => _base(
    fontSize: 13,
    weight: FontWeight.w700,
    letterSpacing: 0.2,
    height: 1.2,
  );

  // ── Card (앱 최빈 패턴 — 카드 제목/부제. B-2 타이포 통일 2026-06-12) ──
  // §4.3 (2026-08-04): 카드 제목 = 15~17 w700 — w800 금지 규정에 맞춰
  // 14/w800 → 15/w700. 위계는 크기 차(제목 15 vs 본문 12~13)로 낸다.
  TextStyle get cardTitle => _base(
    fontSize: 15,
    weight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.3,
  );
  TextStyle get cardSubtitle => _base(
    fontSize: 12,
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
    bool tabular = false,
    String fontFamily = SoriFonts.sans,
  }) => TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    height: height,
    color: color ?? _s.text,
    fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
  );
}
