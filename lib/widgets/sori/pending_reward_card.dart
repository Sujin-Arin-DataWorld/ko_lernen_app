import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'pressable.dart';
import 'tokens.dart';

/// 지금 열 수 있는 보자기(학습 보상)가 있다는 발견 배너 — 홈·사랑방 공용.
///
/// [count] 는 [DecorationRewardService.openableBoxCount] 로 이미 0 초과일 때만
/// 렌더된다(손상된 상자는 제외됨). 탭하면 부모가 `/bojagi` 로 보내고, 돌아온 뒤
/// 자신의 pending-box 상태를 새로고침한다.
///
/// Jin 선호대로 숫자 배지가 아니라 인라인 **콘텐츠 카드**다.
class PendingRewardCard extends StatelessWidget {
  final int count;
  final VoidCallback onOpen;

  const PendingRewardCard({
    super.key,
    required this.count,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    final s = SoriSurfaces.of(context);
    return Semantics(
      button: true,
      label: t.homeBojagiTitle,
      child: SoriPressable(
        onTap: onOpen,
        haptic: SoriHaptic.selection,
        child: Container(
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: SoriColors.gold.withValues(alpha: 0.10),
            borderRadius: SoriRadius.brMd,
            border: Border.all(color: SoriColors.gold.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.card_giftcard_rounded,
                color: SoriColors.gold,
                size: 28,
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.homeBojagiTitle, style: text.cardTitle),
                    const SizedBox(height: 2),
                    Text(
                      t.homeBojagiBody(count),
                      style: text.bodySmall.copyWith(color: s.textMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: s.textDim),
            ],
          ),
        ),
      ),
    );
  }
}
