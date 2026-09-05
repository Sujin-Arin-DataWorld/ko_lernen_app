import 'package:flutter/material.dart';
import 'tokens.dart';

/// Browsing surfaces can use more of a tablet without turning learning text
/// into an overlong desktop line. The phone column remains unchanged through
/// 600dp, then grows smoothly to a 640dp tablet column at 720dp.
double soriAdaptiveContentMaxWidth(double availableWidth) {
  final progress =
      ((availableWidth - SoriBreakpoints.grid) /
              (SoriBreakpoints.tablet - SoriBreakpoints.grid))
          .clamp(0.0, 1.0)
          .toDouble();
  return SoriBreakpoints.content +
      (SoriBreakpoints.tabletContent - SoriBreakpoints.content) * progress;
}

// ── Immersive study cards: tablet width ramp ───────────────────────────────
// Fixed-focus flashcard/quiz screens (grammar·vocab·cloze…) show a single
// hero card, so — unlike browsing text — they can afford a wider card on
// tablets without the line-length concern. The phone experience
// (≤ [SoriBreakpoints.grid] = 600dp) is untouched; the ramp reaches full size
// by [_studyRampEnd] so 8--13" tablets read comfortably. 폭 램프만 남기고
// 글씨 배율은 SoriTypeScale 로 이관(2026-08-19) — hero text no longer gets an
// extra multiplier here; see [SoriStudyClamp].

const double _studyRampStart = SoriBreakpoints.grid; // 600dp — phone baseline
const double _studyRampEnd = 900; // full tablet enlargement reached here

double _studyProgress(double width) =>
    ((width - _studyRampStart) / (_studyRampEnd - _studyRampStart))
        .clamp(0.0, 1.0)
        .toDouble();

/// Content column width for fixed-focus study screens. 480 on phones (visual
/// change 0), growing to 760 on tablets so the card fills more of the screen.
/// Applied via [SoriStudyClamp]; a drop-in wider sibling of the fixed 480
/// [SoriCenterClamp] used by focus learning views.
double soriStudyContentMaxWidth(double width) =>
    SoriBreakpoints.content +
    (760 - SoriBreakpoints.content) * _studyProgress(width);

/// Font/gap size proportional to a **focus card's inner height** [h], clamped to
/// [min]..[max]. Hero flashcard/quiz text sized with this grows with the card,
/// so its vertical fill ratio stays consistent across phones and tablets while
/// the [min] keeps small viewports legible. Pair with a `spaceEvenly` column and
/// a `SingleChildScrollView` fallback so the rare overflow scrolls instead of
/// clipping. **Only for focus/hero content** — never for chrome (buttons, nav,
/// list rows, chips), whose sizes are tuned and must not scale to fill.
///
/// Returns a raw px value used directly as a `TextStyle.fontSize` at call
/// sites — SoriTypeScale 의 TextScaler 가 한 번 더 곱한다 — Phase 4 에서
/// 호출부 정리.
double soriFillSize(double h, double frac, double min, double max) =>
    (h * frac).clamp(min, max).toDouble();

/// 플래시카드 히어로 타이포의 **기준 높이**.
///
/// [soriFillSize] 에 넘길 h 를 "남은 세로 공간"에서 뽑으면 화면에 무엇이 더
/// 얹혔는지에 따라 글씨 크기가 달라진다. 2026-08-12 실기기에서 그게 드러났다:
/// `Begrüßung & Höflichkeit (1)` 에는 미션 배너("Schritt 1 von 26")가 있어
/// 카드 영역이 좁고 `(2)` 에는 없어서 넓다 → 같은 카드인데 (2)의 제시어가
/// 훨씬 커졌다("갑자기 너무 커진상태" — Jin). 단어 길이에 따라 카드가
/// 들쭉날쭉하다는 오랜 지적도 뿌리가 같다.
///
/// 그래서 기준을 **뷰포트 높이**로 옮긴다. 배너·칩·버튼이 붙고 떨어져도 값이
/// 변하지 않으므로 같은 기기면 언제나 같은 크기가 나온다.
///
/// 0.45 는 Jin 이 "이 크기가 좋다"고 한 (1) 상태 — 배너가 있는 레이아웃의 카드
/// 높이 비율에 맞춘 값이다. 조정할 일이 생기면 이 상수 하나만 건드리면 되고,
/// `test/vocab_pack_typography_test.dart` 가 (1)과 (2)가 같은지 지킨다.
///
/// 이 높이에서 파생된 fontSize(예: [soriFillSize])는 SoriTypeScale 의
/// TextScaler 가 한 번 더 곱한다 — Phase 4 에서 호출부 정리.
double soriStudyTypeScaleHeight(BuildContext context) =>
    (MediaQuery.sizeOf(context).height * 0.45).clamp(280.0, 520.0).toDouble();

