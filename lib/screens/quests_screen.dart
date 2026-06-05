import 'package:flutter/material.dart';

import '../data/quest_catalog.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/quest.dart';
import '../services/quest_tracker.dart';
import '../services/storage_service.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/celebration.dart';
import '../widgets/sori/decoration_layer.dart' show kAvailableDecorations;
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/tokens.dart';

/// Phase 4 (stately-rising-jongga) — 특별 퀘스트 진행 화면.
///
/// 표시 그룹:
///   1. **In-Progress** — 진행 중 (cur > 0, !completed)
///   2. **Available** — 아직 0 (cur == 0, !completed)
///   3. **Completed** — 클리어 (Storage.questCompletions 기반)
///   4. **Seasonal Locked** — 시즌 윈도우 밖 (active == false, !completed)
class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> {
  bool _loading = true;
  String? _error;
  List<QuestProgress> _quests = [];

  @override
  void initState() {
    super.initState();
    _load();
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

      final list = await QuestTracker.computeAll();
      await QuestTracker.persistNewCompletions(list);
      if (!mounted) return;

      // 새로 완료된 퀘스트 감지
      final newlyCompleted = <QuestProgress>[];
      for (final quest in list) {
        if (quest.completed &&
            !prevCompletions.containsKey(quest.questId)) {
          newlyCompleted.add(quest);
        }
      }

      setState(() {
        _quests = list;
        _loading = false;
      });

      // 새로 완료된 퀘스트마다 축하 연출
      for (final quest in newlyCompleted) {
        if (mounted) {
          await _showQuestCompletionCelebration(quest);
          await Future.delayed(const Duration(milliseconds: 600));
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _showQuestCompletionCelebration(
    QuestProgress quest,
  ) async {
    if (!mounted) return;

    final def = kQuestById[quest.questId];
    if (def == null) return;

    final lang = Localizations.localeOf(context).languageCode;
    final isEn = lang == 'en';
    final questName = isEn ? def.name.en : def.name.de;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _QuestCompletionCelebration(
        questName: questName,
        decorationSlug: def.decorationSlug,
        quest: quest,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(t.questsTitle)),
        body: const AppLoading(),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.questsTitle)),
        body: AppError(message: _error!, onRetry: _load),
      );
    }

