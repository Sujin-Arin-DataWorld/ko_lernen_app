import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_practice_context.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/grammar.dart';
import 'package:ko_lernen_app/models/smalltalk.dart';
import 'package:ko_lernen_app/screens/grammar_screen.dart';
import 'package:ko_lernen_app/screens/smalltalk_screen.dart';
import 'package:ko_lernen_app/services/course_checkpoint_questions.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/services/smalltalk_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';
import 'package:ko_lernen_app/widgets/sori/ko_wrap.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/chip.dart';
import 'package:ko_lernen_app/widgets/sori/content_feed.dart';
import 'package:ko_lernen_app/widgets/sori/level_filter_bar.dart';
import 'package:ko_lernen_app/widgets/sori/sheet.dart';

import 'support/reward_preferences_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final originalPreferences = SharedPreferencesStorePlatform.instance;
  late RewardPreferencesPlatform platform;

  setUp(() async {
    Storage.resetForTesting();
    Storage.resetCourseMasteryForTesting();
    CourseProgressService.shared.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    platform = RewardPreferencesPlatform();
    SharedPreferencesStorePlatform.instance = platform;
    await Storage.init();
    await Storage.setTutSeen('grammar');
    await Storage.setTutSeen('smalltalk');
    await Storage.setTutSeen('soriDeck');
    DataLoader.reset();
    SmalltalkLoader.reset();
    CurriculumCatalog.reset();
  });

  tearDown(() {
    Storage.resetForTesting();
    Storage.resetCourseMasteryForTesting();
    CourseProgressService.shared.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = originalPreferences;
  });

  testWidgets(
    'grammar native rejection retains the first answer across a different callback',
    (tester) async {
      final catalog = (await tester.runAsync(CurriculumCatalog.load))!;
      CourseProgressService.shared.resetForTesting();
      const targetId = 'grammar_b2_counterfactual_past';
      final link = catalog.contentLinks.singleWhere(
        (item) =>
            item.contentKind == CurriculumContentKind.grammar &&
            item.contentId == targetId &&
            item.courseUnitId == 'b2_04_complaint_resolution' &&
            item.role == ContentLinkRole.assess,
      );
      final context = CoursePracticeContext.fromLink(link);
      await _activateUnit(tester, catalog, link.courseUnitId);
      platform.writes.clear();

      final scopedIds = courseContentIdsForContext(
        catalog: catalog,
        courseContext: context,
        kind: CurriculumContentKind.grammar,
      )!;
      final scopedGrammar = (await DataLoader.loadGrammar())
          .where((grammar) => scopedIds.contains(grammar.id))
          .toList(growable: false);
      final target = scopedGrammar.singleWhere(
        (grammar) => grammar.id == targetId,
      );
      await Storage.setGrammarLastIdx(
        scopedGrammar.indexWhere((grammar) => grammar.id == targetId),
      );
      await tester.pumpWidget(_wrap(GrammarScreen(courseContext: context)));
      await _settle(tester);
      await tester.tap(find.byType(FlipCard));
      await _settle(tester);

      final choices = tester
          .widgetList<SoriButton>(
            find.descendant(
              of: find.byType(SoriSheetShell),
              matching: find.byType(SoriButton),
            ),
          )
          .where((button) => button.onTap != null)
          .toList(growable: false);
      final correct = choices.singleWhere(
        (button) => button.label == target.pattern,
      );
      final wrong = choices.firstWhere(
        (button) => button.label != target.pattern,
      );
      platform
        ..rejectKey = Storage.courseMasterySnapshotPreferenceKey
        ..successfulReply = false;

      wrong.onTap!();
      await _flush(tester);
      expect(
        platform.writes[Storage.courseMasterySnapshotPreferenceKey],
        1,
        reason: 'The native course snapshot setter must be exercised.',
      );

      platform.rejectKey = null;
      correct.onTap!();
      await _flush(tester);
      expect(platform.writes[Storage.courseMasterySnapshotPreferenceKey], 1);
      await tester.tap(find.byKey(const Key('grammar-checkpoint-retry')));
      await _flush(tester);

      final snapshot = await CourseProgressService.shared.readForDisplay();
      final evidence = snapshot!.evidence
          .where((entry) => entry.contentId == targetId)
          .toList(growable: false);
      expect(evidence, hasLength(1));
      expect(evidence.single.isCorrect, isFalse);
      expect(evidence.single.errorReason, MasteryErrorReason.unknown);
      expect(evidence.single.missionContentLinkId, link.id);
      expect(evidence.single.courseUnitId, link.courseUnitId);
      final completedWriteCount =
          platform.writes[Storage.courseMasterySnapshotPreferenceKey];
      correct.onTap!();
      await _flush(tester);
      expect(
        platform.writes[Storage.courseMasterySnapshotPreferenceKey],
        completedWriteCount,
      );
      await _dispose(tester);
    },
  );

  testWidgets(
    'smalltalk native rejection retains the first relationship across a different callback',
    (tester) async {
      final catalog = (await tester.runAsync(CurriculumCatalog.load))!;
      CourseProgressService.shared.resetForTesting();
      final fixture = await _activeSmalltalkFixture(tester, catalog);
      final link = fixture.link;
      final phrase = fixture.phrase;
      platform.writes.clear();
      await tester.pumpWidget(
        _wrap(
          SmalltalkScreen(courseContext: CoursePracticeContext.fromLink(link)),
        ),
      );
      await _settle(tester);
      await tester.tap(find.text('Quick check').first);
      await tester.pump();

      expect(
        tester
            .widget<SoriPhraseWrap>(find.byKey(const Key('smalltalk-ko')))
            .text,
        phrase.ko,
      );
      final relationshipButtons = tester
          .widgetList<SoriButton>(find.byType(SoriButton))
          .where(
            (button) => SmalltalkRelationshipContext.values.any(
              (context) => context.labelFor('en') == button.label,
            ),
          )
          .toList(growable: false);
      final correct = relationshipButtons.singleWhere(
        (button) => button.label == phrase.relationshipContext.labelFor('en'),
      );
      final wrong = relationshipButtons.firstWhere(
        (button) => button.label != phrase.relationshipContext.labelFor('en'),
      );
      platform
        ..rejectKey = Storage.courseMasterySnapshotPreferenceKey
        ..successfulReply = false;

      wrong.onTap!();
      await _flush(tester);
      expect(
        platform.writes[Storage.courseMasterySnapshotPreferenceKey],
        1,
        reason: 'The native course snapshot setter must be exercised.',
      );

      platform.rejectKey = null;
      correct.onTap!();
      await _flush(tester);
      expect(platform.writes[Storage.courseMasterySnapshotPreferenceKey], 1);
      await tester.ensureVisible(
        find.byKey(const Key('smalltalk-checkpoint-retry')),
      );
      await tester.tap(find.byKey(const Key('smalltalk-checkpoint-retry')));
      await _flush(tester);

      final snapshot = await CourseProgressService.shared.readForDisplay();
      final evidence = snapshot!.evidence
          .where((entry) => entry.contentId == phrase.id)
          .toList(growable: false);
      expect(evidence, hasLength(1));
      expect(evidence.single.isCorrect, isFalse);
      expect(evidence.single.errorReason, MasteryErrorReason.speechStyle);
      expect(evidence.single.missionContentLinkId, isNotNull);
      expect(evidence.single.courseUnitId, link.courseUnitId);
      final completedWriteCount =
          platform.writes[Storage.courseMasterySnapshotPreferenceKey];
      correct.onTap!();
      await _flush(tester);
      expect(
        platform.writes[Storage.courseMasterySnapshotPreferenceKey],
        completedWriteCount,
      );
      await _dispose(tester);
    },
  );

  testWidgets(
    'grammar pending save refreshes the reopened sheet and retries the same answer',
    (tester) async {
      final catalog = (await tester.runAsync(CurriculumCatalog.load))!;
      CourseProgressService.shared.resetForTesting();
      final fixture = await _openGrammarFixture(tester, catalog);
      final wrong = fixture.choices.firstWhere(
        (button) => button.label != fixture.target.pattern,
      );
      final writeEntered = Completer<void>();
      final releaseWrite = Completer<void>();
      platform.writes.clear();
      platform
        ..rejectKey = Storage.courseMasterySnapshotPreferenceKey
        ..successfulReply = false
        ..writeEntered = writeEntered
        ..releaseWrite = releaseWrite;

      wrong.onTap!();
      await tester.pump();
      await writeEntered.future;
      expect(
        find.byKey(const Key('grammar-checkpoint-saving')),
        findsOneWidget,
      );

      Navigator.of(tester.element(find.byType(SoriSheetShell))).pop();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byType(FlipCard));
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.byKey(const Key('grammar-checkpoint-saving')),
        findsOneWidget,
      );

      releaseWrite.complete();
      await _flush(tester);
      expect(find.byKey(const Key('grammar-checkpoint-saving')), findsNothing);
      expect(
        find.byKey(const Key('grammar-checkpoint-save-error')),
        findsOneWidget,
      );

      platform
        ..rejectKey = null
        ..releaseWrite = null;
      await tester.tap(find.byKey(const Key('grammar-checkpoint-retry')));
      await _flush(tester);
      final evidence = (await CourseProgressService.shared.readForDisplay())!
          .evidence
          .where((entry) => entry.contentId == fixture.target.id)
          .toList(growable: false);
      expect(evidence, hasLength(1));
      expect(evidence.single.isCorrect, isFalse);
      expect(evidence.single.missionContentLinkId, fixture.targetLink.id);
      expect(platform.writes[Storage.courseMasterySnapshotPreferenceKey], 2);
      await _dispose(tester);
    },
  );

  testWidgets(
    'grammar reset retires pending injected work and blocks stale callbacks',
    (tester) async {
      final catalog = (await tester.runAsync(CurriculumCatalog.load))!;
      CourseProgressService.shared.resetForTesting();
      final links = _grammarAssessmentPair(catalog);
      final recorderEntered = Completer<void>();
      final releaseRecorder = Completer<void>();
      var recorderCalls = 0;
      final fixture = await _openGrammarFixture(
        tester,
        catalog,
        sourceLink: links.source,
        targetLink: links.target,
        checkpointRecorder: (attempt) async {
          recorderCalls++;
          recorderEntered.complete();
          await releaseRecorder.future;
        },
      );
      final correct = fixture.choices.singleWhere(
        (button) => button.label == fixture.target.pattern,
      );
      final wrong = fixture.choices.firstWhere(
        (button) => button.label != fixture.target.pattern,
      );

      wrong.onTap!();
      await tester.pump();
      await recorderEntered.future;
      LocalDataLifetime.invalidate();
      releaseRecorder.complete();
      await _flush(tester);

      expect(recorderCalls, 1);
      expect(find.byKey(const Key('grammar-checkpoint-saving')), findsNothing);
      expect(
        find.byKey(const Key('grammar-checkpoint-save-error')),
        findsOneWidget,
      );
      correct.onTap!();
      await _flush(tester);
      expect(recorderCalls, 1);
      final writeCountAfterActivation =
          platform.writes[Storage.courseMasterySnapshotPreferenceKey];

      await tester.ensureVisible(
        find.byKey(const Key('grammar-checkpoint-retry')),
      );
      await tester.tap(find.byKey(const Key('grammar-checkpoint-retry')));
      await _settle(tester);
      expect(find.byType(SoriSheetShell), findsNothing);
      await tester.tap(find.byType(FlipCard));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(SoriSheetShell), findsNothing);
      expect(recorderCalls, 1);
      expect(
        platform.writes[Storage.courseMasterySnapshotPreferenceKey],
        writeCountAfterActivation,
      );
      await _dispose(tester);
    },
  );

  testWidgets(
    'smalltalk reset expires the live card attempt and leaves a usable exit',
    (tester) async {
      final catalog = (await tester.runAsync(CurriculumCatalog.load))!;
      CourseProgressService.shared.resetForTesting();
      final fixture = await _activeSmalltalkFixture(tester, catalog);
      await tester.pumpWidget(
        _wrap(
          SmalltalkScreen(
            courseContext: CoursePracticeContext.fromLink(fixture.link),
          ),
        ),
      );
      await _settle(tester);
      await tester.tap(find.text('Quick check').first);
      await tester.pump();
      final choices = _relationshipButtons(tester);
      final correct = choices.singleWhere(
        (button) =>
            button.label == fixture.phrase.relationshipContext.labelFor('en'),
      );
      final wrong = choices.firstWhere(
        (button) =>
            button.label != fixture.phrase.relationshipContext.labelFor('en'),
      );
      final writeEntered = Completer<void>();
      final releaseWrite = Completer<void>();
      platform.writes.clear();
      platform
        ..rejectKey = Storage.courseMasterySnapshotPreferenceKey
        ..successfulReply = false
        ..writeEntered = writeEntered
        ..releaseWrite = releaseWrite;

      wrong.onTap!();
      await tester.pump();
      await writeEntered.future;
      LocalDataLifetime.invalidate();
      releaseWrite.complete();
      await _flush(tester);

      expect(
        find.byKey(const Key('smalltalk-checkpoint-saving')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('smalltalk-checkpoint-save-error')),
        findsOneWidget,
      );
      correct.onTap!();
      await _flush(tester);
      expect(platform.writes[Storage.courseMasterySnapshotPreferenceKey], 1);
      await tester.ensureVisible(
        find.byKey(const Key('smalltalk-checkpoint-retry')),
      );
      await tester.tap(find.byKey(const Key('smalltalk-checkpoint-retry')));
      await tester.pump();
      expect(
        find.byKey(const Key('smalltalk-checkpoint-save-error')),
        findsNothing,
      );
      expect(
        tester
            .widget<InkWell>(
              find.byKey(const Key('smalltalk-category-selector')),
            )
            .onTap,
        isNull,
      );
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Quick check'))
            .onPressed,
        isNull,
      );
      expect(
        tester.widget<SoriContentFeed>(find.byType(SoriContentFeed)).onNext,
        isNull,
      );
      await _dispose(tester);
    },
  );

  testWidgets(
    'smalltalk route pop retires the card and stale callbacks cannot write',
    (tester) async {
      final catalog = (await tester.runAsync(CurriculumCatalog.load))!;
      CourseProgressService.shared.resetForTesting();
      final fixture = await _activeSmalltalkFixture(tester, catalog);
      await tester.pumpWidget(
        _wrapLauncher(
          SmalltalkScreen(
            courseContext: CoursePracticeContext.fromLink(fixture.link),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open-evidence-route')));
      await _settle(tester);
      await tester.tap(find.text('Quick check').first);
      await tester.pump();
      final choices = _relationshipButtons(tester);
      final wrong = choices.firstWhere(
        (button) =>
            button.label != fixture.phrase.relationshipContext.labelFor('en'),
      );
      final writeEntered = Completer<void>();
      final releaseWrite = Completer<void>();
      platform.writes.clear();
      platform
        ..rejectKey = Storage.courseMasterySnapshotPreferenceKey
        ..successfulReply = false
        ..writeEntered = writeEntered
        ..releaseWrite = releaseWrite;

      wrong.onTap!();
      await tester.pump();
      await writeEntered.future;
      Navigator.of(tester.element(find.byType(SmalltalkScreen))).pop();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const Key('open-evidence-route')), findsOneWidget);
      releaseWrite.complete();
      await _flush(tester);
      wrong.onTap!();
      await _flush(tester);
      expect(platform.writes[Storage.courseMasterySnapshotPreferenceKey], 1);
      final snapshot = await CourseProgressService.shared.readForDisplay();
      expect(
        snapshot!.evidence.where(
          (entry) => entry.contentId == fixture.phrase.id,
        ),
        isEmpty,
      );
      await _dispose(tester);
    },
  );

  testWidgets(
    'smalltalk synchronous next transition rejects the old answer callback',
    (tester) async {
      final catalog = (await tester.runAsync(CurriculumCatalog.load))!;
      CourseProgressService.shared.resetForTesting();
      final fixture = await _activeSmalltalkFixture(tester, catalog);
      await tester.pumpWidget(
        _wrap(
          SmalltalkScreen(
            courseContext: CoursePracticeContext.fromLink(fixture.link),
          ),
        ),
      );
      await _settle(tester);
      await tester.tap(find.text('Quick check').first);
      await tester.pump();
      final oldAnswer = _relationshipButtons(tester).first;
      final next = tester
          .widget<SoriContentFeed>(find.byType(SoriContentFeed))
          .onNext!;
      platform.writes.clear();

      next();
      oldAnswer.onTap!();
      await _flush(tester);

      expect(
        platform.writes[Storage.courseMasterySnapshotPreferenceKey],
        isNull,
        reason: 'A retired source card must not reach the native setter.',
      );
      final snapshot = await CourseProgressService.shared.readForDisplay();
      expect(
        snapshot!.evidence.where(
          (entry) => entry.contentId == fixture.phrase.id,
        ),
        isEmpty,
      );
      expect(
        tester
            .widget<InkWell>(
              find.byKey(const Key('smalltalk-category-selector')),
            )
            .onTap,
        isNotNull,
        reason: 'The retired card must not leave the new feed locked.',
      );
      await _dispose(tester);
    },
  );

  testWidgets(
    'smalltalk synchronous previous transition rejects the old answer callback',
    (tester) async {
      final catalog = (await tester.runAsync(CurriculumCatalog.load))!;
      CourseProgressService.shared.resetForTesting();
      final pair = await _activeSmalltalkPair(tester, catalog);
      await tester.pumpWidget(
        _wrap(
          SmalltalkScreen(
            courseContext: CoursePracticeContext.fromLink(pair.sourceLink),
          ),
        ),
      );
      await _settle(tester);
      for (var i = 0; i < pair.navigationCount; i++) {
        tester.widget<SoriContentFeed>(find.byType(SoriContentFeed)).onNext!();
        await tester.pump();
      }
      await tester.tap(find.text('Quick check').first);
      await tester.pump();
      final oldAnswer = _relationshipButtons(tester).first;
      final previous = tester
          .widget<SoriContentFeed>(find.byType(SoriContentFeed))
          .onPrevious!;
      platform.writes.clear();

      previous();
      oldAnswer.onTap!();
      await _flush(tester);

      expect(platform.writes[Storage.courseMasterySnapshotPreferenceKey], null);
      expect(
        tester
            .widget<InkWell>(
              find.byKey(const Key('smalltalk-category-selector')),
            )
            .onTap,
        isNotNull,
      );
      await _dispose(tester);
    },
  );

  testWidgets(
    'smalltalk synchronous level filter rejects the old answer callback',
    (tester) async {
      final catalog = (await tester.runAsync(CurriculumCatalog.load))!;
      CourseProgressService.shared.resetForTesting();
      final fixture = await _activeSmalltalkFixture(tester, catalog);
      await tester.pumpWidget(
        _wrap(
          SmalltalkScreen(
            courseContext: CoursePracticeContext.fromLink(fixture.link),
          ),
        ),
      );
      await _settle(tester);
      await tester.tap(find.text('Quick check').first);
      await tester.pump();
      final oldAnswer = _relationshipButtons(tester).first;
      final changeLevel = tester
          .widget<SoriLevelFilterBar>(find.byType(SoriLevelFilterBar))
          .onChanged;
      platform.writes.clear();

      changeLevel('a2');
      oldAnswer.onTap!();
      await _flush(tester);

      expect(platform.writes[Storage.courseMasterySnapshotPreferenceKey], null);
      expect(
        tester
            .widget<InkWell>(
              find.byKey(const Key('smalltalk-category-selector')),
            )
            .onTap,
        isNotNull,
      );
      await tester.tap(find.text('Quick check').first);
      await tester.pump();
      expect(
        _relationshipButtons(tester).where((button) => button.onTap != null),
        isNotEmpty,
        reason: 'The current card must remain usable after a level transition.',
      );
      await _dispose(tester);
    },
  );

  testWidgets(
    'smalltalk synchronous category filter rejects the old answer callback',
    (tester) async {
      final catalog = (await tester.runAsync(CurriculumCatalog.load))!;
      CourseProgressService.shared.resetForTesting();
      final fixture = await _activeSmalltalkFixture(tester, catalog);
      await tester.pumpWidget(
        _wrap(
          SmalltalkScreen(
            courseContext: CoursePracticeContext.fromLink(fixture.link),
          ),
        ),
      );
      await _settle(tester);
      await tester.tap(find.text('Quick check').first);
      await tester.pump();
      final oldAnswer = _relationshipButtons(tester).first;
      tester
          .widget<InkWell>(find.byKey(const Key('smalltalk-category-selector')))
          .onTap!();
      await tester.pump();
      final selectCategory = tester
          .widgetList<SoriChip>(find.byType(SoriChip))
          .firstWhere((chip) => !chip.selected && chip.onTap != null)
          .onTap!;
      platform.writes.clear();

      selectCategory();
      oldAnswer.onTap!();
      await _flush(tester);

      expect(platform.writes[Storage.courseMasterySnapshotPreferenceKey], null);
      expect(
        tester
            .widget<InkWell>(
              find.byKey(const Key('smalltalk-category-selector')),
            )
            .onTap,
        isNotNull,
      );
      await _dispose(tester);
    },
  );

  testWidgets(
    'grammar parent route pop retires pending sheet work and stale callbacks',
    (tester) async {
      final catalog = (await tester.runAsync(CurriculumCatalog.load))!;
      CourseProgressService.shared.resetForTesting();
      final fixture = await _openGrammarFixture(
        tester,
        catalog,
        routeLauncher: true,
      );
      final wrong = fixture.choices.firstWhere(
        (button) => button.label != fixture.target.pattern,
      );
      final writeEntered = Completer<void>();
      final releaseWrite = Completer<void>();
      platform.writes.clear();
      platform
        ..rejectKey = Storage.courseMasterySnapshotPreferenceKey
        ..successfulReply = false
        ..writeEntered = writeEntered
        ..releaseWrite = releaseWrite;

      wrong.onTap!();
      await tester.pump();
      await writeEntered.future;
      Navigator.of(tester.element(find.byType(SoriSheetShell))).pop();
      await tester.pump(const Duration(milliseconds: 400));
      Navigator.of(tester.element(find.byType(GrammarScreen))).pop();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const Key('open-evidence-route')), findsOneWidget);

      releaseWrite.complete();
      await _flush(tester);
      wrong.onTap!();
      await _flush(tester);
      expect(platform.writes[Storage.courseMasterySnapshotPreferenceKey], 1);
      final snapshot = await CourseProgressService.shared.readForDisplay();
      expect(
        snapshot!.evidence.where(
          (entry) => entry.contentId == fixture.target.id,
        ),
        isEmpty,
      );
      await _dispose(tester);
    },
  );

  testWidgets(
    'grammar second offered target uses its own exact assessment link',
    (tester) async {
      final catalog = (await tester.runAsync(CurriculumCatalog.load))!;
      CourseProgressService.shared.resetForTesting();
      final links = _grammarAssessmentPair(catalog);
      final fixture = await _openGrammarFixture(
        tester,
        catalog,
        sourceLink: links.source,
        targetLink: links.target,
      );
      final correct = fixture.choices.singleWhere(
        (button) => button.label == fixture.target.pattern,
      );
      correct.onTap!();
      await _flush(tester);
      final evidence = (await CourseProgressService.shared.readForDisplay())!
          .evidence
          .singleWhere((entry) => entry.contentId == fixture.target.id);
      expect(evidence.missionContentLinkId, links.target.id);
      expect(evidence.missionContentLinkId, isNot(links.source.id));
      await _dispose(tester);
    },
  );

  testWidgets(
    'smalltalk second offered phrase uses its own exact assessment link',
    (tester) async {
      final catalog = (await tester.runAsync(CurriculumCatalog.load))!;
      CourseProgressService.shared.resetForTesting();
      final pair = await _activeSmalltalkPair(tester, catalog);
      await tester.pumpWidget(
        _wrap(
          SmalltalkScreen(
            courseContext: CoursePracticeContext.fromLink(pair.sourceLink),
          ),
        ),
      );
      await _settle(tester);
      for (var i = 0; i < pair.navigationCount; i++) {
        tester.widget<SoriContentFeed>(find.byType(SoriContentFeed)).onNext!();
        await tester.pump();
      }
      expect(
        tester
            .widget<SoriPhraseWrap>(find.byKey(const Key('smalltalk-ko')))
            .text,
        pair.targetPhrase.ko,
      );
      await tester.tap(find.text('Quick check').first);
      await tester.pump();
      final correct = _relationshipButtons(tester).singleWhere(
        (button) =>
            button.label ==
            pair.targetPhrase.relationshipContext.labelFor('en'),
      );
      correct.onTap!();
      await _flush(tester);
      final evidence = (await CourseProgressService.shared.readForDisplay())!
          .evidence
          .singleWhere((entry) => entry.contentId == pair.targetPhrase.id);
      expect(evidence.missionContentLinkId, pair.targetLink.id);
      expect(evidence.missionContentLinkId, isNot(pair.sourceLink.id));
      await _dispose(tester);
    },
  );

  testWidgets(
    'invalid supplied grammar and smalltalk routes expose no assessment input',
    (tester) async {
      final catalog = (await tester.runAsync(CurriculumCatalog.load))!;
      CourseProgressService.shared.resetForTesting();
      final grammarLinks = _grammarAssessmentPair(catalog);
      await _activateUnit(tester, catalog, grammarLinks.source.courseUnitId);
      final invalidGrammarContexts = <CoursePracticeContext>[
        CoursePracticeContext(
          courseUnitId: grammarLinks.source.courseUnitId,
          contentKind: grammarLinks.source.contentKind,
          initialContentId: 'wrong_initial_id',
          contentLinkId: grammarLinks.source.id,
        ),
        CoursePracticeContext(
          courseUnitId: grammarLinks.source.courseUnitId,
          contentKind: CurriculumContentKind.smalltalk,
          initialContentId: grammarLinks.source.contentId,
          contentLinkId: grammarLinks.source.id,
        ),
        CoursePracticeContext(
          courseUnitId: grammarLinks.source.courseUnitId,
          contentKind: grammarLinks.source.contentKind,
          initialContentId: grammarLinks.source.contentId,
          contentLinkId: 'wrong_link_id',
        ),
        CoursePracticeContext(
          courseUnitId: 'wrong_unit_id',
          contentKind: grammarLinks.source.contentKind,
          initialContentId: grammarLinks.source.contentId,
          contentLinkId: grammarLinks.source.id,
        ),
      ];
      for (final context in invalidGrammarContexts) {
        await tester.pumpWidget(_wrap(GrammarScreen(courseContext: context)));
        await _settle(tester);
        expect(find.text('Quick check'), findsNothing);
        await _dispose(tester);
      }

      CourseProgressService.shared.resetForTesting();
      final smalltalk = await _activeSmalltalkFixture(tester, catalog);
      final invalidSmalltalk = CoursePracticeContext(
        courseUnitId: smalltalk.link.courseUnitId,
        contentKind: smalltalk.link.contentKind,
        initialContentId: 'wrong_initial_id',
        contentLinkId: smalltalk.link.id,
      );
      await tester.pumpWidget(
        _wrap(SmalltalkScreen(courseContext: invalidSmalltalk)),
      );
      await _settle(tester);
      expect(find.text('Quick check'), findsNothing);
      await _dispose(tester);
    },
  );

  testWidgets(
    'grammar same-State invalid route replacement cannot use a cached assessment',
    (tester) async {
      final catalog = (await tester.runAsync(CurriculumCatalog.load))!;
      CourseProgressService.shared.resetForTesting();
      final link = _grammarAssessmentPair(catalog).source;
      await _activateUnit(tester, catalog, link.courseUnitId);
      final validContext = CoursePracticeContext.fromLink(link);
      final invalidContext = CoursePracticeContext(
        courseUnitId: link.courseUnitId,
        contentKind: link.contentKind,
        initialContentId: 'wrong_initial_id',
        contentLinkId: link.id,
      );
      final screenKey = GlobalKey();
      await tester.pumpWidget(
        _wrap(GrammarScreen(key: screenKey, courseContext: validContext)),
      );
      await _settle(tester);

      await tester.pumpWidget(
        _wrap(GrammarScreen(key: screenKey, courseContext: invalidContext)),
      );
      await tester.pump();
      await tester.tap(find.byType(FlipCard));
      await _settle(tester);
      platform.writes.clear();

      final sheet = find.byType(SoriSheetShell);
      if (sheet.evaluate().isNotEmpty) {
        final answer = tester
            .widgetList<SoriButton>(
              find.descendant(of: sheet, matching: find.byType(SoriButton)),
            )
            .firstWhere((button) => button.onTap != null);
        answer.onTap!();
        await _flush(tester);
      }

      expect(
        platform.writes[Storage.courseMasterySnapshotPreferenceKey],
        isNull,
        reason: 'An invalid replacement route cannot authorize cached links.',
      );
      expect(sheet, findsNothing);
      await _dispose(tester);
    },
  );

  testWidgets(
    'smalltalk same-State invalid route replacement cannot use a cached assessment',
    (tester) async {
      final catalog = (await tester.runAsync(CurriculumCatalog.load))!;
      CourseProgressService.shared.resetForTesting();
      final fixture = await _activeSmalltalkFixture(tester, catalog);
      final validContext = CoursePracticeContext.fromLink(fixture.link);
      final invalidContext = CoursePracticeContext(
        courseUnitId: fixture.link.courseUnitId,
        contentKind: fixture.link.contentKind,
        initialContentId: 'wrong_initial_id',
        contentLinkId: fixture.link.id,
      );
      final screenKey = GlobalKey();
      await tester.pumpWidget(
        _wrap(SmalltalkScreen(key: screenKey, courseContext: validContext)),
      );
      await _settle(tester);

      await tester.pumpWidget(
        _wrap(SmalltalkScreen(key: screenKey, courseContext: invalidContext)),
      );
      await tester.pump();
      platform.writes.clear();

      final quickCheck = find.text('Quick check');
      if (quickCheck.evaluate().isNotEmpty) {
        await tester.tap(quickCheck.first);
        await tester.pump();
        final answer = _relationshipButtons(
          tester,
        ).firstWhere((button) => button.onTap != null);
        answer.onTap!();
        await _flush(tester);
      }

      expect(
        platform.writes[Storage.courseMasterySnapshotPreferenceKey],
        isNull,
        reason: 'An invalid replacement route cannot authorize cached links.',
      );
      expect(quickCheck, findsNothing);
      await _dispose(tester);
    },
  );

  testWidgets(
    'smalltalk same-State injected preview cannot use a cached assessment',
    (tester) async {
      final catalog = (await tester.runAsync(CurriculumCatalog.load))!;
      CourseProgressService.shared.resetForTesting();
      final fixture = await _activeSmalltalkFixture(tester, catalog);
      final validContext = CoursePracticeContext.fromLink(fixture.link);
      final screenKey = GlobalKey();
      await tester.pumpWidget(
        _wrap(SmalltalkScreen(key: screenKey, courseContext: validContext)),
      );
      await _settle(tester);

      await tester.pumpWidget(
        _wrap(
          SmalltalkScreen(
            key: screenKey,
            phrases: <SmalltalkPhrase>[fixture.phrase],
            courseContext: validContext,
          ),
        ),
      );
      await tester.pump();
      platform.writes.clear();

      final quickCheck = find.text('Quick check');
      if (quickCheck.evaluate().isNotEmpty) {
        await tester.tap(quickCheck.first);
        await tester.pump();
        final answer = _relationshipButtons(
          tester,
        ).firstWhere((button) => button.onTap != null);
        answer.onTap!();
        await _flush(tester);
      }

      expect(
        platform.writes[Storage.courseMasterySnapshotPreferenceKey],
        isNull,
        reason: 'An injected preview cannot inherit cached course eligibility.',
      );
      expect(quickCheck, findsNothing);
      await _dispose(tester);
    },
  );

  for (final committed in [false, true]) {
    testWidgets(
      'grammar native unknown committed=$committed retains one first answer',
      (tester) => _grammarUnknownFirstAnswer(tester, platform, committed),
    );
    testWidgets(
      'smalltalk native unknown committed=$committed retains one first relationship',
      (tester) => _smalltalkUnknownFirstAnswer(tester, platform, committed),
    );
  }
}