/// 덱 전체가 **공유하는 균일 헤드라인 크기** — "단어 길이마다 카드 글씨가
/// 커졌다 작아졌다" 문제의 근본 수리 (2026-08-14, 테스터·Jin 반복 지적).
///
/// `FittedBox(scaleDown)` 은 **현재 단어**만 보고 줄인다: 짧은 단어는 [cap],
/// 긴 단어는 축소 → 카드를 넘길 때마다 크기가 요동친다. 이 함수는 덱의 모든
/// 후보 텍스트를 TextPainter 로 실측해, **가장 넓은 텍스트가 [maxWidth] 한
/// 줄에 들어가는 크기 하나**를 돌려준다. 덱 내내 이 값 하나를 쓰면 어떤
/// 단어가 나와도 크기가 같다.
///
/// - [context] 의 ambient textScaler(OS 접근성 배율 + SoriTypeScale 의 comfort
///   배율)를 실측에 반영하므로, 반드시 렌더링과 **같은 서브트리의 컨텍스트**
///   로 호출한다.
/// - 실측은 [DefaultTextStyle] 의 폰트 패밀리를 상속한다 (측정/렌더 폰트 불일치
///   방지) + 2% 안전 마진.
/// - 렌더 쪽에는 FittedBox(scaleDown) 을 **안전망으로만** 남겨 둔다 — 실측이
///   맞으면 절대 개입하지 않아 크기가 균일하고, 폰트 폴백 등으로 1–2% 어긋난
///   극단 케이스에만 잘림 대신 미세 축소로 받아낸다.
double soriUniformFitSize(
  BuildContext context, {
  required Iterable<String> texts,
  required double maxWidth,
  required double cap,
  required double min,
  // 카드 제시어의 정본 굵기 (2026-08-17 Jin). 번들된 Pretendard 는 400~800
  // 뿐이라 w800·w900 이 **둘 다** ExtraBold 로 떨어졌고, 대형 한글에서 ㅇ·ㅃ
  // 속공간이 메워져 덩어리로 보였다. 실측 기본값은 렌더 굵기와 반드시 같아야
  // 한다 — 어긋나면 폭 예산이 틀려 FittedBox 가 안전망 밖에서 개입한다.
  FontWeight fontWeight = FontWeight.w700,
  double letterSpacing = 0,
  double lineHeight = 1.0,
}) {
  if (!maxWidth.isFinite || maxWidth <= 0) {
    return cap;
  }
  final scaler = MediaQuery.textScalerOf(context);
  final baseStyle = DefaultTextStyle.of(context).style;
  var widest = 0.0;
  for (final text in texts) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      continue;
    }
    final painter = TextPainter(
      text: TextSpan(
        text: trimmed,
        style: baseStyle.copyWith(
          fontSize: cap,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
          height: lineHeight,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    if (width > widest) {
      widest = width;
    }
  }
  final budget = maxWidth * 0.98;
  if (widest <= budget) {
    return cap;
  }
  return (cap * budget / widest).clamp(min, cap).toDouble();
}

/// Center-clamps immersive study content to [soriStudyContentMaxWidth] so the
/// card grows with the viewport on tablets. Drop-in replacement for
/// [SoriCenterClamp] on fixed-focus flashcard/quiz screens — phones unchanged.
class SoriStudyClamp extends StatelessWidget {
  final Widget child;
  final AlignmentGeometry alignment;

  const SoriStudyClamp({
    super.key,
    required this.child,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => SoriCenterClamp(
        maxWidth: soriStudyContentMaxWidth(c.maxWidth),
        alignment: alignment,
        child: child,
      ),
    );
  }
}

/// When [maxWidth] is omitted, the same adaptive phone-to-tablet column is
/// used. Pass an explicit value for intentionally fixed-focus learning views.
/// 콘텐츠를 [maxWidth]로 클램프하는 듀오링고식 반응형 수평 padding.
///
/// 폰(availableWidth ≤ maxWidth)에선 [base]를 그대로 돌려줘 **시각 변화 0**,
/// 넓은 화면에선 잉여폭을 좌우로 절반씩 나눠 콘텐츠를 가운데 정렬한다.
/// 상하 padding은 [base] 값을 보존한다.
///
/// 예) `soriClampPadding(1200, maxWidth: 480)` → 좌우 각 +360, 가운데 480 컬럼.
EdgeInsets soriClampPadding(
  double availableWidth, {
  double? maxWidth,
  EdgeInsets base = const EdgeInsets.symmetric(horizontal: Spacing.lg),
}) {
  final resolvedMaxWidth =
      maxWidth ?? soriAdaptiveContentMaxWidth(availableWidth);
  final extra = ((availableWidth - resolvedMaxWidth) / 2).clamp(
    0.0,
    double.infinity,
  );
  return EdgeInsets.fromLTRB(
    base.left + extra,
    base.top,
    base.right + extra,
    base.bottom,
  );
}

/// 스크롤뷰를 감싸 **padding만** 반응형으로 클램프한다. viewport는 풀블리드로
/// 유지되므로 웹 스크롤바·RefreshIndicator가 창 가장자리에 고정된다
/// (Center+ConstrainedBox로 스크롤뷰 자체를 감싸는 방식의 단점 회피).
///
/// [builder]가 넘겨주는 padding을 스크롤뷰의 `padding:` 슬롯에 그대로 사용:
/// ```dart
/// SoriContentClamp(
///   base: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.md, Spacing.lg, Spacing.xl),
///   builder: (context, padding) => SingleChildScrollView(
///     padding: padding,
///     child: Column(...),
///   ),
/// )
/// ```
/// SafeArea는 포함하지 않는다(화면마다 위치가 달라 이중 inset 위험) — 호출부가
/// 기존 SafeArea를 유지한다. `CustomScrollView`(sliver) 화면은 이 위젯 대신
/// [soriClampPadding] 함수를 자체 `LayoutBuilder` 안에서 직접 호출한다.
class SoriContentClamp extends StatelessWidget {
  final EdgeInsets base;
  final double? maxWidth;
  final Widget Function(BuildContext context, EdgeInsets padding) builder;

  const SoriContentClamp({
    super.key,
    required this.builder,
    this.base = const EdgeInsets.symmetric(horizontal: Spacing.lg),
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final resolvedMaxWidth =
            maxWidth ?? soriAdaptiveContentMaxWidth(c.maxWidth);
        final pad = soriClampPadding(
          c.maxWidth,
          maxWidth: resolvedMaxWidth,
          base: base,
        );
        return builder(context, pad);
      },
    );
  }
}

