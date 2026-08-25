import '../models/personal_hanok.dart';

/// The only asset root the personal estate is allowed to use.
const kPersonalHanokAssetRoot = 'assets/illustrations/personal_hanok_v2/';

/// The fixed master canvas every estate art layer is authored on.
///
/// Pinned by `docs/PERSONAL_HANOK_CANONICAL_ASSET_CONTRACT.md` and
/// `tool/check_personal_hanok_assets.py`'s `CANVAS`.
const int kPersonalHanokCanvasWidth = 1536;
const int kPersonalHanokCanvasHeight = 1152;

/// Runtime-wide decoded-image ceiling.
///
/// Source: `docs/assets/HANOK_V1_ASSET_PROVENANCE.json` ->
/// `runtimeLimits.decodedMemoryMaxBytes`. It sits as a **sibling** of
/// `a1ConstructionStates`, not inside it, so it governs the estate map too —
/// which had no enforcement at all until this budget existed.
const int kPersonalHanokDecodedMemoryMaxBytes = 33554432;

const int _kPersonalHanokBytesPerPixel = 4;

/// A fixed-canvas art layer. The renderer chooses it solely from the pure
/// [PersonalHanokProjection]; this metadata never owns progress or storage.
class PersonalHanokMapLayer {
  final String id;
  final String assetPath;
  final int zIndex;
  final PersonalHanokMilestone? milestone;

  /// Painted alpha bounds on the fixed 1536 × 1152 master canvas.
  ///
  /// These are intentionally independent from a place's tap target. They
  /// make the art-coordinate contract explicit for focus/reveal work while
  /// allowing accessibility targets to remain a comfortable 48dp minimum.
  final PersonalHanokRect? visualBounds;
  final bool opaque;

  /// Groups multi-stage construction layers that belong to the same
  /// building (e.g. `haengrangchae`), null for every layer that has only
  /// ever had one finished state. Unset (the case for every layer below
  /// today) means this layer is not part of a sub-beat construction chain
  /// and renders exactly as before — see [stageIndex].
  final String? buildingId;

  /// This layer's position within its [buildingId]'s stage sequence
  /// (0-based, later stages are strict supersets of earlier ones — same
  /// contract as `docs/assets/hanok_estate_kit/*_stages.json`'s `recall
  /// 1.0`). Null when [buildingId] is null.
  final int? stageIndex;

  /// The `HanokGrantKind.constructionPiece` grant id that reveals this
  /// stage, matching `tools/content_factory/drafts/hanok_grants.json`'s
  /// `revealAssetIds` -> grant mapping. Null when [buildingId] is null.
  final String? grantId;

  /// Vertical nudge in master-canvas pixels (negative = up), applied only
  /// when this layer is painted on the map.
  ///
  /// The PNG itself is never touched. `sarangchae.png` is the source the
  /// whole A1 kit is derived from and its sha256 is pinned by nine ledger
  /// records plus `a1_kit_geometry.json`, `overlays.json` and this repo's
  /// provenance test — repainting it to move the building would either
  /// break those or force us to rewrite what was actually fed to the model.
  /// A paint-time offset moves the building on the map and leaves every
  /// audit record true. See `docs/SESSION_LOG.md` 2026-08-19.
  final int canvasOffsetY;

  const PersonalHanokMapLayer({
    required this.id,
    required this.assetPath,
    required this.zIndex,
    this.milestone,
    this.visualBounds,
    this.opaque = false,
    this.buildingId,
    this.stageIndex,
    this.grantId,
    this.canvasOffsetY = 0,
  });
}

/// Semantic interaction area, intentionally independent from paint bounds.
class PersonalHanokZoneDefinition {
  final PersonalHanokZone zone;

  /// Broad visual bounds used by a future selected-place viewport.
  final PersonalHanokRect bounds;

