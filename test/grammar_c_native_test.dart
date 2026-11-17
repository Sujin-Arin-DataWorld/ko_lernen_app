import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/grammar.dart';
import 'package:ko_lernen_app/models/course_practice_context.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/screens/grammar_choice_quiz_screen.dart';
import 'package:ko_lernen_app/screens/grammar_screen.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/sound_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/learning_stage_navigation.dart';
import 'package:ko_lernen_app/widgets/sori/quiz_choice.dart';
import 'package:ko_lernen_app/widgets/sori/grammar_c.dart';
import 'package:ko_lernen_app/widgets/sori/grammar_c_plan.dart';
import 'package:ko_lernen_app/widgets/sori/home_action.dart';
import 'package:ko_lernen_app/widgets/sori/content_feed.dart';
import 'package:ko_lernen_app/widgets/sori/ko_wrap.dart';
import 'package:ko_lernen_app/widgets/sori/route_observer.dart';
import 'package:ko_lernen_app/widgets/sori/speakable.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'support/c_native_capture_assets.dart';
import 'support/real_fonts.dart';
import 'support/sori_speech_stubs.dart';

const _capture = ValueKey('grammar-native-capture');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Grammar> source;
  setUpAll(() async {
    await loadSoriRealFonts(materialIcons: true);
    final bytes = File('assets/fonts/Lora/Lora-Variable.ttf').readAsBytesSync();
    await (FontLoader(
      'Lora',
    )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
    source = await DataLoader.loadGrammar();
  });
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_tut_seen_grammar': true,
      'kl_tut_seen_soriDeck': true,
    });
    await Storage.init();
    await Storage.setTutSeen('grammar');
    await Storage.setTutSeen('soriDeck');
    stubSoriSpeech();
    SoundService.playImpl = (_) {};
  });
  tearDown(SoundService.resetForTesting);

  for (final size in [
    const Size(402, 874),
    const Size(430, 932),
    const Size(320, 640),
  ]) {
    for (final scale in [1.0, 1.6]) {
      testWidgets(
        'C grammar $size scale $scale preserves choices, score and CTA clearance',
        (tester) async {
          await _pump(
            tester,
            GrammarChoiceQuizScreen(
              initialLevel: 'A1',
              allowedTargetIds: const {'grammar_a1_want'},
              grammarLoader: () async => source,
              maxQuestions: 1,
              randomSeed: 7,
            ),
            size,
            scale,
          );
          expect(find.byType(SoriLearningStageNavigation), findsOneWidget);
          expect(find.text('한국에 가고 싶어요.'), findsNothing);
          expect(find.byType(QuizChoice), findsNWidgets(4));
          expect(tester.takeException(), isNull);
          await _save(tester, 'question-${size.width.toInt()}-$scale');
          final correct = tester
              .widgetList<QuizChoice>(find.byType(QuizChoice))
              .singleWhere((c) => c.isCorrect);
          final correctChoice = find.byWidget(correct);
          await _revealAction(tester, correctChoice);
          await tester.tap(correctChoice);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          final action = find.widgetWithText(SoriButton, 'Ergebnis ansehen');
          await _revealAction(tester, action);
          expect(action.hitTestable(), findsOneWidget);
          final actionRect = tester.getRect(action);
          final navRect = tester.getRect(
            find.byType(SoriLearningStageNavigation),
          );
          expect(
            navRect.top - actionRect.bottom,
            greaterThanOrEqualTo(22),
            reason: '16dp clear space plus 6dp painted shadow',
          );
          expect(actionRect.height, greaterThanOrEqualTo(48));
          await _save(tester, 'feedback-${size.width.toInt()}-$scale');
          await tester.tap(action);
          await tester.pump();
          expect(find.text('1 von 1 richtig'), findsOneWidget);
          expect(Storage.xp, 0);
          await _save(tester, 'result-${size.width.toInt()}-$scale');
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final config in [
    (const Size(402, 874), 1.0),
    (const Size(320, 640), 1.0),
    (const Size(320, 640), 1.6),
  ]) {
    testWidgets(
      'C explanation ${config.$1} scale ${config.$2} preserves native content',
      (tester) async {
        await _pump(
          tester,
          const GrammarScreen(initialGrammarId: 'grammar_a1_want'),
          config.$1,
          config.$2,
        );
        final close = tester.getSize(find.byType(SoriCloseAction));
        expect(close.width, greaterThanOrEqualTo(48));
        expect(close.height, greaterThanOrEqualTo(48));
        tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(SoriLearningStageNavigation), findsOneWidget);
        expect(find.text('V-고 싶다', skipOffstage: false), findsWidgets);
        expect(
          find.byWidgetPredicate(
            (w) => w is SoriPhraseWrap && w.text == '한국에 가고 싶어요.',
            skipOffstage: false,
          ),
          findsWidgets,
        );
        await _save(
          tester,
          'explanation-${config.$1.width.toInt()}-${config.$2}',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'course header filter has a real 48dp target including its lower edge',
    (tester) async {
      final catalog = (await tester.runAsync(CurriculumCatalog.load))!;
      final link = catalog.contentLinks.firstWhere(
        (item) =>
            item.contentKind == CurriculumContentKind.grammar &&
            item.courseUnitId == 'a1_03_topic_subject_particles' &&
            item.role == ContentLinkRole.assess,
      );
      await _pump(
        tester,
        GrammarScreen(courseContext: CoursePracticeContext.fromLink(link)),
        const Size(402, 874),
        1,
      );
      final filter = find.widgetWithIcon(IconButton, Icons.filter_list_rounded);
      final rect = tester.getRect(filter);
      expect(rect.width, greaterThanOrEqualTo(48));
      expect(rect.height, greaterThanOrEqualTo(48));
      await _save(tester, 'course-checkpoint-402');
      await tester.tapAt(rect.bottomCenter - const Offset(0, 1));
      await _settle(tester);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Filter'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final config in [
    (const Size(402, 874), 1.0),
    (const Size(320, 640), 1.6),
  ]) {
    testWidgets(
      'approved plan ${config.$1} scale ${config.$2} retains every level and pace',
      (tester) async {
        await _pump(tester, const GrammarScreen(), config.$1, config.$2);
        expect(find.byType(GrammarCLevelTray), findsOneWidget);
        expect(find.byType(GrammarCPlanChoice), findsNWidgets(10));
        final start = find.widgetWithText(SoriButton, 'Starten');
        await _revealAction(tester, start);
        expect(start.hitTestable(), findsOneWidget);
        expect(tester.getSize(start).height, greaterThanOrEqualTo(48));
        if (config.$1.width == 402 && config.$2 == 1.0) {
          expect(
            tester.getRect(find.byType(GrammarCPlanPreview)).bottom + 6,
            lessThanOrEqualTo(tester.getRect(start).top - 8),
            reason: 'The approved five-card preview and shadow stay visible.',
          );
        }
        await _save(tester, 'plan-${config.$1.width.toInt()}-${config.$2}');
        for (final n in [3, 5, 7, 10]) {
          final choice = find.byKey(Key('grammar-plan-items-$n'));
          await tester.ensureVisible(choice);
          await tester.tap(choice);
          await tester.pump();
          expect(
            tester
                .widget<GrammarCPlanPreview>(find.byType(GrammarCPlanPreview))
                .count,
            n,
          );
          expect(
            find.byWidgetPredicate(
              (w) =>
                  w is Image &&
                  w.key is ValueKey<String> &&
                  (w.key! as ValueKey<String>).value.startsWith(
                    'grammar-daily-card-',
                  ),
            ),
            findsNWidgets(n),
          );
          expect(tester.takeException(), isNull);
        }
        await _revealAction(tester, start);
        await tester.tap(start);
        await _settle(tester);
        expect(
          find.byKey(const Key('grammar-plan-day-header')),
          findsOneWidget,
        );
        expect(Storage.grammarPlanRawJson, isNotEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'native plan pending, save failure and same-operation retry remain truthful',
    (tester) async {
      final original = SharedPreferencesStorePlatform.instance;
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({});
      final native = _PlanCapturePlatform();
      SharedPreferencesStorePlatform.instance = native;
      addTearDown(() {
        Storage.resetForTesting();
        SharedPreferences.setMockInitialValues({});
        SharedPreferencesStorePlatform.instance = original;
      });
      await Storage.init();
      await _pump(tester, const GrammarScreen(), const Size(402, 874), 1);
      native.pending = Completer<bool>();
      tester
          .widget<SoriButton>(find.widgetWithText(SoriButton, 'Starten'))
          .onTap!();
      await tester.pump();
      await _save(tester, 'plan-save-pending-402');
      native.pending!.complete(false);
      await _settle(tester);
      expect(find.byKey(const Key('grammar-plan-save-error')), findsOneWidget);
      expect(Storage.grammarPlanRawJson, isEmpty);
      await _save(tester, 'plan-save-error-402');
      native.pending = Completer<bool>();
      await tester.tap(find.byKey(const Key('grammar-plan-save-retry')));
      await tester.pump();
      await _save(tester, 'plan-retry-pending-402');
      native.pending!.complete(true);
      await _settle(tester);
      expect(find.byKey(const Key('grammar-plan-day-header')), findsOneWidget);
      expect(Storage.grammarPlanRawJson, isNotEmpty);
      await _save(tester, 'plan-active-402');
      native.pending = null;
      native.reject = true;
      for (var i = 0; i < 5; i++) {
        tester.widget<SoriContentFeed>(find.byType(SoriContentFeed)).onSkip!();
        await _settle(tester);
      }
      expect(find.byKey(const Key('grammar-plan-save-error')), findsOneWidget);
      expect(
        find.byKey(const Key('grammar-plan-completion-sheet')),
        findsNothing,
      );
      await _save(tester, 'plan-completion-error-402');
      native.reject = false;
      await tester.tap(find.byKey(const Key('grammar-plan-save-retry')));
      await _settle(tester);
      expect(
        find.byKey(const Key('grammar-plan-completion-sheet')),
        findsOneWidget,
      );
      await _save(tester, 'plan-completion-confirmed-402');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'wrong quiz shows save warning and continue without inventing retry, with motion',
    (tester) async {
      await _pump(
        tester,
        GrammarChoiceQuizScreen(
          initialLevel: 'A1',
          allowedTargetIds: const {'grammar_a1_want'},
          grammarLoader: () async => source,
          maxQuestions: 1,
          randomSeed: 7,
          markGrammarHard: (_) async => throw StateError('rejected write'),
        ),
        const Size(402, 874),
        1,
        reduceMotion: false,
      );
      final wrong = tester
          .widgetList<QuizChoice>(find.byType(QuizChoice))
          .firstWhere((c) => !c.isCorrect);
      wrong.onSelected!();
      await _settle(tester);
      expect(
        find.byKey(const Key('grammar-choice-save-error')),
        findsOneWidget,
      );
      expect(find.text('Erneut versuchen'), findsNothing);
      await _save(tester, 'quiz-wrong-save-warning-402-motion');
      await tester.tap(find.widgetWithText(SoriButton, 'Ergebnis ansehen'));
      await _settle(tester);
      expect(find.text('0 von 1 richtig'), findsOneWidget);
      expect(Storage.xp, 0);
      await _save(tester, 'quiz-wrong-result-402-motion');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('grammar speech stops on background and before quiz navigation', (
    tester,
  ) async {
    final requests = <String>[];
    final pending = <Completer<bool>>[];
    var stops = 0;
    SoriSpeech.speakImpl = (text, voice) {
      requests.add(text);
      final c = Completer<bool>();
      pending.add(c);
      return c.future;
    };
    SoriSpeech.stopImpl = () async {
      stops++;
    };
    await _pump(
      tester,
      const GrammarScreen(initialGrammarId: 'grammar_a1_want'),
      const Size(402, 874),
      1,
    );
    await tester.tap(find.widgetWithText(SoriButton, 'Anhören'));
    await tester.pump();
    expect(requests, ['한국에 가고 싶어요.']);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(stops, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(requests.length, 1);
    await tester.tap(find.widgetWithText(SoriButton, 'Anhören'));
    await tester.pump();
    expect(requests.length, 2);
    await tester.tap(find.byKey(const Key('grammar-choice-cta')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(stops, 2);
    expect(find.byType(GrammarChoiceQuizScreen), findsOneWidget);
    for (final c in pending) {
      c.complete(false);
    }
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'system pop stops owned speech and an idle frame never stops another owner',
    (tester) async {
      var stops = 0;
      SoriSpeech.stopImpl = () async {
        stops++;
      };
      final pending = Completer<bool>();
      SoriSpeech.speakImpl = (_, __) => pending.future;
      await _pump(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => GrammarCFrame(
                  title: 'Grammatik',
                  child: GrammarCStudyControls(
                    korean: '한국어',
                    onBookmark: () {},
                    saved: false,
                  ),
                ),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
        const Size(402, 874),
        1,
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(SoriButton, 'Anhören'));
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(stops, 1);
      pending.complete(false);
      await tester.pump();
      await _pump(
        tester,
        const GrammarCFrame(title: 'Grammatik', child: Text('Idle')),
        const Size(402, 874),
        1,
      );
      final foreign = Completer<bool>();
      SoriSpeech.speakImpl = (_, __) => foreign.future;
      unawaited(SoriSpeech.speak('Another screen'));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      expect(
        stops,
        1,
        reason: 'A frame that did not request audio cannot stop it',
      );
      foreign.complete(false);
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen,
  Size size,
  double scale, {
  bool reduceMotion = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      navigatorObservers: [soriRouteObserver],
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

/// A flowing large-text action must be reachable in full before a real tap.
Future<void> _revealAction(WidgetTester tester, Finder action) async {
  expect(action, findsOneWidget);
  await Scrollable.ensureVisible(tester.element(action), alignment: 1);
  await tester.pump();
  expect(action.hitTestable(), findsOneWidget);
  final actionRect = tester.getRect(action);
  expect(actionRect.height, greaterThanOrEqualTo(48));
  final viewports = find.ancestor(
    of: action,
    matching: find.byType(Scrollable),
  );
  for (final viewport in tester.renderObjectList<RenderBox>(viewports)) {
    final viewportRect = viewport.localToGlobal(Offset.zero) & viewport.size;
    expect(actionRect.left, greaterThanOrEqualTo(viewportRect.left));
    expect(actionRect.top, greaterThanOrEqualTo(viewportRect.top));
    expect(actionRect.right, lessThanOrEqualTo(viewportRect.right));
    expect(actionRect.bottom, lessThanOrEqualTo(viewportRect.bottom));
  }
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class _PlanCapturePlatform extends SharedPreferencesStorePlatform {
  final values = <String, Object>{
    'flutter.kl_user_level': 'a1',
    'flutter.kl_tut_grammar': true,
    'flutter.kl_tut_soriDeck': true,
  };
  Completer<bool>? pending;
  bool reject = false;
  @override
  Future<Map<String, Object>> getAll() async => {...values};
  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (key == 'flutter.kl_gram_plan_v1') {
      final accepted = pending == null ? !reject : await pending!.future;
      if (!accepted) return false;
    }
    values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    values.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    values.clear();
    return true;
  }
}

Future<void> _save(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_GRAMMAR_C')) return;
  await settleCNativeCaptureAssets(tester);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_capture),
  );
  final geometry = <Map<String, Object?>>[];
  if (name == 'plan-402-1.0') {
    for (final element
        in find
            .byWidgetPredicate(
              (widget) =>
                  widget is Text ||
                  widget is Image ||
                  widget is GrammarCLevelTray ||
                  widget is GrammarCPlanChoice ||
                  widget is GrammarCPlanPreview ||
                  widget is SoriButton,
            )
            .evaluate()) {
      final render = element.findRenderObject();
      if (render is! RenderBox || !render.hasSize) continue;
      final widget = element.widget;
      final rect = render.localToGlobal(Offset.zero) & render.size;
      geometry.add({
        'type': widget.runtimeType.toString(),
        'key': widget.key?.toString(),
        'text': widget is Text ? widget.data : null,
        'asset': widget is Image ? widget.image.toString() : null,
        'rect': [rect.left, rect.top, rect.width, rect.height],
      });
    }
  }
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    const directory = String.fromEnvironment(
      'GRAMMAR_CAPTURE_DIR',
      defaultValue: 'build/grammar-c-captures',
    );
    final file = File('$directory/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    if (geometry.isNotEmpty) {
      await File(
        '$directory/$name.geometry.json',
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(geometry));
    }
  });
}
