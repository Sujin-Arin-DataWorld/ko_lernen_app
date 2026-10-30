import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/canonical_companion_art.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'only canonical companions ship while reward and onboarding art stays',
    () async {
      final assets = (await AssetManifest.loadFromAssetBundle(
        rootBundle,
      )).listAssets().toSet();
      final retired = <String>[
        for (final file in Directory(
          'assets/illustrations/mascot',
        ).listSync().whereType<File>())
          if (!['bok.png', 'yupjeon.png'].contains(file.uri.pathSegments.last))
            file.path.replaceAll('\\', '/'),
        'assets/illustrations/error/lost_magpie.png',
        'assets/illustrations/onboarding/tiger_crystal.png',
        for (final file in Directory(
          'assets/illustrations/onboarding/companions',
        ).listSync().whereType<File>())
          file.path.replaceAll('\\', '/'),
      ];
      for (final path in retired) {
        expect(assets, isNot(contains(path)), reason: path);
        expect(
          File(path).existsSync(),
          isTrue,
          reason: 'Keep the supplied original',
        );
      }
      for (final path in [
        'assets/illustrations/mascot/bok.png',
        'assets/illustrations/mascot/yupjeon.png',
        'assets/illustrations/error/offline_lantern.png',
        'assets/illustrations/onboarding/book_scan.png',
        'assets/illustrations/onboarding/book_extract.webp',
        'assets/illustrations/onboarding/gate-01-alpha.webp',
        'assets/illustrations/onboarding/gate-02-alpha.webp',
        'assets/illustrations/onboarding/sarangchae-01-alpha.webp',
        'assets/illustrations/onboarding/sarangchae-02-alpha.webp',
        'assets/illustrations/onboarding/sarangchae_canonical.webp',
      ]) {
        expect(assets, contains(path), reason: path);
        expect((await rootBundle.load(path)).lengthInBytes, greaterThan(0));
      }
    },
  );

  test(
    'canonical companion originals are bundled intact with real alpha',
    () async {
      final record =
          jsonDecode(
                File(
                  'docs/assets/canonical_companions_20261030.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final assets = (record['assets'] as List).cast<Map<String, dynamic>>();
      expect(assets.map((asset) => asset['asset']).toSet(), {
        CanonicalCompanionArt.baekhoStanding,
        CanonicalCompanionArt.baekhoGuide,
        CanonicalCompanionArt.baekhoSeated,
        CanonicalCompanionArt.baekhoPortrait,
        CanonicalCompanionArt.magpieStanding,
        CanonicalCompanionArt.magpieGuide,
        CanonicalCompanionArt.magpieCelebrate,
        CanonicalCompanionArt.magpiePortrait,
      });
      expect(assets.map((asset) => asset['sha256']).toSet(), hasLength(8));
      for (final asset in assets) {
        final path = asset['asset'] as String;
        final bundled = await rootBundle.load(path);
        final bytes = bundled.buffer.asUint8List(
          bundled.offsetInBytes,
          bundled.lengthInBytes,
        );
        expect(sha256.convert(bytes).toString(), asset['sha256'], reason: path);
        final codec = await ui.instantiateImageCodec(bytes, targetWidth: 48);
        try {
          final frame = await codec.getNextFrame();
          try {
            final pixels = await frame.image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            );
            expect(pixels, isNotNull, reason: path);
            final alpha = [
              for (var i = 3; i < pixels!.lengthInBytes; i += 4)
                pixels.getUint8(i),
            ];
            expect(alpha, contains(0), reason: '$path must remain a cutout');
            expect(
              alpha.reduce((a, b) => a > b ? a : b),
              // Small-image filtering can average antialiased alpha to 254.
              // Original full-resolution bytes are pinned separately above.
              greaterThanOrEqualTo(250),
              reason: '$path must retain its subject',
            );
            final width = frame.image.width;
            final height = frame.image.height;
            for (final index in [
              0,
              width - 1,
              width * (height - 1),
              width * height - 1,
            ]) {
              expect(
                alpha[index],
                0,
                reason: '$path must not have a baked matte',
              );
            }
          } finally {
            frame.image.dispose();
          }
        } finally {
          codec.dispose();
        }
      }
    },
  );

  test('superseded companion originals remain byte-preserved', () {
    final record =
        jsonDecode(
              File('docs/assets/TACTILE_UI_ASSETS.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    final originals = (record['supersededCompanionAssets'] as List)
        .cast<Map<String, dynamic>>();
    expect(originals, hasLength(2));
    for (final original in originals) {
      final path = original['path'] as String;
      expect(
        sha256.convert(File(path).readAsBytesSync()).toString(),
        original['sha256'],
        reason: path,
      );
    }
  });
}