  /// One or more precise, non-overlapping hit regions on the fixed map.
  ///
  /// A Hanok can have separated wings, so a single large rectangular target
  /// would make one place intercept another. These regions intentionally
  /// follow the physical building/landscape pieces instead.
  final List<PersonalHanokRect> hitRegions;
  final PersonalHanokMilestone? requires;
  final bool isInteractive;

  const PersonalHanokZoneDefinition({
    required this.zone,
    required this.bounds,
    required this.hitRegions,
    this.requires,
    this.isInteractive = true,
  });
}

const kPersonalHanokLayers = <PersonalHanokMapLayer>[
  PersonalHanokMapLayer(
    id: 'site_base',
    assetPath: '${kPersonalHanokAssetRoot}map/site_base_light.png',
    zIndex: 0,
    opaque: true,
  ),
  PersonalHanokMapLayer(
    id: 'rear_garden',
    assetPath: '${kPersonalHanokAssetRoot}map/landscape/rear_garden.png',
    zIndex: 11,
    milestone: PersonalHanokMilestone.rearGarden,
    visualBounds: PersonalHanokRect(
      left: .013,
      top: .091,
      width: .973,
      height: .454,
    ),
  ),
  PersonalHanokMapLayer(
    id: 'sotdaeulmun',
    assetPath: '${kPersonalHanokAssetRoot}map/structures/sotdaeulmun.png',
    // 화면 아래일수록 관찰자에 가까우므로 나중에 그린다(painter's algorithm).
    // 이 세 채의 알파 하단은 사랑채 920 < 행랑채 1031 < 솟을대문 1079 이다.
    zIndex: 22,
    milestone: PersonalHanokMilestone.sotdaeulmun,
    visualBounds: PersonalHanokRect(
      left: .389,
      top: .759,
      width: .223,
      height: .180,
    ),
  ),
  PersonalHanokMapLayer(
    id: 'haengrangchae',
    assetPath: '${kPersonalHanokAssetRoot}map/structures/haengrangchae.png',
    zIndex: 21,
    milestone: PersonalHanokMilestone.haengrangchae,
    visualBounds: PersonalHanokRect(
      left: .163,
      top: .743,
      width: .278,
      height: .155,
    ),
  ),
  PersonalHanokMapLayer(
    id: 'sarangchae',
    assetPath: '${kPersonalHanokAssetRoot}map/structures/sarangchae.png',
    // 셋 중 가장 뒤(안쪽)라 먼저 그린다. 22였을 때는 사랑채 기단이 앞에 선
    // 솟을대문·행랑채 지붕을 잘라먹었다(행랑채 알파의 27.9%가 가려졌다).
    zIndex: 20,
    // z를 고쳐 가림 순서는 맞췄지만 두 줄이 여전히 맞닿아 있었다. 40px 올리면
    // 겹침이 17,370px -> 1,735px 로 줄어 사랑마당이 드러난다(Jin 선택, 2026-08-19).
    canvasOffsetY: -40,
    milestone: PersonalHanokMilestone.sarangchae,
    visualBounds: PersonalHanokRect(
      left: .104,
      // 616 - 40 = 576 → 576/1152. canvasOffsetY 와 함께 움직여야 잠금해제
      // 스포트라이트가 건물을 따라간다.
      top: .500,
      width: .556,
      height: .268,
    ),
  ),
  PersonalHanokMapLayer(
    id: 'anchae',
    assetPath: '${kPersonalHanokAssetRoot}map/structures/anchae.png',
    zIndex: 23,
    milestone: PersonalHanokMilestone.anchae,
    visualBounds: PersonalHanokRect(
      left: .262,
      top: .258,
      width: .455,
      height: .294,
    ),
  ),
  PersonalHanokMapLayer(
    id: 'daecheongmaru',
    assetPath: '${kPersonalHanokAssetRoot}map/structures/daecheongmaru.png',
    zIndex: 24,
    milestone: PersonalHanokMilestone.daecheongmaru,
    visualBounds: PersonalHanokRect(
      left: .449,
      top: .303,
      width: .113,
      height: .125,
    ),
  ),
  PersonalHanokMapLayer(
    id: 'sadang',
    assetPath: '${kPersonalHanokAssetRoot}map/structures/sadang.png',
    zIndex: 25,
    milestone: PersonalHanokMilestone.sadang,
    visualBounds: PersonalHanokRect(
      left: .779,
      top: .298,
      width: .131,
      height: .203,
    ),
  ),
];

