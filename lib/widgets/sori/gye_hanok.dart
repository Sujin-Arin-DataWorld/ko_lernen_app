import 'package:flutter/material.dart';

import '../../models/gye_dedication.dart';
import '../../models/gye.dart';
import '../../models/gye_lantern_progress.dart';
import '../../models/hanok_stage.dart';
import 'gye_dedication_layer.dart';
import 'hanok_header.dart';
import 'madang_background.dart';
import 'tiger_video.dart' show TigerStageVideo;
import 'tokens.dart';

/// 계가 아직 없을 때 보여 주는 공동마당 완성 예시.
///
/// 진행도용 [GyeHanok] 레이어 8장을 한꺼번에 켜면 서로 다른 원근과 축척이
/// 완성 종가 배경 위에 겹쳐져 건물이 뭉쳐 보인다. 빈 화면은 진행도 시뮬레이션이
/// 아니라 영감용 한 장면이므로, 동일한 Faceted Minhwa 세계관의 단일 16:9
/// courtyard 프레임을 쓴다. 실제 가입한 계의 주간/누적 진행 표현과는 분리한다.
class GyeShowcaseArtwork extends StatelessWidget {
  static const String asset =
      'assets/illustrations/gye/gye_showcase_courtyard.webp';
  static const String videoAsset =
      'assets/video/gye/gye_shared_hanok_build.mp4';

  const GyeShowcaseArtwork({super.key});

  @override
  Widget build(BuildContext context) {
    final poster = Image.asset(
      key: const ValueKey('gye-showcase-artwork'),
      asset,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      gaplessPlayback: true,
      excludeFromSemantics: true,
      errorBuilder: (_, __, ___) => const MadangBackground(
        stage: HanokStage.jongga,
        child: SizedBox.expand(),
      ),
    );
    if (!TigerStageVideo.videoReady || SoriMotion.reduceMotion(context)) {
      return poster;
    }
    return SoriPosterLoop(
      key: const ValueKey('gye-showcase-build-video'),
      videoAsset: videoAsset,
      poster: poster,
      fit: BoxFit.cover,
      loop: false,
    );
  }
}

/// 계 공동 한옥 — 종갓집 배경 위에 계 추가 요소(gye_* 8장)를 합성. plan §7.5.
///
/// **물성화(Step C)**: "내 학습이 우리 한옥을 올린다".
/// - 완성된 요소(누적 달성 주간목표) = 실체(1.0, 영구).
/// - **다음 요소 = 이번 주 진행률만큼 실체화**(`weeklyGoalProgress`) + 은은한 호흡
///   ("여기를 함께 짓는 중"). 팩을 깰수록 다음 건물이 ghost→실체로 차오른다.
/// - 그 뒤 요소 = ghost(0.22)로 "앞으로 지어갈 모습" 미리보기.
///
/// 좌표는 시안값 — 실기기 육안 튜닝 필요(Jin).
class GyeHanok extends StatefulWidget {
  final GyeMeta meta;
  final Iterable<GyeDedication> dedications;

  /// The "building" element's gentle breathing pulse (§W-G2 item 3). Default
  /// `true` keeps the full-scale detail scene (`gye_screen.dart`) as it was.
  /// List-card previews (`gye_tab_screen.dart`'s `_GyeCard`) pass `false` —
  /// one `AnimationController` per visible card, repeating forever, is a
  /// real battery/frame cost once a member has several courtyards, and it
  /// was also the direct cause of a `pumpAndSettle()` timeout in
  /// `gye_tab_landing_test.dart`'s populated-list test. Treated identically
  /// to reduce-motion internally — both stop the controller and hold it at
  /// its resting value.
  final bool animate;

  const GyeHanok({
    super.key,
    required this.meta,
    this.dedications = const <GyeDedication>[],
    this.animate = true,
  });