({ContentLink source, ContentLink target}) _grammarAssessmentPair(
  CurriculumCatalog catalog,
) {
  final links = catalog.contentLinks
      .where(
        (link) =>
            link.courseUnitId == 'b2_04_complaint_resolution' &&
            link.contentKind == CurriculumContentKind.grammar &&
            link.role == ContentLinkRole.assess &&
            link.conceptIds.length == 1,
      )
      .toList(growable: false);
  if (links.length < 2) {
    throw StateError('Expected two assessed grammar links in the active unit.');
  }
  return (source: links.first, target: links[1]);
}

Future<
  ({
    ContentLink sourceLink,
    ContentLink targetLink,
    Grammar target,
    List<SoriButton> choices,
  })
>
_openGrammarFixture(
  WidgetTester tester,
  CurriculumCatalog catalog, {
  ContentLink? sourceLink,
  ContentLink? targetLink,
  GrammarCheckpointRecorder? checkpointRecorder,
  bool routeLauncher = false,
}) async {
  final fallback = catalog.contentLinks.singleWhere(
    (link) =>
        link.contentKind == CurriculumContentKind.grammar &&
        link.contentId == 'grammar_b2_counterfactual_past' &&
        link.courseUnitId == 'b2_04_complaint_resolution' &&
        link.role == ContentLinkRole.assess,
  );
  final source = sourceLink ?? fallback;
  final targetAssessment = targetLink ?? fallback;
  final context = CoursePracticeContext.fromLink(source);
  await _activateUnit(tester, catalog, source.courseUnitId);
  final ids = courseContentIdsForContext(
    catalog: catalog,
    courseContext: context,
    kind: CurriculumContentKind.grammar,
  )!;
  final grammar = (await DataLoader.loadGrammar())
      .where((item) => ids.contains(item.id))
      .toList(growable: false);
  final target = grammar.singleWhere(
    (item) => item.id == targetAssessment.contentId,
  );
  await Storage.setGrammarLastIdx(grammar.indexOf(target));
  final screen = GrammarScreen(
    courseContext: context,
    checkpointRecorder: checkpointRecorder,
  );
  await tester.pumpWidget(
    routeLauncher ? _wrapLauncher(screen) : _wrap(screen),
  );
  if (routeLauncher) {
    await tester.tap(find.byKey(const Key('open-evidence-route')));
  }
  await _settle(tester);
  await tester.tap(find.byType(FlipCard));
  await _settle(tester);
  final choices = tester
      .widgetList<SoriButton>(
        find.descendant(
          of: find.byType(SoriSheetShell),
          matching: find.byType(SoriButton),
        ),
      )
      .where((button) => button.onTap != null)
      .toList(growable: false);
  return (
    sourceLink: source,
    targetLink: targetAssessment,
    target: target,
    choices: choices,
  );
}

