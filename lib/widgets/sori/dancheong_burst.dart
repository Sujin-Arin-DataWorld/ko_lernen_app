import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'celebration.dart';
import 'hanok_tokens.dart';
import 'tokens.dart';

/// **DancheongBurst** — 복주머니·엽전 스프라이트가 터져 나가는 정답 축하 연출.
///
/// [SoriCelebration]의 Overlay 구조를 따르되 절차적 도형 대신 실제 PNG를 뿌린다.
/// 복주머니는 오방색 4종(적·청·황·흑), 엽전 1종. 각자 회전하며 방사형으로
/// 솟았다가 중력으로 떨어진다. 반짝임은 에셋에 넣지 않고 절차적으로 그린다.
///
/// ```dart
/// DancheongBurst.fire(context, origin: mascotCenter);
/// ```
///
/// 스프라이트가 아직 로드되지 않았거나 PNG가 없으면 기존
/// [SoriCelebration.burst]로 자동 폴백한다 — 에셋 없이도 정상 동작.
/// `MediaQuery.disableAnimations`가 켜져 있으면 no-op.
class DancheongBurst {
  DancheongBurst._();

  static const _pouchAssets = <String>[
    'assets/illustrations/burst/burst_pouch_jeok.png',
    'assets/illustrations/burst/burst_pouch_cheong.png',
    'assets/illustrations/burst/burst_pouch_hwang.png',
    'assets/illustrations/burst/burst_pouch_heuk.png',
  ];
  static const _coinAsset = 'assets/illustrations/burst/burst_coin.png';

  static List<ui.Image>? _pouches;
  static ui.Image? _coin;
  static bool _loading = false;
  static bool _failed = false;

  /// 스프라이트가 준비됐는지. 테스트/폴백 분기용.
  static bool get ready => _pouches != null && _coin != null;

