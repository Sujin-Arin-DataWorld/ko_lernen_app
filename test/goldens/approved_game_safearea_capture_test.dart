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

import '../../tool/visual_review/approved_game_gallery.dart';
import '../support/real_fonts.dart';

// Explicit evidence gate. Never creates or updates approved golden baselines.
// flutter test --no-pub test/goldens/approved_game_safearea_capture_test.dart
//   --dart-define=CAPTURE_APPROVED_GAMES=<absolute output directory>
const _captureDirectory = String.fromEnvironment('CAPTURE_APPROVED_GAMES');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'capture six native-frame fixtures with Android SafeArea',
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
          'MaruBuri': [
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
      tester.view.devicePixelRatio = 2.75;
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.padding = const FakeViewPadding(top: 74.25, bottom: 148.5);
      tester.view.viewPadding = const FakeViewPadding(
        top: 74.25,
        bottom: 148.5,
      );
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
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
      for (var fixture = 0; fixture < 6; fixture++) {
        await tester.pumpWidget(
          ApprovedGameGalleryApp(
            key: ValueKey(fixture),
            fixture: fixture,
            normalizeCapture: false,
            captureKey: boundaryKey,
          ),
        );
        final context = tester.element(find.byType(ApprovedGameFrame));
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
        expect(
          tester.getSize(find.byKey(boundaryKey)),
          const Size(1080 / 2.75, 2400 / 2.75),
        );
        expect(
          tester.getRect(find.byType(ApprovedGameNavigation)),
          const Rect.fromLTWH(0, 2400 / 2.75 - 54 - 82, 1080 / 2.75, 82),
        );
        final scrollable = tester.state<ScrollableState>(
          find.byType(Scrollable).first,
        );
        expect(scrollable.position.maxScrollExtent, lessThanOrEqualTo(.01));
        final navigation = tester.getRect(find.byType(ApprovedGameNavigation));
        final targets = [
          if (fixture < 3)
            for (var i = 0; i < 4; i++)
              tester.getRect(find.byKey(ValueKey('approved-quiz-choice-$i')))
          else
            for (var i = 0; i < 6; i++)
              for (final side in ['left', 'right'])
                tester.getRect(
                  find.byKey(ValueKey('approved-matching-$side-$i')),
                ),
        ];
        final minimumTargetHeight = targets
            .map((rect) => rect.height)
            .reduce((a, b) => a < b ? a : b);
        final lastTargetBottom = targets
            .map((rect) => rect.bottom)
            .reduce((a, b) => a > b ? a : b);
        final navigationClearance = navigation.top - lastTargetBottom;
        expect(minimumTargetHeight, greaterThanOrEqualTo(48));
        expect(navigationClearance, greaterThanOrEqualTo(15.99));
        final name =
            '${approvedGameFixtureNames[fixture]}-safe-area-flutter.png';
        await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(boundaryKey),
          );
          final image = await boundary.toImage(pixelRatio: 2.75);
          expect(image.width, 1080);
          expect(image.height, 2400);
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          final output = File('$_captureDirectory/$name');
          await output.parent.create(recursive: true);
          await output.writeAsBytes(png!.buffer.asUint8List(), flush: true);
          image.dispose();
          records.add({
            'fixture': fixture,
            'name': name,
            'bytes': await output.length(),
            'minimumTargetHeightDp': minimumTargetHeight,
            'lastTargetToNavigationDp': navigationClearance,
            'scrollExtentDp': scrollable.position.maxScrollExtent,
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
                'Approved Figma text overrides in gallery only; no production per-word lookup',
            'engineValidation':
                'Separate widget and recovery tests; not established by these images',
            'viewport': [1080 / 2.75, 2400 / 2.75],
            'devicePixelRatio': 2.75,
            'textScale': 1,
            'locale': 'de',
            'safeAreaNormalization':
                'Android-like top27/bottom54dp, production Frame and navigation; widget-render evidence, not an OS screenshot',
            'files': records,
          }),
        );
      });
    },
  );
}
