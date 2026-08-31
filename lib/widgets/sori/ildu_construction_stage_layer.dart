import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/ildu_turntable_catalog.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/ildu_construction_plan.dart';
import 'hanok_turntable_2d.dart';
import 'tokens.dart';

/// 단계 에셋이 승격되면 살게 될 폴더. 아직 pubspec 에 등록된 파일이 없으므로
/// 현재 릴리스의 1차 렌더 경로는 고스트 모드다 (Phase 3 계약).
const String kIlDuConstructionStageAssetRoot =
    'assets/illustrations/personal_hanok_v3/construction/';

String ilduConstructionStageAssetPath(String buildingId, String fileName) =>
    '$kIlDuConstructionStageAssetRoot$buildingId/$fileName';

/// 공통 공정 어휘의 UI 크롬 라벨. 콘텐츠(플랜 JSON)가 아니라 크롬이므로
/// arb 로 현지화한다.
String ilduProcessTagLabel(AppL10n t, IlDuProcessTag tag) => switch (tag) {
  IlDuProcessTag.site => t.ilduProcessSite,
  IlDuProcessTag.foundation => t.ilduProcessFoundation,
  IlDuProcessTag.framePosts => t.ilduProcessFramePosts,
  IlDuProcessTag.frameBeams => t.ilduProcessFrameBeams,
  IlDuProcessTag.raftersSanja => t.ilduProcessRaftersSanja,
  IlDuProcessTag.roofBed => t.ilduProcessRoofBed,
  IlDuProcessTag.roofTiles => t.ilduProcessRoofTiles,
  IlDuProcessTag.floorNumaru => t.ilduProcessFloorNumaru,
  IlDuProcessTag.wallInfill => t.ilduProcessWallInfill,
  IlDuProcessTag.doorsChangho => t.ilduProcessDoorsChangho,
  IlDuProcessTag.identityFinish => t.ilduProcessIdentityFinish,
  IlDuProcessTag.complete => t.ilduProcessComplete,
};

/// A1 카탈로그(181~233행)의 상주 창 패턴 이식: fallback(직전)·현재·다음
/// 단계만 디코드 상주 대상이다 — 최대 3단계.
List<IlDuConstructionStage> ilduConstructionResidentStages(
  IlDuBuildingConstructionPlan building,
  String currentStageId,
) {
  final index = building.stages.indexWhere(
    (stage) => stage.stageId == currentStageId,
  );
  if (index < 0) {
    return const [];
  }
  final current = building.stages[index];
  final resident = <IlDuConstructionStage>[];
  final fallbackId = current.fallbackStageId;
  if (fallbackId != null) {
    resident.add(building.stageFor(fallbackId));
  }
  resident.add(current);
  if (index + 1 < building.stages.length) {
    resident.add(building.stages[index + 1]);
  }
  return List.unmodifiable(resident);
}

/// 상주 창 밖의 모든 단계 에셋 경로 — ImageCache 축출 대상.
/// 전역 캐시를 비우지 않고 이 건물의 비상주 경로만 겨냥한다.
List<String> ilduConstructionEvictionTargets({
  required IlDuBuildingConstructionPlan building,
  required String currentStageId,
}) {
  final residentPaths = <String>{
    for (final stage in ilduConstructionResidentStages(
      building,
      currentStageId,
    ))
      ..._stageAssetPaths(building.buildingId, stage),
  };
  final targets = <String>[];
  final seen = <String>{};
  for (final stage in building.stages) {
    for (final path in _stageAssetPaths(building.buildingId, stage)) {
      if (!residentPaths.contains(path) && seen.add(path)) {
        targets.add(path);
      }
    }
  }
  return targets;
}

List<String> _stageAssetPaths(String buildingId, IlDuConstructionStage stage) =>
    [
      ilduConstructionStageAssetPath(buildingId, stage.baseAsset),
      for (final overlay in stage.overlayAssets)
        ilduConstructionStageAssetPath(buildingId, overlay),
    ];

