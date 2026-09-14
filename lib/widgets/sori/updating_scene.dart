import 'package:flutter/material.dart';

import 'tokens.dart';

/// Keeps unfinished Hanok/Gye visuals behind the static preview notice.
/// Personal Hanok routes use the approved V3 preview; retired V1 maps are
/// no longer a fallback when this flag changes.
const bool kHanokWorldUpdating = true;

/// **SoriUpdatingScene** — 재작업 중인 시각 자산을 가리는 표준 베일.
///
/// 완성도 높은 스틸 한 장 위에 반투명 스크림을 얹고, 중앙에 작은 원형
/// 매트 안 공사 아이콘 + 안내 문구 한 줄을 띄운다. 정적이며(애니메이션
/// 없음) 새 색은 쓰지 않는다 — 배지·필 장식도 없이 텍스트만.
class SoriUpdatingScene extends StatelessWidget {
  /// 베일 아래 깔릴 스틸 자산.
  final String asset;

  /// 매트 아래 표시할 안내 문구(예: "한옥을 새로 짓는 중이에요").
  final String message;

  /// 자산 정렬 — 그림마다 중심 피사체 위치가 달라 호출부에서 지정한다.
  final Alignment alignment;

  /// 자산을 가용 영역에 배치하는 방식. 기존 호출부는 cover를 유지한다.
  final BoxFit assetFit;

  /// 자산 여백에 사용할 배경색. 지정하지 않으면 현재 Sori surface를 쓴다.
  final Color? backdropColor;

  /// 스크림 불투명도.
  final double veilOpacity;

  /// 아이콘 매트+문구 블록의 정렬. 기본은 정중앙 — 호출부가 그 위에 다른
  /// 오버레이(예: Gye 카드의 우하단 진행 링)를 얹어 겹치면 상단·하단
  /// 쪽으로 옮길 수 있다.
  final Alignment messageAlignment;

  const SoriUpdatingScene({
    super.key,
    required this.asset,
    required this.message,
    this.alignment = Alignment.center,
    this.assetFit = BoxFit.cover,
    this.backdropColor,
    this.veilOpacity = 0.45,
    this.messageAlignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final tt = SoriTextTheme.of(context);
    return Semantics(
      label: message,
      image: true,
      excludeSemantics: true,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ExcludeSemantics(
            child: ColoredBox(
              color: backdropColor ?? s.surfaceAlt,
              child: Image.asset(
                asset,
                fit: assetFit,
                alignment: alignment,
                errorBuilder: (_, __, ___) => ColoredBox(color: s.surfaceAlt),
              ),
            ),
          ),
          ColoredBox(color: s.bg.withValues(alpha: veilOpacity)),
          LayoutBuilder(
            builder: (context, constraints) {
              final showIcon = constraints.maxHeight >= 120;
              final compactMessage = constraints.maxHeight < 80;
              final verticalPadding = showIcon ? Spacing.md : Spacing.xs;
              return Align(
                key: const ValueKey('sori-updating-scene-message-align'),
                alignment: messageAlignment,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: verticalPadding,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showIcon) ...[
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: s.surface.withValues(alpha: 0.9),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.construction_rounded,
                            size: 16,
                            color: SoriColors.accent,
                          ),
                        ),
                        const SizedBox(height: Spacing.xs),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.lg,
                        ),
                        child: Text(
                          message,
                          textAlign: TextAlign.center,
                          maxLines: compactMessage ? 1 : 2,
                          overflow: compactMessage
                              ? TextOverflow.ellipsis
                              : null,
                          softWrap: true,
                          style: tt.label,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
