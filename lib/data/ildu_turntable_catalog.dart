import 'dart:ui';

const String kIlDuTurntableAssetRoot =
    'assets/illustrations/ildu_r16_support/turnarounds/';

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

final IlDuTurntableSpec kIlDuSarangchaeTurntable = IlDuTurntableSpec(
  anchorId: 'sarangchae',
  mapAspectRatio: 1.74807198,
  frames: <IlDuTurntableFrame>[
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/sarang/view_00.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(116, 97, 724, 467),
      viewportBounds: Rect.fromLTRB(44, 78, 724, 467),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/sarang/view_01.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(205, 78, 624, 464),
      viewportBounds: Rect.fromLTRB(44, 78, 724, 467),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/sarang/view_02.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(64, 101, 704, 461),
      viewportBounds: Rect.fromLTRB(44, 78, 724, 467),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/sarang/view_03.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(74, 115, 692, 430),
      viewportBounds: Rect.fromLTRB(44, 78, 724, 467),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/sarang/view_04.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(44, 80, 652, 455),
      viewportBounds: Rect.fromLTRB(44, 78, 724, 467),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/sarang/view_05.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(144, 83, 564, 455),
      viewportBounds: Rect.fromLTRB(44, 78, 724, 467),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/sarang/view_06.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(64, 84, 704, 448),
      viewportBounds: Rect.fromLTRB(44, 78, 724, 467),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/sarang/view_07.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(76, 122, 694, 419),
      viewportBounds: Rect.fromLTRB(44, 78, 724, 467),
    ),
  ],
);

final IlDuTurntableSpec kIlDuAnsarangchaeTurntable = IlDuTurntableSpec(
  anchorId: 'ansarang',
  mapAspectRatio: 1.56769596,
  frames: <IlDuTurntableFrame>[
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/ansarang/view_06.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(64, 102, 714, 474),
      viewportBounds: Rect.fromLTRB(54, 71, 714, 492),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/ansarang/view_07.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(194, 71, 592, 485),
      viewportBounds: Rect.fromLTRB(54, 71, 714, 492),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/ansarang/view_00.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(99, 87, 683, 492),
      viewportBounds: Rect.fromLTRB(54, 71, 714, 492),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/ansarang/view_01.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(73, 143, 699, 442),
      viewportBounds: Rect.fromLTRB(54, 71, 714, 492),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/ansarang/view_02.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(54, 108, 704, 480),
      viewportBounds: Rect.fromLTRB(54, 71, 714, 492),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/ansarang/view_03.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(176, 72, 574, 486),
      viewportBounds: Rect.fromLTRB(54, 71, 714, 492),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/ansarang/view_04.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(85, 83, 669, 488),
      viewportBounds: Rect.fromLTRB(54, 71, 714, 492),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/ansarang/view_05.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(70, 135, 695, 435),
      viewportBounds: Rect.fromLTRB(54, 71, 714, 492),
    ),
  ],
);

final IlDuTurntableSpec kIlDuChanggoTurntable = IlDuTurntableSpec(
  anchorId: 'changgo',
  mapAspectRatio: 1.49555556,
  frames: <IlDuTurntableFrame>[
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/changgo/view_06.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(64, 84, 704, 448),
      viewportBounds: Rect.fromLTRB(48, 30, 721, 480),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/changgo/view_07.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(235, 30, 533, 480),
      viewportBounds: Rect.fromLTRB(48, 30, 721, 480),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/changgo/view_00.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(120, 52, 648, 472),
      viewportBounds: Rect.fromLTRB(48, 30, 721, 480),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/changgo/view_01.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(48, 138, 721, 406),
      viewportBounds: Rect.fromLTRB(48, 30, 721, 480),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/changgo/view_02.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(65, 84, 704, 449),
      viewportBounds: Rect.fromLTRB(48, 30, 721, 480),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/changgo/view_03.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(235, 30, 533, 480),
      viewportBounds: Rect.fromLTRB(48, 30, 721, 480),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/changgo/view_04.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(120, 52, 648, 471),
      viewportBounds: Rect.fromLTRB(48, 30, 721, 480),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/changgo/view_05.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(48, 138, 721, 402),
      viewportBounds: Rect.fromLTRB(48, 30, 721, 480),
    ),
  ],
);

