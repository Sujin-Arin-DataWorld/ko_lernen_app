import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/access_snapshot_controller.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';

Map<String, dynamic> snapshot({
  String uid = 'a',
  int now = 172800000,
  String environment = 'PRODUCTION',
  String source = 'subscription',
}) => {
  'schemaVersion': 1,
  'ownerUid': uid,
  'environment': environment,
  'revision': 'a' * 64,
  'source': source,
  'contentAccess': source == 'free' ? 'a1' : 'all',
  'aiPolicyId': source == 'free' || source == 'free_launch'
      ? 'free_v1'
      : 'premium_v1',
  'bookDailyLimit': source == 'free' || source == 'free_launch' ? 3 : 20,
  'pronunciationDailyLimit': source == 'free' || source == 'free_launch'
      ? 5
      : 50,
  'serverNow': now,
  'accessUntil': source == 'subscription' ? now + 86400000 : null,
  'offlineUntil': source == 'subscription'
      ? now + 86400000
      : source == 'closed_tester_lifetime'
      ? now + 30 * 86400000
      : now,
  'nextResetAt': (now ~/ 86400000 + 1) * 86400000,
};

void main() {
  late CloudWriteSessionController sessions;
  late AccessSnapshotController controller;
  late MemoryAccessSnapshotStore store;
  late int wall;
  late int elapsed;
  setUp(() {
    sessions = CloudWriteSessionController()..acquire('a');
    store = MemoryAccessSnapshotStore();
    wall = 172800000;
    elapsed = 0;
  });
  void create(Future<Map<String, dynamic>> Function() fetch) {
    controller = AccessSnapshotController(
      sessions: sessions,
      store: store,
      environment: 'PRODUCTION',
      fetch: fetch,
      wallMillis: () => wall,
      elapsedMillis: () => elapsed,
    );
  }

  tearDown(() => controller.dispose());

  test(
    'server resolves free-launch content without claiming premium AI',
    () async {
      create(() async => snapshot(source: 'free_launch'));
      await controller.refresh();
      expect(controller.snapshot?.hasAllContent, isTrue);
      expect(controller.snapshot?.hasPremium, isFalse);
      expect(controller.snapshot?.bookDailyLimit, 3);
    },
  );
  test(
    'UID and non-ready epoch synchronously invalidate cached access',
    () async {
      create(() async => snapshot());
      await controller.refresh();
      expect(controller.snapshot?.hasPremium, isTrue);
      sessions.transition(CloudWriteMode.quiesced);
      expect(controller.snapshot, isNull);
    },
  );
  test('late same-UID old-epoch response cannot repopulate access', () async {
    final response = Completer<Map<String, dynamic>>();
    create(() => response.future);
    final pending = controller.refresh();
    sessions.acquire('a');
    response.complete(snapshot());
    await pending;
    expect(controller.snapshot, isNull);
    expect(store.read(), isNull);
  });
  test('wrong UID or environment response fails closed', () async {
    create(() async => snapshot(uid: 'other', environment: 'SANDBOX'));
    await controller.refresh();
    expect(controller.snapshot, isNull);
  });
  test(
    'offline lease expires at subscription expiry without touching progress',
    () async {
      create(() async => snapshot());
      await controller.refresh();
      wall += 86400000;
      elapsed += 86400000;
      expect(controller.snapshot, isNull);
    },
  );
  test(
    'wall rollback fails closed even when monotonic timer advances',
    () async {
      create(() async => snapshot());
      await controller.refresh();
      wall--;
      elapsed++;
      expect(controller.snapshot, isNull);
    },
  );
  test('older concurrent response cannot replace a newer revision', () async {
    final first = Completer<Map<String, dynamic>>();
    var count = 0;
    create(
      () =>
          ++count == 1 ? first.future : Future.value(snapshot(now: 172800010)),
    );
    final older = controller.refresh();
    await controller.refresh();
    first.complete(snapshot());
    await older;
    expect(controller.snapshot?.serverNow, 172800010);
  });
  test(
    'valid same UID epoch cache survives restart but legacy boolean cannot grant',
    () async {
      create(() async => snapshot());
      await controller.refresh();
      await Future<void>.delayed(Duration.zero);
      controller.dispose();
      wall += 1000;
      elapsed = 0;
      create(() async => throw StateError('offline'));
      await controller.refresh();
      expect(controller.snapshot?.hasPremium, isTrue);
      controller.dispose();
      store.value = 'true';
      create(() async => throw StateError('offline'));
      expect(controller.snapshot, isNull);
    },
  );
  test(
    'persisted revision UID environment and schema cannot be swapped',
    () async {
      create(() async => snapshot());
      await controller.refresh();
      await Future<void>.delayed(Duration.zero);
      final valid = store.value!;
      for (final mutation in <void Function(Map<String, dynamic>)>[
        (record) => record['epoch'] = 999,
        (record) => record['revision'] = 'b' * 64,
        (record) => (record['snapshot'] as Map)['ownerUid'] = 'b',
        (record) => (record['snapshot'] as Map)['environment'] = 'SANDBOX',
        (record) => (record['snapshot'] as Map)['schemaVersion'] = 2,
      ]) {
        controller.dispose();
        final record = jsonDecode(valid) as Map<String, dynamic>;
        mutation(record);
        store.value = jsonEncode(record);
        create(() async => throw StateError('offline'));
        expect(controller.snapshot, isNull);
        await Future<void>.delayed(Duration.zero);
      }
    },
  );
  test(
    'persisted wall-clock high water rejects rollback after restart',
    () async {
      create(() async => snapshot());
      await controller.refresh();
      wall += 1000;
      elapsed += 1000;
      controller.checkpoint();
      await Future<void>.delayed(Duration.zero);
      controller.dispose();
      wall -= 1;
      elapsed = 0;
      create(() async => throw StateError('offline'));
      expect(controller.snapshot, isNull);
    },
  );
  test(
    'tester offline lease expires at 30 days without server downgrade grant',
    () async {
      create(() async => snapshot(source: 'closed_tester_lifetime'));
      await controller.refresh();
      wall += 30 * 86400000 - 1;
      elapsed = 30 * 86400000 - 1;
      expect(controller.snapshot?.hasPremium, isTrue);
      wall++;
      elapsed++;
      expect(controller.snapshot, isNull);
    },
  );
  test('account deletion clear invalidates snapshot synchronously', () async {
    create(() async => snapshot());
    await controller.refresh();
    sessions.clear();
    expect(controller.snapshot, isNull);
    await Future<void>.delayed(Duration.zero);
    expect(store.read(), isNull);
  });
}
