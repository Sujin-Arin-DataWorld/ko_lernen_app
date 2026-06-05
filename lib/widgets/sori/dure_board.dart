import 'package:flutter/material.dart';

import '../../data/dure_title.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/gye.dart';
import '../../services/gye_service.dart';
import 'tokens.dart';

/// 두레판 — 계 주간 공동 기여를 "함께 채우는" 협력 보드.
///
/// 듀오링고식 경쟁 리더보드와 정반대 설계:
/// - **합계가 주인공** (개인 순위 아님)
/// - 개인 기여는 **하나의 막대를 색 세그먼트로 함께 채운다** (분리된 경쟁 막대 X)
/// - 범례에 **순위 숫자·등수 없음** — 대신 **칭호**(든든이/새내기/새싹/일꾼, 비위계)
/// - 강등·꼴등 낙인 없음 — 쌓기만
///
/// 데이터는 `weeklyPacksContributed`(CF `on_pack_cleared`가 매주 적립).
class DureBoard extends StatelessWidget {
  final String gyeId;
  final GyeMeta meta;
  final String? myUid;

  const DureBoard({
    super.key,
    required this.gyeId,
    required this.meta,
    this.myUid,
  });

  /// 멤버 색 — 기여순 인덱스 → 단청 팔레트 (막대 세그먼트 == 칩 색점).
  static const List<Color> _palette = [
    SoriColors.primary, // 녹청
    SoriColors.tiger, // 호랑이 주황
    SoriColors.highlight, // 청금석
    SoriColors.gold, // 황
    SoriColors.accent, // 석간주
    SoriColors.warning, // 황 lifted
  ];
  static Color _colorFor(int i) => _palette[i % _palette.length];

  static String _titleLabel(AppL10n t, DureTitle title) => switch (title) {
        DureTitle.duru => t.dureTitleDuru,
        DureTitle.newcomer => t.dureTitleNewcomer,
        DureTitle.sprout => t.dureTitleSprout,
        DureTitle.helper => t.dureTitleHelper,
      };

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    return StreamBuilder<List<GyeMember>>(
      stream: GyeService.membersStream(gyeId),
      builder: (context, snap) {
        final members = [...(snap.data ?? const <GyeMember>[])]..sort((a, b) =>
            b.weeklyPacksContributed.compareTo(a.weeklyPacksContributed));
        final total =
            members.fold<int>(0, (sum, m) => sum + m.weeklyPacksContributed);
        final goal = meta.weeklyGoalPacks;
        final done = goal > 0 && total >= goal;
        final contributors =
            members.where((m) => m.weeklyPacksContributed > 0).toList();
        final now = DateTime.now();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 — 라벨 + 합계(주인공) / 목표
            Row(
              children: [
                Icon(done ? Icons.local_florist_rounded : Icons.grass_rounded,
                    size: 16,
                    color: done ? SoriColors.gold : SoriColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    t.gyeDureTitle,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: s.text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text.rich(TextSpan(children: [
                  TextSpan(
                    text: '$total',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: done ? SoriColors.gold : SoriColors.primary),
                  ),
                  TextSpan(
                    text: goal > 0 ? ' / $goal' : '',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: s.textMuted),
                  ),
                ])),
              ],
            ),
            const SizedBox(height: 8),
            // 스택 막대 — 하나를 여럿이 색으로 함께 채운다
            ClipRRect(
              borderRadius: BorderRadius.circular(SoriRadius.pill),
              child: SizedBox(
                height: 12,
                child: (total == 0 || goal <= 0)
                    ? ColoredBox(color: s.border)
                    : Row(
                        children: [
                          for (var i = 0; i < contributors.length; i++)
                            Expanded(
                              flex: contributors[i].weeklyPacksContributed,
                              child: ColoredBox(color: _colorFor(i)),
                            ),
                          if (total < goal)
                            Expanded(
                              flex: goal - total,
                              child: ColoredBox(color: s.border),
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 10),
            // 범례 — 칭호(비위계) · 본인 강조 · 계장 👑
            if (contributors.isEmpty)
              Text(
                t.gyeDureEmpty,
                style: TextStyle(
                    fontSize: 12,
                    color: s.textMuted,
                    fontStyle: FontStyle.italic),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final m in members)
                    _MemberChip(
                      color: contributors.contains(m)
                          ? _colorFor(contributors.indexOf(m))
                          : s.textDim,
                      name: m.uid == myUid ? t.gyeDureMe : m.nickname,
                      count: m.weeklyPacksContributed,
                      isMe: m.uid == myUid,
                      isOwner: m.role == GyeRole.owner,
                      title: dureTitleFor(m, members, now: now),
                      titleLabel:
                          _titleLabel(t, dureTitleFor(m, members, now: now)),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _MemberChip extends StatelessWidget {
  final Color color;
  final String name;
  final int count;
  final bool isMe;
  final bool isOwner;
  final DureTitle title;
  final String titleLabel;
  const _MemberChip({
    required this.color,
    required this.name,
    required this.count,
    required this.isMe,
    required this.isOwner,
    required this.title,
    required this.titleLabel,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final titleColor = switch (title) {
      DureTitle.duru => SoriColors.gold,
      DureTitle.newcomer => SoriColors.highlight,
      DureTitle.sprout => SoriColors.primary,
      DureTitle.helper => s.textMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isMe ? color.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(SoriRadius.pill),
        border: Border.all(
            color: isMe ? color.withValues(alpha: 0.5) : s.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          if (isOwner) ...[
            const Icon(Icons.workspace_premium_rounded,
                size: 12, color: SoriColors.gold),
            const SizedBox(width: 2),
          ],
          Text(
            name,
            style: TextStyle(
                fontSize: 12,
                fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
                color: s.text),
          ),
          const SizedBox(width: 5),
          // 칭호 배지 (비위계 인정)
          Text(
            titleLabel,
            style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w800, color: titleColor),
          ),
          const SizedBox(width: 5),
          Text(
            '$count',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}
