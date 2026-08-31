import 'dart:ui';

const String kIlDuTurntableAssetRoot =
    'assets/illustrations/personal_hanok_v3/turnarounds/';

/// One authored view in a clockwise eight-direction Hanok turnaround.
///
/// [contentBounds] records the nontransparent pixels without changing the
/// source PNG. [viewportBounds] can retain a shared authored crop so every
/// direction keeps one scale and ground line in the map and inspection card.
class IlDuTurntableFrame {
  final String assetPath;
  final Size sourceSize;
  final Rect contentBounds;
  final Rect? viewportBounds;

  const IlDuTurntableFrame({
    required this.assetPath,
    required this.sourceSize,
    required this.contentBounds,
    this.viewportBounds,
  });

  /// The authored crop used for display.
  ///
  /// Most legacy turntables tightly crop each direction. New sets can provide
  /// one shared viewport so a turn keeps its exact scale and ground line.
  Rect get displayBounds => viewportBounds ?? contentBounds;
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
  double bottom, {
  Rect? viewportBounds,
}) => IlDuTurntableFrame(
  assetPath: '$kIlDuTurntableAssetRoot$file',
  sourceSize: Size(sourceWidth, sourceHeight),
  contentBounds: Rect.fromLTRB(left, top, right, bottom),
  viewportBounds: viewportBounds,
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

final IlDuTurntableSpec kIlDuChanggoTurntable = IlDuTurntableSpec(
  anchorId: 'changgo',
  mapAspectRatio: 1.78,
  frames: <IlDuTurntableFrame>[
    _frame('ildu_changgo_00_front.png', 384, 512, 21, 345, 363, 472),
    _frame('ildu_changgo_01_front_right.png', 384, 512, 15, 284, 368, 472),
    _frame('ildu_changgo_02_right.png', 384, 512, 111, 203, 272, 472),
    _frame('ildu_changgo_03_rear_right.png', 384, 512, 12, 296, 371, 472),
    _frame('ildu_changgo_04_rear.png', 384, 512, 19, 358, 365, 472),
    _frame('ildu_changgo_05_rear_left.png', 384, 512, 8, 316, 376, 472),
    _frame('ildu_changgo_06_left.png', 384, 512, 110, 205, 274, 472),
    _frame('ildu_changgo_07_front_left.png', 384, 512, 13, 292, 370, 472),
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
    _frame('ildu_sotdaeulmun_00_front.png', 384, 512, 18, 231, 366, 452),
    _frame('ildu_sotdaeulmun_01_front_right.png', 384, 512, 13, 205, 372, 452),
    _frame('ildu_sotdaeulmun_02_right.png', 384, 512, 32, 215, 353, 452),
    _frame('ildu_sotdaeulmun_03_rear_right.png', 384, 512, 20, 206, 363, 452),
    _frame('ildu_sotdaeulmun_04_rear.png', 384, 512, 20, 230, 363, 452),
    _frame('ildu_sotdaeulmun_05_rear_left.png', 384, 512, 14, 211, 371, 452),
    _frame('ildu_sotdaeulmun_06_left.png', 384, 512, 41, 210, 343, 452),
    _frame('ildu_sotdaeulmun_07_front_left.png', 384, 512, 22, 220, 363, 452),
  ],
);

const Rect _kIlDuAraechaeViewport = Rect.fromLTRB(448, 274, 2111, 1259);

final IlDuTurntableSpec kIlDuAraechaeTurntable = IlDuTurntableSpec(
  anchorId: 'araechae',
  mapAspectRatio: 1.6883248731,
  frames: <IlDuTurntableFrame>[
    _frame(
      'ildu_araechae_00_front.png',
      2560,
      1440,
      618,
      435,
      1943,
      1259,
      viewportBounds: _kIlDuAraechaeViewport,
    ),
    _frame(
      'ildu_araechae_01_front_right.png',
      2560,
      1440,
      449,
      282,
      2111,
      1259,
      viewportBounds: _kIlDuAraechaeViewport,
    ),
    _frame(
      'ildu_araechae_02_right.png',
      2560,
      1440,
      808,
      274,
      1751,
      1259,
      viewportBounds: _kIlDuAraechaeViewport,
    ),
    _frame(
      'ildu_araechae_03_rear_right.png',
      2560,
      1440,
      448,
      342,
      2111,
      1259,
      viewportBounds: _kIlDuAraechaeViewport,
    ),
    _frame(
      'ildu_araechae_04_rear.png',
      2560,
      1440,
      574,
      453,
      1987,
      1259,
      viewportBounds: _kIlDuAraechaeViewport,
    ),
    _frame(
      'ildu_araechae_05_rear_left.png',
      2560,
      1440,
      449,
      391,
      2111,
      1259,
      viewportBounds: _kIlDuAraechaeViewport,
    ),
    _frame(
      'ildu_araechae_06_left.png',
      2560,
      1440,
      808,
      341,
      1751,
      1259,
      viewportBounds: _kIlDuAraechaeViewport,
    ),
    _frame(
      'ildu_araechae_07_front_left.png',
      2560,
      1440,
      448,
      350,
      2111,
      1259,
      viewportBounds: _kIlDuAraechaeViewport,
    ),
  ],
);

/// Jin-approved V05 Jungmunganchae turnaround.
///
/// The source frames are the approved 28-degree elevated RGBA exports. Their
/// differing source canvases are cropped only by transparent alpha bounds at
/// paint time; the authored pixels themselves remain unchanged.
final IlDuTurntableSpec kIlDuJungmunganchaeTurntable = IlDuTurntableSpec(
  anchorId: 'jungmunganchae',
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

final IlDuTurntableSpec kIlDuSadangTurntable = IlDuTurntableSpec(
  anchorId: 'sadang',
  mapAspectRatio: 1.15,
  frames: <IlDuTurntableFrame>[
    _frame('ildu_sadang_00_front.png', 384, 512, 16, 188, 368, 488),
    _frame('ildu_sadang_01_front_right.png', 384, 512, 22, 188, 362, 488),
    _frame('ildu_sadang_02_right.png', 384, 512, 59, 188, 324, 488),
    _frame('ildu_sadang_03_rear_right.png', 384, 512, 30, 188, 353, 488),
    _frame('ildu_sadang_04_rear.png', 384, 512, 16, 188, 368, 488),
    _frame('ildu_sadang_05_rear_left.png', 384, 512, 35, 188, 349, 488),
    _frame('ildu_sadang_06_left.png', 384, 512, 48, 188, 336, 488),
    _frame('ildu_sadang_07_front_left.png', 384, 512, 32, 188, 352, 488),
  ],
);

final IlDuTurntableSpec kIlDuSadangmunTurntable = IlDuTurntableSpec(
  anchorId: 'sadang-gate',
  mapAspectRatio: .85,
  frames: <IlDuTurntableFrame>[
    _frame('ildu_sadangmun_00_front.png', 384, 512, 16, 87, 368, 488),
    _frame('ildu_sadangmun_01_front_right.png', 384, 512, 28, 87, 355, 488),
    _frame('ildu_sadangmun_02_right.png', 384, 512, 103, 87, 281, 488),
    _frame('ildu_sadangmun_03_rear_right.png', 384, 512, 38, 87, 346, 488),
    _frame('ildu_sadangmun_04_rear.png', 384, 512, 30, 87, 354, 488),
    _frame('ildu_sadangmun_05_rear_left.png', 384, 512, 25, 87, 358, 488),
    _frame('ildu_sadangmun_06_left.png', 384, 512, 102, 87, 282, 488),
    _frame('ildu_sadangmun_07_front_left.png', 384, 512, 36, 87, 347, 488),
  ],
);

List<IlDuTurntableFrame> _sadangHyeopmunFrames() => <IlDuTurntableFrame>[
  _frame('ildu_sadang_hyeopmun_00_front.png', 384, 512, 37, 57, 347, 488),
  _frame('ildu_sadang_hyeopmun_01_front_right.png', 384, 512, 33, 40, 350, 488),
  _frame('ildu_sadang_hyeopmun_02_right.png', 384, 512, 92, 59, 291, 488),
  _frame('ildu_sadang_hyeopmun_03_rear_right.png', 384, 512, 38, 61, 345, 488),
  _frame('ildu_sadang_hyeopmun_04_rear.png', 384, 512, 40, 90, 343, 488),
  _frame('ildu_sadang_hyeopmun_05_rear_left.png', 384, 512, 43, 65, 341, 488),
  _frame('ildu_sadang_hyeopmun_06_left.png', 384, 512, 96, 65, 287, 488),
  _frame('ildu_sadang_hyeopmun_07_front_left.png', 384, 512, 34, 50, 349, 488),
];

final IlDuTurntableSpec kIlDuHyeopmunWestTurntable = IlDuTurntableSpec(
  anchorId: 'hyeopmun-west',
  mapAspectRatio: .85,
  frames: _sadangHyeopmunFrames(),
);

final IlDuTurntableSpec kIlDuHyeopmunEastTurntable = IlDuTurntableSpec(
  anchorId: 'hyeopmun-east',
  mapAspectRatio: .85,
  frames: _sadangHyeopmunFrames(),
);

/// Blueprint-corrected four-bay Anchae storehouse.
///
/// The V3 original remains the material/style authority while the recorded
/// drawings determine its 9360 x 2700 mm structure and side/rear openings.
final IlDuTurntableSpec kIlDuAnchaeStoreTurntable = IlDuTurntableSpec(
  anchorId: 'anchae-store',
  mapAspectRatio: 2.75,
  frames: <IlDuTurntableFrame>[
    _frame('ildu_anchae_store_00_front.png', 384, 512, 29, 354, 354, 472),
    _frame('ildu_anchae_store_01_front_right.png', 384, 512, 65, 354, 319, 472),
    _frame('ildu_anchae_store_02_right.png', 384, 512, 130, 354, 253, 472),
    _frame('ildu_anchae_store_03_rear_right.png', 384, 512, 104, 354, 280, 472),
    _frame('ildu_anchae_store_04_rear.png', 384, 512, 9, 354, 375, 472),
    _frame('ildu_anchae_store_05_rear_left.png', 384, 512, 60, 354, 323, 472),
    _frame('ildu_anchae_store_06_left.png', 384, 512, 137, 354, 246, 472),
    _frame('ildu_anchae_store_07_front_left.png', 384, 512, 70, 354, 313, 472),
  ],
);

/// Blueprint-corrected five-bay outer storehouse.
final IlDuTurntableSpec kIlDuGokganTurntable = IlDuTurntableSpec(
  anchorId: 'gokgan',
  mapAspectRatio: 1.93,
  frames: <IlDuTurntableFrame>[
    _frame('ildu_gokgan_00_front.png', 384, 512, 23, 297, 360, 472),
    _frame('ildu_gokgan_01_front_right.png', 384, 512, 25, 297, 359, 472),
    _frame('ildu_gokgan_02_right.png', 384, 512, 57, 297, 327, 472),
    _frame('ildu_gokgan_03_rear_right.png', 384, 512, 31, 297, 352, 472),
    _frame('ildu_gokgan_04_rear.png', 384, 512, 9, 297, 375, 472),
    _frame('ildu_gokgan_05_rear_left.png', 384, 512, 31, 297, 352, 472),
    _frame('ildu_gokgan_06_left.png', 384, 512, 56, 297, 328, 472),
    _frame('ildu_gokgan_07_front_left.png', 384, 512, 44, 297, 339, 472),
  ],
);

List<IlDuTurntableFrame> _toiletFrames() => <IlDuTurntableFrame>[
  _frame('ildu_toilet_00_front.png', 384, 512, 22, 152, 361, 472),
  _frame('ildu_toilet_01_front_right.png', 384, 512, 8, 152, 375, 472),
  _frame('ildu_toilet_02_right.png', 384, 512, 59, 152, 324, 472),
  _frame('ildu_toilet_03_rear_right.png', 384, 512, 48, 152, 336, 472),
  _frame('ildu_toilet_04_rear.png', 384, 512, 33, 152, 350, 472),
  _frame('ildu_toilet_05_rear_left.png', 384, 512, 41, 152, 342, 472),
  _frame('ildu_toilet_06_left.png', 384, 512, 60, 152, 323, 472),
  _frame('ildu_toilet_07_front_left.png', 384, 512, 33, 152, 351, 472),
];

/// No dedicated toilet drawing is present in the blueprint archive. Both map
/// placements intentionally share one source-faithful eight-direction kit.
final IlDuTurntableSpec kIlDuToiletNorthTurntable = IlDuTurntableSpec(
  anchorId: 'toilet-north',
  mapAspectRatio: 1.06,
  frames: _toiletFrames(),
);

final IlDuTurntableSpec kIlDuToiletSouthTurntable = IlDuTurntableSpec(
  anchorId: 'toilet-south',
  mapAspectRatio: 1.06,
  frames: _toiletFrames(),
);

final Map<String, IlDuTurntableSpec> kIlDuTurntables =
    <String, IlDuTurntableSpec>{
      kIlDuSarangchaeTurntable.anchorId: kIlDuSarangchaeTurntable,
      kIlDuAnsarangchaeTurntable.anchorId: kIlDuAnsarangchaeTurntable,
      kIlDuChanggoTurntable.anchorId: kIlDuChanggoTurntable,
      kIlDuAnchaeTurntable.anchorId: kIlDuAnchaeTurntable,
      kIlDuSotdaeulmunTurntable.anchorId: kIlDuSotdaeulmunTurntable,
      kIlDuAraechaeTurntable.anchorId: kIlDuAraechaeTurntable,
      kIlDuJungmunganchaeTurntable.anchorId: kIlDuJungmunganchaeTurntable,
      kIlDuSadangTurntable.anchorId: kIlDuSadangTurntable,
      kIlDuSadangmunTurntable.anchorId: kIlDuSadangmunTurntable,
      kIlDuHyeopmunWestTurntable.anchorId: kIlDuHyeopmunWestTurntable,
      kIlDuHyeopmunEastTurntable.anchorId: kIlDuHyeopmunEastTurntable,
      kIlDuAnchaeStoreTurntable.anchorId: kIlDuAnchaeStoreTurntable,
      kIlDuGokganTurntable.anchorId: kIlDuGokganTurntable,
      kIlDuToiletNorthTurntable.anchorId: kIlDuToiletNorthTurntable,
      kIlDuToiletSouthTurntable.anchorId: kIlDuToiletSouthTurntable,
    };

IlDuTurntableSpec? ilduTurntableForAnchor(String anchorId) =>
    kIlDuTurntables[anchorId];