/// 고스트 모드에서 완성 스프라이트를 아래(하부 공정)부터 위로 드러내는
/// 클리퍼. fraction 0 = 아무것도 안 보임, 1 = 전부.
class IlDuGhostRevealClipper extends CustomClipper<Rect> {
  const IlDuGhostRevealClipper(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(
    0,
    size.height * (1 - fraction.clamp(0.0, 1.0)),
    size.width,
    size.height,
  );

  @override
  bool shouldReclip(IlDuGhostRevealClipper oldClipper) =>
      oldClipper.fraction != fraction;
}

/// 사랑채(및 이후 건물) 건설 단계의 지도 렌더 레이어.
///
/// 렌더 우선순위 (Phase 3, 설계 §14):
/// 1. 현재 단계의 baseAsset 이 번들에 있으면 base + overlay Stack.
///    에셋이 없거나 실패하면 fallbackStageId 체인을 따라 **더 이른** 정상
///    단계를 유지한다 — 일반 한옥 대체물은 절대 표시하지 않는다.
/// 2. 체인 전체가 비어 있으면(현재 릴리스 기본) **고스트 모드**: 완성
///    턴테이블 스프라이트를 단계 진행률에 따라 하부→상부로 드러내고, 미완
///    부분은 저채도 실루엣(불투명도 .25)으로 남긴다. 신규 에셋 0장.
class IlDuConstructionStageLayer extends StatefulWidget {
  const IlDuConstructionStageLayer({
    super.key,
    required this.buildingId,
    required this.anchorId,
    required this.building,
    required this.currentStage,
    required this.completedStageCount,
    required this.completedFrame,
    this.cacheWidth = 360,
    this.bundle,
  });

  final String buildingId;
  final String anchorId;
  final IlDuBuildingConstructionPlan building;
  final IlDuConstructionStage currentStage;
  final int completedStageCount;

  /// 기존 8각도 턴테이블의 현재 방향 프레임 — 고스트 모드의 유일한 소스.
  final IlDuTurntableFrame completedFrame;
  final int cacheWidth;

  /// 테스트가 단계 에셋 존재 여부를 주입하는 경계. null 이면 rootBundle.
  final AssetBundle? bundle;

