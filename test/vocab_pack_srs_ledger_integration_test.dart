import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';
import 'package:ko_lernen_app/widgets/sori/quiz_choice.dart';

import 'helpers/deck_actions.dart';

Vocab _word(int index, {required String packId, bool boss = false}) => Vocab(
  id: '$packId-v$index',
  korean: '증거단어$index',
  romanization: 'jeunggeo$index',
  german: 'EVIDENCE-$index',
  english: 'evidence-$index',
  level: 'A1',
  posDe: 'Nomen',
  exampleKorean: '',
  exampleGerman: '',
  topic: 'test',
  packId: packId,
  packOrder: index,
  isReviewBoss: boss,
);

Future<AppL10n> _pumpPack(WidgetTester tester, VocabPack pack) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      routes: <String, WidgetBuilder>{
        '/vocab/result': (_) => const Scaffold(body: Text('pack-result')),
      },
      home: VocabPackScreen(
        packId: pack.id,
        packLoader: (_) async => pack,
        siblingPacksLoader: (_) async => <VocabPack>[pack],
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return AppL10n.delegate.load(const Locale('de'));
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
    await tester.pump(const Duration(milliseconds: 400));
  }
}

Future<void> _answerCurrent(
  WidgetTester tester, {
  required bool correct,
}) async {
  final choice = tester
      .widgetList<QuizChoice>(find.byType(QuizChoice))
      .firstWhere((candidate) => candidate.isCorrect == correct);
  choice.onSelected!();
  await tester.pump(const Duration(milliseconds: 900));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Storage.init();
    await Storage.setTutVocabPackSeen();
    await Storage.setTutPackQuizSeen();
    await Storage.setTutPackBossSeen();
  });

  testWidgets(
    'Learn then correct Quiz and Boss recognition records one positive SRS review per word',
    (tester) async {
      const packId = 'a1_ledger_positive_1';
      final pack = VocabPack(
        id: packId,
        level: 'A1',
        words: <Vocab>[
          _word(1, packId: packId),
          _word(2, packId: packId),
          _word(3, packId: packId),
          _word(4, packId: packId),
          _word(5, packId: packId, boss: true),
        ],
      );
      final t = await _pumpPack(tester, pack);

      await _learnKnown(tester, t, count: pack.total);
      for (var index = 0; index < pack.normalWords.length; index++) {
        await _answerCurrent(tester, correct: true);
      }
      for (var index = 0; index < pack.bossWords.length; index++) {
        await _answerCurrent(tester, correct: true);
      }

      for (final word in pack.words) {
        final card = Storage.srsCard(word.korean);
        expect(card, isNotNull);
        expect(
          card!.reviewCount,
          1,
          reason: '${word.korean} must not be promoted again by recognition',
        );
        expect(card.intervalDays, 1);
      }
      expect(Storage.srsTotalReviewed(), pack.total);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a Learn positive followed by a Quiz miss writes one negative and keeps wrong-count',
    (tester) async {
      const packId = 'a1_ledger_negative_1';
      final pack = VocabPack(
        id: packId,
        level: 'A1',
        words: <Vocab>[
          _word(1, packId: packId),
          _word(2, packId: packId, boss: true),
          _word(3, packId: packId),
          _word(4, packId: packId),
        ],
      );
      final t = await _pumpPack(tester, pack);

      await _learnKnown(tester, t, count: pack.total);

      final currentWord = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .whereType<String>()
          .firstWhere((text) => text.startsWith('증거단어'));
      await _answerCurrent(tester, correct: false);

      final card = Storage.srsCard(currentWord)!;
      expect(card.intervalDays, 1);
      expect(card.reviewCount, 2);
      expect(Storage.wrongCountOf(currentWord), 1);
      expect(tester.takeException(), isNull);
    },
  );
}
