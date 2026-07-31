import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/pack_progress.dart';
import 'pressable.dart';
import 'tokens.dart';

/// 경로 위의 정거장 하나 — 단어팩 노드.
@immutable
class SoriPathStop {
  /// 팩 id (디버그·테스트 식별용).
  final String id;
  final String label;
  final PackStatus status;

  /// 0.0 – 1.0. `isNow` 노드에서 링 게이지로 그려진다.
  final double fraction;

  /// "지금 할 것" — 레벨 통틀어 하나만 true여야 한다.
  final bool isNow;

  /// 잠금 노드도 반드시 콜백을 받는다 — 잠금 힌트를 띄워야 하므로
  /// "탭이 되는 것"과 "팩이 열리는 것"은 별개다.
  final VoidCallback onTap;

  /// 코치마크 타겟 등 외부에서 노드를 잡아야 할 때.
  final Key? nodeKey;

  const SoriPathStop({
    required this.id,
    required this.label,
    required this.status,
    required this.fraction,
    required this.isNow,
    required this.onTap,
    this.nodeKey,
  });
}

/// **SoriPathTrail** — 지그재그(serpentine) 학습 경로.
///
/// 세로로 똑같이 나열된 [PathNode] 리스트를 대체한다. 같은 데이터·같은
/// 콜백을 쓰되 노드를 좌우로 흔들어 배치해 눈이 "목록"이 아니라 "길"로
/// 읽게 만든다.
///
/// ## 100% 탭 보장 설계
///
/// 절대 좌표 Stack에 노드를 흩뿌리는 흔한 구현은 두 지점에서 탭을 잃는다:
/// Stack 밖으로 나간 자식은 clip되어 히트테스트에서 제외되고, 겹친 노드는
/// 위 노드가 아래 노드의 탭을 가로챈다. 그래서 이 위젯은:
///
/// 1. **노드마다 전용 슬롯(행)** — 슬롯은 `트랙 폭 x 슬롯 높이`의 SizedBox이고
///    노드는 그 안에서 [Align]으로만 좌우 이동한다. Align은 자식을 부모 경계
///    안에 가두므로 가로 오버플로가 원천적으로 없고, 슬롯이 세로로 겹치지
///    않으므로 노드끼리 탭을 뺏지 않는다.
/// 2. **연결선은 [IgnorePointer] + [CustomPaint]** — 선이 탭을 먹지 않는다.
/// 3. **탭 타깃 = 슬롯 전체** ([nodeWidth] x 슬롯 높이, 최소 132x136dp).
///    Material 최소 타깃 48dp의 2배 이상이며, 원 안쪽뿐 아니라 라벨과 그
///    주변 여백까지 모두 반응한다.
/// 4. **[HitTestBehavior.opaque]** — 원과 라벨 사이 빈 공간에서도 탭이 잡힌다.
/// 5. **잠금 노드도 동일한 타깃** — 흐리게 보이지만 탭은 100% 잡히고
///    잠금 힌트가 뜬다.
///
/// [swayAt]과 [centerXFor]는 노드 배치와 연결선 painter가 **같은 식**을
/// 쓰도록 하는 단일 진실 공급원이다. 둘이 어긋나면 선이 원을 빗나간다.
class SoriPathTrail extends StatelessWidget {
  const SoriPathTrail({super.key, required this.stops});

  final List<SoriPathStop> stops;

  /// 노드 열 폭 = 탭 타깃 가로 크기이자 지그재그 진폭의 기준.
  static const double nodeWidth = 132;

  /// 원이 사는 상자 높이. 가장 큰 원(76) + 펄스 후광(±10) 여유.
  static const double discBox = 100;

  /// 원 지름 — 전부 Material 최소 타깃 48dp 이상.
  static const double discNow = 76;
  static const double discNormal = 62;
  static const double discLocked = 58;

