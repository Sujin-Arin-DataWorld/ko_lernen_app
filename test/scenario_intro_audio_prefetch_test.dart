import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/speakable.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

import 'support/scenario_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SoriSpeech.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'kl_tut_scenario': true,
      'kl_tut_wordbook': true,
    });
    await Storage.init();
  });

  tearDown(SoriSpeech.resetForTesting);

  test('first dialog line selects the playback voice and v3 cache key', () {
    final request = scenarioIntroAudioPrefetchFor(
      scenarioAirportArrivalFixture,
    );

    expect(request, isNotNull);
    expect(request!.text, '여권 보여주세요.');
    expect(request.voice, 'male');
    expect(
      request.cacheKey.storagePath,
      'tts/v3/male/35972279e5f04e1dd85b3528a799c657ef46a017.mp3',
    );
  });

  test('all 120 canonical intro requests match the checked manifest keys', () {
    final manifest =
        jsonDecode(
              File(
                'assets/data/tts_first_line_manifest.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final items = (manifest['items'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final byId = <String, Map<String, dynamic>>{
      for (final item in items) item['scenarioId']! as String: item,
    };
    final scenarios = <Scenario>[];
    for (final level in LearnerLevel.values) {
      final payload =
          jsonDecode(
                File(
                  'assets/data/scenarios_${level.code}.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      scenarios.addAll(
        (payload['scenarios'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(Scenario.fromJson),
      );
    }

    expect(scenarios, hasLength(120));
    expect(items, hasLength(120));
    expect(byId, hasLength(120));
    for (final scenario in scenarios) {
      final request = scenarioIntroAudioPrefetchFor(scenario);
      final item = byId[scenario.id];
      expect(request, isNotNull, reason: scenario.id);
      expect(item, isNotNull, reason: scenario.id);
      expect(
        request!.text.trim(),
        item!['normalizedText'],
        reason: scenario.id,
      );
      expect(request.voice, item['voice'], reason: scenario.id);
      expect(
        request.cacheKey.storagePath,
        item['storagePath'],
        reason: scenario.id,
      );
    }
  });

  test(
    'legacy user is female but an authored character profile stays exact',
    () {
      final legacy = scenarioIntroAudioPrefetchFor(
        _scenarioWithDialog(const <DialogLine>[
          DialogLine(speaker: 'user', ko: '안녕하세요.', de: 'Hallo.', en: 'Hello.'),
        ]),
      );
      final canonical = scenarioIntroAudioPrefetchFor(
        _scenarioWithDialog(const <DialogLine>[
          DialogLine(speaker: 'user', ko: '안녕하세요.', de: 'Hallo.', en: 'Hello.'),
        ], playerCharacterId: 'christian'),
      );

      expect(legacy?.voice, 'female');
      expect(canonical?.voice, 'male');
    },
  );

  test('blank or missing first line does not skip ahead or prefetch', () {
    expect(
      scenarioIntroAudioPrefetchFor(_scenarioWithDialog(const [])),
      isNull,
    );
    expect(
      scenarioIntroAudioPrefetchFor(
        _scenarioWithDialog(const <DialogLine>[
          DialogLine(speaker: 'user', ko: '   ', de: '', en: ''),
          DialogLine(
            speaker: 'officer',
            ko: '두 번째 문장',
            de: 'Zweiter Satz',
            en: 'Second line',
          ),
        ]),
      ),
      isNull,
    );
  });

  test('request preserves playback text while the cache key normalizes it', () {
    final request = scenarioIntroAudioPrefetchFor(
      _scenarioWithDialog(const <DialogLine>[
        DialogLine(
          speaker: 'user',
          ko: '  안녕하세요.  ',
          de: 'Hallo.',
          en: 'Hello.',
        ),
      ]),
    );

    expect(request?.text, '  안녕하세요.  ');
    expect(
      request?.cacheKey.storagePath,
      'tts/v3/female/3aeedb15f39df4538ab653e2fecd349783c59380.mp3',
    );
  });

  testWidgets('resolved intro prefetches exactly the first dialog line', (
    tester,
  ) async {
    CourseProgressService.shared.resetForTesting();
    await tester.runAsync(CurriculumCatalog.load);
    final calls = <(String, String)>[];
    var speakCalls = 0;
    SoriSpeech.prefetchImpl = (text, voice) async {
      calls.add((text, voice));
    };
    SoriSpeech.speakImpl = (text, voice) async {
      speakCalls += 1;
      return true;
    };

    await _pumpPlayer(
      tester,
      ScenarioPlayerScreen(
        scenarioId: scenarioAirportArrivalFixture.id,
        scenarioLoader: (_) async => scenarioAirportArrivalFixture,
      ),
    );

    expect(calls, const <(String, String)>[('여권 보여주세요.', 'male')]);
    expect(speakCalls, 0, reason: 'prefetch must never autoplay');
  });

  testWidgets('one intro state calls its injected prefetcher once on rebuild', (
    tester,
  ) async {
    final calls = <ScenarioIntroAudioPrefetchRequest>[];
    Future<void> prefetch(ScenarioIntroAudioPrefetchRequest request) async {
      calls.add(request);
    }

    Widget buildPlayer() => ScenarioPlayerScreen.preview(
      key: const ValueKey<String>('same-intro-player'),
      fixture: const ScenarioPlayerPreviewFixture.action(
        scenario: scenarioAirportArrivalFixture,
        stage: ScenarioStage.intro,
      ),
      introAudioPrefetcher: prefetch,
    );

    await _pumpPlayer(tester, buildPlayer());
    expect(calls, hasLength(1));

    await tester.pumpWidget(_host(buildPlayer()));
    await tester.pump();
    expect(calls, hasLength(1));
  });

  testWidgets('a pending prefetch never delays the Begin action', (
    tester,
  ) async {
    final pending = Completer<void>();
    await _pumpPlayer(
      tester,
      ScenarioPlayerScreen.preview(
        fixture: const ScenarioPlayerPreviewFixture.action(
          scenario: scenarioAirportArrivalFixture,
          stage: ScenarioStage.intro,
        ),
        introAudioPrefetcher: (_) => pending.future,
      ),
    );

    expect(pending.isCompleted, isFalse);
    await tester.tap(find.text("Los geht's!"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('여권'), findsOneWidget);
    expect(pending.isCompleted, isFalse);
    pending.complete();
    await tester.pump();
  });

  testWidgets('a synchronous prefetch failure is fail-soft for Begin', (
    tester,
  ) async {
    await _pumpPlayer(
      tester,
      ScenarioPlayerScreen.preview(
        fixture: const ScenarioPlayerPreviewFixture.action(
          scenario: scenarioAirportArrivalFixture,
          stage: ScenarioStage.intro,
        ),
        introAudioPrefetcher: (_) => throw StateError('prefetch failed'),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.tap(find.text("Los geht's!"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('여권'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a late prefetch error after dispose stays contained', (
    tester,
  ) async {
    final pending = Completer<void>();
    await _pumpPlayer(
      tester,
      ScenarioPlayerScreen.preview(
        fixture: const ScenarioPlayerPreviewFixture.action(
          scenario: scenarioAirportArrivalFixture,
          stage: ScenarioStage.intro,
        ),
        introAudioPrefetcher: (_) => pending.future,
      ),
    );

    await tester.pumpWidget(_host(const SizedBox.shrink()));
    await tester.pump();
    pending.completeError(StateError('late prefetch failure'));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('non-intro previews and passive previews do not prefetch', (
    tester,
  ) async {
    var injectedCalls = 0;
    var networkCalls = 0;
    SoriSpeech.prefetchImpl = (text, voice) async => networkCalls += 1;

    await _pumpPlayer(
      tester,
      ScenarioPlayerScreen.preview(
        fixture: const ScenarioPlayerPreviewFixture.action(
          scenario: scenarioAirportArrivalFixture,
          stage: ScenarioStage.vocab,
        ),
        introAudioPrefetcher: (_) async => injectedCalls += 1,
      ),
    );
    expect(injectedCalls, 0);

    await _pumpPlayer(
      tester,
      ScenarioPlayerScreen.preview(
        key: const ValueKey<String>('passive-intro-preview'),
        fixture: const ScenarioPlayerPreviewFixture.action(
          scenario: scenarioAirportArrivalFixture,
          stage: ScenarioStage.intro,
        ),
      ),
    );
    expect(networkCalls, 0);
  });
}

Scenario _scenarioWithDialog(
  List<DialogLine> dialog, {
  String playerCharacterId = '',
}) => Scenario(
  id: 'audio-prefetch-fixture',
  level: LearnerLevel.a1,
  emoji: '🎭',
  register: Register.polite,
  title: const LocalizedText(ko: '장면', de: 'Szene', en: 'Scene'),
  intro: const LocalizedText(ko: '', de: 'Intro', en: 'Intro'),
  vocab: const [],
  grammarIds: const [],
  dialog: dialog,
  quests: const [],
  playerCharacterId: playerCharacterId,
);

Future<void> _pumpPlayer(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_host(child));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Widget _host(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: const Locale('de'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, appChild) => SoriTypeScale(child: appChild!),
  home: child,
);