Future<void> _grammarUnknownFirstAnswer(
  WidgetTester tester,
  RewardPreferencesPlatform platform,
  bool committed,
) async {
  final catalog = (await tester.runAsync(CurriculumCatalog.load))!;
  CourseProgressService.shared.resetForTesting();
  const targetId = 'grammar_b2_counterfactual_past';
  final link = catalog.contentLinks.singleWhere(
    (item) =>
        item.contentKind == CurriculumContentKind.grammar &&
        item.contentId == targetId &&
        item.courseUnitId == 'b2_04_complaint_resolution' &&
        item.role == ContentLinkRole.assess,
  );
  final context = CoursePracticeContext.fromLink(link);
  await _activateUnit(tester, catalog, link.courseUnitId);
  platform.writes.clear();
  final ids = courseContentIdsForContext(
    catalog: catalog,
    courseContext: context,
    kind: CurriculumContentKind.grammar,
  )!;
  final grammar = (await DataLoader.loadGrammar())
      .where((item) => ids.contains(item.id))
      .toList(growable: false);
  final target = grammar.singleWhere((item) => item.id == targetId);
  await Storage.setGrammarLastIdx(
    grammar.indexWhere((item) => item.id == targetId),
  );
  await tester.pumpWidget(_wrap(GrammarScreen(courseContext: context)));
  await _settle(tester);
  await tester.tap(find.byType(FlipCard));
  await _settle(tester);
  final choices = tester
      .widgetList<SoriButton>(
        find.descendant(
          of: find.byType(SoriSheetShell),
          matching: find.byType(SoriButton),
        ),
      )
      .where((button) => button.onTap != null)
      .toList(growable: false);
  final correct = choices.singleWhere(
    (button) => button.label == target.pattern,
  );
  final wrong = choices.firstWhere((button) => button.label != target.pattern);
  platform
    ..rejectKey = Storage.courseMasterySnapshotPreferenceKey
    ..throwReply = true
    ..commitBeforeFailure = committed
    ..failReloadAfterWrite = true;
  wrong.onTap!();
  await _flush(tester);
  expect(platform.unavailable, isTrue);
  expect(platform.writes[Storage.courseMasterySnapshotPreferenceKey], 1);
  platform
    ..rejectKey = null
    ..unavailable = false;
  correct.onTap!();
  await _flush(tester);
  expect(platform.writes[Storage.courseMasterySnapshotPreferenceKey], 1);
  await tester.tap(find.byKey(const Key('grammar-checkpoint-retry')));
  await _flush(tester);
  final snapshot = await CourseProgressService.shared.readForDisplay();
  final evidence = snapshot!.evidence
      .where((entry) => entry.contentId == targetId)
      .toList(growable: false);
  expect(evidence, hasLength(1));
  expect(evidence.single.isCorrect, isFalse);
  expect(evidence.single.missionContentLinkId, link.id);
  expect(
    platform.writes[Storage.courseMasterySnapshotPreferenceKey],
    committed ? 1 : 2,
  );
  await _dispose(tester);
}

