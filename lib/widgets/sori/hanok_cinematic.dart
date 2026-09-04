import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/hanok_stage.dart';
import '../../services/storage_service.dart';
import 'tokens.dart';

/// Phase 3 (stately-rising-jongga) — 한옥 단계 전환 시네마틱.
///
/// **언제 트리거**: 새 단계 (`current`) 가 직전 본 단계 (`previous`) 보다
/// 진행되어 있고, 사용자가 아직 안 본 경우. 결과 화면 자동 트리거 +
/// 홈 진입 시 자동 트리거.
///
/// **연출** (Plan §5.3):
///   1. 까치가 왼쪽에서 날아옴 (1초, 가로 sweep)
///   2. cross-fade overlay (0.5초) — 새 단계 PNG 등장
///   3. 까치가 추가된 부분에 앉음 (1초)
///   4. 토스트 메시지 ("기둥이 세워졌어요!" 등)
///   5. 자동 dismiss → `markHanokStageSeen` 호출
///
/// **Reduce-motion 대응**: `MediaQuery.disableAnimations` 시 그냥 토스트만.
class HanokCinematic extends StatefulWidget {
  /// 신규 도달 단계.
  final HanokStage current;

  /// 자동 dismiss 후 호출 — 부모가 overlay 를 닫게 한다.
  final VoidCallback onDone;

  /// 자동 dismiss 까지 시간 (기본 3.5초).
  final Duration totalDuration;

  const HanokCinematic({
    super.key,
    required this.current,
    required this.onDone,
    this.totalDuration = const Duration(milliseconds: 3500),
  });

  /// 헬퍼: 본 적 없는 stage 면 markSeen + true 반환.
  /// 시네마틱 호출 전 게이트로 사용.
  static Future<bool> shouldShow(HanokStage stage) async {
    return !Storage.hasSeenHanokStage(stage.toJsonValue());
  }

  /// 호환 헬퍼 — 시네마틱 표시 후 호출.
  static Future<void> markSeen(HanokStage stage) async {
    await Storage.markHanokStageSeen(stage.toJsonValue());
  }

  @override
  State<HanokCinematic> createState() => _HanokCinematicState();
}

class _HanokCinematicState extends State<HanokCinematic>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _magpieX;
  late final Animation<double> _fade;
  late final Animation<double> _toastY;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.totalDuration);
    // 까치: 좌측 -10% → 우측 50% 위치 (1.0s 첫 phase)
    _magpieX = Tween<double>(begin: -0.1, end: 0.55).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );
    // 배경 fade: 0.3 ~ 0.6 phase
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.3, 0.6, curve: Curves.easeInOut),
    );
    // 토스트 슬라이드 인: 0.6 ~ 0.9 phase
    _toastY = Tween<double>(begin: 60, end: 0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.6, 0.85, curve: Curves.easeOutBack),
      ),
    );

    _ctrl.forward();
    _ctrl.addStatusListener((status) async {
      if (status == AnimationStatus.completed && mounted) {
        await HanokCinematic.markSeen(widget.current);
        widget.onDone();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      // 모션 끄기 — 토스트만, 즉시 dismiss 트리거.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await HanokCinematic.markSeen(widget.current);
        if (mounted) widget.onDone();
      });
      // ⚠️ Align/SafeArea/Padding 래퍼는 필수다. 이 위젯은 홈에서
      // `Positioned.fill` 로 마운트돼 **꽉 찬 tight 제약**을 받는데,
      // `_ToastBanner` 의 `Container(constraints: maxWidth 320)` 은
      // ConstrainedBox → `enforce(incoming)` 라 tight 제약에 눌려 320 상한이
      // 무시된다. 그대로 두면 알파 0.96 크림 패널이 홈 **전체를 덮는다**
      // (애니메이션 끄기 사용자만 겪던 버그, 2026-08-06). 아래 래퍼는
      // 애니메이션 경로(같은 build 하단)와 동일한 구성이다.
      return Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 48),
            child: _ToastBanner(stage: widget.current),
          ),
        ),
      );
    }

    final t = AppL10n.of(context);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // ── 1. Full-screen scrim (점점 어두워졌다 다시 밝아짐) ──
            IgnorePointer(
              child: Container(
                color: Colors.black.withValues(alpha: _fade.value * 0.42),
              ),
            ),

            // ── 2. 까치 가로 sweep ──
            Align(
              alignment: Alignment(
                _magpieX.value * 2 - 1, // [-1..1] from [-0.1..0.55]
                -0.4,
              ),
              child: const _Magpie(size: 56),
            ),

            // ── 3. 토스트 (밑에서 슬라이드 인) ──
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: Transform.translate(
                    offset: Offset(0, _toastY.value),
                    child: Opacity(
                      opacity: (1 - _toastY.value / 60).clamp(0.0, 1.0),
                      child: _ToastBanner(
                        stage: widget.current,
                        intro: t.hanokCinematicIntro,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Magpie extends StatelessWidget {
  final double size;
  const _Magpie({required this.size});

  @override
  Widget build(BuildContext context) {
    // 실제 까치 이미지 없으면 emoji 대체 — Phase 2 stamp 처럼 자기완결.
    // 까치 PNG 가 들어오면 Image.asset 으로 교체 가능.
    return Image.asset(
      'assets/illustrations/mascot/magpie_wingup.png',
      width: size,
      height: size,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/illustrations/mascot/magpie_perched.png',
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Colors.black87,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('🐦', style: TextStyle(fontSize: 28)),
          ),
        ),
      ),
    );
  }
}

class _ToastBanner extends StatelessWidget {
  final HanokStage stage;
  final String? intro;
  const _ToastBanner({required this.stage, this.intro});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final label = _stageLabel(t, stage);
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: s.bg.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(SoriRadius.lg),
          border: Border.all(
            color: SoriColors.primary.withValues(alpha: 0.4),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (intro != null)
              Text(
                intro!,
                textAlign: TextAlign.center,
                style: SoriTextTheme.of(context).caption,
              ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: SoriColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _stageLabel(AppL10n t, HanokStage st) => switch (st) {
    HanokStage.empty => t.hanokStageEmpty,
    HanokStage.foundation => t.hanokStageFoundation,
    HanokStage.pillars => t.hanokStagePillars,
    HanokStage.beams => t.hanokStageBeams,
    HanokStage.thatchRoof => t.hanokStageThatch,
    HanokStage.tileRoofPartial => t.hanokStageTilePartial,
    HanokStage.tileRoofComplete => t.hanokStageTileComplete,
    HanokStage.dancheong => t.hanokStageDancheong,
    HanokStage.gate => t.hanokStageGate,
    HanokStage.windows => t.hanokStageWindows,
    HanokStage.sideBuilding => t.hanokStageSideBuilding,
    HanokStage.jongga => t.hanokStageJongga,
  };
}
