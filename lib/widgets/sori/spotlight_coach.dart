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
    final step = widget.steps[_i];
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
          GestureDetector(
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

          // ─ 말풍선 툴팁
          if (_targetRect != null) _buildTooltip(context, step),
        ],
      ),
    );
  }

  Widget _buildTooltip(BuildContext context, SpotlightStep step) {
    final screenSize = MediaQuery.of(context).size;
    final rect = _targetRect!;
    final spaceAbove = rect.top;
    final spaceBelow = screenSize.height - rect.bottom;

    final tooltip = _CoachTooltip(
      step: step,
      stepIndex: _i,
      totalSteps: widget.steps.length,
      onNext: _next,
      onSkip: _skipAll,
    );

    // 위·아래 중 넓은 쪽에 배치.
    final placeAbove = spaceAbove > spaceBelow;
    final avail = placeAbove ? spaceAbove : spaceBelow;
    // 타겟이 화면 대부분을 차지해 위·아래가 모두 좁으면 화면 하단에 고정해
    // 말풍선이 화면 밖으로 잘리지 않게 한다(타겟 일부를 가리더라도 가독성 우선).
    if (avail < 180) {
      return Positioned(left: 16, right: 16, bottom: 24, child: tooltip);
    }
    if (placeAbove) {
      return Positioned(
        left: 16,
        right: 16,
        bottom: screenSize.height - rect.top + 12,
        child: tooltip,
      );
    }
    return Positioned(
      left: 16,
      right: 16,
      top: rect.bottom + 12,
      child: tooltip,
    );
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
          constraints: const BoxConstraints(maxWidth: 320),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(SoriRadius.lg),
            boxShadow: SoriElevation.high,
            border: Border.all(
              color: SoriColors.tiger.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 옵션 아이콘 + 제목
              if (step.icon != null) ...[
                Icon(step.icon, color: SoriColors.tiger, size: 22),
                const SizedBox(height: Spacing.xs),
              ],
              Text(
                step.title,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0E1A18),
                  letterSpacing: -0.2,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: Spacing.xs),

              // 본문
              Text(
                step.body,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4A6560),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: Spacing.md),

              // 단계 dot
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(totalSteps, (i) {
                  final isCurrent = i == stepIndex;
                  return Container(
                    margin: const EdgeInsets.only(right: 5),
                    width: isCurrent ? 8 : 6,
                    height: isCurrent ? 8 : 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCurrent ? SoriColors.tiger : Colors.transparent,
                      border: isCurrent
                          ? null
                          : Border.all(
                              color: SoriColors.tiger.withValues(alpha: 0.4),
                              width: 1.2,
                            ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: Spacing.md),

              // 버튼 행 — Flexible+ellipsis로 308px overflow 방지
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Flexible(
                    child: TextButton(
                      onPressed: onSkip,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF7A9490),
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        t.navTourSkip,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  SoriButton.filled(
                    label: isLast ? t.navTourDone : t.navTourNext,
                    size: SoriButtonSize.sm,
                    onTap: onNext,
                  ),
                ],
              ),
            ],
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
