import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/book_image_service.dart';
import 'package:ko_lernen_app/services/picker_recovery_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Gateway implements LostDataGateway {
  _Gateway(this.result);

  final LostPickerData result;
  int calls = 0;

  @override
  Future<LostPickerData> retrieveLostData() async {
    calls++;
    return result;
  }
}

class _ThrowingGateway implements LostDataGateway {
  @override
  Future<LostPickerData> retrieveLostData() async {
    throw StateError('platform failure');
  }
}

class _ControlledGateway implements LostDataGateway {
  final completer = Completer<LostPickerData>();

  @override
  Future<LostPickerData> retrieveLostData() => completer.future;
}

void main() {
  test(
    'Android retrieves lost picker data once and routes marked book purpose',
    () async {
      final gateway = _Gateway(
        const LostPickerData(paths: ['/cache/book.jpg']),
      );
      final recovered = <String>[];
      final coordinator = PickerRecoveryCoordinator(
        gateway: gateway,
        isAndroid: true,
        readMarker: () async => const PickerRecoveryMarker(
          purpose: PickerPurpose.book,
          workflowId: 'book-flow',
        ),
        clearMarker: () async {},
        recoverBook: (path, workflowId) async {
          expect(workflowId, 'book-flow');
          recovered.add(path);
        },
        recoverWord: (_, __) async {},
      );

      await Future.wait([
        coordinator.recoverOnce(),
        coordinator.recoverOnce(),
        coordinator.recoverOnce(),
      ]);

      expect(gateway.calls, 1);
      expect(recovered, ['/cache/book.jpg']);
    },
  );

  test('iOS and web do not invoke Android lost-data recovery', () async {
    final gateway = _Gateway(const LostPickerData(paths: ['/cache/word.jpg']));
    final coordinator = PickerRecoveryCoordinator(
      gateway: gateway,
      isAndroid: false,
      readMarker: () async => const PickerRecoveryMarker(
        purpose: PickerPurpose.word,
        workflowId: 'word-flow',
      ),
      clearMarker: () async {},
      recoverBook: (_, __) async {},
      recoverWord: (_, __) async {},
    );

    await coordinator.recoverOnce();

    expect(gateway.calls, 0);
  });

  test('picker exception clears purpose and busy state in finally', () async {
    final events = <String>[];
    final gateway = _Gateway(const LostPickerData(error: 'picker failed'));
    final coordinator = PickerRecoveryCoordinator(
      gateway: gateway,
      isAndroid: true,
      readMarker: () async => const PickerRecoveryMarker(
        purpose: PickerPurpose.word,
        workflowId: 'word-flow',
      ),
      clearMarker: () async => events.add('clear-purpose'),
      recoverBook: (_, __) async {},
      recoverWord: (_, __) async {},
      setBusy: (value) => events.add('busy:$value'),
    );

    await coordinator.recoverOnce();

    expect(events, ['busy:true', 'clear-purpose', 'busy:false']);
  });

  test(
    'native error still reconnects an existing deterministic journal',
    () async {
      final events = <String>[];
      final coordinator = PickerRecoveryCoordinator(
        gateway: _Gateway(const LostPickerData(error: 'native-error')),
        isAndroid: true,
        readMarker: () async => const PickerRecoveryMarker(
          purpose: PickerPurpose.word,
          workflowId: 'stable-target',
          attemptId: 'attempt',
        ),
        clearMarker: () async => events.add('clear'),
        recoverBook: (_, __) async {},
        recoverWord: (_, __) async {},
        recoverJournal: (marker) async =>
            events.add('journal:${marker.journalId}'),
      );

      await coordinator.recoverOnce();

      expect(events, ['journal:attempt', 'clear']);
    },
  );

  test(
    'gateway throw preserves marker for retry and always resets busy',
    () async {
      final events = <String>[];
      final coordinator = PickerRecoveryCoordinator(
        gateway: _ThrowingGateway(),
        isAndroid: true,
        readMarker: () async => const PickerRecoveryMarker(
          purpose: PickerPurpose.book,
          workflowId: 'book-flow',
        ),
        clearMarker: () async => events.add('clear-marker'),
        recoverBook: (_, __) async {},
        recoverWord: (_, __) async {},
        setBusy: (value) => events.add('busy:$value'),
      );

      await coordinator.recoverOnce();

      expect(events, ['busy:true', 'busy:false']);
    },
  );

  test('recovery callback failure preserves marker and resets busy', () async {
    final events = <String>[];
    final coordinator = PickerRecoveryCoordinator(
      gateway: _Gateway(const LostPickerData(paths: ['/cache/book.jpg'])),
      isAndroid: true,
      readMarker: () async => const PickerRecoveryMarker(
        purpose: PickerPurpose.book,
        workflowId: 'book-flow',
      ),
      clearMarker: () async => events.add('clear-marker'),
      recoverBook: (_, __) async => throw StateError('stage failed'),
      recoverWord: (_, __) async {},
      setBusy: (value) => events.add('busy:$value'),
    );

    await coordinator.recoverOnce();

    expect(events, ['busy:true', 'busy:false']);
  });

  test('clear marker throw cannot prevent busy reset', () async {
    final events = <String>[];
    final coordinator = PickerRecoveryCoordinator(
      gateway: _Gateway(const LostPickerData()),
      isAndroid: true,
      readMarker: () async => const PickerRecoveryMarker(
        purpose: PickerPurpose.word,
        workflowId: 'word-flow',
      ),
      clearMarker: () async => throw StateError('remove failed'),
      recoverBook: (_, __) async {},
      recoverWord: (_, __) async {},
      setBusy: (value) => events.add('busy:$value'),
    );

    await expectLater(coordinator.recoverOnce(), throwsStateError);
    expect(events, ['busy:true', 'busy:false']);
  });

  test('destructive gateway completion is fully awaited', () async {
    final gateway = _ControlledGateway();
    final events = <String>[];
    final coordinator = PickerRecoveryCoordinator(
      gateway: gateway,
      isAndroid: true,
      readMarker: () async => const PickerRecoveryMarker(
        purpose: PickerPurpose.word,
        workflowId: 'word-flow',
      ),
      clearMarker: () async => events.add('clear'),
      recoverBook: (_, __) async {},
      recoverWord: (_, __) async => events.add('recover'),
      setBusy: (value) => events.add('busy:$value'),
    );

    final recovery = coordinator.recoverOnce();
    await Future<void>.delayed(Duration.zero);
    gateway.completer.complete(
      const LostPickerData(paths: ['/cache/late.jpg']),
    );
    await recovery;

    expect(events, ['busy:true', 'recover', 'clear', 'busy:false']);
  });

  test(
    'startup recovery stages one external word and records its workflow',
    () async {
      final sandbox = await Directory.systemTemp.createTemp('picker_startup_');
      addTearDown(() async {
        PickerRecoveryService.resetForTesting();
        await sandbox.delete(recursive: true);
      });
      final docs = Directory('${sandbox.path}${Platform.pathSeparator}docs')
        ..createSync();
      final cache = Directory('${sandbox.path}${Platform.pathSeparator}cache')
        ..createSync();
      final external = File('${cache.path}${Platform.pathSeparator}gallery.jpg')
        ..writeAsBytesSync([8, 9]);
      final store = ManagedMediaStore(
        documentsDirectory: docs,
        temporaryDirectory: cache,
        nonce: () => 'recovery',
      );
      SharedPreferences.setMockInitialValues({});
      Storage.resetForTesting();
      await Storage.init();
      await Storage.markPickerLaunch(
        purpose: 'word',
        workflowId: 'pack:word:0',
      );
      final gateway = _Gateway(LostPickerData(paths: [external.path]));

      await Future.wait([
        PickerRecoveryService.recoverAtStartup(
          isAndroid: true,
          gateway: gateway,
          mediaStore: store,
        ),
        PickerRecoveryService.recoverAtStartup(
          isAndroid: true,
          gateway: gateway,
          mediaStore: store,
        ),
      ]);

      expect(gateway.calls, 1);
      expect(Storage.pickerRecoveryMarkerJson, isEmpty);
      expect(Storage.recoveredWordLease, contains('pack:word:0'));
      final record = PickerRecoveryMarker.tryParse(
        Storage.pickerRecoveryMarkerJson,
      );
      expect(record, isNull);
      expect(await external.exists(), isFalse);
      final pending = await Directory(
        '${store.root.path}${Platform.pathSeparator}pending',
      ).list().toList();
      expect(pending, hasLength(1));
    },
  );

  test(
    'startup book recovery records picked phase for later cropping',
    () async {
      final sandbox = await Directory.systemTemp.createTemp('picker_book_');
      addTearDown(() async {
        PickerRecoveryService.resetForTesting();
        await sandbox.delete(recursive: true);
      });
      final docs = Directory('${sandbox.path}${Platform.pathSeparator}docs')
        ..createSync();
      final cache = Directory('${sandbox.path}${Platform.pathSeparator}cache')
        ..createSync();
      final external = File('${cache.path}${Platform.pathSeparator}gallery.jpg')
        ..writeAsBytesSync([6, 7]);
      final store = ManagedMediaStore(
        documentsDirectory: docs,
        temporaryDirectory: cache,
        nonce: () => 'book_recovery',
      );
      SharedPreferences.setMockInitialValues({});
      Storage.resetForTesting();
      await Storage.init();
      await Storage.markPickerLaunch(purpose: 'book', workflowId: 'book-flow');

      await PickerRecoveryService.recoverAtStartup(
        isAndroid: true,
        gateway: _Gateway(LostPickerData(paths: [external.path])),
        mediaStore: store,
      );

      final record = RecoveredBookDraft.tryParse(Storage.recoveredBookLease);
      expect(record?.workflowId, 'book-flow');
      expect(record?.phase, RecoveredBookPhase.picked);
      expect(await external.exists(), isFalse);
    },
  );

  test('book and word journals reconnect after strict write failure', () async {
    for (final purpose in PickerPurpose.values) {
      final sandbox = await Directory.systemTemp.createTemp(
        'picker_retry_${purpose.name}_',
      );
      addTearDown(() async => sandbox.delete(recursive: true));
      final docs = Directory('${sandbox.path}${Platform.pathSeparator}docs')
        ..createSync();
      final cache = Directory('${sandbox.path}${Platform.pathSeparator}cache')
        ..createSync();
      final source = File(
        '${cache.path}${Platform.pathSeparator}${purpose.name}.jpg',
      )..writeAsBytesSync([purpose.index + 1]);
      final store = ManagedMediaStore(
        documentsDirectory: docs,
        temporaryDirectory: cache,
        nonce: () => purpose.name,
      );
      SharedPreferences.setMockInitialValues({});
      Storage.resetForTesting();
      PickerRecoveryService.resetForTesting();
      await Storage.init();
      final workflowId = '${purpose.name}-target';
      final attemptId = '${purpose.name}-attempt';
      await Storage.markPickerLaunch(
        purpose: purpose.name,
        workflowId: workflowId,
        attemptId: attemptId,
      );

      await PickerRecoveryService.recoverAtStartup(
        isAndroid: true,
        gateway: _Gateway(LostPickerData(paths: [source.path])),
        mediaStore: store,
        persistRecoveredBook: purpose == PickerPurpose.book
            ? (_) async => throw StateError('book write failure')
            : null,
        persistRecoveredWord: purpose == PickerPurpose.word
            ? (_) async => throw StateError('word write failure')
            : null,
      );

      expect(Storage.pickerRecoveryMarkerJson, contains(attemptId));
      final kind = purpose == PickerPurpose.book
          ? ManagedMediaKind.book
          : ManagedMediaKind.word;
      final journal = await store.findRecoveredPicker(attemptId, kind);
      expect(journal, isNotNull);
      expect(await source.exists(), isTrue);

      PickerRecoveryService.resetForTesting();
      await PickerRecoveryService.recoverAtStartup(
        isAndroid: true,
        gateway: _Gateway(const LostPickerData()),
        mediaStore: store,
      );

      expect(Storage.pickerRecoveryMarkerJson, isEmpty);
      if (purpose == PickerPurpose.book) {
        final record = RecoveredBookDraft.tryParse(Storage.recoveredBookLease);
        expect(record?.workflowId, workflowId);
        expect(record?.lease.encoded, journal?.encoded);
      } else {
        final claim = await Storage.claimRecoveredWordLease(workflowId);
        expect(claim.record, contains(journal?.encoded));
      }
      final pending = await Directory(
        '${store.root.path}${Platform.pathSeparator}pending',
      ).list().toList();
      expect(pending, hasLength(1));
    }
  });

  test('marker keeps stable word target separate from unique attempt', () {
    final marker = PickerRecoveryMarker.tryParse(
      '{"purpose":"word","workflowId":"stable-target",'
      '"attemptId":"unique-attempt"}',
    );

    expect(marker?.workflowId, 'stable-target');
    expect(marker?.journalId, 'unique-attempt');
  });

  test('unique picker attempts cannot reuse earlier journal bytes', () async {
    final sandbox = await Directory.systemTemp.createTemp('picker_attempts_');
    addTearDown(() async => sandbox.delete(recursive: true));
    final docs = Directory('${sandbox.path}${Platform.pathSeparator}docs')
      ..createSync();
    final cache = Directory('${sandbox.path}${Platform.pathSeparator}cache')
      ..createSync();
    final first = File('${cache.path}${Platform.pathSeparator}first.jpg')
      ..writeAsBytesSync([1]);
    final second = File('${cache.path}${Platform.pathSeparator}second.jpg')
      ..writeAsBytesSync([2]);
    final store = ManagedMediaStore(
      documentsDirectory: docs,
      temporaryDirectory: cache,
      nonce: () => 'picker_attempts',
    );

    final firstLease = await store.stageRecoveredPicker(
      first,
      'attempt-1',
      ManagedMediaKind.word,
    );
    final secondLease = await store.stageRecoveredPicker(
      second,
      'attempt-2',
      ManagedMediaKind.word,
    );

    expect(firstLease?.encoded, isNot(secondLease?.encoded));
    expect(await store.pendingFile(firstLease!).readAsBytes(), [1]);
    expect(await store.pendingFile(secondLease!).readAsBytes(), [2]);
  });

  test(
    'recovered word workflows are keyed and claimed independently',
    () async {
      SharedPreferences.setMockInitialValues({});
      Storage.resetForTesting();
      await Storage.init();
      await Future.wait([
        Storage.setRecoveredWordLease(
          '{"workflowId":"pack-a:word-0","lease":'
          '"pending:word:p_word_a.jpg"}',
        ),
        Storage.setRecoveredWordLease(
          '{"workflowId":"pack-b:word-0","lease":'
          '"pending:word:p_word_b.jpg"}',
        ),
      ]);

      final claimedB = await Storage.claimRecoveredWordLease('pack-b:word-0');
      expect(claimedB.record, contains('p_word_b.jpg'));
      expect(Storage.recoveredWordLease, contains('pack-a:word-0'));
      expect(Storage.recoveredWordLease, isNot(contains('pack-b:word-0')));

      final claimedA = await Storage.claimRecoveredWordLease('pack-a:word-0');
      expect(claimedA.record, contains('p_word_a.jpg'));
      expect(Storage.recoveredWordLease, isEmpty);
    },
  );

  test(
    'recovered word replacement and ninth entry report displaced leases',
    () async {
      SharedPreferences.setMockInitialValues({});
      Storage.resetForTesting();
      await Storage.init();
      await Storage.setRecoveredWordLease(
        '{"workflowId":"same","lease":"pending:word:p_word_old.jpg"}',
      );

      final replaced = await Storage.setRecoveredWordLease(
        '{"workflowId":"same","lease":"pending:word:p_word_new.jpg"}',
      );
      expect(replaced, ['pending:word:p_word_old.jpg']);

      var evicted = <String>[];
      for (var index = 0; index < 8; index++) {
        evicted = await Storage.setRecoveredWordLease(
          '{"workflowId":"flow-$index","lease":'
          '"pending:word:p_word_$index.jpg"}',
        );
      }
      expect(evicted, ['pending:word:p_word_new.jpg']);
      expect(Storage.recoveredWordLease, isNot(contains('"same"')));
    },
  );

  test('missing or expired recovered-word timestamps are pruned', () async {
    SharedPreferences.setMockInitialValues({
      'kl_recovered_word_lease': jsonEncode({
        'missing': {
          'workflowId': 'missing',
          'lease': 'pending:word:p_word_missing.jpg',
        },
        'expired': {
          'workflowId': 'expired',
          'lease': 'pending:word:p_word_expired.jpg',
          'createdAt': '2000-01-01T00:00:00.000Z',
        },
      }),
    });
    Storage.resetForTesting();
    await Storage.init();

    final claim = await Storage.claimRecoveredWordLease('unrelated');

    expect(
      claim.discardedLeases,
      containsAll([
        'pending:word:p_word_missing.jpg',
        'pending:word:p_word_expired.jpg',
      ]),
    );
    expect(Storage.recoveredWordLease, isEmpty);
  });
}
