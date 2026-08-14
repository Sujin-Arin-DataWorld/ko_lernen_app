import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/quest.dart';
import '../../services/decoration_reward_service.dart';
import '../../services/quest_tracker.dart';
import '../../services/storage_service.dart';
import '../../widgets/sori/card.dart';
import '../../widgets/sori/dancheong_stamp.dart' show DancheongMotif;
import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/reward_thumb.dart';
import '../../widgets/sori/screen_background.dart';
import '../../widgets/sori/tokens.dart';
import '../bojagi_screen.dart' show kBojagiClosed;
import '../hanok_world_screen.dart';
import 'sori_stage_common.dart';

class SoriStageHanokScreen extends StatefulWidget {
  const SoriStageHanokScreen({super.key});

  @override
  State<SoriStageHanokScreen> createState() => _SoriStageHanokScreenState();
}

class _SoriStageHanokScreenState extends State<SoriStageHanokScreen> {
  late Future<List<QuestProgress>> _quests;

  @override
  void initState() {
    super.initState();
    _quests = QuestTracker.computeAll();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Scaffold(
      body: SoriScreenBackground(
        child: SafeArea(
          child: Column(
            children: [
              SoriContentClamp(
                maxWidth: 960,
                base: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                builder: (context, padding) => Padding(
                  padding: padding,
                  child: SoriStageRootHeader(
                    eyebrow: t.soriStageNavHanok,
                    title: t.soriStageHanokTitle,
                    body: t.soriStageHanokBody,
                  ),
                ),
              ),
              const Expanded(child: HanokWorldScreen(embedded: true)),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: _ShortcutTiles(quests: _quests),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 한옥 탭 하단의 세 갈래 — 퀘스트 · 도장첩 · 보자기.
///
/// 예전엔 `SoriButton.ghost` 세 개(투명·무테두리·텍스트만)라 정작 번들에 있는
/// 장식·도장·보자기 그림이 이 표면에서 하나도 쓰이지 않았다. 각각이 무엇을
/// 모으는 곳인지 **그림으로** 말하고, 얼마나 모았는지 숫자로 붙인다.
class _ShortcutTiles extends StatelessWidget {
  const _ShortcutTiles({required this.quests});

  final Future<List<QuestProgress>> quests;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    // 도장·보자기는 동기 읽기지만 퀘스트 합계는 비동기 계산이라, 카운트가
    // 늦게 와도 타일 자체는 즉시 뜬다(폴백 우선 배포 — 숫자는 나중에).
    final Set<String> earned = Storage.earnedStamps.toSet();
    final int stamps = DancheongMotif.values
        .where((m) => earned.contains(m.name))
        .length;
    final int bojagi = DecorationRewardService.openableBoxCount();

    return Row(
      children: [
        Expanded(
          child: FutureBuilder<List<QuestProgress>>(
            future: quests,
            builder: (context, snap) {
              final list = snap.data;
              // 총계는 상수 14 가 아니다 — 시즌 윈도우가 열리면 활성
              // 퀘스트가 늘어난다. quests_screen 의 요약과 같은 계산을 쓴다.
              final String? count = list == null
                  ? null
                  : '${list.where((q) => q.completed).length}'
                        ' / '
                        '${list.where((q) => q.active || q.completed).length}';
              return _ShortcutTile(
                thumb: const SoriRewardThumb(
                  slug: 'decoration_jangdokdae',
                  earned: true,
                  size: 40,
                ),
                label: t.soriStageQuests,
                count: count,
                route: '/quests',
              );
            },
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: _ShortcutTile(
            thumb: Image.asset(
              'assets/illustrations/stamps/stamp_lotus.png',
              width: 40,
              height: 40,
              errorBuilder: (_, _, _) => const Icon(
                Icons.approval_rounded,
                size: 32,
                color: SoriColors.accent,
              ),
            ),
            label: t.soriStageDojang,
            count: '$stamps / ${DancheongMotif.values.length}',
            route: '/dojangcheop',
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: _ShortcutTile(
            thumb: Image.asset(
              kBojagiClosed,
              width: 40,
              height: 40,
              errorBuilder: (_, _, _) => const Icon(
                Icons.redeem_rounded,
                size: 32,
                color: SoriColors.gold,
              ),
            ),
            label: t.soriStageBojagi,
            count: '$bojagi',
            route: '/bojagi',
          ),
        ),
      ],
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.thumb,
    required this.label,
    required this.count,
    required this.route,
  });

  final Widget thumb;
  final String label;

  /// null 이면 카운트 줄을 생략한다 (아직 계산 중).
  final String? count;
  final String route;

  @override
  Widget build(BuildContext context) {
    final tt = SoriTextTheme.of(context);
    final s = SoriSurfaces.of(context);
    final String? count = this.count;
    return Semantics(
      button: true,
      label: count == null ? label : '$label, $count',
      child: ExcludeSemantics(
        child: SoriCard(
          variant: SoriCardVariant.compact,
          onTap: () => Navigator.of(context).pushNamed(route),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 40, child: thumb),
              const SizedBox(height: Spacing.xs),
              Text(
                label,
                style: tt.cardTitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (count != null)
                Text(
                  count,
                  style: tt.caption.copyWith(color: s.textMuted),
                  maxLines: 1,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