  // (slug, leftFrac, bottomFrac, widthFrac) — 리스트 순서 = 뒤→앞 z순 + 잠금 해제 순.
  // PIL 합성 프리뷰(393×280)로 보정한 시안값. 실기기에서 미세 조정 가능.
  static const List<({String slug, double left, double bottom, double width})>
  _elements = [
    // 뒤(건물)
    (slug: 'gye_gate_grand', left: 0.31, bottom: 0.00, width: 0.46),
    (slug: 'gye_haenglangchae', left: 0.00, bottom: 0.16, width: 0.40),
    (slug: 'gye_byeoldang', left: 0.64, bottom: 0.18, width: 0.34),
    (slug: 'gye_jeongja', left: 0.72, bottom: 0.46, width: 0.26),
    // 앞(조경)
    (slug: 'gye_garden', left: 0.00, bottom: 0.00, width: 0.33),
    (slug: 'gye_jangmyeongdeung_pair', left: 0.30, bottom: 0.05, width: 0.15),
    (slug: 'gye_pond_large', left: 0.28, bottom: 0.01, width: 0.40),
    (slug: 'gye_bridge', left: 0.40, bottom: 0.085, width: 0.20),
  ];

  /// [_elements]의 길이 — [GyeLanternProgress.fromMeta]의 `elementCount`
  /// 인자와 항상 같은 값이어야 한다(§W-G G2). 계 목록 카드의 진행 링이
  /// 이 씬과 같은 임계값으로 채워지려면 두 호출부가 같은 요소 수를 써야
  /// 하므로, 사설 상수를 복제하는 대신 여기서 공개한다.
  static int get elementCount => _elements.length;

  @override
  State<GyeHanok> createState() => _GyeHanokState();
}

class _GyeHanokState extends State<GyeHanok>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  void _syncPulse() {
    final shouldAnimate = widget.animate && !SoriMotion.reduceMotion(context);
    if (shouldAnimate) {
      if (!_pulse.isAnimating) {
        _pulse.repeat(reverse: true);
      }
      return;
    }
    _pulse.stop();
    _pulse.value = 0;
  }

  @override
  void didUpdateWidget(covariant GyeHanok oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) {
      _syncPulse();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  GyeLanternProgress get _progress => GyeLanternProgress.fromMeta(
    widget.meta,
    elementCount: GyeHanok.elementCount,
  );

  /// 요소 기본 실체화 — 완성(1.0) / 다음=기존 주간 목표 비율 / 그 뒤=ghost.
  double _baseOpacity(int i, GyeLanternProgress progress) {
    if (i < progress.permanentElementCount) {
      return 1.0;
    }
    if (i == progress.permanentElementCount && progress.hasWeeklyGoal) {
      return (0.22 + 0.78 * progress.weeklyFraction).clamp(0.22, 1.0);
    }
    return 0.22;
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    // `!widget.animate` is treated exactly like reduce-motion — a static
    // scene either way (§W-G2 item 3).
    final reduce = SoriMotion.reduceMotion(context) || !widget.animate;
    return MadangBackground(
      stage: HanokStage.jongga,
      child: LayoutBuilder(
        builder: (ctx, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;
          Widget content() => Stack(
            children: [
              for (var i = 0; i < GyeHanok._elements.length; i++)
                _element(i, progress, w, h, reduce),
              GyeDedicationLayer(dedications: widget.dedications),
            ],
          );
          if (reduce) {
            return content();
          }
          return AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) => content(),
          );
        },
      ),
    );
  }

  Widget _element(
    int i,
    GyeLanternProgress progress,
    double w,
    double h,
    bool reduce,
  ) {
    final base = _baseOpacity(i, progress);
    // "짓는 중" = 다음 요소(미완성). 진행률과 무관하게 은은히 호흡해 살아있게.
    final building = i == progress.permanentElementCount && base < 1.0;
    // The gold treatment acknowledges the present illustration state only.
    final complete =
        i == progress.permanentElementCount &&
        base >= 1.0 &&
        progress.hasWeeklyGoal;
    final p = reduce ? 0.0 : _pulse.value;
    final opacity = building ? (base + p * 0.14).clamp(0.0, 1.0) : base;

    Widget child = Image.asset(
      'assets/illustrations/gye/${GyeHanok._elements[i].slug}.png',
      width: w * GyeHanok._elements[i].width,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
    if (complete) {
      child = ColorFiltered(
        colorFilter: ColorFilter.mode(
          SoriColors.gold.withValues(alpha: p * 0.4),
          BlendMode.srcATop,
        ),
        child: child,
      );
    }

    return Positioned(
      left: w * GyeHanok._elements[i].left,
      bottom: h * GyeHanok._elements[i].bottom,
      width: w * GyeHanok._elements[i].width,
      child: IgnorePointer(
        child: Opacity(opacity: opacity, child: child),
      ),
    );
  }
}
