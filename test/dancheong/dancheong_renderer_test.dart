import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_models.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_renderer.dart';
import '../support/real_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadSoriRealFonts);
  DancheongArtwork art(DancheongTemplate template, DancheongFormat format) =>
      DancheongArtwork(
        id: '00000000-0000-4000-8000-000000000001',
        revision: 1,
        completedAt: DateTime.utc(2026, 10, 3),
        composition: DancheongComposition(
          template: template,
          format: format,
          motifSlugs: ['lotus'],
          koreanText: '안녕, Jürgen\n${'가' * 60}',
          translation: 'Grüße aus meinem Atelier! ${'ä' * 100}',
          signature: 'Jürgen',
        ),
      );
  for (final template in DancheongTemplate.values) {
    for (final format in DancheongFormat.values) {
      test(
        '${template.name} ${format.name} produces actual full-size PNG',
        () async {
          final result = await DancheongRenderer().render(
            art(template, format),
            ownedSlugs: {'lotus'},
          );
          final codec = await ui.instantiateImageCodec(result.png);
          final frame = await codec.getNextFrame();
          expect(frame.image.width, 1080);
          expect(
            frame.image.height,
            format == DancheongFormat.story ? 1920 : 1350,
          );
          expect(result.sha256.length, 64);
          frame.image.dispose();
          codec.dispose();
        },
      );
    }
  }
  test(
    'missing source and unowned material fail without substituting lotus',
    () async {
      await expectLater(
        DancheongRenderer(bundle: _MissingBundle()).render(
          art(DancheongTemplate.letter, DancheongFormat.portrait),
          ownedSlugs: {'lotus'},
        ),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        DancheongRenderer().render(
          art(DancheongTemplate.flower, DancheongFormat.portrait),
          ownedSlugs: {},
        ),
        throwsA(isA<StateError>()),
      );
    },
  );
}

class _MissingBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => throw Exception('Missing source');
}
