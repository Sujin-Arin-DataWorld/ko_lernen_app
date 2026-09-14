// PR S3 (진행도 쓰기 디바운스) — PackSyncQueue 계약.
//
// `PackProgressService._persist` 는 예전엔 `recordWordLearned` /
// `recordBossAttempt` 호출마다 Firestore `savePack` 을 fire-and-forget 했다
// (1k DAU 기준 추산 ~90k ops/day). 이 큐는 packId 당 최신 상태만 들고 있다가
// 세 트리거(상태 전이, 30초 유휴, flushAll) 중 가장 먼저 오는 걸로만 저장한다.
//
// fake_async 로 유휴 타이머를 실제로 30초 기다리지 않고 검증한다.

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/pack_progress.dart';
import 'package:ko_lernen_app/services/diagnostics_service.dart';
import 'package:ko_lernen_app/services/pack_sync_queue.dart';

void main() {
  tearDown(DiagnosticsService.resetForTesting);

  PackProgress progress(
    String packId, {
    PackStatus status = PackStatus.inProgress,
    int wordsLearned = 0,
  }) => PackProgress(
    packId: packId,
    level: 'A1',
    status: status,
    wordsLearned: wordsLearned,
    wordsTotal: 10,
    bossAccuracy: 0.0,
    attempts: 0,
    clearedAtIso: null,
  );

  test(
    '30 enqueues of the same pack within 10s → 0 saves until 30s idle → '
    'exactly 1 save with the last state',
    () {
      fakeAsync((async) {
        final saved = <PackProgress>[];
        final queue = PackSyncQueue(
          savePack: (p) async {
            saved.add(p);
          },
        );

        for (var i = 0; i < 30; i++) {
          queue.enqueue(
            progress('a1_greetings_1', status: PackStatus.inProgress, wordsLearned: i),
          );
          async.elapse(const Duration(milliseconds: 300));
        }
        // 30 * 300ms = 9s elapsed — well under the 30s idle window, and
        // every enqueue restarts the idle timer, so nothing should have
        // flushed yet.
        expect(saved, isEmpty);

        // Idle window elapses after the last enqueue.
        async.elapse(const Duration(seconds: 30));

        expect(saved, hasLength(1));
        expect(saved.single.packId, 'a1_greetings_1');
        expect(saved.single.wordsLearned, 29);
      });
    },
  );

  test('status change learning→cleared flushes immediately', () {
    fakeAsync((async) {
      final saved = <PackProgress>[];
      final queue = PackSyncQueue(
        savePack: (p) async {
          saved.add(p);
        },
      );

      queue.enqueue(progress('a1_greetings_1', status: PackStatus.inProgress));
      async.elapse(const Duration(milliseconds: 100));
      expect(saved, isEmpty, reason: 'first-ever state is not a transition');

      queue.enqueue(progress('a1_greetings_1', status: PackStatus.cleared));
      // Transition triggers flush() which is async — pump the microtask
      // queue without advancing the idle timer.
      async.flushMicrotasks();

      expect(saved, hasLength(1));
      expect(saved.single.status, PackStatus.cleared);
    });
  });

  test('flushAll() on paused saves immediately without waiting for idle', () {
    fakeAsync((async) {
      final saved = <PackProgress>[];
      final queue = PackSyncQueue(
        savePack: (p) async {
          saved.add(p);
        },
      );

      queue.enqueue(progress('a1_greetings_1'));
      async.elapse(const Duration(seconds: 1));
      expect(saved, isEmpty);

      queue.flushAll();
      async.flushMicrotasks();

      expect(saved, hasLength(1));
    });
  });

  test(
    'a save failure keeps the entry queued, reports once, and retries on '
    'the next trigger',
    () {
      fakeAsync((async) {
        final sink = _RecordingSink();
        DiagnosticsService.configureForTesting(sink: sink, consent: () => true);
        var attempts = 0;
        final saved = <PackProgress>[];
        final queue = PackSyncQueue(
          savePack: (p) async {
            attempts += 1;
            if (attempts == 1) {
              throw StateError('firestore unavailable');
            }
            saved.add(p);
          },
        );

        queue.enqueue(progress('a1_greetings_1'));
        queue.flushAll();
        async.flushMicrotasks();

        // First attempt failed — nothing saved yet, but swallowed+reported.
        expect(saved, isEmpty);
        expect(attempts, 1);
        expect(sink.recordedErrors, hasLength(1));
        expect(sink.recordedErrors.single.$1, 'pack_sync_queue.flush');

        // Entry must still be queued — retried on the next trigger.
        expect(queue.pendingCount, 1);
        queue.flushAll();
        async.flushMicrotasks();

        expect(attempts, 2);
        expect(saved, hasLength(1));
        expect(queue.pendingCount, 0);
        // Still reported only once even though flush ran twice — the
        // second (successful) attempt never called recordNonFatal again.
        expect(sink.recordedErrors, hasLength(1));
      });
    },
  );

  test('two different packs → 2 saves', () {
    fakeAsync((async) {
      final saved = <PackProgress>[];
      final queue = PackSyncQueue(
        savePack: (p) async {
          saved.add(p);
        },
      );

      queue.enqueue(progress('a1_greetings_1'));
      queue.enqueue(progress('a1_greetings_2'));
      async.elapse(const Duration(seconds: 30));

      expect(saved, hasLength(2));
      expect(saved.map((p) => p.packId).toSet(), {
        'a1_greetings_1',
        'a1_greetings_2',
      });
    });
  });
}

class _RecordingSink implements DiagnosticsSink {
  final recordedErrors = <(String, Object, StackTrace)>[];

  @override
  Future<void> log(String message) async {}

  @override
  Future<void> setCustomKey(String key, String value) async {}

  @override
  Future<void> recordNonFatal(
    String scope,
    Object error,
    StackTrace stackTrace,
  ) async => recordedErrors.add((scope, error, stackTrace));
}