Future<void> _smalltalkUnknownFirstAnswer(
  WidgetTester tester,
  RewardPreferencesPlatform platform,
  bool committed,
) async {
  final catalog = (await tester.runAsync(CurriculumCatalog.load))!;
  CourseProgressService.shared.resetForTesting();
  final fixture = await _activeSmalltalkFixture(tester, catalog);
  final link = fixture.link;
  final phrase = fixture.phrase;
  platform.writes.clear();
  await tester.pumpWidget(
    _wrap(SmalltalkScreen(courseContext: CoursePracticeContext.fromLink(link))),
  );
  await _settle(tester);
  await tester.tap(find.text('Quick check').first);
  await tester.pump();
  final buttons = tester
      .widgetList<SoriButton>(find.byType(SoriButton))
      .where(
        (button) => SmalltalkRelationshipContext.values.any(
          (context) => context.labelFor('en') == button.label,
        ),
      )
      .toList(growable: false);
  final correct = buttons.singleWhere(
    (button) => button.label == phrase.relationshipContext.labelFor('en'),
  );
  final wrong = buttons.firstWhere(
    (button) => button.label != phrase.relationshipContext.labelFor('en'),
  );
  platform
    ..rejectKey = Storage.courseMasterySnapshotPreferenceKey
    ..throwReply = true
    ..commitBeforeFailure = committed
    ..failReloadAfterWrite = true;
  wrong.onTap!();
  await _flush(tester);
  expect(platform.unavailable, isTrue);
  expect(platform.writes[Storage.courseMasterySnapshotPreferenceKey], 1);
  platform
    ..rejectKey = null
    ..unavailable = false;
  correct.onTap!();
  await _flush(tester);
  expect(platform.writes[Storage.courseMasterySnapshotPreferenceKey], 1);
  await tester.ensureVisible(
    find.byKey(const Key('smalltalk-checkpoint-retry')),
  );
  await tester.tap(find.byKey(const Key('smalltalk-checkpoint-retry')));
  await _flush(tester);
  final snapshot = await CourseProgressService.shared.readForDisplay();
  final evidence = snapshot!.evidence
      .where((entry) => entry.contentId == phrase.id)
      .toList(growable: false);
  expect(evidence, hasLength(1));
  expect(evidence.single.isCorrect, isFalse);
  expect(evidence.single.missionContentLinkId, link.id);
  expect(
    platform.writes[Storage.courseMasterySnapshotPreferenceKey],
    committed ? 1 : 2,
  );
  await _dispose(tester);
}

