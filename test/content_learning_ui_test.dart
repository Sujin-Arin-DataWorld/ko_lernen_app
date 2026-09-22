import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_hub.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_models.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_service.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_widgets.dart';
import 'package:ko_lernen_app/features/content_learning/content_lesson_screen.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/models/smalltalk.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/smalltalk_loader.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/theme.dart';
import 'support/real_fonts.dart';
import 'support/reward_preferences_platform.dart';

const _title = LocalizedText(
  ko: '기분',
  de: 'Wie geht es dir heute?',
  en: 'How are you today?',
);
const _intro = LocalizedText(
  ko: '오늘 기분을 물어보세요.',
  de: 'Frage nach dem Befinden und lerne eine passende Antwort kennen.',
  en: 'Ask how someone is feeling and learn a useful response.',
);
const _phrases = [
  SmalltalkPhrase(
    id: 'p1',
    category: 'mood',
    level: 'a1',
    kind: 'question',
    ko: '오늘 기분이 어때요?',
    de: 'Wie geht es dir heute?',
    en: 'How are you feeling today?',
  ),
  SmalltalkPhrase(
    id: 'p2',
    category: 'mood',
    level: 'a1',
    kind: 'reaction',
    ko: '기분이 좋아요.',
    de: 'Mir geht es gut.',
    en: 'I feel good.',
  ),
];
const _lesson = ContentLesson(
  id: 'ui.lesson',
  kind: LearningContentKind.smalltalk,
  level: 'a1',
  topicId: 'mood',
  title: _title,
  intro: _intro,
  contentIds: ['p1', 'p2'],
  questions: [
    ContentLessonQuestion(
      id: 'q1',
      type: 'choice',
      skill: 'meaning',
      prompt: LocalizedText(
        ko: '무슨 뜻이에요?',
        de: 'Was bedeutet die Frage?',
        en: 'What does the question mean?',
      ),
      explanation: _intro,
      sourceIds: ['p1'],
      evidenceKo: '오늘 기분이 어때요?',
      options: [
        LocalizedText(
          ko: '기분',
          de: 'Nach dem Befinden fragen',
          en: 'Ask how someone feels',
        ),
        LocalizedText(
          ko: '시간',
          de: 'Nach der Uhrzeit fragen',
          en: 'Ask for the time',
        ),
      ],
    ),
    ContentLessonQuestion(
      id: 'q2',
      type: 'order',
      skill: 'sentence',
      prompt: _title,
      explanation: _intro,
      sourceIds: ['p2'],
      targetKo: '기분이 좋아요.',
    ),
  ],
);
const _listening = ContentLesson(
  id: 'ui.listening',
  kind: LearningContentKind.listening,
  level: 'a1',
  topicId: 'a1_greet',
  title: _title,
  intro: _intro,
  contentIds: ['scene'],
  questions: [
    ContentLessonQuestion(
      id: 'listen.q',
      type: 'choice',
      skill: 'situation',
      prompt: _title,
      explanation: _intro,
      sourceIds: ['scene'],
      options: [_title, _intro],
      evidenceKo: '안녕하세요.',
    ),
  ],
);
final _scenario = Scenario.fromJson({
  'id': 'scene',
  'level': 'a1',
  'title': {'ko': '인사', 'de': 'Begrüßung', 'en': 'Greetings'},
  'dialog': [
    {'speaker': 'user', 'ko': '안녕하세요.', 'de': 'Hallo.', 'en': 'Hello.'},
    {
      'speaker': 'minsu',
      'ko': '반가워요.',
      'de': 'Freut mich.',
      'en': 'Nice to meet you.',
    },
    {
      'speaker': 'user',
      'ko': '잘 지내세요?',
      'de': 'Wie geht es Ihnen?',
      'en': 'How are you?',
    },
  ],
});
const _capture = bool.fromEnvironment('CAPTURE_CONTENT_LEARNING_EVIDENCE');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadSoriRealFonts(materialIcons: true);
    await SmalltalkLoader.load();
  });
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });
  testWidgets('goals are per level and read-only hub does not start a day', (
    tester,
  ) async {
    await _pump(
      tester,
      const ContentGoalEditor(kind: LearningContentKind.smalltalk, level: 'a1'),
    );
    await tester.tap(find.byKey(const ValueKey('content-goal-2')));
    await tester.pumpAndSettle();
    expect(ContentLearningService.goal(LearningContentKind.smalltalk, 'a1'), 2);
    expect(
      ContentLearningService.goal(LearningContentKind.smalltalk, 'a2'),
      isNull,
    );
    expect(ContentLearningService.activeDaily(), isEmpty);
    await _pump(
      tester,
      ContentLearningHub(
        kind: LearningContentKind.smalltalk,
        loadLessons: () async => [_lesson],
      ),
    );
    await tester.pumpAndSettle();
    expect(ContentLearningService.activeDaily(), isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets('open today card clears yesterday at midnight without writing', (
    tester,
  ) async {
    var now = DateTime(2026, 9, 22, 23, 59, 59);
    ContentLearningService.clock = () => now;
    addTearDown(() => ContentLearningService.clock = DateTime.now);
    await ContentLearningService.setGoal(_lesson.kind, 'a1', 1);
    await ContentLearningService.startLesson(_lesson, [_lesson]);
    final before = Storage.contentLearningRawJson;
    await _pump(tester, const ContentDailyGoals());
    expect(find.byType(ListTile), findsOneWidget);
    now = DateTime(2026, 9, 23, 0, 0, 1);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(ListTile), findsNothing);
    expect(Storage.contentLearningRawJson, before);
  });
  testWidgets('corrupt progress shows retry instead of fresh progress', (
    tester,
  ) async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      Storage.contentLearningPreferenceKey: '{broken',
    });
    await Storage.init();
    await _pump(tester, const ContentDailyGoals());
    await tester.pumpAndSettle();
    expect(find.byType(ContentLearningFailure), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _pump(
      tester,
      const ContentGoalEditor(kind: LearningContentKind.smalltalk, level: 'a1'),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ContentLearningFailure), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final committed in [false, true]) {
    testWidgets(
      'unknown native write can retry on screen committed=$committed',
      (tester) async {
        final originalPlatform = SharedPreferencesStorePlatform.instance;
        Storage.resetForTesting();
        SharedPreferences.setMockInitialValues({});
        final platform = RewardPreferencesPlatform();
        SharedPreferencesStorePlatform.instance = platform;
        addTearDown(() {
          Storage.resetForTesting();
          SharedPreferences.setMockInitialValues({});
          SharedPreferencesStorePlatform.instance = originalPlatform;
        });
        await Storage.init();
        await ContentLearningService.startLesson(_lesson, [_lesson]);
        await _pump(
          tester,
          const ContentLessonScreen(
            lesson: _lesson,
            scope: [_lesson],
            phrases: _phrases,
          ),
        );
        await tester.pumpAndSettle();
        platform
          ..rejectKey = Storage.contentLearningPreferenceKey
          ..throwReply = true
          ..commitBeforeFailure = committed
          ..failReloadAfterWrite = true;
        await _tap(tester, find.byKey(const ValueKey('content-learn-next')));
        expect(find.byType(ContentLearningFailure), findsOneWidget);
        expect(
          () => ContentLearningService.progress(_lesson.id),
          throwsA(isA<PreferenceOutcomeUnknownException>()),
        );
        platform
          ..unavailable = false
          ..rejectKey = null;
        await _tap(tester, find.text('Try again'));
        expect(ContentLearningService.progress(_lesson.id).position, 1);
        expect(find.text('기분이 좋아요.'), findsOneWidget);
        expect(find.byType(ContentLearningFailure), findsNothing);
        expect(ContentLearningService.progress(_lesson.id).completed, isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('an old screen cannot write into a new account lifetime', (
    tester,
  ) async {
    await ContentLearningService.startLesson(_lesson, [_lesson]);
    await _pump(
      tester,
      const ContentLessonScreen(
        lesson: _lesson,
        scope: [_lesson],
        phrases: _phrases,
      ),
    );
    await tester.pumpAndSettle();
    LocalDataLifetime.invalidate();
    await _tap(tester, find.byKey(const ValueKey('content-learn-next')));
    expect(ContentLearningService.progress(_lesson.id).position, 0);
    expect(find.byType(ContentLearningFailure), findsOneWidget);
  });
  testWidgets('finish for today leaves study and preserves its credit', (
    tester,
  ) async {
    await ContentLearningService.setGoal(_lesson.kind, 'a1', 1);
    await ContentLearningService.startLesson(_lesson, [_lesson]);
    await ContentLearningService.savePosition(
      _lesson,
      ContentLessonPhase.practice,
      0,
    );
    for (final question in _lesson.questions) {
      await ContentLearningService.answer(_lesson, question.id, true);
    }
    await ContentLearningService.finish(_lesson);
    final before = Storage.contentLearningRawJson;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ContentLessonScreen(
                    lesson: _lesson,
                    scope: [_lesson],
                    phrases: _phrases,
                  ),
                ),
              ),
              child: const Text('Home fixture'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Home fixture'));
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Finish for today'));
    expect(find.byType(ContentLessonScreen), findsNothing);
    expect(find.text('Home fixture'), findsOneWidget);
    expect(Storage.contentLearningRawJson, before);
  });
  testWidgets(
    'source resume, wrong choice, order, result and mistake-only review',
    (tester) async {
      await ContentLearningService.setGoal(
        LearningContentKind.smalltalk,
        'a1',
        1,
      );
      await ContentLearningService.startLesson(_lesson, [_lesson]);
      await _pump(
        tester,
        const ContentLessonScreen(
          lesson: _lesson,
          scope: [_lesson],
          phrases: _phrases,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('오늘 기분이 어때요?'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('content-learn-next')));
      expect(
        ContentLearningService.progress(_lesson.id).seenIds,
        contains('p1'),
      );
      await _pump(
        tester,
        const ContentLessonScreen(
          key: ValueKey('resume'),
          lesson: _lesson,
          scope: [_lesson],
          phrases: _phrases,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('기분이 좋아요.'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('content-learn-next')));
      await _tap(tester, find.text('Ask for the time'));
      await _tap(tester, find.byKey(const ValueKey('content-check')));
      expect(
        ContentLearningService.progress(_lesson.id).missedQuestionIds,
        contains('q1'),
      );
      expect(find.text('Source passage'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('content-feedback-next')));
      await _tap(tester, find.text('기분이'));
      await _tap(tester, find.text('좋아요.'));
      await _tap(tester, find.byKey(const ValueKey('content-check')));
      await _tap(tester, find.byKey(const ValueKey('content-feedback-next')));
      expect(ContentLearningService.progress(_lesson.id).completed, isTrue);
      expect(
        ContentLearningService.daily(
          LearningContentKind.smalltalk,
          'a1',
        ).completedCount,
        1,
      );
      expect(find.text('Your daily goal is complete'), findsOneWidget);
      await _tap(tester, find.text('Review mistakes'));
      expect(ContentLearningService.progress(_lesson.id).practiceQuestionIds, [
        'q1',
      ]);
      await _tap(tester, find.text('Ask how someone feels'));
      await _tap(tester, find.byKey(const ValueKey('content-check')));
      await _tap(tester, find.byKey(const ValueKey('content-feedback-next')));
      expect(
        ContentLearningService.progress(_lesson.id).missedQuestionIds,
        isEmpty,
      );
      expect(
        ContentLearningService.daily(
          LearningContentKind.smalltalk,
          'a1',
        ).completedCount,
        1,
      );
    },
  );
  testWidgets(
    'listening resumes exact dialogue line and listening alone never completes',
    (tester) async {
      await ContentLearningService.setGoal(
        LearningContentKind.listening,
        'a1',
        1,
      );
      await ContentLearningService.startLesson(_listening, [_listening]);
      await ContentLearningService.savePosition(
        _listening,
        ContentLessonPhase.learn,
        1,
      );
      await _pump(
        tester,
        ContentLessonScreen(
          lesson: _listening,
          scope: const [_listening],
          scenario: _scenario,
          speak: (text, {voice = 'auto'}) async => true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('반가워요.'), findsOneWidget);
      await _tap(tester, find.text('Listen'));
      expect(ContentLearningService.progress(_listening.id).completed, isFalse);
      await _tap(tester, find.byKey(const ValueKey('content-learn-next')));
      expect(ContentLearningService.progress(_listening.id).position, 2);
      await _tap(tester, find.byKey(const ValueKey('content-learn-next')));
      expect(find.text('Key expressions'), findsWidgets);
      expect(
        ContentLearningService.progress(_listening.id).seenIds,
        contains('scene'),
      );
      await _tap(tester, find.byKey(const ValueKey('content-start-practice')));
      expect(
        ContentLearningService.progress(_listening.id).phase,
        ContentLessonPhase.practice,
      );
      expect(ContentLearningService.progress(_listening.id).completed, isFalse);
    },
  );
  testWidgets('autoplay ignores a late completion after pause', (tester) async {
    await ContentLearningService.startLesson(_listening, [_listening]);
    final playback = Completer<bool>();
    await _pump(
      tester,
      ContentLessonScreen(
        lesson: _listening,
        scope: const [_listening],
        scenario: _scenario,
        speak: (text, {voice = 'auto'}) => playback.future,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play from here'));
    await tester.pump();
    expect(find.text('Pause'), findsWidgets);
    await tester.tap(find.text('Pause').first);
    await tester.pump();
    playback.complete(true);
    await tester.pumpAndSettle();
    expect(ContentLearningService.progress(_listening.id).position, 0);
    expect(ContentLearningService.progress(_listening.id).completed, isFalse);
  });
  for (final lesson in [_lesson, _listening]) {
    testWidgets(
      'completed ${lesson.kind.name} can replay sources without new credit',
      (tester) async {
        await ContentLearningService.setGoal(lesson.kind, lesson.level, 1);
        await ContentLearningService.startLesson(lesson, [lesson]);
        await ContentLearningService.savePosition(
          lesson,
          ContentLessonPhase.practice,
          0,
        );
        for (final question in lesson.questions) {
          await ContentLearningService.answer(lesson, question.id, false);
        }
        await ContentLearningService.finish(lesson);
        final before = ContentLearningService.progress(lesson.id);
        await _pump(
          tester,
          ContentLessonScreen(
            lesson: lesson,
            scope: [lesson],
            phrases: _phrases,
            scenario: lesson.kind == LearningContentKind.listening
                ? _scenario
                : null,
          ),
        );
        await tester.pumpAndSettle();
        await _tap(tester, find.byKey(const ValueKey('content-learn-again')));
        expect(
          find.text(
            lesson.kind == LearningContentKind.listening
                ? '안녕하세요.'
                : '오늘 기분이 어때요?',
          ),
          findsOneWidget,
        );
        final after = ContentLearningService.progress(lesson.id);
        expect(after.phase, ContentLessonPhase.learn);
        expect(after.position, 0);
        expect(after.completedAt, before.completedAt);
        expect(after.missedQuestionIds, before.missedQuestionIds);
        expect(
          ContentLearningService.daily(
            lesson.kind,
            lesson.level,
          ).completedCount,
          1,
        );
      },
    );
  }
  testWidgets('next card starts at the heading after a long accessible card', (
    tester,
  ) async {
    await ContentLearningService.startLesson(_lesson, [_lesson]);
    await _pump(
      tester,
      const ContentLessonScreen(
        lesson: _lesson,
        scope: [_lesson],
        phrases: _phrases,
      ),
      locale: 'de',
      size: const Size(320, 640),
      scale: 2,
    );
    await tester.pumpAndSettle();
    final next = find.byKey(const ValueKey('content-learn-next'));
    final translation = find.text('Übersetzung zeigen');
    await tester.ensureVisible(translation);
    await tester.pumpAndSettle();
    final beforeTranslation = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .pixels;
    await tester.tap(translation);
    await tester.pumpAndSettle();
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels,
      beforeTranslation,
    );
    await tester.scrollUntilVisible(
      next,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(next);
    await tester.pumpAndSettle();
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels,
      greaterThan(100),
    );
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels,
      0,
    );
    final heading = tester.getRect(find.text('Lernen'));
    expect(heading.top, greaterThanOrEqualTo(0));
    expect(heading.bottom, lessThan(640));
    expect(tester.takeException(), isNull);
  });
  testWidgets('feedback next stops pending source audio', (tester) async {
    await ContentLearningService.startLesson(_lesson, [_lesson]);
    await ContentLearningService.savePosition(
      _lesson,
      ContentLessonPhase.practice,
      0,
    );
    final playback = Completer<bool>();
    await _pump(
      tester,
      ContentLessonScreen(
        lesson: _lesson,
        scope: const [_lesson],
        phrases: _phrases,
        speak: (text, {voice = 'auto'}) => playback.future,
      ),
    );
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Ask how someone feels'));
    await _tap(tester, find.byKey(const ValueKey('content-check')));
    await _tap(tester, find.text('Listen'));
    expect(find.text('Pause'), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('content-feedback-next')));
    playback.complete(false);
    await tester.pumpAndSettle();
    expect(find.text('Pause'), findsNothing);
    expect(find.text('Source passage'), findsNothing);
    expect(
      find.text('The audio could not be played. Tap Listen to try again.'),
      findsNothing,
    );
    expect(ContentLearningService.progress(_lesson.id).position, 1);
  });
  testWidgets(
    'late listening completion cannot repopulate reset account data',
    (tester) async {
      await ContentLearningService.startLesson(_listening, [_listening]);
      final playback = Completer<bool>();
      await _pump(
        tester,
        ContentLessonScreen(
          lesson: _listening,
          scope: const [_listening],
          scenario: _scenario,
          speak: (text, {voice = 'auto'}) => playback.future,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Play from here'));
      await tester.pump();
      await Storage.resetAll();
      expect(Storage.contentLearningRawJson, isEmpty);
      playback.complete(true);
      await tester.pumpAndSettle();
      expect(Storage.contentLearningRawJson, isEmpty);
      expect(
        ContentLearningService.progress(_listening.id).lastUpdatedAt,
        isNull,
      );
      expect(ContentLearningService.activeDaily(), isEmpty);
    },
  );
  testWidgets('whole dialogue opens expressions without completing practice', (
    tester,
  ) async {
    await ContentLearningService.startLesson(_listening, [_listening]);
    final spoken = <String>[];
    await _pump(
      tester,
      ContentLessonScreen(
        lesson: _listening,
        scope: const [_listening],
        scenario: _scenario,
        speak: (text, {voice = 'auto'}) async {
          spoken.add(text);
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Play from here'));
    expect(spoken, _scenario.dialog.map((line) => line.ko).toList());
    expect(find.text('Key expressions'), findsOneWidget);
    expect(ContentLearningService.progress(_listening.id).position, 3);
    expect(ContentLearningService.progress(_listening.id).completed, isFalse);
  });
  testWidgets('loading, failure retry and empty are distinct', (tester) async {
    final pending = Completer<List<ContentLesson>>();
    await _pump(
      tester,
      ContentLearningHub(
        kind: LearningContentKind.listening,
        loadLessons: () => pending.future,
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.completeError(StateError('load failure'));
    await tester.pumpAndSettle();
    expect(find.byType(ContentLearningFailure), findsOneWidget);
    var attempts = 0;
    await _pump(
      tester,
      ContentLearningHub(
        key: const ValueKey('retry'),
        kind: LearningContentKind.listening,
        loadLessons: () async {
          attempts++;
          if (attempts == 1) {
            throw StateError('once');
          }
          return [];
        },
      ),
    );
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Try again'));
    expect(attempts, 2);
    expect(
      find.text('No lessons are available for this level yet.'),
      findsOneWidget,
    );
  });
  for (final language in ['de', 'en']) {
    for (final size in [
      const Size(390, 844),
      const Size(1024, 768),
      const Size(1024, 1366),
    ]) {
      testWidgets(
        'goal layout and evidence $language ${size.width}x${size.height}',
        (tester) async {
          await _pump(
            tester,
            ContentLearningHub(
              kind: LearningContentKind.smalltalk,
              loadLessons: () async => [_lesson],
            ),
            locale: language,
            size: size,
          );
          await tester.pumpAndSettle();
          _expectBalancedAction(tester, 'content-goal-2', size);
          expect(tester.takeException(), isNull);
          if (_capture) {
            await _save(
              tester,
              'content-first-goal-$language-${_evidenceSize(size)}.png',
            );
          }
          await _pump(
            tester,
            const ContentGoalSettingsScreen(),
            locale: language,
            size: size,
          );
          await tester.pumpAndSettle();
          _expectBalancedAction(tester, 'content-goal-2', size);
          expect(tester.takeException(), isNull);
          if (_capture) {
            await _save(
              tester,
              'content-goal-settings-$language-${_evidenceSize(size)}.png',
            );
          }
        },
      );
      testWidgets('layout and evidence $language ${size.width}x${size.height}', (
        tester,
      ) async {
        await ContentLearningService.setGoal(
          LearningContentKind.smalltalk,
          'a1',
          2,
        );
        await ContentLearningService.startLesson(_lesson, [_lesson]);
        await _pump(
          tester,
          const ContentLessonScreen(
            lesson: _lesson,
            scope: [_lesson],
            phrases: _phrases,
          ),
          locale: language,
          size: size,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        _expectBalancedAction(tester, 'content-learn-next', size);
        if (_capture) {
          await _save(
            tester,
            'content-learning-$language-${_evidenceSize(size)}.png',
          );
        }
        await _tap(tester, find.byKey(const ValueKey('content-learn-next')));
        await _tap(tester, find.byKey(const ValueKey('content-learn-next')));
        expect(tester.takeException(), isNull);
        _expectBalancedAction(tester, 'content-check', size);
        if (_capture) {
          await _save(
            tester,
            'content-practice-$language-${_evidenceSize(size)}.png',
          );
        }
        await _tap(
          tester,
          find.text(_lesson.questions.first.options[1].pick(language)),
        );
        await _tap(tester, find.byKey(const ValueKey('content-check')));
        await _tap(tester, find.byKey(const ValueKey('content-feedback-next')));
        await _tap(tester, find.text('기분이'));
        await _tap(tester, find.text('좋아요.'));
        await _tap(tester, find.byKey(const ValueKey('content-check')));
        await _tap(tester, find.byKey(const ValueKey('content-feedback-next')));
        expect(ContentLearningService.progress(_lesson.id).completed, isTrue);
        final strings = AppL10n.of(
          tester.element(find.byType(ContentLessonScreen)),
        );
        expect(find.text(strings.contentLearningTodayDone), findsOneWidget);
        expect(find.text(strings.contentLearningEndToday), findsOneWidget);
        expect(
          find.text(strings.contentLearningReviewMistakes),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        _expectBalancedAction(tester, 'content-result-exit', size);
        final heading = tester.getRect(
          find.text(strings.contentLearningTodayDone),
        );
        expect(
          heading.center.dy,
          greaterThan(size.height * .25),
          reason:
              'Result text must use the body instead of clustering at the top.',
        );
        expect(heading.center.dy, lessThan(size.height * .65));
        if (_capture) {
          await _save(
            tester,
            'content-result-$language-${_evidenceSize(size)}.png',
          );
          await _pump(
            tester,
            ContentLearningHub(
              kind: LearningContentKind.smalltalk,
              loadLessons: () async => [_lesson],
            ),
            locale: language,
            size: size,
          );
          await tester.pumpAndSettle();
          await _save(
            tester,
            'content-hub-$language-${_evidenceSize(size)}.png',
          );
        }
        await ContentLearningService.startLesson(_listening, [_listening]);
        await _pump(
          tester,
          ContentLessonScreen(
            lesson: _listening,
            scope: const [_listening],
            scenario: _scenario,
          ),
          locale: language,
          size: size,
        );
        await tester.pumpAndSettle();
        _expectBalancedAction(tester, 'content-learn-next', size);
        expect(tester.takeException(), isNull);
        if (_capture) {
          await _save(
            tester,
            'content-listening-$language-${_evidenceSize(size)}.png',
          );
        }
      });
    }
  }
  testWidgets(
    'large German text keeps source actions reachable on narrow display',
    (tester) async {
      await ContentLearningService.startLesson(_lesson, [_lesson]);
      await _pump(
        tester,
        const ContentLessonScreen(
          lesson: _lesson,
          scope: [_lesson],
          phrases: _phrases,
        ),
        locale: 'de',
        size: const Size(320, 640),
        scale: 2,
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('content-learn-next')));
      expect(ContentLearningService.progress(_lesson.id).position, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('goal choices remain reachable in narrow large-text layouts', (
    tester,
  ) async {
    await _pump(
      tester,
      const ContentGoalSettingsScreen(),
      locale: 'de',
      size: const Size(320, 640),
      scale: 2,
    );
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const ValueKey('content-goal-0')));
    expect(ContentLearningService.goal(_lesson.kind, 'a1'), 0);
    expect(tester.takeException(), isNull);
  });
}

String _evidenceSize(Size size) => size.height == 1366
    ? '${size.width.toInt()}x${size.height.toInt()}'
    : '${size.width.toInt()}';

void _expectBalancedAction(WidgetTester tester, String key, Size size) {
  final action = tester.getRect(find.byKey(ValueKey(key)));
  expect(
    action.center.dy,
    greaterThan(size.height * .65),
    reason:
        'The primary action belongs in the lower viewport, not under a top-heavy text stack.',
  );
  expect(action.bottom, lessThanOrEqualTo(size.height - 8));
  for (final scroll in tester.stateList<ScrollableState>(
    find.byType(Scrollable),
  )) {
    expect(
      scroll.position.maxScrollExtent,
      lessThanOrEqualTo(1),
      reason: 'Short normal-size content should fit in one viewport.',
    );
  }
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  String locale = 'en',
  Size size = const Size(390, 844),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: Locale(locale),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: RepaintBoundary(
        key: const ValueKey('evidence'),
        child: Scaffold(body: child),
      ),
    ),
  );
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('evidence')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('docs/screenshots/$name');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
