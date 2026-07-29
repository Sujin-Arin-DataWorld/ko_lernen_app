import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/book_image_service.dart';
import 'package:ko_lernen_app/services/crop_recovery_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CropGateway implements CropRecoveryGateway {
  _CropGateway({this.path, this.error});

  final String? path;
  final Object? error;
  int calls = 0;

  @override
  Future<String?> recoverImagePath() async {
    calls++;
    if (error != null) {
      throw error!;
    }
    return path;
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
    CropRecoveryService.resetForTesting();
    await Storage.init();
  });

  tearDown(CropRecoveryService.resetForTesting);

  test(
    'surviving Android crop clears strict marker then plugin cache',
    () async {
      final events = <String>[];
      final session = BookCropSession(
        isAndroid: true,
        markLaunch: (workflowId) async => events.add('mark:$workflowId'),
        clearLaunch: () async => events.add('clear-marker'),
        clearCachedResult: () async => events.add('clear-cache'),
      );

      final result = await session.run(
        workflowId: 'book-flow',
        crop: () async {
          events.add('crop');
          return 'cropped';
        },
        acceptAndRecord: (result) async {
          events.add('accept:$result');
          return 'accepted:$result';
        },
      );

      expect(result, 'accepted:cropped');
      expect(events, [
        'clear-cache',
        'mark:book-flow',
        'crop',
        'accept:cropped',
        'clear-marker',
        'clear-cache',
      ]);
    },
  );

  test(
    'null crop still clears cache while crop exception preserves marker',
    () async {
      final nullEvents = <String>[];
      final nullSession = BookCropSession(
        isAndroid: true,
        markLaunch: (_) async => nullEvents.add('mark'),
        clearLaunch: () async => nullEvents.add('clear-marker'),
        clearCachedResult: () async => nullEvents.add('clear-cache'),
      );
      expect(
        await nullSession.run<String, String>(
          workflowId: 'book-flow',
          crop: () async => null,
          acceptAndRecord: (result) async => result,
        ),
        isNull,
      );
      expect(nullEvents, [
        'clear-cache',
        'mark',
        'clear-marker',
        'clear-cache',
      ]);

      final failureEvents = <String>[];
      final failureSession = BookCropSession(
        isAndroid: true,
        markLaunch: (_) async => failureEvents.add('mark'),
        clearLaunch: () async => failureEvents.add('clear-marker'),
        clearCachedResult: () async => failureEvents.add('clear-cache'),
      );
      await expectLater(
        failureSession.run<String, String>(
          workflowId: 'book-flow',
          crop: () async => throw StateError('crop failed'),
          acceptAndRecord: (result) async => result,
        ),
        throwsStateError,
      );
      expect(failureEvents, ['clear-cache', 'mark']);
    },
  );

  test(
    'strict marker-clear failure leaves new recoverable cache untouched',
    () async {
      var cacheDrains = 0;
      final session = BookCropSession(
        isAndroid: true,
        markLaunch: (_) async {},
        clearLaunch: () async => throw StateError('preference failure'),
        clearCachedResult: () async => cacheDrains++,
      );

      await expectLater(
        session.run(
          workflowId: 'book-flow',
          crop: () async => 'cropped',
          acceptAndRecord: (result) async => result,
        ),
        throwsStateError,
      );

      expect(cacheDrains, 1);
    },
  );

  test('failed stale-cache pre-drain aborts before marking or crop', () async {
    final events = <String>[];
    final session = BookCropSession(
      isAndroid: true,
      markLaunch: (_) async => events.add('mark'),
      clearLaunch: () async => events.add('clear-marker'),
      clearCachedResult: () async {
        events.add('pre-drain');
        throw StateError('cache failure');
      },
    );

    await expectLater(
      session.run(
        workflowId: 'book-flow',
        crop: () async {
          events.add('crop');
          return 'cropped';
        },
        acceptAndRecord: (result) async => result,
      ),
      throwsStateError,
    );

    expect(events, ['pre-drain']);
  });

  test('pending journal blocks a new crop before cache pre-drain', () async {
    final events = <String>[];
    final session = BookCropSession(
      isAndroid: true,
      ensureCanLaunch: () async {
        events.add('guard');
        throw StateError('recovery pending');
      },
      markLaunch: (_) async => events.add('mark'),
      clearLaunch: () async => events.add('clear-marker'),
      clearCachedResult: () async => events.add('clear-cache'),
    );

    await expectLater(
      session.run(
        workflowId: 'new-attempt',
        crop: () async {
          events.add('crop');
          return 'cropped';
        },
        acceptAndRecord: (result) async => result,
      ),
      throwsStateError,
    );

    expect(events, ['guard']);
  });

  test(
    'crop acceptance failure preserves marker cache and picked raw lease',
    () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'crop_accept_failure_',
      );
      addTearDown(() async => sandbox.delete(recursive: true));
      final docs = Directory('${sandbox.path}${Platform.pathSeparator}docs')
        ..createSync();
      final cache = Directory('${sandbox.path}${Platform.pathSeparator}cache')
        ..createSync();
      final raw = File('${sandbox.path}${Platform.pathSeparator}raw.jpg')
        ..writeAsBytesSync([1, 2]);
      final cachedCrop = File(
        '${cache.path}${Platform.pathSeparator}cropped.jpg',
      )..writeAsBytesSync([3, 4]);
      final store = ManagedMediaStore(
        documentsDirectory: docs,
        temporaryDirectory: cache,
        nonce: () => 'accept_failure',
      );
      final rawLease = await store.stage(raw, ManagedMediaKind.book);
      await Storage.setRecoveredBookLease(
        RecoveredBookDraft(
          workflowId: 'picked-flow',
          lease: rawLease,
          phase: RecoveredBookPhase.picked,
        ).encoded,
      );
      var cacheDrains = 0;
      final session = BookCropSession(
        isAndroid: true,
        markLaunch: (workflowId) =>
            Storage.markCropLaunch(workflowId: workflowId),
        clearLaunch: Storage.clearCropLaunch,
        clearCachedResult: () async => cacheDrains++,
      );

      await expectLater(
        session.run(
          workflowId: 'new-flow',
          crop: () async => cachedCrop.path,
          acceptAndRecord: (path) => acceptBookCrop(
            path: path,
            workflowId: 'new-flow',
            mediaStore: store,
            persistRecoveredBook: (_) async =>
                throw StateError('preference failure'),
          ),
        ),
        throwsStateError,
      );

      expect(cacheDrains, 1);
      expect(Storage.cropRecoveryMarkerJson, contains('new-flow'));
      expect(
        RecoveredBookDraft.tryParse(Storage.recoveredBookLease)?.lease.encoded,
        rawLease.encoded,
      );
      expect(await store.resolvePending(rawLease), isNotNull);
      expect(await cachedCrop.exists(), isTrue);
    },
  );

  test(
    'accepted crop is durably recorded before recovery signals clear',
    () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'crop_accept_success_',
      );
      addTearDown(() async => sandbox.delete(recursive: true));
      final docs = Directory('${sandbox.path}${Platform.pathSeparator}docs')
        ..createSync();
      final cache = Directory('${sandbox.path}${Platform.pathSeparator}cache')
        ..createSync();
      final cropped = File('${cache.path}${Platform.pathSeparator}cropped.jpg');
      final store = ManagedMediaStore(
        documentsDirectory: docs,
        temporaryDirectory: cache,
        nonce: () => 'accept_success',
      );
      final session = BookCropSession(
        isAndroid: true,
        markLaunch: (workflowId) =>
            Storage.markCropLaunch(workflowId: workflowId),
        clearLaunch: () async {
          final record = RecoveredBookDraft.tryParse(
            Storage.recoveredBookLease,
          );
          expect(record?.phase, RecoveredBookPhase.cropped);
          await Storage.clearCropLaunch();
        },
        clearCachedResult: () async {
          if (await cropped.exists()) {
            await cropped.delete();
          }
        },
      );

      final accepted = await session.run(
        workflowId: 'book-success',
        crop: () async {
          await cropped.writeAsBytes([5, 6]);
          return cropped.path;
        },
        acceptAndRecord: (path) => acceptBookCrop(
          path: path,
          workflowId: 'book-success',
          mediaStore: store,
        ),
      );

      expect(accepted, isNotNull);
      expect(Storage.cropRecoveryMarkerJson, isEmpty);
      expect(
        RecoveredBookDraft.tryParse(Storage.recoveredBookLease)?.lease.encoded,
        accepted?.lease.encoded,
      );
      expect(await store.resolvePending(accepted!.lease), isNotNull);
      expect(await cropped.exists(), isFalse);
    },
  );

  test('iOS and web session path never uses Android marker or cache', () async {
    final events = <String>[];
    final session = BookCropSession(
      isAndroid: false,
      markLaunch: (_) async => events.add('mark'),
      clearLaunch: () async => events.add('clear-marker'),
      clearCachedResult: () async => events.add('clear-cache'),
    );

    expect(
      await session.run(
        workflowId: 'book-flow',
        crop: () async {
          events.add('crop');
          return 'cropped';
        },
        acceptAndRecord: (result) async {
          events.add('accept:$result');
          return 'accepted:$result';
        },
      ),
      'accepted:cropped',
    );
    expect(events, ['crop', 'accept:cropped']);
  });

  test(
    'startup recovers marked crop exactly once into pending book record',
    () async {
      final sandbox = await Directory.systemTemp.createTemp('crop_recovery_');
      addTearDown(() async => sandbox.delete(recursive: true));
      final docs = Directory('${sandbox.path}${Platform.pathSeparator}docs')
        ..createSync();
      final cache = Directory('${sandbox.path}${Platform.pathSeparator}cache')
        ..createSync();
      final recovered = File(
        '${cache.path}${Platform.pathSeparator}cropped.jpg',
      )..writeAsBytesSync([1, 2, 3]);
      final store = ManagedMediaStore(
        documentsDirectory: docs,
        temporaryDirectory: cache,
        nonce: () => 'crop',
      );
      final gateway = _CropGateway(path: recovered.path);
      await Storage.markCropLaunch(workflowId: 'book-flow');

      await Future.wait([
        CropRecoveryService.recoverAtStartup(
          isAndroid: true,
          gateway: gateway,
          mediaStore: store,
        ),
        CropRecoveryService.recoverAtStartup(
          isAndroid: true,
          gateway: gateway,
          mediaStore: store,
        ),
      ]);

      expect(gateway.calls, 1);
      expect(Storage.cropRecoveryMarkerJson, isEmpty);
      expect(Storage.recoveredBookLease, contains('book-flow'));
      final record = RecoveredBookDraft.tryParse(Storage.recoveredBookLease);
      expect(record?.phase, RecoveredBookPhase.cropped);
      expect(await recovered.exists(), isFalse);
      final pending = await Directory(
        '${store.root.path}${Platform.pathSeparator}pending',
      ).list().toList();
      expect(pending, hasLength(1));
    },
  );

  test(
    'startup record failure reconnects deterministic journal next launch',
    () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'crop_startup_write_failure_',
      );
      addTearDown(() async => sandbox.delete(recursive: true));
      final docs = Directory('${sandbox.path}${Platform.pathSeparator}docs')
        ..createSync();
      final cache = Directory('${sandbox.path}${Platform.pathSeparator}cache')
        ..createSync();
      final recovered = File(
        '${cache.path}${Platform.pathSeparator}cropped.jpg',
      )..writeAsBytesSync([9, 8, 7]);
      final store = ManagedMediaStore(
        documentsDirectory: docs,
        temporaryDirectory: cache,
        nonce: () => 'startup_failure',
      );
      await Storage.markCropLaunch(workflowId: 'book-retry');

      await CropRecoveryService.recoverAtStartup(
        isAndroid: true,
        gateway: _CropGateway(path: recovered.path),
        mediaStore: store,
        persistRecoveredBook: (_) async =>
            throw StateError('preference failure'),
      );

      expect(Storage.cropRecoveryMarkerJson, contains('book-retry'));
      expect(Storage.recoveredBookLease, isEmpty);
      expect(await recovered.readAsBytes(), [9, 8, 7]);
      var pending = await Directory(
        '${store.root.path}${Platform.pathSeparator}pending',
      ).list().toList();
      expect(pending, hasLength(1));
      final journal = await store.findRecoveredCrop('book-retry');
      expect(journal, isNotNull);

      CropRecoveryService.resetForTesting();
      final secondGateway = _CropGateway();
      await CropRecoveryService.recoverAtStartup(
        isAndroid: true,
        gateway: secondGateway,
        mediaStore: store,
      );

      expect(secondGateway.calls, 1);
      expect(Storage.cropRecoveryMarkerJson, isEmpty);
      final record = RecoveredBookDraft.tryParse(Storage.recoveredBookLease);
      expect(record?.phase, RecoveredBookPhase.cropped);
      expect(record?.lease.encoded, journal?.encoded);
      pending = await Directory(
        '${store.root.path}${Platform.pathSeparator}pending',
      ).list().toList();
      expect(pending, hasLength(1));
    },
  );

  test(
    'marker-clear failure retries the same journal without duplication',
    () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'crop_marker_failure_',
      );
      addTearDown(() async => sandbox.delete(recursive: true));
      final docs = Directory('${sandbox.path}${Platform.pathSeparator}docs')
        ..createSync();
      final cache = Directory('${sandbox.path}${Platform.pathSeparator}cache')
        ..createSync();
      final recovered = File(
        '${cache.path}${Platform.pathSeparator}cropped.jpg',
      )..writeAsBytesSync([2, 4, 6]);
      final store = ManagedMediaStore(
        documentsDirectory: docs,
        temporaryDirectory: cache,
        nonce: () => 'marker_failure',
      );
      await Storage.markCropLaunch(workflowId: 'marker-retry');

      await expectLater(
        CropRecoveryService.recoverAtStartup(
          isAndroid: true,
          gateway: _CropGateway(path: recovered.path),
          mediaStore: store,
          clearMarker: () async => throw StateError('remove failure'),
        ),
        throwsStateError,
      );
      final firstRecord = RecoveredBookDraft.tryParse(
        Storage.recoveredBookLease,
      );
      expect(firstRecord?.phase, RecoveredBookPhase.cropped);
      expect(Storage.cropRecoveryMarkerJson, contains('marker-retry'));

      CropRecoveryService.resetForTesting();
      await CropRecoveryService.recoverAtStartup(
        isAndroid: true,
        gateway: _CropGateway(),
        mediaStore: store,
      );

      final secondRecord = RecoveredBookDraft.tryParse(
        Storage.recoveredBookLease,
      );
      expect(Storage.cropRecoveryMarkerJson, isEmpty);
      expect(secondRecord?.lease.encoded, firstRecord?.lease.encoded);
      final pending = await Directory(
        '${store.root.path}${Platform.pathSeparator}pending',
      ).list().toList();
      expect(pending, hasLength(1));
    },
  );

  test('distinct crop attempt IDs cannot reuse stale journal bytes', () async {
    final sandbox = await Directory.systemTemp.createTemp('crop_attempt_ids_');
    addTearDown(() async => sandbox.delete(recursive: true));
    final docs = Directory('${sandbox.path}${Platform.pathSeparator}docs')
      ..createSync();
    final cache = Directory('${sandbox.path}${Platform.pathSeparator}cache')
      ..createSync();
    final first = File('${cache.path}${Platform.pathSeparator}first.jpg')
      ..writeAsBytesSync([1]);
    final second = File('${cache.path}${Platform.pathSeparator}second.jpg')
      ..writeAsBytesSync([2]);
    final replacement = File(
      '${cache.path}${Platform.pathSeparator}replacement.jpg',
    )..writeAsBytesSync([3]);
    final store = ManagedMediaStore(
      documentsDirectory: docs,
      temporaryDirectory: cache,
      nonce: () => 'attempts',
    );

    final firstLease = await store.stageRecoveredCrop(first, 'attempt-1');
    final secondLease = await store.stageRecoveredCrop(second, 'attempt-2');
    final sameAttempt = await store.stageRecoveredCrop(
      replacement,
      'attempt-1',
    );

    expect(firstLease?.encoded, isNot(secondLease?.encoded));
    expect(sameAttempt?.encoded, firstLease?.encoded);
    expect(await store.pendingFile(firstLease!).readAsBytes(), [1]);
    expect(await store.pendingFile(secondLease!).readAsBytes(), [2]);
    expect(await replacement.readAsBytes(), [3]);
  });

  test('recovery journal rejects a cache symlink source', () async {
    final sandbox = await Directory.systemTemp.createTemp('crop_symlink_');
    addTearDown(() async => sandbox.delete(recursive: true));
    final docs = Directory('${sandbox.path}${Platform.pathSeparator}docs')
      ..createSync();
    final cache = Directory('${sandbox.path}${Platform.pathSeparator}cache')
      ..createSync();
    final outside = File('${sandbox.path}${Platform.pathSeparator}outside.jpg')
      ..writeAsBytesSync([7, 7]);
    final link = Link('${cache.path}${Platform.pathSeparator}linked.jpg');
    try {
      await link.create(outside.path);
    } on FileSystemException {
      return;
    }
    final store = ManagedMediaStore(
      documentsDirectory: docs,
      temporaryDirectory: cache,
      nonce: () => 'symlink',
    );

    expect(await store.stageRecoveredCrop(File(link.path), 'linked'), isNull);
    expect(await store.findRecoveredCrop('linked'), isNull);
    expect(await outside.readAsBytes(), [7, 7]);
  });

  test(
    'startup drains stale cache once without a marker and does not attach',
    () async {
      final sandbox = await Directory.systemTemp.createTemp('crop_stale_');
      addTearDown(() async => sandbox.delete(recursive: true));
      final docs = Directory('${sandbox.path}${Platform.pathSeparator}docs')
        ..createSync();
      final cache = Directory('${sandbox.path}${Platform.pathSeparator}cache')
        ..createSync();
      final outside = File('${sandbox.path}${Platform.pathSeparator}stale.jpg')
        ..writeAsBytesSync([4, 5, 6]);
      final store = ManagedMediaStore(
        documentsDirectory: docs,
        temporaryDirectory: cache,
        nonce: () => 'stale',
      );
      final gateway = _CropGateway(path: outside.path);

      await Future.wait([
        CropRecoveryService.recoverAtStartup(
          isAndroid: true,
          gateway: gateway,
          mediaStore: store,
        ),
        CropRecoveryService.recoverAtStartup(
          isAndroid: true,
          gateway: gateway,
          mediaStore: store,
        ),
      ]);

      expect(gateway.calls, 1);
      expect(Storage.recoveredBookLease, isEmpty);
      expect(await outside.exists(), isTrue);
      expect(await store.root.exists(), isFalse);
    },
  );

  test(
    'marked crop outside trusted cache is rejected without reading it',
    () async {
      final sandbox = await Directory.systemTemp.createTemp('crop_outside_');
      addTearDown(() async => sandbox.delete(recursive: true));
      final docs = Directory('${sandbox.path}${Platform.pathSeparator}docs')
        ..createSync();
      final cache = Directory('${sandbox.path}${Platform.pathSeparator}cache')
        ..createSync();
      final outside = File(
        '${sandbox.path}${Platform.pathSeparator}sentinel.jpg',
      )..writeAsBytesSync([7, 8, 9]);
      final store = ManagedMediaStore(
        documentsDirectory: docs,
        temporaryDirectory: cache,
        nonce: () => 'outside',
      );
      await Storage.markCropLaunch(workflowId: 'book-outside');

      await CropRecoveryService.recoverAtStartup(
        isAndroid: true,
        gateway: _CropGateway(path: outside.path),
        mediaStore: store,
      );

      expect(Storage.cropRecoveryMarkerJson, isEmpty);
      expect(Storage.recoveredBookLease, isEmpty);
      expect(await outside.readAsBytes(), [7, 8, 9]);
      expect(await store.root.exists(), isFalse);
    },
  );

  test('legacy recovered book record defaults to picked phase', () {
    final record = RecoveredBookDraft.tryParse(
      '{"workflowId":"legacy","lease":'
      '"pending:book:p_book_legacy.jpg"}',
    );

    expect(record?.phase, RecoveredBookPhase.picked);
  });

  test(
    'startup none clears marker, exception preserves it, non-Android skips',
    () async {
      final sandbox = await Directory.systemTemp.createTemp('crop_none_');
      addTearDown(() async => sandbox.delete(recursive: true));
      final store = ManagedMediaStore(
        documentsDirectory: Directory(
          '${sandbox.path}${Platform.pathSeparator}docs',
        )..createSync(),
        temporaryDirectory: Directory(
          '${sandbox.path}${Platform.pathSeparator}cache',
        )..createSync(),
        nonce: () => 'none',
      );
      await Storage.markCropLaunch(workflowId: 'book-flow');
      final none = _CropGateway();
      await CropRecoveryService.recoverAtStartup(
        isAndroid: true,
        gateway: none,
        mediaStore: store,
      );
      expect(Storage.cropRecoveryMarkerJson, isEmpty);

      CropRecoveryService.resetForTesting();
      await Storage.markCropLaunch(workflowId: 'book-retry');
      final failure = _CropGateway(error: StateError('platform failure'));
      await CropRecoveryService.recoverAtStartup(
        isAndroid: true,
        gateway: failure,
      );
      expect(Storage.cropRecoveryMarkerJson, contains('book-retry'));

      CropRecoveryService.resetForTesting();
      final skipped = _CropGateway(path: '/cache/ignored.jpg');
      await CropRecoveryService.recoverAtStartup(
        isAndroid: false,
        gateway: skipped,
      );
      expect(skipped.calls, 0);
    },
  );
}
