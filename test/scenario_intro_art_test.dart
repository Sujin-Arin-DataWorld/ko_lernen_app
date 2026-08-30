import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    ScenarioLoader.reset();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'kl_tut_scenario': true,
      'kl_tut_wordbook': true,
    });
    await Storage.init();
  });

  test('scenario intro art has no video or ambient-loop branch', () {
    final source = File(
      'lib/screens/scenario_player_screen.dart',
    ).readAsStringSync();
    final start = source.indexOf('class _ScenarioIntroArt');
    final end = source.indexOf('\nclass _ScenarioGrammarExpandedCard', start);
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));

    final introArtSource = source.substring(start, end);
    expect(introArtSource, isNot(contains('SoriPosterLoop')));
    expect(introArtSource, isNot(contains('loopAsset')));
    expect(introArtSource, isNot(contains('TigerStageVideo')));
    expect(introArtSource, isNot(contains('VideoPlayerController')));
  });

  test('scenario intro FNV-1a uses stable unsigned UTF-8 vectors', () {
    expect(scenarioIntroFnv1a32(''), 0x811c9dc5);
    expect(scenarioIntroFnv1a32('a'), 0xe40c292c);
    expect(scenarioIntroFnv1a32('foobar'), 0xbf9cf968);
    expect(scenarioIntroFnv1a32('안녕'), 0x10cea929);
  });

  test(
    'course unit is the preferred seed and id is the blank-unit fallback',
    () {
      final withUnit = _scenario(
        id: 'introduce_yourself',
        courseUnitId: ' a1_02_self_intro_identity ',
      );
      final withoutUnit = _scenario(id: 'fallback-id', courseUnitId: '   ');

      expect(scenarioIntroSeedFor(withUnit), 'a1_02_self_intro_identity');
      expect(scenarioIntroSeedFor(withoutUnit), 'fallback-id');
      expect(scenarioIntroAlignmentFor(withUnit), const Alignment(0.12, 0));
      expect(
        scenarioIntroAlignmentFor(withoutUnit),
        const Alignment(0.12, -0.12),
      );
    },
  );

  testWidgets('the same scenario keeps its crop across complete rebuilds', (
    tester,
  ) async {
    final scenario = _scenario(id: 'stable-rebuild', courseUnitId: 'unit-a');

    await _pumpIntro(tester, scenario, playerKey: const ValueKey('first'));
    final first = _introImage(tester).alignment;
    expect(first, scenarioIntroAlignmentFor(scenario));

    await _pumpIntro(tester, scenario, playerKey: const ValueKey('second'));
    final second = _introImage(tester).alignment;
    expect(second, first);
  });

  testWidgets('scenarios in one course unit share the exact focal alignment', (
    tester,
  ) async {
    late Scenario introduction;
    late Scenario kpop;
    await tester.runAsync(() async {
      final scenarios = await ScenarioLoader.loadLevel(LearnerLevel.a1);
      introduction = scenarios.singleWhere(
        (scenario) => scenario.id == 'introduce_yourself',
      );
      kpop = scenarios.singleWhere(
        (scenario) => scenario.id == 'a1_kpop_my_bias',
      );
    });
    expect(introduction.courseUnitId, 'a1_02_self_intro_identity');
    expect(kpop.courseUnitId, introduction.courseUnitId);

    await _pumpIntro(tester, introduction);
    final introductionAlignment = _introImage(tester).alignment;
    await _pumpIntro(tester, kpop);
    final kpopAlignment = _introImage(tester).alignment;

    expect(introductionAlignment, scenarioIntroAlignmentFor(introduction));
    expect(kpopAlignment, introductionAlignment);
  });
}

Scenario _scenario({required String id, String courseUnitId = ''}) => Scenario(
  id: id,
  level: LearnerLevel.a1,
  emoji: '🎭',
  register: Register.polite,
  title: const LocalizedText(ko: '소개', de: 'Vorstellung', en: 'Introduction'),
  intro: const LocalizedText(ko: '', de: 'Intro', en: 'Intro'),
  vocab: const [],
  grammarIds: const [],
  dialog: const [],
  quests: const [],
  courseUnitId: courseUnitId,
  backdrop: 'home',
);

Future<void> _pumpIntro(
  WidgetTester tester,
  Scenario scenario, {
  Key? playerKey,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) => SoriTypeScale(child: child!),
      home: ScenarioPlayerScreen.preview(
        key: playerKey,
        fixture: ScenarioPlayerPreviewFixture.action(
          scenario: scenario,
          stage: ScenarioStage.intro,
        ),
      ),
    ),
  );
  await tester.pump();
}

Image _introImage(WidgetTester tester) => tester.widget<Image>(
  find.byKey(const ValueKey('scenario-intro-art-image')),
);