final IlDuTurntableSpec kIlDuAnchaeTurntable = IlDuTurntableSpec(
  anchorId: 'anchae',
  mapAspectRatio: 1.91977077,
  frames: <IlDuTurntableFrame>[
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/anchae/view_06.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(123, 106, 558, 312),
      viewportBounds: Rect.fromLTRB(49, 75, 719, 424),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/anchae/view_07.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(323, 75, 539, 332),
      viewportBounds: Rect.fromLTRB(49, 75, 719, 424),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/anchae/view_00.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(312, 113, 677, 355),
      viewportBounds: Rect.fromLTRB(49, 75, 719, 424),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/anchae/view_01.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(266, 199, 719, 349),
      viewportBounds: Rect.fromLTRB(49, 75, 719, 424),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/anchae/view_02.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(210, 196, 646, 406),
      viewportBounds: Rect.fromLTRB(49, 75, 719, 424),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/anchae/view_03.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(229, 166, 445, 424),
      viewportBounds: Rect.fromLTRB(49, 75, 719, 424),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/anchae/view_04.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(91, 153, 456, 392),
      viewportBounds: Rect.fromLTRB(49, 75, 719, 424),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/anchae/view_05.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(49, 164, 502, 309),
      viewportBounds: Rect.fromLTRB(49, 75, 719, 424),
    ),
  ],
);

final IlDuTurntableSpec kIlDuSotdaeulmunTurntable = IlDuTurntableSpec(
  anchorId: 'main-gate',
  mapAspectRatio: 1.02078522,
  frames: <IlDuTurntableFrame>[
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/main_gate/view_00.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(163, 78, 582, 425),
      viewportBounds: Rect.fromLTRB(163, 48, 605, 481),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/main_gate/view_01.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(171, 135, 598, 408),
      viewportBounds: Rect.fromLTRB(163, 48, 605, 481),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/main_gate/view_02.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(217, 52, 576, 453),
      viewportBounds: Rect.fromLTRB(163, 48, 605, 481),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/main_gate/view_03.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(259, 50, 514, 471),
      viewportBounds: Rect.fromLTRB(163, 48, 605, 481),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/main_gate/view_04.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(186, 99, 605, 460),
      viewportBounds: Rect.fromLTRB(163, 48, 605, 481),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/main_gate/view_05.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(170, 164, 597, 411),
      viewportBounds: Rect.fromLTRB(163, 48, 605, 481),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/main_gate/view_06.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(192, 72, 551, 481),
      viewportBounds: Rect.fromLTRB(163, 48, 605, 481),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/main_gate/view_07.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(254, 48, 509, 469),
      viewportBounds: Rect.fromLTRB(163, 48, 605, 481),
    ),
  ],
);

final IlDuTurntableSpec kIlDuAraechaeTurntable = IlDuTurntableSpec(
  anchorId: 'araechae',
  mapAspectRatio: 1.33186813,
  frames: <IlDuTurntableFrame>[
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/arae/view_00.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(81, 82, 684, 469),
      viewportBounds: Rect.fromLTRB(81, 35, 687, 490),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/arae/view_01.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(158, 35, 609, 481),
      viewportBounds: Rect.fromLTRB(81, 35, 687, 490),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/arae/view_02.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(111, 46, 659, 490),
      viewportBounds: Rect.fromLTRB(81, 35, 687, 490),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/arae/view_03.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(102, 110, 669, 450),
      viewportBounds: Rect.fromLTRB(81, 35, 687, 490),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/arae/view_04.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(84, 83, 687, 469),
      viewportBounds: Rect.fromLTRB(81, 35, 687, 490),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/arae/view_05.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(159, 36, 610, 479),
      viewportBounds: Rect.fromLTRB(81, 35, 687, 490),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/arae/view_06.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(109, 47, 657, 484),
      viewportBounds: Rect.fromLTRB(81, 35, 687, 490),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/arae/view_07.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(98, 110, 666, 451),
      viewportBounds: Rect.fromLTRB(81, 35, 687, 490),
    ),
  ],
);

