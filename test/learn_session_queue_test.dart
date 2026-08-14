// Learn 단계 세션 내 재출제 큐 — 재삽입 위치, 진행 분자/분모 계약,
// 3회 실패 졸업, 종료 상한(≤ maxMisses × n).

import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/services/learn_session_queue.dart';

LearnSessionQueue<String> _q(List<String> items) =>
    LearnSessionQueue<String>(items, idOf: (s) => s);

void main() {
  test('markKnown removes the head and advances position', () {
    final q = _q(['a', 'b', 'c']);
    expect(q.current, 'a');
    expect(q.servedPosition, 1);
    expect(q.uniqueTotal, 3);

    expect(q.markKnown(), LearnAnswerOutcome.advanced);
    expect(q.current, 'b');
    expect(q.servedPosition, 2);

    q.markKnown();
    q.markKnown();
    expect(q.isDone, isTrue);
    expect(q.current, isNull);
    expect(q.servedPosition, 3); // 완료 후에도 분모를 넘지 않는다
  });

  test('markUnknown reinserts after reinsertGap cards', () {
    final q = _q(['a', 'b', 'c', 'd', 'e']);
    expect(q.markUnknown(), LearnAnswerOutcome.requeued);
    // 남은 [b,c,d,e] 의 index 3 에 삽입 → b,c,d,a,e
    final served = <String>[];
    while (!q.isDone) {
      served.add(q.current!);
      q.markKnown();
    }
    expect(served, ['b', 'c', 'd', 'a', 'e']);
  });

  test('reinsert gap clamps to remaining length (near the end)', () {
    final q = _q(['a', 'b']);
    q.markKnown(); // a 제거 → [b]
    expect(q.markUnknown(), LearnAnswerOutcome.requeued); // [b] 그대로 재삽입
    expect(q.current, 'b');
    expect(q.servedPosition, 2);
  });

  test(
    'single always-missed word is re-served immediately, then graduates',
    () {
      final q = _q(['a']);
      expect(q.markUnknown(), LearnAnswerOutcome.requeued);
      expect(q.current, 'a');
      expect(q.markUnknown(), LearnAnswerOutcome.requeued);
      expect(q.markUnknown(), LearnAnswerOutcome.graduated);
      expect(q.isDone, isTrue);
      expect(q.missesOf('a'), 3);
    },
  );

  test('servedPosition holds during re-asks (denominator never changes)', () {
    final q = _q(['a', 'b', 'c']);
    q.markUnknown(); // a 재삽입 → 남은 고유 3
    expect(q.servedPosition, 1);
    q.markKnown(); // b 또는 재배치된 순서의 head 제거
    expect(q.servedPosition, 2);
    expect(q.uniqueTotal, 3);
  });

  test(
    'termination bound: always-wrong user finishes in ≤ maxMisses × n serves',
    () {
      final q = _q(List.generate(10, (i) => 'w$i'));
      var serves = 0;
      while (!q.isDone) {
        serves++;
        q.markUnknown();
        expect(serves, lessThanOrEqualTo(30));
      }
      expect(serves, 30);
      for (var i = 0; i < 10; i++) {
        expect(q.missesOf('w$i'), 3);
      }
    },
  );

  test('graduated word (3rd miss) leaves without reinsertion', () {
    final q = _q(['a', 'b']);
    q.markUnknown(); // a 미스 1 → [b, a]
    q.markKnown(); // b 제거 → [a]
    q.markUnknown(); // a 미스 2 → [a]
    expect(q.markUnknown(), LearnAnswerOutcome.graduated); // a 미스 3
    expect(q.isDone, isTrue);
  });

  test('answering an empty queue is a programming error', () {
    final q = _q([]);
    expect(q.isDone, isTrue);
    expect(q.markKnown, throwsStateError);
    expect(q.markUnknown, throwsStateError);
    expect(q.defer, throwsStateError);
  });

  test('peekNext exposes only the next queued card', () {
    expect(_q([]).peekNext, isNull);
    expect(_q(['a']).peekNext, isNull);
    expect(_q(['a', 'b']).peekNext, 'b');
  });

  test('defer uses the reinsert gap without recording misses', () {
    final q = _q(['a', 'b', 'c', 'd', 'e']);
    expect(q.defer(), LearnAnswerOutcome.deferred);
    expect(q.missesOf('a'), 0);
    final served = <String>[];
    while (!q.isDone) {
      served.add(q.current!);
      q.markKnown();
    }
    expect(served, ['b', 'c', 'd', 'a', 'e']);
  });

  test('repeated defer never graduates or changes unique total', () {
    final q = _q(['a']);
    for (var i = 0; i < 10; i++) {
      expect(q.defer(), LearnAnswerOutcome.deferred);
      expect(q.current, 'a');
      expect(q.missesOf('a'), 0);
      expect(q.uniqueTotal, 1);
      expect(q.isDone, isFalse);
    }
  });
}
