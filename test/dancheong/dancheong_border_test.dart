import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_models.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_renderer.dart';
import '../support/real_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadSoriRealFonts);
  test(
    'border choice persists and old documents keep their unframed composition',
    () {
      final c = DancheongComposition(
        template: DancheongTemplate.flower,
        format: DancheongFormat.portrait,
        motifSlugs: ['lotus'],
        border: DancheongBorder.lotusScroll,
      );
      expect(
        DancheongComposition.fromJson(c.toJson()).border,
        DancheongBorder.lotusScroll,
      );
      final legacy = c.toJson()..remove('border');
      expect(
        DancheongComposition.fromJson(legacy).border,
        DancheongBorder.none,
      );
    },
  );
  test(
    'both original frames actually change PNG pixels and fit portrait/story',
    () async {
      final hashes = <String>{};
      for (final border in DancheongBorder.values) {
        for (final format in DancheongFormat.values) {
          final c = DancheongComposition(
            template: DancheongTemplate.flower,
            format: format,
            motifSlugs: ['lotus'],
            border: border,
            koreanText: '안녕, Jürgen',
            translation: 'My first Korean artwork',
            signature: 'Jürgen',
          );
          final art = DancheongArtwork(
            id: '00000000-0000-4000-8000-000000000001',
            revision: 1,
            composition: c,
            completedAt: DateTime.utc(2026),
          );
          final p = await DancheongRenderer().render(
            art,
            ownedSlugs: {'lotus'},
          );
          hashes.add(p.sha256);
          final codec = await ui.instantiateImageCodec(p.png);
          final frame = await codec.getNextFrame();
          expect(frame.image.width, 1080);
          expect(
            frame.image.height,
            format == DancheongFormat.story ? 1920 : 1350,
          );
          frame.image.dispose();
          codec.dispose();
          if (Platform.environment['CAPTURE_DANCHEONG_EVIDENCE'] == '1') {
            final directory = Directory(
              '.superpowers/sdd/2026-10-03-dancheong-app-connection/exports',
            )..createSync(recursive: true);
            await File(
              '${directory.path}/${border.name}-${format.name}.png',
            ).writeAsBytes(p.png);
          }
        }
      }
      expect(hashes.length, 8);
    },
  );
  test('new artwork defaults to the selected asymmetric brocade frame', () {
    expect(
      DancheongComposition(
        template: DancheongTemplate.flower,
        format: DancheongFormat.portrait,
        motifSlugs: ['lotus'],
      ).border.name,
      'brocadeFlow',
    );
  });
}
