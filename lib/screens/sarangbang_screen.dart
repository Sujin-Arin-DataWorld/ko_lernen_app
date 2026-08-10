import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/personal_room.dart';
import '../services/decoration_reward_service.dart';
import '../services/mission_recommender.dart';
import '../services/pack_access.dart';
import '../services/quest_tracker.dart';
import '../services/room_placement_service.dart';
import '../services/storage_service.dart';
import '../services/today_learning_navigation.dart';
import '../services/today_learning_snapshot.dart';
import '../services/vocab_pack_service.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/mission_hero_card.dart';
import '../widgets/sori/pending_reward_card.dart';
import '../widgets/sori/personal_room_scene.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/tokens.dart';

/// The study-facing Sarangbang. It presents the one recommendation selected
/// by the existing engine, then launches the exact original learning surface.
///
/// Decorating remains intentionally separate at `/sarangbang/furnish` so a
/// learner never has to enter a placement UI before studying.
class SarangbangStudyScreen extends StatefulWidget {
  final Future<TodayLearningSnapshot> Function()? loadTodaySnapshot;
  final Future<void> Function(TodayLearningSnapshot recommendation)?
  onOpenRecommendation;

  const SarangbangStudyScreen({
    super.key,
    this.loadTodaySnapshot,
    this.onOpenRecommendation,
  });

  @override
  State<SarangbangStudyScreen> createState() => _SarangbangStudyScreenState();
}

class _SarangbangStudyScreenState extends State<SarangbangStudyScreen> {
  TodayLearningSnapshot? _snapshot;
  RoomPlacements _placements = const {};
  Set<String> _ownedDecor = const {};
  int _openableBoxes = 0; // 지금 열 수 있는 보자기 — 사랑방 발견 배너 게이트
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  ({RoomPlacements placements, Set<String> owned}) _readRoomSnapshot() {
    try {
      return (
        placements: RoomPlacementService.sanitizeAll(Storage.roomPlacements),
        owned: Storage.ownedDecor.toSet(),
      );
    } catch (_) {
      return (placements: const {}, owned: const {});
    }
  }

