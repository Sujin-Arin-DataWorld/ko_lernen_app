import 'package:flutter/material.dart';

import '../../data/quest_catalog.dart';
import '../../models/quest.dart';
import 'tokens.dart';

/// 퀘스트 보상 썸네일 (공용 위젯).
///
/// quests_screen 의 _RewardThumb 에서 승격.
class RewardThumb extends StatelessWidget {
  final String slug;
  final bool earned;

  const RewardThumb({
    super.key,
    required this.slug,
    this.earned = true,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final giftIcon = Icon(
      Icons.card_giftcard_rounded,
      size: 20,
      color: earned ? SoriColors.success : s.textDim,
    );
    return Opacity(
      opacity: earned ? 1.0 : 0.4,
      child: SizedBox(
        width: 34,
        height: 34,
        child: kAvailableDecorations.contains(slug)
            ? Image.asset(
                'assets/illustrations/decorations/$slug.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => giftIcon,
              )
            : giftIcon,
      ),
    );
  }
}
