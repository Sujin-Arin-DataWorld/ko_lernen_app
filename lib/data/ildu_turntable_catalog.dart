import 'dart:ui';

const String kIlDuTurntableAssetRoot =
    'assets/illustrations/personal_hanok_v3/turnarounds/';

/// One authored view in a clockwise eight-direction Hanok turnaround.
///
/// [contentBounds] removes transparent generation padding at paint time. The
/// source PNG stays byte-for-byte unchanged while every direction shares a
/// stable visual baseline in the map and inspection card.
class IlDuTurntableFrame {
  final String assetPath;
  final Size sourceSize;
  final Rect contentBounds;

  const IlDuTurntableFrame({
    required this.assetPath,
    required this.sourceSize,
    required this.contentBounds,
  });
}

class IlDuTurntableSpec {
  final String anchorId;
  final List<IlDuTurntableFrame> frames;

  /// Width divided by height for the stable footprint used on the estate map.
  final double mapAspectRatio;

  const IlDuTurntableSpec({
    required this.anchorId,
    required this.frames,
    required this.mapAspectRatio,
  });

  int directionForDegrees(double degrees) {
    final normalized = ((degrees % 360) + 360) % 360;
    return (normalized / 45).round() % frames.length;
  }
}

IlDuTurntableFrame _frame(
  String file,
  double sourceWidth,
  double sourceHeight,
  double left,
  double top,
  double right,
  double bottom,
) => IlDuTurntableFrame(
  assetPath: '$kIlDuTurntableAssetRoot$file',
  sourceSize: Size(sourceWidth, sourceHeight),
  contentBounds: Rect.fromLTRB(left, top, right, bottom),
);

final IlDuTurntableSpec kIlDuSarangchaeTurntable = IlDuTurntableSpec(
  anchorId: 'sarangchae',
  mapAspectRatio: 1.25,
  frames: <IlDuTurntableFrame>[
    _frame('ildu_sarangchae_00_front.png', 384, 512, 8, 259, 376, 472),
    _frame('ildu_sarangchae_01_front_right.png', 384, 512, 23, 230, 360, 472),
    _frame('ildu_sarangchae_02_right.png', 384, 512, 19, 264, 364, 472),
    _frame('ildu_sarangchae_03_rear_right.png', 384, 512, 34, 235, 349, 472),
    _frame('ildu_sarangchae_04_rear.png', 384, 512, 10, 282, 374, 472),
    _frame('ildu_sarangchae_05_rear_left.png', 384, 512, 21, 230, 362, 472),
    _frame('ildu_sarangchae_06_left.png', 384, 512, 20, 243, 363, 472),
    _frame('ildu_sarangchae_07_front_left.png', 384, 512, 30, 247, 353, 472),
  ],
);

final IlDuTurntableSpec kIlDuAnsarangchaeTurntable = IlDuTurntableSpec(
  anchorId: 'ansarang',
  mapAspectRatio: 1.1,
  frames: <IlDuTurntableFrame>[
    _frame('ildu_ansarangchae_00_front.png', 384, 512, 14, 225, 370, 470),
    _frame('ildu_ansarangchae_01_front_right.png', 384, 512, 17, 158, 366, 470),
    _frame('ildu_ansarangchae_02_right.png', 384, 512, 82, 159, 302, 470),
    _frame('ildu_ansarangchae_03_rear_right.png', 384, 512, 28, 195, 356, 470),
    _frame('ildu_ansarangchae_04_rear.png', 384, 512, 17, 225, 367, 470),
    _frame('ildu_ansarangchae_05_rear_left.png', 384, 512, 18, 145, 366, 470),
    _frame('ildu_ansarangchae_06_left.png', 384, 512, 76, 143, 307, 470),
    _frame('ildu_ansarangchae_07_front_left.png', 384, 512, 10, 143, 373, 470),
  ],
);

final IlDuTurntableSpec kIlDuAnchaeTurntable = IlDuTurntableSpec(
  anchorId: 'anchae',
  mapAspectRatio: 1.78,
  frames: <IlDuTurntableFrame>[
    _frame('ildu_anchae_00_front.png', 384, 512, 26, 332, 358, 472),
    _frame('ildu_anchae_01_front_right.png', 384, 512, 30, 287, 353, 472),
    _frame('ildu_anchae_02_right.png', 384, 512, 111, 267, 273, 472),
    _frame('ildu_anchae_03_rear_right.png', 384, 512, 27, 285, 357, 472),
    _frame('ildu_anchae_04_rear.png', 384, 512, 8, 336, 376, 472),
    _frame('ildu_anchae_05_rear_left.png', 384, 512, 18, 293, 365, 472),
    _frame('ildu_anchae_06_left.png', 384, 512, 99, 275, 285, 472),
    _frame('ildu_anchae_07_front_left.png', 384, 512, 19, 285, 365, 472),
  ],
);

final IlDuTurntableSpec kIlDuSotdaeulmunTurntable = IlDuTurntableSpec(
  anchorId: 'main-gate',
  mapAspectRatio: 1.35,
  frames: <IlDuTurntableFrame>[
    _frame('ildu_sotdaeulmun_00_front.png', 384, 512, 8, 187, 375, 413),
    _frame('ildu_sotdaeulmun_01_front_right.png', 384, 512, 13, 166, 371, 439),
    _frame('ildu_sotdaeulmun_02_right.png', 384, 512, 46, 167, 337, 429),
    _frame('ildu_sotdaeulmun_03_rear_right.png', 384, 512, 16, 164, 368, 429),
    _frame('ildu_sotdaeulmun_04_rear.png', 384, 512, 7, 66, 376, 283),
    _frame('ildu_sotdaeulmun_05_rear_left.png', 384, 512, 20, 60, 363, 311),
    _frame('ildu_sotdaeulmun_06_left.png', 384, 512, 45, 61, 338, 323),
    _frame('ildu_sotdaeulmun_07_front_left.png', 384, 512, 11, 65, 373, 312),
  ],
);

final Map<String, IlDuTurntableSpec> kIlDuTurntables =
    <String, IlDuTurntableSpec>{
      kIlDuSarangchaeTurntable.anchorId: kIlDuSarangchaeTurntable,
      kIlDuAnsarangchaeTurntable.anchorId: kIlDuAnsarangchaeTurntable,
      kIlDuAnchaeTurntable.anchorId: kIlDuAnchaeTurntable,
      kIlDuSotdaeulmunTurntable.anchorId: kIlDuSotdaeulmunTurntable,
    };

IlDuTurntableSpec? ilduTurntableForAnchor(String anchorId) =>
    kIlDuTurntables[anchorId];
