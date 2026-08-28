import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/ildu_world_manifest.dart';
import '../models/personal_hanok.dart';
import '../services/hanok_structure_projection_service.dart';
import '../services/ildu_decoration_placement_service.dart';
import '../services/ildu_world_projection_adapter.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/app_bar.dart';
import '../widgets/sori/tokens.dart';

typedef IlDuManifestLoader = Future<IlDuWorldManifest> Function();
typedef IlDuLegacyProjectionLoader = Future<PersonalHanokProjection> Function();

class IlDuWorldScreen extends StatefulWidget {
  final IlDuManifestLoader? loadManifest;
  final IlDuLegacyProjectionLoader? loadProjection;
  final IlDuDecorationPlacementStore decorationStore;

  const IlDuWorldScreen({
    super.key,
    this.loadManifest,
    this.loadProjection,
    this.decorationStore =
        const SharedPreferencesIlDuDecorationPlacementStore(),
  });

  @override
  State<IlDuWorldScreen> createState() => _IlDuWorldScreenState();
}

class _IlDuWorldScreenState extends State<IlDuWorldScreen> {
  final TransformationController _mapController = TransformationController();
  IlDuWorldManifest? _manifest;
  IlDuWorldProjection? _projection;
  List<IlDuDecorationPlacement> _placements = const <IlDuDecorationPlacement>[];
  String? _selectedBuildingId;
  bool _decorating = false;
  bool _mapPositioned = false;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final results = await Future.wait<Object>([
        (widget.loadManifest ?? IlDuWorldManifest.load)(),
        (widget.loadProjection ??
            HanokStructureProjectionService.loadCurrent)(),
      ]);
      final manifest = results[0] as IlDuWorldManifest;
      final legacyProjection = results[1] as PersonalHanokProjection;
      final placements = await widget.decorationStore.load(manifest);
      if (!mounted) {
        return;
      }
      setState(() {
        _manifest = manifest;
        _projection = const IlDuWorldProjectionAdapter().fromPersonalHanok(
          legacyProjection,
        );
        _placements = placements;
        _selectedBuildingId = manifest.buildings.first.id;
        _mapPositioned = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loadError = error);
    }
  }

  Future<void> _persistPlacements() async {
    try {
      await widget.decorationStore.save(_placements);
    } catch (_) {
      if (!mounted) {
        return;
      }
      final t = AppL10n.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.ilduWorldSaveError)));
    }
  }

  void _openRoute(String route) {
    Navigator.of(context).pushNamed(route);
  }

  void _selectBuilding(IlDuWorldBuilding building) {
    setState(() {
      _selectedBuildingId = building.id;
      _decorating = false;
    });
  }

  void _addDecoration(IlDuWorldDecoration definition) {
    final manifest = _manifest;
    final projection = _projection;
    if (manifest == null ||
        projection == null ||
        !projection.isAvailable(definition.unlockEra) ||
        _placements.length >=
            SharedPreferencesIlDuDecorationPlacementStore.maximumPlacements) {
      return;
    }
    final yard = manifest.yardFor(definition.allowedYards.first);
    final placement = IlDuDecorationPlacement(
      instanceId:
          '${definition.id}-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
      definitionId: definition.id,
      yardId: yard.id,
      x: yard.bounds.left + yard.bounds.width / 2,
      y: yard.bounds.top + yard.bounds.height / 2,
    );
    setState(
      () => _placements = <IlDuDecorationPlacement>[..._placements, placement],
    );
    unawaited(_persistPlacements());
  }

  void _moveDecoration(
    IlDuDecorationPlacement placement,
    Offset delta,
    Size mapSize,
  ) {
    final manifest = _manifest;
    if (manifest == null) {
      return;
    }
    final definition = manifest.decorationFor(placement.definitionId);
    final moved = moveIlDuDecoration(
      placement: placement,
      definition: definition,
      manifest: manifest,
      proposedX: placement.x + delta.dx / mapSize.width * 100,
      proposedY: placement.y + delta.dy / mapSize.height * 100,
    );
    setState(() {
      _placements = [
        for (final current in _placements)
          if (current.instanceId == placement.instanceId) moved else current,
      ];
    });
  }

  void _positionMapOnce(Size viewport, Size mapSize) {
    if (_mapPositioned) {
      return;
    }
    _mapPositioned = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final dx = math.min(0.0, (viewport.width - mapSize.width) / 2);
      final dy = math.min(0.0, (viewport.height - mapSize.height) * .42);
      _mapController.value = Matrix4.identity()..setTranslationRaw(dx, dy, 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final manifest = _manifest;
    final projection = _projection;
    return Scaffold(
      appBar: SoriAppBar(
        title: t.ilduWorldTitle,
        textScale: MediaQuery.textScalerOf(context).scale(1),
        viewportWidth: MediaQuery.sizeOf(context).width,
      ),
      body: manifest == null || projection == null
          ? _loadError == null
                ? const AppLoading()
                : _LoadFailure(onRetry: _load)
          : _WorldBody(
              manifest: manifest,
              projection: projection,
              selectedBuildingId: _selectedBuildingId!,
              decorating: _decorating,
              placements: _placements,
              mapController: _mapController,
              onPositionMap: _positionMapOnce,
              onSelectBuilding: _selectBuilding,
              onStartDecorating: () => setState(() => _decorating = true),
              onFinishDecorating: () => setState(() => _decorating = false),
              onAddDecoration: _addDecoration,
              onMoveDecoration: _moveDecoration,
              onFinishMove: () => unawaited(_persistPlacements()),
              onOpenRoute: _openRoute,
            ),
    );
  }
}

