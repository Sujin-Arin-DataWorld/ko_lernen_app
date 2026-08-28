// 레벨 혼입(leak) 가드 — 2026-08-13 테스터 리포트 "A2인데 양극화":
// `todayNewIds` 는 입력 순서대로 신규 카드를 뽑으므로, 복습 덱의 CSV 부분은
// 반드시 레벨 오름차순(안정 정렬)이어야 한다. 워들 데일리 정답 풀도 사용자
// 레벨 이하로 캡.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/models/vocab.dart';

import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/personalized_lesson_service.dart';
import 'package:ko_lernen_app/services/review_deck_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

Vocab _v(String ko, String level, {int order = 0}) => Vocab(
  korean: ko,
  romanization: ko,
  german: 'de-$ko',
  level: level,
  posDe: 'Nomen',
  exampleKorean: '',
  exampleGerman: '',
  topic: 'test',
  packOrder: order,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    DataLoader.reset();
  });

  group('sortByLevelStable', () {
    test('orders by level rank, keeps within-level input order', () {
      final input = [
        _v('나1', 'B1', order: 1),
        _v('가1', 'A1', order: 1),
        _v('다1', 'B2', order: 1),
        _v('가2', 'A1', order: 2),
        _v('나2', 'B1', order: 2),
        _v('가3', 'A2', order: 1),
      ];
      final out = ReviewDeckService.sortByLevelStable(input);
      expect(out.map((v) => v.korean).toList(), [
        '가1', '가2', // A1 — 입력 순서 유지
        '가3', // A2
        '나1', '나2', // B1 — 입력 순서 유지
        '다1', // B2
      ]);
    });

    test('empty list stays empty', () {
      expect(ReviewDeckService.sortByLevelStable(const []), isEmpty);
    });
  });

  group('todaySelectionForLevel', () {
    test('fresh C1 learner receives C1 new cards instead of A1 starters', () {
      final selection = ReviewDeckService.todaySelectionForLevel([
        _v('안녕하세요', 'A1'),
        _v('환원하다', 'C1'),
        _v('담론', 'C1'),
        _v('가정컨대', 'C2'),
      ], levelCode: 'c1');

      expect(selection.words.map((word) => word.korean), ['환원하다', '담론']);
      expect(selection.newCount, 2);
      expect(selection.reviewCount, 0);
    });

    test('C1 today deck excludes an overdue A1 review card', () async {
      await Storage.setSrsRawJson(
        '{"안녕하세요":{"e":2.5,"i":1,"n":"2020-01-01","r":1}}',
      );

      final selection = ReviewDeckService.todaySelectionForLevel([
        _v('안녕하세요', 'A1'),
        _v('환원하다', 'C1'),
        _v('담론', 'C1'),
      ], levelCode: 'c1');

      expect(selection.words.map((word) => word.korean), ['환원하다', '담론']);
      expect(selection.newCount, 2);
      expect(selection.reviewCount, 0);
    });
  });

  test(
    'allReviewable serves the real CSV in non-decreasing level order',
    () async {
      final all = await ReviewDeckService.allReviewable();
      expect(all, isNotEmpty);
      // 신규 커스텀 팩/책장이 없는 fresh 상태 → 전부 CSV 단어.
      var last = 0;
      for (final v in all) {
        final rank = PersonalizedLessonService.levelRank(v.level);
        expect(
          rank >= last,
          isTrue,
          reason: '${v.korean} (${v.level}) appears after a higher level',
        );
        last = rank;
      }
    },
  );

  group('ReviewDeckService.deckForIds', () {
    test('maps in requested order and skips unknown IDs', () {
      final all = [_v('하나', 'A1'), _v('둘', 'A1'), _v('셋', 'A1')];

      final result = ReviewDeckService.deckForIds(
        all,
        ['셋', '없는 단어', '하나', '셋'],
      );

      expect(result.map((word) => word.korean), ['셋', '하나', '셋']);
    });

    test('uses the first Vocab when source IDs are duplicated', () {
      final first = _v('하나', 'A1');
      final duplicate = Vocab(
        korean: '하나',
        romanization: '다른 발음',
        german: 'zweite Bedeutung',
        level: 'B1',
        posDe: 'Nomen',
        exampleKorean: '',
        exampleGerman: '',
        topic: 'different',
      );

      final result = ReviewDeckService.deckForIds(
        [first, duplicate],
        ['하나'],
      );

      expect(result, [first]);
    });
  });
}
