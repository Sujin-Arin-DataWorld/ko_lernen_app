import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/review_session_queue.dart';

void main() {
  group('ReviewSessionQueue', () {
    test('serves actual history without changing pending order', () {
      final queue = _queue(const [_Item('a'), _Item('b')]);

      expect(queue.current?.id, 'a');
      expect(queue.servedPosition, 1);
      expect(queue.originalCount, 2);

      queue.recordJudgment(correct: false);
      expect(queue.current?.id, 'b');
      expect(queue.servedPosition, 2);

      queue.recordJudgment(correct: true);
      expect(queue.current?.id, 'a');
      expect(queue.servedPosition, 2);
      expect(queue.pendingCount, 0);

      expect(queue.previous(), isTrue);
      expect(queue.current?.id, 'b');
      expect(queue.previous(), isTrue);
      expect(queue.current?.id, 'a');
      expect(queue.pendingCount, 0);

      expect(queue.nextHistory(), isTrue);
      expect(queue.current?.id, 'b');
      expect(queue.nextHistory(), isTrue);
      expect(queue.current?.id, 'a');
      expect(queue.pendingCount, 0);
    });

    test('history browsing cannot judge or requeue an earlier card', () {
      final queue = _queue(const [_Item('a'), _Item('b'), _Item('c')]);

      queue.recordJudgment(correct: false);
      expect(queue.current?.id, 'b');
      expect(queue.pendingCount, 2);

      expect(queue.previous(), isTrue);
      expect(queue.current?.id, 'a');
      expect(queue.isBrowsingHistory, isTrue);
      expect(queue.canJudgeCurrent, isFalse);

      queue.recordJudgment(correct: false);
      expect(queue.current?.id, 'a');
      expect(queue.pendingCount, 2);
      expect(queue.isComplete, isFalse);

      expect(queue.nextHistory(), isTrue);
      expect(queue.current?.id, 'b');
      queue.recordJudgment(correct: true);
      expect(queue.current?.id, 'c');
      queue.recordJudgment(correct: true);
      expect(queue.current?.id, 'a');
      expect(queue.currentNeedsEvidence, isFalse);
      expect(queue.isComplete, isFalse);
      queue.recordJudgment(correct: true);
      expect(queue.isComplete, isTrue);
    });

    test(
      'each original is requeued at most once and evidence is first-only',
      () {
        final queue = _queue(const [_Item('a'), _Item('b')]);

        expect(queue.currentNeedsEvidence, isTrue);
        queue.recordJudgment(correct: false);
        expect(queue.current?.id, 'b');

        expect(queue.currentNeedsEvidence, isTrue);
        queue.recordJudgment(correct: false);
        expect(queue.current?.id, 'a');

        expect(queue.currentNeedsEvidence, isFalse);
        queue.recordJudgment(correct: false);
        expect(queue.current?.id, 'b');
        expect(queue.isComplete, isFalse);

        expect(queue.currentNeedsEvidence, isFalse);
        queue.recordJudgment(correct: false);
        expect(queue.isComplete, isTrue);
        expect(queue.pendingCount, 0);
      },
    );

    test(
      'deduplicates originals and completes only after pending exhausts',
      () {
        final queue = _queue(const [
          _Item('a'),
          _Item('a', label: 'duplicate'),
          _Item('b'),
        ]);

        expect(queue.originalCount, 2);
        expect(queue.servedPosition, 1);
        expect(queue.isComplete, isFalse);

        queue.recordJudgment(correct: true);
        expect(queue.current?.id, 'b');
        expect(queue.servedPosition, 2);
        expect(queue.isComplete, isFalse);

        queue.recordJudgment(correct: true);
        expect(queue.isComplete, isTrue);
      },
    );

    test('defer serves the next card without recording evidence', () {
      final queue = _queue(const [_Item('a'), _Item('b')]);

      expect(queue.currentNeedsEvidence, isTrue);
      expect(queue.defer(), isTrue);
      expect(queue.current?.id, 'b');
      expect(queue.servedPosition, 1);
      expect(queue.currentNeedsEvidence, isTrue);

      queue.recordJudgment(correct: true);
      expect(queue.current?.id, 'a');
      expect(queue.currentNeedsEvidence, isTrue);
    });
  });
}

ReviewSessionQueue<_Item> _queue(List<_Item> items) {
  return ReviewSessionQueue<_Item>(items, idOf: (item) => item.id);
}

final class _Item {
  const _Item(this.id, {this.label = ''});

  final String id;
  final String label;
}
