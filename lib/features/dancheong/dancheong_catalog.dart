import '../../widgets/sori/dancheong_stamp.dart';

DancheongMotif? knownMotif(String slug) =>
    DancheongMotif.values.where((motif) => motif.name == slug).firstOrNull;

Set<String> knownOwnedMotifs(Iterable<String> earnedSlugs) => {
  for (final slug in earnedSlugs)
    if (knownMotif(slug) != null) slug,
};

/// Native source widths are used to avoid enlarging a small stamp in exports.
int motifSourceWidth(String slug) => switch (slug) {
  'chilbo' || 'gwigap' || 'peony' || 'taegeuk' || 'vine' || 'wave' => 512,
  'bamboo' ||
  'chrysanthemum' ||
  'cloud' ||
  'lotus' ||
  'mountain' ||
  'octagon' ||
  'plum' ||
  'manja' => 1254,
  _ => 1024,
};

const dancheongExamplePatternAsset =
    'assets/illustrations/dancheong_studio/v1/pattern.png';
const dancheongExampleLetterAsset =
    'assets/illustrations/dancheong_studio/v1/letter.png';
const dancheongFlowerStudyAsset =
    'assets/illustrations/dancheong_studio/v1/flower.png';
const dancheongRibbonStudyAsset =
    'assets/illustrations/dancheong_studio/v1/ribbon.png';
const dancheongColorRibbonBorderAsset =
    'assets/illustrations/dancheong_studio/v1/color_ribbon_frame.png';
const dancheongLotusBorderAsset =
    'assets/illustrations/dancheong_studio/v1/lotus_frame.png';
const dancheongBrocadeFlowBorderAsset =
    'assets/illustrations/dancheong_studio/v1/brocade_flow_frame.png';