  /// 지그재그 가로 위치 (-1 = 왼쪽 끝, +1 = 오른쪽 끝).
  ///
  /// 주기 6의 사인파 — 0, +.87, +.87, 0, -.87, -.87, 0 … 좌우로 감기는
  /// 뱀 모양이 되어 눈이 길을 따라 내려간다. 톱니(-1,+1 반복)보다 부드럽고
  /// 같은 폭 안에서 노드 간 거리가 균일하다.
  static double swayAt(int i) => math.sin(i * math.pi / 3);

  /// [Align]이 자식을 놓는 위치와 **정확히 같은** 중심 x.
  ///
  /// `Align(Alignment(fx, _))`는 자식 왼쪽을 `(W - w) * (fx + 1) / 2`에 두므로
  /// 중심은 `W/2 + fx * (W - w)/2`. 연결선이 원 중심을 정확히 통과하려면
  /// painter도 반드시 이 식을 써야 한다.
  static double centerXFor(double trackWidth, double nodeW, int i) =>
      trackWidth / 2 + swayAt(i) * (trackWidth - nodeW) / 2;

  /// 라벨 블록 높이 — 시스템 글자 크기 설정을 존중한다.
  /// (고정값이면 큰 글자 설정에서 라벨이 잘리거나 오버플로가 난다.)
  static double labelBlockHeight(BuildContext context) {
    final scaled = MediaQuery.textScalerOf(context).scale(12);
    return scaled * 1.3 + 10;
  }