  @override
  State<IlDuConstructionStageLayer> createState() =>
      IlDuConstructionStageLayerState();
}

class IlDuConstructionStageLayerState
    extends State<IlDuConstructionStageLayer> {
  static const _luminanceDesaturate = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0,
  ]);

  final Map<String, bool> _assetAvailability = <String, bool>{};
  final Set<String> _touchedAssetPaths = <String>{};
  IlDuConstructionStage? _effectiveStage;
  int _resolveGeneration = 0;

  @visibleForTesting
  IlDuConstructionStage? get effectiveStage => _effectiveStage;

  @visibleForTesting
  double get revealFraction => widget.building.stages.isEmpty
      ? 0
      : (widget.completedStageCount / widget.building.stages.length)
            .clamp(0.0, 1.0)
            .toDouble();

  AssetBundle get _bundle => widget.bundle ?? rootBundle;

  @override
  void initState() {
    super.initState();
    _resolveEffectiveStage();
  }

  @override
  void didUpdateWidget(IlDuConstructionStageLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStage.stageId != widget.currentStage.stageId ||
        oldWidget.buildingId != widget.buildingId) {
      _resolveEffectiveStage();
    }
  }

  @override
  void dispose() {
    _resolveGeneration += 1;
    for (final path in _touchedAssetPaths) {
      _evictPath(path);
    }
    _touchedAssetPaths.clear();
    super.dispose();
  }

  /// 현재 단계에서 fallback 체인을 따라 내려가며 모든 에셋(base+overlay)이
  /// 실재하는 첫 단계를 찾는다. 없으면 null — 고스트 모드.
  Future<void> _resolveEffectiveStage() async {
    final generation = ++_resolveGeneration;
    IlDuConstructionStage? candidate = widget.currentStage;
    IlDuConstructionStage? resolved;
    while (candidate != null) {
      if (await _stageAssetsAvailable(candidate)) {
        resolved = candidate;
        break;
      }
      final fallbackId = candidate.fallbackStageId;
      candidate = fallbackId == null
          ? null
          : widget.building.stageFor(fallbackId);
    }
    if (!mounted || generation != _resolveGeneration) {
      return;
    }
    setState(() => _effectiveStage = resolved);
    _evictNonResidentStageAssets();
  }

  Future<bool> _stageAssetsAvailable(IlDuConstructionStage stage) async {
    for (final path in _stageAssetPaths(widget.buildingId, stage)) {
      if (!await _assetAvailable(path)) {
        return false;
      }
    }
    return true;
  }

  Future<bool> _assetAvailable(String path) async {
    final known = _assetAvailability[path];
    if (known != null) {
      return known;
    }
    var available = false;
    try {
      await _bundle.load(path);
      available = true;
    } catch (_) {
      available = false;
    }
    _assetAvailability[path] = available;
    return available;
  }

  /// 상주 창(직전 fallback·현재·다음, 최대 3단계) 밖에서 이미 디코드를
  /// 건드린 경로를 ImageCache 에서 겨냥 축출한다.
  void _evictNonResidentStageAssets() {
    final effective = _effectiveStage;
    if (effective == null) {
      return;
    }
    final targets = ilduConstructionEvictionTargets(
      building: widget.building,
      currentStageId: effective.stageId,
    );
    for (final path in targets) {
      if (_touchedAssetPaths.remove(path)) {
        _evictPath(path);
      }
    }
  }

  void _evictPath(String path) {
    final image = AssetImage(path, bundle: widget.bundle);
    unawaited(ResizeImage(image, width: widget.cacheWidth).evict());
    unawaited(image.evict());
  }

  /// 렌더 시점 디코드 실패: 그 단계를 불가로 기록하고 체인을 다시 푼다.
  /// 재해결이 끝날 때까지는 고스트가 임시 표면이다 — 대체물 금지 유지.
  void _markStageAssetBroken(IlDuConstructionStage stage) {
    var changed = false;
    for (final path in _stageAssetPaths(widget.buildingId, stage)) {
      if (_assetAvailability[path] != false) {
        _assetAvailability[path] = false;
        changed = true;
      }
    }
    if (changed) {
      scheduleMicrotask(() {
        if (mounted) {
          _resolveEffectiveStage();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stage = _effectiveStage;
    if (stage == null) {
      return _buildGhost(context);
    }
    return _buildStageStack(stage);
  }

  Widget _buildStageStack(IlDuConstructionStage stage) {
    final paths = _stageAssetPaths(widget.buildingId, stage);
    _touchedAssetPaths.addAll(paths);
    return RepaintBoundary(
      key: ValueKey('ildu-construction-stage-${stage.stageId}'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final path in paths)
            Image.asset(
              path,
              bundle: widget.bundle,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              cacheWidth: widget.cacheWidth,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) {
                _markStageAssetBroken(stage);
                return const SizedBox.shrink();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildGhost(BuildContext context) {
    final fraction = revealFraction;
    final frameImage = HanokTurntableFrameImage(
      frame: widget.completedFrame,
      cacheWidth: widget.cacheWidth,
    );
    if (fraction >= 1) {
      // 방어선: 완공 진행도가 레이어까지 내려오면 필터 없이 완성 스프라이트를
      // 그대로 보여준다 (해금 자체는 월드 화면이 턴테이블로 복귀시킨다).
      return KeyedSubtree(
        key: ValueKey('ildu-construction-complete-frame-${widget.anchorId}'),
        child: frameImage,
      );
    }
    return RepaintBoundary(
      key: ValueKey('ildu-construction-ghost-${widget.anchorId}'),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: fraction),
        duration: SoriMotion.respect(context, SoriMotion.slow),
        curve: SoriMotion.gentle,
        builder: (context, revealed, _) => Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Opacity(
                key: ValueKey('ildu-ghost-silhouette-${widget.anchorId}'),
                opacity: .25,
                child: ColorFiltered(
                  colorFilter: _luminanceDesaturate,
                  child: frameImage,
                ),
              ),
            ),
            Positioned.fill(
              child: ClipRect(
                key: ValueKey('ildu-ghost-reveal-${widget.anchorId}'),
                clipper: IlDuGhostRevealClipper(revealed),
                child: frameImage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