const kPersonalHanokZones = <PersonalHanokZoneDefinition>[
  PersonalHanokZoneDefinition(
    zone: PersonalHanokZone.sarangbang,
    bounds: PersonalHanokRect(left: .10, top: .53, width: .56, height: .27),
    hitRegions: <PersonalHanokRect>[
      // Leave room for the 48dp haengrang target at compact map heights.
      PersonalHanokRect(left: .15, top: .60, width: .49, height: .14),
    ],
    requires: PersonalHanokMilestone.sarangchae,
  ),
  PersonalHanokZoneDefinition(
    zone: PersonalHanokZone.daecheongmaru,
    bounds: PersonalHanokRect(left: .44, top: .30, width: .13, height: .13),
    hitRegions: <PersonalHanokRect>[
      PersonalHanokRect(left: .43, top: .31, width: .14, height: .11),
    ],
    requires: PersonalHanokMilestone.daecheongmaru,
  ),
  PersonalHanokZoneDefinition(
    zone: PersonalHanokZone.haengrangchae,
    bounds: PersonalHanokRect(left: .16, top: .74, width: .28, height: .16),
    hitRegions: <PersonalHanokRect>[
      // The building begins directly below the Sarangchae facade. This keeps
      // its compact 48dp target below that facade instead of intercepting a
      // Sarangbang tap near the center of the map.
      PersonalHanokRect(left: .17, top: .80, width: .26, height: .09),
    ],
    requires: PersonalHanokMilestone.haengrangchae,
  ),
  PersonalHanokZoneDefinition(
    zone: PersonalHanokZone.anchae,
    bounds: PersonalHanokRect(left: .26, top: .25, width: .46, height: .30),
    hitRegions: <PersonalHanokRect>[
      PersonalHanokRect(left: .26, top: .32, width: .13, height: .20),
      PersonalHanokRect(left: .64, top: .32, width: .09, height: .20),
    ],
    requires: PersonalHanokMilestone.anchae,
  ),
  PersonalHanokZoneDefinition(
    zone: PersonalHanokZone.huwon,
    bounds: PersonalHanokRect(left: .01, top: .09, width: .98, height: .46),
    hitRegions: <PersonalHanokRect>[
      PersonalHanokRect(left: .20, top: .12, width: .21, height: .16),
      PersonalHanokRect(left: .08, top: .31, width: .17, height: .20),
    ],
    requires: PersonalHanokMilestone.rearGarden,
  ),
  PersonalHanokZoneDefinition(
    zone: PersonalHanokZone.sadang,
    bounds: PersonalHanokRect(left: .78, top: .30, width: .13, height: .20),
    hitRegions: <PersonalHanokRect>[
      PersonalHanokRect(left: .79, top: .32, width: .12, height: .18),
    ],
    requires: PersonalHanokMilestone.sadang,
  ),
  PersonalHanokZoneDefinition(
    zone: PersonalHanokZone.gyeRoad,
    bounds: PersonalHanokRect(left: .86, top: .70, width: .14, height: .25),
    hitRegions: <PersonalHanokRect>[
      PersonalHanokRect(left: .86, top: .70, width: .14, height: .25),
    ],
    isInteractive: false,
  ),
];

/// Returns only the personal places that are built and can be opened now.
///
/// The map, accessible place list, and future focused viewport share this
/// predicate so their affordances cannot drift apart.
Iterable<PersonalHanokZoneDefinition> visiblePersonalHanokZones(
  PersonalHanokProjection projection,
) => kPersonalHanokZones.where((definition) {
  final required = definition.requires;
  return definition.isInteractive &&
      required != null &&
      projection.isUnlocked(required);
});

