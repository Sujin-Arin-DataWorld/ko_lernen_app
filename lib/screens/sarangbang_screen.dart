import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/personal_room.dart';
import '../services/mission_recommender.dart';
import '../services/pack_access.dart';
import '../services/room_placement_service.dart';
import '../services/storage_service.dart';
import '../services/today_learning_snapshot.dart';
import '../services/vocab_pack_service.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/mission_hero_card.dart';
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
        _loading = false;
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

    final destination = snapshot.destination;
    if (destination == null) {
      return;
    }
    final level = destination.packAccessLevel;
    if (level != null) {
      final allowed = await ensurePackAccess(context, level: level);
      if (!allowed || !mounted) {
        return;
      }
    }
    await Navigator.of(
      context,
    ).pushNamed(destination.route, arguments: destination.arguments);
    if (mounted) {
      await _load();
    }
  }

  Future<void> _openFurnish() async {
    await Navigator.of(context).pushNamed('/sarangbang/furnish');
    if (mounted) {
      _reloadRoomScene();
    }
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
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final mission = KeyedSubtree(
                              key: const ValueKey('sarangbang-study-mission'),
                              child: MissionHeroCard(
                                loading: false,
                                content: _missionContent(t),
                                onAnotherRound: () =>
                                    Navigator.of(context).pushNamed('/path'),
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
                                  Expanded(flex: 11, child: mission),
                                  const SizedBox(width: Spacing.lg),
                                  Expanded(flex: 9, child: room),
                                ],
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                mission,
                                const SizedBox(height: Spacing.lg),
                                room,
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