final IlDuTurntableSpec kIlDuJungmunganchaeTurntable = IlDuTurntableSpec(
  anchorId: 'jungmunganchae',
  mapAspectRatio: 1.37831858,
  frames: <IlDuTurntableFrame>[
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/jung/view_06.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(102, 67, 695, 450),
      viewportBounds: Rect.fromLTRB(72, 30, 695, 482),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/jung/view_07.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(200, 30, 572, 474),
      viewportBounds: Rect.fromLTRB(72, 30, 695, 482),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/jung/view_00.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(159, 61, 667, 475),
      viewportBounds: Rect.fromLTRB(72, 30, 695, 482),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/jung/view_01.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(96, 142, 685, 424),
      viewportBounds: Rect.fromLTRB(72, 30, 695, 482),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/jung/view_02.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(72, 91, 666, 464),
      viewportBounds: Rect.fromLTRB(72, 30, 695, 482),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/jung/view_03.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(196, 35, 568, 482),
      viewportBounds: Rect.fromLTRB(72, 30, 695, 482),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/jung/view_04.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(101, 45, 608, 480),
      viewportBounds: Rect.fromLTRB(72, 30, 695, 482),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/jung/view_05.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(83, 114, 673, 441),
      viewportBounds: Rect.fromLTRB(72, 30, 695, 482),
    ),
  ],
);

final IlDuTurntableSpec kIlDuSadangTurntable = IlDuTurntableSpec(
  anchorId: 'sadang',
  mapAspectRatio: 1.41648107,
  frames: <IlDuTurntableFrame>[
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/sadang/view_06.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(124, 39, 644, 484),
      viewportBounds: Rect.fromLTRB(66, 39, 702, 488),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/sadang/view_07.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(66, 75, 702, 480),
      viewportBounds: Rect.fromLTRB(66, 39, 702, 488),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/sadang/view_00.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(84, 91, 683, 469),
      viewportBounds: Rect.fromLTRB(66, 39, 702, 488),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/sadang/view_01.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(89, 46, 679, 488),
      viewportBounds: Rect.fromLTRB(66, 39, 702, 488),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/sadang/view_02.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(124, 39, 644, 484),
      viewportBounds: Rect.fromLTRB(66, 39, 702, 488),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/sadang/view_03.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(66, 75, 702, 479),
      viewportBounds: Rect.fromLTRB(66, 39, 702, 488),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/sadang/view_04.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(84, 91, 683, 469),
      viewportBounds: Rect.fromLTRB(66, 39, 702, 488),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/sadang/view_05.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(89, 46, 679, 488),
      viewportBounds: Rect.fromLTRB(66, 39, 702, 488),
    ),
  ],
);

final IlDuTurntableSpec kIlDuSadangmunTurntable = IlDuTurntableSpec(
  anchorId: 'sadang-gate',
  mapAspectRatio: 0.82959641,
  frames: <IlDuTurntableFrame>[
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/shrine/view_00.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(199, 56, 569, 482),
      viewportBounds: Rect.fromLTRB(199, 37, 569, 483),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/shrine/view_01.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(248, 37, 520, 475),
      viewportBounds: Rect.fromLTRB(199, 37, 569, 483),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/shrine/view_02.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(214, 45, 554, 483),
      viewportBounds: Rect.fromLTRB(199, 37, 569, 483),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/shrine/view_03.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(211, 74, 557, 472),
      viewportBounds: Rect.fromLTRB(199, 37, 569, 483),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/shrine/view_04.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(199, 56, 569, 482),
      viewportBounds: Rect.fromLTRB(199, 37, 569, 483),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/shrine/view_05.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(248, 37, 520, 476),
      viewportBounds: Rect.fromLTRB(199, 37, 569, 483),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/shrine/view_06.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(214, 45, 554, 483),
      viewportBounds: Rect.fromLTRB(199, 37, 569, 483),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/shrine/view_07.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(211, 74, 557, 472),
      viewportBounds: Rect.fromLTRB(199, 37, 569, 483),
    ),
  ],
);

final IlDuTurntableSpec kIlDuHyeopmunWestTurntable = IlDuTurntableSpec(
  anchorId: 'hyeopmun-west',
  mapAspectRatio: 0.85260771,
  frames: <IlDuTurntableFrame>[
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/left/view_00.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(196, 66, 572, 485),
      viewportBounds: Rect.fromLTRB(196, 46, 572, 487),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/left/view_01.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(224, 46, 544, 478),
      viewportBounds: Rect.fromLTRB(196, 46, 572, 487),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/left/view_02.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(199, 54, 569, 487),
      viewportBounds: Rect.fromLTRB(196, 46, 572, 487),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/left/view_03.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(223, 85, 544, 471),
      viewportBounds: Rect.fromLTRB(196, 46, 572, 487),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/left/view_04.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(196, 66, 572, 485),
      viewportBounds: Rect.fromLTRB(196, 46, 572, 487),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/left/view_05.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(224, 46, 544, 478),
      viewportBounds: Rect.fromLTRB(196, 46, 572, 487),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/left/view_06.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(199, 54, 569, 487),
      viewportBounds: Rect.fromLTRB(196, 46, 572, 487),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/left/view_07.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(223, 85, 544, 471),
      viewportBounds: Rect.fromLTRB(196, 46, 572, 487),
    ),
  ],
);

