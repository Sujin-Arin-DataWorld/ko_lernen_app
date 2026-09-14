import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_practice_context.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/sound_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/vocab_pack_finish_coordinator.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/app_error.dart';
import 'package:ko_lernen_app/widgets/app_loading.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/quiz_choice.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'helpers/deck_actions.dart';
import 'support/reward_preferences_platform.dart';
import 'support/sori_speech_stubs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final original = SharedPreferencesStorePlatform.instance;
  late RewardPreferencesPlatform platform;
  late ContentLink link;
  late Vocab word;
  late Vocab secondWord;
  late VocabPack pack;
  late int conceptCount;

  setUp(() async {
    stubSoriSpeech();
    SoundService.playImpl = (_) {};
    Storage.resetForTesting();
    Storage.resetCourseMasteryForTesting();
    CourseProgressService.shared.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    platform = RewardPreferencesPlatform();
    SharedPreferencesStorePlatform.instance = platform;
    await Storage.init();
    await Storage.setTutVocabPackSeen();
    await Storage.setTutPackQuizSeen();
    await Storage.setTutPackBossSeen();
    final catalog = await CurriculumCatalog.load();
    final words = await DataLoader.loadVocab();
    final byId = <String, Vocab>{for (final item in words) item.id: item};
    link = catalog.contentLinks.firstWhere(
      (candidate) =>
          candidate.contentKind == CurriculumContentKind.vocab &&
          byId[candidate.contentId]?.isReviewBoss == false,
    );
    word = byId[link.contentId]!;
    secondWord = catalog.contentLinks
        .where(
          (candidate) =>
              candidate.contentKind == CurriculumContentKind.vocab &&
              candidate.contentId != word.id &&
              byId[candidate.contentId]?.isReviewBoss == false &&
              byId[candidate.contentId]?.translationFor('en') !=
                  word.translationFor('en'),
        )
        .map((candidate) => byId[candidate.contentId]!)
        .first;
    pack = VocabPack(id: word.packId, level: word.level, words: <Vocab>[word]);
    conceptCount = catalog
        .linksForContent(CurriculumContentKind.vocab, word.id)
        .expand((candidate) => candidate.conceptIds)
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
    SharedPreferences.setMockInitialValues(<String, Object>{});
    SharedPreferencesStorePlatform.instance = original;
  });

  testWidgets(
    'native course rejection retains the accepted recognition before feedback',
    (tester) async {
      await _pumpPack(
        tester,
        pack,
        courseContext: CoursePracticeContext.fromLink(link),
      );
      final t = await AppL10n.delegate.load(const Locale('en'));
      tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      tapDeckAction(tester, t.vocabPackGotIt);
      await tester.pump();
      await _flush(tester);

      platform.rejectKey = Storage.courseMasterySnapshotPreferenceKey;
      final correct = tester
          .widgetList<QuizChoice>(find.byType(QuizChoice))
          .singleWhere((choice) => choice.isCorrect);
      correct.onSelected!();
      correct.onSelected!();
      await _flush(tester);
      await tester.pump(const Duration(milliseconds: 100));
      await _flush(tester);

      expect(Storage.srsCard(word.korean)?.reviewCount, 1);
      expect(Storage.wrongCountOf(word.korean), 0);
      expect(
        platform.writes,
        containsPair(Storage.courseMasterySnapshotPreferenceKey, 1),
      );
      expect(find.byType(AppError), findsOneWidget);
      final retry = tester.widget<AppError>(find.byType(AppError)).onRetry!;
      platform.rejectKey = null;
      retry();
      retry();
      await _flush(tester);
      expect(find.byType(AppError), findsNothing);
      final snapshot = await CourseProgressService.shared.readForDisplay();
      final evidence = snapshot!.evidence
          .where((entry) => entry.contentId == word.id)
          .toList();
      expect(evidence, hasLength(conceptCount));
      expect(evidence.every((entry) => entry.isCorrect), isTrue);
      expect(
        evidence.every(
          (entry) =>
              entry.courseUnitId == null && entry.missionContentLinkId == null,
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'unknown committed course reply stays pending for reconciliation',
    (tester) async {
      await _pumpPack(
        tester,
        pack,
        courseContext: CoursePracticeContext.fromLink(link),
      );
      final t = await AppL10n.delegate.load(const Locale('en'));
      tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      tapDeckAction(tester, t.vocabPackGotIt);
      await tester.pump();
      await _flush(tester);

      platform
        ..rejectKey = Storage.courseMasterySnapshotPreferenceKey
        ..throwReply = true
        ..commitBeforeFailure = true
        ..failReloadAfterWrite = true;
      final correct = tester
          .widgetList<QuizChoice>(find.byType(QuizChoice))
          .singleWhere((choice) => choice.isCorrect);
      correct.onSelected!();
      await _flush(tester);

      expect(platform.writes[Storage.courseMasterySnapshotPreferenceKey], 1);
      expect(find.byType(AppError), findsOneWidget);
      final retry = tester.widget<AppError>(find.byType(AppError)).onRetry!;
      final writesBefore = Map<String, int>.of(platform.writes);
      retry();
      await _flush(tester);
      expect(platform.writes, writesBefore);
      expect(find.byType(AppError), findsOneWidget);
      platform
        ..rejectKey = null
        ..unavailable = false;
      retry();
      retry();
      await _flush(tester);
      expect(find.byType(AppError), findsNothing);
      final snapshot = await CourseProgressService.shared.readForDisplay();
      expect(
        snapshot!.evidence.where((entry) => entry.contentId == word.id),
        hasLength(conceptCount),
      );
    },
  );

  testWidgets(
    'route pop during linked answer SRS write prevents the course leg',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final twoWordPack = VocabPack(
        id: 'a1_course_evidence_pop',
        level: 'A1',
        words: <Vocab>[word, secondWord],
      );
      await _pumpPack(
        tester,
        twoWordPack,
        courseContext: CoursePracticeContext.fromLink(link),
        pushedRoute: true,
      );
      final t = await AppL10n.delegate.load(const Locale('en'));
      await _learnKnown(tester, t, count: 2);
      final srsWritesBefore = platform.writes['kl_srs_v1'] ?? 0;
      final release = Completer<void>();
      platform
        ..rejectKey = 'kl_srs_v1'
        ..releaseWrite = release
        ..successfulReply = true
        ..commitBeforeFailure = true;
      tester
          .widgetList<QuizChoice>(find.byType(QuizChoice))
          .firstWhere((choice) => !choice.isCorrect)
          .onSelected!();
      await _flush(tester);
      expect(find.byType(AppLoading), findsOneWidget);
      expect(platform.writes['kl_srs_v1'], srsWritesBefore + 1);
      expect(
        platform.writes[Storage.courseMasterySnapshotPreferenceKey],
        isNull,
      );

      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pump(const Duration(milliseconds: 400));
      tester
          .widgetList<SoriButton>(find.byType(SoriButton))
          .singleWhere((button) => button.label == t.homeActionConfirmLeave)
          .onTap!();
      await tester.pump(const Duration(milliseconds: 400));
      final retiringElement = tester.element(find.byType(VocabPackScreen));
      expect(retiringElement.mounted, isTrue);
      expect(ModalRoute.of(retiringElement)!.isActive, isFalse);
      release.complete();
      await _flush(tester);
      await tester.pump(const Duration(seconds: 2));
      await _flush(tester);

      expect(find.byType(VocabPackScreen), findsNothing);
      expect(find.text('pack-result'), findsNothing);
      expect(
        platform.writes[Storage.courseMasterySnapshotPreferenceKey],
        isNull,
      );
      expect(Storage.xp, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'two accepted recognition answers keep distinct course evidence and wrong semantics',
    (tester) async {
      final twoWordPack = VocabPack(
        id: 'a1_course_evidence_pair',
        level: 'A1',
        words: <Vocab>[word, secondWord],
      );
      await _pumpPack(tester, twoWordPack);
      final t = await AppL10n.delegate.load(const Locale('en'));
      await _learnKnown(tester, t, count: 2);

      final firstKorean = <String>[
        word.korean,
        secondWord.korean,
      ].singleWhere((text) => find.text(text).evaluate().isNotEmpty);
      final firstContentId = firstKorean == word.korean
          ? word.id
          : secondWord.id;
      final wrong = tester
          .widgetList<QuizChoice>(find.byType(QuizChoice))
          .firstWhere((choice) => !choice.isCorrect);
      wrong.onSelected!();
      await _flush(tester);
      await tester.pump(const Duration(milliseconds: 850));
      await _flush(tester);

      final correct = tester
          .widgetList<QuizChoice>(find.byType(QuizChoice))
          .singleWhere((choice) => choice.isCorrect);
      correct.onSelected!();
      await _flush(tester);

      final snapshot = await CourseProgressService.shared.readForDisplay();
      final evidence = snapshot!.evidence
          .where(
            (entry) =>
                entry.contentId == word.id || entry.contentId == secondWord.id,
          )
          .toList();
      final catalog = await CurriculumCatalog.load();
      final expectedCount = <Vocab>[word, secondWord]
          .map(
            (item) => catalog
                .linksForContent(CurriculumContentKind.vocab, item.id)
                .expand((candidate) => candidate.conceptIds)
                .toSet()
                .length,
          )
          .reduce((left, right) => left + right);
      expect(evidence, hasLength(expectedCount));
      expect(
        evidence.map((entry) => entry.id).toSet(),
        hasLength(expectedCount),
      );
      final wrongEvidence = evidence
          .where((entry) => entry.contentId == firstContentId)
          .toList();
      expect(wrongEvidence, isNotEmpty);
      expect(wrongEvidence.every((entry) => !entry.isCorrect), isTrue);
      expect(
        wrongEvidence.every(
          (entry) => entry.errorReason == MasteryErrorReason.vocabularyRecall,
        ),
        isTrue,
      );
      final otherKorean = firstKorean == word.korean
          ? secondWord.korean
          : word.korean;
      expect(Storage.srsCard(firstKorean)?.reviewCount, 2);
      expect(Storage.srsCard(otherKorean)?.reviewCount, 1);
      expect(Storage.wrongCountOf(firstKorean), 1);
    },
  );

  testWidgets('unlinked free-browse recognition is explicitly not applicable', (
    tester,
  ) async {
    final unlinked = _unlinkedWord();
    final freePack = VocabPack(
      id: 'a1_unlinked_free',
      level: 'A1',
      words: <Vocab>[unlinked],
    );
    await _pumpPack(tester, freePack);
    final t = await AppL10n.delegate.load(const Locale('en'));
    await _learnKnown(tester, t, count: 1);
    expect(platform.writes[Storage.courseMasterySnapshotPreferenceKey], isNull);
    tester
        .widgetList<QuizChoice>(find.byType(QuizChoice))
        .singleWhere((choice) => choice.isCorrect)
        .onSelected!();
    await _flush(tester);
    expect(find.byType(AppError), findsNothing);
    expect(platform.writes[Storage.courseMasterySnapshotPreferenceKey], isNull);
  });

  testWidgets('course-routed unlinked recognition cannot silently succeed', (
    tester,
  ) async {
    final unlinked = _unlinkedWord();
    final invalidPack = VocabPack(
      id: 'a1_unlinked_course',
      level: 'A1',
      words: <Vocab>[unlinked],
    );
    final invalidContext = CoursePracticeContext(
      courseUnitId: link.courseUnitId,
      contentKind: CurriculumContentKind.vocab,
      initialContentId: unlinked.id,
      contentLinkId: 'missing-vocab-link',
    );
    await _pumpPack(tester, invalidPack, courseContext: invalidContext);
    expect(find.byType(AppError), findsOneWidget);
    expect(find.byType(FlipCard), findsNothing);
    expect(find.byType(QuizChoice), findsNothing);
    expect(platform.writes[Storage.courseMasterySnapshotPreferenceKey], isNull);
  });

  for (final invalidRoute in <String>['content link', 'course unit']) {
    testWidgets(
      'linked content rejects a mismatched $invalidRoute at admission',
      (tester) async {
        final invalidContext = CoursePracticeContext(
          courseUnitId: invalidRoute == 'course unit'
              ? '${link.courseUnitId}-mismatch'
              : link.courseUnitId,
          contentKind: CurriculumContentKind.vocab,
          initialContentId: word.id,
          contentLinkId: invalidRoute == 'content link'
              ? 'missing-linked-vocab-edge'
              : link.id,
        );

        await _pumpPack(tester, pack, courseContext: invalidContext);

        expect(find.byType(AppError), findsOneWidget);
        expect(find.byType(FlipCard), findsNothing);
        expect(find.byType(QuizChoice), findsNothing);
        expect(find.text('pack-result'), findsNothing);
        expect(Storage.srsCard(word.korean), isNull);
        expect(Storage.wrongCountOf(word.korean), 0);
        expect(Storage.xp, 0);
        expect(
          platform.writes[Storage.courseMasterySnapshotPreferenceKey],
          isNull,
        );
      },
    );
  }

  for (final retirement in <String>['leave', 'reset']) {
    testWidgets('pending assessment course write stops on $retirement', (
      tester,
    ) async {
      await _pumpPack(
        tester,
        pack,
        courseContext: CoursePracticeContext.fromLink(link),
      );
      final t = await AppL10n.delegate.load(const Locale('en'));
      await _learnKnown(tester, t, count: 1);
      final release = Completer<void>();
      platform
        ..rejectKey = Storage.courseMasterySnapshotPreferenceKey
        ..releaseWrite = release
        ..successfulReply = true
        ..commitBeforeFailure = true;
      tester
          .widgetList<QuizChoice>(find.byType(QuizChoice))
          .singleWhere((choice) => choice.isCorrect)
          .onSelected!();
      await _flush(tester);
      expect(find.byType(AppLoading), findsOneWidget);
      expect(platform.writes[Storage.courseMasterySnapshotPreferenceKey], 1);

      Future<void>? reset;
      if (retirement == 'leave') {
        tester.widget<SoriStudyFrame>(find.byType(SoriStudyFrame)).onLeave!();
      } else {
        reset = Storage.resetAllStrict();
      }
      release.complete();
      await _flush(tester);
      await reset;
      await tester.pump(const Duration(seconds: 2));
      await _flush(tester);

      expect(find.text('pack-result'), findsNothing);
      expect(Storage.xp, 0);
      if (retirement == 'reset') {
        expect(Storage.courseMasterySnapshotRawJson, isEmpty);
      }
    });
  }

  test(
    'production finish operation rejects an unconfirmed native course write',
    () async {
      platform.rejectKey = Storage.courseMasterySnapshotPreferenceKey;
      final request = VocabPackFinishRequest(
        pack: pack,
        siblingPacks: <VocabPack>[pack],
        bossAccuracy: 1,
        bossCorrect: 1,
        bossTotal: 1,
        quizCorrect: 1,
        quizTotal: 1,
        courseContext: CoursePracticeContext.fromLink(link),
        completionStampMotif: 'test_stamp',
      );

      await expectLater(
        DefaultVocabPackFinishOperations().recordCourseAttempt(request),
        throwsA(anything),
      );
      expect(platform.writes[Storage.courseMasterySnapshotPreferenceKey], 1);
    },
  );

  for (final committed in <bool>[false, true]) {
    test(
      'finish unknown committed=$committed retries one immutable course attempt',
      () async {
        final operations = DefaultVocabPackFinishOperations();
        final request = VocabPackFinishRequest(
          pack: pack,
          siblingPacks: <VocabPack>[pack],
          bossAccuracy: .75,
          bossCorrect: 1,
          bossTotal: 1,
          quizCorrect: 2,
          quizTotal: 3,
          courseContext: CoursePracticeContext.fromLink(link),
          completionStampMotif: 'test_stamp',
        );
        expect(request.courseScore, .75);
        platform
          ..rejectKey = Storage.courseMasterySnapshotPreferenceKey
          ..throwReply = true
          ..commitBeforeFailure = committed
          ..failReloadAfterWrite = true;

        await expectLater(
          operations.recordCourseAttempt(request),
          throwsA(anything),
        );
        final writesBefore = Map<String, int>.of(platform.writes);
        await expectLater(
          operations.recordCourseAttempt(request),
          throwsA(anything),
        );
        expect(platform.writes, writesBefore);

        platform
          ..rejectKey = null
          ..unavailable = false;
        await operations.recordCourseAttempt(request);
        final snapshot = await CourseProgressService.shared.readForDisplay();
        final evidence = snapshot!.evidence
            .where((entry) => entry.missionContentLinkId == link.id)
            .toList();
        expect(evidence, hasLength(link.conceptIds.length));
        expect(evidence.every((entry) => entry.isCorrect), isTrue);
        expect(evidence.every((entry) => entry.score == .75), isTrue);
        final confirmedWrites = Map<String, int>.of(platform.writes);
        await operations.recordCourseAttempt(request);
        expect(platform.writes, confirmedWrites);
      },
    );
  }

  test(
    'finish keeps weighted score, mission context, and .70 threshold',
    () async {
      final request = VocabPackFinishRequest(
        pack: pack,
        siblingPacks: <VocabPack>[pack],
        bossAccuracy: .5,
        bossCorrect: 0,
        bossTotal: 1,
        quizCorrect: 1,
        quizTotal: 1,
        courseContext: CoursePracticeContext.fromLink(link),
        completionStampMotif: 'test_stamp',
      );
      expect(request.courseScore, .5);
      await DefaultVocabPackFinishOperations().recordCourseAttempt(request);
      final snapshot = await CourseProgressService.shared.readForDisplay();
      final evidence = snapshot!.evidence
          .where((entry) => entry.missionContentLinkId == link.id)
          .toList();
      expect(evidence, hasLength(link.conceptIds.length));
      expect(evidence.every((entry) => !entry.isCorrect), isTrue);
      expect(evidence.every((entry) => entry.score == .5), isTrue);
      expect(
        evidence.every(
          (entry) =>
              entry.courseUnitId == link.courseUnitId &&
              entry.errorReason == MasteryErrorReason.vocabularyRecall,
        ),
        isTrue,
      );
    },
  );

  test('finish without course context is an explicit no-op', () async {
    platform.rejectKey = Storage.courseMasterySnapshotPreferenceKey;
    final request = VocabPackFinishRequest(
      pack: pack,
      siblingPacks: <VocabPack>[pack],
      bossAccuracy: 1,
      bossCorrect: 1,
      bossTotal: 1,
      quizCorrect: 1,
      quizTotal: 1,
      completionStampMotif: 'test_stamp',
    );
    await DefaultVocabPackFinishOperations().recordCourseAttempt(request);
    expect(platform.writes[Storage.courseMasterySnapshotPreferenceKey], isNull);
  });
}

Future<void> _pumpPack(
  WidgetTester tester,
  VocabPack pack, {
  CoursePracticeContext? courseContext,
  bool pushedRoute = false,
}) async {
  CourseProgressService.shared.resetForTesting();
  final navigatorKey = GlobalKey<NavigatorState>();
  final screen = VocabPackScreen(
    packId: pack.id,
    courseContext: courseContext,
    packLoader: (_) async => pack,
    siblingPacksLoader: (_) async => <VocabPack>[pack],
  );
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigatorKey,
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      routes: <String, WidgetBuilder>{
        '/vocab/result': (_) => const Scaffold(body: Text('pack-result')),
      },
      home: pushedRoute ? const SizedBox() : screen,
    ),
  );
  if (pushedRoute) {
    unawaited(
      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => screen),
      ),
    );
  }
  await _flush(tester);
}

Future<void> _flush(WidgetTester tester) async {
  for (var index = 0; index < 30; index++) {
    await tester.pump();
  }
}

Future<void> _learnKnown(
  WidgetTester tester,
  AppL10n t, {
  required int count,
}) async {
  for (var index = 0; index < count; index++) {
    tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    tapDeckAction(tester, t.vocabPackGotIt);
    await tester.pump();
    await _flush(tester);
  }
}

Vocab _unlinkedWord() => const Vocab(
  id: 'vocab-unlinked-task-41',
  korean: '미연결어',
  romanization: 'miyeongyeoreo',
  german: 'nicht verknupft',
  english: 'unlinked',
  level: 'A1',
  posDe: 'Nomen',
  exampleKorean: '',
  exampleGerman: '',
  topic: 'test',
  packId: 'a1_unlinked',
  packOrder: 1,
);
