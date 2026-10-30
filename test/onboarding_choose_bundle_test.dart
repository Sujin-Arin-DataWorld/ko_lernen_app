import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'retired choose originals remain intact outside the app bundle',
    () async {
      const directory = 'assets/illustrations/onboarding/companions';
      final manifest =
          jsonDecode(
                await File(
                  'tool/onboarding_media/choose_manifest.json',
                ).readAsString(),
              )
              as Map<String, dynamic>;
      final assets = manifest['assets'] as List<dynamic>;
      final bundled = (await AssetManifest.loadFromAssetBundle(
        rootBundle,
      )).listAssets().toSet();
      expect(assets, hasLength(2));
      for (final asset in assets.cast<Map<String, dynamic>>()) {
        for (final kind in ['animation', 'poster']) {
          final path = '$directory/${asset[kind]}';
          expect(bundled, isNot(contains(path)));
          final data = await File(path).readAsBytes();
          expect(data.length, asset['${kind}_bytes']);
          final codec = await ui.instantiateImageCodec(data);
          expect(
            codec.frameCount,
            kind == 'animation' ? asset['frame_count'] : 1,
          );
          final frame = await codec.getNextFrame();
          expect([frame.image.width, frame.image.height], asset['canvas']);
          final rgba = await frame.image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          final bytes = rgba!.buffer.asUint8List();
          expect(bytes[3], 0, reason: 'The corner has real transparency.');
          expect(
            [for (var i = 3; i < bytes.length; i += 4) bytes[i]],
            contains(255),
            reason:
                'A visible character remains inside the transparent canvas.',
          );
          frame.image.dispose();
          codec.dispose();
        }
      }
    },
  );
}
