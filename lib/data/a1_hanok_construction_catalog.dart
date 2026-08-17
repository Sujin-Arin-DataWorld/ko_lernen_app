/// Immutable A1 0-16 construction states for the Living Hanok V1 camera.
///
/// This catalog is presentation-only. It does not award grants, read
/// CourseMastery, or import pack/XP/Gye/legacy stage authority.
library;

const int kA1HanokMinStep = 0;
const int kA1HanokMaxStep = 16;
const int kA1HanokCanvasWidth = 1536;
const int kA1HanokCanvasHeight = 1152;
const int kA1HanokDecodedMemoryMaxBytes = 33554432;
const int kA1HanokResidentFrameLimit = 3;

const String kA1HanokRuntimeStateRoot =
    'assets/illustrations/personal_hanok_v2/a1/states/';
const String kA1HanokEmptySiteAsset =
    'assets/illustrations/personal_hanok_v2/map/site_base_light.png';

final class A1HanokConstructionState {
  const A1HanokConstructionState({
    required this.step,
    required this.id,
    required this.fileName,
    required this.assetPath,
    this.grantId,
    this.revealAssetId,
  });

  final int step;
  final String id;
  final String fileName;
  final String assetPath;
  final String? grantId;
  final String? revealAssetId;
}

const List<A1HanokConstructionState> kA1HanokConstructionStates = [
  A1HanokConstructionState(
    step: 0,
    id: '00_empty_site',
    fileName: 'site_base_light.png',
    assetPath: kA1HanokEmptySiteAsset,
  ),
  A1HanokConstructionState(
    step: 1,
    id: '01_site_setout',
    fileName: '01_site_setout.webp',
    assetPath: '${kA1HanokRuntimeStateRoot}01_site_setout.webp',
    grantId: 'hanok_a1_01_site_setout',
    revealAssetId: 'hanok_a1_state_01_site_setout',
  ),
  A1HanokConstructionState(
    step: 2,
    id: '02_plan_layout',
    fileName: '02_plan_layout.webp',
    assetPath: '${kA1HanokRuntimeStateRoot}02_plan_layout.webp',
    grantId: 'hanok_a1_02_plan_layout',
    revealAssetId: 'hanok_a1_state_02_plan_layout',
  ),
  A1HanokConstructionState(
    step: 3,
    id: '03_foundation_gidan',
    fileName: '03_foundation_gidan.webp',
    assetPath: '${kA1HanokRuntimeStateRoot}03_foundation_gidan.webp',
    grantId: 'hanok_a1_03_foundation_gidan',
    revealAssetId: 'hanok_a1_state_03_foundation_gidan',
  ),
  A1HanokConstructionState(
    step: 4,
    id: '04_cornerstones_choseok',
    fileName: '04_cornerstones_choseok.webp',
    assetPath: '${kA1HanokRuntimeStateRoot}04_cornerstones_choseok.webp',
    grantId: 'hanok_a1_04_cornerstones_choseok',
    revealAssetId: 'hanok_a1_state_04_cornerstones_choseok',
  ),
  A1HanokConstructionState(
    step: 5,
    id: '05_timber_preparation',
    fileName: '05_timber_preparation.webp',
    assetPath: '${kA1HanokRuntimeStateRoot}05_timber_preparation.webp',
    grantId: 'hanok_a1_05_timber_preparation',
    revealAssetId: 'hanok_a1_state_05_timber_preparation',
  ),
  A1HanokConstructionState(
    step: 6,
    id: '06_columns',
    fileName: '06_columns.webp',
    assetPath: '${kA1HanokRuntimeStateRoot}06_columns.webp',
    grantId: 'hanok_a1_06_columns',
    revealAssetId: 'hanok_a1_state_06_columns',
  ),
  A1HanokConstructionState(
    step: 7,
    id: '07_beams_changbang',
    fileName: '07_beams_changbang.webp',
    assetPath: '${kA1HanokRuntimeStateRoot}07_beams_changbang.webp',
    grantId: 'hanok_a1_07_beams_changbang',
    revealAssetId: 'hanok_a1_state_07_beams_changbang',
  ),
  A1HanokConstructionState(
    step: 8,
    id: '08_purlins_sangnyang',
    fileName: '08_purlins_sangnyang.webp',
    assetPath: '${kA1HanokRuntimeStateRoot}08_purlins_sangnyang.webp',
    grantId: 'hanok_a1_08_purlins_sangnyang',
    revealAssetId: 'hanok_a1_state_08_purlins_sangnyang',
  ),
  A1HanokConstructionState(
    step: 9,
    id: '09_rafters_roof_frame',
    fileName: '09_rafters_roof_frame.webp',
    assetPath: '${kA1HanokRuntimeStateRoot}09_rafters_roof_frame.webp',
    grantId: 'hanok_a1_09_rafters_roof_frame',
    revealAssetId: 'hanok_a1_state_09_rafters_roof_frame',
  ),
  A1HanokConstructionState(
    step: 10,
    id: '10_roof_base',
    fileName: '10_roof_base.webp',
    assetPath: '${kA1HanokRuntimeStateRoot}10_roof_base.webp',
    grantId: 'hanok_a1_10_roof_base',
    revealAssetId: 'hanok_a1_state_10_roof_base',
  ),
  A1HanokConstructionState(
    step: 11,
    id: '11_giwa_roof',
    fileName: '11_giwa_roof.webp',
    assetPath: '${kA1HanokRuntimeStateRoot}11_giwa_roof.webp',
    grantId: 'hanok_a1_11_giwa_roof',
    revealAssetId: 'hanok_a1_state_11_giwa_roof',
  ),
  A1HanokConstructionState(
    step: 12,
    id: '12_wall_frame_sujang',
    fileName: '12_wall_frame_sujang.webp',
    assetPath: '${kA1HanokRuntimeStateRoot}12_wall_frame_sujang.webp',
    grantId: 'hanok_a1_12_wall_frame_sujang',
    revealAssetId: 'hanok_a1_state_12_wall_frame_sujang',
  ),
  A1HanokConstructionState(
    step: 13,
    id: '13_earth_walls',
    fileName: '13_earth_walls.webp',
    assetPath: '${kA1HanokRuntimeStateRoot}13_earth_walls.webp',
    grantId: 'hanok_a1_13_earth_walls',
    revealAssetId: 'hanok_a1_state_13_earth_walls',
  ),
  A1HanokConstructionState(
    step: 14,
    id: '14_ondol_maru',
    fileName: '14_ondol_maru.webp',
    assetPath: '${kA1HanokRuntimeStateRoot}14_ondol_maru.webp',
    grantId: 'hanok_a1_14_ondol_maru',
    revealAssetId: 'hanok_a1_state_14_ondol_maru',
  ),
  A1HanokConstructionState(
    step: 15,
    id: '15_changho_finish',
    fileName: '15_changho_finish.webp',
    assetPath: '${kA1HanokRuntimeStateRoot}15_changho_finish.webp',
    grantId: 'hanok_a1_15_changho_finish',
    revealAssetId: 'hanok_a1_state_15_changho_finish',
  ),
  A1HanokConstructionState(
    step: 16,
    id: '16_landscape_move_in',
    fileName: '16_landscape_move_in.webp',
    assetPath: '${kA1HanokRuntimeStateRoot}16_landscape_move_in.webp',
    grantId: 'hanok_a1_16_landscape_move_in',
    revealAssetId: 'hanok_a1_state_16_landscape_move_in',
  ),
];