final IlDuTurntableSpec kIlDuHyeopmunEastTurntable = IlDuTurntableSpec(
  anchorId: 'hyeopmun-east',
  mapAspectRatio: 0.84234234,
  frames: <IlDuTurntableFrame>[
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/right/view_00.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(224, 47, 570, 487),
      viewportBounds: Rect.fromLTRB(197, 43, 571, 487),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/right/view_01.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(222, 47, 549, 463),
      viewportBounds: Rect.fromLTRB(197, 43, 571, 487),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/right/view_02.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(212, 75, 571, 479),
      viewportBounds: Rect.fromLTRB(197, 43, 571, 487),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/right/view_03.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(253, 115, 538, 477),
      viewportBounds: Rect.fromLTRB(197, 43, 571, 487),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/right/view_04.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(198, 92, 544, 483),
      viewportBounds: Rect.fromLTRB(197, 43, 571, 487),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/right/view_05.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(220, 57, 545, 464),
      viewportBounds: Rect.fromLTRB(197, 43, 571, 487),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/right/view_06.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(197, 43, 556, 481),
      viewportBounds: Rect.fromLTRB(197, 43, 571, 487),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/right/view_07.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(230, 61, 515, 482),
      viewportBounds: Rect.fromLTRB(197, 43, 571, 487),
    ),
  ],
);

final IlDuTurntableSpec kIlDuAnchaeStoreTurntable = IlDuTurntableSpec(
  anchorId: 'anchae-store',
  mapAspectRatio: 1.39351852,
  frames: <IlDuTurntableFrame>[
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/angotgan/view_06.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(83, 98, 685, 448),
      viewportBounds: Rect.fromLTRB(83, 45, 685, 477),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/angotgan/view_07.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(172, 45, 596, 476),
      viewportBounds: Rect.fromLTRB(83, 45, 685, 477),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/angotgan/view_00.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(131, 54, 637, 475),
      viewportBounds: Rect.fromLTRB(83, 45, 685, 477),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/angotgan/view_01.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(89, 119, 679, 430),
      viewportBounds: Rect.fromLTRB(83, 45, 685, 477),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/angotgan/view_02.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(83, 98, 685, 449),
      viewportBounds: Rect.fromLTRB(83, 45, 685, 477),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/angotgan/view_03.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(172, 45, 596, 477),
      viewportBounds: Rect.fromLTRB(83, 45, 685, 477),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/angotgan/view_04.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(131, 54, 637, 475),
      viewportBounds: Rect.fromLTRB(83, 45, 685, 477),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/angotgan/view_05.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(89, 119, 679, 430),
      viewportBounds: Rect.fromLTRB(83, 45, 685, 477),
    ),
  ],
);

final IlDuTurntableSpec kIlDuGokganTurntable = IlDuTurntableSpec(
  anchorId: 'gokgan',
  mapAspectRatio: 1.54133333,
  frames: <IlDuTurntableFrame>[
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/gokgan/view_06.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(95, 104, 673, 467),
      viewportBounds: Rect.fromLTRB(95, 99, 673, 474),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/gokgan/view_07.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(200, 104, 568, 462),
      viewportBounds: Rect.fromLTRB(95, 99, 673, 474),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/gokgan/view_00.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(105, 99, 662, 474),
      viewportBounds: Rect.fromLTRB(95, 99, 673, 474),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/gokgan/view_01.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(125, 138, 642, 434),
      viewportBounds: Rect.fromLTRB(95, 99, 673, 474),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/gokgan/view_02.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(95, 104, 673, 444),
      viewportBounds: Rect.fromLTRB(95, 99, 673, 474),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/gokgan/view_03.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(200, 104, 568, 439),
      viewportBounds: Rect.fromLTRB(95, 99, 673, 474),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/gokgan/view_04.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(105, 99, 662, 450),
      viewportBounds: Rect.fromLTRB(95, 99, 673, 474),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/gokgan/view_05.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(125, 138, 642, 414),
      viewportBounds: Rect.fromLTRB(95, 99, 673, 474),
    ),
  ],
);

