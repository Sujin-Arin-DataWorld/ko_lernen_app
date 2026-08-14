import 'dart:math' as math;

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
import 'package:ko_lernen_app/widgets/sori/deck_action_bar.dart';
import 'package:ko_lernen_app/widgets/sori/quiz_choice.dart';

Vocab _word(int index, {bool boss = false}) => Vocab(
  id: 'order-$index',
  korean: '순서단어$index',
  romanization: 'sunseo$index',
  german: 'ORDER-$index',
  level: 'A1',
  posDe: 'Nomen',
  exampleKorean: '',
  exampleGerman: '',
  topic: 'test',
  packId: 'a1_order_1',
  packOrder: index,
  isReviewBoss: boss,
);

Future<void> _revealAndMarkKnown(WidgetTester tester) async {
  tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  tester.widget<DeckActionBar>(find.byType(DeckActionBar)).onKnow();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _answerCorrect(WidgetTester tester) async {
  final correct = find.byWidgetPredicate(
    (widget) => widget is QuizChoice && widget.isCorrect,
  );
  expect(correct, findsOneWidget);
  tester.widget<QuizChoice>(correct).onSelected!();
  await tester.pump(const Duration(milliseconds: 900));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await Storage.setTutVocabPackSeen();
    await Storage.setTutPackQuizSeen();
    await Storage.setTutPackBossSeen();
  });

  test(
    'assessment order is reproducible with a seed and preserves every item',
    () {
      const source = ['one', 'two', 'three', 'four'];

      final first = shuffledAssessmentOrder(source, rng: math.Random(42));
      final second = shuffledAssessmentOrder(source, rng: math.Random(42));

      expect(first, second);
      expect(first.toSet(), source.toSet());
      expect(first, isNot(source));
    },
  );

  test('an identity shuffle rotates a multi-item assessment order', () {
    const source = ['one', 'two'];
    var identitySeed = -1;
    for (var seed = 0; seed < 1000; seed++) {
      final candidate = List<String>.of(source)..shuffle(math.Random(seed));
      if (candidate[0] == source[0] && candidate[1] == source[1]) {
        identitySeed = seed;
        break;
      }
    }
    expect(identitySeed, greaterThanOrEqualTo(0));

    final actual = shuffledAssessmentOrder(
      source,
      rng: math.Random(identitySeed),
    );

    expect(actual, ['two', 'one']);
  });

  testWidgets('screen uses cached shuffled Quiz and Boss orders after Learn', (
    tester,
  ) async {
    final pack = VocabPack(
      id: 'a1_order_1',
      level: 'A1',
      words: [_word(1), _word(2), _word(3, boss: true), _word(4, boss: true)],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: VocabPackScreen(
          packId: pack.id,
          packLoader: (_) async => pack,
          siblingPacksLoader: (_) async => [pack],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    for (var i = 0; i < pack.total; i++) {
      await _revealAndMarkKnown(tester);
    }

    // Two-item orders cannot keep their source order: the helper rotates an
    // identity shuffle, so Quiz starts with normal word 2.
    expect(find.text('순서단어2'), findsOneWidget);
    await _answerCorrect(tester);
    expect(find.text('순서단어1'), findsOneWidget);
    await _answerCorrect(tester);

    // Boss uses its independently cached shuffled membership order, not the
    // Learn sequence or normal Quiz order.
    expect(find.text('순서단어4'), findsOneWidget);
    await _answerCorrect(tester);
    expect(find.text('순서단어3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
