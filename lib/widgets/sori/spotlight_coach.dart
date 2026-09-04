import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'button.dart';
import 'tokens.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

/// 구멍(cutout) 모양.
enum ShapeKind {
  /// Rounded rectangle — 카드·섹션 라벨에.
  rrect,

  /// Circle — BottomNav 아이콘처럼 둥근 타겟에.
  circle,
}

/// 코치마크 말풍선 카드의 테스트 손잡이 + 폭 상한(dp).
///
/// 상한은 태블릿에서 카드가 화면 폭을 다 먹지 않게 하는 계약이다 —
/// 회귀 테스트가 이 상수로 검증한다.
const Key kSpotlightTooltipKey = Key('sori-coach-tooltip');
const double kSpotlightTooltipMaxWidth = 340;

/// 스포트라이트 코치마크 한 단계 명세.
class SpotlightStep {
  final GlobalKey targetKey;
  final String title;
  final String body;
  final IconData? icon;
  final EdgeInsets cutoutPadding;
  final double cutoutRadius;
  final ShapeKind shape;

  const SpotlightStep({
    required this.targetKey,
    required this.title,
    required this.body,
    this.icon,
    this.cutoutPadding = const EdgeInsets.all(8),
    this.cutoutRadius = 16,
    this.shape = ShapeKind.rrect,
  });
}

/// Google식 스포트라이트 코치마크.
///
/// 외부 패키지 없음. [Overlay] 위에 반투명 딤 + 구멍(cutout) + 말풍선을 올려
/// 단계별(next → next → done)로 UI 요소를 짚어준다.
///
/// ```dart
/// SpotlightCoach.show(
///   context,
///   steps: [...],
///   onComplete: () => Storage.setTutHomeTourSeen(),
/// );
/// ```
class SpotlightCoach {
  SpotlightCoach._();

