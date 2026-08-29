import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/ildu_turntable_catalog.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/ildu_world_manifest.dart';
import '../models/personal_hanok.dart';
import '../services/hanok_structure_projection_service.dart';
import '../services/ildu_anchor_placement_service.dart';
import '../services/ildu_decoration_placement_service.dart';
import '../services/ildu_world_projection_adapter.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/app_bar.dart';
import '../widgets/sori/hanok_turntable_2d.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/toast.dart';

typedef IlDuManifestLoader = Future<IlDuWorldManifest> Function();
typedef IlDuLegacyProjectionLoader = Future<PersonalHanokProjection> Function();

class IlDuWorldScreen extends StatefulWidget {
  final IlDuManifestLoader? loadManifest;
  final IlDuLegacyProjectionLoader? loadProjection;
  final IlDuDecorationPlacementStore decorationStore;
  final IlDuAnchorPlacementStore anchorPlacementStore;

  const IlDuWorldScreen({
    super.key,
    this.loadManifest,
    this.loadProjection,
    this.decorationStore =
        const SharedPreferencesIlDuDecorationPlacementStore(),
    this.anchorPlacementStore =
        const SharedPreferencesIlDuAnchorPlacementStore(),
  });

  @override
  State<IlDuWorldScreen> createState() => _IlDuWorldScreenState();
}

class _IlDuWorldScreenState extends State<IlDuWorldScreen> {
  final TransformationController _mapController = TransformationController();
  IlDuWorldManifest? _manifest;
  IlDuWorldProjection? _projection;
  List<IlDuDecorationPlacement> _placements = const <IlDuDecorationPlacement>[];
  List<IlDuAnchorPlacement> _anchorPlacements = const <IlDuAnchorPlacement>[];
  Map<String, Offset> _anchorPositions = const <String, Offset>{};
  Map<String, int> _anchorDirections = const <String, int>{};
  String? _selectedBuildingId;
  String? _selectedGateId;
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
      final savedPlacements = await Future.wait<Object>([
        widget.decorationStore.load(manifest),
        widget.anchorPlacementStore.load(manifest),
      ]);
      final placements = savedPlacements[0] as List<IlDuDecorationPlacement>;
      final anchorPlacements = savedPlacements[1] as List<IlDuAnchorPlacement>;
      final savedAnchors = <String, IlDuAnchorPlacement>{
        for (final placement in anchorPlacements) placement.anchorId: placement,
      };
      if (!mounted) {
        return;
      }
      setState(() {
        _manifest = manifest;
        _projection = const IlDuWorldProjectionAdapter().fromPersonalHanok(
          legacyProjection,
        );
        _placements = placements;
        _anchorPlacements = anchorPlacements;
        _anchorDirections = <String, int>{
          for (final anchor in <IlDuWorldAnchor>[
            ...manifest.buildings,
            ...manifest.gates,
          ])
            if (ilduTurntableForAnchor(anchor.id) case final turntable?)
              anchor.id:
                  savedAnchors[anchor.id]?.direction ??
                  turntable.directionForDegrees(anchor.rotation),
        };
        _anchorPositions = <String, Offset>{
          for (final anchor in <IlDuWorldAnchor>[
            ...manifest.buildings,
            ...manifest.gates,
          ])
            if (ilduTurntableForAnchor(anchor.id) != null)
              anchor.id: Offset(
                savedAnchors[anchor.id]?.x ?? anchor.x,
                savedAnchors[anchor.id]?.y ?? anchor.y,
              ),
        };
        _selectedBuildingId = manifest.buildings.first.id;
        _selectedGateId = null;
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
      soriToast(context, t.ilduWorldSaveError);
    }
  }

  Future<void> _persistAnchorPlacements() async {
    try {
      await widget.anchorPlacementStore.save(_anchorPlacements);
    } catch (_) {
      if (!mounted) {
        return;
      }
      final t = AppL10n.of(context);
      soriToast(context, t.ilduWorldSaveError);
    }
  }

  void _upsertAnchorPlacement(IlDuAnchorPlacement placement) {
    _anchorPlacements = <IlDuAnchorPlacement>[
      for (final current in _anchorPlacements)
        if (current.anchorId != placement.anchorId) current,
      placement,
    ];
  }

  void _openRoute(String route) {
    Navigator.of(context).pushNamed(route);
  }

  void _selectBuilding(IlDuWorldBuilding building) {
    setState(() {
      _selectedBuildingId = building.id;
      _selectedGateId = null;
      _decorating = false;
    });
  }

