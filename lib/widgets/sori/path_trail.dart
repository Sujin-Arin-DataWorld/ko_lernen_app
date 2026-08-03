import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/pack_progress.dart';
import 'character_clip.dart';
import 'dancheong_stamp.dart';
import 'mascot.dart';
import 'mascot_preference.dart';
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
  const SoriPathTrail({
    super.key,
    required this.stops,
    this.liveNowNode = true,
  });

  final List<SoriPathStop> stops;

  /// "지금" 노드에 살아있는 캐릭터 클립을 쓸지. **홈 임베드는 false** —
  /// 홈 히어로(TigerStageVideo)와 단일 영상 lease 를 두고 경합하면
  /// SD678 계열에서 히어로가 reclaim 으로 꺼진다(ADR-001). false 면
  /// 정적 Mascot 으로 강등되어 디코더를 아예 요청하지 않는다.
  final bool liveNowNode;

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
                          liveNow: liveNowNode,
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
    required this.liveNow,
  });

  final bool liveNow;

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
                  child: _Disc(
                    stop: stop,
                    cleared: cleared,
                    locked: locked,
                    liveNow: liveNow,
                  ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 1,
                    ),
                    child: Text(
                      stop.label,
                      // §4.3: 경로 라벨 말줄임 1줄 금지 — 2줄 허용
                      // (라벨 영역 ≈36px: 12px×1.3 두 줄 수용, 1.3× 글씨는
                      // 실기기 확인 항목).
                      maxLines: 2,
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

/// 원 — 상태는 **에셋 자체**가 말한다. Material 아이콘·수동 원은 쓰지 않는다.
///
/// - 완료 : 팩 주제의 단청 도장 (`stamps/stamp_*.png`) 원본 컬러.
///          도장 PNG가 이미 원형 + 붉은 테두리라 별도 원/체크가 필요 없다.
/// - 열림 : 같은 도장 + 황금 링 (지금 들어갈 수 있다는 신호).
/// - 잠금 : 같은 도장을 회색조 45% — 자물쇠(벽)가 아니라 **받게 될 도장의
///          미리보기**. 경로 전체가 "찍힌 도장 / 찍을 도장"으로 읽힌다.
/// - 지금 : 마스코트 클립 (아래 [_NowDisc]).
///
/// 모티프는 기존 [motifForPackId] 매핑을 그대로 쓴다 — 인사=연꽃, 시간=국화,
/// 감정=매화, 학교·직장=대나무, 날씨=구름, 음식·쇼핑=팔각, 교통=산, 몸=만자.
class _Disc extends StatelessWidget {
  const _Disc({
    required this.stop,
    required this.cleared,
    required this.locked,
    required this.liveNow,
  });

  final SoriPathStop stop;
  final bool cleared;
  final bool locked;
  final bool liveNow;

  /// 휘도 기준 회색조 (Rec.709). 알파 행은 항등 — 투명도는 건드리지 않는다.
  static const List<double> _greyscale = <double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    if (stop.isNow) {
      return _NowDisc(
        fraction: stop.fraction,
        badge: t.pathNodeNow,
        live: liveNow,
      );
    }

    final motif = motifForPackId(stop.id);

    if (cleared) {
      return DancheongStamp(
        motif: motif,
        size: SoriPathTrail.discNormal,
        stamped: true,
      );
    }

    if (locked) {
      return Opacity(
        opacity: 0.45,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix(_greyscale),
          child: DancheongStamp(motif: motif, size: SoriPathTrail.discLocked),
        ),
      );
    }

    // available / inProgress — 열려 있지만 아직 "지금"은 아닌 팩.
    return SizedBox.square(
      dimension: SoriPathTrail.discNormal + 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: SoriColors.gold, width: 3),
            ),
            child: const SizedBox.expand(),
          ),
          DancheongStamp(motif: motif, size: SoriPathTrail.discNormal - 4),
        ],
      ),
    );
  }
}

/// "지금 여기" 노드 — 진행 링 + 숨쉬는 후광 + Jetzt 배지.
class _NowDisc extends StatefulWidget {
  const _NowDisc({
    required this.fraction,
    required this.badge,
    required this.live,
  });

  final double fraction;
  final String badge;
  final bool live;

  @override
  State<_NowDisc> createState() => _NowDiscState();
}

class _NowDiscState extends State<_NowDisc>
    with SingleTickerProviderStateMixin {
  /// 원판 색 = 클립 multiply blendColor. 둘이 다르면 원 안에 사각 이음매가 뜬다.
  static const Color _clipBlend = Colors.white;

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
    // 프로필과 같은 규칙 — 사용자가 고른 캐릭터를 경로에서도 유지한다.
    final isMagpie = MascotPreference.kind.value == MascotKind.magpie;

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
                      color: SoriColors.tiger.withValues(alpha: 0.38 * (1 - v)),
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
                // 흰 원판 — 클립이 흰 배경 mp4를 multiply로 녹이므로
                // blendColor와 반드시 같은 색이어야 이음매가 안 보인다.
                color: _clipBlend,
                border: Border.all(color: SoriColors.tiger, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: SoriColors.tiger.withValues(alpha: 0.38),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Center(
                  // live=false(홈 임베드): 디코더 lease 를 아예 요청하지 않는
                  // 정적 마스코트 — 홈 히어로 영상과의 경합 원천 차단.
                  child: widget.live
                      ? CharacterClipPlayer(
                          // 호랑이는 게임 대기 바운스, 까치는 앉아 대기 —
                          // 둘 다 "네 차례야" 를 몸짓으로 말하는 아이들 루프.
                          asset: isMagpie
                              ? CharacterClips.magpiePerched
                              : CharacterClips.tigerBob,
                          size: d - 14,
                          loop: true,
                          blendColor: _clipBlend,
                          fallbackKind: isMagpie
                              ? MascotKind.magpie
                              : MascotKind.tiger,
                          fallbackEmotion: MascotEmotion.smile,
                        )
                      : Mascot(
                          kind: isMagpie ? MascotKind.magpie : MascotKind.tiger,
                          emotion: MascotEmotion.smile,
                          size: d - 14,
                          animate: false,
                        ),
                ),
              ),
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
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
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
          from.dx,
          from.dy + dy * 0.45,
          to.dx,
          to.dy - dy * 0.45,
          to.dx,
          to.dy,
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

/// 홈 미리보기(`PathPreviewRow`)용 공개 노드 디스크 — 내부 [_Disc] 문법
/// (도장·황금 링·잠금 회색조 프리뷰)을 그대로 재사용한다 (§10.2).
/// [liveNow]=false면 "지금" 노드도 정적 — 홈 히어로 클립과의 동시 재생을
/// 막는 디코더 ≤1 계약.
class SoriPathNodeDisc extends StatelessWidget {
  final SoriPathStop stop;
  final bool liveNow;

  const SoriPathNodeDisc({super.key, required this.stop, this.liveNow = false});

  @override
  Widget build(BuildContext context) => _Disc(
    stop: stop,
    cleared: stop.status == PackStatus.cleared,
    locked: stop.status == PackStatus.locked,
    liveNow: liveNow,
  );
}
