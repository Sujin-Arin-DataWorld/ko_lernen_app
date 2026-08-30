import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as raster;
import 'package:ko_lernen_app/widgets/sori/ildu_sarangchae_construction_pilot.dart';

const _pilotAsset =
    'assets_unused/pending_review/personal_hanok_v3/'
    'sarangchae_construction_pilot_v1/sarangchae_v3_placement_angle_v1.png';

void main() {
  final geometry = SarangchaeGeometry.standard();

  setUpAll(() async {
    final bytes = File(
      'assets/fonts/WantedSans/WantedSans-Bold.otf',
    ).readAsBytesSync();
    final loader = FontLoader('WantedSans')
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  });

  test('front and rear post counts stay paired for main body and numaru', () {
    expect(geometry.frontPostCount, 10);
    expect(geometry.rearPostCount, 10);
    expect(geometry.frontPostCount, geometry.rearPostCount);
  });

  test('every post head is reused by at least one beam endpoint', () {
    final beamEndpoints = {
      for (final beam in geometry.beams) ...[beam.start, beam.end],
    };
    final heads = {
      ...geometry.mainFrontHeads,
      ...geometry.mainRearHeads,
      ...geometry.wingFrontHeads,
      ...geometry.wingRearHeads,
    };
    expect(beamEndpoints.containsAll(heads), isTrue);
  });

  test('every rafter joins one locked ridge and one locked eave', () {
    bool onSegment(Offset point, SarangchaeSegment segment) {
      final cross =
          (point.dx - segment.start.dx) * (segment.end.dy - segment.start.dy) -
          (point.dy - segment.start.dy) * (segment.end.dx - segment.start.dx);
      if (cross.abs() > 0.000001) return false;
      final dot =
          (point.dx - segment.start.dx) * (point.dx - segment.end.dx) +
          (point.dy - segment.start.dy) * (point.dy - segment.end.dy);
      return dot <= 0.000001;
    }

    for (final rafter in geometry.rafters) {
      expect(
        geometry.ridges.any((ridge) => onSegment(rafter.start, ridge)),
        isTrue,
      );
      expect(geometry.eaves.any((eave) => onSegment(rafter.end, eave)), isTrue);
    }
  });

  test('all eight phases share one immutable geometry instance', () {
    final identity = identityHashCode(geometry);
    for (final phase in SarangchaeBuildPhase.values) {
      final widget = SarangchaeConstructionPilot(
        phase: phase,
        geometry: geometry,
      );
      expect(identityHashCode(widget.geometry), identity);
    }
  });

  test('finished pilot is a real transparent RGBA sprite', () {
    final decoded = raster.decodePng(File(_pilotAsset).readAsBytesSync());
    expect(decoded, isNotNull);
    expect(decoded!.numChannels, 4);
    var hasTransparentPixel = false;
    var hasVisiblePixel = false;
    for (final pixel in decoded) {
      hasTransparentPixel |= pixel.a == 0;
      hasVisiblePixel |= pixel.a > 200;
      if (hasTransparentPixel && hasVisiblePixel) break;
    }
    expect(hasTransparentPixel, isTrue);
    expect(hasVisiblePixel, isTrue);
  });

  testWidgets('renders the eight-stage Sarangchae approval sheet', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final bytes = File(_pilotAsset).readAsBytesSync();
    final image = await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(bytes);
      return (await codec.getNextFrame()).image;
    });
    expect(image, isNotNull);
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: const ValueKey('sarangchae-pilot-sheet'),
          child: ColoredBox(
            color: const Color(0xFFF4E5C6),
            child: SizedBox(
              width: 1600,
              height: 900,
              child: Column(
                children: [
                  for (var row = 0; row < 2; row++)
                    Expanded(
                      child: Row(
                        children: [
                          for (var column = 0; column < 4; column++)
                            Expanded(
                              child: _ReviewTile(
                                phase: SarangchaeBuildPhase
                                    .values[row * 4 + column],
                                image: image!,
                                geometry: geometry,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byKey(const ValueKey('sarangchae-pilot-sheet')),
      matchesGoldenFile('goldens/ildu_sarangchae_construction_pilot_v1.png'),
    );
  });
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.phase,
    required this.image,
    required this.geometry,
  });

  final SarangchaeBuildPhase phase;
  final ui.Image image;
  final SarangchaeGeometry geometry;

  static const labels = [
    '1 자리 잡기',
    '2 초석·돌기단',
    '3 앞뒤 기둥',
    '4 보·도리',
    '5 앞뒤 서까래',
    '6 기와·용마루',
    '7 벽체·창호지',
    '8 완성 V3 사랑채',
  ];

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0x55785B32)),
    ),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              labels[phase.index],
              style: const TextStyle(
                fontFamily: 'WantedSans',
                color: Color(0xFF3F2A18),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Expanded(
          child: SarangchaeConstructionPilot(
            phase: phase,
            geometry: geometry,
            finishedImage: image,
          ),
        ),
      ],
    ),
  );
}