Future<({ContentLink link, SmalltalkPhrase phrase})> _activeSmalltalkFixture(
  WidgetTester tester,
  CurriculumCatalog catalog,
) async {
  await tester.runAsync(SmalltalkLoader.load);
  const unitId = 'a2_02_plans_proposals';
  final seed = catalog.contentLinks.firstWhere(
    (link) =>
        link.contentKind == CurriculumContentKind.smalltalk &&
        link.courseUnitId == unitId &&
        link.role == ContentLinkRole.assess,
  );
  final context = CoursePracticeContext.fromLink(seed);
  final ids = courseContentIdsForContext(
    catalog: catalog,
    courseContext: context,
    kind: CurriculumContentKind.smalltalk,
  )!;
  final assessments = courseAssessmentLinksForContext(
    catalog: catalog,
    courseContext: context,
    kind: CurriculumContentKind.smalltalk,
  );
  final visibleCategoryIds = SmalltalkLoader.phrases
      .where((phrase) => ids.contains(phrase.id))
      .map((phrase) => phrase.category)
      .toSet();
  final firstCategory = SmalltalkLoader.categories.firstWhere(
    (category) => visibleCategoryIds.contains(category.id),
  );
  final firstPhrase = SmalltalkLoader.filter(
    category: firstCategory.id,
  ).firstWhere((phrase) => ids.contains(phrase.id));
  final exactLink = assessments[firstPhrase.id];
  if (exactLink == null) {
    throw StateError('The scoped feed does not begin with an assessment.');
  }
  await _activateUnit(tester, catalog, unitId);
  return (link: exactLink, phrase: firstPhrase);
}

