import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/ildu_turntable_catalog.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/ildu_construction_plan.dart';
import '../models/ildu_world_manifest.dart';
import '../models/personal_hanok.dart';
import '../services/hanok_structure_projection_service.dart';
import '../services/ildu_anchor_placement_service.dart';
import '../services/ildu_construction_plan_repository.dart';
import '../services/ildu_construction_progress_service.dart';
import '../services/ildu_decoration_placement_service.dart';
import '../services/ildu_world_projection_adapter.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/app_bar.dart';
import '../widgets/sori/hanok_turntable_2d.dart';
import '../widgets/sori/ildu_construction_stage_layer.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/toast.dart';
import 'ildu_learning_module_screen.dart';

typedef IlDuManifestLoader = Future<IlDuWorldManifest> Function();
typedef IlDuLegacyProjectionLoader = Future<PersonalHanokProjection> Function();
typedef IlDuConstructionPlanLoader =
    Future<IlDuEstateConstructionPlan> Function();

/// 건물 시트가 그리는 현재 공정 정보. 완공(마지막 단계 완료) 앵커에는
/// 만들어지지 않는다 — 그때는 기존 시트·턴테이블로 복귀한다.
class IlDuConstructionSheetInfo {
  const IlDuConstructionSheetInfo({
    required this.stage,
    required this.module,
    required this.onOpenModule,
  });

  final IlDuConstructionStage stage;

  /// 현재 단계에서 아직 완료되지 않은 첫 필수 모듈 — "다음 공정"의 목적지.
  final IlDuLearningModule module;
  final VoidCallback onOpenModule;
}

class IlDuWorldScreen extends StatefulWidget {
  final IlDuManifestLoader? loadManifest;
  final IlDuLegacyProjectionLoader? loadProjection;
  final IlDuDecorationPlacementStore decorationStore;
  final IlDuAnchorPlacementStore anchorPlacementStore;

  /// 건설 플랜 로더. null 이면 번들 리포지토리. 로드 실패는 화면을 죽이지
  /// 않는다 — 렌더는 fail-open(기존 턴테이블), 데이터는 fail-closed.
  final IlDuConstructionPlanLoader? loadConstructionPlan;
  final IlDuConstructionProgressStore constructionProgressStore;

