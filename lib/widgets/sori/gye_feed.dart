import 'package:flutter/material.dart';

import '../../data/sticker_catalog.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/gye.dart';
import 'tokens.dart';

/// 계 피드 — 최근 이벤트(도장 획득·승급·스티커). plan §7.4/8.3.
/// 3c는 골격 — 이벤트는 3e Cloud Function(`onPackCleared`) + 3d 스티커가 채움.
class GyeFeed extends StatelessWidget {
  final List<GyeFeedEvent> events;

  const GyeFeed({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Text(
            t.gyeFeedEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(color: s.textMuted, fontSize: 13, height: 1.5),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      itemCount: events.length,
      itemBuilder: (_, i) {
        final e = events[i];
        return ListTile(
          dense: true,
          leading: e.type == GyeFeedType.sticker
              ? _stickerLeading(e)
              : Icon(_icon(e.type), color: _color(e.type), size: 20),
          title: Text(_message(t, e), style: const TextStyle(fontSize: 13)),
        );
      },
    );
  }

  IconData _icon(GyeFeedType ty) => switch (ty) {
        GyeFeedType.packCleared => Icons.workspace_premium_outlined,
        GyeFeedType.questCompleted => Icons.local_florist_outlined,
        GyeFeedType.levelUp => Icons.trending_up_rounded,
        GyeFeedType.goalAchieved => Icons.celebration_outlined,
        GyeFeedType.sticker => Icons.emoji_emotions_outlined,
        GyeFeedType.cheer => Icons.volunteer_activism_outlined,
      };

  Color _color(GyeFeedType ty) => switch (ty) {
        GyeFeedType.packCleared => SoriColors.gold,
        GyeFeedType.questCompleted => SoriColors.primary,
        GyeFeedType.levelUp => SoriColors.accent,
        GyeFeedType.goalAchieved => SoriColors.tiger,
        GyeFeedType.sticker => SoriColors.highlight,
        GyeFeedType.cheer => SoriColors.tiger,
      };

  String _message(AppL10n t, GyeFeedEvent e) => switch (e.type) {
        GyeFeedType.packCleared => t.gyeFeedPackCleared(e.actorNickname),
        GyeFeedType.questCompleted => t.gyeFeedQuest(e.actorNickname),
        GyeFeedType.levelUp => t.gyeFeedLevelUp(e.actorNickname),
        GyeFeedType.goalAchieved => t.gyeFeedGoalAchieved,
        GyeFeedType.sticker => t.gyeFeedSticker(e.actorNickname),
        GyeFeedType.cheer =>
          '${e.actorNickname} → ${(e.payload['targetNickname'] as String?) ?? ''}  ${_cheerText(t, (e.payload['cheerCode'] as num?)?.toInt() ?? 1)}',
      };

  /// 응원 코드(1~5) → 정형 메시지 (자유 텍스트 X = 모더레이션 안전).
  String _cheerText(AppL10n t, int code) => switch (code) {
        1 => t.gyeCheer1,
        2 => t.gyeCheer2,
        3 => t.gyeCheer3,
        4 => t.gyeCheer4,
        _ => t.gyeCheer5,
      };

  Widget _stickerLeading(GyeFeedEvent e) {
    final code = (e.payload['stickerCode'] as num?)?.toInt() ?? 0;
    final def = stickerByCode(code);
    if (def == null) {
      return const Icon(Icons.emoji_emotions_outlined,
          color: SoriColors.highlight, size: 20);
    }
    return SizedBox(
      width: 40,
      height: 40,
      child: Image.asset(
        def.asset,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
            Icons.emoji_emotions_outlined,
            color: SoriColors.highlight,
            size: 20),
      ),
    );
  }
}
