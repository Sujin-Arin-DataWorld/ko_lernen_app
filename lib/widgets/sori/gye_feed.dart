import 'package:flutter/material.dart';

import '../../data/sticker_catalog.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/gye.dart';
import 'sticker_image.dart';
import 'tokens.dart';

/// 계 피드 — 최근 이벤트(도장 획득·승급·스티커·응원) + **반응(reaction)**.
///
/// 반응 = 특정 피드 이벤트에 스티커로 답한 것(`payload.targetEventId`). 타임라인엔
/// 독립 항목으로 띄우지 않고 **대상 이벤트 아래에 작은 스티커**로 묶어 보여준다.
/// 마일스톤 이벤트(클리어·퀘스트·레벨업·목표달성)엔 "반응" 버튼이 붙어
/// `onReact(eventId)`를 호출한다(자유 텍스트 X = 모더레이션 안전).
class GyeFeed extends StatelessWidget {
  final List<GyeFeedEvent> events;

  /// 마일스톤 이벤트의 "반응" 버튼 → 스티커 피커 오픈(소유 화면이 처리).
  final void Function(String targetEventId)? onReact;
  final bool shrinkWrap;

  const GyeFeed({
    super.key,
    required this.events,
    this.onReact,
    this.shrinkWrap = false,
  });

  /// 이벤트를 (타임라인, 반응 by targetEventId)로 분리 — 순수 함수(테스트 대상).
  static ({
    List<GyeFeedEvent> timeline,
    Map<String, List<GyeFeedEvent>> reactions,
  })
  splitReactions(List<GyeFeedEvent> events) {
    final timeline = <GyeFeedEvent>[];
    final reactions = <String, List<GyeFeedEvent>>{};
    for (final e in events) {
      final target = e.payload['targetEventId'] as String?;
      if (target != null && target.isNotEmpty) {
        reactions.putIfAbsent(target, () => []).add(e);
      } else {
        timeline.add(e);
      }
    }
    return (timeline: timeline, reactions: reactions);
  }

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
    final split = splitReactions(events);
    final timeline = split.timeline;
    final reactions = split.reactions;
    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      itemCount: timeline.length,
      itemBuilder: (_, i) {
        final e = timeline[i];
        final myReactions = reactions[e.id] ?? const <GyeFeedEvent>[];
        final reactable =
            onReact != null && e.type.supportsReaction && e.id.isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              dense: true,
              leading: e.type == GyeFeedType.sticker
                  ? _stickerLeading(e)
                  : Icon(_icon(e.type), color: _color(e.type), size: 20),
              title: Text(_message(t, e), style: const TextStyle(fontSize: 13)),
              trailing: reactable
                  ? IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.add_reaction_outlined, size: 20),
                      color: SoriColors.highlight,
                      tooltip: t.gyeReactTooltip,
                      onPressed: () => onReact!(e.id),
                    )
                  : null,
            ),
            // 반응 스티커 행 — 대상 이벤트 아래에 작게 묶어 표시.
            if (myReactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(
                  left: 56,
                  right: Spacing.md,
                  bottom: Spacing.xs,
                ),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [for (final r in myReactions) _reactionThumb(r)],
                ),
              ),
          ],
        );
      },
    );
  }

  IconData _icon(GyeFeedType ty) => switch (ty) {
    GyeFeedType.packCleared => Icons.workspace_premium_outlined,
    GyeFeedType.questCompleted => Icons.local_florist_outlined,
    GyeFeedType.levelUp => Icons.trending_up_rounded,
    GyeFeedType.goalAchieved => Icons.celebration_outlined,
    GyeFeedType.allInChallenge => Icons.local_fire_department_rounded,
    GyeFeedType.sticker => Icons.emoji_emotions_outlined,
    GyeFeedType.cheer => Icons.volunteer_activism_outlined,
  };

  Color _color(GyeFeedType ty) => switch (ty) {
    GyeFeedType.packCleared => SoriColors.gold,
    GyeFeedType.questCompleted => SoriColors.primary,
    GyeFeedType.levelUp => SoriColors.accent,
    GyeFeedType.goalAchieved => SoriColors.tiger,
    GyeFeedType.allInChallenge => SoriColors.tiger,
    GyeFeedType.sticker => SoriColors.highlight,
    GyeFeedType.cheer => SoriColors.tiger,
  };

  String _message(AppL10n t, GyeFeedEvent e) => switch (e.type) {
    GyeFeedType.packCleared => t.gyeFeedPackCleared(e.actorNickname),
    GyeFeedType.questCompleted => t.gyeFeedQuest(e.actorNickname),
    GyeFeedType.levelUp => t.gyeFeedLevelUp(e.actorNickname),
    // Keep the trusted goal-achieved event, but do not surface a winner or a
    // score-like comparison in the shared courtyard landing feed.
    GyeFeedType.goalAchieved => t.gyeFeedGoalAchieved,
    GyeFeedType.allInChallenge => t.gyeFeedAllIn,
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
      return const Icon(
        Icons.emoji_emotions_outlined,
        color: SoriColors.highlight,
        size: 20,
      );
    }
    return StickerImage(spec: def, size: 40);
  }

  /// 반응 스티커 썸네일(작게) — 대상 이벤트 하단 묶음용.
  Widget _reactionThumb(GyeFeedEvent r) {
    final code = (r.payload['stickerCode'] as num?)?.toInt() ?? 0;
    final def = stickerByCode(code);
    if (def == null) {
      return const Icon(
        Icons.emoji_emotions_outlined,
        color: SoriColors.highlight,
        size: 22,
      );
    }
    return StickerImage(spec: def, size: 28);
  }
}
