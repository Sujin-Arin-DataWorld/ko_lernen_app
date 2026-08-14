import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/screens/vocab_pack_recall_screen.dart';
import 'package:ko_lernen_app/screens/vocab_pack_result_screen.dart';
import 'package:ko_lernen_app/services/pack_session_srs_ledger.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/vocab_recall_evidence.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';

Vocab _word(int index, {bool boss = false}) => Vocab(
  id: 'recall-$index',
  korean: index == 1 ? '하나' : '둘',
  romanization: index == 1 ? 'hana' : 'dul',
  german: index == 1 ? 'eins' : 'zwei',
  english: index == 1 ? 'one' : 'two',
  level: 'A1',
  posDe: 'Zahl',
  exampleKorean: '',
  exampleGerman: '',
  topic: 'test',
  packId: 'a1_recall_1',
  packOrder: index,
  isReviewBoss: boss,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  test('typed recall grading only credits an unhinted first success', () {
    expect(
      gradeVocabRecallAnswer(
        submitted: '하 나',
        expected: '하나',
        usedHint: false,
      ).evidence,
      VocabRecallEvidence.positive,
    );
    expect(
      gradeVocabRecallAnswer(
        submitted: '하나',
        expected: '하나',
        usedHint: true,
      ).evidence,
      VocabRecallEvidence.none,
    );
    expect(
      gradeVocabRecallAnswer(
        submitted: '둘',
        expected: '하나',
        usedHint: false,
      ).evidence,
      VocabRecallEvidence.negative,
    );
    expect(revealedVocabRecallAnswer.evidence, VocabRecallEvidence.negative);
  });

  test('typed recall order is seeded, complete, and not the source order', () {
    final source = [_word(1, boss: true), _word(2, boss: true)];

    final first = shuffledVocabRecallWords(source, rng: math.Random(12));
    final second = shuffledVocabRecallWords(source, rng: math.Random(12));

    expect(
      first.map((word) => word.id).toList(),
      second.map((word) => word.id).toList(),
    );
    expect(
      first.map((word) => word.id).toSet(),
      source.map((word) => word.id).toSet(),
    );
    expect(
      first.map((word) => word.id).toList(),
      isNot(source.map((word) => word.id).toList()),
    );
  });

  testWidgets(
    'pack recall asks only current-pack Boss words and credits a direct success',
    (tester) async {
      final pack = VocabPack(
        id: 'a1_recall_1',
        level: 'A1',
        words: [_word(1), _word(2, boss: true)],
      );
      await _pumpRecall(
        tester,
        pack,
        recallSession: PackRecallSession.forPack(packId: pack.id),
      );

      expect(find.text('eins'), findsNothing);
      expect(find.text('zwei'), findsOneWidget);
      expect(find.text('둘'), findsNothing);

      await tester.enterText(find.byKey(const Key('vocab-recall-input')), '둘');
      await tester.pump();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('vocab-recall-input')))
            .controller!
            .text,
        '둘',
      );
      final submit = find.byKey(const Key('vocab-recall-submit'));
      await tester.ensureVisible(submit);
      expect(tester.widget<SoriButton>(submit).onTap, isNotNull);
      await tester.tap(submit);
      await tester.pump();
      await tester.pump();

      final card = Storage.srsCard('둘')!;
      expect(card.intervalDays, 1);
      expect(card.reviewCount, 1);
      expect(Storage.wrongCountOf('둘'), 0);
    },
  );

  testWidgets(
    'a hint can help practice but does not award positive SRS credit',
    (tester) async {
      final pack = VocabPack(
        id: 'a1_recall_1',
        level: 'A1',
        words: [_word(1, boss: true)],
      );
      await _pumpRecall(
        tester,
        pack,
        recallSession: PackRecallSession.forPack(packId: pack.id),
      );

      await tester.tap(find.byKey(const Key('vocab-recall-hint')));
      await tester.pump();
      expect(find.byKey(const Key('vocab-recall-hint-label')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('vocab-recall-input')), '하나');
      await tester.pump();
      final submit = find.byKey(const Key('vocab-recall-submit'));
      await tester.ensureVisible(submit);
      expect(tester.widget<SoriButton>(submit).onTap, isNotNull);
      await tester.tap(submit);
      await tester.pump();
      await tester.pump();

      expect(Storage.srsCard('하나'), isNull);
      expect(Storage.wrongCountOf('하나'), 0);
    },
  );

  testWidgets(
    'a direct typed success does not promote a word already credited in this pack session',
    (tester) async {
      final session = PackRecallSession.forPack(packId: 'a1_recall_1');
      expect(
        session.recordPositiveFor(expectedPackId: 'a1_recall_1', wordId: '하나'),
        PackSessionSrsAction.positive,
      );
      await Storage.srsReview('하나', gotIt: true);
      final pack = VocabPack(
        id: 'a1_recall_1',
        level: 'A1',
        words: [_word(1, boss: true)],
      );
      await _pumpRecall(tester, pack, recallSession: session);

      await tester.enterText(find.byKey(const Key('vocab-recall-input')), '하나');
      await tester.pump();
      final submit = find.byKey(const Key('vocab-recall-submit'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump();
      await tester.pump();

      final card = Storage.srsCard('하나')!;
      expect(card.intervalDays, 1);
      expect(card.reviewCount, 1);
    },
  );

  testWidgets(
    'a wrong typed attempt overrides an earlier positive once and locks the answer',
    (tester) async {
      final session = PackRecallSession.forPack(packId: 'a1_recall_1');
      expect(
        session.recordPositiveFor(expectedPackId: 'a1_recall_1', wordId: '하나'),
        PackSessionSrsAction.positive,
      );
      await Storage.srsReview('하나', gotIt: true);
      final pack = VocabPack(
        id: 'a1_recall_1',
        level: 'A1',
        words: [_word(1, boss: true)],
      );
      await _pumpRecall(tester, pack, recallSession: session);

      await tester.enterText(find.byKey(const Key('vocab-recall-input')), '둘');
      await tester.pump();
      final submit = find.byKey(const Key('vocab-recall-submit'));
      await tester.ensureVisible(submit);
      expect(tester.widget<SoriButton>(submit).onTap, isNotNull);
      await tester.tap(submit);
      await tester.pump();
      await tester.pump();

      final input = tester.widget<TextField>(
        find.byKey(const Key('vocab-recall-input')),
      );
      final card = Storage.srsCard('하나')!;
      expect(input.enabled, isFalse);
      expect(card.intervalDays, 1);
      expect(card.reviewCount, 2);
      expect(Storage.wrongCountOf('하나'), 1);
      expect(session.ledger.stateFor('하나'), PackSessionSrsState.negative);
    },
  );

  testWidgets(
    'reopening recall after a negative stays SRS-neutral but still practices',
    (tester) async {
      final pack = VocabPack(
        id: 'a1_recall_1',
        level: 'A1',
        words: [_word(1, boss: true)],
      );
      final session = PackRecallSession.forPack(packId: pack.id);

      await _pumpRecall(tester, pack, recallSession: session);
      await _submitRecall(tester, '둘');
      expect(Storage.srsCard('하나')!.reviewCount, 1);
      expect(Storage.wrongCountOf('하나'), 1);

      // A second visit receives the same object that the result route keeps.
      await _pumpRecall(tester, pack, recallSession: session);
      await _submitRecall(tester, '하나');

      final card = Storage.srsCard('하나')!;
      expect(card.intervalDays, 1);
      expect(card.reviewCount, 1);
      expect(Storage.wrongCountOf('하나'), 1);
      expect(session.ledger.stateFor('하나'), PackSessionSrsState.negative);
    },
  );

  testWidgets(
    'result route reuses one session object when typed recall is reopened',
    (tester) async {
      final pack = VocabPack(
        id: 'a1_recall_1',
        level: 'A1',
        words: [_word(1, boss: true)],
      );
      final session = PackRecallSession.forPack(packId: pack.id);
      final t = await AppL10n.delegate.load(const Locale('de'));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          onGenerateRoute: (settings) {
            if (settings.name != '/vocab/recall') {
              return null;
            }
            final args = settings.arguments as Map?;
            final routeSession = PackRecallSession.fromRouteArgument(
              args?['recallSession'],
              expectedPackId: pack.id,
            );
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => VocabPackRecallScreen(
                packId: pack.id,
                packLoader: (_) async => pack,
                orderRng: math.Random(1),
                recallSession: routeSession,
              ),
            );
          },
          home: VocabPackResultScreen(
            packId: pack.id,
            bossAccuracy: 1,
            bossCorrect: 1,
            bossTotal: 1,
            quizCorrect: 0,
            quizTotal: 0,
            justCleared: true,
            nextUnlockedPackId: null,
            recallSession: session,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1100));

      Future<void> openAndAnswer() async {
        final cta = find.text(t.vocabPackResultRecallCta);
        await tester.ensureVisible(cta);
        await tester.tap(cta);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await _submitRecall(tester, '하나');
      }

      await openAndAnswer();
      expect(Storage.srsCard('하나')!.reviewCount, 1);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      await openAndAnswer();
      expect(Storage.srsCard('하나')!.reviewCount, 1);
      expect(session.ledger.stateFor('하나'), PackSessionSrsState.positive);
    },
  );

  testWidgets(
    'missing, malformed, and pack-mismatched sessions are practice only',
    (tester) async {
      final pack = VocabPack(
        id: 'a1_recall_1',
        level: 'A1',
        words: [_word(1, boss: true)],
      );
      final malformed = PackRecallSession.fromRouteArgument(<String, Object>{
        'packId': pack.id,
      }, expectedPackId: pack.id);
      final mismatched = PackRecallSession.forPack(packId: 'a1_other_1');
      final sessions = <PackRecallSession?>[null, malformed, mismatched];

      for (final session in sessions) {
        await _pumpRecall(tester, pack, recallSession: session);
        await _submitRecall(tester, '둘');

        expect(
          Storage.srsCard('하나'),
          isNull,
          reason: 'practice-only sessions must not schedule a wrong answer',
        );
        expect(
          Storage.wrongCountOf('하나'),
          0,
          reason: 'practice-only sessions must not update wrong-count',
        );
      }
    },
  );

  testWidgets(
    'threshold-reaching recall misses offer the existing Hard Words route',
    (tester) async {
      await Storage.incrementWrongCount('하나');
      await Storage.incrementWrongCount('하나');
      final pack = VocabPack(
        id: 'a1_recall_1',
        level: 'A1',
        words: [_word(1, boss: true)],
      );
      await _pumpRecall(
        tester,
        pack,
        recallSession: PackRecallSession.forPack(packId: pack.id),
        routes: {
          '/hard_words': (_) => const Scaffold(body: Text('hard-words-route')),
        },
      );

      await tester.enterText(find.byKey(const Key('vocab-recall-input')), '둘');
      await tester.pump();
      final submit = find.byKey(const Key('vocab-recall-submit'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump();
      await tester.pump();
      final next = find.byKey(const Key('vocab-recall-next'));
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pump();

      final hardWords = find.byKey(const Key('vocab-recall-hard-words'));
      expect(hardWords, findsOneWidget);
      await tester.tap(hardWords);
      await tester.pumpAndSettle();
      expect(find.text('hard-words-route'), findsOneWidget);
    },
  );

  testWidgets(
    'result exposes the optional recall route only when Boss words exist',
    (tester) async {
      final t = await AppL10n.delegate.load(const Locale('de'));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          routes: {
            '/vocab/recall': (_) => const Scaffold(body: Text('recall-route')),
          },
          home: const VocabPackResultScreen(
            packId: 'a1_recall_1',
            bossAccuracy: 1,
            bossCorrect: 2,
            bossTotal: 2,
            quizCorrect: 3,
            quizTotal: 3,
            justCleared: true,
            nextUnlockedPackId: null,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1100));

      final recallCta = find.text(t.vocabPackResultRecallCta);
      expect(recallCta, findsOneWidget);
      await tester.ensureVisible(recallCta);
      await tester.tap(recallCta);
      await tester.pumpAndSettle();
      expect(find.text('recall-route'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: const VocabPackResultScreen(
            packId: 'a1_recall_1',
            bossAccuracy: 1,
            bossCorrect: 0,
            bossTotal: 0,
            quizCorrect: 3,
            quizTotal: 3,
            justCleared: false,
            nextUnlockedPackId: null,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.text(t.vocabPackResultRecallCta), findsNothing);
    },
  );
}

Future<void> _pumpRecall(
  WidgetTester tester,
  VocabPack pack, {
  PackRecallSession? recallSession,
  Map<String, WidgetBuilder> routes = const <String, WidgetBuilder>{},
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      routes: routes,
      home: VocabPackRecallScreen(
        key: UniqueKey(),
        packId: pack.id,
        packLoader: (_) async => pack,
        orderRng: math.Random(1),
        recallSession: recallSession,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _submitRecall(WidgetTester tester, String answer) async {
  await tester.enterText(find.byKey(const Key('vocab-recall-input')), answer);
  await tester.pump();
  final submit = find.byKey(const Key('vocab-recall-submit'));
  await tester.ensureVisible(submit);
  expect(tester.widget<SoriButton>(submit).onTap, isNotNull);
  await tester.tap(submit);
  await tester.pump();
  await tester.pump();
}
