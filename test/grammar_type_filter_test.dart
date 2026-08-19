import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/grammar.dart';
import 'package:ko_lernen_app/services/data_loader.dart';

/// 문법 "Typ" 필터가 덱을 카드 1 장으로 만들지 못하게 지키는 래칫.
///
/// `grammar.csv` 의 `type_de` 는 214 행에 고유값 213 개다 — 212 개가 1 행짜리라
/// 사실상 기본키다. 화면이 이걸 그대로 필터 선택지로 내주면, 유형을 하나 고르는
/// 순간 덱이 1 장이 되고 `_canNavigateDeck`(길이>1)이 false 가 되어 뭘 눌러도
/// 같은 카드만 나온다 (2026-08-19 Jin: "뭘 눌러도 이것만 나온다니까?").
///
/// 화면은 `_typesForLevel` 에서 **2 건 이상인 유형만** 내주고, 남는 게 'Alle'
/// 뿐이면 드롭다운 자체를 감춘다. 이 테스트는 그 규칙이 데이터에 대해 실제로
/// 무엇을 뜻하는지 고정한다 — CSV 가 굵은 유형으로 정리되면 여기 숫자가 늘고,
/// 그때 필터가 자연스럽게 되살아난다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(DataLoader.reset);

  test('type_de 는 필터로 쓸 만큼 굵지 않다 — 1건짜리 유형이 대다수', () async {
    final grammar = await DataLoader.loadGrammar();
    final counts = <String, int>{};
    for (final item in grammar) {
      counts[item.typeDe] = (counts[item.typeDe] ?? 0) + 1;
    }
    final singletons = counts.values.where((count) => count == 1).length;

    expect(
      singletons / counts.length,
      greaterThan(0.9),
      reason:
          '이 비율이 크게 떨어졌다면 type_de 가 굵은 분류로 정리된 것이다. '
          'grammar_screen 의 Typ 드롭다운 숨김 조건을 다시 볼 것.',
    );
  });

  test('레벨별로 2건 이상인 유형만 고르게 하면 덱이 1장으로 안 줄어든다', () async {
    final grammar = await DataLoader.loadGrammar();

    for (final level in const ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']) {
      final scoped = grammar
          .where((item) => item.level == level)
          .toList(growable: false);
      final counts = <String, int>{};
      for (final item in scoped) {
        counts[item.typeDe] = (counts[item.typeDe] ?? 0) + 1;
      }
      final offered = counts.entries
          .where((entry) => entry.value >= 2)
          .map((entry) => entry.key);

      for (final type in offered) {
        final deck = scoped
            .where((Grammar item) => item.typeDe == type)
            .toList(growable: false);
        expect(
          deck.length,
          greaterThan(1),
          reason: '$level / $type 를 고르면 덱이 ${deck.length}장이 된다',
        );
      }
    }
  });
}
