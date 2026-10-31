import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/ildu_r16_art.dart';
import 'package:ko_lernen_app/models/ildu_r16_layers.dart';
import 'package:ko_lernen_app/widgets/sori/ildu_r16_layer_artwork.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final original = IlDuR16ArtCatalog.fromJson(
    jsonDecode(File(IlDuR16ArtCatalog.assetPath).readAsStringSync()),
  );

  test(
    'layer catalog retains all exact approved standalone process identities',
    () {
      final catalog = IlDuR16LayerCatalog.fromJson(
        _catalog(original),
        original: original,
      );
      expect(
        catalog.stagesByProcessId.keys,
        original.buildings.first.stages.map((s) => s.processId),
      );
    },
  );

  test('rejects partial stages, changed source or mismatched layer canvas', () {
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (m) => (m['stages'] as List).removeLast(),
      (m) => m['sourceCatalogSha256'] = 'other',
      (m) => (m['stages'] as List)[0]['sourceImageSha256'] = 'other',
      (m) => (m['stages'] as List)[0]['processId'] = 'ildu.future-house',
      (m) => (m['stages'] as List)[0]['shadow']['width'] = 1799,
      (m) => (m['stages'] as List)[0]['foreground']['asset'] =
          'assets/old-white.png',
      (m) => m['progressOrOwnershipMigrationIncluded'] = true,
    ]) {
      final json = _catalog(original);
      mutate(json);
      expect(
        () => IlDuR16LayerCatalog.fromJson(json, original: original),
        throwsFormatException,
      );
    }
  });

  for (final background in [const Color(0xff005044), const Color(0xfffff1d6)]) {
    for (final opacity in [1.0, .24]) {
      testWidgets(
        'neutral shadow corners preserve $background at opacity $opacity',
        (tester) async {
          await tester.runAsync(() async {
            final shadow = await _image((canvas) {
              canvas.drawColor(Colors.white, BlendMode.src);
              canvas.drawRect(
              const Rect.fromLTWH(16, 16, 32, 32),
                Paint()..color = const Color(0xff808080),
              );
            });
            final foreground = await _image((canvas) {});
            final recorder = ui.PictureRecorder();
            final canvas = Canvas(recorder)
              ..drawColor(background, BlendMode.src);
            IlDuR16LayerPainter(
              shadow: shadow,
              foreground: foreground,
              opacity: opacity,
            ).paint(canvas, const Size(80, 40));
            final picture = recorder.endRecording();
            final output = await picture.toImage(80, 40);
            final bytes = (await output.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!;
            List<int> pixel(int x, int y) =>
                List.generate(4, (i) => bytes.getUint8((y * 80 + x) * 4 + i));
            final expected = [
              background.r,
              background.g,
              background.b,
            ].map((c) => (c * 255).round()).toList();
            for (final point in [
              const Offset(0, 0),
              const Offset(21, 1),
              const Offset(58, 38),
              const Offset(79, 39),
            ]) {
              expect(pixel(point.dx.toInt(), point.dy.toInt()), [
                ...expected,
                255,
              ]);
            }
            final darkened = pixel(40, 20);
            final multiplier = 1 + opacity * (128 / 255 - 1);
            for (var channel = 0; channel < 3; channel++) {
              expect(
                darkened[channel],
                closeTo(expected[channel] * multiplier, 2),
              );
            }
            expect(darkened[3], 255);
            output.dispose();
            picture.dispose();
            shadow.dispose();
            foreground.dispose();
          });
        },
      );
    }
  }

  testWidgets(
    'foreground is composited after shadow with identical contain fit',
    (tester) async {
      await tester.runAsync(() async {
        final shadow = await _image(
          (canvas) => canvas.drawColor(const Color(0xff808080), BlendMode.src),
        );
        final foreground = await _image(
          (canvas) => canvas.drawRect(
            const Rect.fromLTWH(16, 16, 32, 32),
            Paint()..color = Colors.orange,
          ),
        );
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder)..drawColor(Colors.teal, BlendMode.src);
        IlDuR16LayerPainter(
          shadow: shadow,
          foreground: foreground,
        ).paint(canvas, const Size(80, 40));
        final picture = recorder.endRecording();
        final image = await picture.toImage(80, 40);
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final center = 4 * (20 * 80 + 40);
        expect(List.generate(4, (i) => bytes.getUint8(center + i)), [
          255,
          152,
          0,
          255,
        ]);
        image.dispose();
        picture.dispose();
        shadow.dispose();
        foreground.dispose();
      });
    },
  );
}

Future<ui.Image> _image(void Function(Canvas) draw) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(64, 64);
  picture.dispose();
  return image;
}

Map<String, dynamic> _catalog(IlDuR16ArtCatalog original) {
  final hash = List.filled(64, 'a').join();
  Map<String, dynamic> image() => {
    'asset': 'assets/illustrations/ildu_r16_layers/$hash.png',
    'sha256': hash,
    'bytes': 20,
    'width': 1800,
    'height': 1200,
  };
  return {
    'schemaVersion': 1,
    'presentationOnly': true,
    'sourceCatalogSha256': IlDuR16LayerCatalog.sourceCatalogSha256,
    'canonicalPromotionSha256': IlDuR16LayerCatalog.canonicalPromotionSha256,
    'shadowOperation': 'multiply-then-foreground-source-over',
    'progressOrOwnershipMigrationIncluded': false,
    'stages': [
      for (final stage in original.buildings.first.stages)
        {
          'sequence': stage.sequence,
          'processId': stage.processId,
          'sourceImageSha256': stage.image.sha256,
          'foreground': image(),
          'shadow': image(),
        },
    ],
  };
}
