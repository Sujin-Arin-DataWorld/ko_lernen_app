import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/approved_games_preview_data.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_games_demo.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/einleitung_capture_assets.dart';
import 'support/real_fonts.dart';
import 'support/sori_speech_stubs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadEinleitungFonts();
    await loadSoriRealFonts();
  });

  test(
    'every level keeps shipped vocabulary, cloze, puzzle and chain identities',
    () async {
      final puzzleBundle =
          jsonDecode(File('assets/data/silben_puzzles.json').readAsStringSync())
              as Map;
      final clozeBundle =
          jsonDecode(File('assets/data/cloze.json').readAsStringSync()) as Map;
      final clozeIds = {for (final item in clozeBundle['items']) item['id']};
      for (final level in LearnerLevel.values) {
        final data = await ApprovedGamesPreviewData.load(level);
        expect(data.words.every((word) => word.hasExplicitId), isTrue);
        expect(
          data.words.every((word) => word.level.toLowerCase() == level.code),
          isTrue,
        );
        expect(clozeIds, contains(data.daily.id));
        expect(data.daily.level, level.code);
        expect(data.puzzle.id, puzzleBundle['levels'][level.display][0]['id']);
        expect(data.chain.first.last, data.chain[1].first);
        expect(data.chain.first.word, isNot(data.chain[1].word));
        expect(data.chain.first.level.toLowerCase(), level.code);
      }
      expect(OnboardingGamesDemo.activityIds, [
        'chosung',
        'syllable_cross',
        'daily_game',
        'speed_match',
        'kkeunmari',
        'custom_practice',
      ]);
    },
  );

  testWidgets(
    'full-screen preview returns to the exact owner without learner writes',
    (tester) async {
      SharedPreferences.setMockInitialValues({'kl_xp': 42, 'kl_level': 'b1'});
      final speech = stubSoriSpeech();
      final prefs = await SharedPreferences.getInstance();
      final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final selected = ValueNotifier<int>(4);
      addTearDown(selected.dispose);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          theme: AppTheme.light,
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: selected,
                    builder: (_, value, child) => Text(
                      'Einleitung $value',
                      key: const ValueKey('owner-state'),
                    ),
                  ),
                  TextButton(
                    key: const ValueKey('open-games'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        fullscreenDialog: true,
                        builder: (_) => const OnboardingGamesDemo.fullScreen(
                          level: LearnerLevel.a1,
                        ),
                      ),
                    ),
                    child: const Text('Vorschau'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('open-games')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('demo-game-5')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('demo-card-flip')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('demo-game-audio')));
      await tester.pumpAndSettle();
      expect(speech.spoken, isNotEmpty);
      await tester.tap(find.byKey(const ValueKey('demo-games-back')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('demo-games-close')));
      await tester.pumpAndSettle();
      expect(find.text('Einleitung 4'), findsOneWidget);
      expect(selected.value, 4);
      expect(speech.stops, greaterThan(0));
      expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, before);
      expect(tester.takeException(), isNull);
    },
  );

  if (const bool.fromEnvironment('CAPTURE_SPIELE_PREVIEW_EVIDENCE')) {
    testWidgets('capture native preview art and live interaction states', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      stubSoriSpeech();
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundary = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: const Locale('de'),
            theme: AppTheme.light,
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            home: const OnboardingGamesDemo.fullScreen(level: LearnerLevel.a1),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final directory = Directory(
        'C:/dev/hangulsori/_codex_artifacts/spiele-preview-fit-20261029/captures',
      )..createSync(recursive: true);
      Future<void> capture(String name) async {
        await settleEinleitungCaptureAssets(tester);
        await tester.runAsync(() async {
          final render =
              boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary;
          final picture = await render.toImage(pixelRatio: 1);
          final bytes = (await picture.toByteData(
            format: ui.ImageByteFormat.png,
          ))!;
          File(
            '${directory.path}/$name.png',
          ).writeAsBytesSync(bytes.buffer.asUint8List());
          picture.dispose();
        });
      }

      await capture('00-picker');
      for (var game = 0; game < 6; game++) {
        await tester.ensureVisible(find.byKey(ValueKey('demo-game-$game')));
        await tester.tap(find.byKey(ValueKey('demo-game-$game')));
        await tester.pumpAndSettle();
        await capture('0${game + 1}-${OnboardingGamesDemo.activityIds[game]}');
        await tester.tap(find.byKey(const ValueKey('demo-games-back')));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  }
}
