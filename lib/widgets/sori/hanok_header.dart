import 'package:flutter/material.dart';

import 'hanok_tokens.dart';

/// **HanokHeader** — 모듈 상단 wide 한옥 일러스트 배너.
///
/// 10:3 가로 비율(`scholar_room.png`, `achievements.png` 등)을 위한 자리.
/// 이미지가 아직 없으면 단청 그라데이션 + 아이콘 fallback으로 자연스럽게 떨어진다.
///
/// ```dart
/// HanokHeader(asset: 'assets/illustrations/hanok/scholar_room.png',
///             fallbackIcon: Icons.tune)
/// ```
class HanokHeader extends StatelessWidget {
  final String asset;

  /// 자산 로드 실패 시 표시할 아이콘.
  final IconData fallbackIcon;

  /// 자산 로드 실패 시 그라데이션 톤. null이면 한옥 토큰 한지/단청.
  final Color? fallbackTint;

  /// 가로/세로 비율 — 기본 10:3 (1888×560 권장).
  final double aspectRatio;

  /// 상단 corner radius — 화면 최상단에 붙을 때는 0, 카드 안에 넣을 때는 16.
  final double radius;

  const HanokHeader({
    super.key,
    required this.asset,
    this.fallbackIcon = Icons.image_outlined,
    this.fallbackTint,
    this.aspectRatio = 10 / 3,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final tint = fallbackTint ?? HanokColors.cheong;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) => _Fallback(
            icon: fallbackIcon,
            tint: tint,
          ),
        ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  final IconData icon;
  final Color tint;

  const _Fallback({required this.icon, required this.tint});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HanokColors.hanjiCream,
            Color.alphaBlend(tint.withValues(alpha: 0.16), HanokColors.hanjiCream),
          ],
        ),
      ),
      child: Center(
        child: Icon(icon, size: 48, color: tint.withValues(alpha: 0.55)),
      ),
    );
  }
}
