import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/account_deletion_status_receipt.dart';

void main() {
  group('AccountDeletionStatusReceipt', () {
    test('accepts exactly 32 canonical base64url bytes', () {
      final value = _receiptValue(7);
      final receipt = AccountDeletionStatusReceipt.checked(
        sourceUid: 'source-uid',
        requestKey: 'request-key',
        terminalStatusReceipt: value,
      );

      expect(value, hasLength(43));
      expect(AccountDeletionStatusReceipt.isCanonicalValue(value), isTrue);
      expect(
        base64Url.decode('$value='),
        hasLength(AccountDeletionStatusReceipt.byteLength),
      );
      expect(receipt.terminalStatusReceipt, value);
    });

    for (final malformed in <String>[
      '',
      'short',
      'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
      'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA+',
      'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
    ]) {
      test('rejects malformed capability without echoing it: $malformed', () {
        Object? caught;
        try {
          AccountDeletionStatusReceipt.checked(
            sourceUid: 'source-uid',
            requestKey: 'request-key',
            terminalStatusReceipt: malformed,
          );
        } catch (error) {
          caught = error;
        }

        expect(caught, isA<AccountDeletionStatusReceiptFailure>());
        if (malformed.isNotEmpty) {
          expect(caught.toString(), isNot(contains(malformed)));
        }
      });
    }

    test(
      'strict storage decoding rejects unknown fields and future versions',
      () {
        final value = _receiptValue(3);
        final valid = <String, Object?>{
          'version': AccountDeletionStatusReceipt.currentVersion,
          'sourceUid': 'source-uid',
          'requestKey': 'request-key',
          'terminalStatusReceipt': value,
          'operationId': null,
        };

        expect(
          AccountDeletionStatusReceipt.fromStoredValue(jsonEncode(valid)),
          AccountDeletionStatusReceipt.checked(
            sourceUid: 'source-uid',
            requestKey: 'request-key',
            terminalStatusReceipt: value,
          ),
        );

        expect(
          () => AccountDeletionStatusReceipt.fromStoredValue(
            jsonEncode({...valid, 'unexpected': true}),
          ),
          throwsA(isA<AccountDeletionStatusReceiptFailure>()),
        );
        expect(
          () => AccountDeletionStatusReceipt.fromStoredValue(
            jsonEncode({...valid, 'version': 2}),
          ),
          throwsA(isA<AccountDeletionStatusReceiptFailure>()),
        );
      },
    );

    test('debug text never contains the raw capability', () {
      final value = _receiptValue(9);
      final receipt = AccountDeletionStatusReceipt.checked(
        sourceUid: 'source-uid',
        requestKey: 'request-key',
        terminalStatusReceipt: value,
        operationId: 'operation-1',
      );

      expect(receipt.toString(), isNot(contains(value)));
      expect(receipt.toString(), contains('bound: true'));
    });
  });

  group('AccountDeletionStatusReceiptStore', () {
    test(
      'creates, verifies, and idempotently reuses the same workflow',
      () async {
        final storage = _FakeSecureStorage();
        final value = _receiptValue(1);
        final store = AccountDeletionStatusReceiptStore(
          storage: storage,
          generateReceipt: () => value,
        );

        final created = await store.create(
          sourceUid: 'source-uid',
          requestKey: 'request-key',
        );
        final repeated = await store.create(
          sourceUid: 'source-uid',
          requestKey: 'request-key',
        );

        expect(created, repeated);
        expect(created.terminalStatusReceipt, value);
        expect(await store.read(), created);
        expect(storage.writeCount, 1);
      },
    );

    test('never overwrites a different or malformed stored receipt', () async {
      final storage = _FakeSecureStorage();
      final firstStore = AccountDeletionStatusReceiptStore(
        storage: storage,
        generateReceipt: () => _receiptValue(1),
      );
      final first = await firstStore.create(
        sourceUid: 'source-1',
        requestKey: 'request-1',
      );

      await expectLater(
        firstStore.create(sourceUid: 'source-2', requestKey: 'request-2'),
        throwsA(
          isA<AccountDeletionStatusReceiptFailure>().having(
            (failure) => failure.code,
            'code',
            AccountDeletionStatusReceiptFailureCode.conflict,
          ),
        ),
      );
      expect(await firstStore.read(), first);

      storage.value = '{not-valid-json:${_receiptValue(4)}}';
      final writesBeforeMalformedRead = storage.writeCount;
      await expectLater(
        firstStore.create(sourceUid: 'source-3', requestKey: 'request-3'),
        throwsA(isA<AccountDeletionStatusReceiptFailure>()),
      );
      expect(storage.writeCount, writesBeforeMalformedRead);
    });

    test(
      'bind is idempotent and refuses to replace a different operation',
      () async {
        final store = AccountDeletionStatusReceiptStore(
          storage: _FakeSecureStorage(),
          generateReceipt: () => _receiptValue(2),
        );
        final created = await store.create(
          sourceUid: 'source-uid',
          requestKey: 'request-key',
        );

        final bound = await store.bindOperation(
          expected: created,
          operationId: 'operation-1',
        );
        final repeated = await store.bindOperation(
          expected: created,
          operationId: 'operation-1',
        );

        expect(bound.operationId, 'operation-1');
        expect(repeated, bound);
        await expectLater(
          store.bindOperation(expected: created, operationId: 'operation-2'),
          throwsA(
            isA<AccountDeletionStatusReceiptFailure>().having(
              (failure) => failure.code,
              'code',
              AccountDeletionStatusReceiptFailureCode.conflict,
            ),
          ),
        );
        expect(await store.read(), bound);
      },
    );

    test('stale clear cannot erase a newer capability', () async {
      final storage = _FakeSecureStorage();
      final store = AccountDeletionStatusReceiptStore(
        storage: storage,
        generateReceipt: () => _receiptValue(1),
      );
      final stale = AccountDeletionStatusReceipt.checked(
        sourceUid: 'source-uid',
        requestKey: 'request-key',
        terminalStatusReceipt: _receiptValue(0),
      );
      final current = await store.create(
        sourceUid: 'source-uid',
        requestKey: 'request-key',
      );

      expect(await store.clearIfCurrent(stale), isFalse);
      expect(await store.read(), current);
      expect(await store.clearIfCurrent(current), isTrue);
      expect(await store.read(), isNull);
    });

    test(
      'pre-bind snapshot cannot clear a receipt bound concurrently',
      () async {
        final store = AccountDeletionStatusReceiptStore(
          storage: _FakeSecureStorage(),
          generateReceipt: () => _receiptValue(4),
        );
        final unbound = await store.create(
          sourceUid: 'source-uid',
          requestKey: 'request-key',
        );
        final bound = await store.bindOperation(
          expected: unbound,
          operationId: 'operation-1',
        );

        expect(await store.clearIfCurrent(unbound), isFalse);
        expect(await store.read(), bound);
        expect(await store.clearIfCurrent(bound), isTrue);
        expect(await store.read(), isNull);
      },
    );

    test('write and delete are read-back verified and fail closed', () async {
      final storage = _FakeSecureStorage()..discardWrites = true;
      final store = AccountDeletionStatusReceiptStore(
        storage: storage,
        generateReceipt: () => _receiptValue(5),
      );

      await expectLater(
        store.create(sourceUid: 'source-uid', requestKey: 'request-key'),
        throwsA(
          isA<AccountDeletionStatusReceiptFailure>().having(
            (failure) => failure.code,
            'code',
            AccountDeletionStatusReceiptFailureCode.verificationFailed,
          ),
        ),
      );

      storage
        ..discardWrites = false
        ..discardDeletes = true;
      final receipt = await store.create(
        sourceUid: 'source-uid',
        requestKey: 'request-key',
      );
      await expectLater(
        store.clearIfCurrent(receipt),
        throwsA(
          isA<AccountDeletionStatusReceiptFailure>().having(
            (failure) => failure.code,
            'code',
            AccountDeletionStatusReceiptFailureCode.verificationFailed,
          ),
        ),
      );
    });

    test('storage exceptions are sanitized', () async {
      final secret = _receiptValue(8);
      final store = AccountDeletionStatusReceiptStore(
        storage: _FakeSecureStorage()..readError = StateError(secret),
        generateReceipt: () => secret,
      );

      Object? caught;
      try {
        await store.read();
      } catch (error) {
        caught = error;
      }

      expect(caught, isA<AccountDeletionStatusReceiptFailure>());
      expect(caught.toString(), isNot(contains(secret)));
    });

    test('serializes secure storage operations within one store', () async {
      final storage = _FakeSecureStorage();
      final store = AccountDeletionStatusReceiptStore(
        storage: storage,
        generateReceipt: () => _receiptValue(6),
      );
      await store.create(sourceUid: 'source-uid', requestKey: 'request-key');
      storage.delayOperations = true;

      await Future.wait([store.read(), store.read(), store.read()]);

      expect(storage.maxActiveOperations, 1);
    });

    test('production adapter uses device-only first-unlock iOS options', () {
      const options =
          FlutterSecureAccountDeletionStatusReceiptStorage.iosOptions;

      expect(
        options.accessibility,
        KeychainAccessibility.first_unlock_this_device,
      );
      expect(options.synchronizable, isFalse);
    });
  });
}

String _receiptValue(int byte) {
  return base64Url.encode(List<int>.filled(32, byte)).replaceAll('=', '');
}

class _FakeSecureStorage implements AccountDeletionStatusReceiptSecureStorage {
  String? value;
  Object? readError;
  bool discardWrites = false;
  bool discardDeletes = false;
  bool delayOperations = false;
  int writeCount = 0;
  int _activeOperations = 0;
  int maxActiveOperations = 0;

  @override
  Future<void> delete() async {
    await _duringOperation(() {
      if (!discardDeletes) {
        value = null;
      }
    });
  }

  @override
  Future<String?> read() async {
    return _duringOperation(() {
      final error = readError;
      if (error != null) {
        throw error;
      }
      return value;
    });
  }

  @override
  Future<void> write(String newValue) async {
    await _duringOperation(() {
      writeCount += 1;
      if (!discardWrites) {
        value = newValue;
      }
    });
  }

  Future<T> _duringOperation<T>(T Function() body) async {
    _activeOperations += 1;
    if (_activeOperations > maxActiveOperations) {
      maxActiveOperations = _activeOperations;
    }
    try {
      if (delayOperations) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      return body();
    } finally {
      _activeOperations -= 1;
    }
  }
}