/// 가용 [width]에서 [target] 폭 카드가 몇 개 들어가는지 산출해 grid 컬럼 수로
/// 반환한다. [min]~[max]로 클램프한다.
///
/// 폰(360~430)에서 기존 컬럼 수를 보존하려면 **호출부에서 [min]을 그 화면의
/// 현재 컬럼 수로 지정**한다 — 폰 산출값이 min 밑으로 내려가지 않으면 시각 변화 0.
/// 예) dojangcheop(현재 3컬럼): `soriGridColumns(width, target: 110, min: 3)`
///     → 360px서 3(유지), 768px서 더 많이.
///
/// [outerPadding]은 그리드 좌우 여백 합(기본 [Spacing.lg]×2), [spacing]은
/// 카드 사이 간격이다.
int soriGridColumns(
  double width, {
  double target = SoriBreakpoints.gridCardMin,
  int min = 2,
  int max = 6,
  double outerPadding = Spacing.lg * 2,
  double spacing = Spacing.lg,
}) {
  final usable = (width - outerPadding).clamp(0.0, double.infinity);
  // n*target + (n-1)*spacing ≤ usable  →  n ≤ (usable + spacing)/(target + spacing)
  final raw = ((usable + spacing) / (target + spacing)).floor();
  return raw.clamp(min, max);
}

/// 세로가 짧은 뷰포트(가로로 든 폰·분할 화면)에서 **넘치는 대신 스크롤**시킨다.
///
/// 학습 화면은 대개 `Column(고정 헤더 … Expanded(카드) … 고정 액션 바)` 꼴이다.
/// 이 구조는 뷰포트가 짧아지면 `Expanded` 가 0까지 줄어도 **고정 블록의 합**이
/// 남아 그대로 넘친다 — `Expanded` 는 음수가 될 수 없기 때문이다. 문법 화면이
/// 360×400 에서 25px 넘친 게 정확히 이 경우다(2026-08-07).
///
/// 규칙: 상자가 [minHeight] 이상이면 **지금까지와 완전히 같은 flex 레이아웃**
/// (시각 변화 0). 그보다 짧을 때만 [minHeight] 높이의 상자를 만들어 스크롤한다
/// — 자식은 그대로라 `Expanded` 도 정상 동작하고, 잘려 보이던 것이 스크롤로
/// 도달 가능해진다.
///
/// [minHeight] 는 "이 화면이 쓸 만하게 보이는 최소 높이"다. 상자의 높이가
/// 무한(부모가 이미 스크롤 중)이면 아무것도 하지 않고 [child] 를 그대로 준다.
class SoriMinHeightScroll extends StatelessWidget {
  final Widget child;
  final double minHeight;

