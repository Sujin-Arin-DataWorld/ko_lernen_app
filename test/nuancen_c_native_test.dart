import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/word_relation.dart';
import 'package:ko_lernen_app/screens/word_web_quiz_screen.dart';
import 'package:ko_lernen_app/screens/word_web_screen.dart';
import 'package:ko_lernen_app/screens/word_web_study_screen.dart';
import 'package:ko_lernen_app/services/sound_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/tts_service.dart';
import 'package:ko_lernen_app/services/word_relation_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/learning_stage_navigation.dart';
import 'package:ko_lernen_app/widgets/sori/home_action.dart';
import 'package:ko_lernen_app/widgets/sori/quiz_choice.dart';
import 'package:ko_lernen_app/widgets/sori/nuancen_c.dart';
import 'package:ko_lernen_app/widgets/sori/route_observer.dart';

import 'support/c_native_capture_assets.dart';
import 'support/real_fonts.dart';
import 'support/sori_speech_stubs.dart';

const _capture = ValueKey('nuancen-native-capture');
const _item = WordRelationQuizItem(
  kind: WordRelationKind.antonym,
  clusterId: 'rel_a1_0010',
  sourceKo: '크다',
  promptDe: '크다',
  promptEn: '크다',
  answerKo: '작다',
  options: ['작다', '싸다', '쉽다', '짧다'],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<WordRelationCluster> corpus;
  late WordRelationCluster source;
  setUpAll(() async {
    await loadSoriRealFonts(materialIcons: true);
    corpus = await WordRelationService.load();
    source = corpus.singleWhere((c) => c.id == _item.clusterId);
  });
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await Storage.setTutSeen('wordWeb');
    WordRelationService.catalogLoaderForTesting = () async =>
        throw StateError('no course');
    stubSoriSpeech();
    SoundService.playImpl = (_) {};
  });
  tearDown(() {
    SoundService.resetForTesting();
    WordRelationService.resetForTesting();
  });

  for (final size in [const Size(390, 844), const Size(320, 640)]) {
    for (final scale in [1.0, 1.6]) {
      testWidgets(
        'Nuancen $size scale $scale choice feedback result and clearance',
        (tester) async {
          await _pump(
            tester,
            WordWebQuizScreen(
              clusters: [source],
              quizBuilder: (_) => const [_item],
            ),
            size: size,
            scale: scale,
          );
          expect(find.byType(SoriLearningStageNavigation), findsOneWidget);
          await _save(tester, 'quiz-${size.width.toInt()}-$scale');
          final option = find.byKey(const ValueKey('word-web-option-싸다'));
          await tester.scrollUntilVisible(
            option,
            150,
            scrollable: find.byType(Scrollable).last,
          );
          await Scrollable.ensureVisible(
            option.evaluate().single,
            alignment: .5,
            duration: Duration.zero,
          );
          await tester.pump();
          await tester.tap(option);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));
          final finish = find.widgetWithText(SoriButton, 'Ergebnis ansehen');
          expect(finish.hitTestable(), findsOneWidget);
          final nav = tester.getRect(find.byType(SoriLearningStageNavigation));
          final action = tester.getRect(finish);
          expect(nav.top - action.bottom, greaterThanOrEqualTo(22));
          expect(action.height, greaterThanOrEqualTo(48));
          expect(find.text('Dazu passt: 작다'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await _save(tester, 'feedback-${size.width.toInt()}-$scale');
          await tester.tap(finish);
          await tester.pump();
          expect(find.text('0/1 richtig'), findsOneWidget);
          expect(Storage.xp, 0);
          expect(Storage.vokSeenIds, isEmpty);
          await _save(tester, 'result-${size.width.toInt()}-$scale');
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'normal advance awaits actual speech completion and a minimum 850ms',
    (tester) async {
      final speech = stubSoriSpeech(completeSpeak: false);
      await _pump(
        tester,
        WordWebQuizScreen(
          clusters: [source],
          quizBuilder: (_) => const [_item],
        ),
        reduceMotion: false,
      );
      await tester.tap(find.byKey(const ValueKey('word-web-option-작다')));
      await tester.pump();
      expect(speech.spoken, ['작다']);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Runde geschafft!'), findsNothing);
      expect(find.widgetWithText(SoriButton, 'Ergebnis ansehen'), findsNothing);
      speech.speakCompleter!.complete(true);
      await tester.pump();
      expect(find.text('1/1 richtig'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('1/1 richtig'), findsOneWidget);
    },
  );

  testWidgets(
    'background cancels speech and old completion cannot advance on resume',
    (tester) async {
      final speech = stubSoriSpeech(completeSpeak: false);
      await _pump(
        tester,
        WordWebQuizScreen(
          clusters: [source],
          quizBuilder: (_) => const [_item],
        ),
        reduceMotion: false,
      );
      await tester.tap(find.byKey(const ValueKey('word-web-option-작다')));
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(speech.stops, 1);
      speech.speakCompleter!.complete(true);
      await tester.pump(const Duration(seconds: 2));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('Runde geschafft!'), findsNothing);
      await tester.tap(find.widgetWithText(SoriButton, 'Ergebnis ansehen'));
      await tester.pump();
      expect(find.text('1/1 richtig'), findsOneWidget);
    },
  );

  testWidgets(
    'covering quiz cancels audio and returning retains one selected answer',
    (tester) async {
      final speech = stubSoriSpeech(completeSpeak: false);
      await _pump(
        tester,
        WordWebQuizScreen(
          clusters: [source],
          quizBuilder: (_) => const [_item],
        ),
        reduceMotion: false,
      );
      await tester.tap(find.byKey(const ValueKey('word-web-option-작다')));
      await tester.pump();
      final context = tester.element(find.byType(WordWebQuizScreen));
      unawaited(
        showDialog<void>(
          context: context,
          builder: (_) => const AlertDialog(content: Text('covered')),
        ),
      );
      await tester.pump();
      expect(speech.stops, 1);
      speech.speakCompleter!.complete(true);
      await tester.pump(const Duration(seconds: 2));
      Navigator.of(context).pop();
      await tester.pumpAndSettle();
      expect(find.text('Runde geschafft!'), findsNothing);
      expect(
        tester
            .widget<QuizChoice>(
              find.byKey(const ValueKey('word-web-option-작다')),
            )
            .isSelected,
        isTrue,
      );
      await tester.tap(find.widgetWithText(SoriButton, 'Ergebnis ansehen'));
      await tester.pump();
      expect(find.text('1/1 richtig'), findsOneWidget);
    },
  );

  testWidgets(
    'popping study stops pending speech before its reverse transition ends',
    (tester) async {
      final speech = stubSoriSpeech(completeSpeak: false);
      await _pump(
        tester,
        const Scaffold(body: Text('root')),
        reduceMotion: false,
      );
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      unawaited(
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => WordWebStudyScreen(cluster: source),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Aussprache: 크다'));
      await tester.pump();
      navigator.pop();
      await tester.pump();
      expect(speech.stops, 1);
      expect(
        find.byType(WordWebStudyScreen),
        findsOneWidget,
        reason: 'The old route still exists during the reverse transition.',
      );
      speech.speakCompleter!.complete(true);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('study speaks exact Korean and disposes unresolved speech', (
    tester,
  ) async {
    final speech = stubSoriSpeech(completeSpeak: false);
    await _pump(tester, WordWebStudyScreen(cluster: source));
    await tester.tap(find.byTooltip('Aussprache: 크다'));
    await tester.pump();
    expect(speech.spoken, ['크다']);
    await tester.pumpWidget(const SizedBox());
    expect(speech.stops, 1);
    speech.speakCompleter!.complete(true);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'default learned snapshot refreshes actual Storage after /vocab',
    (tester) async {
      await _pump(tester, WordWebScreen(clusterLoader: () async => corpus));
      expect(find.text('Noch kein Netz'), findsOneWidget);
      await _save(tester, 'empty-390-1.0');
      final open = find.widgetWithText(SoriButton, 'Wortpakete öffnen');
      await tester.ensureVisible(open);
      await tester.tap(open);
      await tester.pumpAndSettle();
      expect(find.text('vocab-route'), findsOneWidget);
      await Storage.addVokSeen('크다');
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey(source.id)), findsOneWidget);
      expect(find.text('Noch kein Netz'), findsNothing);
    },
  );

  testWidgets(
    '114 authored clusters and all four study groups remain reachable',
    (tester) async {
      expect(corpus, hasLength(114));
      await _pump(
        tester,
        WordWebScreen(
          clusterLoader: () async => corpus,
          seenLoader: () => const {},
        ),
      );
      await tester.tap(find.byKey(const ValueKey('word-web-filter-level')));
      await tester.pump();
      await _save(tester, 'catalog-390-1.0');
      expect(find.text('114 Wörter mit Nachbarn'), findsOneWidget);
      final quiz = tester.getRect(find.byKey(const ValueKey('word-web-quiz')));
      final nav = tester.getRect(find.byType(SoriLearningStageNavigation));
      expect(nav.top - quiz.bottom, greaterThanOrEqualTo(22));
      await _pump(tester, WordWebStudyScreen(cluster: source));
      await _save(tester, 'study-390-1.0');
      for (final label in [
        'Ähnliche Wörter',
        'Gegenteile',
        'Verwandte Wörter',
        'Wendungen',
      ]) {
        await tester.scrollUntilVisible(
          find.text(label),
          150,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.text(label), findsOneWidget);
      }
      await tester.scrollUntilVisible(
        find.text(source.expressions.single.exampleKo),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text(source.expressions.single.exampleDe), findsOneWidget);
      expect(find.byKey(const ValueKey('word-web-quiz')), findsNothing);
      await _save(tester, 'study-expression-390-1.0');
    },
  );

  testWidgets(
    'load failure remains distinct and retry uses the same native flow',
    (tester) async {
      var attempt = 0;
      await _pump(
        tester,
        WordWebScreen(
          clusterLoader: () async {
            if (attempt++ == 0) throw StateError('unreadable');
            return corpus;
          },
          seenLoader: () => const {'크다'},
        ),
      );
      expect(find.text('Netz nicht geladen'), findsOneWidget);
      expect(find.text('Noch kein Netz'), findsNothing);
      await _save(tester, 'error-390-1.0');
      await tester.tap(find.widgetWithText(SoriButton, 'Erneut versuchen'));
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey(source.id)), findsOneWidget);
    },
  );
  testWidgets(
    'close confirmation names the catalog and stay preserves the answer',
    (tester) async {
      await _pump(
        tester,
        WordWebScreen(
          clusterLoader: () async => corpus,
          seenLoader: () => const {},
        ),
      );
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      unawaited(
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => WordWebQuizScreen(
              clusters: [source],
              quizBuilder: (_) => const [_item],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('word-web-option-작다')));
      await tester.pump();
      await tester.tap(find.byType(SoriCloseAction));
      await tester.pumpAndSettle();
      expect(find.text('Zur Wortliste'), findsOneWidget);
      expect(find.text('Zur Startseite'), findsNothing);
      await _save(tester, 'close-confirmation-390-1.0');
      await tester.tap(find.widgetWithText(SoriButton, 'Weiterspielen'));
      await tester.pumpAndSettle();
      expect(find.text('Richtig: 작다'), findsOneWidget);
      await tester.tap(find.byType(SoriCloseAction));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(SoriButton, 'Zur Wortliste'));
      await tester.pumpAndSettle();
      expect(find.byType(WordWebQuizScreen), findsNothing);
      expect(find.text('Noch kein Netz'), findsOneWidget);
    },
  );

  testWidgets(
    'speech speed preserves the six real presets and persisted selection',
    (tester) async {
      await TtsService.setSpeed(1);
      addTearDown(() => TtsService.setSpeed(1));
      await _pump(tester, WordWebStudyScreen(cluster: source));
      await tester.tap(find.byType(NuancenSpeedAction));
      await tester.pumpAndSettle();
      for (final label in ['0.5×', '0.75×', '0.8×', '1×', '1.25×', '1.5×']) {
        expect(find.text(label), findsWidgets);
      }
      await _save(tester, 'speed-390-1.0');
      await tester.tap(find.text('0.75×'));
      await tester.pumpAndSettle();
      expect(Storage.ttsSpeed, .75);
      expect(TtsService.speedNotifier.value, .75);
    },
  );

  testWidgets(
    'result closes to retained all scope and only catalog starts a fresh quiz',
    (tester) async {
      await _pump(
        tester,
        WordWebScreen(
          clusterLoader: () async => corpus,
          seenLoader: () => const {},
        ),
      );
      await tester.tap(find.byKey(const ValueKey('word-web-filter-level')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('word-web-quiz')));
      await tester.pumpAndSettle();
      for (var count = 0; count < 10; count++) {
        final list = tester.widget<ListView>(find.byType(ListView));
        final children =
            (list.childrenDelegate as SliverChildListDelegate).children;
        final answer = children
            .whereType<NuancenLinkedPanel>()
            .map((panel) => panel.child)
            .whereType<QuizChoice>()
            .singleWhere((choice) => choice.isCorrect);
        final answerFinder = find.byKey(
          ValueKey('word-web-option-${answer.text}'),
        );
        await tester.scrollUntilVisible(
          answerFinder,
          150,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(answerFinder);
        await tester.pump();
        final next = find.widgetWithText(
          SoriButton,
          count == 9 ? 'Ergebnis ansehen' : 'Weiter',
        );
        await tester.tap(next);
        await tester.pump();
      }
      expect(find.text('10/10 richtig'), findsOneWidget);
      await tester.tap(find.widgetWithText(SoriButton, 'Schließen'));
      await tester.pumpAndSettle();
      expect(find.text('114 Wörter mit Nachbarn'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('word-web-quiz')));
      await tester.pumpAndSettle();
      expect(find.text('1 / 10'), findsOneWidget);
      expect(find.text('10/10 richtig'), findsNothing);
      expect(Storage.vokSeenIds, isEmpty);
    },
  );
  testWidgets('402 approved viewport captures catalog study quiz and result', (
    tester,
  ) async {
    const size = Size(402, 874);
    await _pump(
      tester,
      WordWebScreen(
        clusterLoader: () async => corpus,
        seenLoader: () => const {},
      ),
      size: size,
    );
      await _save(tester, 'empty-402-1.0');
    await tester.tap(find.byKey(const ValueKey('word-web-filter-level')));
    await tester.pump();
    expect(find.text('Nuancen & Gegenteile'), findsNWidgets(2));
    await _save(tester, 'catalog-402-1.0');
    await _pump(tester, WordWebStudyScreen(cluster: source), size: size);
    await _save(tester, 'study-402-1.0');
    await tester.scrollUntilVisible(
      find.text(source.expressions.single.exampleKo),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await _save(tester, 'study-expression-402-1.0');
    await _pump(
      tester,
      WordWebQuizScreen(clusters: [source], quizBuilder: (_) => const [_item]),
      size: size,
    );
    await _save(tester, 'quiz-402-1.0');
    await tester.tap(find.byKey(const ValueKey('word-web-option-싸다')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await _save(tester, 'feedback-402-1.0');
    final finish = find.widgetWithText(SoriButton, 'Ergebnis ansehen');
    expect(
      tester.getRect(find.byType(SoriLearningStageNavigation)).top -
          tester.getRect(finish).bottom,
      greaterThanOrEqualTo(22),
    );
    await tester.tap(finish);
    await tester.pump();
    await _save(tester, 'result-402-1.0');
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(390, 844),
  double scale = 1,
  bool reduceMotion = true,
}) async {
  tester.view.physicalSize = size;
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
      navigatorObservers: [soriRouteObserver],
      routes: {'/vocab': (_) => const Scaffold(body: Text('vocab-route'))},
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: reduceMotion,
        ),
        child: RepaintBoundary(key: _capture, child: child!),
      ),
      home: screen,
    ),
  );
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _save(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_NUANCEN_C')) return;
  await settleCNativeCaptureAssets(tester);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_capture),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    const directory = String.fromEnvironment(
      'NUANCEN_CAPTURE_DIR',
      defaultValue: 'build/nuancen-c-captures',
    );
    final file = File('$directory/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}
