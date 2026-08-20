import 'package:flutter/material.dart';

import 'dart:async';

import '../data/personal_hanok_catalog.dart';
import '../data/personal_hanok_venue_catalog.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/hanok_build_narrative.dart';
import '../models/personal_hanok.dart';
import '../services/analytics_service.dart';
import '../services/hanok_build_narrative_service.dart';
import '../services/hanok_stage_service.dart';
import '../services/hanok_structure_projection_service.dart';
import '../services/personal_hanok_reveal_service.dart';
import 'daily_char_sheet.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/app_bar.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/cultural_help.dart';
import '../widgets/sori/hanok_build_narrative_line.dart';
import '../widgets/sori/personal_hanok_map.dart';
import '../widgets/sori/personal_hanok_unlock_reveal.dart';
import '../widgets/sori/personal_hanok_venue_sheet.dart';
import '../widgets/sori/progress.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/window_class.dart';
import '../widgets/sori/world_map_viewport.dart';

/// The personal estate is a read-only projection of existing course progress.
///
/// It never awards, migrates, or infers learning state. A completed building
/// is simply a spatial doorway to an established Hangul Sori surface.
class HanokWorldPreviewData {
  final PersonalHanokProjection projection;
  final HanokBuildNarrative narrative;
  final PersonalHanokZone? selectedZone;

  const HanokWorldPreviewData({
    required this.projection,
    required this.narrative,
    this.selectedZone,
  });
}

class HanokWorldScreen extends StatefulWidget {
  final Future<LevelRatios> Function()? loadRatios;
  final Future<PersonalHanokProjection> Function(LevelRatios ratios)?
  loadProjection;
  final Future<HanokBuildNarrative> Function(
    PersonalHanokProjection projection,
  )?
  loadNarrative;
  final ValueChanged<PersonalHanokZone>? onOpenZone;
  final PersonalHanokRevealStore revealStore;
  final Future<void> Function(PersonalHanokVenueAction action)?
  onOpenVenueAction;
  final HanokWorldPreviewData? preview;
  final bool embedded;

  const HanokWorldScreen({
    super.key,
    this.loadRatios,
    this.loadProjection,
    this.loadNarrative,
    this.onOpenZone,
    this.revealStore = const StoragePersonalHanokRevealStore(),
    this.onOpenVenueAction,
    this.preview,
    this.embedded = false,
  });

  /// Renders the production 03A/03B screen from fixture state. No storage,
  /// reveal journal, progress service, or reward write is touched.
  factory HanokWorldScreen.preview({
    Key? key,
    required PersonalHanokProjection projection,
    required HanokBuildNarrative narrative,
    PersonalHanokZone? selectedZone,
    ValueChanged<PersonalHanokZone>? onOpenZone,
  }) => HanokWorldScreen(
    key: key,
    preview: HanokWorldPreviewData(
      projection: projection,
      narrative: narrative,
      selectedZone: selectedZone,
    ),
    onOpenZone: onOpenZone,
  );

  @override
  State<HanokWorldScreen> createState() => _HanokWorldScreenState();
}

