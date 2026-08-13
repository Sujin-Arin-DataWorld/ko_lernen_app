import 'package:flutter/material.dart';

import '../../data/quest_catalog.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/quest.dart';
import '../../models/sori_stage_progression.dart';
import '../../services/pack_access.dart';
import '../../services/sori_stage_progression_service.dart';
import '../../services/sori_stage_reward_receipt_service.dart';
import '../../services/today_learning_navigation.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/screen_background.dart';
import '../../widgets/sori/tokens.dart';
import 'sori_stage_common.dart';
import 'sori_stage_reward_receipt_sheet.dart';

class SoriStageTodayScreen extends StatefulWidget {
  const SoriStageTodayScreen({super.key, this.loadSnapshot});

  final Future<SoriStageProgressionSnapshot> Function()? loadSnapshot;

  @override
  State<SoriStageTodayScreen> createState() => _SoriStageTodayScreenState();
}

class _SoriStageTodayScreenState extends State<SoriStageTodayScreen> {
  late Future<SoriStageProgressionSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = (widget.loadSnapshot ?? SoriStageProgressionService.load)();
  }

  void _reload() => setState(() {
    _future = (widget.loadSnapshot ?? SoriStageProgressionService.load)();
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SoriScreenBackground(
      child: SafeArea(
        child: Column(
          children: [
            SoriContentClamp(
              maxWidth: 880,
              base: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              builder: (context, padding) => Padding(
                padding: padding,
                child: SoriStageRootHeader(
                  eyebrow: AppL10n.of(context).soriStageTodayEyebrow,
                  title: AppL10n.of(context).soriStageTodayTitle,
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<SoriStageProgressionSnapshot>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AppLoading();
                  }
                  if (!snapshot.hasData) {
                    return _TodayError(onRetry: _reload);
                  }
                  return _TodayContent(
                    snapshot: snapshot.requireData,
                    onRefresh: _reload,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TodayContent extends StatelessWidget {
  const _TodayContent({required this.snapshot, required this.onRefresh});
  final SoriStageProgressionSnapshot snapshot;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return SoriContentClamp(
      maxWidth: 880,
      base: const EdgeInsets.fromLTRB(20, 20, 20, 48),
      builder: (context, padding) => RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding,
          children: [
            _TodayMissionStage(
              snapshot: snapshot,
              onActivityReturned: onRefresh,
            ),
            if (snapshot.pendingBojagiCount > 0) ...[
              const SizedBox(height: Spacing.lg),
              _PendingBojagi(count: snapshot.pendingBojagiCount),
            ],
            const SizedBox(height: Spacing.xl),
            _HanokProgress(snapshot: snapshot),
            if (snapshot.closestQuests.isNotEmpty) ...[
              const SizedBox(height: Spacing.xl),
              Text(
                t.soriStageClosestQuests,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              for (final quest in snapshot.closestQuests)
                _QuestProgressRow(progress: quest),
            ],
          ],
        ),
      ),
    );
  }
}

class _TodayMissionStage extends StatelessWidget {
  const _TodayMissionStage({
    required this.snapshot,
    required this.onActivityReturned,
  });
  final SoriStageProgressionSnapshot snapshot;
  final VoidCallback onActivityReturned;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final destination = snapshot.today.destination;
    final contract = snapshot.todayReward;
    final rewardText =
        contract?.items
            .map((item) => localCopy(context, item.label))
            .join(' · ') ??
        '';
    return Container(
      padding: const EdgeInsets.all(Spacing.xl),
      decoration: BoxDecoration(
        color: SoriActivityColors.hanokStage,
        borderRadius: BorderRadius.circular(SoriRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'SORI STAGE',
            style: TextStyle(
              color: SoriColors.gold,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            destination == null
                ? t.soriStageTodayEmpty
                : t.soriStageMissionAction,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              height: 1.12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (rewardText.isNotEmpty) ...[
            const SizedBox(height: Spacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.roofing_rounded, color: SoriColors.gold),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    '${t.soriStagePossibleReward}: $rewardText',
                    style: const TextStyle(
                      color: SoriActivityColors.onHanokStage,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: Spacing.xl),
          SoriButton(
            label: t.soriStageMissionAction,
            onTap: () async {
              final activityId =
                  contract?.activityId ?? destination?.route ?? 'today';
              final receipt = await SoriStageRewardReceiptService.capture(
                activityId: activityId,
                loadSnapshot: SoriStageProgressionService.load,
                openActivity: () async {
                  if (destination == null) {
                    await Navigator.of(context).pushNamed('/path');
                    return;
                  }
                  await TodayLearningNavigation.open(
                    destination,
                    ensurePackAccess: (level) =>
                        ensurePackAccess(context, level: level),
                    openRoute: (route, arguments) async {
                      await Navigator.of(
                        context,
                      ).pushNamed(route, arguments: arguments);
                    },
                  );
                },
              );
              if (!context.mounted) return;
              onActivityReturned();
              if (receipt != null) {
                await showSoriStageRewardReceipt(context, receipt);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _PendingBojagi extends StatelessWidget {
  const _PendingBojagi({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed('/bojagi'),
      borderRadius: BorderRadius.circular(SoriRadius.md),
      child: Container(
        constraints: const BoxConstraints(minHeight: 88),
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          color: SoriColors.gold.withValues(alpha: .18),
          border: Border.all(color: SoriColors.gold),
          borderRadius: BorderRadius.circular(SoriRadius.md),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.redeem_rounded,
              size: 36,
              color: SoriColors.goldOnLight,
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${t.soriStageBojagiTitle} · $count',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(t.soriStageBojagiBody),
                ],
              ),
            ),
            Text(
              t.soriStageOpenBojagi,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _HanokProgress extends StatelessWidget {
  const _HanokProgress({required this.snapshot});
  final SoriStageProgressionSnapshot snapshot;
  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final built = snapshot.hanok.unlocked.length;
    const total = 7;
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed('/hanok'),
      borderRadius: BorderRadius.circular(SoriRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(Spacing.xl),
        decoration: BoxDecoration(
          color: SoriColors.primarySoft,
          borderRadius: BorderRadius.circular(SoriRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.home_work_outlined,
                  size: 34,
                  color: SoriColors.primaryDark,
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Text(
                    t.soriStageHanokNow,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '$built / $total',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            LinearProgressIndicator(
              value: snapshot.hanok.constructionFraction,
              minHeight: 12,
              borderRadius: BorderRadius.circular(12),
              color: SoriColors.primaryDark,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              '${t.soriStageNextPiece}: ${snapshot.hanok.structureStage.name}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestProgressRow extends StatelessWidget {
  const _QuestProgressRow({required this.progress});
  final QuestProgress progress;
  @override
  Widget build(BuildContext context) {
    final definition = kQuestCatalog.firstWhere(
      (quest) => quest.id == progress.questId,
    );
    final language = Localizations.localeOf(context).languageCode;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minVerticalPadding: Spacing.sm,
      title: Text(
        language == 'de' ? definition.name.de : definition.name.en,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: LinearProgressIndicator(
          value: progress.fraction,
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      trailing: Text(
        '${progress.current} / ${progress.target}',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      onTap: () => Navigator.of(context).pushNamed('/quests'),
    );
  }
}

class _TodayError extends StatelessWidget {
  const _TodayError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: Spacing.md),
          Text(
            AppL10n.of(context).soriStageTodayEmpty,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.lg),
          SoriButton.outlined(label: 'Retry', onTap: onRetry),
        ],
      ),
    ),
  );
}
