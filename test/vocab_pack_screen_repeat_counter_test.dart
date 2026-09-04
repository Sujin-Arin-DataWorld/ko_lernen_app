// Learn 단계 진행 칩 — 재출제(재서빙) 카드가 나오면 "n / m · +k Wdh."
// 형식으로 숫자 옆에 재출제 횟수를 병기한다 (지시서 1.1, 검수#21: 별도
// 칩이 아니라 숫자에 병기).

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

import 'helpers/deck_actions.dart';

Vocab _word(int n) => Vocab(
  id: 'rc_v$n',
  korean: '반복단어$n',
  romanization: 'banbokdaneo$n',
  german: 'RC-GER-$n',
  level: 'A1',
  posDe: 'Nomen',
  exampleKorean: '',
  exampleGerman: '',
  topic: 'test',
  packId: 'a1_rc_1',
  packOrder: n,
);

Future<AppL10n> _pump(WidgetTester tester, VocabPack pack) async {
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
        siblingPacksLoader: (_) async => [pack],
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return AppL10n.delegate.load(const Locale('de'));
}

void _tapButton(WidgetTester tester, String label) {
  tapDeckAction(tester, label);
}

Future<void> _revealCurrentLearnCard(WidgetTester tester) async {
  tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _revealAndTapButton(WidgetTester tester, String label) async {
  await _revealCurrentLearnCard(tester);
  _tapButton(tester, label);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
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

  testWidgets('재출제 카드가 나오면 카운터가 "n / m · +k Wdh." 형식이 된다', (
    tester,
  ) async {
    // 기존 하네스로 3단어 팩을 로드하고 1번째 카드에서 "몰라요"를 눌러
    // 재출제를 유발한 뒤, 재출제 카드가 서빙되는 시점의 SoriChip 라벨을 검증.
    final pack = VocabPack(
      id: 'a1_rc_1',
      level: 'A1',
      words: [_word(1), _word(2), _word(3)],
    );
    final t = await _pump(tester, pack);

    // 1번째 카드(반복단어1)에서 "몰라요" → 큐 끝에 재삽입되어
    // 재출제 대상이 된다.
    await _revealAndTapButton(tester, t.vocabPackDontKnow);
    await _settle(tester);

    // 2, 3번째 카드는 "알아요" → 큐를 소진해 재출제된 1번 카드가 다시 서빙된다.
    await _revealAndTapButton(tester, t.vocabPackGotIt);
    await _settle(tester);
    await _revealAndTapButton(tester, t.vocabPackGotIt);
    await _settle(tester);

    expect(find.text('반복단어1'), findsOneWidget);
    expect(find.textContaining('· +1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('같은 세션에서 재출제가 두 번 겹치면 카운터가 "+2" 까지 누적된다 (Task 2 리뷰 Minor)', (
    tester,
  ) async {
    // 4단어 팩. 1번째 카드를 두 번 몰라서 재출제 이벤트를 두 번 겹치게
    // 만든다: 1차 몰라요 후 나머지 3장을 다 맞히면 큐가 [1] 하나만 남은
    // 채로 재서빙된다(1번째 재출제 이벤트, +1). 그 상태에서 다시 몰라요를
    // 누르면 큐가 비었다가 즉시 같은 카드가 재삽입되어 재서빙된다(2번째
    // 재출제 이벤트, +2) — maxMisses=3 이라 misses=2 는 아직 졸업이 아니다.
    final pack = VocabPack(
      id: 'a1_rc_2',
      level: 'A1',
      words: [_word(1), _word(2), _word(3), _word(4)],
    );
    final t = await _pump(tester, pack);

    await _revealAndTapButton(tester, t.vocabPackDontKnow);
    await _settle(tester);
    await _revealAndTapButton(tester, t.vocabPackGotIt);
    await _settle(tester);
    await _revealAndTapButton(tester, t.vocabPackGotIt);
    await _settle(tester);
    await _revealAndTapButton(tester, t.vocabPackGotIt);
    await _settle(tester);

    expect(find.text('반복단어1'), findsOneWidget);
    expect(find.textContaining('· +1'), findsOneWidget);

    // 큐에 1번 카드 하나만 남은 상태에서 다시 "몰라요" → 즉시 같은 자리에
    // 재삽입되어 다시 서빙된다(2번째 재출제 이벤트).
    await _revealAndTapButton(tester, t.vocabPackDontKnow);
    await _settle(tester);

    expect(find.text('반복단어1'), findsOneWidget);
    expect(find.textContaining('· +2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
