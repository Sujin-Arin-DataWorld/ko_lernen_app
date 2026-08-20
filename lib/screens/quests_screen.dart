import 'package:flutter/material.dart';

import '../data/quest_catalog.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/content_feedback.dart';
import '../models/feedback_completion.dart';
import '../models/quest.dart';
import '../services/quest_tracker.dart';
import '../services/quest_action_resolver.dart';
import '../services/storage_service.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/celebration.dart';
import '../widgets/sori/content_feedback_card.dart';
import '../widgets/sori/dialog.dart';
import '../widgets/sori/cultural_help.dart';
import '../widgets/sori/decoration_layer.dart' show kAvailableDecorations;
import '../widgets/sori/reward_thumb.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/section_header.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/window_class.dart';

/// Phase 4 (stately-rising-jongga) — 특별 퀘스트 진행 화면.
///
/// 표시 그룹:
///   1. **In-Progress** — 진행 중 (cur > 0, !completed)
///   2. **Available** — 아직 0 (cur == 0, !completed)
///   3. **Completed** — 클리어 (Storage.questCompletions 기반)
///   4. **Seasonal Locked** — 시즌 윈도우 밖 (active == false, !completed)
class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key, this.loadQuests, this.persistNewCompletions});

  final Future<List<QuestProgress>> Function()? loadQuests;
  final Future<void> Function(List<QuestProgress>)? persistNewCompletions;

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen>
    with ScreenCoachMixin<QuestsScreen> {
  bool _loading = true;
  String? _error;
  List<QuestProgress> _quests = [];

  // ── 코치마크 타겟 ──
  final GlobalKey _summaryKey = GlobalKey();

  @override
  String get coachId => 'quests';

  // 퀘스트 로드 완료 후에만 발화 (요약 카드가 퀘스트 데이터 필요).
  @override
  bool get coachReady => !_loading && _quests.isNotEmpty;

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _summaryKey,
        title: t.coachQuestsTitle,
        body: t.coachQuestsBody,
        icon: Icons.emoji_events_rounded,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _load();
    scheduleCoach();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // 로드 전 기존 완료 퀘스트 기록
      final prevCompletions = Map<String, String>.from(
        Storage.questCompletions,
      );

      final list = await (widget.loadQuests ?? QuestTracker.computeAll)();
      await (widget.persistNewCompletions ??
          QuestTracker.persistNewCompletions)(list);
      if (!mounted) return;

      // 새로 완료된 퀘스트 감지
      final newlyCompleted = <QuestProgress>[];
      for (final quest in list) {
        if (quest.completed && !prevCompletions.containsKey(quest.questId)) {
          newlyCompleted.add(quest);
        }
      }

      setState(() {
        _quests = list;
        _loading = false;
      });

      // 새로 완료된 퀘스트마다 축하 연출.
      // 사용자가 "선물 열기"를 누르면 곧장 보자기 화면으로 넘기고 나머지 축하는
      // 멈춘다 — 상자 위에 다음 축하 다이얼로그가 겹치지 않게.
      for (final quest in newlyCompleted) {
        if (!mounted) {
          break;
        }
        final openGift = await _showQuestCompletionCelebration(quest);
        if (openGift) {
          if (!mounted) {
            break;
          }
          await Navigator.of(context).pushNamed('/bojagi');
          if (mounted) {
            await _load();
          }
          break;
        }
        await Future.delayed(const Duration(milliseconds: 600));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppL10n.of(context).loadErrorTryAgain;
      });
    }
  }

  Future<bool> _showQuestCompletionCelebration(QuestProgress quest) async {
    if (!mounted) return false;

    final def = kQuestById[quest.questId];
    if (def == null) return false;

    final lang = Localizations.localeOf(context).languageCode;
    final isEn = lang == 'en';
    final questName = isEn ? def.name.en : def.name.de;
    final feedbackContext = FeedbackCompletion.questReward(
      questId: def.id,
      questType: def.type.name,
      target: def.target,
    ).context;

    final openGift = await showSoriDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _QuestCompletionCelebration(
        questName: questName,
        decorationSlug: def.decorationSlug,
        quest: quest,
        feedbackContext: feedbackContext,
      ),
    );
    return openGift ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    if (_loading) {
      return SoriStandardFrame(
        appBarTitle: t.questsTitle,
        builder: (context, padding) => const AppLoading(),
      );
    }
    if (_error != null) {
      return SoriStandardFrame(
        appBarTitle: t.questsTitle,
        builder: (context, padding) =>
            AppError(message: _error!, onRetry: _load),
      );
    }

    final inProgress = _quests
        .where((q) => q.active && !q.completed && q.current > 0)
        .toList();
    final available = _quests
        .where((q) => q.active && !q.completed && q.current == 0)
        .toList();
    final completed = _quests.where((q) => q.completed).toList();
    final seasonalLocked = _quests
        .where((q) => !q.active && !q.completed)
        .toList();

    return SoriStandardFrame(
      appBarTitle: t.questsTitle,
      maxWidth: SoriMaxWidth.hub,
      particles: true,
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.xs,
        Spacing.lg,
        Spacing.xxl,
      ),
      builder: (context, padding) => CulturalGlossaryBuilder(
        builder: (context, glossary) {
          final shownTermIds = <String>{};
          bool showCulturalHelp(QuestProgress quest) {
            final slug = kQuestById[quest.questId]?.decorationSlug;
            final termId = slug == null
                ? null
                : glossary?.termIdForDecoration(slug);
            return termId != null && shownTermIds.add(termId);
          }

          return RefreshIndicator(
            onRefresh: _load,
            color: SoriColors.primary,
            child: ListView(
              padding: padding,
              children: [
                const HanokHeader(
                  asset: 'assets/illustrations/hanok/achievements.png',
                  fallbackIcon: Icons.workspace_premium_outlined,
                ),
                const SizedBox(height: Spacing.md),
                // 전체 진행 요약 — 완료/전체 + 진행바 (한눈에 보기).
                if (_quests.isNotEmpty) ...[
                  KeyedSubtree(
                    key: _summaryKey,
                    child: _QuestSummary(quests: _quests),
                  ),
                  const SizedBox(height: Spacing.md),
                ],
                if (inProgress.isEmpty &&
                    available.isEmpty &&
                    completed.isEmpty &&
                    seasonalLocked.isEmpty)
                  SoriEmptyState(
                    asset: 'assets/illustrations/mascot/magpie_encourage.png',
                    icon: Icons.local_florist_outlined,
                    title: t.questsEmptyTitle,
                    body: t.questsEmptyBody,
                  ),
                if (inProgress.isNotEmpty) ...[
                  SoriSectionHeader(t.questsSectionInProgress),
                  ...inProgress.map(
                    (q) =>
                        _QuestTile(q: q, showCulturalHelp: showCulturalHelp(q)),
                  ),
                  const SizedBox(height: Spacing.lg),
                ],
                if (available.isNotEmpty) ...[
                  SoriSectionHeader(t.questsSectionAvailable),
                  ...available.map(
                    (q) =>
                        _QuestTile(q: q, showCulturalHelp: showCulturalHelp(q)),
                  ),
                  const SizedBox(height: Spacing.lg),
                ],
                if (completed.isNotEmpty) ...[
                  SoriSectionHeader(t.questsSectionCompleted),
                  ...completed.map(
                    (q) =>
                        _QuestTile(q: q, showCulturalHelp: showCulturalHelp(q)),
                  ),
                  const SizedBox(height: Spacing.lg),
                ],
                if (seasonalLocked.isNotEmpty) ...[
                  SoriSectionHeader(t.questsSectionSeasonalLocked),
                  ...seasonalLocked.map(
                    (q) =>
                        _QuestTile(q: q, showCulturalHelp: showCulturalHelp(q)),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QuestTile extends StatelessWidget {
  final QuestProgress q;
  final bool showCulturalHelp;
  const _QuestTile({required this.q, required this.showCulturalHelp});

  @override
  Widget build(BuildContext context) {
    final def = kQuestById[q.questId];
    if (def == null) return const SizedBox.shrink();
    final s = SoriSurfaces.of(context);
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final isEn = lang == 'en';
    final name = isEn ? def.name.en : def.name.de;
    final desc = isEn ? def.description.en : def.description.de;

    final isCompleted = q.completed;
    final isLocked = !q.active && !isCompleted;
    final action = QuestActionResolver.resolve(def.id, now: DateTime.now());
    final actionLabel = action.labelKey == QuestActionLabelKey.seasonOpens
        ? t.questSeasonOpens(
            QuestActionResolver.dateLabel(action.seasonOpensAt!),
          )
        : t.questActionLabel(action.labelKey.name);
    final accentColor = isCompleted
        ? SoriColors.success
        : (isLocked ? s.textDim : SoriColors.info);

    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: isCompleted
            ? SoriColors.success.withValues(alpha: 0.08)
            : s.surface,
        borderRadius: BorderRadius.circular(SoriRadius.md),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.30),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isCompleted
                    ? Icons.check_circle
                    : (isLocked
                          ? Icons.lock_outline_rounded
                          : Icons.local_florist_outlined),
                size: 18,
                color: accentColor,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: SoriTextTheme.of(context).cardTitle.copyWith(
                        color: isLocked ? s.textDim : s.text,
                      ),
                    ),
                    if (def.type == QuestType.seasonal) ...[
                      const SizedBox(height: Spacing.xs),
                      Text(
                        AppL10n.of(context).questsSeasonalBadge,
                        style: SoriTextTheme.of(
                          context,
                        ).meta.copyWith(color: SoriColors.warning),
                      ),
                    ],
                  ],
                ),
              ),
              if (showCulturalHelp)
                CulturalDecorationHelpButton(
                  decorationSlug: def.decorationSlug,
                ),
              const SizedBox(width: Spacing.sm),
              // 보상 미리보기 — 이 퀘스트로 언락되는 마당 장식.
              SoriRewardThumb(
                slug: def.decorationSlug,
                earned: isCompleted,
                semantic: '',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: SoriTextTheme.of(
              context,
            ).bodySmall.copyWith(color: s.textMuted),
          ),
          if (!isCompleted) ...[
            const SizedBox(height: Spacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: q.fraction,
                minHeight: 6,
                backgroundColor: s.text.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation(accentColor),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${q.current} / ${q.target}  ·  ${(q.fraction * 100).round()}%',
              style: SoriTextTheme.of(
                context,
              ).meta.copyWith(color: s.textMuted),
            ),
            const SizedBox(height: Spacing.sm),
            if (action.route != null)
              Align(
                alignment: Alignment.centerRight,
                child: SoriButton.ghost(
                  label: actionLabel,
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamed(action.route!, arguments: action.arguments),
                ),
              )
            else
              Row(
                children: [
                  const Icon(Icons.calendar_month_outlined, size: 18),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      actionLabel,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

/// Gesamtfortschritt aller Quests — abgeschlossen / erreichbar + Balken.
class _QuestSummary extends StatelessWidget {
  final List<QuestProgress> quests;
  const _QuestSummary({required this.quests});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final done = quests.where((q) => q.completed).length;
    final total = quests.where((q) => q.active || q.completed).length;
    final inProgress = quests
        .where((q) => q.active && !q.completed && q.current > 0)
        .length;
    final frac = total == 0 ? 0.0 : done / total;
    return SoriCard(
      accent: SoriColors.success,
      tinted: true,
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: SoriColors.gold,
                size: 22,
              ),
              Text(
                '$done / $total',
                style: SoriTextTheme.of(
                  context,
                ).numeral.copyWith(color: SoriColors.success),
              ),
              Text(
                t.questsSectionCompleted,
                style: SoriTextTheme.of(
                  context,
                ).bodySmall.copyWith(color: s.textMuted),
              ),
              if (inProgress > 0)
                Semantics(
                  label: '$inProgress',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_florist_outlined,
                        size: 14,
                        color: SoriColors.info,
                      ),
                      const SizedBox(width: Spacing.xs),
                      Text(
                        '$inProgress',
                        style: SoriTextTheme.of(
                          context,
                        ).label.copyWith(color: SoriColors.info),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: frac,
              minHeight: 8,
              backgroundColor: s.text.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation(SoriColors.success),
            ),
          ),
        ],
      ),
    );
  }
}

/// 퀘스트 완료 축하 다이얼로그 — 3단 시퀀스.
/// (1) 까치 박수 (2) 마당 장식 이미지 + 반짝임 (3) 선택형 Pulse + Continue
class _QuestCompletionCelebration extends StatefulWidget {
  final String questName;
  final String decorationSlug;
  final QuestProgress quest;
  final ContentFeedbackContext feedbackContext;

  const _QuestCompletionCelebration({
    required this.questName,
    required this.decorationSlug,
    required this.quest,
    required this.feedbackContext,
  });

  @override
  State<_QuestCompletionCelebration> createState() =>
      _QuestCompletionCelebrationState();
}

class _QuestCompletionCelebrationState
    extends State<_QuestCompletionCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int _phase = 0; // 0=마스코트, 1=장식 + 반짝임, 2=Pulse + Continue

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
    _playSequence();
  }

  Future<void> _playSequence() async {
    if (!mounted) return;
    // Phase 1: 까치 박수 (1.2s)
    setState(() => _phase = 0);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    // Phase 2: 장식 + 반짝임 (1.5s)
    setState(() => _phase = 1);
    SoriCelebration.burst(context);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    // Phase 3: 선택형 Pulse를 읽은 뒤 사용자가 Continue로 닫는다.
    setState(() => _phase = 2);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final t = AppL10n.of(context);
    final feedbackScope = ContentFeedbackControllerScope.maybeOf(context);
    final giftIcon = Icon(
      Icons.card_giftcard_rounded,
      size: 48,
      color: SoriColors.success,
    );

    return SoriDialogFrame(
      backgroundColor: s.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SoriRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 340,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Phase 1: 마스코트 박수
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _phase == 0
                    ? SizedBox(
                        height: 100,
                        key: const ValueKey(0),
                        child: Center(
                          child: Mascot(
                            kind: MascotKind.magpie,
                            emotion: MascotEmotion.celebrate,
                            size: 80,
                            animate: true,
                          ),
                        ),
                      )
                    : SizedBox(
                        height: 100,
                        key: const ValueKey(1),
                        child: Center(
                          child:
                              kAvailableDecorations.contains(
                                widget.decorationSlug,
                              )
                              ? Image.asset(
                                  'assets/illustrations/decorations/${widget.decorationSlug}.png',
                                  fit: BoxFit.contain,
                                  width: 80,
                                  errorBuilder: (_, __, ___) => giftIcon,
                                )
                              : giftIcon,
                        ),
                      ),
              ),
              const SizedBox(height: Spacing.md),
              Text(
                widget.questName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                t.questsCompletionCelebration,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: s.textMuted),
              ),
              if (_phase >= 2) ...[
                if (feedbackScope != null &&
                    feedbackScope.featureGate.isEnabled) ...[
                  const SizedBox(height: Spacing.lg),
                  ContentFeedbackCard(
                    feedbackContext: widget.feedbackContext,
                    featureGate: feedbackScope.featureGate,
                    submitFeedback: feedbackScope.submitFeedback,
                  ),
                ],
                const SizedBox(height: Spacing.lg),
                SoriButton.filled(
                  key: const Key('quest-completion-open-gift'),
                  label: t.questsOpenGiftCta,
                  fullWidth: true,
                  onTap: () => Navigator.of(context).pop(true),
                ),
                const SizedBox(height: Spacing.sm),
                SoriButton.outlined(
                  key: const Key('quest-completion-continue'),
                  label: t.feedbackCompletionContinue,
                  fullWidth: true,
                  onTap: () => Navigator.of(context).pop(false),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
