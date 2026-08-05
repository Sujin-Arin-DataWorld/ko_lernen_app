import 'package:flutter/material.dart';

import '../data/personal_hanok_catalog.dart';
import '../data/personal_hanok_venue_catalog.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/personal_hanok.dart';
import '../services/hanok_stage_service.dart';
import '../services/personal_hanok_reveal_service.dart';
import 'daily_char_sheet.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/personal_hanok_map.dart';
import '../widgets/sori/personal_hanok_unlock_reveal.dart';
import '../widgets/sori/personal_hanok_venue_sheet.dart';
import '../widgets/sori/progress.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/world_map_viewport.dart';

/// The personal estate is a read-only projection of existing course progress.
///
/// It never awards, migrates, or infers learning state. A completed building
/// is simply a spatial doorway to an established Hangul Sori surface.
class HanokWorldScreen extends StatefulWidget {
  final Future<LevelRatios> Function()? loadRatios;
  final ValueChanged<PersonalHanokZone>? onOpenZone;
  final PersonalHanokRevealStore revealStore;
  final Future<void> Function(PersonalHanokVenueAction action)?
  onOpenVenueAction;

  const HanokWorldScreen({
    super.key,
    this.loadRatios,
    this.onOpenZone,
    this.revealStore = const StoragePersonalHanokRevealStore(),
    this.onOpenVenueAction,
  });

  @override
  State<HanokWorldScreen> createState() => _HanokWorldScreenState();
}

class _HanokWorldScreenState extends State<HanokWorldScreen> {
  PersonalHanokProjection? _projection;
  PersonalHanokZone? _selectedZone;
  PersonalHanokMilestone? _activeReveal;
  List<PersonalHanokMilestone> _queuedReveals =
      const <PersonalHanokMilestone>[];
  var _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    final loadRatios = widget.loadRatios ?? HanokStageService.levelRatios;
    try {
      final ratios = await loadRatios();
      if (!mounted) {
        return;
      }
      await _showProjection(
        PersonalHanokProjection.from(ratios),
        generation: generation,
      );
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
      _selectedZone = nextSelection;
    });
    await _scheduleReveal(projection, generation: generation);
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

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final projection = _projection;
    final activeReveal = _activeReveal;
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(t.hanokWorldTitle)),
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
                          maxWidth: 960,
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
                                  onOpenSarangbang: () =>
                                      _openZone(PersonalHanokZone.sarangbang),
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
                              ] else
                                Padding(
                                  padding: sidePadding,
                                  child: PersonalHanokMap(
                                    projection: projection,
                                    zoneLabel: (zone) => _zoneLabel(t, zone),
                                  ),
                                ),
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
              SoriButton.outlined(
                key: ValueKey('hanok-world-place-${place.zone.name}'),
                label: _zoneLabel(t, place.zone),
                fullWidth: true,
                maxLines: 2,
                onTap: () => onSelectZone(place.zone),
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
  final VoidCallback onOpenSarangbang;

  const _WorldIntroduction({
    required this.projection,
    required this.onOpenSarangbang,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    final hasMap = projection.usesCompoundMap;
    return SoriCard(
      variant: SoriCardVariant.hanji,
      accent: SoriColors.primary,
      tinted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasMap ? t.hanokWorldTitle : t.hanokWorldLegacyTitle,
            style: text.h2,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            hasMap ? t.hanokWorldIntro : t.hanokWorldLegacyBody,
            style: text.bodySmall,
          ),
          const SizedBox(height: Spacing.md),
          Semantics(
            label: t.hanokWorldProgress,
            child: SoriProgressBar(
              value: projection.constructionFraction,
              animated: true,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          SoriButton.outlined(
            label: t.hanokWorldOpenSarangbang,
            fullWidth: true,
            onTap: onOpenSarangbang,
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