PersonalHanokMapLayer layerForMilestone(PersonalHanokMilestone milestone) {
  return kPersonalHanokLayers.firstWhere(
    (layer) => layer.milestone == milestone,
  );
}

PersonalHanokZoneDefinition zoneFor(PersonalHanokZone zone) {
  return kPersonalHanokZones.firstWhere(
    (definition) => definition.zone == zone,
  );
}

/// Decoded bytes for [layerCount] estate layers decoded at [cacheWidth].
///
/// Every layer shares the one master canvas, so a layer's decoded height is
/// its decoded width scaled by the canvas aspect. `cacheWidth` null means the
/// asset decodes at its native canvas width.
int personalHanokResidentBytes({
  required int layerCount,
  int? cacheWidth,
}) {
  if (layerCount <= 0) {
    return 0;
  }
  final width = (cacheWidth == null || cacheWidth > kPersonalHanokCanvasWidth)
      ? kPersonalHanokCanvasWidth
      : (cacheWidth < 1 ? 1 : cacheWidth);
  final height =
      (width * kPersonalHanokCanvasHeight / kPersonalHanokCanvasWidth).round();
  return layerCount * width * (height < 1 ? 1 : height) *
      _kPersonalHanokBytesPerPixel;
}

/// The widest decode that keeps [layerCount] simultaneously painted layers
/// inside [kPersonalHanokDecodedMemoryMaxBytes].
///
/// **Why this is not just a clamp to the canvas width.** The estate paints
/// every unlocked layer at once. Eight full-canvas RGBA layers are
/// 8 × 1536 × 1152 × 4 = 56.6 MiB, so clamping to the canvas still leaves the
/// map at 1.7× the runtime ceiling. The bound has to come from the budget.
int personalHanokDecodeBudgetWidth(int layerCount) {
  if (layerCount <= 0) {
    return kPersonalHanokCanvasWidth;
  }
  var width = kPersonalHanokCanvasWidth;
  while (width > 1 &&
      personalHanokResidentBytes(layerCount: layerCount, cacheWidth: width) >
          kPersonalHanokDecodedMemoryMaxBytes) {
    width -= 1;
  }
  return width;
}

/// Decode width for one estate layer: the display request, capped by both the
/// master canvas and the decoded-memory budget.
///
/// Mirrors `a1HanokDecodeCacheWidth` in
/// `lib/data/a1_hanok_construction_catalog.dart`, which is the same guard for
/// the A1 map. The estate map had no equivalent.
int personalHanokDecodeCacheWidth({
  required double displayWidth,
  required double devicePixelRatio,
  required int layerCount,
}) {
  final budget = personalHanokDecodeBudgetWidth(layerCount);
  if (!displayWidth.isFinite ||
      displayWidth <= 0 ||
      !devicePixelRatio.isFinite ||
      devicePixelRatio <= 0) {
    return budget;
  }
  final hinted = (displayWidth * devicePixelRatio).round();
  if (hinted < 1) {
    return 1;
  }
  if (hinted > budget) {
    return budget;
  }
  return hinted;
}

/// Worst-case resident bytes for the fully built estate.
///
/// The peak is every catalog layer painted at once. During a reveal the map
/// suppresses one milestone and the reveal widget paints that same layer
/// itself, so the total never exceeds the catalog size.
int personalHanokWorstCaseResidentBytes({
  required double displayWidth,
  required double devicePixelRatio,
}) {
  final peakLayers = kPersonalHanokLayers.length;
  final cacheWidth = personalHanokDecodeCacheWidth(
    displayWidth: displayWidth,
    devicePixelRatio: devicePixelRatio,
    layerCount: peakLayers,
  );
  return personalHanokResidentBytes(
    layerCount: peakLayers,
    cacheWidth: cacheWidth,
  );
}
