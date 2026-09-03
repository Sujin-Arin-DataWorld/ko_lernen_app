import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'motion.dart';
import 'tokens.dart';

enum _SoriProgressMeterVariant { bar, segments, ring }

/// **SoriProgressMeter** — 진행도 시각화 3종 (§W-D D1).
///
/// - [SoriProgressMeter.bar] — 연속 선형 게이지 (기존 [SoriProgressBar]가
///   위임하는 대상).
/// - [SoriProgressMeter.segments] — 이산 칸 게이지 (한옥 건축 부재처럼
///   "몇 개 중 몇 개" 가 자연스러운 진행).
/// - [SoriProgressMeter.ring] — 원형 게이지 (중앙에 숫자/아이콘을 얹을 때).
///
/// 색: 채움 기본 [SoriColors.primary], 트랙 `SoriSurfaces.surfaceAlt`.
/// 라벨이 있으면 `Row[Expanded(meter), gap md, label]` — 라벨은
/// [SoriTextTheme.label] + tabular figures + `textMuted`.
///
/// 첫 등장 시 0→값 애니메이션(600ms, [SoriAnimation.gentle]).
/// [SoriMotion.reduceMotion] 이면 즉시 최종값 — 세그먼트도 칸 순서 지연
/// (40ms/칸) 없이 즉시 렌더한다.
class SoriProgressMeter extends StatefulWidget {
  const SoriProgressMeter.bar({
    super.key,
    required this.value,
    this.label,
    this.height = 10,
    this.color,
    this.trackColor,
    this.animate = true,
  }) : _variant = _SoriProgressMeterVariant.bar,
       filled = 0,
       total = 1,
       gap = 4,
       size = 56,
       stroke = 6,
       center = null;

  const SoriProgressMeter.segments({
    super.key,
    required this.filled,
    required this.total,
    this.label,
    this.height = 10,
    this.gap = 4,
    this.color,
  }) : _variant = _SoriProgressMeterVariant.segments,
       value = 0,
       trackColor = null,
       animate = true,
       size = 56,
       stroke = 6,
       center = null;

  const SoriProgressMeter.ring({
    super.key,
    required this.value,
    this.size = 56,
    this.stroke = 6,
    this.center,
    this.color,
  }) : _variant = _SoriProgressMeterVariant.ring,
       label = null,
       trackColor = null,
       animate = true,
       filled = 0,
       total = 1,
       height = 10,
       gap = 4;

  final _SoriProgressMeterVariant _variant;

  /// `.bar`/`.ring` 값 (0..1 로 클램프됨).
  final double value;

  /// `.segments` 채워진 칸 수.
  final int filled;

  /// `.segments` 전체 칸 수.
  final int total;

  final String? label;

  /// `.bar`/`.segments` 두께.
  final double height;

  /// `.segments` 칸 사이 간격.
  final double gap;

  final Color? color;

  /// `.bar` 전용 트랙 색 오버라이드 — 기본은 `s.surfaceAlt`.
  /// 기존 [SoriProgressBar.trackColor] 호출부(퀘스트 화면 2곳)를 무손실
  /// 위임하기 위한 추가 파라미터.
  final Color? trackColor;

  /// `.bar` 전용 — false 면 값 변경을 즉시 반영(트윈 없음). 기존
  /// [SoriProgressBar.animated] 호출부를 무손실 위임하기 위한 추가 파라미터.
  final bool animate;

  /// `.ring` 지름.
  final double size;

  /// `.ring` 선 두께.
  final double stroke;

  /// `.ring` 중앙에 얹는 위젯 (숫자/아이콘 등).
  final Widget? center;

  @override
  State<SoriProgressMeter> createState() => _SoriProgressMeterState();
}