  /// 스프라이트를 미리 디코딩해 첫 정답에서 폴백이 뜨는 걸 막는다.
  /// 실패해도 조용히 넘어간다 (폴백 경로가 받아준다).
  static Future<void> preload() async {
    if (ready || _loading || _failed) return;
    _loading = true;
    try {
      final pouches = await Future.wait(_pouchAssets.map(_decode));
      final coin = await _decode(_coinAsset);
      _pouches = pouches;
      _coin = coin;
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

  /// 일회성 버스트를 [Overlay]에 띄운다. 900ms 후 스스로 사라진다.
  ///
  /// [intensity]는 입자 수 배율 (0.5 = 절반, 1.0 = 기본).
  static void fire(
    BuildContext context, {
    required Offset origin,
    double intensity = 1.0,
  }) {
    if (SoriMotion.reduceMotion(context)) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final pouches = _pouches;
    final coin = _coin;
    if (pouches == null || coin == null) {
      // 스프라이트 미준비 → 절차적 버스트로 폴백 + 다음을 위해 로드 시작.
      unawaited(preload());
      SoriCelebration.burst(context, origin: origin, particles: 22);
      return;
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _BurstLayer(
        origin: origin,
        pouches: pouches,
        coin: coin,
        intensity: intensity,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

// ─────────────────────────────────────────────────────────────────────────

class _BurstLayer extends StatefulWidget {
  final Offset origin;
  final List<ui.Image> pouches;
  final ui.Image coin;
  final double intensity;
  final VoidCallback onDone;

  const _BurstLayer({
    required this.origin,
    required this.pouches,
    required this.coin,
    required this.intensity,
    required this.onDone,
  });

  @override
  State<_BurstLayer> createState() => _BurstLayerState();
}

class _BurstLayerState extends State<_BurstLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Sprite> _sprites;
  late final List<_Sparkle> _sparkles;

  /// 반짝임 색 — 오방색 (백은 한지 배경 위에서 안 보여 제외).
  static const _sparklePalette = <Color>[
    HanokColors.jeok,
    HanokColors.cheong,
    HanokColors.hwang,
    SoriColors.gold,
  ];

  @override
  void initState() {
    super.initState();
    // 트리거마다 재생성 — 매번 다른 모양으로 터진다.
    final rnd = math.Random();
    final pouchCount = (7 * widget.intensity).round().clamp(2, 14);
    final coinCount = (9 * widget.intensity).round().clamp(2, 18);
    final sparkleCount = (14 * widget.intensity).round().clamp(4, 28);

    _sprites = [
      for (var i = 0; i < pouchCount; i++)
        _Sprite(
          image: widget.pouches[rnd.nextInt(widget.pouches.length)],
          angle: _launchAngle(rnd),
          speed: 130 + rnd.nextDouble() * 190,
          size: 26 + rnd.nextDouble() * 14,
          spin: (rnd.nextDouble() - 0.5) * 7,
          delay: rnd.nextDouble() * 0.10,
        ),
      for (var i = 0; i < coinCount; i++)
        _Sprite(
          image: widget.coin,
          angle: _launchAngle(rnd),
          speed: 170 + rnd.nextDouble() * 240,
          size: 15 + rnd.nextDouble() * 9,
          spin: (rnd.nextDouble() - 0.5) * 11,
          delay: rnd.nextDouble() * 0.12,
        ),
    ];

    _sparkles = [
      for (var i = 0; i < sparkleCount; i++)
        _Sparkle(
          angle: rnd.nextDouble() * math.pi * 2,
          speed: 230 + rnd.nextDouble() * 260,
          size: 2.5 + rnd.nextDouble() * 3.5,
          color: _sparklePalette[rnd.nextInt(_sparklePalette.length)],
          delay: rnd.nextDouble() * 0.08,
        ),
    ];

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDone();
      });
    _ctrl.forward();
  }

  /// 위쪽 반구 위주 (−170°~−10°) — 솟았다 떨어지는 궤적을 만든다.
  static double _launchAngle(math.Random rnd) =>
      -math.pi + rnd.nextDouble() * math.pi * 0.92 + 0.08;

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
              painter: _BurstPainter(
                sprites: _sprites,
                sparkles: _sparkles,
                origin: widget.origin,
                t: _ctrl.value,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Sprite {
  final ui.Image image;
  final double angle; // 발사 방향 (rad)
  final double speed; // 초기 속도
  final double size; // 목표 폭 (px)
  final double spin; // 회전 속도 (rad)
  final double delay; // 0~0.12 — 약간 어긋나게 터짐

  const _Sprite({
    required this.image,
    required this.angle,
    required this.speed,
    required this.size,
    required this.spin,
    required this.delay,
  });
}

class _Sparkle {
  final double angle;
  final double speed;
  final double size;
  final Color color;
  final double delay;

  const _Sparkle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
    required this.delay,
  });
}

class _BurstPainter extends CustomPainter {
  final List<_Sprite> sprites;
  final List<_Sparkle> sparkles;
  final Offset origin;
  final double t; // 0..1

  _BurstPainter({
    required this.sprites,
    required this.sparkles,
    required this.origin,
    required this.t,
  });

  /// `celebration.dart`와 동일 상수 — 두 연출의 낙하감을 맞춘다.
  static const double _gravity = 720;

  /// 초반 폭발 후 급감속. 타격감의 핵심.
  static double _reach(double lt) => Curves.easeOutExpo.transform(lt);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in sparkles) {
      final lt = ((t - s.delay) / (1.0 - s.delay)).clamp(0.0, 1.0);
      if (lt <= 0) {
        continue;
      }
      final reach = _reach(lt);
      final pos = origin +
          Offset(
            math.cos(s.angle) * s.speed * reach,
            math.sin(s.angle) * s.speed * reach + _gravity * lt * lt * 0.35,
          );
      // 반짝임은 더 빨리 사라진다 (t=0.45부터).
      final fade = lt < 0.45 ? 1.0 : (1 - (lt - 0.45) / 0.55);
      if (fade <= 0) {
        continue;
      }
      canvas.drawCircle(
        pos,
        s.size * (1 - lt * 0.4),
        Paint()..color = s.color.withValues(alpha: fade.clamp(0.0, 1.0)),
      );
    }

    for (final s in sprites) {
      final lt = ((t - s.delay) / (1.0 - s.delay)).clamp(0.0, 1.0);
      if (lt <= 0) {
        continue;
      }

      final reach = _reach(lt);
      final pos = origin +
          Offset(
            math.cos(s.angle) * s.speed * reach,
            math.sin(s.angle) * s.speed * reach + _gravity * lt * lt * 0.5,
          );

      // 끝 35%에서 페이드 + 축소 (1.0 → 0.7).
      final fade = lt < 0.65 ? 1.0 : (1 - (lt - 0.65) / 0.35);
      if (fade <= 0) {
        continue;
      }
      final scale = 1.0 - lt * 0.3;

      final img = s.image;
      final w = s.size * scale;
      final h = w * (img.height / img.width);
      if (w <= 0 || h <= 0) {
        continue;
      }

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(s.spin * lt);
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
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}
