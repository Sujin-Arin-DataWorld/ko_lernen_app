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

  // ── defer (아래 스와이프 = 스킵) ────────────────────────────────────
  // 스킵은 판정이 아니다: 실패로 세지 않으므로 아무리 스킵해도 졸업하지
  // 않고, 고유 단어 수(분모)도 그대로다.

  test('defer reinserts after reinsertGap without counting a miss', () {
    final q = _q(['a', 'b', 'c', 'd', 'e']);
    expect(q.defer(), LearnAnswerOutcome.deferred);
    expect(q.missesOf('a'), 0, reason: '스킵은 실패가 아니다');
    // markUnknown 과 같은 재삽입 기하 — 3장 뒤.
    expect(q.current, 'b');
    q.markKnown(); // b
    q.markKnown(); // c
    q.markKnown(); // d
    expect(q.current, 'a', reason: 'gap 3 뒤에 다시 서빙된다');
  });

  test('deferring ten times never graduates and keeps the denominator', () {
    final q = _q(['a', 'b']);
    for (var i = 0; i < 10; i++) {
      expect(q.defer(), LearnAnswerOutcome.deferred);
    }
    expect(q.uniqueTotal, 2);
    expect(q.isDone, isFalse, reason: '스킵만으로는 세션이 끝나지 않는다');
    expect(q.missesOf('a'), 0);
    expect(q.missesOf('b'), 0);
  });

  test('defer on a single-card queue re-serves the same card', () {
    final q = _q(['a']);
    expect(q.defer(), LearnAnswerOutcome.deferred);
    expect(q.current, 'a');
    expect(q.isDone, isFalse);
  });

  test('defer never moves the progress numerator backwards', () {
    final q = _q(['a', 'b', 'c']);
    final before = q.servedPosition;
    q.defer();
    expect(q.servedPosition, before, reason: '진행바 후퇴 금지');
  });

  test('peekNext reads the following card without mutating the queue', () {
    final q = _q(['a', 'b', 'c']);
    expect(q.peekNext, 'b');
    expect(q.peekNext, 'b', reason: '읽기 전용 — 두 번 불러도 같다');
    expect(q.current, 'a');
    expect(q.servedPosition, 1);

    q.markKnown();
    expect(q.peekNext, 'c');

    q.markKnown();
    expect(q.peekNext, isNull, reason: '한 장 남으면 다음 카드가 없다');

    q.markKnown();
    expect(q.peekNext, isNull, reason: '빈 큐도 null (throw 아님)');
  });
}
