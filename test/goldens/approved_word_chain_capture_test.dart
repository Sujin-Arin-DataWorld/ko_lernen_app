import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/approved_games/approved_game_material.dart';

import '../../tool/visual_review/approved_word_chain_gallery.dart';
import 'package:ko_lernen_app/widgets/sori/approved_games/approved_word_chain_view.dart';
import '../support/real_fonts.dart';

// Explicit evidence gate. Never creates or updates approved golden baselines.
// flutter test --no-pub test/goldens/approved_word_chain_capture_test.dart
//   --dart-define=CAPTURE_APPROVED_WORD_CHAIN=<absolute output directory>
const _captureDirectory = String.fromEnvironment('CAPTURE_APPROVED_WORD_CHAIN');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'capture three approved word-chain presentation fixtures at 402x874',
    skip: _captureDirectory.isEmpty,
    (tester) async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({'kl_tts_speed_v1': 1.0});
      await Storage.init();
      addTearDown(Storage.resetForTesting);
      await tester.runAsync(() async {
        await loadSoriRealFonts(materialIcons: true);
        for (final entry in {
          'Lora': ['assets/fonts/Lora/Lora-Variable.ttf'],
          'MaruBuriOTF': [
            'assets/fonts/MaruBuri/MaruBuri-Regular.otf',
            'assets/fonts/MaruBuri/MaruBuri-SemiBold.otf',
            'assets/fonts/MaruBuri/MaruBuri-Bold.otf',
          ],
        }.entries) {
          final loader = FontLoader(entry.key);
          for (final path in entry.value) {
            loader.addFont(rootBundle.load(path));
          }
          await loader.load();
        }
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(402, 874);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final oldCacheLimit =
          PaintingBinding.instance.imageCache.maximumSizeBytes;
      PaintingBinding.instance.imageCache.maximumSizeBytes = 256 << 20;
      addTearDown(
        () => PaintingBinding.instance.imageCache.maximumSizeBytes =
            oldCacheLimit,
      );

      const boundaryKey = ValueKey('approved-game-evidence');
      final records = <Map<String, Object>>[];
      for (var fixture = 0; fixture < 3; fixture++) {
        await tester.pumpWidget(
          ApprovedWordChainGalleryApp(
            key: ValueKey(fixture),
            fixture: fixture,
            normalizeCapture: true,
            captureKey: boundaryKey,
          ),
        );
        final context = tester.element(find.byType(ApprovedWordChainFrame));
        await tester.runAsync(() async {
          final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
          await Future.wait([
            for (final path in manifest.listAssets())
              if (path.startsWith('assets/illustrations/approved_games/') &&
                  path.endsWith('.png'))
                precacheImage(AssetImage(path), context),
          ]);
        });
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byKey(boundaryKey)), const Size(402, 874));
        expect(
          tester.getRect(find.byType(ApprovedGameNavigation)),
          const Rect.fromLTWH(0, 792, 402, 82),
        );
        final name = '${approvedWordChainFixtureNames[fixture]}-flutter.png';
        await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(boundaryKey),
          );
          final image = await boundary.toImage(pixelRatio: 1);
          expect(image.width, 402);
          expect(image.height, 874);
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          final output = File('$_captureDirectory/$name');
          await output.parent.create(recursive: true);
          await output.writeAsBytes(png!.buffer.asUint8List(), flush: true);
          image.dispose();
          records.add({
            'fixture': fixture,
            'name': name,
            'bytes': await output.length(),
          });
        });
        await tester.pumpWidget(const SizedBox());
      }
      await tester.runAsync(() async {
        await File('$_captureDirectory/CAPTURE_MANIFEST.json').writeAsString(
          const JsonEncoder.withIndent('  ').convert({
            'capturedAtUtc': DateTime.now().toUtc().toIso8601String(),
            'evidenceKind':
                'Flutter presentation fixtures using production view widgets',
            'fixtureLineBreaks':
                'Approved content states in gallery only; production layout measures actual text',
            'engineValidation':
                'Separate widget and recovery tests; not established by these images',
            'viewport': [402, 874],
            'devicePixelRatio': 1,
            'textScale': 1,
            'locale': 'de',
            'safeAreaNormalization':
                'zero insets for approved Figma comparison',
            'files': records,
          }),
        );
      });
    },
  );
}
