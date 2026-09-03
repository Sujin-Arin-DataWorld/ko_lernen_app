import 'package:flutter/material.dart';

import '../../models/hanok_stage.dart';
import 'tokens.dart';

/// Phase 3 (stately-rising-jongga) — 단계별 한옥 마당 배경 위젯.
///
/// 1순위: `assets/illustrations/hanok_stages/stage_{slug}_{brightness}.png`
/// 2순위: `assets/illustrations/hanok/madang(light).png` (Phase 2 까지의 배경)
/// 3순위: Theme gradient (PNG 둘 다 실패)
///
/// **변경 없는 v4 home_screen 과의 호환**: `child` 슬롯에 home content 를
/// 그대로 stack 한다. errorBuilder 가 PNG 실패 시 단색 gradient 로 떨어져
/// "찢어진 한옥" 없이 항상 깨끗하게 보임.
class MadangBackground extends StatelessWidget {
  final HanokStage stage;

  /// 선택: child overlay (홈 content). null 이면 배경만 그림.
  final Widget? child;

  /// Stage 라벨 배지 표시 여부 (기본 false — 홈에서 작은 badge 로 표시할 때만 true).
  final bool showStageBadge;

  const MadangBackground({
    super.key,
    required this.stage,
    this.child,
    this.showStageBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final variant = isDark ? 'dark' : 'light';

    final stageAsset =
        'assets/illustrations/hanok_stages/stage_${stage.assetSlug}_$variant.png';
    final fallbackAsset = 'assets/illustrations/hanok/madang($variant).png';

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── BG image with cascading fallback ──
        _BackgroundLayer(
          stageAsset: stageAsset,
          fallbackAsset: fallbackAsset,
          isDark: isDark,
        ),
        if (child != null) child!,
        if (showStageBadge)
          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(child: _StageBadge(stage: stage)),
          ),
      ],
    );
  }
}

class _BackgroundLayer extends StatelessWidget {
  final String stageAsset;
  final String fallbackAsset;
  final bool isDark;
  const _BackgroundLayer({
    required this.stageAsset,
    required this.fallbackAsset,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // 1차: stage PNG (가장 정확한 단계 표현)
    return Image.asset(
      stageAsset,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (ctx, _, __) => Image.asset(
        // 2차: 기존 madang PNG
        fallbackAsset,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (ctx, _, __) {
          // 3차: 단색 gradient — v4 home 의 기존 분위기 유지
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? const [
                        Color(0xFF14201E),
                        Color(0xFF0E1815),
                        Color(0xFF0A1310),
                      ]
                    : const [
                        Color(0xFFFAF6EC),
                        Color(0xFFF4ECDA),
                        Color(0xFFEEDFC2),
                      ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StageBadge extends StatelessWidget {
  final HanokStage stage;
  const _StageBadge({required this.stage});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: s.bg.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(SoriRadius.pill),
        border: Border.all(
          color: SoriColors.primary.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.home_work_outlined, size: 14, color: SoriColors.primary),
          const SizedBox(width: 4),
          Text(
            _stageShortLabel(stage),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: s.text,
            ),
          ),
        ],
      ),
    );
  }

  // 짧은 KR 라벨 — 홈 배지 폭 제한.
  // 풀 다국어는 vocab_packs_screen 의 _StageLabel 이 ARB 키로 처리한다.
  String _stageShortLabel(HanokStage st) => switch (st) {
    HanokStage.empty => '터',
    HanokStage.foundation => '주춧돌',
    HanokStage.pillars => '기둥',
    HanokStage.beams => '대들보',
    HanokStage.thatchRoof => '초가',
    HanokStage.tileRoofPartial => '기와',
    HanokStage.tileRoofComplete => '기와 완성',
    HanokStage.dancheong => '단청',
    HanokStage.gate => '솟을대문',
    HanokStage.windows => '창호',
    HanokStage.sideBuilding => '사랑채',
    HanokStage.jongga => '종갓집',
  };
}
