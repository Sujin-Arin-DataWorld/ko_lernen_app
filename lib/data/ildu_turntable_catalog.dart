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
  final String buildingId;
  final List<IlDuTurntableFrame> frames;

  /// Width divided by height for the stable footprint used on the estate map.
  final double mapAspectRatio;

  const IlDuTurntableSpec({
    required this.buildingId,
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
  buildingId: 'sarangchae',
  mapAspectRatio: 1.25,
  frames: <IlDuTurntableFrame>[
    _frame('ildu_sarangchae_00_front.png', 450, 436, 42, 129, 450, 385),
    _frame('ildu_sarangchae_01_front_right.png', 450, 436, 0, 122, 450, 414),
    _frame('ildu_sarangchae_02_right.png', 450, 436, 0, 156, 441, 398),
    _frame('ildu_sarangchae_03_rear_right.png', 451, 436, 24, 129, 417, 409),
    _frame('ildu_sarangchae_04_rear.png', 450, 437, 22, 78, 450, 300),
    _frame('ildu_sarangchae_05_rear_left.png', 450, 437, 0, 64, 446, 346),
    _frame('ildu_sarangchae_06_left.png', 450, 437, 22, 59, 432, 329),
    _frame('ildu_sarangchae_07_front_left.png', 451, 437, 19, 62, 441, 339),
  ],
);

final IlDuTurntableSpec kIlDuAnsarangchaeTurntable = IlDuTurntableSpec(
  buildingId: 'ansarang',
  mapAspectRatio: 1.1,
  frames: <IlDuTurntableFrame>[
    _frame('ildu_ansarangchae_00_front.png', 384, 512, 14, 128, 384, 415),
    _frame('ildu_ansarangchae_01_front_right.png', 384, 512, 0, 100, 384, 455),
    _frame('ildu_ansarangchae_02_right.png', 384, 512, 0, 103, 384, 440),
    _frame('ildu_ansarangchae_03_rear_right.png', 384, 512, 0, 129, 369, 431),
    _frame('ildu_ansarangchae_04_rear.png', 384, 512, 10, 44, 384, 325),
    _frame('ildu_ansarangchae_05_rear_left.png', 384, 512, 0, 28, 384, 390),
    _frame('ildu_ansarangchae_06_left.png', 384, 512, 0, 14, 384, 367),
    _frame('ildu_ansarangchae_07_front_left.png', 384, 512, 0, 16, 357, 376),
  ],
);

final Map<String, IlDuTurntableSpec> kIlDuTurntables =
    <String, IlDuTurntableSpec>{
      kIlDuSarangchaeTurntable.buildingId: kIlDuSarangchaeTurntable,
      kIlDuAnsarangchaeTurntable.buildingId: kIlDuAnsarangchaeTurntable,
    };

IlDuTurntableSpec? ilduTurntableForBuilding(String buildingId) =>
    kIlDuTurntables[buildingId];