final IlDuTurntableSpec kIlDuToiletNorthTurntable = IlDuTurntableSpec(
  anchorId: 'toilet-north',
  mapAspectRatio: 1.01418440,
  frames: <IlDuTurntableFrame>[
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/toilet/view_00.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(170, 71, 599, 483),
      viewportBounds: Rect.fromLTRB(170, 61, 599, 484),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/toilet/view_01.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(233, 61, 535, 468),
      viewportBounds: Rect.fromLTRB(170, 61, 599, 484),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/toilet/view_02.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(170, 70, 597, 482),
      viewportBounds: Rect.fromLTRB(170, 61, 599, 484),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/toilet/view_03.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(217, 95, 552, 461),
      viewportBounds: Rect.fromLTRB(170, 61, 599, 484),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/toilet/view_04.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(170, 72, 599, 482),
      viewportBounds: Rect.fromLTRB(170, 61, 599, 484),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/toilet/view_05.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(233, 61, 535, 468),
      viewportBounds: Rect.fromLTRB(170, 61, 599, 484),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/toilet/view_06.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(170, 70, 597, 484),
      viewportBounds: Rect.fromLTRB(170, 61, 599, 484),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/toilet/view_07.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(217, 95, 552, 467),
      viewportBounds: Rect.fromLTRB(170, 61, 599, 484),
    ),
  ],
);

final IlDuTurntableSpec kIlDuToiletSouthTurntable = IlDuTurntableSpec(
  anchorId: 'toilet-south',
  mapAspectRatio: 1.00480769,
  frames: <IlDuTurntableFrame>[
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/toilet1/view_00.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(175, 75, 593, 480),
      viewportBounds: Rect.fromLTRB(175, 64, 593, 480),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/toilet1/view_01.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(236, 64, 531, 464),
      viewportBounds: Rect.fromLTRB(175, 64, 593, 480),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/toilet1/view_02.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(175, 73, 593, 478),
      viewportBounds: Rect.fromLTRB(175, 64, 593, 480),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/toilet1/view_03.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(220, 98, 548, 457),
      viewportBounds: Rect.fromLTRB(175, 64, 593, 480),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/toilet1/view_04.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(175, 75, 593, 477),
      viewportBounds: Rect.fromLTRB(175, 64, 593, 480),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/toilet1/view_05.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(236, 64, 531, 464),
      viewportBounds: Rect.fromLTRB(175, 64, 593, 480),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/toilet1/view_06.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(175, 73, 593, 480),
      viewportBounds: Rect.fromLTRB(175, 64, 593, 480),
    ),
    IlDuTurntableFrame(
      assetPath: 'assets/illustrations/ildu_r16_support/turnarounds/toilet1/view_07.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(220, 98, 548, 462),
      viewportBounds: Rect.fromLTRB(175, 64, 593, 480),
    ),
  ],
);

final IlDuTurntableSpec kIlDuOutsideGateTurntable = IlDuTurntableSpec(
  anchorId: 'outside-gate',
  mapAspectRatio: 0.84234234,
  frames: <IlDuTurntableFrame>[
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/right/view_00.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(224, 47, 570, 487),
      viewportBounds: Rect.fromLTRB(197, 43, 571, 487),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/right/view_01.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(222, 47, 549, 463),
      viewportBounds: Rect.fromLTRB(197, 43, 571, 487),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/right/view_02.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(212, 75, 571, 479),
      viewportBounds: Rect.fromLTRB(197, 43, 571, 487),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/right/view_03.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(253, 115, 538, 477),
      viewportBounds: Rect.fromLTRB(197, 43, 571, 487),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/right/view_04.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(198, 92, 544, 483),
      viewportBounds: Rect.fromLTRB(197, 43, 571, 487),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/right/view_05.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(220, 57, 545, 464),
      viewportBounds: Rect.fromLTRB(197, 43, 571, 487),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/right/view_06.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(197, 43, 556, 481),
      viewportBounds: Rect.fromLTRB(197, 43, 571, 487),
    ),
    IlDuTurntableFrame(
      assetPath:
          'assets/illustrations/ildu_r16_support/turnarounds/right/view_07.png',
      sourceSize: Size(768, 512),
      contentBounds: Rect.fromLTRB(230, 61, 515, 482),
      viewportBounds: Rect.fromLTRB(197, 43, 571, 487),
    ),
  ],
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
      kIlDuOutsideGateTurntable.anchorId: kIlDuOutsideGateTurntable,
    };

IlDuTurntableSpec? ilduTurntableForAnchor(String anchorId) =>
    kIlDuTurntables[anchorId];
