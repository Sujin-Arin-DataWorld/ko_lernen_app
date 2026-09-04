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

  test('markUnknown reinserts after every currently queued card', () {
    final q = _q(['a', 'b', 'c', 'd', 'e']);
    expect(q.markUnknown(), LearnAnswerOutcome.requeued);
    // 아직 보지 않은 [b,c,d,e] 뒤에 재삽입 → b,c,d,e,a
    final served = <String>[];
    while (!q.isDone) {
      served.add(q.current!);
      q.markKnown();
    }
    expect(served, ['b', 'c', 'd', 'e', 'a']);
  });

  test('unknown on the final card re-serves it immediately', () {
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

  test('servedPosition counts first presentations and holds on repeats', () {
    final q = _q(['a', 'b', 'c', 'd', 'e']);
    q.markUnknown(); // a 재삽입 → b,c,d,e,a
    expect(q.servedPosition, 2, reason: 'b는 두 번째로 처음 보는 카드다');
    q.markKnown(); // b 제거 → c,d,e,a
    expect(q.servedPosition, 3);
    q.markKnown(); // c 제거 → d,e,a
    expect(q.servedPosition, 4);
    q.markKnown(); // d 제거 → e,a
    expect(q.servedPosition, 5);
    q.markKnown(); // e 제거 → a; a는 재출제
    expect(q.current, 'a');
    expect(q.currentIsRepeat, isTrue);
    expect(q.servedPosition, 5, reason: '재출제는 고유 카드 수를 늘리지 않는다');
    expect(q.uniqueTotal, 5);
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

  test(
    'repeated markUnknown visits every unique card before the first repeat',
    () {
      final words = List.generate(8, (i) => 'w${i + 1}');
      final q = _q(words);
      final served = <String>[];

      for (var i = 0; i < words.length; i++) {
        served.add(q.current!);
        expect(q.servedPosition, i + 1);
        expect(q.markUnknown(), LearnAnswerOutcome.requeued);
      }

      expect(served, words);
      expect(q.current, 'w1');
      expect(q.currentIsRepeat, isTrue);
      expect(q.servedPosition, words.length);
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

  // ── §P2-4 defer() + peekNext ──────────────────────────────────────────

  test('defer moves the card to the tail without counting a miss', () {
    final q = _q(['a', 'b', 'c', 'd', 'e']);
    expect(q.defer(), LearnAnswerOutcome.deferred);
    // 스킵한 a는 아직 보지 않은 카드 전체가 나온 뒤 다시 서빙된다.
    final served = <String>[];
    while (!q.isDone) {
      served.add(q.current!);
      q.markKnown();
    }
    expect(served, ['b', 'c', 'd', 'e', 'a']);
  });

  test(
    'defer x10 never graduates, visits both cards, and keeps uniqueTotal',
    () {
      final q = _q(['a', 'b']);
      final served = <String>[];
      for (var i = 0; i < 10; i++) {
        served.add(q.current!);
        expect(q.defer(), LearnAnswerOutcome.deferred);
        expect(q.isDone, isFalse, reason: 'defer 는 큐를 비우지 않는다');
      }
      expect(served, ['a', 'b', 'a', 'b', 'a', 'b', 'a', 'b', 'a', 'b']);
      expect(q.missesOf('a'), 0);
      expect(q.missesOf('b'), 0);
      expect(q.uniqueTotal, 2);
      expect(q.servedPosition, 2);
    },
  );

  test('repeated defer visits every unique card before the first repeat', () {
    final words = List.generate(8, (i) => 'w${i + 1}');
    final q = _q(words);
    final served = <String>[];

    for (var i = 0; i < words.length; i++) {
      served.add(q.current!);
      expect(q.servedPosition, i + 1);
      q.defer();
    }

    expect(served, words);
    expect(q.current, 'w1');
    expect(q.currentIsRepeat, isTrue);
    expect(q.servedPosition, words.length);
  });

  test('defer on a single-card queue re-serves the same card', () {
    final q = _q(['a']);
    expect(q.defer(), LearnAnswerOutcome.deferred);
    expect(q.current, 'a');
    expect(q.isDone, isFalse);
  });

  test('peekNext exposes the second card only', () {
    final two = _q(['a', 'b']);
    expect(two.peekNext, 'b');
    final one = _q(['a']);
    expect(one.peekNext, isNull);
    final zero = _q([]);
    expect(zero.peekNext, isNull);
    // defer 뒤에도 peekNext 는 재배치된 큐를 그대로 반영한다.
    final q = _q(['a', 'b', 'c', 'd', 'e']);
    q.defer(); // → b,c,d,a,e
    expect(q.current, 'b');
    expect(q.peekNext, 'c');
  });

  // ── currentIsRepeat (지시서 1.1 보강 — 재출제 칩) ─────────────────────

  test('첫 서빙은 재출제가 아니다', () {
    final q = _q(['a', 'b', 'c']);
    expect(q.currentIsRepeat, isFalse);
  });

  test('markUnknown 이후 재삽입된 카드가 다시 나오면 재출제다', () {
    final q = _q(['a', 'b', 'c', 'd', 'e']);
    q.markUnknown(); // a 재삽입 → b,c,d,e,a. 지금 current 는 b(최초 서빙).
    expect(q.currentIsRepeat, isFalse);
    q.markKnown(); // b 제거 → c,d,e,a
    q.markKnown(); // c 제거 → d,e,a
    q.markKnown(); // d 제거 → e,a
    q.markKnown(); // e 제거 → a — a 가 다시 current
    expect(q.currentIsRepeat, isTrue);
  });

  test('defer 로 재배치된 카드도 재출제로 표시된다', () {
    final q = _q(['a', 'b']);
    q.defer(); // a 재삽입 → [b, a]
    expect(q.currentIsRepeat, isFalse); // 지금 current = b, 최초 서빙
    q.markKnown(); // b 제거 → [a]
    expect(q.currentIsRepeat, isTrue); // a 는 이미 한 번 서빙됨
  });

  test('큐가 비면 currentIsRepeat 은 false', () {
    final q = _q([]);
    expect(q.currentIsRepeat, isFalse);
  });
}