  static double slotHeightFor(BuildContext context) =>
      discBox + labelBlockHeight(context) + 12;

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) return const SizedBox.shrink();

    final slotH = slotHeightFor(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackW = constraints.maxWidth;
        // 좁은 화면에서 노드가 트랙보다 넓어지면 centerXFor 식이 뒤집힌다.
        final nodeW = math.min(nodeWidth, trackW);

        // 원 중심 y — 슬롯 높이가 균일하므로 i번째는 항상 같은 오프셋.
        final centersY = <double>[
          for (var i = 0; i < stops.length; i++) i * slotH + discBox / 2,
        ];

        return SizedBox(
          width: trackW,
          height: slotH * stops.length,
          child: Stack(
            children: [
              // 연결선 — 항상 노드 뒤, 탭은 절대 가로채지 않는다.
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _TrailPainter(
                        stops: stops,
                        centersY: centersY,
                        nodeWidth: nodeW,
                        travelled: SoriColors.primary,
                        upcoming: SoriColors.gold,
                        ahead: SoriColors.lightBorderStrong,
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < stops.length; i++)
                    SizedBox(
                      width: trackW,
                      height: slotH,
                      child: Align(
                        alignment: Alignment(swayAt(i), 0),
                        child: _TrailNode(
                          stop: stops[i],
                          width: nodeW,
                          height: slotH,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 노드
// ─────────────────────────────────────────────────────────────────────────

class _TrailNode extends StatelessWidget {
  const _TrailNode({
    required this.stop,
    required this.width,
    required this.height,
  });

  final SoriPathStop stop;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final cleared = stop.status == PackStatus.cleared;
    final locked = stop.status == PackStatus.locked;

    return Semantics(
      button: true,
      enabled: !locked,
      label: stop.label,
      child: SoriPressable(
        key: stop.nodeKey,
        onTap: stop.onTap,
        haptic: locked ? SoriHaptic.light : SoriHaptic.selection,
        // 원·라벨 사이 여백에서도 탭이 잡히도록 슬롯 전체를 불투명 타깃으로.
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: width,
          height: height,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(
                height: SoriPathTrail.discBox,
                child: Center(
                  child: _Disc(stop: stop, cleared: cleared, locked: locked),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    // 배경색 칩 — 연결선이 라벨 글자를 가로지르지 않게 가린다.
                    decoration: BoxDecoration(
                      color: s.bg,
                      borderRadius: SoriRadius.brSm,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    child: Text(
                      stop.label,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        fontWeight: locked ? FontWeight.w600 : FontWeight.w700,
                        // 잠금도 본문 대비를 유지 — opacity로 뭉개지 않는다.
                        color: locked ? s.textMuted : s.text,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 원 — 상태가 색이 아니라 **형태**로 읽히도록 넷 다 실루엣이 다르다.
class _Disc extends StatelessWidget {
  const _Disc({
    required this.stop,
    required this.cleared,
    required this.locked,
  });

  final SoriPathStop stop;
  final bool cleared;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);

    if (stop.isNow) {
      return _NowDisc(fraction: stop.fraction, badge: t.pathNodeNow);
    }

    if (cleared) {
      return SizedBox.square(
        dimension: SoriPathTrail.discNormal + 16,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 지나온 자리를 표시하는 바깥 점선 링 — 도장 자국 느낌.
            CustomPaint(
              size: const Size.square(SoriPathTrail.discNormal + 16),
              painter: _DashedRingPainter(
                color: SoriColors.primary.withValues(alpha: 0.45),
              ),
            ),
            Container(
              width: SoriPathTrail.discNormal,
              height: SoriPathTrail.discNormal,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SoriColors.primary,
                border: Border.all(color: SoriColors.primaryDark, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: SoriColors.primaryDark.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              // 흰 체크 on 녹청 = 5.2:1.
              child: const Icon(Icons.check_rounded,
                  size: 30, color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (locked) {
      return SizedBox.square(
        dimension: SoriPathTrail.discLocked,
        child: CustomPaint(
          painter: _DashedRingPainter(
            color: SoriColors.lightBorderStrong,
            strokeWidth: 2.5,
            fill: s.surface,
          ),
          child: Center(
            child: Icon(Icons.lock_outline_rounded,
                size: 22, color: SoriColors.lightBorderStrong),
          ),
        ),
      );
    }

    // available / inProgress — 열려 있지만 아직 "지금"은 아닌 팩.
    return Container(
      width: SoriPathTrail.discNormal,
      height: SoriPathTrail.discNormal,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: SoriColors.gold, width: 3),
        boxShadow: [
          BoxShadow(
            color: SoriColors.lightText.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(Icons.play_arrow_rounded,
          size: 28, color: SoriColors.goldOnLight),
    );
  }
}

/// "지금 여기" 노드 — 진행 링 + 숨쉬는 후광 + Jetzt 배지.
class _NowDisc extends StatefulWidget {
  const _NowDisc({required this.fraction, required this.badge});

  final double fraction;
  final String badge;

  @override
  State<_NowDisc> createState() => _NowDiscState();
}

class _NowDiscState extends State<_NowDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // WCAG 2.3.3 — "동작 줄이기"면 후광은 정지.
    if (SoriMotion.reduceMotion(context)) {
      _pulse.stop();
      _pulse.value = 0;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const box = SoriPathTrail.discBox;
    const d = SoriPathTrail.discNow;

    return RepaintBoundary(
      child: SizedBox.square(
        dimension: box,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                final v = _pulse.value;
                if (v == 0) return const SizedBox.shrink();
                return Container(
                  width: d + 20 * v,
                  height: d + 20 * v,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: SoriColors.tiger
                          .withValues(alpha: 0.38 * (1 - v)),
                      width: 2.5,
                    ),
                  ),
                );
              },
            ),
            Container(
              width: d,
              height: d,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: SoriColors.tiger, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: SoriColors.tiger.withValues(alpha: 0.38),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.play_arrow_rounded,
                  size: 34, color: SoriColors.tigerOnLight),
            ),
            // 진행 링 — 몇 % 남았는지 원 자체가 말해준다.
            if (widget.fraction > 0)
              CustomPaint(
                size: const Size.square(d + 16),
                painter: _ProgressRingPainter(widget.fraction),
              ),
            // Jetzt 배지 — 먹색 on 주황(7.2:1). 흰 글씨는 2.3:1로 AA 미달.
            Positioned(
              bottom: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                decoration: BoxDecoration(
                  color: SoriColors.tiger,
                  borderRadius: SoriRadius.brPill,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  widget.badge,
                  // w800/w900 은 typography_guard_test 의 래칫 상한에 걸린다
                  // (Pretendard 는 400~800만 번들 → w900 은 어차피 800으로 렌더).
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: SoriColors.lightText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Painters
// ─────────────────────────────────────────────────────────────────────────

/// 노드를 잇는 길. 지나온 구간은 실선 녹청, 앞으로 갈 구간은 점선.
class _TrailPainter extends CustomPainter {
  _TrailPainter({
    required this.stops,
    required this.centersY,
    required this.nodeWidth,
    required this.travelled,
    required this.upcoming,
    required this.ahead,
  });

  final List<SoriPathStop> stops;
  final List<double> centersY;
  final double nodeWidth;
  final Color travelled;
  final Color upcoming;
  final Color ahead;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < stops.length - 1; i++) {
      final from = Offset(
        SoriPathTrail.centerXFor(size.width, nodeWidth, i),
        centersY[i],
      );
      final to = Offset(
        SoriPathTrail.centerXFor(size.width, nodeWidth, i + 1),
        centersY[i + 1],
      );
      final dy = to.dy - from.dy;
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..cubicTo(
          from.dx, from.dy + dy * 0.45,
          to.dx, to.dy - dy * 0.45,
          to.dx, to.dy,
        );

      final done = stops[i].status == PackStatus.cleared;
      // 지금 노드에서 나가는 구간은 황금 — "다음 한 걸음"을 눈으로 잇는다.
      final next = stops[i].isNow;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = done ? 5 : 4
        ..color = done
            ? travelled.withValues(alpha: 0.55)
            : next
                ? upcoming
                : ahead.withValues(alpha: 0.75);

      canvas.drawPath(done ? path : _dashed(path), paint);
    }
  }

  /// 디딤돌 느낌의 점선. strokeCap.round + 짧은 dash = 동그란 점.
  Path _dashed(Path source, {double dash = 2, double gap = 13}) {
    final out = Path();
    for (final metric in source.computeMetrics()) {
      var pos = 0.0;
      while (pos < metric.length) {
        final end = math.min(pos + dash, metric.length);
        out.addPath(metric.extractPath(pos, end), Offset.zero);
        pos += dash + gap;
      }
    }
    return out;
  }

  @override
  bool shouldRepaint(covariant _TrailPainter old) =>
      old.centersY.length != centersY.length ||
      old.nodeWidth != nodeWidth ||
      !_sameStates(old.stops, stops);

  static bool _sameStates(List<SoriPathStop> a, List<SoriPathStop> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].status != b[i].status || a[i].isNow != b[i].isNow) return false;
    }
    return true;
  }
}

class _DashedRingPainter extends CustomPainter {
  _DashedRingPainter({
    required this.color,
    this.strokeWidth = 1.6,
    this.fill,
  });

  final Color color;
  final double strokeWidth;
  final Color? fill;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = (size.shortestSide - strokeWidth) / 2;
    if (fill != null) {
      canvas.drawCircle(center, r, Paint()..color = fill!);
    }
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;

    const seg = 14; // 점선 조각 수
    const sweep = math.pi * 2 / seg;
    final rect = Rect.fromCircle(center: center, radius: r);
    for (var i = 0; i < seg; i++) {
      canvas.drawArc(rect, i * sweep, sweep * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRingPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth || old.fill != fill;
}

class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter(this.fraction);

  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    final f = fraction.clamp(0.0, 1.0);
    if (f <= 0) return;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - 5) / 2,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * f,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = SoriColors.tiger,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) =>
      old.fraction != fraction;
}