  void _selectGate(IlDuWorldGate gate) {
    setState(() {
      _selectedGateId = gate.id;
      _decorating = false;
    });
  }

  void _turnAnchor(String anchorId, int direction) {
    final turntable = ilduTurntableForAnchor(anchorId);
    final manifest = _manifest;
    if (turntable == null ||
        manifest == null ||
        direction < 0 ||
        direction >= turntable.frames.length) {
      return;
    }
    final anchor = <IlDuWorldAnchor>[
      ...manifest.buildings,
      ...manifest.gates,
    ].firstWhere((candidate) => candidate.id == anchorId);
    final position = _anchorPositions[anchorId] ?? Offset(anchor.x, anchor.y);
    setState(() {
      _anchorDirections = <String, int>{
        ..._anchorDirections,
        anchorId: direction,
      };
      _upsertAnchorPlacement(
        IlDuAnchorPlacement(
          anchorId: anchorId,
          x: position.dx,
          y: position.dy,
          direction: direction,
        ),
      );
    });
    unawaited(_persistAnchorPlacements());
  }

  void _moveAnchor(IlDuWorldAnchor anchor, Offset delta, Size mapSize) {
    final turntable = ilduTurntableForAnchor(anchor.id);
    if (turntable == null) {
      return;
    }
    final currentPosition =
        _anchorPositions[anchor.id] ?? Offset(anchor.x, anchor.y);
    final direction =
        _anchorDirections[anchor.id] ??
        turntable.directionForDegrees(anchor.rotation);
    final heightPercent =
        (mapSize.width * anchor.width / 100 / turntable.mapAspectRatio) /
        mapSize.height *
        100;
    final moved = moveIlDuAnchor(
      placement: IlDuAnchorPlacement(
        anchorId: anchor.id,
        x: currentPosition.dx,
        y: currentPosition.dy,
        direction: direction,
      ),
      proposedX: currentPosition.dx + delta.dx / mapSize.width * 100,
      proposedY: currentPosition.dy + delta.dy / mapSize.height * 100,
      widthPercent: anchor.width,
      heightPercent: heightPercent,
    );
    setState(() {
      _anchorPositions = <String, Offset>{
        ..._anchorPositions,
        anchor.id: Offset(moved.x, moved.y),
      };
      _upsertAnchorPlacement(moved);
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
              selectedGateId: _selectedGateId,
              decorating: _decorating,
              placements: _placements,
              anchorPositions: _anchorPositions,
              anchorDirections: _anchorDirections,
              mapController: _mapController,
              onPositionMap: _positionMapOnce,
              onSelectBuilding: _selectBuilding,
              onSelectGate: _selectGate,
              onTurnAnchor: _turnAnchor,
              onMoveAnchor: _moveAnchor,
              onFinishMoveAnchor: () => unawaited(_persistAnchorPlacements()),
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
  final String? selectedGateId;
  final bool decorating;
  final List<IlDuDecorationPlacement> placements;
  final Map<String, Offset> anchorPositions;
  final Map<String, int> anchorDirections;
  final TransformationController mapController;
  final void Function(Size viewport, Size mapSize) onPositionMap;
  final ValueChanged<IlDuWorldBuilding> onSelectBuilding;
  final ValueChanged<IlDuWorldGate> onSelectGate;
  final void Function(String anchorId, int direction) onTurnAnchor;
  final void Function(IlDuWorldAnchor anchor, Offset delta, Size mapSize)
  onMoveAnchor;
  final VoidCallback onFinishMoveAnchor;
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
    required this.selectedGateId,
    required this.decorating,
    required this.placements,
    required this.anchorPositions,
    required this.anchorDirections,
    required this.mapController,
    required this.onPositionMap,
    required this.onSelectBuilding,
    required this.onSelectGate,
    required this.onTurnAnchor,
    required this.onMoveAnchor,
    required this.onFinishMoveAnchor,
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
    final selectedBuilding = manifest.buildings.firstWhere(
      (building) => building.id == selectedBuildingId,
    );
    final selectedGate = selectedGateId == null
        ? null
        : manifest.gates.firstWhere((gate) => gate.id == selectedGateId);
    final selectedAnchorId = selectedGate?.id ?? selectedBuilding.id;
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
                        boundaryMargin: const EdgeInsets.all(Spacing.xxxl * 2),
                        child: SizedBox.fromSize(
                          size: mapSize,
                          child: _EstateMap(
                            manifest: manifest,
                            projection: projection,
                            selectedAnchorId: selectedAnchorId,
                            placements: placements,
                            anchorPositions: anchorPositions,
                            anchorDirections: anchorDirections,
                            mapSize: mapSize,
                            onSelectBuilding: onSelectBuilding,
                            onSelectGate: onSelectGate,
                            onMoveAnchor: onMoveAnchor,
                            onFinishMoveAnchor: onFinishMoveAnchor,
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
                          style: SoriTextTheme.of(
                            context,
                          ).label.copyWith(color: const Color(0xFFFFF8E8)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: selectedGate == null
                    ? _PlaceSheet(
                        manifest: manifest,
                        projection: projection,
                        building: selectedBuilding,
                        decorating: decorating,
                        onStartDecorating: onStartDecorating,
                        onFinishDecorating: onFinishDecorating,
                        onAddDecoration: onAddDecoration,
                        direction: anchorDirections[selectedBuilding.id],
                        onDirectionChanged: (direction) =>
                            onTurnAnchor(selectedBuilding.id, direction),
                        onOpenRoute: onOpenRoute,
                      )
                    : _GateSheet(
                        projection: projection,
                        gate: selectedGate,
                        direction: anchorDirections[selectedGate.id],
                        onDirectionChanged: (direction) =>
                            onTurnAnchor(selectedGate.id, direction),
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
                style: SoriTextTheme.of(context).label,
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            '${era.code.toUpperCase()} · ${t.ilduWorldEvidenceNote}',
            style: SoriTextTheme.of(context).caption.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
  final String selectedAnchorId;
  final List<IlDuDecorationPlacement> placements;
  final Map<String, Offset> anchorPositions;
  final Map<String, int> anchorDirections;
  final Size mapSize;
  final ValueChanged<IlDuWorldBuilding> onSelectBuilding;
  final ValueChanged<IlDuWorldGate> onSelectGate;
  final void Function(IlDuWorldAnchor anchor, Offset delta, Size mapSize)
  onMoveAnchor;
  final VoidCallback onFinishMoveAnchor;
  final void Function(IlDuDecorationPlacement, Offset, Size) onMoveDecoration;
  final VoidCallback onFinishMove;

  const _EstateMap({
    required this.manifest,
    required this.projection,
    required this.selectedAnchorId,
    required this.placements,
    required this.anchorPositions,
    required this.anchorDirections,
    required this.mapSize,
    required this.onSelectBuilding,
    required this.onSelectGate,
    required this.onMoveAnchor,
    required this.onFinishMoveAnchor,
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
        for (final gate in manifest.gates) _gateAnchor(gate),
        for (final building in manifest.buildings) _buildingAnchor(building),
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

  Widget _buildingAnchor(IlDuWorldBuilding building) {
    final turntable = ilduTurntableForAnchor(building.id);
    final direction =
        anchorDirections[building.id] ??
        turntable?.directionForDegrees(building.rotation);
    return _MapAnchor(
      key: ValueKey('ildu-map-turntable-${building.id}-$direction'),
      anchor: building,
      mapSize: mapSize,
      available: projection.isAvailable(building.unlockEra),
      selected: selectedAnchorId == building.id,
      position: anchorPositions[building.id],
      assetPath: manifest.worldAsset(building.asset),
      turntableFrame: turntable == null || direction == null
          ? null
          : turntable.frames[direction],
      turntableAspectRatio: turntable?.mapAspectRatio,
      onTap: () => onSelectBuilding(building),
      onPanUpdate: (details) => onMoveAnchor(building, details.delta, mapSize),
      onPanEnd: (_) => onFinishMoveAnchor(),
      onPanCancel: onFinishMoveAnchor,
    );
  }

  Widget _gateAnchor(IlDuWorldGate gate) {
    final turntable = ilduTurntableForAnchor(gate.id);
    final direction =
        anchorDirections[gate.id] ??
        turntable?.directionForDegrees(gate.rotation);
    return _MapAnchor(
      key: ValueKey('ildu-map-turntable-${gate.id}-$direction'),
      anchor: gate,
      mapSize: mapSize,
      available: projection.isAvailable(gate.unlockEra),
      selected: selectedAnchorId == gate.id,
      position: anchorPositions[gate.id],
      assetPath: manifest.worldAsset(gate.asset),
      turntableFrame: turntable == null || direction == null
          ? null
          : turntable.frames[direction],
      turntableAspectRatio: turntable?.mapAspectRatio,
      onTap: () => onSelectGate(gate),
      onPanUpdate: (details) => onMoveAnchor(gate, details.delta, mapSize),
      onPanEnd: (_) => onFinishMoveAnchor(),
      onPanCancel: onFinishMoveAnchor,
    );
  }
}

class _MapAnchor extends StatelessWidget {
  final IlDuWorldAnchor anchor;
  final Size mapSize;
  final bool available;
  final bool selected;
  final String assetPath;
  final Offset? position;
  final IlDuTurntableFrame? turntableFrame;
  final double? turntableAspectRatio;
  final VoidCallback? onTap;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;
  final GestureDragCancelCallback? onPanCancel;

  const _MapAnchor({
    super.key,
    required this.anchor,
    required this.mapSize,
    required this.available,
    required this.assetPath,
    this.position,
    this.turntableFrame,
    this.turntableAspectRatio,
    this.selected = false,
    this.onTap,
    this.onPanUpdate,
    this.onPanEnd,
    this.onPanCancel,
  });

  @override
  Widget build(BuildContext context) {
    final width = mapSize.width * anchor.width / 100;
    final center = position ?? Offset(anchor.x, anchor.y);
    final frame = turntableFrame;
    final image = frame == null
        ? Image.asset(
            assetPath,
            width: width,
            fit: BoxFit.contain,
            cacheWidth: onTap == null ? 180 : 360,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          )
        : SizedBox(
            width: width,
            height: width / turntableAspectRatio!,
            child: HanokTurntableFrameImage(frame: frame, cacheWidth: 360),
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
        Padding(padding: const EdgeInsets.all(Spacing.xs), child: visual),
        if (!available && onTap != null)
          DecoratedBox(
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
                  style: SoriTextTheme.of(
                    context,
                  ).cultureTitle.copyWith(color: const Color(0xFFFFE3A7)),
                ),
              ),
            ),
          ),
      ],
    );
    return Positioned(
      left: mapSize.width * center.dx / 100,
      top: mapSize.height * center.dy / 100,
      child: FractionalTranslation(
        translation: const Offset(-.5, -.5),
        child: Transform.rotate(
          angle: frame == null ? anchor.rotation * math.pi / 180 : 0,
          child: onTap == null
              ? content
              : Semantics(
                  button: true,
                  label: anchor.ko,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onTap,
                    onPanUpdate: available ? onPanUpdate : null,
                    onPanEnd: available ? onPanEnd : null,
                    onPanCancel: available ? onPanCancel : null,
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

class _GateSheet extends StatelessWidget {
  final IlDuWorldProjection projection;
  final IlDuWorldGate gate;
  final int? direction;
  final ValueChanged<int> onDirectionChanged;

  const _GateSheet({
    required this.projection,
    required this.gate,
    required this.direction,
    required this.onDirectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final available = projection.isAvailable(gate.unlockEra);
    final turntable = ilduTurntableForAnchor(gate.id);
    final turntableDirection =
        direction ?? turntable?.directionForDegrees(gate.rotation);
    final showsTurntable =
        available && turntable != null && turntableDirection != null;
    return Material(
      elevation: 18,
      color: Theme.of(context).colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: showsTurntable
              ? Spacing.xxxl * 5 + Spacing.xl
              : Spacing.xxxl * 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.sm,
              Spacing.lg,
              Spacing.md,
            ),
            child: Column(
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
                      borderRadius: SoriRadius.brPill,
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
                            gate.unlockEra.code.toUpperCase(),
                            style: SoriTextTheme.of(
                              context,
                            ).eyebrow.copyWith(color: SoriColors.primaryDark),
                          ),
                          Text(
                            gate.ko,
                            style: SoriTextTheme.of(context).cultureTitle,
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
                if (showsTurntable) ...[
                  const SizedBox(height: Spacing.sm),
                  SizedBox(
                    height: 118,
                    child: Row(
                      children: [
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: SoriSurfaces.of(context).surfaceAlt,
                              borderRadius: SoriRadius.brMd,
                              border: Border.all(
                                color: SoriColors.primary.withValues(
                                  alpha: .18,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(Spacing.xs),
                              child: HanokTurntable2D(
                                key: ValueKey('ildu-turntable-${gate.id}'),
                                frames: turntable.frames,
                                direction: turntableDirection,
                                onDirectionChanged: onDirectionChanged,
                                semanticsLabel:
                                    '${gate.ko}. ${t.ilduWorldRotateBuildingHint}',
                                zoomInLabel: t.ilduWorldZoomInBuilding,
                                zoomOutLabel: t.ilduWorldZoomOutBuilding,
                                resetZoomLabel: t.ilduWorldResetBuildingZoom,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        SizedBox(
                          width: 104,
                          child: Text(
                            t.ilduWorldRotateBuildingHint,
                            style: SoriTextTheme.of(context).caption.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        t.ilduWorldGateHeritageDetail,
                        style: SoriTextTheme.of(context).caption.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: Spacing.md),
                  Text(
                    t.ilduWorldLockedTitle(gate.unlockEra.code.toUpperCase()),
                    style: SoriTextTheme.of(context).cardTitle,
                  ),
                  Text(
                    t.ilduWorldLockedBody,
                    style: SoriTextTheme.of(context).caption.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
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
  final int? direction;
  final ValueChanged<int> onDirectionChanged;
  final ValueChanged<String> onOpenRoute;

  const _PlaceSheet({
    required this.manifest,
    required this.projection,
    required this.building,
    required this.decorating,
    required this.onStartDecorating,
    required this.onFinishDecorating,
    required this.onAddDecoration,
    required this.direction,
    required this.onDirectionChanged,
    required this.onOpenRoute,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final hub = manifest.hubFor(building.hubId);
    final available = projection.isAvailable(building.unlockEra);
    final turntable = ilduTurntableForAnchor(building.id);
    final turntableDirection =
        direction ?? turntable?.directionForDegrees(building.rotation);
    final showsTurntable =
        available && turntable != null && turntableDirection != null;
    return Material(
      elevation: 18,
      color: Theme.of(context).colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: showsTurntable
              ? Spacing.xxxl * 8 + Spacing.sm
              : Spacing.xxxl * 6,
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
                                  style: SoriTextTheme.of(context).eyebrow
                                      .copyWith(color: SoriColors.primaryDark),
                                ),
                                Text(
                                  building.ko,
                                  style: SoriTextTheme.of(context).cultureTitle,
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
                      if (showsTurntable) ...[
                        const SizedBox(height: Spacing.sm),
                        SizedBox(
                          height: 118,
                          child: Row(
                            children: [
                              Expanded(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: SoriSurfaces.of(context).surfaceAlt,
                                    borderRadius: SoriRadius.brMd,
                                    border: Border.all(
                                      color: SoriColors.primary.withValues(
                                        alpha: .18,
                                      ),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(Spacing.xs),
                                    child: HanokTurntable2D(
                                      key: ValueKey(
                                        'ildu-turntable-${building.id}',
                                      ),
                                      frames: turntable.frames,
                                      direction: turntableDirection,
                                      onDirectionChanged: onDirectionChanged,
                                      semanticsLabel:
                                          '${building.ko}. ${t.ilduWorldRotateBuildingHint}',
                                      zoomInLabel: t.ilduWorldZoomInBuilding,
                                      zoomOutLabel: t.ilduWorldZoomOutBuilding,
                                      resetZoomLabel:
                                          t.ilduWorldResetBuildingZoom,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: Spacing.sm),
                              SizedBox(
                                width: 94,
                                child: Text(
                                  t.ilduWorldRotateBuildingHint,
                                  style: SoriTextTheme.of(context).caption
                                      .copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: Spacing.sm),
                      if (available)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.ilduWorldRecommended,
                                style: SoriTextTheme.of(context).eyebrow,
                              ),
                              Text(
                                building.lessonIntent,
                                style: SoriTextTheme.of(context).cardTitle,
                              ),
                              const Spacer(),
                              SizedBox(
                                width: double.infinity,
                                height: Spacing.xxxl,
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
                                style: SoriTextTheme.of(context).eyebrow,
                              ),
                              Text(
                                t.ilduWorldLockedTitle(
                                  building.unlockEra.code.toUpperCase(),
                                ),
                                style: SoriTextTheme.of(context).cardTitle,
                              ),
                              Text(
                                t.ilduWorldLockedBody,
                                style: SoriTextTheme.of(context).caption
                                    .copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: double.infinity,
                                height: Spacing.xxxl,
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
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.xs,
        ),
        child: Text(
          label,
          style: SoriTextTheme.of(context).label.copyWith(color: color),
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
                    style: SoriTextTheme.of(context).cultureTitle,
                  ),
                  Text(
                    t.ilduWorldDecorBody,
                    style: SoriTextTheme.of(context).caption.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: SoriTextTheme.of(context).label,
                      ),
                      Text(
                        available
                            ? t.ilduWorldDecorPlace
                            : t.ilduWorldDecorRequires(
                                definition.unlockEra.code.toUpperCase(),
                              ),
                        textAlign: TextAlign.center,
                        style: SoriTextTheme.of(context).caption.copyWith(
                          color: SoriColors.primaryDark,
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
