import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'celebration.dart';
import 'tokens.dart';

/// **DancheongBurst** — 복주머니 시트와 엽전 시트가 "파박" 두 번 터지는 정답 축하.
///
/// 입자를 절차적으로 흩뿌리지 않고, 작가가 배치까지 구성해 둔 두 장의 투명 PNG를
/// **통째로** 확 키우며 터뜨린다. 반짝임 궤적·글로우가 원본 구성 그대로 살아난다.
///
/// 두 장을 살짝 어긋난 타이밍(0ms / 70ms)으로 쏘는 게 "파-박"의 핵심이다.
/// 동시에 터지면 한 번의 뭉툭한 팝이 되고, 어긋나면 두 번 얻어맞는 느낌이 난다.
/// 엽전이 조금 더 멀리 퍼지고 서로 반대로 미세하게 회전해, 두 장이 겹쳐 있다는
/// 인상 대신 하나의 폭발이 두 겹으로 번지는 인상을 준다.
///
/// ```dart
/// DancheongBurst.fire(context, origin: mascotCenter);
/// ```
///
/// [SoriCelebration]의 Overlay 구조를 따르므로 카드 경계에 잘리지 않는다.
/// 시트가 아직 디코딩되지 않았거나 PNG가 없으면 절차적 [SoriCelebration.burst]로
/// 폴백한다 — 에셋 없이도 정상 동작. `MediaQuery.disableAnimations`면 no-op.
class DancheongBurst {
  DancheongBurst._();

  static const _pouchSheet = 'assets/illustrations/burst/burst_pouches.png';
  static const _coinSheet = 'assets/illustrations/burst/burst_coins.png';

  static ui.Image? _pouches;
  static ui.Image? _coins;
  static bool _loading = false;
  static bool _failed = false;

  /// 시트가 준비됐는지. 테스트/폴백 분기용.
  static bool get ready => _pouches != null && _coins != null;

  /// 시트를 미리 디코딩해 첫 정답에서 폴백이 뜨는 걸 막는다.
  /// 실패해도 조용히 넘어간다 (폴백 경로가 받아준다).
  static Future<void> preload() async {
    if (ready || _loading || _failed) return;
    _loading = true;
    try {
      final pouches = await _decode(_pouchSheet);
      final coins = await _decode(_coinSheet);
      _pouches = pouches;
      _coins = coins;
    } catch (_) {
      _failed = true;
    } finally {
      _loading = false;
    }
  }