class _SoriProgressMeterState extends State<SoriProgressMeter> {
  // MediaQuery.maybeOf() (via SoriMotion.reduceMotion) may not be called
  // from initState() — InheritedModel asserts on it (measured: "was called
  // before initState() completed"). didChangeDependencies() runs right
  // after initState() and before the first build(), so reading it there
  // still lets reduce-motion render its final state on the very first
  // pump — the _initialized guard just keeps the one-shot stagger schedule
  // from re-running on later dependency changes.
  bool _reduceMotion = false;
  late List<bool> _segmentRevealed;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _segmentRevealed = List<bool>.generate(
      widget.total,
      (i) => i >= widget.filled,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    _reduceMotion = SoriMotion.reduceMotion(context);
    if (_reduceMotion) {
      _segmentRevealed = List<bool>.generate(widget.total, (_) => true);
      return;
    }
    for (var i = 0; i < widget.filled && i < widget.total; i++) {
      Future<void>.delayed(Duration(milliseconds: 40 * i), () {
        if (mounted) {
          setState(() => _segmentRevealed[i] = true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return switch (widget._variant) {
      _SoriProgressMeterVariant.bar => _bar(context, s),
      _SoriProgressMeterVariant.segments => _segments(context, s),
      _SoriProgressMeterVariant.ring => _ring(context, s),
    };
  }

  Widget _withLabel(BuildContext context, SoriSurfaces s, Widget meter) {
    final label = widget.label;
    if (label == null) {
      return meter;
    }
    // 실측(320dp·200% 텍스트, `sori_stage_today_matte_test.dart` "long
    // German reward wraps..."): 라벨이 `Row`의 비-flex 자식이면 자기 고유
    // 폭을 그대로 요구해 174px RenderFlex 오버플로가 났다(FlutterError 덤프
    // — creator: Row ← SoriProgressMeter). `Flexible` 로 감싸 남는 폭
    // 안에서만 차지하게 하고, 미터 쪽에 더 큰 flex(3)를 줘 평소 짧은
    // 라벨에서는 미터가 여전히 거의 꽉 차 보이게 한다.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 3, child: meter),
        const SizedBox(width: Spacing.md),
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.end,
            style: SoriTextTheme.of(context).label.copyWith(
              color: s.textMuted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bar(BuildContext context, SoriSurfaces s) {
    final fg = widget.color ?? SoriColors.primary;
    final bg = widget.trackColor ?? s.surfaceAlt;
    final duration = (!widget.animate || _reduceMotion)
        ? Duration.zero
        : SoriMotion.verySlow;
    final meter = TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: widget.value.clamp(0.0, 1.0)),
      duration: duration,
      curve: SoriAnimation.gentle,
      builder: (context, v, _) => ClipRRect(
        borderRadius: BorderRadius.circular(widget.height / 2),
        child: SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              ColoredBox(color: bg),
              FractionallySizedBox(
                widthFactor: v,
                child: ColoredBox(color: fg),
              ),
            ],
          ),
        ),
      ),
    );
    return _withLabel(context, s, meter);
  }

  Widget _segments(BuildContext context, SoriSurfaces s) {
    final fg = widget.color ?? SoriColors.primary;
    final bg = s.surfaceAlt;
    final cells = Row(
      children: [
        for (var i = 0; i < widget.total; i++) ...[
          if (i > 0) SizedBox(width: widget.gap),
          Expanded(
            child: AnimatedOpacity(
              opacity: i < widget.filled && !_segmentRevealed[i] ? 0 : 1,
              duration: _reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              curve: SoriAnimation.gentle,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.height / 2),
                child: SizedBox(
                  height: widget.height,
                  child: ColoredBox(color: i < widget.filled ? fg : bg),
                ),
              ),
            ),
          ),
        ],
      ],
    );
    return _withLabel(context, s, cells);
  }

  Widget _ring(BuildContext context, SoriSurfaces s) {
    final fg = widget.color ?? SoriColors.primary;
    final bg = s.surfaceAlt;
    final duration = _reduceMotion ? Duration.zero : SoriMotion.verySlow;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: widget.value.clamp(0.0, 1.0)),
      duration: duration,
      curve: SoriAnimation.gentle,
      builder: (context, v, _) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _SoriProgressRingPainter(
            value: v,
            stroke: widget.stroke,
            color: fg,
            track: bg,
          ),
          child: widget.center == null ? null : Center(child: widget.center),
        ),
      ),
    );
  }
}

class _SoriProgressRingPainter extends CustomPainter {
  const _SoriProgressRingPainter({
    required this.value,
    required this.stroke,
    required this.color,
    required this.track,
  });

  final double value;
  final double stroke;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final clamped = value.clamp(0.0, 1.0);
    final sweep = 2 * math.pi * clamped;
    if (sweep > 0) {
      final fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweep,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SoriProgressRingPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.stroke != stroke ||
      oldDelegate.color != color ||
      oldDelegate.track != track;
}
