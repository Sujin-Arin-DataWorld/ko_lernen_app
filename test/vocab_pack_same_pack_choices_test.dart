// 퀴즈 보기 = 그 장에서 배운 단어들 (2026-08-14 Jin 제안):
// "잘 지냈어요?"의 보기에 Tee/Wochenende(다른 팩)가 나오면 주제만 봐도
// 정답이 드러난다. 보기 4개는 전부 현재 팩의 뜻이어야 한다.

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

Vocab _word(String packId, int n, {bool boss = false, String prefix = 'GER'}) =>
    Vocab(
      id: '${packId}_v$n',
      korean: '$packId단어$n',
      romanization: 'r$n',
      german: '$prefix-$packId-$n',
      level: 'A1',
      posDe: 'Nomen',
      exampleKorean: '',
      exampleGerman: '',
      topic: 'test',
      packId: packId,
      packOrder: n,
      isReviewBoss: boss,
    );

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

  testWidgets('quiz choices come only from the current pack', (tester) async {
    // 현재 팩 5단어(뜻 4개 이상) + 다른 팩 8단어(OTHER-*) — 예전 로직이면
    // 랜덤/품사 계층이 OTHER 를 뽑을 수 있는 구성.
    final pack = VocabPack(
      id: 'a1_greet_1',
      level: 'A1',
      words: [
        for (var i = 1; i <= 4; i++) _word('a1_greet_1', i),
        _word('a1_greet_1', 5, boss: true),
      ],
    );
    final sibling = VocabPack(
      id: 'a1_food_1',
      level: 'A1',
      words: [
        for (var i = 1; i <= 8; i++) _word('a1_food_1', i, prefix: 'OTHER'),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: VocabPackScreen(
          packId: pack.id,
          packLoader: (_) async => pack,
          siblingPacksLoader: (_) async => [pack, sibling],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Learn은 Boss 단어까지 포함한 현재 팩 5장을 모두 통과한 뒤 Quiz로 간다.
    for (var i = 0; i < 5; i++) {
      tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      tester.widget<SoriDeckActionBar>(find.byType(SoriDeckActionBar)).onKnow();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    // 퀴즈 스테이지 — 보기 4개 전부 현재 팩의 뜻(GER-a1_greet_1-*).
    final choices = tester
        .widgetList<QuizChoice>(find.byType(QuizChoice))
        .toList();
    expect(choices, hasLength(4));
    for (final choice in choices) {
      expect(
        choice.text.startsWith('GER-a1_greet_1-'),
        isTrue,
        reason:
            '보기 "${choice.text}" 는 현재 팩 밖의 단어다 — 그 장에서 배운 '
            '단어들이 보기로 나와야 한다',
      );
    }
    expect(tester.takeException(), isNull);
  });
}
