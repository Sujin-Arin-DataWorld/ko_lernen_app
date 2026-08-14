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
}