A1HanokConstructionState a1HanokConstructionState(int step) {
  if (step < kA1HanokMinStep || step > kA1HanokMaxStep) {
    throw RangeError.range(step, kA1HanokMinStep, kA1HanokMaxStep, 'step');
  }
  return kA1HanokConstructionStates[step];
}

/// Previous/current/next only. Active decoded residency stays at 3 frames.
List<int> a1HanokResidentSteps(int current) {
  if (current < kA1HanokMinStep || current > kA1HanokMaxStep) {
    throw RangeError.range(current, kA1HanokMinStep, kA1HanokMaxStep, 'current');
  }
  final steps = <int>{
    if (current > kA1HanokMinStep) current - 1,
    current,
    if (current < kA1HanokMaxStep) current + 1,
  }.toList()..sort();
  if (steps.length > kA1HanokResidentFrameLimit) {
    throw StateError('A1 decode window exceeded $kA1HanokResidentFrameLimit');
  }
  return List<int>.unmodifiable(steps);
}

int a1HanokDecodeCacheWidth({
  required double displayWidth,
  required double devicePixelRatio,
}) {
  if (!displayWidth.isFinite ||
      displayWidth <= 0 ||
      !devicePixelRatio.isFinite ||
      devicePixelRatio <= 0) {
    return kA1HanokCanvasWidth;
  }
  final hinted = (displayWidth * devicePixelRatio).round();
  if (hinted < 1) {
    return 1;
  }
  if (hinted > kA1HanokCanvasWidth) {
    return kA1HanokCanvasWidth;
  }
  return hinted;
}

int a1HanokWorstCaseResidentBytes() =>
    kA1HanokResidentFrameLimit *
    kA1HanokCanvasWidth *
    kA1HanokCanvasHeight *
    4;

/// One ImageCache key to evict. [cacheWidth] null means the raw asset key.
final class A1HanokEvictionSpec {
  const A1HanokEvictionSpec({required this.path, this.cacheWidth});

  final String path;
  final int? cacheWidth;
}

/// Catalog-wide ImageCache eviction set. Never clears the global cache.
///
/// Non-resident catalog paths are evicted at every seen decode width and as
/// the raw asset. Resident paths are evicted only at stale widths other than
/// [currentCacheWidth].
List<A1HanokEvictionSpec> a1HanokEvictionTargets({
  required int currentStep,
  required Set<int> seenCacheWidths,
  required int currentCacheWidth,
}) {
  final residents = {
    for (final step in a1HanokResidentSteps(currentStep))
      a1HanokConstructionState(step).assetPath,
  };
  final targets = <A1HanokEvictionSpec>[];
  for (final state in kA1HanokConstructionStates) {
    final path = state.assetPath;
    if (!residents.contains(path)) {
      targets.add(A1HanokEvictionSpec(path: path));
      for (final width in seenCacheWidths) {
        targets.add(A1HanokEvictionSpec(path: path, cacheWidth: width));
      }
    } else {
      for (final width in seenCacheWidths) {
        if (width != currentCacheWidth) {
          targets.add(A1HanokEvictionSpec(path: path, cacheWidth: width));
        }
      }
    }
  }
  return List<A1HanokEvictionSpec>.unmodifiable(targets);
}
