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
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/models/pack_progress.dart';
import 'package:ko_lernen_app/services/diagnostics_service.dart';
import 'package:ko_lernen_app/services/pack_sync_queue.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    Storage.resetPackProgressForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });
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
          canMirror: () => true,
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
        canMirror: () => true,
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
        canMirror: () => true,
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
          canMirror: () => true,
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
        canMirror: () => true,
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

  // ── R2/R4 durability review — gap A: cold-start immediate flush ──────
  //
  // A fresh PackSyncQueue (as after a process restart) has no in-memory
  // history for any packId. The original `previousStatus != null && ...`
  // check treated that as "not a transition", so a pack that was `cleared`
  // right after a cold start wasted the full 30s idle window instead of
  // flushing immediately — and if the process died in that window, the
  // Firestore doc driving server-side Gye crediting / cross-device restore
  // never got the `cleared` state at all.

  test(
    'R2/R4: fresh queue, first-ever enqueue with a terminal (cleared) '
    'status flushes immediately even with no prior status known',
    () {
      fakeAsync((async) {
        final saved = <PackProgress>[];
        final queue = PackSyncQueue(
          canMirror: () => true,
          savePack: (p) async {
            saved.add(p);
          },
        );

        // No Storage entry at all for this packId — genuinely first-ever.
        queue.enqueue(progress('a1_new_pack', status: PackStatus.cleared));
        async.flushMicrotasks();

        expect(saved, hasLength(1));
        expect(saved.single.status, PackStatus.cleared);
      });
    },
  );

  test(
    'R2/R4: fresh queue, first-ever enqueue matching the persisted status '
    'takes the idle path (no immediate flush)',
    () async {
      await Storage.setPackProgressJson(
        'a1_greetings_1',
        progress('a1_greetings_1', status: PackStatus.inProgress).toJson(),
      );

      fakeAsync((async) {
        final saved = <PackProgress>[];
        final queue = PackSyncQueue(
          canMirror: () => true,
          savePack: (p) async {
            saved.add(p);
          },
        );

        queue.enqueue(progress('a1_greetings_1', status: PackStatus.inProgress));
        async.flushMicrotasks();

        expect(
          saved,
          isEmpty,
          reason: 'unchanged vs. what Storage already had → idle debounce',
        );
      });
    },
  );

  test(
    'R2/R4: fresh queue, first-ever enqueue that differs from the '
    'persisted status flushes immediately (any change vs. persisted)',
    () async {
      await Storage.setPackProgressJson(
        'a1_greetings_1',
        progress('a1_greetings_1', status: PackStatus.cleared).toJson(),
      );

      fakeAsync((async) {
        final saved = <PackProgress>[];
        final queue = PackSyncQueue(
          canMirror: () => true,
          savePack: (p) async {
            saved.add(p);
          },
        );

        // The queue itself has no in-memory history — only Storage does —
        // yet this must still be treated as a change and flush immediately.
        queue.enqueue(
          progress('a1_greetings_1', status: PackStatus.inProgress),
        );
        async.flushMicrotasks();

        expect(saved, hasLength(1));
        expect(saved.single.status, PackStatus.inProgress);
      });
    },
  );

  // ── R2/R4 durability review — gap B: survive a kill, not just 30s ────
  //
  // The queue was in-memory only: a process kill before any trigger fired
  // lost the pending write outright, with no way to recover it even at the
  // next launch. Storage.pendingPackSyncIds now mirrors the pending set so
  // flushPendingFromStorage() can pick it back up.

  test(
    'R2/R4: a kill before any trigger fires leaves the id in '
    'Storage.pendingPackSyncIds; flushPendingFromStorage() recovers it',
    () async {
      await Storage.setPackProgressJson(
        'a1_greetings_1',
        progress('a1_greetings_1', status: PackStatus.inProgress).toJson(),
      );
      final queue1 = PackSyncQueue(
        canMirror: () => true,
        savePack: (p) async {
          fail(
            'queue1 must never actually flush — it is abandoned here to '
            'simulate a process kill before its idle timer fires',
          );
        },
      );

      // Matches what's already in Storage → idle path only, no immediate
      // flush — exactly the case where a kill would otherwise lose it.
      queue1.enqueue(progress('a1_greetings_1', status: PackStatus.inProgress));
      // enqueue()'s Storage.setPendingPackSyncIds write is fire-and-forget;
      // give it a turn of the event loop before reading Storage back.
      await Future<void>.delayed(Duration.zero);
      expect(Storage.pendingPackSyncIds, contains('a1_greetings_1'));

      // "Restart": a brand-new queue instance, as after a cold start — it
      // has zero in-memory knowledge of queue1's abandoned pending entry.
      final saved = <PackProgress>[];
      final queue2 = PackSyncQueue(
        canMirror: () => true,
        savePack: (p) async {
          saved.add(p);
        },
      );
      await queue2.flushPendingFromStorage();

      expect(saved, hasLength(1));
      expect(saved.single.packId, 'a1_greetings_1');
      expect(
        Storage.pendingPackSyncIds,
        isEmpty,
        reason: 'a successful recovery clears the id',
      );
    },
  );

  test(
    'R2/R4: a failed flush keeps the id in Storage.pendingPackSyncIds for '
    'the next trigger',
    () async {
      DiagnosticsService.configureForTesting(consent: () => false);
      addTearDown(DiagnosticsService.resetForTesting);
      await Storage.setPackProgressJson(
        'a1_greetings_1',
        progress('a1_greetings_1', status: PackStatus.inProgress).toJson(),
      );
      var attempts = 0;
      final queue = PackSyncQueue(
        canMirror: () => true,
        savePack: (p) async {
          attempts += 1;
          throw StateError('firestore unavailable');
        },
      );

      // Terminal status → enqueue() kicks off an unawaited flush(); a
      // second, public flush() call while that's in flight returns the same
      // future, so awaiting it here waits for that same attempt to finish.
      queue.enqueue(progress('a1_greetings_1', status: PackStatus.cleared));
      await queue.flush();

      expect(attempts, 1);
      expect(Storage.pendingPackSyncIds, contains('a1_greetings_1'));
    },
  );
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