Future<
  ({
    ContentLink sourceLink,
    ContentLink targetLink,
    SmalltalkPhrase targetPhrase,
    int navigationCount,
  })
>
_activeSmalltalkPair(WidgetTester tester, CurriculumCatalog catalog) async {
  await tester.runAsync(SmalltalkLoader.load);
  const unitId = 'a2_02_plans_proposals';
  final seed = catalog.contentLinks.firstWhere(
    (link) =>
        link.contentKind == CurriculumContentKind.smalltalk &&
        link.courseUnitId == unitId &&
        link.role == ContentLinkRole.assess,
  );
  final context = CoursePracticeContext.fromLink(seed);
  final ids = courseContentIdsForContext(
    catalog: catalog,
    courseContext: context,
    kind: CurriculumContentKind.smalltalk,
  )!;
  final assessments = courseAssessmentLinksForContext(
    catalog: catalog,
    courseContext: context,
    kind: CurriculumContentKind.smalltalk,
  );
  final visibleCategoryIds = SmalltalkLoader.phrases
      .where((phrase) => ids.contains(phrase.id))
      .map((phrase) => phrase.category)
      .toSet();
  final category = SmalltalkLoader.categories.firstWhere(
    (item) => visibleCategoryIds.contains(item.id),
  );
  final phrases = SmalltalkLoader.filter(
    category: category.id,
  ).where((phrase) => ids.contains(phrase.id)).toList(growable: false);
  final sourcePhrase = phrases.first;
  final sourceLink = assessments[sourcePhrase.id];
  if (sourceLink == null) {
    throw StateError('The scoped feed does not begin with an assessment.');
  }
  final targetIndex = phrases.indexWhere(
    (phrase) =>
        phrase.id != sourcePhrase.id && assessments.containsKey(phrase.id),
  );
  if (targetIndex < 1) {
    throw StateError('Expected a second assessed phrase in the visible feed.');
  }
  final targetPhrase = phrases[targetIndex];
  await _activateUnit(tester, catalog, unitId);
  return (
    sourceLink: sourceLink,
    targetLink: assessments[targetPhrase.id]!,
    targetPhrase: targetPhrase,
    navigationCount: targetIndex,
  );
}

