import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/screens/satz_arcade_screen.dart';
import 'package:ko_lernen_app/screens/quest_engines/satz_bauen_quest.dart';
import 'package:ko_lernen_app/screens/quest_engines/quest_models.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/course_activity_reporter.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/satz_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/sound_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/app_error.dart';
import 'package:ko_lernen_app/widgets/app_loading.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/chrome_row.dart';
import 'package:ko_lernen_app/models/course_practice_context.dart';
import 'package:ko_lernen_app/widgets/sori/game_reward.dart';
import 'support/reward_preferences_platform.dart';
import 'support/sori_speech_stubs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final original = SharedPreferencesStorePlatform.instance;
  late RewardPreferencesPlatform platform;
  late SatzSentence sentence;
  late int conceptCount;
  setUp(() async {
    stubSoriSpeech();
    SoundService.playImpl = (_) {};
    Storage.resetForTesting();
    Storage.resetCourseMasteryForTesting();
    CourseProgressService.shared.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    platform = RewardPreferencesPlatform();
    SharedPreferencesStorePlatform.instance = platform;
    await Storage.init();
    final catalog = await CurriculumCatalog.load();
    final linked = catalog.contentLinks
        .where((l) => l.contentKind == CurriculumContentKind.satz)
        .map((l) => l.contentId)
        .toSet();
    sentence = (await SatzLoader.load()).firstWhere(
      (s) => linked.contains(s.id) && s.vocabKo.isNotEmpty,
    );
    conceptCount = catalog
        .linksForContent(CurriculumContentKind.satz, sentence.id)
        .expand((l) => l.conceptIds)
        .toSet()
        .length;
    await CourseProgressService.shared.initializeForPlacement('a1');
    platform.writes.clear();
  });
  tearDown(() {
    SoundService.resetForTesting();
    Storage.resetForTesting();
    Storage.resetCourseMasteryForTesting();
    CourseProgressService.shared.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = original;
  });
  test(
    'ordinary course calls with the same timestamp remain distinct',
    () async {
      final time = DateTime.utc(2026, 9, 11, 10);
      for (var i = 0; i < 2; i++) {
        await CourseProgressService.shared.recordContentAttempt(
          CurriculumContentKind.satz,
          sentence.id,
          true,
          occurredAt: time,
        );
      }
      final snapshot = await CourseProgressService.shared.readForDisplay();
      expect(
        snapshot!.evidence.where((e) => e.contentId == sentence.id).length,
        conceptCount * 2,
      );
    },
  );
  test(
    'distinct retained answers sharing a timestamp never collapse',
    () async {
      final time = DateTime.utc(2026, 9, 11, 10);
      final first = CourseContentAttempt(
        kind: CurriculumContentKind.satz,
        contentId: sentence.id,
        isCorrect: true,
        occurredAt: time,
      );
      final second = CourseContentAttempt(
        kind: CurriculumContentKind.satz,
        contentId: sentence.id,
        isCorrect: true,
        occurredAt: time,
      );
      final firstSave = first.save();
      expect(identical(first.save(), firstSave), isTrue);
      await Future.wait([firstSave, second.save()]);
      await first.save();
      await second.save();
      final snapshot = await CourseProgressService.shared.readForDisplay();
      final evidence = snapshot!.evidence
          .where((e) => e.contentId == sentence.id)
          .toList();
      expect(evidence.length, conceptCount * 2);
      expect(evidence.map((e) => e.id).toSet().length, conceptCount * 2);
    },
  );
  test('retained saved course result expires after local reset', () async {
    final attempt = CourseContentAttempt(
      kind: CurriculumContentKind.satz,
      contentId: sentence.id,
      isCorrect: true,
    );
    await attempt.save();
    await Storage.resetAllStrict();
    await expectLater(
      attempt.save(),
      throwsA(isA<StaleLocalDataLifetimeException>()),
    );
    expect(Storage.courseMasterySnapshotRawJson, isEmpty);
  });
  for (final stage in ['card', 'log', 'course']) {
    for (final committed in [false, true]) {
      for (final passed in [false, true]) {
        testWidgets(
          '$stage unknown committed=$committed passed=$passed reconciles one answer',
          (tester) async {
            await _pump(tester, sentence);
            final key = _key(stage);
            platform
              ..rejectKey = key
              ..throwReply = true
              ..commitBeforeFailure = committed
              ..failReloadAfterWrite = true;
            final answer = _complete(tester, passed: passed);
            answer();
            answer();
            await _flush(tester);
            expect(find.byType(AppError), findsOneWidget);
            expect(Storage.xp, 0);
            final retry = tester
                .widget<AppError>(find.byType(AppError))
                .onRetry!;
            final writesBefore = Map.of(platform.writes);
            retry();
            await _flush(tester);
            expect(
              platform.writes,
              writesBefore,
              reason: 'No mutation while durable state cannot be read.',
            );
            platform
              ..rejectKey = null
              ..unavailable = false;
            retry();
            retry();
            await _flush(tester);
            await tester.pump(const Duration(milliseconds: 301));
            await _flush(tester);
            expect(find.byType(AppError), findsNothing);
            expect(find.byType(GameOverCard), findsOneWidget);
            expect(Storage.srsCard(sentence.vocabKo)?.reviewCount, 1);
            expect(
              Storage.studyLogIdsFor(Storage.todayIso()),
              contains(sentence.vocabKo),
            );
            expect(Storage.xp, passed ? 5 : 0);
            final snapshot = await CourseProgressService.shared
                .readForDisplay();
            final evidence = snapshot!.evidence
                .where((e) => e.contentId == sentence.id)
                .toList();
            expect(evidence.length, conceptCount);
            expect(
              evidence.every(
                (e) =>
                    e.isCorrect == passed &&
                    e.courseUnitId == null &&
                    e.missionContentLinkId == null,
              ),
              isTrue,
            );
            if (!passed) {
              expect(
                evidence.every(
                  (e) => e.errorReason == MasteryErrorReason.wordOrder,
                ),
                isTrue,
              );
            }
            final confirmedWrites = Map.of(platform.writes);
            answer();
            retry();
            await _flush(tester);
            expect(platform.writes, confirmedWrites);
            await _dispose(tester);
          },
        );
      }
    }
    for (final retirement in ['exit', 'unmount', 'pop', 'reset']) {
      testWidgets('$stage pending answer retires on $retirement', (
        tester,
      ) async {
        await _pump(tester, sentence, pushed: retirement == 'pop');
        final release = Completer<void>();
        platform
          ..rejectKey = _key(stage)
          ..releaseWrite = release
          ..successfulReply = true
          ..commitBeforeFailure = true;
        final answer = _complete(tester);
        answer();
        await _flush(tester);
        expect(find.byType(AppLoading), findsOneWidget);
        expect(
          platform.writes[_key(stage)],
          1,
          reason: 'The native target write must actually be pending.',
        );
        Future<void>? reset;
        if (retirement == 'exit') {
          tester.widget<SoriStudyFrame>(find.byType(SoriStudyFrame)).onLeave!();
        } else if (retirement == 'unmount') {
          await tester.pumpWidget(const SizedBox());
        } else if (retirement == 'pop') {
          Navigator.of(tester.element(find.byType(SoriStudyFrame))).pop();
        } else {
          reset = Storage.resetAllStrict();
        }
        release.complete();
        await _flush(tester);
        if (reset != null) {
          await reset;
          expect(Storage.srsCard(sentence.vocabKo), isNull);
          expect(Storage.courseMasterySnapshotRawJson, isEmpty);
        }
        if (stage != 'course') {
          expect(
            platform.writes[Storage.courseMasterySnapshotPreferenceKey],
            isNull,
            reason: 'Retirement cannot admit the next course-write leg.',
          );
        }
        final writesAfter = Map.of(platform.writes);
        answer();
        await tester.pump(const Duration(seconds: 2));
        await _flush(tester);
        expect(Storage.xp, 0);
        expect(platform.writes, writesAfter);
        await _dispose(tester);
      });
    }
    testWidgets('native $stage rejection keeps answer pending until retry', (
      tester,
    ) async {
      await _pump(tester, sentence);
      final key = _key(stage);
      platform.rejectKey = key;
      _complete(tester)();
      await _flush(tester);
      await tester.pump(const Duration(seconds: 1));
      await _flush(tester);
      expect(find.byType(AppError), findsOneWidget);
      expect(find.byType(GameOverCard), findsNothing);
      expect(Storage.xp, 0);
      platform.rejectKey = null;
      tester.widget<AppError>(find.byType(AppError)).onRetry!();
      await _flush(tester);
      await tester.pump(const Duration(milliseconds: 301));
      await _flush(tester);
      expect(find.byType(GameOverCard), findsOneWidget);
      expect(Storage.srsCard(sentence.vocabKo)?.reviewCount, 1);
      expect(Storage.xp, 5);
      final snapshot = await CourseProgressService.shared.readForDisplay();
      expect(
        snapshot!.evidence.where((e) => e.contentId == sentence.id).isNotEmpty,
        isTrue,
      );
      await _dispose(tester);
    });
  }

  testWidgets('unlinked free sentence without vocabulary stays playable', (
    tester,
  ) async {
    const unlinked = SatzSentence(
      id: 'unlinked-fixture',
      level: 'a1',
      targetKo: '가요',
      promptDe: 'Ich gehe.',
      promptEn: 'I go.',
      distractors: [],
    );
    await _pump(tester, unlinked);
    _complete(tester)();
    await _flush(tester);
    await tester.pump(const Duration(milliseconds: 301));
    await _flush(tester);
    expect(find.byType(GameOverCard), findsOneWidget);
    expect(Storage.xp, 5);
    expect(platform.writes['kl_srs_v1'], isNull);
    final snapshot = await CourseProgressService.shared.readForDisplay();
    expect(snapshot!.evidence, isEmpty);
    await _dispose(tester);
  });

  testWidgets('accepted callback stays consumed during delayed advancement', (
    tester,
  ) async {
    await _pump(tester, sentence);
    final answer = _complete(tester);
    answer();
    await _flush(tester);
    expect(Storage.srsCard(sentence.vocabKo)?.reviewCount, 1);
    answer();
    await _flush(tester);
    await tester.pump(const Duration(milliseconds: 301));
    await _flush(tester);
    expect(Storage.srsCard(sentence.vocabKo)?.reviewCount, 1);
    expect(Storage.xp, 5);
    final snapshot = await CourseProgressService.shared.readForDisplay();
    expect(
      snapshot!.evidence.where((e) => e.contentId == sentence.id).length,
      conceptCount,
    );
    expect(find.byType(GameOverCard), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('typed mission keeps original graph edge after recovery', (
    tester,
  ) async {
    final catalog = await CurriculumCatalog.load();
    CourseProgressService.shared.resetForTesting();
    final activeLinks = catalog.linksForCourseUnit(Storage.courseUnitId!);
    final link = activeLinks.firstWhere(
      (l) => l.contentKind == CurriculumContentKind.satz,
    );
    final missionSentence = (await SatzLoader.load()).firstWhere(
      (s) => s.id == link.contentId,
    );
    await _pump(
      tester,
      missionSentence,
      courseContext: CoursePracticeContext.fromLink(link),
    );
    platform.rejectKey = Storage.courseMasterySnapshotPreferenceKey;
    _complete(tester)();
    await _flush(tester);
    expect(find.byType(AppError), findsOneWidget);
    platform.rejectKey = null;
    tester.widget<AppError>(find.byType(AppError)).onRetry!();
    await _flush(tester);
    await tester.pump(const Duration(milliseconds: 301));
    await _flush(tester);
    final snapshot = await CourseProgressService.shared.readForDisplay();
    final evidence = snapshot!.evidence
        .where((e) => e.contentId == missionSentence.id)
        .toList();
    expect(evidence.length, link.conceptIds.length);
    expect(
      evidence.every(
        (e) =>
            e.missionContentLinkId == link.id &&
            e.courseUnitId == link.courseUnitId,
      ),
      isTrue,
    );
    await _dispose(tester);
  });

  testWidgets('popped route rejects retained answer before disposal', (
    tester,
  ) async {
    await _pump(tester, sentence, pushed: true);
    final answer = _complete(tester);
    final context = tester.element(find.byType(SoriStudyFrame));
    Navigator.of(context).pop();
    expect(context.mounted, isTrue);
    answer();
    await _flush(tester);
    expect(platform.writes['kl_srs_v1'], isNull);
    await _dispose(tester);
  });

  testWidgets('old filter callback cannot open a sheet in a replayed round', (
    tester,
  ) async {
    await _pump(tester, sentence, production: true);
    final oldFilter = tester
        .widget<SoriChromeRow>(find.byType(SoriChromeRow))
        .onFilterTap!;
    for (var i = 0; i < 8; i++) {
      _complete(tester)();
      await _flush(tester);
      await tester.pump(const Duration(milliseconds: 301));
      await _flush(tester);
    }
    final t = AppL10n.of(tester.element(find.byType(GameOverCard)));
    tester
        .widgetList<SoriButton>(find.byType(SoriButton))
        .singleWhere((b) => b.label == t.quizAgain)
        .onTap!();
    await _flush(tester);
    oldFilter();
    await _flush(tester);
    expect(find.byType(BottomSheet), findsNothing);
    tester.widget<SoriChromeRow>(find.byType(SoriChromeRow)).onFilterTap!();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(BottomSheet), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('old answer and result callbacks cannot alter replayed round', (
    tester,
  ) async {
    await _pump(tester, sentence);
    final answer = _complete(tester);
    answer();
    await _flush(tester);
    await tester.pump(const Duration(milliseconds: 301));
    await _flush(tester);
    final t = AppL10n.of(tester.element(find.byType(GameOverCard)));
    final replay = tester
        .widgetList<SoriButton>(find.byType(SoriButton))
        .singleWhere((b) => b.label == t.quizAgain)
        .onTap!;
    final close = tester
        .widgetList<SoriButton>(find.byType(SoriButton))
        .singleWhere((b) => b.label == t.btnClose)
        .onTap!;
    replay();
    await _flush(tester);
    final newQuestKey = tester
        .widget<SatzBauenQuest>(find.byType(SatzBauenQuest))
        .key;
    final writes = Map.of(platform.writes);
    answer();
    replay();
    close();
    await tester.pump(const Duration(seconds: 1));
    await _flush(tester);
    expect(
      tester.widget<SatzBauenQuest>(find.byType(SatzBauenQuest)).key,
      newQuestKey,
    );
    expect(platform.writes, writes);
    expect(Storage.xp, 5);
    await _dispose(tester);
  });
}

String _key(String stage) => switch (stage) {
  'card' => 'kl_srs_v1',
  'log' => 'kl_study_log_v1_${Storage.todayIso()}',
  _ => Storage.courseMasterySnapshotPreferenceKey,
};

VoidCallback _complete(WidgetTester tester, {bool passed = true}) {
  final callback = tester
      .widget<SatzBauenQuest>(find.byType(SatzBauenQuest))
      .onComplete;
  return () => callback(QuestResult(passed: passed, firstTry: passed));
}

Future<void> _pump(
  WidgetTester tester,
  SatzSentence sentence, {
  bool pushed = false,
  bool production = false,
  CoursePracticeContext? courseContext,
}) async {
  // The setUp placement writes real storage, but its queue Future belongs to
  // the outer test zone. Recreate the screen queue inside testWidgets.
  CourseProgressService.shared.resetForTesting();
  final navigator = GlobalKey<NavigatorState>();
  final game = SatzArcadeScreen(
    items: production ? null : [sentence],
    courseContext: courseContext,
  );
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: pushed ? const SizedBox() : game,
    ),
  );
  if (pushed) {
    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => game),
      ),
    );
  }
  await _flush(tester);
  if (pushed) {
    await tester.pump(const Duration(milliseconds: 500));
    await _flush(tester);
  }
}

Future<void> _flush(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump();
  }
}

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 2));
  expect(tester.takeException(), isNull);
}
