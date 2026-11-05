import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_catalog.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_models.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_service.dart';
import 'package:ko_lernen_app/features/content_learning/content_lesson_screen.dart';
import 'package:ko_lernen_app/features/content_learning/listening_object_art.dart';
import 'package:ko_lernen_app/features/content_learning/listening_recovery_widgets.dart';
import 'package:ko_lernen_app/features/content_learning/listening_figma_materials.dart';
import 'package:ko_lernen_app/widgets/sori/pressable.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/smalltalk_loader.dart';
import 'package:ko_lernen_app/services/sound_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/yeopjeon_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'support/real_fonts.dart';
import 'support/reward_preferences_platform.dart';
import 'support/sori_speech_stubs.dart';

const _capture = String.fromEnvironment('HOREN_CAPTURE_DIR');
const _boundary = ValueKey('horen-c-capture');

class _CompletionPreferences extends RewardPreferencesPlatform {
  bool failCompletion = false;
  bool unknownCompletion = false;
  Completer<void>? completionGate;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (key.endsWith(Storage.contentLearningPreferenceKey) &&
        value is String &&
        value.contains('"phase":"complete"')) {
      await completionGate?.future;
      if (unknownCompletion) {
        values[key.substring('flutter.'.length)] = value;
        unavailable = true;
        throw StateError('Completion reply lost');
      }
      if (failCompletion) return false;
    }
    return super.setValue(type, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<ContentLesson> lessons;
  late List<Scenario> scenarios;
  late ContentLesson lesson;
  late Scenario scenario;
  late _CompletionPreferences platform;
  setUpAll(() async {
    await loadSoriRealFonts(materialIcons: true);
    await CurriculumCatalog.load();
    await SmalltalkLoader.load();
    await ContentLearningCatalog.load(LearningContentKind.smalltalk);
    lessons = await ContentLearningCatalog.load(LearningContentKind.listening);
    scenarios = await ScenarioLoader.load();
    lesson = lessons.firstWhere(
      (l) => l.contentIds.contains('clothing_refund_size'),
    );
    scenario = scenarios.firstWhere((s) => s.id == 'clothing_refund_size');
  });
  setUp(() async {
    stubSoriSpeech();
    SoundService.playImpl = (_) {};
    addTearDown(SoundService.resetForTesting);
    final previous = SharedPreferencesStorePlatform.instance;
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    platform = _CompletionPreferences();
    SharedPreferencesStorePlatform.instance = platform;
    addTearDown(() {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({});
      SharedPreferencesStorePlatform.instance = previous;
    });
    await Storage.init();
    await ContentLearningService.setGoal(lesson.kind, lesson.level, 0);
    await ContentLearningService.startLesson(lesson, [lesson]);
  });

  test(
    '90 live topics use the 20 original and 55 byte-identical expansion objects',
    () {
      final topics = lessons.map((l) => l.topicId).toSet();
      expect(topics.length, 90);
      expect(listeningObjects.keys.toSet(), topics);
      expect(lessons.map((l) => l.level).toSet(), {
        'a1',
        'a2',
        'b1',
        'b2',
        'c1',
        'c2',
      });
      final manifest =
          jsonDecode(
                File(
                  'docs/design/HOREN_ORIGINAL_ASSETS_20261103.json',
                ).readAsStringSync(),
              )
              as List;
      expect(manifest.length, 55);
      expect(manifest.expand((e) => e['topics'] as List).length, 70);
      for (final entry in manifest) {
        expect(
          sha256
              .convert(File(entry['runtime'] as String).readAsBytesSync())
              .toString(),
          entry['sha256'],
        );
        for (final topic in entry['topics'] as List) {
          expect(
            listeningObjects[topic]?.file,
            (entry['runtime'] as String).split('/').last,
          );
        }
      }
    },
  );

  Future<void> answerLesson() async {
    expect(lesson.questions.length, 4);
    await ContentLearningService.savePosition(
      lesson,
      ContentLessonPhase.practice,
      0,
      sourcesComplete: true,
    );
    for (var i = 0; i < lesson.questions.length; i++) {
      await ContentLearningService.answer(
        lesson,
        lesson.questions[i].id,
        i != 1,
      );
    }
  }

  testWidgets(
    'failed completion preserves answers, disables retry during write, then records one result',
    (tester) async {
      await answerLesson();
      final answers = Map.of(
        ContentLearningService.progress(lesson.id).answers,
      );
      platform.failCompletion = true;
      await _pump(tester, lesson, scenario);
      await _tap(
        tester,
        find.text(
          AppL10n.of(
            tester.element(find.byType(ContentLessonScreen)),
          ).contentLearningFinish,
        ),
      );
      expect(find.text('Noch nicht gespeichert.'), findsOneWidget);
      expect(find.text('3 von 4 richtig'), findsOneWidget);
      expect(ContentLearningService.progress(lesson.id).completed, isFalse);
      expect(ContentLearningService.progress(lesson.id).answers, answers);
      await _save(tester, 'save-error');
      platform.failCompletion = false;
      platform.completionGate = Completer<void>();
      await tester.tap(find.byKey(const ValueKey('listening-save-retry')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Wird gespeichert …'), findsNWidgets(2));
      expect(ContentLearningService.progress(lesson.id).answers, answers);
      expect(
        tester
            .widget<ListeningOutcomePanel>(find.byType(ListeningOutcomePanel))
            .saving,
        isTrue,
      );
      await _save(tester, 'retrying');
      platform.completionGate!.complete();
      await tester.pumpAndSettle();
      expect(ContentLearningService.progress(lesson.id).completed, isTrue);
      expect(find.byType(ListeningResultPanel), findsOneWidget);
      expect(find.text('3 von 4 richtig'), findsOneWidget);
      await _save(tester, 'result');
      final completed = ContentLearningService.progress(lesson.id).completedAt;
      final wallet = await YeopjeonService.captureBackupJson();
      await _tap(tester, find.byKey(const ValueKey('content-learn-again')));
      expect(
        ContentLearningService.progress(lesson.id).phase,
        ContentLessonPhase.learn,
      );
      expect(ContentLearningService.progress(lesson.id).completedAt, completed);
      expect(await YeopjeonService.captureBackupJson(), wallet);
      expect(tester.takeException(), isNull);
    },
  );

  for (final throwAudio in [false, true]) {
    testWidgets(
      'audio ${throwAudio ? 'exception' : 'false'} retries exact line and voice, reading preserves cursor',
      (tester) async {
        final calls = <(String, String)>[];
        await _pump(
          tester,
          lesson,
          scenario,
          speak: (text, {voice = 'auto'}) async {
            calls.add((text, voice));
            if (throwAudio) throw StateError('audio unavailable');
            return false;
          },
        );
        await _tap(tester, find.byKey(const ValueKey('listening-replay-0')));
        expect(find.byType(ListeningAudioRecovery), findsOneWidget);
        await _tap(tester, find.byKey(const ValueKey('listening-audio-retry')));
        expect(calls, [
          (
            scenario.dialog[0].ko,
            scenario.voiceForSpeaker(scenario.dialog[0].speaker),
          ),
          (
            scenario.dialog[0].ko,
            scenario.voiceForSpeaker(scenario.dialog[0].speaker),
          ),
        ]);
        expect(ContentLearningService.progress(lesson.id).position, 0);
        await _save(tester, 'audio-error');
        await _tap(tester, find.byKey(const ValueKey('listening-audio-read')));
        expect(find.byType(ListeningAudioRecovery), findsNothing);
        expect(find.text(scenario.dialog[0].ko), findsOneWidget);
        expect(ContentLearningService.progress(lesson.id).position, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('unknown completion reply reconciles durable data before retry', (
    tester,
  ) async {
    await answerLesson();
    platform.unknownCompletion = true;
    await _pump(tester, lesson, scenario);
    final finish = AppL10n.of(
      tester.element(find.byType(ContentLessonScreen)),
    ).contentLearningFinish;
    await _tap(tester, find.text(finish));
    expect(find.text('Noch nicht gespeichert.'), findsOneWidget);
    expect(find.text('3 von 4 richtig'), findsOneWidget);
    expect(
      () => ContentLearningService.progress(lesson.id),
      throwsA(isA<PreferenceOutcomeUnknownException>()),
    );
    platform
      ..unknownCompletion = false
      ..unavailable = false;
    await _tap(tester, find.byKey(const ValueKey('listening-save-retry')));
    expect(ContentLearningService.progress(lesson.id).completed, isTrue);
    expect(find.byType(ListeningResultPanel), findsOneWidget);
    final completed = ContentLearningService.progress(lesson.id).completedAt;
    final wallet = await YeopjeonService.captureBackupJson();
    await ContentLearningService.finish(lesson);
    await YeopjeonService.grantConfirmedLesson(lessonId: lesson.id);
    expect(ContentLearningService.progress(lesson.id).completedAt, completed);
    expect(await YeopjeonService.captureBackupJson(), wallet);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'audio recovery keeps both authored turns and opened translations',
    (tester) async {
      await ContentLearningService.savePosition(
        lesson,
        ContentLessonPhase.learn,
        1,
      );
      await _pump(
        tester,
        lesson,
        scenario,
        speak: (text, {voice = 'auto'}) async => false,
      );
      await _tap(tester, find.byKey(const ValueKey('listening-translation-0')));
      await _tap(tester, find.byKey(const ValueKey('listening-translation-1')));
      await _tap(tester, find.byKey(const ValueKey('listening-replay-1')));
      expect(find.byType(ListeningAudioRecovery), findsOneWidget);
      expect(find.text(scenario.dialog[0].pick('de')), findsOneWidget);
      expect(find.text(scenario.dialog[1].pick('de')), findsOneWidget);
      expect(find.text('Du'), findsOneWidget);
      expect(find.text('Service'), findsOneWidget);
      expect(find.text('Lena'), findsNothing);
      expect(find.text('Mitarbeiterin'), findsNothing);
      expect(
        find.byKey(const ValueKey('listening-learner-role-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('listening-service-role-0')),
        findsOneWidget,
      );
      expect(ContentLearningService.progress(lesson.id).position, 1);
      await _save(tester, 'audio-error-two-turns');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'autoplay failure retries the failed source and resumes the real dialogue',
    (tester) async {
      final calls = <String>[];
      var fail = true;
      await _pump(
        tester,
        lesson,
        scenario,
        speak: (text, {voice = 'auto'}) async {
          calls.add(text);
          return !fail || text != scenario.dialog[1].ko;
        },
      );
      await _tap(
        tester,
        find.byKey(const ValueKey('content-listening-autoplay')),
      );
      expect(ContentLearningService.progress(lesson.id).position, 1);
      fail = false;
      await _tap(tester, find.byKey(const ValueKey('listening-audio-retry')));
      expect(calls.take(3).toList(), [
        scenario.dialog[0].ko,
        scenario.dialog[1].ko,
        scenario.dialog[1].ko,
      ]);
      expect(
        ContentLearningService.progress(lesson.id).position,
        scenario.dialog.length,
      );
      expect(ContentLearningService.progress(lesson.id).completed, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  for (final view in [
    (402.0, 874.0, 1.0),
    (320.0, 640.0, 1.0),
    (320.0, 874.0, 2.0),
  ]) {
    testWidgets('reading action and navigation stay separate at $view', (
      tester,
    ) async {
      await _pump(
        tester,
        lesson,
        scenario,
        size: Size(view.$1, view.$2),
        scale: view.$3,
        speak: (text, {voice = 'auto'}) async => false,
      );
      await _tap(tester, find.byKey(const ValueKey('listening-replay-0')));
      final read = find.byKey(const ValueKey('listening-audio-read'));
      await tester.ensureVisible(read);
      await tester.pumpAndSettle();
      final readRect = tester.getRect(read);
      final navRect = tester.getRect(
        find.byKey(const ValueKey('listening-bottom-navigation')),
      );
      expect(readRect.height, greaterThanOrEqualTo(48));
      expect(navRect.top - readRect.bottom, greaterThanOrEqualTo(16));
      expect(readRect.overlaps(navRect), isFalse);
      expect(read.hitTestable(), findsOneWidget);
      expect(navRect.bottom, lessThanOrEqualTo(view.$2));
      await _save(tester, 'footer-${view.$1}-${view.$3}');
      final before = ContentLearningService.progress(lesson.id).position;
      await tester.tap(read);
      await tester.pumpAndSettle();
      expect(find.byType(ListeningAudioRecovery), findsNothing);
      expect(ContentLearningService.progress(lesson.id).position, before);
      expect(tester.takeException(), isNull);
    });
  }

  for (final reduced in [false, true]) {
    testWidgets(
      'retry face gives depth without scaling text; reduced motion $reduced',
      (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 300,
                    child: ListeningFigmaPrimary(
                      label: 'Ton wiederholen',
                      onTap: () => taps++,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        final label = find.text('Ton wiederholen');
        final original = tester.getTopLeft(label);
        final press = find.byType(SoriPressable);
        final gesture = await tester.startGesture(tester.getCenter(press));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 170));
        final pressed = tester.getTopLeft(label);
        expect(pressed.dx, closeTo(original.dx, .01));
        expect(
          pressed.dy - original.dy,
          reduced ? closeTo(0, .01) : greaterThan(1),
        );
        await gesture.up();
        await tester.pumpAndSettle();
        expect(taps, 1);
        expect(tester.getTopLeft(label).dy, closeTo(original.dy, .01));
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final view in [(320.0, 640.0, 1.0), (320.0, 874.0, 2.0)]) {
    testWidgets('real result and mistake review remain reachable at $view', (
      tester,
    ) async {
      await answerLesson();
      await ContentLearningService.finish(lesson);
      await _pump(
        tester,
        lesson,
        scenario,
        size: Size(view.$1, view.$2),
        scale: view.$3,
      );
      expect(find.text('3 von 4 richtig'), findsOneWidget);
      await _tap(
        tester,
        find.byKey(const ValueKey('listening-result-practice')),
      );
      final progress = ContentLearningService.progress(lesson.id);
      expect(progress.phase, ContentLessonPhase.practice);
      expect(progress.practiceQuestionIds, [lesson.questions[1].id]);
      expect(progress.completed, isTrue);
      expect(tester.takeException(), isNull);
      await _save(tester, 'review-${view.$1}-${view.$3}');
    });
  }
}

Future<void> _pump(
  WidgetTester tester,
  ContentLesson lesson,
  Scenario scenario, {
  Size size = const Size(402, 874),
  double scale = 1,
  Future<bool> Function(String, {String voice})? speak,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
  tester.view.viewPadding = const FakeViewPadding(top: 59, bottom: 34);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('de'),
      debugShowCheckedModeBanner: false,
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: RepaintBoundary(key: _boundary, child: child!),
      ),
      home: ContentLessonScreen(
        lesson: lesson,
        scope: [lesson],
        scenario: scenario,
        speak: speak,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester, String name) async {
  if (_capture.isEmpty) return;
  final context = tester.element(find.byType(MaterialApp));
  final providers = tester
      .widgetList<Image>(find.byType(Image))
      .map((im) => im.image)
      .toSet();
  await tester.runAsync(() async {
    await Future.wait(
      providers.map(
        (p) => precacheImage(p, context).timeout(const Duration(seconds: 15)),
      ),
    );
  });
  await tester.pump();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$_capture/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
