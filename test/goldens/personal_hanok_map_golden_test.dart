import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/data/personal_hanok_catalog.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/personal_hanok_map.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

const _goldenMapWidth = 768;

void main() {
  setUp(() {
    // Half the fixed 1536 x 1152 master canvas retains architectural detail
    // while keeping the golden files compact and deterministic.
    TestWidgetsFlutterBinding
            .instance
            .platformDispatcher
            .textScaleFactorTestValue =
        1;
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearTextScaleFactorTestValue();
  });

  testWidgets('canonical map — early estate', (tester) async {
    await _expectMap(
      tester,
      _projection(b1: .25),
      'baselines/personal_hanok_map_early.png',
    );
  });

  testWidgets('canonical map — mid estate', (tester) async {
    await _expectMap(
      tester,
      _projection(b1: 1, b2: .5),
      'baselines/personal_hanok_map_mid.png',
    );
  });

  testWidgets('canonical map — complete estate', (tester) async {
    await _expectMap(
      tester,
      _projection(b1: 1, b2: 1),
      'baselines/personal_hanok_map_complete.png',
    );
  });
}

Future<void> _expectMap(
  WidgetTester tester,
  PersonalHanokProjection projection,
  String baseline,
) async {
  tester.view.physicalSize = const Size(800, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await _precachePersonalHanokMapAssets(tester);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: Scaffold(
        backgroundColor: SoriColors.lightBg,
        body: Center(
          child: RepaintBoundary(
            key: const ValueKey('personal-hanok-map-golden-boundary'),
            child: SizedBox(
              width: 768,
              height: 576,
              child: PersonalHanokMap(
                projection: projection,
                zoneLabel: (zone) => zone.name,
                showTargets: false,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(tester.takeException(), isNull);
  await expectLater(
    find.byKey(const ValueKey('personal-hanok-map-golden-boundary')),
    matchesGoldenFile(baseline),
  );
}

/// Real asset decoding must happen outside widget tests' FakeAsync zone.
/// Precache the same resized provider key used by [PersonalHanokMap] at this
/// viewport; caching the full-size asset does not warm its `cacheWidth` image
/// and makes each golden render the previous test's layers.
Future<void> _precachePersonalHanokMapAssets(WidgetTester tester) async {
  final futures = <Future<void>>[];
  await tester.runAsync(() async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            futures.addAll(
              kPersonalHanokLayers.map(
                (layer) => precacheImage(
                  ResizeImage.resizeIfNeeded(
                    _goldenMapWidth,
                    null,
                    AssetImage(layer.assetPath),
                  ),
                  context,
                ),
              ),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await Future.wait(futures);
  });
}

PersonalHanokProjection _projection({required double b1, double b2 = 0}) =>
    PersonalHanokProjection.from(LevelRatios(a1: 1, a2: 1, b1: b1, b2: b2));
