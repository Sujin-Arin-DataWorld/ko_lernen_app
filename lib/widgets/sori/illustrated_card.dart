import 'package:flutter/material.dart';

import 'pressable.dart';
import 'tokens.dart';

/// 일러스트 카드의 상태 — 시각 처리만 바꾼다 (탭 동작은 호출부 소관).
enum SoriIllustratedCardState {
  /// 기본 — 일러스트 원색.
  normal,

  /// 잠김 — 일러스트 딤 + 우상단 자물쇠 칩.
  locked,

  /// 프리미엄 티저 — 우상단 골드 왕관 칩 (탭하면 페이월로 보내는 용도).
  premium,

  /// 클리어 — [overlay] (예: 단청 도장)를 우상단에 얹는다.
  cleared,
}

/// **SoriIllustratedCard** — 균일 일러스트 그리드 카드 (2026-08-13 Phase 1).
///
/// Vocabulary급 카드 규율의 표준형: 상단 일러스트 슬롯(고정 비율) →
/// 타이틀/서브타이틀 → footer(진행 점·칩). 모든 그리드(단어팩·활동 카탈로그·
/// 카테고리)가 이 한 규격을 쓴다.
///
/// **일러스트는 항상 폴백과 함께**: [illustrationAsset] 이 없거나 로드에
/// 실패하면 [fallback] 을 같은 슬롯에 그린다 — 아트가 나중에 드롭되어도
/// 화면이 먼저 배포될 수 있는 계약 (asset 규약: 새 파일을 넣기만 하면 된다).
class SoriIllustratedCard extends StatelessWidget {
  const SoriIllustratedCard({
    super.key,
    required this.title,
    this.subtitle,
    this.illustrationAsset,
    this.fallback,
    this.footer,
    this.state = SoriIllustratedCardState.normal,
    this.overlay,
    this.imageOverlay,
    this.onTap,
    this.onLongPress,
    this.semanticsLabel,
    this.imageAspectRatio = 16 / 10,
    this.shrinkWrap = false,
  });

  final String title;
  final String? subtitle;

  /// `assets/illustrations/...` 경로. null 이면 [fallback] 만 그린다.
  final String? illustrationAsset;

  /// 일러스트 부재/로드 실패 시 슬롯에 그릴 위젯 (아이콘·도장 등).
  final Widget? fallback;

  /// 타이틀 아래 슬롯 — 진행 점, 카운트, 칩 등.
  final Widget? footer;

  final SoriIllustratedCardState state;

  /// [SoriIllustratedCardState.cleared] 일 때 우상단에 얹는 위젯 (단청 도장).
  final Widget? overlay;

  /// 이미지 슬롯 **내부** 우하단에 얹는 위젯 (§P4-3 — 분(分) 미니 필 등).
  /// ⚠️ 카드 전체 Stack 이 아니라 이미지 ClipRRect 안에 배치된다 — 밖에
  /// 두면 footer 위에 얹힌다. 기본 null — 기존 호출부(팩 그리드 등) 영향 0.
  final Widget? imageOverlay;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticsLabel;
  final double imageAspectRatio;

  /// 세로가 **비고정**인 컨텍스트(SliverToBoxAdapter 의 히어로 카드 등)용.
  /// 기본(false)은 그리드 셀의 고정 높이를 전제로 본문을 Expanded +
  /// spaceBetween 으로 채우지만, 비고정 높이에서 Expanded 는 예외를 던진다 —
  /// true 면 본문이 내용만큼만 차지한다 (footer 는 내용 뒤에 붙음).
  final bool shrinkWrap;

  bool get _locked => state == SoriIllustratedCardState.locked;

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final tt = SoriTextTheme.of(context);
    final light = s.brightness == Brightness.light;
    final raised = light ? SoriColors.lightSurfaceRaised : s.surface;

    final Widget body = Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.sm,
        Spacing.md,
        Spacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
        // 고정 높이(그리드 셀)에서는 footer 를 바닥에 핀 — 비고정에서는
        // 내용 흐름대로.
        mainAxisAlignment: shrinkWrap
            ? MainAxisAlignment.start
            : MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: tt.cardTitle.copyWith(
                  color: _locked ? s.text.withValues(alpha: 0.55) : s.text,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: tt.cardSubtitle),
              ],
            ],
          ),
          if (footer != null) ...[const SizedBox(height: Spacing.xs), footer!],
        ],
      ),
    );

    final card = Container(
      clipBehavior: Clip.none,
      decoration: BoxDecoration(
        color: _locked ? s.surface.withValues(alpha: 0.6) : raised,
        borderRadius: SoriRadius.brLg,
        border: Border.all(color: s.border, width: 1),
        boxShadow: light && !_locked ? SoriElevation.low : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(SoriRadius.lg - 1),
                ),
                child: AspectRatio(
                  aspectRatio: imageAspectRatio,
                  // §P4-3: imageOverlay 는 이미지 슬롯 내부 Stack — 필이
                  // 이미지 위에만 얹히고 footer 를 침범하지 않는다.
                  child: imageOverlay == null
                      ? _Illustration(
                          asset: illustrationAsset,
                          fallback: fallback,
                          dimmed: _locked,
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            _Illustration(
                              asset: illustrationAsset,
                              fallback: fallback,
                              dimmed: _locked,
                            ),
                            Positioned(
                              right: Spacing.xs + 2,
                              bottom: Spacing.xs + 2,
                              child: imageOverlay!,
                            ),
                          ],
                        ),
                ),
              ),
              if (shrinkWrap) body else Expanded(child: body),
            ],
          ),
          if (_locked)
            const Positioned(
              top: Spacing.sm,
              right: Spacing.sm,
              child: _LockChip(),
            ),
          if (state == SoriIllustratedCardState.premium)
            const Positioned(
              top: Spacing.sm,
              right: Spacing.sm,
              child: _PremiumChip(),
            ),
          if (state == SoriIllustratedCardState.cleared && overlay != null)
            Positioned(top: -4, right: -4, child: overlay!),
        ],
      ),
    );

    return SoriPressable(
      onTap: onTap,
      onLongPress: onLongPress,
      haptic: _locked ? SoriHaptic.selection : SoriHaptic.light,
      child: semanticsLabel == null
          ? card
          : Semantics(button: true, label: semanticsLabel, child: card),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({
    required this.asset,
    required this.fallback,
    required this.dimmed,
  });

  final String? asset;
  final Widget? fallback;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final placeholder = ColoredBox(
      color: s.surfaceAlt,
      child: Center(child: fallback ?? const SizedBox.shrink()),
    );
    final Widget image = asset == null
        ? placeholder
        : Image.asset(
            asset!,
            fit: BoxFit.cover,
            // 아트 미존재/미번들 시 조용히 폴백 — 화면이 아트보다 먼저 배포된다.
            errorBuilder: (_, _, _) => placeholder,
          );
    if (!dimmed) {
      return image;
    }
    return Opacity(opacity: 0.45, child: image);
  }
}

class _LockChip extends StatelessWidget {
  const _LockChip();

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: s.bg.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        border: Border.all(color: s.border),
      ),
      child: Icon(Icons.lock_rounded, size: 14, color: s.textMuted),
    );
  }
}

class _PremiumChip extends StatelessWidget {
  const _PremiumChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
        color: SoriColors.gold,
        borderRadius: SoriRadius.brPill,
      ),
      child: Icon(
        Icons.workspace_premium_rounded,
        size: 14,
        color: SoriColors.onGoldFill,
      ),
    );
  }
}
