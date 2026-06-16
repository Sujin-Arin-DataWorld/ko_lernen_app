import 'package:flutter/material.dart';

import '../../data/dure_title.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/gye.dart';
import '../../services/gye_service.dart';
import 'celebration.dart';
import 'sheet.dart';
import 'tokens.dart';

/// 두레판 — 계 주간 공동 기여를 "함께 채우는" 협력 보드.
///
/// 듀오링고식 경쟁 리더보드와 정반대 설계:
/// - **합계가 주인공** (개인 순위 아님)
/// - 개인 기여는 **하나의 막대를 색 세그먼트로 함께 채운다** (분리된 경쟁 막대 X)
/// - 범례에 **순위 숫자·등수 없음** — 대신 **칭호**(든든이/새내기/새싹/일꾼, 비위계)
/// - **다른 계원 칩 탭 → 응원**(정형 격려, 3픽 리텐션 훅)
/// - **전원 참여 챌린지**(5픽): 모두가 1팩+ 하면 🔥 (협력 강조)
/// - 강등·꼴등 낙인 없음 — 쌓기만
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

  /// 전원 참여(5픽) 달성 축하 — 앱 실행당 계마다 1회 (재진입 스팸 방지).
  static final Set<String> _allInCelebrated = {};

  static String _titleLabel(AppL10n t, DureTitle title) => switch (title) {
    DureTitle.duru => t.dureTitleDuru,
    DureTitle.newcomer => t.dureTitleNewcomer,
    DureTitle.sprout => t.dureTitleSprout,
    DureTitle.helper => t.dureTitleHelper,
  };

  /// 3픽: 다른 계원 칩 탭 → 정형 격려(자유 텍스트 X = 모더레이션 안전) 시트.
  void _showCheerSheet(
    BuildContext context,
    String targetUid,
    String targetNickname,
  ) {
    final t = AppL10n.of(context);
    final cheers = [
      t.gyeCheer1,
      t.gyeCheer2,
      t.gyeCheer3,
      t.gyeCheer4,
      t.gyeCheer5,
    ];
    showSoriSheet<void>(
      context: context,
      builder: (sheetCtx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Text(
              '${t.gyeCheerTitle} → $targetNickname',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
          for (var i = 0; i < cheers.length; i++)
            ListTile(
              leading: const Icon(
                Icons.volunteer_activism_outlined,
                color: SoriColors.tiger,
              ),
              title: Text(cheers[i]),
              onTap: () async {
                Navigator.of(sheetCtx).pop();
                final ok = await GyeService.sendCheer(
                  gyeId: gyeId,
                  targetUid: targetUid,
                  targetNickname: targetNickname,
                  cheerCode: i + 1,
                );
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t.gyeStickerRateLimited)),
                  );
                }
              },
            ),
          const SizedBox(height: Spacing.sm),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    return StreamBuilder<List<GyeMember>>(
      stream: GyeService.membersStream(gyeId),
      builder: (context, snap) {
        final members = [...(snap.data ?? const <GyeMember>[])]
          ..sort(
            (a, b) =>
                b.weeklyPacksContributed.compareTo(a.weeklyPacksContributed),
          );
        final total = members.fold<int>(
          0,
          (sum, m) => sum + m.weeklyPacksContributed,
        );
        final goal = meta.weeklyGoalPacks;
        final done = goal > 0 && total >= goal;
        final contributors = members
            .where((m) => m.weeklyPacksContributed > 0)
            .toList();
        final now = DateTime.now();
        // 5픽: 전원 참여 챌린지 (모두 1팩+).
        final allIn =
            members.isNotEmpty && contributors.length == members.length;

        // 전원 참여 달성 순간 → 단청 burst(실행당 1회) + 피드 1회 기록(주 dedup).
        if (allIn && members.length >= 2 && !_allInCelebrated.contains(gyeId)) {
          _allInCelebrated.add(gyeId);
          // 피드 기록은 결정적 doc id로 중복 0 (GyeService가 보장).
          // ignore: discarded_futures, unawaited_futures
          GyeService.markAllInAchieved(gyeId);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              SoriCelebration.burst(context);
            }
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 — 라벨 + 합계(주인공) / 목표
            Row(
              children: [
                Icon(
                  done ? Icons.local_florist_rounded : Icons.grass_rounded,
                  size: 16,
                  color: done ? SoriColors.gold : SoriColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    t.gyeDureTitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: s.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$total',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: done ? SoriColors.gold : SoriColors.primary,
                        ),
                      ),
                      TextSpan(
                        text: goal > 0 ? ' / $goal' : '',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: s.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
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
            // 범례 — 칭호(비위계) · 본인 강조 · 계장 👑 · 탭하면 응원
            if (contributors.isEmpty)
              Text(
                t.gyeDureEmpty,
                style: TextStyle(
                  fontSize: 12,
                  color: s.textMuted,
                  fontStyle: FontStyle.italic,
                ),
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
                      titleLabel: _titleLabel(
                        t,
                        dureTitleFor(m, members, now: now),
                      ),
                      onTap: m.uid == myUid
                          ? null
                          : () => _showCheerSheet(context, m.uid, m.nickname),
                    ),
                ],
              ),
            // 5픽: 전원 참여 챌린지 줄
            if (members.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    allIn
                        ? Icons.local_fire_department_rounded
                        : Icons.groups_outlined,
                    size: 14,
                    color: allIn ? SoriColors.tiger : s.textMuted,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      allIn ? t.gyeChallengeDone : t.gyeChallengeTitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: allIn ? FontWeight.w800 : FontWeight.w600,
                        color: allIn ? SoriColors.tiger : s.textMuted,
                      ),
                    ),
                  ),
                  Text(
                    '${contributors.length}/${members.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: allIn ? SoriColors.tiger : s.textMuted,
                    ),
                  ),
                ],
              ),
            ],
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
  final VoidCallback? onTap;
  const _MemberChip({
    required this.color,
    required this.name,
    required this.count,
    required this.isMe,
    required this.isOwner,
    required this.title,
    required this.titleLabel,
    this.onTap,
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
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isMe ? color.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(SoriRadius.pill),
        border: Border.all(
          color: isMe ? color.withValues(alpha: 0.5) : s.border,
          width: 1,
        ),
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
            const Icon(
              Icons.workspace_premium_rounded,
              size: 12,
              color: SoriColors.gold,
            ),
            const SizedBox(width: 2),
          ],
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
              color: s.text,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            titleLabel,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: titleColor,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(Icons.volunteer_activism_outlined, size: 12, color: s.textDim),
          ],
        ],
      ),
    );
    if (onTap == null) {
      return chip;
    }
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: chip,
    );
  }
}
