import 'dart:async';
import 'dart:ui' as ui;

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
import 'package:ko_lernen_app/widgets/app_error.dart';
import 'package:ko_lernen_app/widgets/app_loading.dart';
import 'package:ko_lernen_app/widgets/sori/app_bar.dart';
import 'package:ko_lernen_app/widgets/sori/home_action.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

import 'support/scenario_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_tut_scenario': true,
      'kl_tut_wordbook': true,
    });
    await Storage.init();
  });

  test('load lifecycle starts tracking once and never after exit', () {
    final activeGate = ScenarioLoadLifecycleGate();
    var trackingStarts = 0;

    activeGate.startLessonTracking(() => trackingStarts += 1);
    activeGate.startLessonTracking(() => trackingStarts += 1);

    expect(trackingStarts, 1);
    expect(activeGate.requestExit(), isTrue);
    expect(activeGate.requestExit(), isFalse);
    activeGate.startLessonTracking(() => trackingStarts += 1);
    expect(trackingStarts, 1);

    final exitedGate = ScenarioLoadLifecycleGate();
    expect(exitedGate.requestExit(), isTrue);
    exitedGate.startLessonTracking(() => trackingStarts += 1);
    expect(trackingStarts, 1);
  });

  testWidgets('loading uses the standard Sori player state', (tester) async {
    final pending = Completer<Scenario?>();
    addTearDown(() {
      if (!pending.isCompleted) {
        pending.complete(null);
      }
    });

    await _pumpPlayer(
      tester,
      child: ScenarioPlayerScreen(
        scenarioId: scenarioAirportArrivalFixture.id,
        scenarioLoader: (_) => pending.future,
      ),
      size: const Size(390, 844),
      textScale: 1.3,
    );

    expect(find.byType(SoriStudyFrame), findsOneWidget);
    expect(find.byType(AppLoading), findsOneWidget);
    expect(find.byTooltip('Schließen'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'load failure stays in the player and retries the same scenario',
    (tester) async {
      // _load()가 이제 항상 activeScenarioCheckpointContext(→
      // CourseProgressService.shared, CurriculumCatalog.load())를 거친다
      // (T8, 지시서 4.15) — 첫 시도는 실패하지만 재시도가 성공하면 그
      // 시점부터는 이 경로를 탄다. 그 서비스의 직렬화 큐는 testWidgets
      // 마다 새로 생기는 Zone 을 넘나들면 응답하지 않으므로 이 테스트
      // 자신의 Zone 안에서 새로 시작하고, CurriculumCatalog.load()는
      // ScenarioLoader.load()의 compute() 격리를 거치므로 runAsync로
      // 감싸 미리 예열한다(scenario_mission_context_test.dart와 동일
      // 패턴).
      CourseProgressService.shared.resetForTesting();
      await tester.runAsync(() async {
        await CurriculumCatalog.load();
      });
      for (final locale in const [Locale('de'), Locale('en')]) {
        var attempts = 0;
        final isGerman = locale.languageCode == 'de';

        await _pumpPlayer(
          tester,
          child: ScenarioPlayerScreen(
            key: ValueKey('load-${locale.languageCode}'),
            scenarioId: scenarioAirportArrivalFixture.id,
            scenarioLoader: (_) async {
              attempts += 1;
              if (attempts == 1) {
                throw StateError('fixture load failure');
              }
              return scenarioAirportArrivalFixture;
            },
          ),
          size: const Size(320, 640),
          textScale: 2,
          locale: locale,
        );

        final errorTitle = isGerman
            ? 'Hm, da ist etwas schiefgelaufen'
            : 'Hmm, something went wrong';
        final retryLabel = isGerman ? 'Erneut versuchen' : 'Try again';
        final startLabel = isGerman ? "Los geht's!" : "Let's go";
        expect(find.byType(SoriStudyFrame), findsOneWidget);
        expect(find.byType(AppError), findsOneWidget);
        expect(find.text(errorTitle), findsOneWidget);
        expect(find.text(retryLabel), findsOneWidget);
        expect(attempts, 1);

        await tester.tap(find.text(retryLabel));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(attempts, 2);
        expect(find.byType(AppError), findsNothing);
        expect(
          find.text(
            scenarioAirportArrivalFixture.title.pick(locale.languageCode),
          ),
          findsWidgets,
        );
        expect(find.text(startLabel), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'default route close blocks late initialization while still mounted',
    (tester) async {
      final pending = Completer<Scenario?>();

      await _pumpPlayer(
        tester,
        child: ScenarioPlayerScreen(
          scenarioId: scenarioAirportArrivalFixture.id,
          scenarioLoader: (_) => pending.future,
        ),
        size: const Size(320, 640),
        textScale: 2,
      );

      await tester.tap(find.byTooltip('Schließen'));
      await tester.pump();
      expect(find.byType(ScenarioPlayerScreen), findsOneWidget);

      pending.complete(scenarioAirportArrivalFixture);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(AppLoading), findsOneWidget);
      expect(find.text('Einreise am Flughafen'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('vocabulary and dialogue audio controls are labeled buttons', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await _pumpPreview(
      tester,
      stage: ScenarioStage.vocab,
      size: const Size(390, 844),
      textScale: 1.3,
    );

    final vocabularyListen = find.byTooltip('Aussprache');
    expect(vocabularyListen, findsWidgets);
    expect(
      tester.getSize(vocabularyListen.first).height,
      greaterThanOrEqualTo(48),
    );

    await _pumpPreview(
      tester,
      stage: ScenarioStage.dialog,
      size: const Size(390, 844),
      textScale: 1.3,
    );

    final dialogueListen = find.bySemanticsLabel(
      RegExp(r'^Aussprache: 여권 보여주세요\.'),
    );
    expect(dialogueListen, findsOneWidget);
    final semanticsData = tester
        .getSemantics(dialogueListen)
        .getSemanticsData();
    expect(semanticsData.flagsCollection.isButton, isTrue);
    expect(semanticsData.hasAction(ui.SemanticsAction.tap), isTrue);
    semantics.dispose();
  });

  testWidgets('DE and EN states remain reachable across the viewport matrix', (
    tester,
  ) async {
    const cases = <({Size size, double scale, ScenarioStage stage})>[
      (size: Size(320, 640), scale: 2.0, stage: ScenarioStage.intro),
      (size: Size(360, 400), scale: 1.0, stage: ScenarioStage.vocab),
      (size: Size(390, 844), scale: 1.3, stage: ScenarioStage.dialog),
      (size: Size(720, 1024), scale: 1.3, stage: ScenarioStage.grammar),
      (size: Size(1280, 900), scale: 1.3, stage: ScenarioStage.result),
    ];

    for (final locale in const [Locale('de'), Locale('en')]) {
      for (final testCase in cases) {
        await _pumpPreview(
          tester,
          stage: testCase.stage,
          size: testCase.size,
          textScale: testCase.scale,
          locale: locale,
        );

        final expectedTitle = scenarioAirportArrivalFixture.title.pick(
          locale.languageCode,
        );
        final appBar = tester.widget<SoriAppBar>(find.byType(SoriAppBar));
        expect(appBar.title, expectedTitle);
        final title = tester.widget<Text>(
          find.descendant(
            of: find.byType(SoriAppBar),
            matching: find.text(expectedTitle),
          ),
        );
        expect(title.overflow, TextOverflow.clip);
        expect(find.byTooltip(_closeLabel(locale)), findsOneWidget);

        if (testCase.stage == ScenarioStage.result) {
          final returnLabel = locale.languageCode == 'de'
              ? 'Zurück zum Hanok'
              : 'Back to my Hanok';
          await _scrollTo(tester, find.text(returnLabel));
          expect(find.text(returnLabel), findsOneWidget);
        } else {
          final nextLabel = testCase.stage == ScenarioStage.intro
              ? locale.languageCode == 'de'
                    ? "Los geht's!"
                    : "Let's go"
              : locale.languageCode == 'de'
              ? 'Weiter'
              : 'Next';
          expect(find.text(nextLabel), findsOneWidget);
          final buttonRect = tester.getRect(find.text(nextLabel));
          expect(buttonRect.bottom, lessThanOrEqualTo(testCase.size.height));
        }
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('home confirmation follows intro, active, and result stages', (
    tester,
  ) async {
    for (final testCase in const <({ScenarioStage stage, bool confirm})>[
      (stage: ScenarioStage.intro, confirm: false),
      (stage: ScenarioStage.vocab, confirm: true),
      (stage: ScenarioStage.result, confirm: false),
    ]) {
      await _pumpPreview(
        tester,
        stage: testCase.stage,
        size: const Size(390, 844),
        textScale: 1,
      );

      expect(find.byType(SoriHomeAction), findsOneWidget);
      expect(
        tester
            .widget<SoriHomeAction>(find.byType(SoriHomeAction))
            .escape
            .confirmWhen,
        testCase.confirm,
        reason: testCase.stage.name,
      );
    }
  });

  testWidgets(
    'changed vocabulary and dialogue states cover the full DE and EN matrix',
    (tester) async {
      const viewports = <({Size size, double scale})>[
        (size: Size(320, 640), scale: 2),
        (size: Size(360, 400), scale: 1),
        (size: Size(390, 844), scale: 1.3),
        (size: Size(720, 1024), scale: 1.3),
        (size: Size(1280, 900), scale: 1.3),
      ];

      for (final locale in const [Locale('de'), Locale('en')]) {
        for (final stage in const [ScenarioStage.vocab, ScenarioStage.dialog]) {
          for (final viewport in viewports) {
            await _pumpPreview(
              tester,
              stage: stage,
              size: viewport.size,
              textScale: viewport.scale,
              locale: locale,
            );

            final nextLabel = locale.languageCode == 'de' ? 'Weiter' : 'Next';
            expect(find.text(nextLabel), findsOneWidget);
            expect(
              find.byTooltip(
                locale.languageCode == 'de' ? 'Schließen' : 'Close',
              ),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
          }
        }
      }
    },
  );
}

Future<void> _pumpPreview(
  WidgetTester tester, {
  required ScenarioStage stage,
  required Size size,
  required double textScale,
  Locale locale = const Locale('de'),
}) {
  final fixture = stage == ScenarioStage.result
      ? const ScenarioPlayerPreviewFixture.result(
          scenario: scenarioAirportArrivalFixture,
          result: null,
        )
      : ScenarioPlayerPreviewFixture.action(
          scenario: scenarioAirportArrivalFixture,
          stage: stage,
        );
  return _pumpPlayer(
    tester,
    child: ScenarioPlayerScreen.preview(
      key: ValueKey('${locale.languageCode}-${stage.name}-${size.width}'),
      fixture: fixture,
    ),
    size: size,
    textScale: textScale,
    locale: locale,
  );
}

Future<void> _pumpPlayer(
  WidgetTester tester, {
  required Widget child,
  required Size size,
  required double textScale,
  Locale locale = const Locale('de'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, appChild) {
        final media = MediaQuery.of(context);
        const safeInsets = EdgeInsets.only(top: 44, bottom: 34);
        return MediaQuery(
          data: media.copyWith(
            padding: safeInsets,
            viewPadding: safeInsets,
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: SoriTypeScale(child: appChild!),
        );
      },
      home: child,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  final scrollable = find.byType(Scrollable).last;
  for (var index = 0; index < 30 && finder.evaluate().isEmpty; index += 1) {
    await tester.drag(scrollable, const Offset(0, -240));
    await tester.pump();
  }
  if (finder.evaluate().isNotEmpty) {
    await tester.ensureVisible(finder.first);
  }
  await tester.pump();
}

String _closeLabel(Locale locale) =>
    locale.languageCode == 'de' ? 'Schließen' : 'Close';
