import 'package:flutter/material.dart';

import 'button.dart';
import 'motion.dart';
import 'tokens.dart';

/// **SoriEmptyState** — 빈 화면·오류·완료 상태의 표준 표현.
///
/// 한옥 세계관을 끊지 않기 위해 모든 빈 상태는
/// "일러스트 + 한 줄 제목 + (선택) 보조 설명 + (선택) CTA" 4단 구성.
///
/// 일러스트 PNG가 아직 없을 때는 [icon]만 지정하면 자동으로 fallback —
/// 따라서 자산 생성 작업과 분리해 미리 코드에 박을 수 있다.
///
/// ```dart
/// SoriEmptyState(
///   asset: 'assets/illustrations/mascot/tiger_sit.png',
///   icon: Icons.bed_outlined,
///   title: '곧 만나요',
///   body: 'B2 시나리오 5개를 준비 중이에요.',
///   ctaLabel: '알림 받기',
///   onCta: _toggleWishlist,
/// )
/// ```
class SoriEmptyState extends StatelessWidget {
  /// 사용할 일러스트 자산 (없거나 로드 실패 시 [icon] fallback).
  final String? asset;

  /// 일러스트 fallback 또는 자산 미지정 시 표시될 아이콘.
  final IconData icon;

  /// 짧은 한 줄 제목.
  final String title;

  /// 보조 설명 (옵션).
  final String? body;

  /// CTA 버튼 라벨 — null이면 버튼 미표시.
  final String? ctaLabel;

  /// CTA 콜백 — null이면 버튼 미표시.
  final VoidCallback? onCta;

  /// 보조 CTA (옵션) — outlined 톤. 두 번째 액션 필요 시.
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// 일러스트 영역 max 높이. 자산 크기에 따라 보수적으로 잡는다.
  final double illustrationMaxHeight;

  /// 강조 색 — 아이콘 fallback / CTA 톤. 기본은 primary.
  final Color? accent;

  const SoriEmptyState({
    super.key,
    this.asset,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.body,
    this.ctaLabel,
    this.onCta,
    this.secondaryLabel,
    this.onSecondary,
    this.illustrationMaxHeight = 200,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final accentColor = accent ?? SoriColors.primary;

    // 짧은 뷰포트(폰 가로모드·분할화면)에서는 200dp 일러스트가 제목·CTA 를
    // 화면 밖으로 밀어냈다(2026-08-06: dojangcheop @740×360 에서 17px 오버플로).
    // 장식인 일러스트가 먼저 양보하고, 그래도 모자라면 스크롤한다.
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.maxHeight.isFinite;
        final illustrationHeight = hasBoundedHeight
            ? illustrationMaxHeight.clamp(0.0, constraints.maxHeight * 0.38)
            : illustrationMaxHeight;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: hasBoundedHeight ? constraints.maxHeight : 0,
            ),
            child: _buildContent(
              context,
              s,
              accentColor,
              illustrationHeight.toDouble(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    SoriSurfaces s,
    Color accentColor,
    double illustrationHeight,
  ) {
    final illustration = SizedBox(
      height: illustrationHeight,
      child: Center(
        child: asset != null
            ? Image.asset(
                asset!,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) =>
                    _IconFallback(icon: icon, color: accentColor),
              )
            : _IconFallback(icon: icon, color: accentColor),
      ),
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.xl,
          vertical: Spacing.lg,
        ),
        child: SoriEntrance(
          duration: const Duration(milliseconds: 380),
          slideY: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              illustration,
              const SizedBox(height: Spacing.lg),
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    color: s.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    height: 1.3,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (body != null) ...[
                const SizedBox(height: Spacing.sm),
                Text(
                  body!,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    color: s.textMuted,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
              if (onCta != null && ctaLabel != null) ...[
                const SizedBox(height: Spacing.xl),
                SoriButton(label: ctaLabel!, onTap: onCta, accent: accentColor),
              ],
              if (onSecondary != null && secondaryLabel != null) ...[
                const SizedBox(height: Spacing.sm),
                SoriButton(
                  label: secondaryLabel!,
                  onTap: onSecondary,
                  variant: SoriButtonVariant.outlined,
                  accent: accentColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _IconFallback extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconFallback({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 56, color: color),
    );
  }
}
