import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_journey_scenes.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_story_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_copy.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v3_demo_support.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/einleitung_capture_assets.dart';
import 'support/real_fonts.dart';
import 'support/sori_speech_stubs.dart';

const _capture = Key('approved-book-preview-capture');
const _output = String.fromEnvironment('BOOK_PREVIEW_EVIDENCE_DIR');
const _captureArt =
    'assets/illustrations/onboarding/book_capture_approved_20261030.png';
const _studyArt =
    'assets/illustrations/onboarding/book_study_approved_20261030.png';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadSoriRealFonts();
    await loadEinleitungFonts();
  });

  test(
    'book illustrations preserve the exact approved source and crop provenance',
    () async {
      final manifest =
          jsonDecode(
                File(
                  'docs/assets/APPROVED_BOOK_PREVIEW_20261030.json',
                ).readAsStringSync(),
              )
              as Map;
      expect(manifest['items'], hasLength(2));
      for (final row in (manifest['items'] as List).cast<Map>()) {
        final bytes = File(row['assetPath'] as String).readAsBytesSync();
        expect(sha256.convert(bytes).toString(), row['sha256']);
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        expect([frame.image.width, frame.image.height], row['size']);
        frame.image.dispose();
        codec.dispose();
      }
      final rows = (manifest['items'] as List).cast<Map>();
      expect(
        rows[0]['sourceSha256'],
        'aaef1e2ab9a15dabd23013bdd4bead1bdd6bf573a18465bd948f8089ad2d93dd',
      );
      expect(
        rows[1]['sourceSha256'],
        'd3607520de81e1439c24714bfc5eff4d8ecf2ad488431ea148dcbc51f02b3d32',
      );
      expect(rows[0]['assetPath'], _captureArt);
      expect(rows[1]['assetPath'], _studyArt);
    },
  );

  for (final language in ['de', 'en']) {
    for (final configuration in [
      (size: const Size(320, 640), scale: 1.0, level: LearnerLevel.a1),
      (size: const Size(393, 873), scale: 1.0, level: LearnerLevel.c1),
      (size: const Size(320, 640), scale: 2.0, level: LearnerLevel.a1),
      (size: const Size(393, 873), scale: 2.0, level: LearnerLevel.c1),
    ]) {
      testWidgets(
        '$language approved book preview ${configuration.size} ${configuration.scale} keeps real content and no writes',
        (tester) async {
          SharedPreferences.setMockInitialValues({
            'kl_xp': 42,
            'kl_level': 'b1',
          });
          final prefs = await SharedPreferences.getInstance();
          final before = {
            for (final key in prefs.getKeys()) key: prefs.get(key),
          };
          final speech = stubSoriSpeech(completeSpeak: false);
          final t = lookupAppL10n(Locale(language));
          final allContent =
              jsonDecode(
                    File(
                      'assets/data/onboarding_v3_demo_content.json',
                    ).readAsStringSync(),
                  )
                  as Map;
          final course =
              ((allContent['levels'] as Map)[configuration.level.display]
                      as Map)['course']
                  as Map;
          final routeNames = _RouteNames();
          tester.view.physicalSize = configuration.size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            RepaintBoundary(
              key: _capture,
              child: MaterialApp(
                locale: Locale(language),
                theme: AppTheme.light,
                localizationsDelegates: AppL10n.localizationsDelegates,
                supportedLocales: AppL10n.supportedLocales,
                navigatorObservers: [routeNames],
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(configuration.scale),
                  ),
                  child: child!,
                ),
                home: OnboardingStoryScreen(
                  copy: onboardingV2Copy(t),
                  pageIndex: 3,
                  selectedLevel: configuration.level,
                  onContinue: (_) {},
                  onPrevious: (_) {},
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final open = find.byKey(const ValueKey('c-onboarding-preview-5'));
          await tester.ensureVisible(open);
          await tester.tap(open);
          await tester.pumpAndSettle();
          expect(find.byType(OnboardingBookScene), findsOneWidget);
          final photo = find.byKey(const ValueKey('onboarding-v3-book-photo'));
          expect(
            (tester.widget<Image>(photo).image as AssetImage).assetName,
            _captureArt,
          );
          await settleEinleitungCaptureAssets(tester);
          if (configuration.size.width == 393 && configuration.scale == 1) {
            await _write(tester, 'book-photo-$language-393-873');
          }
          final action = find.byKey(
            const ValueKey('onboarding-v3-book-action'),
          );
          expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
          await tester.tap(action);
          await tester.pump();
          final extract = find.byKey(
            const ValueKey('onboarding-v3-book-extract'),
          );
          if (configuration.scale == 1) {
            expect(extract, findsOneWidget);
            expect(
              (tester.widget<Image>(extract).image as AssetImage).assetName,
              _studyArt,
            );
            expect(tester.getSize(extract).height, greaterThan(0));
          }
          expect(
            tester
                .widget<JourneyReading>(find.byType(JourneyReading).first)
                .text,
            course['ko'],
          );
          if (configuration.size.width == 393 && configuration.scale == 1) {
            await _write(tester, 'book-study-$language-393-873');
          }
          await tester.tap(
            find.byKey(const ValueKey('onboarding-v3-book-meaning')),
          );
          await tester.pump();
          final readings = tester.widgetList<JourneyReading>(
            find.byType(JourneyReading),
          );
          expect(
            readings.map((reading) => reading.text),
            contains(course[language]),
          );
          await tester.tap(
            find.byKey(const ValueKey('onboarding-v3-book-audio')),
          );
          await tester.pump();
          expect(speech.spoken, [course['ko']]);
          await tester.tap(action);
          await tester.pump();
          expect(tester.widget<DemoChoice>(action).selected, isTrue);
          await tester.tap(
            find.byKey(const ValueKey('onboarding-v3-book-replay')),
          );
          await tester.pump();
          expect(photo, findsOneWidget);
          expect(
            find.byKey(const ValueKey('onboarding-v3-book-extract')),
            findsNothing,
          );
          expect(speech.stops, greaterThan(0));
          await tester.tap(
            find.byKey(const ValueKey('c-onboarding-sheet-close')),
          );
          await tester.pumpAndSettle();
          expect(find.byType(OnboardingBookScene), findsNothing);
          expect(
            routeNames.names.whereType<String>(),
            isNot(contains('/book')),
          );
          expect(
            routeNames.names.whereType<String>(),
            isNot(contains('/book/preview')),
          );
          expect({
            for (final key in prefs.getKeys()) key: prefs.get(key),
          }, before);
          speech.speakCompleter!.complete(true);
          await tester.pump();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

class _RouteNames extends NavigatorObserver {
  final names = <String?>[];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      names.add(route.settings.name);
}

Future<void> _write(WidgetTester tester, String name) async {
  if (_output.isEmpty) {
    return;
  }
  await settleEinleitungCaptureAssets(tester);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_capture),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final directory = Directory(_output)..createSync(recursive: true);
    File(
      '${directory.path}/$name.png',
    ).writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