  /// W10 T-V1(2026-09-05): 참이면 뷰포트가 [minHeight] 보다 **길 때도**
  /// 유한 높이를 그대로 상자에 채운다 — 안의 Column이 `Spacer`/`Expanded`/
  /// `mainAxisAlignment` 로 그 높이 전체에 분배될 수 있게(= "본문이 위쪽에
  /// 뭉친다" D-4 신고의 근본 원인: [SoriStandardPage] 등이 항상 `ListView` 라
  /// 짧은 콘텐츠가 위에 붙고 아래가 빈다). `false`(기본값)면 기존 동작과
  /// 완전히 같다 — 짧을 때만 스크롤 상자를 만든다.
  final bool fillViewport;

  const SoriMinHeightScroll({
    super.key,
    required this.child,
    required this.minHeight,
    this.fillViewport = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // ⚠️ 높이가 **무한**이면(부모가 이미 스크롤) 자식을 그대로 돌려준다 —
        //    자연 높이가 정답이고 여기서 스크롤을 겹치면 안 된다.
        //    단 그 경우 자식 Column 에 `Spacer`/`Expanded` 를 두면 안 된다:
        //    무한 높이 + flex 자식 = "RenderFlex children have non-zero flex
        //    but incoming height constraints are unbounded" 로 레이아웃이
        //    죽어 **화면이 통째로 빈다**(2026-08-12 Flughafen 시나리오 사고).
        //    하단 고정이 필요하면 flex 대신 `MainAxisAlignment.spaceBetween`
        //    2-자식 패턴을 써라 — 유한 높이에서만 벌어지고 무한에서는 무해하다.
        if (fillViewport && c.maxHeight.isFinite) {
          // 항상 뷰포트 높이를 최소 높이로 준다 — 짧으면 그대로, 길면 아래가
          // Spacer/Expanded 로 채워진다. `IntrinsicHeight` 로 감싸 Column이
          // 그 높이에 맞춰 자신을 측정하게 하고, 콘텐츠가 실제로 더 크면
          // `SingleChildScrollView` 가 넘침 대신 스크롤을 허용한다.
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight),
              child: IntrinsicHeight(child: child),
            ),
          );
        }
        if (!c.maxHeight.isFinite || c.maxHeight >= minHeight) return child;
        return SingleChildScrollView(
          child: SizedBox(height: minHeight, child: child),
        );
      },
    );
  }
}

/// 비스크롤 콘텐츠(Column/Expanded/Stack)를 [maxWidth]로 가운데 클램프한다.
/// 폰(부모 폭 ≤ maxWidth)에선 [child]가 폰 폭을 그대로 채워 **시각 변화 0**,
/// 넓은 화면에서만 단일 중앙 컬럼이 된다.
///
/// 내부 `SizedBox(width: double.infinity)`가 자식에게 항상 클램프된 폭을
/// 꽉 채우게 강제하므로, 감싸는 Column의 `crossAxisAlignment`(start/center/
/// stretch)와 **무관하게** 폰에서 정렬이 보존된다(= 회귀 0). 이 폭 강제가 없으면
/// 폭을 다 안 쓰는 Column을 Align이 중앙으로 밀어 폰에서 정렬이 바뀐다.
///
/// [SoriContentClamp]와의 차이: 저쪽은 *스크롤뷰 padding 슬롯*만 클램프해
/// viewport는 풀블리드(스크롤바·RefreshIndicator가 창 가장자리). 이쪽은
/// *위젯 자체*를 ConstrainedBox로 감싼다 → 스크롤 없는 Column 화면 전용.
/// 배경은 호출부의 Scaffold/Stack에 남겨야 풀블리드가 유지된다(이 위젯은
/// 콘텐츠만 감쌀 것).
///
/// ```dart
/// body: SafeArea(
///   child: SoriCenterClamp(
///     child: Padding(
///       padding: const EdgeInsets.all(Spacing.lg),
///       child: Column(children: [...]),
///     ),
///   ),
/// )
/// ```
class SoriCenterClamp extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  const SoriCenterClamp({
    super.key,
    required this.child,
    this.maxWidth = SoriBreakpoints.content,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
