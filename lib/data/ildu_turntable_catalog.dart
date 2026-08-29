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

/// Jin-approved V05 Jungmunganchae turnaround.
///
/// The source frames are the approved 28-degree elevated RGBA exports. Their
/// differing source canvases are cropped only by transparent alpha bounds at
/// paint time; the authored pixels themselves remain unchanged.
final IlDuTurntableSpec kIlDuJungmunganchaeTurntable = IlDuTurntableSpec(
  buildingId: 'jungmunganchae',
  mapAspectRatio: 2.3,
  frames: <IlDuTurntableFrame>[
    _frame('ildu_jungmunganchae_00_front.png', 1792, 878, 157, 98, 1621, 786),
    _frame(
      'ildu_jungmunganchae_01_front_right.png',
      1454,
      1082,
      39,
      58,
      1434,
      1050,
    ),
    _frame('ildu_jungmunganchae_02_right.png', 1400, 1123, 251, 63, 1149, 1068),
    _frame(
      'ildu_jungmunganchae_03_rear_right.png',
      1453,
      1082,
      21,
      54,
      1433,
      1054,
    ),
    _frame('ildu_jungmunganchae_04_rear.png', 1791, 878, 93, 100, 1698, 800),
    _frame(
      'ildu_jungmunganchae_05_rear_left.png',
      1571,
      1001,
      61,
      36,
      1512,
      964,
    ),
    _frame('ildu_jungmunganchae_06_left.png', 1525, 1031, 389, 50, 1120, 982),
    _frame(
      'ildu_jungmunganchae_07_front_left.png',
      1493,
      1054,
      48,
      60,
      1404,
      989,
    ),
  ],
);

final Map<String, IlDuTurntableSpec> kIlDuTurntables =
    <String, IlDuTurntableSpec>{
      kIlDuSarangchaeTurntable.buildingId: kIlDuSarangchaeTurntable,
      kIlDuAnsarangchaeTurntable.buildingId: kIlDuAnsarangchaeTurntable,
      kIlDuJungmunganchaeTurntable.buildingId: kIlDuJungmunganchaeTurntable,
    };

IlDuTurntableSpec? ilduTurntableForBuilding(String buildingId) =>
    kIlDuTurntables[buildingId];