  static Future<ui.Image> _decode(String asset) {
    final completer = Completer<ui.Image>();
    final stream = AssetImage(asset).resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        stream.removeListener(listener);
        completer.complete(info.image);
      },
      onError: (error, stack) {
        stream.removeListener(listener);
        completer.completeError(error, stack);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  /// 일회성 버스트를 [Overlay]에 띄운다. 780ms 후 스스로 사라진다.
  ///
  /// [intensity]는 최종 크기 배율 (1.0 = 기본 폭 300dp).
  static void fire(
    BuildContext context, {
    required Offset origin,
    double intensity = 1.0,
  }) {
    if (SoriMotion.reduceMotion(context)) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final pouches = _pouches;
    final coins = _coins;
    if (pouches == null || coins == null) {
      // 시트 미준비 → 절차적 버스트로 폴백 + 다음을 위해 로드 시작.
      unawaited(preload());
      SoriCelebration.burst(context, origin: origin, particles: 26);
      return;
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _BurstLayer(
        origin: origin,
        pouches: pouches,
        coins: coins,
        intensity: intensity,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

// ─────────────────────────────────────────────────────────────────────────

/// A safe, paint-ready burst placement for the current overlay viewport.
class DancheongBurstPlacement {
  const DancheongBurstPlacement({
    required this.origin,
    required this.intensity,
    required this.maxPaintBounds,
  });

  final Offset origin;
  final double intensity;
  final Rect maxPaintBounds;
}

/// Keeps the maximum expanded and rotated sheet inside a phone viewport.
///
/// Quest mascots intentionally live just above the top-right card edge. Their
/// global centre is therefore a poor centre for a 300dp celebration sheet on a
/// narrow phone. This helper shifts and, only when necessary, scales the burst
/// while preserving its normal size on larger viewports.
class DancheongBurstLayout {
  DancheongBurstLayout._();

  static const double baseWidth = 300;
  static const double _maxReach = 1.26;
  static const double _edgeMargin = 12;
  static const double _rotationPadding = 0.08;
  static const double _liftPadding = 0.06;

  static DancheongBurstPlacement fit({
    required Size viewport,
    required Offset preferredOrigin,
    required double intensity,
    double heightOverWidth = 2 / 3,
  }) {
    final requestedIntensity = math.max(0.0, intensity).toDouble();
    final safeHeightOverWidth = math.max(0.01, heightOverWidth).toDouble();
    final requestedWidth = baseWidth * requestedIntensity * _maxReach;
    final horizontalExtent = requestedWidth * (0.5 + _rotationPadding);
    final verticalExtent =
        requestedWidth *
        (safeHeightOverWidth / 2 + _liftPadding + _rotationPadding);
    final availableWidth = math
        .max(0.0, viewport.width - 2 * _edgeMargin)
        .toDouble();
    final availableHeight = math
        .max(0.0, viewport.height - 2 * _edgeMargin)
        .toDouble();
    final widthScale = horizontalExtent == 0
        ? 1.0
        : availableWidth / (horizontalExtent * 2);
    final heightScale = verticalExtent == 0
        ? 1.0
        : availableHeight / (verticalExtent * 2);
    final scale = math
        .max(0.0, math.min(1.0, math.min(widthScale, heightScale)))
        .toDouble();
    final resolvedIntensity = requestedIntensity * scale;
    final resolvedWidth = baseWidth * resolvedIntensity * _maxReach;
    final resolvedHorizontalExtent = resolvedWidth * (0.5 + _rotationPadding);
    final resolvedVerticalExtent =
        resolvedWidth *
        (safeHeightOverWidth / 2 + _liftPadding + _rotationPadding);
    final origin = Offset(
      _clampAxis(preferredOrigin.dx, viewport.width, resolvedHorizontalExtent),
      _clampAxis(preferredOrigin.dy, viewport.height, resolvedVerticalExtent),
    );

    return DancheongBurstPlacement(
      origin: origin,
      intensity: resolvedIntensity,
      maxPaintBounds: Rect.fromCenter(
        center: origin,
        width: resolvedHorizontalExtent * 2,
        height: resolvedVerticalExtent * 2,
      ),
    );
  }

  static double _clampAxis(double value, double length, double extent) {
    final inset = math.min(length / 2, _edgeMargin + extent).toDouble();
    return value.clamp(inset, length - inset).toDouble();
  }
}

class _BurstLayer extends StatefulWidget {
  final Offset origin;
  final ui.Image pouches;
  final ui.Image coins;
  final double intensity;
  final VoidCallback onDone;

  const _BurstLayer({
    required this.origin,
    required this.pouches,
    required this.coins,
    required this.intensity,
    required this.onDone,
  });

  @override
  State<_BurstLayer> createState() => _BurstLayerState();
}

class _BurstLayerState extends State<_BurstLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 780),
        )..addStatusListener((s) {
          if (s == AnimationStatus.completed) widget.onDone();
        });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => CustomPaint(
              painter: _SheetBurstPainter(
                pouches: widget.pouches,
                coins: widget.coins,
                origin: widget.origin,
                intensity: widget.intensity,
                t: _ctrl.value,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 한 장의 시트가 터지는 방식.
class _Shot {
  final ui.Image image;

  /// 발사 지연 (0..1 정규화). 두 장을 어긋나게 해 "파-박"을 만든다.
  final double delay;

  /// 최종 폭 배율. 엽전이 더 멀리 퍼진다.
  final double reach;

  /// 총 회전량(rad). 서로 반대로 살짝 돌아 겹침 인상을 지운다.
  final double spin;

  const _Shot({
    required this.image,
    required this.delay,
    required this.reach,
    required this.spin,
  });
}

class _SheetBurstPainter extends CustomPainter {
  final ui.Image pouches;
  final ui.Image coins;
  final Offset origin;
  final double intensity;
  final double t; // 0..1

  _SheetBurstPainter({
    required this.pouches,
    required this.coins,
    required this.origin,
    required this.intensity,
    required this.t,
  });

  /// 기본 폭(dp). intensity 1.0 기준.
  static const double _baseWidth = DancheongBurstLayout.baseWidth;

  /// 터지기 직전의 응축 크기 — 작게 시작해야 확 벌어지는 맛이 산다.
  static const double _startScale = 0.28;

  @override
  void paint(Canvas canvas, Size size) {
    final heightOverWidth = math
        .max(pouches.height / pouches.width, coins.height / coins.width)
        .toDouble();
    final placement = DancheongBurstLayout.fit(
      viewport: size,
      preferredOrigin: origin,
      intensity: intensity,
      heightOverWidth: heightOverWidth,
    );
    final shots = <_Shot>[
      // 복주머니가 먼저 — 크고 무거운 게 앞장서야 타격이 선다.
      _Shot(image: pouches, delay: 0.0, reach: 1.06, spin: -0.06),
      // 엽전이 70ms 뒤 더 멀리 — "파" 다음의 "박".
      _Shot(image: coins, delay: 0.09, reach: 1.26, spin: 0.07),
    ];

    for (final shot in shots) {
      final lt = ((t - shot.delay) / (1.0 - shot.delay)).clamp(0.0, 1.0);
      if (lt <= 0) {
        continue;
      }

      // 초반 폭발 후 급감속 — 타격감의 핵심.
      final eased = Curves.easeOutExpo.transform(lt);
      final scale = _startScale + (shot.reach - _startScale) * eased;

      // 뒤쪽 42%에서 페이드.
      final fade = lt < 0.42 ? 1.0 : (1 - (lt - 0.42) / 0.58);
      if (fade <= 0) {
        continue;
      }

      final img = shot.image;
      final w = _baseWidth * placement.intensity * scale;
      final h = w * (img.height / img.width);
      if (w <= 0 || h <= 0) {
        continue;
      }

      // 살짝 떠오르며 퍼진다 — 바닥에 눌린 느낌을 없앤다.
      final lift = -w * 0.05 * eased;

      canvas.save();
      canvas.translate(placement.origin.dx, placement.origin.dy + lift);
      canvas.rotate(shot.spin * eased);
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        Paint()
          ..filterQuality = FilterQuality.medium
          ..color = Colors.white.withValues(alpha: fade.clamp(0.0, 1.0)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SheetBurstPainter old) => old.t != t;
}
