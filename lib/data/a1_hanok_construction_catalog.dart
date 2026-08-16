/// Fixed master-canvas width for every cumulative A1 construction state.
const int kA1HanokCanvasWidth = 1536;

/// Fixed master-canvas height for every cumulative A1 construction state.
const int kA1HanokCanvasHeight = 1152;

/// Flutter decodes the RGB WebP source into an RGBA surface in memory.
const int kA1HanokDecodedBytesPerPixel = 4;

/// Maximum decoded memory retained by the A1 renderer at one time.
const int kA1HanokDecodedMemoryMaxBytes = 32 * 1024 * 1024;

/// Immutable visual state for one completed A1 construction step.
///
/// This catalog maps already-authorized Hanok progress to art. It does not
/// decide whether a course segment, grant, or reward has been earned.
final class A1HanokConstructionState {
  const A1HanokConstructionState({
    required this.step,
    required this.id,
    required this.assetPath,
    required this.grantId,
  });

  final int step;
  final String id;
  final String assetPath;
  final String? grantId;
}

const String _stateAssetRoot =
    'assets/illustrations/personal_hanok_v2/a1/states/';

/// Cumulative states selected solely by
/// `HanokExperienceProjection.a1ConstructionStep`.
const List<A1HanokConstructionState> kA1HanokConstructionStates = [
  A1HanokConstructionState(
    step: 0,
    id: '00_empty_site',
    assetPath: 'assets/illustrations/personal_hanok_v2/map/site_base_light.png',
    grantId: null,
  ),
  A1HanokConstructionState(
    step: 1,
    id: '01_site_setout',
    assetPath: '${_stateAssetRoot}01_site_setout.webp',
    grantId: 'hanok_a1_01_site_setout',
  ),
  A1HanokConstructionState(
    step: 2,
    id: '02_plan_layout',
    assetPath: '${_stateAssetRoot}02_plan_layout.webp',
    grantId: 'hanok_a1_02_plan_layout',
  ),
  A1HanokConstructionState(
    step: 3,
    id: '03_foundation_gidan',
    assetPath: '${_stateAssetRoot}03_foundation_gidan.webp',
    grantId: 'hanok_a1_03_foundation_gidan',
  ),
  A1HanokConstructionState(
    step: 4,
    id: '04_cornerstones_choseok',
    assetPath: '${_stateAssetRoot}04_cornerstones_choseok.webp',
    grantId: 'hanok_a1_04_cornerstones_choseok',
  ),
  A1HanokConstructionState(
    step: 5,
    id: '05_timber_preparation',
    assetPath: '${_stateAssetRoot}05_timber_preparation.webp',
    grantId: 'hanok_a1_05_timber_preparation',
  ),
  A1HanokConstructionState(
    step: 6,
    id: '06_columns',
    assetPath: '${_stateAssetRoot}06_columns.webp',
    grantId: 'hanok_a1_06_columns',
  ),
  A1HanokConstructionState(
    step: 7,
    id: '07_beams_changbang',
    assetPath: '${_stateAssetRoot}07_beams_changbang.webp',
    grantId: 'hanok_a1_07_beams_changbang',
  ),
  A1HanokConstructionState(
    step: 8,
    id: '08_purlins_sangnyang',
    assetPath: '${_stateAssetRoot}08_purlins_sangnyang.webp',
    grantId: 'hanok_a1_08_purlins_sangnyang',
  ),
  A1HanokConstructionState(
    step: 9,
    id: '09_rafters_roof_frame',
    assetPath: '${_stateAssetRoot}09_rafters_roof_frame.webp',
    grantId: 'hanok_a1_09_rafters_roof_frame',
  ),
  A1HanokConstructionState(
    step: 10,
    id: '10_roof_base',
    assetPath: '${_stateAssetRoot}10_roof_base.webp',
    grantId: 'hanok_a1_10_roof_base',
  ),
  A1HanokConstructionState(
    step: 11,
    id: '11_choga_roof',
    assetPath: '${_stateAssetRoot}11_choga_roof.webp',
    grantId: 'hanok_a1_11_choga_roof',
  ),
  A1HanokConstructionState(
    step: 12,
    id: '12_wall_frame_sujang',
    assetPath: '${_stateAssetRoot}12_wall_frame_sujang.webp',
    grantId: 'hanok_a1_12_wall_frame_sujang',
  ),
  A1HanokConstructionState(
    step: 13,
    id: '13_earth_walls',
    assetPath: '${_stateAssetRoot}13_earth_walls.webp',
    grantId: 'hanok_a1_13_earth_walls',
  ),
  A1HanokConstructionState(
    step: 14,
    id: '14_ondol_maru',
    assetPath: '${_stateAssetRoot}14_ondol_maru.webp',
    grantId: 'hanok_a1_14_ondol_maru',
  ),
  A1HanokConstructionState(
    step: 15,
    id: '15_changho_finish',
    assetPath: '${_stateAssetRoot}15_changho_finish.webp',
    grantId: 'hanok_a1_15_changho_finish',
  ),
  A1HanokConstructionState(
    step: 16,
    id: '16_landscape_move_in',
    assetPath: '${_stateAssetRoot}16_landscape_move_in.webp',
    grantId: 'hanok_a1_16_landscape_move_in',
  ),
];

A1HanokConstructionState a1HanokConstructionStateForStep(int step) {
  RangeError.checkValidIndex(step, kA1HanokConstructionStates, 'step');
  return kA1HanokConstructionStates[step];
}

/// Returns the only states the renderer may keep decoded for [step].
List<A1HanokConstructionState> a1HanokDecodeWindowForStep(int step) {
  RangeError.checkValidIndex(step, kA1HanokConstructionStates, 'step');
  final first = step == 0 ? 0 : step - 1;
  final last = step == kA1HanokConstructionStates.length - 1 ? step : step + 1;
  return List.unmodifiable(kA1HanokConstructionStates.sublist(first, last + 1));
}

int a1HanokDecodeWindowBytesForStep(int step) {
  return a1HanokDecodeWindowForStep(step).length *
      kA1HanokCanvasWidth *
      kA1HanokCanvasHeight *
      kA1HanokDecodedBytesPerPixel;
}