  static void show(
    BuildContext context, {
    required List<SpotlightStep> steps,
    required VoidCallback onComplete,
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      onComplete();
      return;
    }
    if (steps.isEmpty) {
      onComplete();
      return;
    }

    final reduceMotion = SoriMotion.reduceMotion(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _SpotlightLayer(
        steps: steps,
        reduceMotion: reduceMotion,
        onDone: () {
          entry.remove();
          onComplete();
        },
      ),
    );
    overlay.insert(entry);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal — _SpotlightLayer
// ─────────────────────────────────────────────────────────────────────────────

class _SpotlightLayer extends StatefulWidget {
  const _SpotlightLayer({
    required this.steps,
    required this.reduceMotion,
    required this.onDone,
  });

  final List<SpotlightStep> steps;
  final bool reduceMotion;
  final VoidCallback onDone;

  @override
  State<_SpotlightLayer> createState() => _SpotlightLayerState();
}

class _SpotlightLayerState extends State<_SpotlightLayer>
    with SingleTickerProviderStateMixin {
  int _i = 0;
  AnimationController? _pulse;
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    if (!widget.reduceMotion) {
      _pulse = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      )..repeat(reverse: true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  // ── 타겟 측정 ────────────────────────────────────────────────────────────

  Rect? _rectFor(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) {
      return null;
    }
    final ro = ctx.findRenderObject();
    if (ro is! RenderBox) {
      return null;
    }
    if (!ro.hasSize) {
      return null;
    }
    final offset = ro.localToGlobal(Offset.zero);
    return offset & ro.size;
  }

  void _measure() {
    if (!mounted) {
      return;
    }
    final rect = _rectFor(widget.steps[_i].targetKey);
    if (rect == null) {
      _skipToNextMeasurable();
      return;
    }
    setState(() {
      _targetRect = rect;
    });
  }

  void _skipToNextMeasurable() {
    var next = _i + 1;
    while (next < widget.steps.length) {
      final rect = _rectFor(widget.steps[next].targetKey);
      if (rect != null) {
        setState(() {
          _i = next;
          _targetRect = rect;
        });
        return;
      }
      next++;
    }
    widget.onDone();
  }

  // ── 네비게이션 ───────────────────────────────────────────────────────────

  void _next() {
    final nextIndex = _i + 1;
    if (nextIndex >= widget.steps.length) {
      widget.onDone();
      return;
    }
    setState(() {
      _i = nextIndex;
      _targetRect = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _skipAll() {
    widget.onDone();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final step = widget.steps[_i];
    final isLast = _i == widget.steps.length - 1;
    final padding = step.cutoutPadding;

    // cutoutPadding을 rect에 적용해 painter에 최종 hole만 전달
    Rect? hole;
    if (_targetRect != null) {
      final r = _targetRect!;
      hole = Rect.fromLTRB(
        r.left - padding.left,
        r.top - padding.top,
        r.right + padding.right,
        r.bottom + padding.bottom,
      );
    }

    final pulseAnim = _pulse ?? const AlwaysStoppedAnimation<double>(0.0);

    return Positioned.fill(
      child: Stack(
        children: [
          // ─ 딤 + 구멍 레이어 (탭 → 다음 단계)
          Semantics(
            button: true,
            label: isLast ? t.navTourDone : t.navTourNext,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _next,
              child: AnimatedBuilder(
                animation: pulseAnim,
                builder: (ctx, _) {
                  return CustomPaint(
                    painter: _SpotlightPainter(
                      hole: hole,
                      radius: step.cutoutRadius,
                      shape: step.shape,
                      pulse: pulseAnim.value,
                      reduceMotion: widget.reduceMotion,
                    ),
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ),
          ),

          // ─ 말풍선 툴팁
          if (_targetRect != null) _buildTooltip(context, step),
        ],
      ),
    );
  }

  Widget _buildTooltip(BuildContext context, SpotlightStep step) {
    final mq = MediaQuery.of(context);
    final rect = _targetRect!;

    // 말풍선은 **타겟 옆**에 붙는 작은 카드다(2026-08-06 Jin 태블릿 실기기).
    // 예전에는 `Positioned(left: 16, right: 16)` 으로 화면 폭 전체를 잡았는데,
    // 그러면 두 가지가 동시에 깨졌다:
    //   ① `Container(constraints: maxWidth 320)` 이 무력화된다 — 부모가 tight
    //      constraint 를 주면 `BoxConstraints.enforce` 가 320 을 부모 폭으로
    //      끌어올려 태블릿에서 700dp 짜리 흰 판이 떴다.
    //   ② 왼쪽 레일의 `Üben` 을 설명하면서 카드는 화면 한가운데까지 뻗어,
    //      "지금 뭘 가리키는 거지?" 라는 인지 부하가 생겼다.
    // [_CoachTooltipLayout] 이 자식의 **실제 크기**를 보고 타겟 옆/위/아래
    // 중 들어가는 자리를 골라 safe-area 안으로 클램프한다.
    return Positioned.fill(
      child: CustomSingleChildLayout(
        delegate: _CoachTooltipLayout(target: rect, safeInsets: mq.padding),
        child: _CoachTooltip(
          step: step,
          stepIndex: _i,
          totalSteps: widget.steps.length,
          onNext: _next,
          onSkip: _skipAll,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal — _CoachTooltipLayout
// ─────────────────────────────────────────────────────────────────────────────

/// 말풍선을 놓을 방향.
enum _CoachSide { above, below, left, right }

/// 타겟 사각형 옆에 말풍선을 붙이는 레이아웃 델리게이트.
///
/// [SingleChildLayoutDelegate] 를 쓰는 이유: 자식의 **측정된 크기**를 알아야
/// "오른쪽에 들어가나?"를 판단할 수 있는데, 위젯 빌드 시점에는 알 수 없다.
/// (Material `Tooltip` 도 같은 방식이다.)
class _CoachTooltipLayout extends SingleChildLayoutDelegate {
  const _CoachTooltipLayout({required this.target, required this.safeInsets});

  /// 스포트라이트가 뚫은 타겟 사각형(전역 좌표).
  final Rect target;

  /// 상태바·제스처바 등 시스템 인셋. 말풍선이 그 뒤로 잘리면 안 된다.
  final EdgeInsets safeInsets;

  /// 카드 최대 폭. 태블릿이라고 700dp 짜리 말풍선을 만들 이유가 없다.
  static const double kMaxWidth = kSpotlightTooltipMaxWidth;

  /// 타겟과 카드 사이 간격.
  static const double kGap = 12;

  /// 화면 가장자리와 카드 사이 최소 여백.
  static const double kMargin = 12;

  /// 타겟 중심이 이 비율 안쪽 가장자리에 있으면 **옆 배치**를 먼저 시도한다.
  /// 세로 레일(왼쪽 끝)·설정 아이콘(오른쪽 끝)이 여기 걸린다.
  static const double kEdgeBandFraction = 0.28;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final availableWidth =
        constraints.maxWidth - safeInsets.left - safeInsets.right - kMargin * 2;
    final availableHeight =
        constraints.maxHeight -
        safeInsets.top -
        safeInsets.bottom -
        kMargin * 2;
    // 짧은 가로모드에서도 절대 화면 밖으로 나가지 않게 maxHeight 를 준다.
    // 카드 내부가 스크롤 가능하므로 잘리지 않고 줄어든다.
    return BoxConstraints(
      maxWidth: math.max(160.0, math.min(kMaxWidth, availableWidth)),
      maxHeight: math.max(80.0, availableHeight),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final minX = safeInsets.left + kMargin;
    final maxX = size.width - safeInsets.right - kMargin;
    final minY = safeInsets.top + kMargin;
    final maxY = size.height - safeInsets.bottom - kMargin;

    final spaceRight = maxX - (target.right + kGap);
    final spaceLeft = (target.left - kGap) - minX;
    final spaceBelow = maxY - (target.bottom + kGap);
    final spaceAbove = (target.top - kGap) - minY;

    final centerX = target.center.dx;
    final onLeftHalf = centerX <= size.width / 2;
    final edgeBand = size.width * kEdgeBandFraction;
    final nearHorizontalEdge =
        centerX < edgeBand || centerX > size.width - edgeBand;

    // 가장자리 타겟(레일 아이콘 등)은 옆에 붙이는 쪽이 훨씬 잘 읽힌다.
    // 화면 가운데 타겟(카드·섹션 라벨)은 아래→위가 자연스럽다.
    final near = onLeftHalf ? _CoachSide.right : _CoachSide.left;
    final far = onLeftHalf ? _CoachSide.left : _CoachSide.right;
    final order = nearHorizontalEdge
        ? <_CoachSide>[near, far, _CoachSide.below, _CoachSide.above]
        : <_CoachSide>[_CoachSide.below, _CoachSide.above, near, far];

    _CoachSide? chosen;
    for (final side in order) {
      if (_fits(
        side,
        childSize,
        spaceLeft,
        spaceRight,
        spaceAbove,
        spaceBelow,
      )) {
        chosen = side;
        break;
      }
    }
    chosen ??= _roomiest(
      childSize,
      spaceLeft,
      spaceRight,
      spaceAbove,
      spaceBelow,
    );

    double x;
    double y;
    if (chosen == _CoachSide.right) {
      x = target.right + kGap;
      y = target.center.dy - childSize.height / 2;
    } else if (chosen == _CoachSide.left) {
      x = target.left - kGap - childSize.width;
      y = target.center.dy - childSize.height / 2;
    } else if (chosen == _CoachSide.below) {
      x = target.center.dx - childSize.width / 2;
      y = target.bottom + kGap;
    } else {
      x = target.center.dx - childSize.width / 2;
      y = target.top - kGap - childSize.height;
    }

    // 화면(=safe area) 안으로 클램프. 카드가 남은 공간보다 크면 상단/좌측에
    // 붙인다 — `clamp` 는 lower > upper 를 던지므로 상한을 하한으로 올린다.
    final upperX = math.max(minX, maxX - childSize.width);
    final upperY = math.max(minY, maxY - childSize.height);
    return Offset(x.clamp(minX, upperX), y.clamp(minY, upperY));
  }

  bool _fits(
    _CoachSide side,
    Size childSize,
    double spaceLeft,
    double spaceRight,
    double spaceAbove,
    double spaceBelow,
  ) {
    if (side == _CoachSide.right) {
      return spaceRight >= childSize.width;
    }
    if (side == _CoachSide.left) {
      return spaceLeft >= childSize.width;
    }
    if (side == _CoachSide.below) {
      return spaceBelow >= childSize.height;
    }
    return spaceAbove >= childSize.height;
  }

  /// 어느 쪽에도 안 들어가면 "가장 덜 부족한" 쪽. 가로/세로를 같은 잣대로
  /// 비교하려고 필요 크기 대비 비율을 쓴다.
  _CoachSide _roomiest(
    Size childSize,
    double spaceLeft,
    double spaceRight,
    double spaceAbove,
    double spaceBelow,
  ) {
    final w = math.max(1.0, childSize.width);
    final h = math.max(1.0, childSize.height);
    final ratios = <_CoachSide, double>{
      _CoachSide.right: spaceRight / w,
      _CoachSide.left: spaceLeft / w,
      _CoachSide.below: spaceBelow / h,
      _CoachSide.above: spaceAbove / h,
    };
    var best = _CoachSide.below;
    var bestRatio = double.negativeInfinity;
    ratios.forEach((side, ratio) {
      if (ratio > bestRatio) {
        best = side;
        bestRatio = ratio;
      }
    });
    return best;
  }

  @override
  bool shouldRelayout(_CoachTooltipLayout oldDelegate) {
    return oldDelegate.target != target || oldDelegate.safeInsets != safeInsets;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal — _CoachTooltip
// ─────────────────────────────────────────────────────────────────────────────

class _CoachTooltip extends StatelessWidget {
  const _CoachTooltip({
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.onNext,
    required this.onSkip,
  });

  final SpotlightStep step;
  final int stepIndex;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final isLast = stepIndex == totalSteps - 1;

    return Semantics(
      liveRegion: true,
      label: '${step.title}. ${step.body}',
      child: Material(
        color: Colors.transparent,
        child: Container(
          key: kSpotlightTooltipKey,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(SoriRadius.lg),
            boxShadow: SoriElevation.high,
            border: Border.all(
              color: SoriColors.tiger.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(Spacing.md),
          // 짧은 가로모드에서 카드가 화면보다 높으면 잘리는 대신 스크롤된다
          // (`_CoachTooltipLayout` 이 maxHeight 를 준다). 들어갈 때는
          // `constraints.constrain(child.size)` 라 자연 높이 그대로다.
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 아이콘 + 제목을 **한 줄**로 — 세로가 짧은 가로모드에서
                // 아이콘 전용 줄은 순수 손실이다.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (step.icon != null) ...[
                      Icon(step.icon, color: SoriColors.tiger, size: 20),
                      const SizedBox(width: Spacing.sm),
                    ],
                    Flexible(
                      child: Text(
                        step.title,
                        style: const TextStyle(
                          fontFamily: SoriFonts.sans,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0E1A18),
                          letterSpacing: -0.2,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.xs),

                // 본문
                Text(
                  step.body,
                  style: const TextStyle(
                    fontFamily: SoriFonts.sans,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4A6560),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: Spacing.md),

                // 단계 dot + "2 / 5" — dot 만 있으면 총 몇 단계인지 세야 한다.
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: List.generate(totalSteps, (i) {
                          final isCurrent = i == stepIndex;
                          return Container(
                            width: isCurrent ? 8 : 6,
                            height: isCurrent ? 8 : 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCurrent
                                  ? SoriColors.tiger
                                  : Colors.transparent,
                              border: isCurrent
                                  ? null
                                  : Border.all(
                                      color: SoriColors.tiger.withValues(
                                        alpha: 0.4,
                                      ),
                                      width: 1.2,
                                    ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Text(
                      '${stepIndex + 1} / $totalSteps',
                      style: const TextStyle(
                        fontFamily: SoriFonts.sans,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        // 구 #6B827D 은 흰 카드 위 4.11:1 로 WCAG AA(4.5) 미달이었다
                        // (2026-08-07 접근성 게이트). 13.5px 도 large text 예외에
                        // 못 들어가므로 아래 Überspringen 과 같은 톤으로 맞춘다.
                        color: Color(0xFF4A6560),
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.sm),

                // 버튼 행 — Flexible+ellipsis로 308px overflow 방지.
                // Überspringen 은 secondary 지만 **비활성처럼 보이면 안 된다**
                // (구 #7A9490 은 흰 배경 대비 2.9:1). #4A6560 = 7.0:1.
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Flexible(
                      child: TextButton(
                        onPressed: onSkip,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF4A6560),
                          // ⚠️ 가로 padding 만 0 이다. 예전에 `EdgeInsets.zero` +
                          // `Size.zero` + `shrinkWrap` 으로 눌러 놨더니 탭 영역이
                          // **13dp 높이**가 됐다(2026-08-07 접근성 게이트).
                          // 폭은 여전히 자유롭게 줄어들어 짧은 가로모드 overflow
                          // 방어는 그대로 유지되고, 높이만 48dp 를 보장한다.
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.xs,
                          ),
                          minimumSize: const Size(0, kMinInteractiveDimension),
                          tapTargetSize: MaterialTapTargetSize.padded,
                        ),
                        child: Text(
                          t.navTourSkip,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: SoriFonts.sans,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Flexible(
                      child: SoriButton.filled(
                        label: isLast ? t.navTourDone : t.navTourNext,
                        trailingIcon: isLast
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        size: SoriButtonSize.sm,
                        onTap: onNext,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal — _SpotlightPainter
// ─────────────────────────────────────────────────────────────────────────────

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({
    required this.hole,
    required this.radius,
    required this.shape,
    required this.pulse,
    required this.reduceMotion,
  });

  final Rect? hole;
  final double radius;
  final ShapeKind shape;
  final double pulse;
  final bool reduceMotion;

  static const double _dimAlpha = 0.72;

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Offset.zero & size;

    if (hole == null) {
      // 구멍 없이 전체 딤
      canvas.drawRect(
        fullRect,
        Paint()..color = Colors.black.withValues(alpha: _dimAlpha),
      );
      return;
    }

    // 딤 레이어 (구멍 있음)
    final full = Path()..addRect(fullRect);
    final cut = _cutPath(hole!);
    final dimPath = Path.combine(PathOperation.difference, full, cut);
    canvas.drawPath(
      dimPath,
      Paint()..color = Colors.black.withValues(alpha: _dimAlpha),
    );

    // 펄스 링 (reduce-motion 시 정적 테두리)
    if (reduceMotion) {
      _drawStaticBorder(canvas);
    } else {
      _drawPulseRing(canvas);
    }
  }

  Path _cutPath(Rect r) {
    if (shape == ShapeKind.circle) {
      final center = r.center;
      final radius = r.longestSide / 2 + 4;
      return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    } else {
      return Path()
        ..addRRect(RRect.fromRectAndRadius(r, Radius.circular(radius)));
    }
  }

  void _drawStaticBorder(Canvas canvas) {
    final paint = Paint()
      ..color = SoriColors.tiger.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    if (shape == ShapeKind.circle) {
      final center = hole!.center;
      final r = hole!.longestSide / 2 + 4;
      canvas.drawCircle(center, r, paint);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(hole!, Radius.circular(radius)),
        paint,
      );
    }
  }

  void _drawPulseRing(Canvas canvas) {
    // pulse: 0.0 ~ 1.0 (AnimationController repeat(reverse:true))
    final expand = 2 + 6 * pulse;
    final alpha = 0.7 - 0.5 * pulse;

    final paint = Paint()
      ..color = SoriColors.tiger.withValues(alpha: alpha)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    if (shape == ShapeKind.circle) {
      final center = hole!.center;
      final r = hole!.longestSide / 2 + 4 + expand;
      canvas.drawCircle(center, r, paint);
    } else {
      final expanded = hole!.inflate(expand);
      canvas.drawRRect(
        RRect.fromRectAndRadius(expanded, Radius.circular(radius + expand)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) {
    return hole != old.hole ||
        pulse != old.pulse ||
        shape != old.shape ||
        radius != old.radius;
  }
}