List<SoriButton> _relationshipButtons(WidgetTester tester) => tester
    .widgetList<SoriButton>(find.byType(SoriButton))
    .where(
      (button) => SmalltalkRelationshipContext.values.any(
        (context) => context.labelFor('en') == button.label,
      ),
    )
    .toList(growable: false);

Future<void> _activateUnit(
  WidgetTester tester,
  CurriculumCatalog catalog,
  String unitId,
) async {
  final index = catalog.courseUnits.indexWhere((unit) => unit.id == unitId);
  expect(index, isNonNegative);
  final snapshot = CourseMasterySnapshot(
    curriculumGeneration: catalog.scenarioCorpusGeneration,
    placementLevel: 'a1',
    currentCourseUnitId: unitId,
    completedUnitIds: catalog.courseUnits
        .take(index)
        .map((unit) => unit.id)
        .toList(growable: false),
  );
  await CourseProgressService.shared.applyReconciledSnapshot(
    snapshot,
    expectedGeneration: null,
  );
}

Widget _wrap(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, appChild) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(disableAnimations: true),
      child: appChild!,
    );
  },
  home: child,
);

Widget _wrapLauncher(Widget child) => _wrap(
  Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: ElevatedButton(
          key: const Key('open-evidence-route'),
          onPressed: () => Navigator.of(
            context,
          ).push<void>(MaterialPageRoute<void>(builder: (_) => child)),
          child: const Text('Open evidence route'),
        ),
      ),
    ),
  ),
);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _flush(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 25));
  }
}

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}