class _HanokWorldScreenState extends State<HanokWorldScreen> {
  PersonalHanokProjection? _projection;
  HanokBuildNarrative? _narrative;
  PersonalHanokZone? _selectedZone;
  PersonalHanokMilestone? _activeReveal;
  List<PersonalHanokMilestone> _queuedReveals =
      const <PersonalHanokMilestone>[];
  var _loadGeneration = 0;
  final GlobalKey _earlyMapKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final preview = widget.preview;
    if (preview == null) {
      Analytics.hanokBuildStarted(roomType: 'madang');
      _load();
      return;
    }
    _projection = preview.projection;
    _narrative = preview.narrative;
    _selectedZone = _previewSelection(preview);
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    final preview = widget.preview;
    if (preview != null) {
      if (mounted) {
        setState(() {
          _projection = preview.projection;
          _narrative = preview.narrative;
          _selectedZone = _previewSelection(preview);
          _activeReveal = null;
          _queuedReveals = const <PersonalHanokMilestone>[];
        });
      }
      return;
    }
    final loadRatios = widget.loadRatios ?? HanokStageService.levelRatios;
    try {
      final ratios = await loadRatios();
      final loadProjection =
          widget.loadProjection ??
          HanokStructureProjectionService.loadForRatios;
      final projection = await loadProjection(ratios);
      if (!mounted) {
        return;
      }
      await _showProjection(projection, generation: generation);
    } catch (_) {
      // The world is an enhancement of the learning route. If its local
      // progress read fails, show the existing empty courtyard rather than
      // trapping the user in a loading state or writing any recovery value.
      if (!mounted) {
        return;
      }
      await _showProjection(
        PersonalHanokProjection.from(
          const LevelRatios(a1: 0, a2: 0, b1: 0, b2: 0),
        ),
        generation: generation,
      );
    }
  }

  PersonalHanokZone? _previewSelection(HanokWorldPreviewData preview) {
    final available = visiblePersonalHanokZones(
      preview.projection,
    ).map((definition) => definition.zone).toList(growable: false);
    if (available.contains(preview.selectedZone)) {
      return preview.selectedZone;
    }
    return available.contains(PersonalHanokZone.sarangbang)
        ? PersonalHanokZone.sarangbang
        : available.isEmpty
        ? null
        : available.first;
  }

  Future<void> _showProjection(
    PersonalHanokProjection projection, {
    required int generation,
  }) async {
    final available = visiblePersonalHanokZones(
      projection,
    ).map((definition) => definition.zone).toList(growable: false);
    final retained = _selectedZone;
    final nextSelection = available.contains(retained)
        ? retained
        : available.contains(PersonalHanokZone.sarangbang)
        ? PersonalHanokZone.sarangbang
        : available.isEmpty
        ? null
        : available.first;
    setState(() {
      _projection = projection;
      _narrative = HanokBuildNarrative.empty(projection);
      _selectedZone = nextSelection;
    });
    unawaited(_loadNarrative(projection, generation: generation));
    await _scheduleReveal(projection, generation: generation);
  }

  Future<void> _loadNarrative(
    PersonalHanokProjection projection, {
    required int generation,
  }) async {
    HanokBuildNarrative narrative;
    try {
      final loadNarrative =
          widget.loadNarrative ?? HanokBuildNarrativeService.loadForProjection;
      narrative = await loadNarrative(projection);
    } catch (_) {
      narrative = HanokBuildNarrative.empty(projection);
    }
    if (!mounted || generation != _loadGeneration) {
      return;
    }
    setState(() => _narrative = narrative);
  }

  Future<void> _scheduleReveal(
    PersonalHanokProjection projection, {
    required int generation,
  }) async {
    PersonalHanokRevealSnapshot snapshot;
    try {
      snapshot = await widget.revealStore.load();
    } catch (_) {
      // A reveal is a progressive enhancement. A local preference error must
      // never block the map or invent a new learning-state write.
      return;
    }
    if (!mounted || generation != _loadGeneration) {
      return;
    }
    final plan = PersonalHanokRevealPlan.forProjection(
      projection: projection,
      snapshot: snapshot,
    );
    if (plan.shouldInitialize) {
      try {
        await widget.revealStore.initialize(plan.milestonesToPersist);
      } catch (_) {
        // Keep the current map visible. A later visit can safely retry the
        // local visual baseline without affecting progress or rewards.
      }
      return;
    }
    if (plan.reveals.isEmpty || _activeReveal != null) {
      return;
    }
    setState(() {
      _activeReveal = plan.reveals.first;
      _queuedReveals = plan.reveals.skip(1).toList(growable: false);
    });
  }

  Future<void> _completeActiveReveal() async {
    final milestone = _activeReveal;
    if (milestone == null) {
      return;
    }
    try {
      await widget.revealStore.markSeen(milestone);
    } catch (_) {
      // Recording the celebration is best effort. The building itself was
      // already derived from established progress and remains visible.
    }
    if (!mounted) {
      return;
    }
    final next = _queuedReveals;
    setState(() {
      _activeReveal = next.isEmpty ? null : next.first;
      _queuedReveals = next.isEmpty
          ? const <PersonalHanokMilestone>[]
          : next.skip(1).toList(growable: false);
    });
  }

  void _selectZone(PersonalHanokZone zone) {
    final projection = _projection;
    if (projection == null ||
        !visiblePersonalHanokZones(
          projection,
        ).any((definition) => definition.zone == zone)) {
      return;
    }
    setState(() => _selectedZone = zone);
  }

  Future<void> _openSelectedZone() async {
    final zone = _selectedZone;
    if (zone == null) {
      return;
    }
    await _openZone(zone);
  }

  Future<void> _openZone(PersonalHanokZone zone) async {
    final onOpenZone = widget.onOpenZone;
    if (onOpenZone != null) {
      onOpenZone(zone);
      return;
    }
    final projection = _projection;
    final venueActions = personalHanokVenueActionsFor(zone);
    if (projection != null && venueActions.isNotEmpty) {
      final t = AppL10n.of(context);
      final action = await showPersonalHanokVenueSheet(
        context: context,
        projection: projection,
        zone: zone,
        zoneLabel: _zoneLabel(t, zone),
      );
      if (!mounted || action == null) {
        return;
      }
      await _openVenueAction(action);
      return;
    }
    final route = hanokRouteForZone(zone);
    if (route == null) {
      return;
    }
    await Navigator.pushNamed(context, route);
    if (mounted) {
      await _load();
    }
  }

  Future<void> _openVenueAction(PersonalHanokVenueAction action) async {
    final override = widget.onOpenVenueAction;
    if (override != null) {
      await override(action);
      return;
    }
    if (action == PersonalHanokVenueAction.openDailyCharacter) {
      await showDailyCharSheet(context);
      return;
    }
    final route = personalHanokVenueRoute(action);
    if (route == null) {
      return;
    }
    await Navigator.of(context).pushNamed(route);
    if (mounted) {
      await _load();
    }
  }

  Future<void> _openGyeHub() async {
    // The shared Gye courtyard is deliberately not a personal-map zone: it
    // owns separate membership, age-gate, and Firestore boundaries. This is
    // only a contextual doorway into the existing Gye hub.
    await Navigator.pushNamed(context, '/gye/hub');
  }

  void _exploreEarlyHouse() {
    final mapContext = _earlyMapKey.currentContext;
    if (mapContext == null) {
      return;
    }
    Scrollable.ensureVisible(
      mapContext,
      alignment: .12,
      duration: SoriMotion.reduceMotion(context)
          ? Duration.zero
          : const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final projection = _projection;
    final activeReveal = _activeReveal;
    return Scaffold(
      backgroundColor: s.bg,
      appBar: widget.embedded
          ? null
          : SoriAppBar(
              title: t.hanokWorldTitle,
              textScale: MediaQuery.textScalerOf(context).scale(1),
              viewportWidth: MediaQuery.sizeOf(context).width,
              actions: const [CulturalHelpButton(termId: 'hanok')],
            ),
      body: Stack(
        children: [
          SoriScreenBackground(
            child: SafeArea(
              child: projection == null
                  ? const AppLoading()
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final padding = soriClampPadding(
                          constraints.maxWidth,
                          maxWidth: SoriMaxWidth.world,
                          base: const EdgeInsets.fromLTRB(
                            Spacing.lg,
                            Spacing.md,
                            Spacing.lg,
                            Spacing.xxxl,
                          ),
                        );
                        final sidePadding = EdgeInsets.symmetric(
                          horizontal: padding.left,
                        );
                        return RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.only(
                              top: padding.top,
                              bottom: padding.bottom,
                            ),
                            children: [
                              Padding(
                                padding: sidePadding,
                                child: _WorldIntroduction(
                                  projection: projection,
                                  narrative: _narrative,
                                ),
                              ),
                              const SizedBox(height: Spacing.lg),
                              if (projection.usesCompoundMap) ...[
                                Semantics(
                                  label: t.hanokWorldTitle,
                                  child: WorldMapViewport(
                                    projection: projection,
                                    selectedZone: _selectedZone,
                                    suppressedMilestones: activeReveal == null
                                        ? const <PersonalHanokMilestone>{}
                                        : <PersonalHanokMilestone>{
                                            activeReveal,
                                          },
                                    onSelectZone: _selectZone,
                                    onOpenSelectedZone: _openSelectedZone,
                                    zoneLabel: (zone) => _zoneLabel(t, zone),
                                    zonePurpose: (zone) =>
                                        _zonePurpose(t, zone),
                                    mapPlaceLabel: (zone) =>
                                        _mapPlaceLabel(t, zone),
                                    todayExpressionKo:
                                        _narrative?.receipt.nextExpressionKo ??
                                        _narrative
                                            ?.receipt
                                            .latestSafeExpressionKo,
                                    contentPadding: sidePadding,
                                  ),
                                ),
                                const SizedBox(height: Spacing.lg),
                                Padding(
                                  padding: sidePadding,
                                  child: _WorldPlaceList(
                                    projection: projection,
                                    onSelectZone: _selectZone,
                                  ),
                                ),
                                const SizedBox(height: Spacing.lg),
                                Padding(
                                  padding: sidePadding,
                                  child: _GyeBridge(onOpen: _openGyeHub),
                                ),
                              ] else ...[
                                Padding(
                                  padding: sidePadding,
                                  child: ConstrainedBox(
                                    key: _earlyMapKey,
                                    constraints: const BoxConstraints(
                                      minHeight: 278,
                                    ),
                                    child: PersonalHanokMap(
                                      projection: projection,
                                      zoneLabel: (zone) => _zoneLabel(t, zone),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: Spacing.lg),
                                Padding(
                                  padding: sidePadding,
                                  child: _EarlyBuildPlan(
                                    projection: projection,
                                    narrative: _narrative,
                                    onExploreHouse: _exploreEarlyHouse,
                                    onOpenNextScene: () => Navigator.of(
                                      context,
                                    ).pushNamed('/course/mission'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
          if (projection != null && activeReveal != null)
            Positioned.fill(
              child: PersonalHanokUnlockReveal(
                key: ValueKey('personal-hanok-unlock-${activeReveal.name}'),
                projection: projection,
                milestone: activeReveal,
                milestoneLabel: _milestoneLabel(t, activeReveal),
                onDone: _completeActiveReveal,
              ),
            ),
        ],
      ),
    );
  }
}

/// A text-first alternative to tapping the art map.
///
/// This remains useful on compact phones, with assistive technology, and when
/// a learner prefers an explicit destination over a visual target.
class _WorldPlaceList extends StatelessWidget {
  final PersonalHanokProjection projection;
  final ValueChanged<PersonalHanokZone> onSelectZone;

  const _WorldPlaceList({required this.projection, required this.onSelectZone});

  @override
  Widget build(BuildContext context) {
    final places = visiblePersonalHanokZones(
      projection,
    ).toList(growable: false);
    if (places.isEmpty) {
      return const SizedBox.shrink();
    }
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    final s = SoriSurfaces.of(context);
    return Semantics(
      container: true,
      label: t.hanokWorldPlacesTitle,
      child: SoriCard(
        variant: SoriCardVariant.base,
        accent: SoriColors.primary,
        tinted: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.hanokWorldPlacesTitle, style: text.h3),
            const SizedBox(height: Spacing.xs),
            Text(
              t.hanokWorldPlacesBody,
              style: text.bodySmall.copyWith(color: s.textMuted),
            ),
            const SizedBox(height: Spacing.md),
            for (final place in places) ...[
              SoriCard(
                key: ValueKey('hanok-world-place-${place.zone.name}'),
                variant: SoriCardVariant.compact,
                accent: SoriColors.primary,
                onTap: () => onSelectZone(place.zone),
                child: Row(
                  children: [
                    const Icon(Icons.place_outlined, color: SoriColors.primary),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_zoneLabel(t, place.zone), style: text.label),
                          const SizedBox(height: 2),
                          Text(
                            _zonePurpose(t, place.zone),
                            style: text.caption.copyWith(color: s.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: SoriColors.primary,
                    ),
                  ],
                ),
              ),
              if (place != places.last) const SizedBox(height: Spacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _WorldIntroduction extends StatelessWidget {
  final PersonalHanokProjection projection;
  final HanokBuildNarrative? narrative;

  const _WorldIntroduction({required this.projection, required this.narrative});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    final hasMap = projection.usesCompoundMap;
    final languageCode = Localizations.localeOf(context).languageCode;
    final verifiedCanDo = narrative?.verifiedUnit?.canDo.pick(languageCode);
    final earlyBody = verifiedCanDo == null
        ? t.hanokWorldEarlyBody
        : t.hanokWorldEarlyVerifiedBody(
            _conciseCanDo(verifiedCanDo, languageCode),
          );
    return SoriCard(
      variant: SoriCardVariant.hanji,
      accent: SoriColors.primary,
      tinted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasMap ? t.hanokWorldMapEyebrow : t.hanokWorldEarlyEyebrow,
            style: text.label.copyWith(color: SoriColors.primary),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            hasMap ? t.hanokWorldMapTitle : t.hanokWorldEarlyTitle,
            style: text.h1,
          ),
          const SizedBox(height: Spacing.sm),
          Text(hasMap ? t.hanokWorldMapBody : earlyBody, style: text.bodySmall),
        ],
      ),
    );
  }

  static String _conciseCanDo(String value, String languageCode) {
    final prefix = languageCode == 'de' ? 'Ich kann ' : 'I can ';
    return value.startsWith(prefix) ? value.substring(prefix.length) : value;
  }
}

/// The early courtyard keeps the familiar stage art, then makes the next
/// everyday-language milestone and its one direct action explicit.  This is
/// intentionally separate from the heading so the visual order follows the
/// mockup: story, existing courtyard, construction plan, next scene.
class _EarlyBuildPlan extends StatelessWidget {
  const _EarlyBuildPlan({
    required this.projection,
    required this.narrative,
    required this.onExploreHouse,
    required this.onOpenNextScene,
  });

  final PersonalHanokProjection projection;
  final HanokBuildNarrative? narrative;
  final VoidCallback onExploreHouse;
  final VoidCallback onOpenNextScene;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    final buildNarrative = narrative ?? HanokBuildNarrative.empty(projection);
    final safeSceneLabel = t.hanokWorldSafeSceneProgress(
      buildNarrative.safeScenesTowardNextBeam,
      buildNarrative.scenesPerBeam,
    );
    final beamFraction =
        buildNarrative.safeScenesTowardNextBeam / buildNarrative.scenesPerBeam;
    return SoriCard(
      variant: SoriCardVariant.base,
      accent: SoriColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.hanokWorldNextBeamTitle, style: text.h3),
          const SizedBox(height: Spacing.sm),
          HanokBuildNarrativeLine(narrative: buildNarrative),
          const SizedBox(height: Spacing.md),
          Semantics(
            label: safeSceneLabel,
            child: SoriProgressBar(value: beamFraction, animated: true),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            safeSceneLabel,
            style: text.caption.copyWith(
              color: SoriSurfaces.of(context).textMuted,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          SoriButton.filled(
            key: const ValueKey('hanok-world-next-scene'),
            label: t.hanokWorldOpenNextScene,
            fullWidth: true,
            onTap: onOpenNextScene,
          ),
          const SizedBox(height: Spacing.xs),
          SoriButton.ghost(
            key: const ValueKey('hanok-world-explore-house'),
            label: t.hanokWorldExploreHouse,
            fullWidth: true,
            onTap: onExploreHouse,
          ),
        ],
      ),
    );
  }
}

/// A semantic connection to the collaborative courtyard, not a personal
/// structure to be rendered or furnished on the estate map.
class _GyeBridge extends StatelessWidget {
  final VoidCallback onOpen;

  const _GyeBridge({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    final s = SoriSurfaces.of(context);
    return SoriCard(
      variant: SoriCardVariant.base,
      accent: SoriColors.gold,
      tinted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups_2_rounded, color: SoriColors.gold),
              const SizedBox(width: Spacing.sm),
              Expanded(child: Text(t.hanokWorldGyeBridgeTitle, style: text.h3)),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            t.hanokWorldGyeBridgeBody,
            style: text.bodySmall.copyWith(color: s.textMuted),
          ),
          const SizedBox(height: Spacing.md),
          SoriButton.outlined(
            key: const ValueKey('hanok-world-gye-bridge'),
            label: t.hanokWorldGyeBridgeOpen,
            accent: SoriColors.gold,
            fullWidth: true,
            maxLines: 2,
            onTap: onOpen,
          ),
        ],
      ),
    );
  }
}

String? hanokRouteForZone(PersonalHanokZone zone) => switch (zone) {
  PersonalHanokZone.sarangbang => '/sarangbang',
  PersonalHanokZone.daecheongmaru => '/hanok/daecheong',
  PersonalHanokZone.haengrangchae => '/practice',
  PersonalHanokZone.anchae => '/hanok/anbang',
  // Huwon has two established destinations, so it must pass through its
  // context sheet instead of silently opening the unrelated daily challenge.
  PersonalHanokZone.huwon => null,
  PersonalHanokZone.sadang => '/dojangcheop',
  PersonalHanokZone.gyeRoad => null,
};

String _zoneLabel(AppL10n t, PersonalHanokZone zone) => switch (zone) {
  PersonalHanokZone.sarangbang => t.hanokZoneSarangbang,
  PersonalHanokZone.daecheongmaru => t.hanokZoneDaecheong,
  PersonalHanokZone.haengrangchae => t.hanokZoneHaengrang,
  PersonalHanokZone.anchae => t.hanokZoneAnchae,
  PersonalHanokZone.huwon => t.hanokZoneHuwon,
  PersonalHanokZone.sadang => t.hanokZoneSadang,
  PersonalHanokZone.gyeRoad => '',
};

String _zonePurpose(AppL10n t, PersonalHanokZone zone) => switch (zone) {
  PersonalHanokZone.sarangbang => t.hanokWorldPurposeSarangbang,
  PersonalHanokZone.daecheongmaru => t.hanokWorldPurposeDaecheong,
  PersonalHanokZone.haengrangchae => t.hanokWorldPurposeHaengrang,
  PersonalHanokZone.anchae => t.hanokWorldPurposeAnchae,
  PersonalHanokZone.huwon => t.hanokWorldPurposeHuwon,
  PersonalHanokZone.sadang => t.hanokWorldPurposeSadang,
  PersonalHanokZone.gyeRoad => t.hanokWorldPurposeGyeRoad,
};

String _mapPlaceLabel(AppL10n t, PersonalHanokZone zone) => switch (zone) {
  PersonalHanokZone.sarangbang => t.hanokMapPlaceSarangbang,
  PersonalHanokZone.daecheongmaru => t.hanokMapPlaceDaecheong,
  PersonalHanokZone.haengrangchae => t.hanokMapPlaceHaengrang,
  PersonalHanokZone.anchae => t.hanokMapPlaceAnchae,
  PersonalHanokZone.huwon => t.hanokMapPlaceHuwon,
  PersonalHanokZone.sadang => t.hanokMapPlaceSadang,
  PersonalHanokZone.gyeRoad => '',
};

String _milestoneLabel(AppL10n t, PersonalHanokMilestone milestone) =>
    switch (milestone) {
      PersonalHanokMilestone.sotdaeulmun => t.hanokStageGate,
      PersonalHanokMilestone.haengrangchae => t.hanokZoneHaengrang,
      PersonalHanokMilestone.sarangchae => t.hanokZoneSarangbang,
      PersonalHanokMilestone.anchae => t.hanokZoneAnchae,
      PersonalHanokMilestone.daecheongmaru => t.hanokZoneDaecheong,
      PersonalHanokMilestone.sadang => t.hanokZoneSadang,
      PersonalHanokMilestone.rearGarden => t.hanokZoneHuwon,
    };