  void _reloadRoomScene() {
    final room = _readRoomSnapshot();
    if (!mounted) {
      return;
    }
    setState(() {
      _placements = room.placements;
      _ownedDecor = room.owned;
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final load = widget.loadTodaySnapshot ?? TodayLearningSnapshotLoader.load;
      final snapshot = await load();
      final room = _readRoomSnapshot();
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = snapshot;
        _placements = room.placements;
        _ownedDecor = room.owned;
        _openableBoxes = DecorationRewardService.openableBoxCount();
        _loading = false;
      });
      // 방금 학습 루트가 돌아왔다 — 그새 획득한 보자기를 생산한다(퀘스트 화면
      // 안 열어도). 렌더를 막지 않도록 fire-and-forget(best-effort 라 자체 오류를
      // 삼킨다). 동기화가 끝나면 새로 생긴 보자기가 배너에 바로 뜨도록 개수만 다시
      // 읽는다.
      // ignore: discarded_futures
      QuestTracker.syncEarnedRewards().then((_) {
        if (!mounted) {
          return;
        }
        final boxes = DecorationRewardService.openableBoxCount();
        if (boxes != _openableBoxes) {
          setState(() => _openableBoxes = boxes);
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _openRecommendation() async {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return;
    }
    final override = widget.onOpenRecommendation;
    if (override != null) {
      await override(snapshot);
      return;
    }

    if (!mounted) {
      return;
    }
    final opened = await TodayLearningNavigation.open(
      snapshot.destination,
      ensurePackAccess: (level) => ensurePackAccess(context, level: level),
      openRoute: (route, arguments) async {
        await Navigator.of(context).pushNamed(route, arguments: arguments);
      },
    );
    if (opened && mounted) {
      await _load();
    }
  }

  Future<void> _openFurnish() async {
    await Navigator.of(context).pushNamed('/sarangbang/furnish');
    if (mounted) {
      _reloadRoomScene();
    }
  }

  Future<void> _openBojagi() async {
    await Navigator.of(context).pushNamed('/bojagi');
    if (!mounted) {
      return;
    }
    // 보자기를 열고 돌아왔다 — 방 장식과 남은 상자 수를 다시 읽는다.
    final room = _readRoomSnapshot();
    setState(() {
      _placements = room.placements;
      _ownedDecor = room.owned;
      _openableBoxes = DecorationRewardService.openableBoxCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        title: Text(t.sarangbangStudyTitle),
        actions: [
          IconButton(
            tooltip: t.hanokWorldTitle,
            icon: const Icon(Icons.account_balance_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/hanok'),
          ),
          IconButton(
            tooltip: t.sarangbangStudyFurnish,
            icon: const Icon(Icons.chair_outlined),
            onPressed: _openFurnish,
          ),
        ],
      ),
      body: SoriScreenBackground(
        child: SafeArea(
          child: _loading
              ? const AppLoading()
              : _loadFailed
              ? AppError(message: t.courseMissionLoadError, onRetry: _load)
              : SoriContentClamp(
                  // A room scene and the learning CTA share a tablet row.
                  // This is deliberately wider than the default reading clamp;
                  // the decision below still uses the *actual* post-rail width.
                  maxWidth: 960,
                  base: const EdgeInsets.fromLTRB(
                    Spacing.lg,
                    Spacing.md,
                    Spacing.lg,
                    Spacing.xxxl,
                  ),
                  builder: (context, padding) => RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: padding,
                      children: [
                        const _SarangbangWelcome(),
                        const SizedBox(height: Spacing.lg),
                        // 발견 배너 — 열 수 있는 보자기가 있으면 학습하는 자리에서
                        // 바로 보인다(홈과 동일 카드). 없으면 렌더하지 않는다.
                        if (_openableBoxes > 0) ...[
                          PendingRewardCard(
                            count: _openableBoxes,
                            onOpen: _openBojagi,
                          ),
                          const SizedBox(height: Spacing.lg),
                        ],
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final todayLink = KeyedSubtree(
                              key: const ValueKey('sarangbang-today-link'),
                              child: _SarangbangTodayLink(
                                content: _missionContent(t),
                                onOpen: _openRecommendation,
                              ),
                            );
                            final room = _SarangbangStudyScene(
                              placements: _placements,
                              owned: _ownedDecor,
                              onFurnish: _openFurnish,
                            );

                            // This is an available-content threshold rather
                            // than a screen-width threshold: an AppShell rail
                            // consumes width on tablets.
                            if (constraints.maxWidth >= 640) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 11, child: room),
                                  const SizedBox(width: Spacing.lg),
                                  Expanded(flex: 9, child: todayLink),
                                ],
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                room,
                                const SizedBox(height: Spacing.lg),
                                todayLink,
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  MissionHeroContent? _missionContent(AppL10n t) {
    final snapshot = _snapshot;
    final pick = snapshot?.pick;
    final language = Localizations.localeOf(context).languageCode;
    return switch (pick) {
      CoursePick(
        :final unit,
        :final missionNumber,
        :final totalMissions,
        :final fraction,
        :final started,
      ) =>
        MissionHeroContent(
          kind: MissionHeroKind.course,
          title: unit.title.pick(language),
          levelCode: unit.level.toUpperCase(),
          meta: t.missionHeroCourseMeta(missionNumber, totalMissions),
          fraction: fraction,
          started: started,
          onStart: _openRecommendation,
        ),
      PackPick(:final pack, :final fraction) => MissionHeroContent(
        kind: MissionHeroKind.pack,
        title: VocabPackService.displayLabel(pack.id, lang: language),
        levelCode: pack.level.toUpperCase(),
        meta: t.missionHeroPackMeta(pack.level.toUpperCase()),
        fraction: fraction,
        started: true,
        onStart: _openRecommendation,
      ),
      ReviewPick(:final dueCount) => MissionHeroContent(
        kind: MissionHeroKind.review,
        title: t.missionHeroReviewTitle(dueCount),
        levelCode: null,
        meta: t.missionHeroReviewMeta,
        fraction: 0,
        started: false,
        onStart: _openRecommendation,
      ),
      ScenarioPick(:final scenarioId, :final level) => MissionHeroContent(
        kind: MissionHeroKind.scenario,
        title: snapshot?.scenario?.title.pick(language) ?? scenarioId,
        levelCode: level.code.toUpperCase(),
        meta: t.missionHeroScenarioMeta(level.code.toUpperCase()),
        fraction: 0,
        started: false,
        onStart: _openRecommendation,
      ),
      null => null,
    };
  }
}

/// The Sarangbang is a place to revisit and arrange, not Home's mandatory
/// duplicate mission screen. It can still open the already selected today
/// destination when a learner intentionally arrives here from their Hanok.
class _SarangbangTodayLink extends StatelessWidget {
  const _SarangbangTodayLink({required this.content, required this.onOpen});

  final MissionHeroContent? content;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    final mission = content;
    return SoriCard(
      variant: SoriCardVariant.base,
      child: mission == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.missionHeroAllDoneTitle, style: text.cardTitle),
                const SizedBox(height: Spacing.xs),
                Text(t.missionHeroAllDoneBody, style: text.cardSubtitle),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.homeTodayEyebrow,
                  style: text.label.copyWith(color: SoriColors.primary),
                ),
                const SizedBox(height: Spacing.xs),
                Text(mission.title, style: text.cardTitle),
                const SizedBox(height: Spacing.xs),
                Text(mission.meta, style: text.cardSubtitle),
                const SizedBox(height: Spacing.md),
                SoriButton.outlined(
                  label: t.homeTodayMissionStart,
                  fullWidth: true,
                  onTap: onOpen,
                ),
              ],
            ),
    );
  }
}

class _SarangbangStudyScene extends StatelessWidget {
  final RoomPlacements placements;
  final Set<String> owned;
  final VoidCallback onFurnish;

  const _SarangbangStudyScene({
    required this.placements,
    required this.owned,
    required this.onFurnish,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    return Column(
      key: const ValueKey('sarangbang-study-room'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.sarangbangStudySceneLabel, style: text.h3),
        const SizedBox(height: Spacing.sm),
        PersonalRoomScene(
          surface: PersonalRoomSurface.sarangbang,
          placements: placements,
          owned: owned,
          interactive: false,
        ),
        const SizedBox(height: Spacing.md),
        SoriButton.outlined(
          label: t.sarangbangStudyFurnish,
          fullWidth: true,
          onTap: onFurnish,
        ),
      ],
    );
  }
}

class _SarangbangWelcome extends StatelessWidget {
  const _SarangbangWelcome();

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    return SoriCard(
      variant: SoriCardVariant.hanji,
      accent: SoriColors.primary,
      tinted: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.sarangbangStudyIntroTitle, style: text.h3),
                const SizedBox(height: Spacing.xs),
                Text(t.sarangbangStudyIntroBody, style: text.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: Spacing.md),
          const Mascot.tiger(
            emotion: MascotEmotion.thinking,
            size: 76,
            animate: false,
          ),
        ],
      ),
    );
  }
}