    final inProgress = _quests
        .where((q) =>
            q.active && !q.completed && q.current > 0)
        .toList();
    final available = _quests
        .where((q) => q.active && !q.completed && q.current == 0)
        .toList();
    final completed = _quests.where((q) => q.completed).toList();
    final seasonalLocked = _quests
        .where((q) => !q.active && !q.completed)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.questsTitle,
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: SoriColors.primary,
          child: ListView(
            padding: soriClampPadding(
              MediaQuery.sizeOf(context).width,
              base: const EdgeInsets.fromLTRB(12, 4, 12, 32),
            ),
            children: [
              const HanokHeader(
                asset: 'assets/illustrations/hanok/achievements.png',
                fallbackIcon: Icons.workspace_premium_outlined,
              ),
              const SizedBox(height: Spacing.md),
              // 전체 진행 요약 — 완료/전체 + 진행바 (한눈에 보기).
              if (_quests.isNotEmpty) ...[
                _QuestSummary(quests: _quests),
                const SizedBox(height: Spacing.md),
              ],
              if (inProgress.isEmpty &&
                  available.isEmpty &&
                  completed.isEmpty &&
                  seasonalLocked.isEmpty)
                SoriEmptyState(
                  icon: Icons.local_florist_outlined,
                  title: t.questsEmptyTitle,
                  body: t.questsEmptyBody,
                ),
              if (inProgress.isNotEmpty) ...[
                _SectionHeader(label: t.questsSectionInProgress),
                ...inProgress.map((q) => _QuestTile(q: q)),
                const SizedBox(height: Spacing.lg),
              ],
              if (available.isNotEmpty) ...[
                _SectionHeader(label: t.questsSectionAvailable),
                ...available.map((q) => _QuestTile(q: q)),
                const SizedBox(height: Spacing.lg),
              ],
              if (completed.isNotEmpty) ...[
                _SectionHeader(label: t.questsSectionCompleted),
                ...completed.map((q) => _QuestTile(q: q)),
                const SizedBox(height: Spacing.lg),
              ],
              if (seasonalLocked.isNotEmpty) ...[
                _SectionHeader(label: t.questsSectionSeasonalLocked),
                ...seasonalLocked.map((q) => _QuestTile(q: q)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, Spacing.md, 4, Spacing.sm),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _QuestTile extends StatelessWidget {
  final QuestProgress q;
  const _QuestTile({required this.q});

  @override
  Widget build(BuildContext context) {
    final def = kQuestById[q.questId];
    if (def == null) return const SizedBox.shrink();
    final s = SoriSurfaces.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final isEn = lang == 'en';
    final name = isEn ? def.name.en : def.name.de;
    final desc = isEn ? def.description.en : def.description.de;

    final isCompleted = q.completed;
    final isLocked = !q.active && !isCompleted;
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
                child: Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: isLocked ? s.textDim : s.text,
                  ),
                ),
              ),
              if (def.type == QuestType.seasonal)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: SoriColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(SoriRadius.pill),
                  ),
                  child: Text(
                    AppL10n.of(context).questsSeasonalBadge,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: SoriColors.warning,
                    ),
                  ),
                ),
              const SizedBox(width: Spacing.sm),
              // 보상 미리보기 — 이 퀘스트로 언락되는 마당 장식.
              _RewardThumb(slug: def.decorationSlug, earned: isCompleted),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: TextStyle(fontSize: 12, color: s.textMuted),
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
              style: TextStyle(
                fontSize: 11,
                color: s.textMuted,
                fontWeight: FontWeight.w600,
              ),
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
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: SoriColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(SoriRadius.md),
        border: Border.all(color: SoriColors.success.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded,
                  color: SoriColors.gold, size: 22),
              const SizedBox(width: Spacing.sm),
              Text('$done / $total',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: SoriColors.success)),
              const SizedBox(width: Spacing.sm),
              Text(t.questsSectionCompleted,
                  style: TextStyle(
                      fontSize: 12,
                      color: s.textMuted,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              if (inProgress > 0)
                Row(
                  children: [
                    Icon(Icons.local_florist_outlined,
                        size: 14, color: SoriColors.info),
                    const SizedBox(width: 3),
                    Text('$inProgress',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: SoriColors.info)),
                  ],
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

/// Belohnungs-Vorschau — die Hof-Dekoration, die diese Quest freischaltet.
/// Nicht freigeschaltet → gedimmt. Fehlendes PNG → Geschenk-Icon.
class _RewardThumb extends StatelessWidget {
  final String slug;
  final bool earned;
  const _RewardThumb({required this.slug, required this.earned});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final giftIcon = Icon(
      Icons.card_giftcard_rounded,
      size: 22,
      color: earned ? SoriColors.success : s.textDim,
    );
    return Opacity(
      opacity: earned ? 1.0 : 0.4,
      child: SizedBox(
        width: 34,
        height: 34,
        // 자산이 없는 슬러그는 로드 시도 없이 선물 아이콘 (웹 404 방지).
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

/// 퀘스트 완료 축하 다이얼로그 — 3단 시퀀스.
/// (1) 까치 박수 (2) 마당 장식 이미지 + 반짝임 (3) 자동 닫기
class _QuestCompletionCelebration extends StatefulWidget {
  final String questName;
  final String decorationSlug;
  final QuestProgress quest;

  const _QuestCompletionCelebration({
    required this.questName,
    required this.decorationSlug,
    required this.quest,
  });

  @override
  State<_QuestCompletionCelebration> createState() =>
      _QuestCompletionCelebrationState();
}

class _QuestCompletionCelebrationState
    extends State<_QuestCompletionCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int _phase = 0; // 0=마스코트, 1=장식 + 반짝임, 2=끝

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

    // Phase 3: 자동 닫기
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final giftIcon = Icon(
      Icons.card_giftcard_rounded,
      size: 48,
      color: SoriColors.success,
    );

    return Dialog(
      backgroundColor: s.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SoriRadius.lg),
      ),
      child: Container(
        padding: const EdgeInsets.all(Spacing.lg),
        constraints: const BoxConstraints(maxWidth: 300),
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
                        child: kAvailableDecorations
                                .contains(widget.decorationSlug)
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
              AppL10n.of(context).questsCompletionCelebration,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: s.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