  const IlDuWorldScreen({
    super.key,
    this.loadManifest,
    this.loadProjection,
    this.decorationStore =
        const SharedPreferencesIlDuDecorationPlacementStore(),
    this.anchorPlacementStore =
        const SharedPreferencesIlDuAnchorPlacementStore(),
    this.loadConstructionPlan,
    this.constructionProgressStore =
        const SharedPreferencesIlDuConstructionProgressStore(),
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
  Map<String, double> _anchorScales = const <String, double>{};
  Matrix4? _anchorGestureMapTransform;
  bool _restoringAnchorMapTransform = false;
  String? _selectedBuildingId;
  String? _selectedGateId;
  bool _decorating = false;
  bool _anchorGestureActive = false;
  bool _mapPositioned = false;
  bool _anchorSaveInProgress = false;
  bool _anchorSaveRequested = false;
  Object? _loadError;
  late final IlDuConstructionPlanRepository _constructionPlanRepository =
      IlDuConstructionPlanRepository();
  IlDuEstateConstructionPlan? _constructionPlan;
  IlDuConstructionProgressService? _constructionProgress;

  @override
  void initState() {
    super.initState();
    _mapController.addListener(_holdMapDuringAnchorGesture);
    _load();
  }

  @override
  void dispose() {
    _mapController.removeListener(_holdMapDuringAnchorGesture);
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
        _anchorScales = <String, double>{
          for (final anchor in <IlDuWorldAnchor>[
            ...manifest.buildings,
            ...manifest.gates,
          ])
            if (ilduTurntableForAnchor(anchor.id) != null)
              anchor.id: savedAnchors[anchor.id]?.scale ?? 1,
        };
        _constructionPlan = null;
        _constructionProgress = null;
        _selectedBuildingId = manifest.buildings.first.id;
        _selectedGateId = null;
        _anchorGestureActive = false;
        _anchorGestureMapTransform = null;
        _mapPositioned = false;
      });
      // 건설 플랜·진행도는 월드 렌더를 막지 않는다 — 준비되는 대로 붙는다.
      unawaited(_attachConstruction());
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loadError = error);
    }
  }

  /// 건설 플랜·진행도 로드. 어느 쪽이든 실패하면 null — 사랑채는 기존
  /// 턴테이블로 렌더된다 (fail-open 렌더). 데이터 자체는 리포지토리·서비스가
  /// fail-closed 로 지킨다.
  Future<
    ({
      IlDuEstateConstructionPlan plan,
      IlDuConstructionProgressService progress,
    })?
  >
  _loadConstruction() async {
    try {
      final plan = await (widget.loadConstructionPlan ??
          _constructionPlanRepository.load)();
      final progress = IlDuConstructionProgressService(
        plan: plan,
        store: widget.constructionProgressStore,
      );
      await progress.initialize();
      return (plan: plan, progress: progress);
    } catch (_) {
      return null;
    }
  }

  Future<void> _attachConstruction() async {
    final construction = await _loadConstruction();
    if (!mounted || construction == null) {
      return;
    }
    setState(() {
      _constructionPlan = construction.plan;
      _constructionProgress = construction.progress;
    });
  }

  /// 진행도 저장소를 다시 읽는다 — 모듈 화면이 완료를 기록한 뒤 호출된다.
  Future<void> _reloadConstructionProgress() async {
    final progress = _constructionProgress;
    if (progress == null) {
      return;
    }
    try {
      await progress.initialize();
    } catch (_) {
      return;
    }
    if (mounted) {
      setState(() {});
    }
  }

  /// 앵커의 진행 중 건설 상태. 플랜이 없거나(로드 실패 포함) 이 앵커가 플랜
  /// 밖이거나 마지막 단계까지 완료(=해금)면 null.
  ({
    IlDuBuildingConstructionPlan building,
    IlDuConstructionStage stage,
    Set<String> completedStageIds,
    Set<String> completedModuleIds,
  })?
  _constructionStateFor(String anchorId) {
    final plan = _constructionPlan;
    final progress = _constructionProgress;
    if (plan == null || progress == null || !plan.hasBuilding(anchorId)) {
      return null;
    }
    final building = plan.buildingFor(anchorId);
    final record = progress.snapshot.anchorFor(anchorId);
    if (record != null && record.buildingId != anchorId) {
      return null;
    }
    final completedStages = record?.completedStageIds ?? const <String>{};
    if (completedStages.contains(building.stages.last.stageId)) {
      // 완공: 기존 8각도 턴테이블 복귀.
      return null;
    }
    return (
      building: building,
      stage: progress.currentStage(anchorId: anchorId, buildingId: anchorId),
      completedStageIds: completedStages,
      completedModuleIds: record?.completedModuleIds ?? const <String>{},
    );
  }

  Widget? _constructionLayerFor(
    IlDuWorldBuilding building,
    IlDuTurntableFrame frame,
  ) {
    final info = _constructionStateFor(building.id);
    if (info == null) {
      return null;
    }
    return IlDuConstructionStageLayer(
      key: ValueKey('ildu-construction-layer-${building.id}'),
      buildingId: info.building.buildingId,
      anchorId: building.id,
      building: info.building,
      currentStage: info.stage,
      completedStageCount: info.completedStageIds.length,
      completedFrame: frame,
    );
  }

  IlDuConstructionSheetInfo? _constructionSheetFor(IlDuWorldBuilding building) {
    final plan = _constructionPlan;
    final info = _constructionStateFor(building.id);
    if (plan == null || info == null) {
      return null;
    }
    final moduleId = info.stage.requiredModuleIds.firstWhere(
      (id) => !info.completedModuleIds.contains(id),
      orElse: () => info.stage.requiredModuleIds.first,
    );
    return IlDuConstructionSheetInfo(
      stage: info.stage,
      module: plan.moduleFor(moduleId),
      onOpenModule: () => unawaited(
        _openConstructionModule(anchorId: building.id, moduleId: moduleId),
      ),
    );
  }

  Future<void> _openConstructionModule({
    required String anchorId,
    required String moduleId,
  }) async {
    final result = await Navigator.of(context).pushNamed(
      '/hanok/module',
      arguments: IlDuLearningModuleArgs(
        anchorId: anchorId,
        buildingId: anchorId,
        moduleId: moduleId,
      ),
    );
    if (result == true) {
      await _reloadConstructionProgress();
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

  void _queueAnchorPlacementSave() {
    _anchorSaveRequested = true;
    if (_anchorSaveInProgress) {
      return;
    }
    _anchorSaveInProgress = true;
    unawaited(_drainAnchorPlacementSaves());
  }

  Future<void> _drainAnchorPlacementSaves() async {
    var latestSaveFailed = false;
    while (_anchorSaveRequested) {
      _anchorSaveRequested = false;
      final snapshot = List<IlDuAnchorPlacement>.unmodifiable(
        _anchorPlacements,
      );
      try {
        await widget.anchorPlacementStore.save(snapshot);
        latestSaveFailed = false;
      } catch (_) {
        latestSaveFailed = true;
      }
    }
    _anchorSaveInProgress = false;
    if (!latestSaveFailed || !mounted) {
      return;
    }
    final t = AppL10n.of(context);
    soriToast(context, t.ilduWorldSaveError);
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
    final scale = _anchorScales[anchorId] ?? 1;
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
          scale: scale,
        ),
      );
    });
    _queueAnchorPlacementSave();
  }

  void _transformAnchor(IlDuAnchorPlacement placement) {
    final turntable = ilduTurntableForAnchor(placement.anchorId);
    if (turntable == null) {
      return;
    }
    setState(() {
      _anchorPositions = <String, Offset>{
        ..._anchorPositions,
        placement.anchorId: Offset(placement.x, placement.y),
      };
      _anchorScales = <String, double>{
        ..._anchorScales,
        placement.anchorId: placement.scale,
      };
      _upsertAnchorPlacement(placement);
    });
  }

  void _resizeAnchor(
    IlDuWorldAnchor anchor,
    double proposedScale,
    Size mapSize,
  ) {
    final turntable = ilduTurntableForAnchor(anchor.id);
    if (turntable == null) {
      return;
    }
    final currentPosition =
        _anchorPositions[anchor.id] ?? Offset(anchor.x, anchor.y);
    final direction =
        _anchorDirections[anchor.id] ??
        turntable.directionForDegrees(anchor.rotation);
    final currentScale = _anchorScales[anchor.id] ?? 1;
    final baseHeightPercent =
        (mapSize.width * anchor.width / 100 / turntable.mapAspectRatio) /
        mapSize.height *
        100;
    final resized = resizeIlDuAnchor(
      placement: IlDuAnchorPlacement(
        anchorId: anchor.id,
        x: currentPosition.dx,
        y: currentPosition.dy,
        direction: direction,
        scale: currentScale,
      ),
      proposedScale: proposedScale,
      baseWidthPercent: anchor.width,
      baseHeightPercent: baseHeightPercent,
    );
    _transformAnchor(resized);
  }

  void _finishAnchorTransform(IlDuAnchorPlacement placement) {
    _transformAnchor(placement);
    _queueAnchorPlacementSave();
  }

  void _startAnchorGesture() {
    if (mounted && !_anchorGestureActive) {
      setState(() {
        _anchorGestureMapTransform = Matrix4.copy(_mapController.value);
        _anchorGestureActive = true;
      });
    }
  }

  void _finishAnchorGesture() {
    if (mounted && _anchorGestureActive) {
      _holdMapDuringAnchorGesture();
      setState(() {
        _anchorGestureActive = false;
        _anchorGestureMapTransform = null;
      });
    }
  }

  void _holdMapDuringAnchorGesture() {
    final frozen = _anchorGestureMapTransform;
    if (!_anchorGestureActive ||
        frozen == null ||
        _restoringAnchorMapTransform ||
        _sameMatrix(_mapController.value, frozen)) {
      return;
    }
    _restoringAnchorMapTransform = true;
    _mapController.value = Matrix4.copy(frozen);
    _restoringAnchorMapTransform = false;
  }

  bool _sameMatrix(Matrix4 left, Matrix4 right) {
    for (var index = 0; index < 16; index += 1) {
      if (left.storage[index] != right.storage[index]) {
        return false;
      }
    }
    return true;
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
              anchorScales: _anchorScales,
              anchorGestureActive: _anchorGestureActive,
              mapController: _mapController,
              onPositionMap: _positionMapOnce,
              onSelectBuilding: _selectBuilding,
              onSelectGate: _selectGate,
              onTurnAnchor: _turnAnchor,
              onTransformAnchor: _transformAnchor,
              onFinishTransformAnchor: _finishAnchorTransform,
              onStartAnchorGesture: _startAnchorGesture,
              onFinishAnchorGesture: _finishAnchorGesture,
              onResizeAnchor: _resizeAnchor,
              onFinishMoveAnchor: _queueAnchorPlacementSave,
              onStartDecorating: () => setState(() => _decorating = true),
              onFinishDecorating: () => setState(() => _decorating = false),
              onAddDecoration: _addDecoration,
              onMoveDecoration: _moveDecoration,
              onFinishMove: () => unawaited(_persistPlacements()),
              onOpenRoute: _openRoute,
              constructionLayerFor: _constructionLayerFor,
              constructionSheetFor: _constructionSheetFor,
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
  final Map<String, double> anchorScales;
  final bool anchorGestureActive;
  final TransformationController mapController;
  final void Function(Size viewport, Size mapSize) onPositionMap;
  final ValueChanged<IlDuWorldBuilding> onSelectBuilding;
  final ValueChanged<IlDuWorldGate> onSelectGate;
  final void Function(String anchorId, int direction) onTurnAnchor;
  final ValueChanged<IlDuAnchorPlacement> onTransformAnchor;
  final ValueChanged<IlDuAnchorPlacement> onFinishTransformAnchor;
  final VoidCallback onStartAnchorGesture;
  final VoidCallback onFinishAnchorGesture;
  final void Function(IlDuWorldAnchor anchor, double scale, Size mapSize)
  onResizeAnchor;
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
  final Widget? Function(IlDuWorldBuilding building, IlDuTurntableFrame frame)
  constructionLayerFor;
  final IlDuConstructionSheetInfo? Function(IlDuWorldBuilding building)
  constructionSheetFor;

  const _WorldBody({
    required this.manifest,
    required this.projection,
    required this.selectedBuildingId,
    required this.selectedGateId,
    required this.decorating,
    required this.placements,
    required this.anchorPositions,
    required this.anchorDirections,
    required this.anchorScales,
    required this.anchorGestureActive,
    required this.mapController,
    required this.onPositionMap,
    required this.onSelectBuilding,
    required this.onSelectGate,
    required this.onTurnAnchor,
    required this.onTransformAnchor,
    required this.onFinishTransformAnchor,
    required this.onStartAnchorGesture,
    required this.onFinishAnchorGesture,
    required this.onResizeAnchor,
    required this.onFinishMoveAnchor,
    required this.onStartDecorating,
    required this.onFinishDecorating,
    required this.onAddDecoration,
    required this.onMoveDecoration,
    required this.onFinishMove,
    required this.onOpenRoute,
    required this.constructionLayerFor,
    required this.constructionSheetFor,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    Size mapSizeForWidth(double viewportWidth) {
      final mapWidth = math.max(
        manifest.canvas.mobileContentWidth.toDouble(),
        viewportWidth,
      );
      return Size(
        mapWidth,
        mapWidth * manifest.canvas.height / manifest.canvas.width,
      );
    }

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
                    final mapSize = mapSizeForWidth(constraints.maxWidth);
                    onPositionMap(viewport, mapSize);
                    return ColoredBox(
                      color: const Color(0xFFE9D9BC),
                      child: InteractiveViewer(
                        transformationController: mapController,
                        constrained: false,
                        minScale: 1,
                        maxScale: 2.2,
                        panEnabled: !anchorGestureActive,
                        scaleEnabled: !anchorGestureActive,
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
                            anchorScales: anchorScales,
                            mapSize: mapSize,
                            mapController: mapController,
                            onSelectBuilding: onSelectBuilding,
                            onSelectGate: onSelectGate,
                            onTransformAnchor: onTransformAnchor,
                            onFinishTransformAnchor: onFinishTransformAnchor,
                            onStartAnchorGesture: onStartAnchorGesture,
                            onFinishAnchorGesture: onFinishAnchorGesture,
                            onMoveDecoration: onMoveDecoration,
                            onFinishMove: onFinishMove,
                            constructionLayerFor: constructionLayerFor,
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
                        construction: constructionSheetFor(selectedBuilding),
                        decorating: decorating,
                        onStartDecorating: onStartDecorating,
                        onFinishDecorating: onFinishDecorating,
                        onAddDecoration: onAddDecoration,
                        direction: anchorDirections[selectedBuilding.id],
                        scale: anchorScales[selectedBuilding.id] ?? 1,
                        onDirectionChanged: (direction) =>
                            onTurnAnchor(selectedBuilding.id, direction),
                        onScaleChanged: (scale) => onResizeAnchor(
                          selectedBuilding,
                          scale,
                          mapSizeForWidth(MediaQuery.sizeOf(context).width),
                        ),
                        onScaleChangeEnd: onFinishMoveAnchor,
                        onOpenRoute: onOpenRoute,
                      )
                    : _GateSheet(
                        projection: projection,
                        gate: selectedGate,
                        direction: anchorDirections[selectedGate.id],
                        scale: anchorScales[selectedGate.id] ?? 1,
                        onDirectionChanged: (direction) =>
                            onTurnAnchor(selectedGate.id, direction),
                        onScaleChanged: (scale) => onResizeAnchor(
                          selectedGate,
                          scale,
                          mapSizeForWidth(MediaQuery.sizeOf(context).width),
                        ),
                        onScaleChangeEnd: onFinishMoveAnchor,
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
  final Map<String, double> anchorScales;
  final Size mapSize;
  final TransformationController mapController;
  final ValueChanged<IlDuWorldBuilding> onSelectBuilding;
  final ValueChanged<IlDuWorldGate> onSelectGate;
  final ValueChanged<IlDuAnchorPlacement> onTransformAnchor;
  final ValueChanged<IlDuAnchorPlacement> onFinishTransformAnchor;
  final VoidCallback onStartAnchorGesture;
  final VoidCallback onFinishAnchorGesture;
  final void Function(IlDuDecorationPlacement, Offset, Size) onMoveDecoration;
  final VoidCallback onFinishMove;
  final Widget? Function(IlDuWorldBuilding building, IlDuTurntableFrame frame)
  constructionLayerFor;

  const _EstateMap({
    required this.manifest,
    required this.projection,
    required this.selectedAnchorId,
    required this.placements,
    required this.anchorPositions,
    required this.anchorDirections,
    required this.anchorScales,
    required this.mapSize,
    required this.mapController,
    required this.onSelectBuilding,
    required this.onSelectGate,
    required this.onTransformAnchor,
    required this.onFinishTransformAnchor,
    required this.onStartAnchorGesture,
    required this.onFinishAnchorGesture,
    required this.onMoveDecoration,
    required this.onFinishMove,
    required this.constructionLayerFor,
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
    final position =
        anchorPositions[building.id] ?? Offset(building.x, building.y);
    final scale = anchorScales[building.id] ?? 1;
    final frame = turntable == null || direction == null
        ? null
        : turntable.frames[direction];
    final available = projection.isAvailable(building.unlockEra);
    return _MapAnchor(
      key: ValueKey('ildu-map-turntable-${building.id}-$direction'),
      anchor: building,
      mapSize: mapSize,
      mapController: mapController,
      available: available,
      selected: selectedAnchorId == building.id,
      placement: direction == null
          ? null
          : IlDuAnchorPlacement(
              anchorId: building.id,
              x: position.dx,
              y: position.dy,
              direction: direction,
              scale: scale,
            ),
      assetPath: manifest.worldAsset(building.asset),
      turntableFrame: frame,
      turntableAspectRatio: turntable?.mapAspectRatio,
      constructionLayer: frame == null || !available
          ? null
          : constructionLayerFor(building, frame),
      onTap: () => onSelectBuilding(building),
      onTransform: onTransformAnchor,
      onTransformEnd: onFinishTransformAnchor,
      onInteractionStart: onStartAnchorGesture,
      onInteractionEnd: onFinishAnchorGesture,
    );
  }

  Widget _gateAnchor(IlDuWorldGate gate) {
    final turntable = ilduTurntableForAnchor(gate.id);
    final direction =
        anchorDirections[gate.id] ??
        turntable?.directionForDegrees(gate.rotation);
    final position = anchorPositions[gate.id] ?? Offset(gate.x, gate.y);
    final scale = anchorScales[gate.id] ?? 1;
    return _MapAnchor(
      key: ValueKey('ildu-map-turntable-${gate.id}-$direction'),
      anchor: gate,
      mapSize: mapSize,
      mapController: mapController,
      available: projection.isAvailable(gate.unlockEra),
      selected: selectedAnchorId == gate.id,
      placement: direction == null
          ? null
          : IlDuAnchorPlacement(
              anchorId: gate.id,
              x: position.dx,
              y: position.dy,
              direction: direction,
              scale: scale,
            ),
      assetPath: manifest.worldAsset(gate.asset),
      turntableFrame: turntable == null || direction == null
          ? null
          : turntable.frames[direction],
      turntableAspectRatio: turntable?.mapAspectRatio,
      onTap: () => onSelectGate(gate),
      onTransform: onTransformAnchor,
      onTransformEnd: onFinishTransformAnchor,
      onInteractionStart: onStartAnchorGesture,
      onInteractionEnd: onFinishAnchorGesture,
    );
  }
}

class _MapAnchor extends StatefulWidget {
  final IlDuWorldAnchor anchor;
  final Size mapSize;
  final TransformationController mapController;
  final bool available;
  final bool selected;
  final String assetPath;
  final IlDuAnchorPlacement? placement;
  final IlDuTurntableFrame? turntableFrame;
  final double? turntableAspectRatio;

  /// 진행 중인 건설 렌더. null 이면 기존 턴테이블 프레임 그대로 —
  /// 플랜 로드 실패·완공 해금 모두 이 경로로 복귀한다.
  final Widget? constructionLayer;
  final VoidCallback? onTap;
  final ValueChanged<IlDuAnchorPlacement>? onTransform;
  final ValueChanged<IlDuAnchorPlacement>? onTransformEnd;
  final VoidCallback? onInteractionStart;
  final VoidCallback? onInteractionEnd;

  const _MapAnchor({
    super.key,
    required this.anchor,
    required this.mapSize,
    required this.mapController,
    required this.available,
    required this.assetPath,
    this.placement,
    this.turntableFrame,
    this.turntableAspectRatio,
    this.constructionLayer,
    this.selected = false,
    this.onTap,
    this.onTransform,
    this.onTransformEnd,
    this.onInteractionStart,
    this.onInteractionEnd,
  });

  @override
  State<_MapAnchor> createState() => _MapAnchorState();
}

class _MapAnchorState extends State<_MapAnchor> {
  final _AnchorGestureSession _gestureSession = _AnchorGestureSession();

  @override
  void dispose() {
    final onInteractionEnd = widget.onInteractionEnd;
    if (_gestureSession.interactionActive && onInteractionEnd != null) {
      scheduleMicrotask(onInteractionEnd);
    }
    super.dispose();
  }

  bool get _canTransform =>
      widget.available &&
      widget.placement != null &&
      widget.turntableAspectRatio != null &&
      widget.onTransform != null;

  void _trackPointerDown(PointerDownEvent event) {
    if (_gestureSession.pointerPositions.isEmpty) {
      _gestureSession.selectionInvoked = true;
      widget.onTap?.call();
      if (_canTransform) {
        _gestureSession.interactionActive = true;
        widget.onInteractionStart?.call();
      }
    }
    _gestureSession.pointerPositions[event.pointer] = event.position;
    _rebasePointerSegment();
  }

  void _handleTap() {
    if (!_gestureSession.selectionInvoked) {
      widget.onTap?.call();
    }
  }

  void _trackPointerMove(PointerMoveEvent event) {
    if (!_gestureSession.pointerPositions.containsKey(event.pointer) ||
        !_canTransform) {
      return;
    }
    _gestureSession.pointerPositions[event.pointer] = event.position;
    _updatePointerTransform();
  }

  void _trackPointerDone(PointerEvent event) {
    if (!_gestureSession.pointerPositions.containsKey(event.pointer)) {
      return;
    }
    _gestureSession.pointerPositions.remove(event.pointer);
    if (_gestureSession.pointerPositions.isNotEmpty) {
      _rebasePointerSegment();
      return;
    }
    scheduleMicrotask(() {
      if (!mounted || _gestureSession.pointerPositions.isNotEmpty) {
        return;
      }
      final finalPlacement = _gestureSession.draft;
      final changed = _gestureSession.changed;
      final interactionActive = _gestureSession.interactionActive;
      _gestureSession.reset();
      if (changed && finalPlacement != null) {
        widget.onTransformEnd?.call(finalPlacement);
      }
      if (interactionActive) {
        widget.onInteractionEnd?.call();
      }
    });
  }

  void _rebasePointerSegment() {
    final start = _gestureSession.draft ?? widget.placement;
    if (start == null || _gestureSession.pointerPositions.isEmpty) {
      return;
    }
    _gestureSession
      ..start = start
      ..draft = start
      ..focalStart = _pointerCentroid()
      ..spanStart = _pointerSpan();
  }

  Offset _pointerCentroid() {
    var total = Offset.zero;
    for (final position in _gestureSession.pointerPositions.values) {
      total += position;
    }
    return total / _gestureSession.pointerPositions.length.toDouble();
  }

  double? _pointerSpan() {
    if (_gestureSession.pointerPositions.length < 2) {
      return null;
    }
    final positions = _gestureSession.pointerPositions.values.toList(
      growable: false,
    );
    return (positions[0] - positions[1]).distance;
  }

  void _updatePointerTransform() {
    final start = _gestureSession.start;
    final focalStart = _gestureSession.focalStart;
    final aspectRatio = widget.turntableAspectRatio;
    if (start == null || focalStart == null || aspectRatio == null) {
      return;
    }
    final zoom = widget.mapController.value.getMaxScaleOnAxis();
    final safeZoom = zoom.isFinite && zoom > 0 ? zoom : 1.0;
    final mapDelta = (_pointerCentroid() - focalStart) / safeZoom;
    final spanStart = _gestureSession.spanStart;
    final span = _pointerSpan();
    final scaleFactor = spanStart != null && spanStart > 0 && span != null
        ? span / spanStart
        : 1.0;
    final updated = transformIlDuAnchor(
      placement: start,
      proposedX: start.x + mapDelta.dx / widget.mapSize.width * 100,
      proposedY: start.y + mapDelta.dy / widget.mapSize.height * 100,
      proposedScale: start.scale * scaleFactor,
      baseWidthPercent: widget.anchor.width,
      baseHeightPercent:
          (widget.mapSize.width * widget.anchor.width / 100 / aspectRatio) /
          widget.mapSize.height *
          100,
    );
    final previous = _gestureSession.draft;
    if (previous != null &&
        updated.x == previous.x &&
        updated.y == previous.y &&
        updated.scale == previous.scale) {
      return;
    }
    _gestureSession
      ..draft = updated
      ..changed = true;
    widget.onTransform?.call(updated);
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.placement?.scale ?? 1;
    final width = widget.mapSize.width * widget.anchor.width / 100 * scale;
    final center = widget.placement == null
        ? Offset(widget.anchor.x, widget.anchor.y)
        : Offset(widget.placement!.x, widget.placement!.y);
    final frame = widget.turntableFrame;
    final image = frame == null
        ? Image.asset(
            widget.assetPath,
            width: width,
            fit: BoxFit.contain,
            cacheWidth: widget.onTap == null ? 180 : 360,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          )
        : SizedBox(
            width: width,
            height: width / widget.turntableAspectRatio!,
            child:
                widget.constructionLayer ??
                HanokTurntableFrameImage(frame: frame, cacheWidth: 360),
          );
    final visual = AnimatedOpacity(
      opacity: widget.available ? 1 : .18,
      duration: const Duration(milliseconds: 260),
      child: ColorFiltered(
        colorFilter: widget.available
            ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
            : const ColorFilter.mode(Color(0xFF9A8A70), BlendMode.saturation),
        child: image,
      ),
    );
    final content = Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (widget.selected)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: SoriColors.accent, width: 2),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        Padding(padding: const EdgeInsets.all(Spacing.xs), child: visual),
        if (!widget.available && widget.onTap != null)
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
      left: widget.mapSize.width * center.dx / 100,
      top: widget.mapSize.height * center.dy / 100,
      child: FractionalTranslation(
        translation: const Offset(-.5, -.5),
        child: Transform.rotate(
          angle: frame == null ? widget.anchor.rotation * math.pi / 180 : 0,
          child: widget.onTap == null
              ? content
              : Semantics(
                  button: true,
                  label: widget.anchor.ko,
                  value: '${(scale * 100).round()}%',
                  onTap: widget.onTap,
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _handleTap,
                    child: Listener(
                      key: ValueKey('ildu-anchor-gesture-${widget.anchor.id}'),
                      behavior: HitTestBehavior.translucent,
                      onPointerDown: _trackPointerDown,
                      onPointerMove: _trackPointerMove,
                      onPointerUp: _trackPointerDone,
                      onPointerCancel: _trackPointerDone,
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
      ),
    );
  }
}

class _AnchorGestureSession {
  final Map<int, Offset> pointerPositions = <int, Offset>{};
  IlDuAnchorPlacement? start;
  IlDuAnchorPlacement? draft;
  Offset? focalStart;
  double? spanStart;
  bool changed = false;
  bool interactionActive = false;
  bool selectionInvoked = false;

  void reset() {
    pointerPositions.clear();
    start = null;
    draft = null;
    focalStart = null;
    spanStart = null;
    changed = false;
    interactionActive = false;
    selectionInvoked = false;
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
  final double scale;
  final ValueChanged<int> onDirectionChanged;
  final ValueChanged<double> onScaleChanged;
  final VoidCallback onScaleChangeEnd;

  const _GateSheet({
    required this.projection,
    required this.gate,
    required this.direction,
    required this.scale,
    required this.onDirectionChanged,
    required this.onScaleChanged,
    required this.onScaleChangeEnd,
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
              ? Spacing.xxxl * 6 + Spacing.xl
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
                  _AnchorScaleControl(
                    anchorId: gate.id,
                    scale: scale,
                    onChanged: onScaleChanged,
                    onChangeEnd: onScaleChangeEnd,
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

  /// 진행 중 건설 정보. null 이면 기존 추천 미션 블록을 그대로 그린다.
  final IlDuConstructionSheetInfo? construction;
  final bool decorating;
  final VoidCallback onStartDecorating;
  final VoidCallback onFinishDecorating;
  final ValueChanged<IlDuWorldDecoration> onAddDecoration;
  final int? direction;
  final double scale;
  final ValueChanged<int> onDirectionChanged;
  final ValueChanged<double> onScaleChanged;
  final VoidCallback onScaleChangeEnd;
  final ValueChanged<String> onOpenRoute;

  const _PlaceSheet({
    required this.manifest,
    required this.projection,
    required this.building,
    required this.construction,
    required this.decorating,
    required this.onStartDecorating,
    required this.onFinishDecorating,
    required this.onAddDecoration,
    required this.direction,
    required this.scale,
    required this.onDirectionChanged,
    required this.onScaleChanged,
    required this.onScaleChangeEnd,
    required this.onOpenRoute,
  });

  /// 모듈 콘텐츠는 플랜 JSON 의 ko/de/en 을 앱 로케일로 고른다.
  String _constructionModuleTitle(BuildContext context) {
    final module = construction!.module;
    final languageCode = Localizations.localeOf(context).languageCode;
    final copy =
        module.copyByLanguage[languageCode] ?? module.copyByLanguage['en']!;
    return copy.title;
  }

  Widget _secondaryActions(AppL10n t, IlDuWorldHub hub) => Row(
    children: [
      Expanded(
        child: TextButton(
          onPressed: () => onOpenRoute(hub.secondaryRoutes.first),
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
          onPressed: () => onOpenRoute(hub.secondaryRoutes.last),
          child: Text(t.ilduWorldCulture),
        ),
      ),
    ],
  );

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
              ? Spacing.xxxl * 9 + Spacing.sm
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
                        const SizedBox(height: Spacing.xs),
                        _AnchorScaleControl(
                          anchorId: building.id,
                          scale: scale,
                          onChanged: onScaleChanged,
                          onChangeEnd: onScaleChangeEnd,
                        ),
                      ],
                      const SizedBox(height: Spacing.sm),
                      if (available && construction != null)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${t.ilduWorldConstructionCurrent} · '
                                '${ilduProcessTagLabel(t, construction!.stage.processTags.first)}',
                                key: const ValueKey(
                                  'ildu-construction-process-tag',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: SoriTextTheme.of(context).eyebrow,
                              ),
                              Text(
                                _constructionModuleTitle(context),
                                key: const ValueKey(
                                  'ildu-construction-stage-title',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: SoriTextTheme.of(context).cardTitle,
                              ),
                              const Spacer(),
                              SizedBox(
                                width: double.infinity,
                                height: Spacing.xxxl,
                                child: FilledButton(
                                  key: const ValueKey(
                                    'ildu-construction-next-cta',
                                  ),
                                  onPressed: construction!.onOpenModule,
                                  child: Text(t.ilduWorldConstructionNextCta),
                                ),
                              ),
                              const SizedBox(height: Spacing.xs),
                              _secondaryActions(t, hub),
                            ],
                          ),
                        )
                      else if (available)
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
                              _secondaryActions(t, hub),
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

class _AnchorScaleControl extends StatelessWidget {
  final String anchorId;
  final double scale;
  final ValueChanged<double> onChanged;
  final VoidCallback onChangeEnd;

  const _AnchorScaleControl({
    required this.anchorId,
    required this.scale,
    required this.onChanged,
    required this.onChangeEnd,
  });

  double _bounded(double value) => value
      .clamp(IlDuAnchorPlacement.minimumScale, IlDuAnchorPlacement.maximumScale)
      .toDouble();

  void _changeBy(double delta) {
    onChanged(_bounded(scale + delta));
    onChangeEnd();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final boundedScale = _bounded(scale);
    final percent = (boundedScale * 100).round();
    return Semantics(
      container: true,
      label: t.ilduWorldBuildingScale,
      value: '$percent%',
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            IconButton(
              key: ValueKey('ildu-scale-decrease-$anchorId'),
              tooltip: t.ilduWorldShrinkBuilding,
              onPressed: boundedScale > IlDuAnchorPlacement.minimumScale
                  ? () => _changeBy(-IlDuAnchorPlacement.scaleStep)
                  : null,
              icon: const Icon(Icons.remove),
            ),
            Expanded(
              child: Slider(
                key: ValueKey('ildu-scale-slider-$anchorId'),
                value: boundedScale,
                min: IlDuAnchorPlacement.minimumScale,
                max: IlDuAnchorPlacement.maximumScale,
                divisions: 19,
                label: '$percent%',
                semanticFormatterCallback: (value) =>
                    '${(value * 100).round()}%',
                onChanged: onChanged,
                onChangeEnd: (_) => onChangeEnd(),
              ),
            ),
            IconButton(
              key: ValueKey('ildu-scale-increase-$anchorId'),
              tooltip: t.ilduWorldEnlargeBuilding,
              onPressed: boundedScale < IlDuAnchorPlacement.maximumScale
                  ? () => _changeBy(IlDuAnchorPlacement.scaleStep)
                  : null,
              icon: const Icon(Icons.add),
            ),
            SizedBox(
              width: 44,
              child: Text(
                '$percent%',
                textAlign: TextAlign.end,
                style: SoriTextTheme.of(context).label,
              ),
            ),
          ],
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