class _WorldBody extends StatelessWidget {
  final IlDuWorldManifest manifest;
  final IlDuWorldProjection projection;
  final String selectedBuildingId;
  final bool decorating;
  final List<IlDuDecorationPlacement> placements;
  final TransformationController mapController;
  final void Function(Size viewport, Size mapSize) onPositionMap;
  final ValueChanged<IlDuWorldBuilding> onSelectBuilding;
  final VoidCallback onStartDecorating;
  final VoidCallback onFinishDecorating;
  final ValueChanged<IlDuWorldDecoration> onAddDecoration;
  final void Function(
    IlDuDecorationPlacement placement,
    Offset delta,
    Size mapSize,
  )
  onMoveDecoration;
  final VoidCallback onFinishMove;
  final ValueChanged<String> onOpenRoute;

  const _WorldBody({
    required this.manifest,
    required this.projection,
    required this.selectedBuildingId,
    required this.decorating,
    required this.placements,
    required this.mapController,
    required this.onPositionMap,
    required this.onSelectBuilding,
    required this.onStartDecorating,
    required this.onFinishDecorating,
    required this.onAddDecoration,
    required this.onMoveDecoration,
    required this.onFinishMove,
    required this.onOpenRoute,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final builtCount = manifest.buildings
        .where((building) => projection.isAvailable(building.unlockEra))
        .length;
    final selected = manifest.buildings.firstWhere(
      (building) => building.id == selectedBuildingId,
    );
    return Column(
      children: [
        _ProgressHeader(
          era: projection.era,
          built: builtCount,
          total: manifest.buildings.length,
        ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final viewport = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    final mapWidth = math.max(
                      manifest.canvas.mobileContentWidth.toDouble(),
                      constraints.maxWidth,
                    );
                    final mapSize = Size(
                      mapWidth,
                      mapWidth * manifest.canvas.height / manifest.canvas.width,
                    );
                    onPositionMap(viewport, mapSize);
                    return ColoredBox(
                      color: const Color(0xFFE9D9BC),
                      child: InteractiveViewer(
                        transformationController: mapController,
                        constrained: false,
                        minScale: 1,
                        maxScale: 2.2,
                        boundaryMargin: const EdgeInsets.all(80),
                        child: SizedBox.fromSize(
                          size: mapSize,
                          child: _EstateMap(
                            manifest: manifest,
                            projection: projection,
                            selectedBuildingId: selectedBuildingId,
                            placements: placements,
                            mapSize: mapSize,
                            onSelectBuilding: onSelectBuilding,
                            onMoveDecoration: onMoveDecoration,
                            onFinishMove: onFinishMove,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: Spacing.sm,
                left: 0,
                right: 0,
                child: Center(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: SoriColors.darkBg.withValues(alpha: .82),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.md,
                          vertical: Spacing.xs,
                        ),
                        child: Text(
                          t.ilduWorldPanHint,
                          style: const TextStyle(
                            color: Color(0xFFFFF8E8),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _PlaceSheet(
                  manifest: manifest,
                  projection: projection,
                  building: selected,
                  decorating: decorating,
                  onStartDecorating: onStartDecorating,
                  onFinishDecorating: onFinishDecorating,
                  onAddDecoration: onAddDecoration,
                  onOpenRoute: onOpenRoute,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final IlDuWorldEra era;
  final int built;
  final int total;

  const _ProgressHeader({
    required this.era,
    required this.built,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.sm,
        Spacing.lg,
        Spacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: total == 0 ? 0 : built / total,
                    color: SoriColors.primary,
                    backgroundColor: SoriColors.primarySoft,
                  ),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                t.ilduWorldBuiltCount(built, total),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            '${era.code.toUpperCase()} · ${t.ilduWorldEvidenceNote}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _EstateMap extends StatelessWidget {
  final IlDuWorldManifest manifest;
  final IlDuWorldProjection projection;
  final String selectedBuildingId;
  final List<IlDuDecorationPlacement> placements;
  final Size mapSize;
  final ValueChanged<IlDuWorldBuilding> onSelectBuilding;
  final void Function(IlDuDecorationPlacement, Offset, Size) onMoveDecoration;
  final VoidCallback onFinishMove;

  const _EstateMap({
    required this.manifest,
    required this.projection,
    required this.selectedBuildingId,
    required this.placements,
    required this.mapSize,
    required this.onSelectBuilding,
    required this.onMoveDecoration,
    required this.onFinishMove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Image.asset(
            manifest.worldAsset(manifest.canvas.asset),
            fit: BoxFit.fill,
            cacheWidth: 1024,
            filterQuality: FilterQuality.medium,
          ),
        ),
        for (final gate in manifest.gates)
          _MapAnchor(
            anchor: gate,
            mapSize: mapSize,
            available: projection.isAvailable(gate.unlockEra),
            assetPath: manifest.worldAsset(gate.asset),
          ),
        for (final building in manifest.buildings)
          _MapAnchor(
            anchor: building,
            mapSize: mapSize,
            available: projection.isAvailable(building.unlockEra),
            selected: selectedBuildingId == building.id,
            assetPath: manifest.worldAsset(building.asset),
            onTap: () => onSelectBuilding(building),
          ),
        for (final placement in placements)
          _DecorationAnchor(
            placement: placement,
            definition: manifest.decorationFor(placement.definitionId),
            assetPath: manifest.decorationAsset(
              manifest.decorationFor(placement.definitionId).asset,
            ),
            mapSize: mapSize,
            onMove: (delta) => onMoveDecoration(placement, delta, mapSize),
            onFinishMove: onFinishMove,
          ),
      ],
    );
  }
}

class _MapAnchor extends StatelessWidget {
  final IlDuWorldAnchor anchor;
  final Size mapSize;
  final bool available;
  final bool selected;
  final String assetPath;
  final VoidCallback? onTap;

  const _MapAnchor({
    required this.anchor,
    required this.mapSize,
    required this.available,
    required this.assetPath,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = mapSize.width * anchor.width / 100;
    final image = Image.asset(
      assetPath,
      width: width,
      fit: BoxFit.contain,
      cacheWidth: onTap == null ? 180 : 360,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
    final visual = AnimatedOpacity(
      opacity: available ? 1 : .18,
      duration: const Duration(milliseconds: 260),
      child: ColorFiltered(
        colorFilter: available
            ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
            : const ColorFilter.mode(Color(0xFF9A8A70), BlendMode.saturation),
        child: image,
      ),
    );
    final content = Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (selected)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: SoriColors.accent, width: 2),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        Padding(padding: const EdgeInsets.all(5), child: visual),
        if (!available && onTap != null)
          const DecoratedBox(
            decoration: BoxDecoration(
              color: SoriColors.darkBg,
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: 30,
              height: 30,
              child: Center(
                child: Text(
                  '?',
                  style: TextStyle(
                    color: Color(0xFFFFE3A7),
                    fontFamily: 'MaruBuri',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
    return Positioned(
      left: mapSize.width * anchor.x / 100,
      top: mapSize.height * anchor.y / 100,
      child: FractionalTranslation(
        translation: const Offset(-.5, -.5),
        child: Transform.rotate(
          angle: anchor.rotation * math.pi / 180,
          child: onTap == null
              ? content
              : Semantics(
                  button: true,
                  label: anchor.ko,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onTap,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      child: content,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _DecorationAnchor extends StatelessWidget {
  final IlDuDecorationPlacement placement;
  final IlDuWorldDecoration definition;
  final String assetPath;
  final Size mapSize;
  final ValueChanged<Offset> onMove;
  final VoidCallback onFinishMove;

  const _DecorationAnchor({
    required this.placement,
    required this.definition,
    required this.assetPath,
    required this.mapSize,
    required this.onMove,
    required this.onFinishMove,
  });

  @override
  Widget build(BuildContext context) {
    final width = mapSize.width * definition.width / 100;
    return Positioned(
      left: mapSize.width * placement.x / 100,
      top: mapSize.height * placement.y / 100,
      child: FractionalTranslation(
        translation: const Offset(-.5, -.5),
        child: Transform.rotate(
          angle: definition.rotation * math.pi / 180,
          child: Semantics(
            button: true,
            label: definition.ko,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (details) => onMove(details.delta),
              onPanEnd: (_) => onFinishMove(),
              onPanCancel: onFinishMove,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  assetPath,
                  width: width,
                  fit: BoxFit.contain,
                  cacheWidth: 180,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceSheet extends StatelessWidget {
  final IlDuWorldManifest manifest;
  final IlDuWorldProjection projection;
  final IlDuWorldBuilding building;
  final bool decorating;
  final VoidCallback onStartDecorating;
  final VoidCallback onFinishDecorating;
  final ValueChanged<IlDuWorldDecoration> onAddDecoration;
  final ValueChanged<String> onOpenRoute;

  const _PlaceSheet({
    required this.manifest,
    required this.projection,
    required this.building,
    required this.decorating,
    required this.onStartDecorating,
    required this.onFinishDecorating,
    required this.onAddDecoration,
    required this.onOpenRoute,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final hub = manifest.hubFor(building.hubId);
    final available = projection.isAvailable(building.unlockEra);
    return Material(
      elevation: 18,
      color: Theme.of(context).colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: decorating ? 262 : 246,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.sm,
              Spacing.lg,
              Spacing.md,
            ),
            child: decorating
                ? _DecorationPalette(
                    manifest: manifest,
                    projection: projection,
                    onDone: onFinishDecorating,
                    onAdd: onAddDecoration,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: .18),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${hub.ko} · ${building.unlockEra.code.toUpperCase()}',
                                  style: const TextStyle(
                                    color: SoriColors.primaryDark,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  building.ko,
                                  style: const TextStyle(
                                    fontFamily: 'MaruBuri',
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _StateLabel(
                            label: available
                                ? t.ilduWorldOpenState
                                : t.ilduWorldPlannedState,
                            available: available,
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.sm),
                      if (available)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.ilduWorldRecommended,
                                style: const TextStyle(
                                  color: SoriColors.accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                building.lessonIntent,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: double.infinity,
                                height: 42,
                                child: FilledButton(
                                  onPressed: () =>
                                      onOpenRoute(hub.primaryRoute),
                                  child: Text(t.ilduWorldStartRecommended),
                                ),
                              ),
                              const SizedBox(height: Spacing.xs),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () => onOpenRoute(
                                        hub.secondaryRoutes.first,
                                      ),
                                      child: Text(t.ilduWorldExplore),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextButton(
                                      onPressed: onStartDecorating,
                                      child: Text(t.ilduWorldDecorate),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () =>
                                          onOpenRoute(hub.secondaryRoutes.last),
                                      child: Text(t.ilduWorldCulture),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      else
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.ilduWorldLockedEyebrow,
                                style: const TextStyle(
                                  color: SoriColors.accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                t.ilduWorldLockedTitle(
                                  building.unlockEra.code.toUpperCase(),
                                ),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                t.ilduWorldLockedBody,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: double.infinity,
                                height: 42,
                                child: OutlinedButton(
                                  onPressed: () =>
                                      onOpenRoute('/course/mission'),
                                  child: Text(t.ilduWorldLockedCta),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _StateLabel extends StatelessWidget {
  final String label;
  final bool available;

  const _StateLabel({required this.label, required this.available});

  @override
  Widget build(BuildContext context) {
    final color = available ? SoriColors.primaryDark : SoriColors.accent;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        border: Border(left: BorderSide(color: color, width: 2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _DecorationPalette extends StatelessWidget {
  final IlDuWorldManifest manifest;
  final IlDuWorldProjection projection;
  final VoidCallback onDone;
  final ValueChanged<IlDuWorldDecoration> onAdd;

  const _DecorationPalette({
    required this.manifest,
    required this.projection,
    required this.onDone,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.ilduWorldDecorate,
                    style: const TextStyle(
                      fontFamily: 'MaruBuri',
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    t.ilduWorldDecorBody,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onDone, child: Text(t.ilduWorldDecorDone)),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        Expanded(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: manifest.decorations.length,
            separatorBuilder: (_, _) => const SizedBox(width: Spacing.sm),
            itemBuilder: (context, index) {
              final definition = manifest.decorations[index];
              final available = projection.isAvailable(definition.unlockEra);
              return SizedBox(
                width: 92,
                child: OutlinedButton(
                  onPressed: available ? () => onAdd(definition) : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(Spacing.sm),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Image.asset(
                          manifest.decorationAsset(definition.asset),
                          cacheWidth: 150,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Text(
                        definition.ko,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                      Text(
                        available
                            ? t.ilduWorldDecorPlace
                            : t.ilduWorldDecorRequires(
                                definition.unlockEra.code.toUpperCase(),
                              ),
                        style: const TextStyle(
                          color: SoriColors.primaryDark,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LoadFailure extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _LoadFailure({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IconButton.filledTonal(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        tooltip: MaterialLocalizations.of(
          context,
        ).refreshIndicatorSemanticLabel,
      ),
    );
  }
}
