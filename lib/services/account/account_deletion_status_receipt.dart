import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AccountDeletionStatusReceiptFailureCode {
  invalidRecord,
  unavailable,
  conflict,
  verificationFailed,
}

@immutable
class AccountDeletionStatusReceiptFailure implements Exception {
  const AccountDeletionStatusReceiptFailure(this.code);

  final AccountDeletionStatusReceiptFailureCode code;

  @override
  String toString() => 'Deletion status receipt failed (${code.name}).';
}

/// A device-held capability for reading one deletion operation after Firebase
/// Auth has removed the source identity.
///
/// [terminalStatusReceipt] is a secret. Callers may send it only to the
/// deletion request/status callables and must never log it or persist it in a
/// non-secure journal.
@immutable
class AccountDeletionStatusReceipt {
  const AccountDeletionStatusReceipt._({
    required this.version,
    required this.sourceUid,
    required this.requestKey,
    required this.terminalStatusReceipt,
    required this.operationId,
  });

  factory AccountDeletionStatusReceipt.checked({
    required String sourceUid,
    required String requestKey,
    required String terminalStatusReceipt,
    String? operationId,
  }) {
    try {
      return AccountDeletionStatusReceipt._(
        version: currentVersion,
        sourceUid: _checkedIdentifier(sourceUid),
        requestKey: _checkedIdentifier(requestKey),
        terminalStatusReceipt: _checkedCapability(terminalStatusReceipt),
        operationId: operationId == null
            ? null
            : _checkedIdentifier(operationId),
      );
    } catch (_) {
      throw const AccountDeletionStatusReceiptFailure(
        AccountDeletionStatusReceiptFailureCode.invalidRecord,
      );
    }
  }

  factory AccountDeletionStatusReceipt.fromStoredValue(String storedValue) {
    try {
      final decoded = jsonDecode(storedValue);
      if (decoded is! Map<String, dynamic> ||
          !_hasExactKeys(decoded, const <String>{
            'version',
            'sourceUid',
            'requestKey',
            'terminalStatusReceipt',
            'operationId',
          }) ||
          decoded['version'] != currentVersion) {
        throw const FormatException();
      }
      final sourceUid = decoded['sourceUid'];
      final requestKey = decoded['requestKey'];
      final receipt = decoded['terminalStatusReceipt'];
      final operationId = decoded['operationId'];
      if (sourceUid is! String ||
          requestKey is! String ||
          receipt is! String ||
          (operationId != null && operationId is! String)) {
        throw const FormatException();
      }
      return AccountDeletionStatusReceipt.checked(
        sourceUid: sourceUid,
        requestKey: requestKey,
        terminalStatusReceipt: receipt,
        operationId: operationId as String?,
      );
    } catch (_) {
      throw const AccountDeletionStatusReceiptFailure(
        AccountDeletionStatusReceiptFailureCode.invalidRecord,
      );
    }
  }

  static const int currentVersion = 1;
  static const int byteLength = 32;
  static final RegExp _canonicalPattern = RegExp(r'^[A-Za-z0-9_-]{43}$');

  final int version;
  final String sourceUid;
  final String requestKey;
  final String terminalStatusReceipt;
  final String? operationId;

  bool get isBound => operationId != null;

  static bool isCanonicalValue(String value) {
    if (!_canonicalPattern.hasMatch(value)) {
      return false;
    }
    try {
      final decoded = base64Url.decode('$value=');
      return decoded.length == byteLength &&
          base64Url.encode(decoded).replaceAll('=', '') == value;
    } catch (_) {
      return false;
    }
  }

  bool matchesWorkflow({
    required String sourceUid,
    required String requestKey,
  }) {
    return this.sourceUid == sourceUid && this.requestKey == requestKey;
  }

  bool hasSameCapability(AccountDeletionStatusReceipt other) {
    return version == other.version &&
        sourceUid == other.sourceUid &&
        requestKey == other.requestKey &&
        terminalStatusReceipt == other.terminalStatusReceipt;
  }

  AccountDeletionStatusReceipt withOperationId(String operationId) {
    return AccountDeletionStatusReceipt.checked(
      sourceUid: sourceUid,
      requestKey: requestKey,
      terminalStatusReceipt: terminalStatusReceipt,
      operationId: operationId,
    );
  }

  String _toStoredValue() {
    return jsonEncode(<String, Object?>{
      'version': version,
      'sourceUid': sourceUid,
      'requestKey': requestKey,
      'terminalStatusReceipt': terminalStatusReceipt,
      'operationId': operationId,
    });
  }

  @override
  bool operator ==(Object other) {
    return other is AccountDeletionStatusReceipt &&
        other.version == version &&
        other.sourceUid == sourceUid &&
        other.requestKey == requestKey &&
        other.terminalStatusReceipt == terminalStatusReceipt &&
        other.operationId == operationId;
  }

  @override
  int get hashCode => Object.hash(
    version,
    sourceUid,
    requestKey,
    terminalStatusReceipt,
    operationId,
  );

  @override
  String toString() {
    return 'AccountDeletionStatusReceipt(version: $version, bound: $isBound)';
  }
}

abstract interface class AccountDeletionStatusReceiptSecureStorage {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> delete();
}

/// Production adapter. The iOS capability is device-bound and unavailable
/// until the first unlock after a reboot. It is never synchronized to iCloud.
class FlutterSecureAccountDeletionStatusReceiptStorage
    implements AccountDeletionStatusReceiptSecureStorage {
  FlutterSecureAccountDeletionStatusReceiptStorage({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage(iOptions: iosOptions);

  static const IOSOptions iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
    synchronizable: false,
  );
  static const String _storageKey =
      'account_deletion_terminal_status_receipt_v1';

  final FlutterSecureStorage _storage;

  @override
  Future<void> delete() => _storage.delete(key: _storageKey);

  @override
  Future<String?> read() => _storage.read(key: _storageKey);

  @override
  Future<void> write(String value) {
    return _storage.write(key: _storageKey, value: value);
  }
}

typedef AccountDeletionStatusReceiptGenerator = String Function();

/// Serializes secure-storage access, verifies every mutation by reading it
/// back, and uses capability comparisons before bind/clear mutations.
class AccountDeletionStatusReceiptStore {
  AccountDeletionStatusReceiptStore({
    AccountDeletionStatusReceiptSecureStorage? storage,
    @visibleForTesting AccountDeletionStatusReceiptGenerator? generateReceipt,
  }) : _storage = storage ?? FlutterSecureAccountDeletionStatusReceiptStorage(),
       _generateReceipt = generateReceipt ?? _generateCapability;

  final AccountDeletionStatusReceiptSecureStorage _storage;
  final AccountDeletionStatusReceiptGenerator _generateReceipt;
  Future<void> _tail = Future<void>.value();

  Future<AccountDeletionStatusReceipt?> read() {
    return _serialized(_readLocked);
  }

  Future<AccountDeletionStatusReceipt> create({
    required String sourceUid,
    required String requestKey,
  }) {
    return _serialized(() async {
      final current = await _readLocked();
      if (current != null) {
        if (current.matchesWorkflow(
          sourceUid: sourceUid,
          requestKey: requestKey,
        )) {
          return current;
        }
        throw const AccountDeletionStatusReceiptFailure(
          AccountDeletionStatusReceiptFailureCode.conflict,
        );
      }

      late final String generated;
      try {
        generated = _generateReceipt();
      } catch (_) {
        throw const AccountDeletionStatusReceiptFailure(
          AccountDeletionStatusReceiptFailureCode.unavailable,
        );
      }
      final receipt = AccountDeletionStatusReceipt.checked(
        sourceUid: sourceUid,
        requestKey: requestKey,
        terminalStatusReceipt: generated,
      );
      await _writeAndVerifyLocked(receipt);
      return receipt;
    });
  }

  Future<AccountDeletionStatusReceipt> bindOperation({
    required AccountDeletionStatusReceipt expected,
    required String operationId,
  }) {
    return _serialized(() async {
      final current = await _readLocked();
      if (current == null || !current.hasSameCapability(expected)) {
        throw const AccountDeletionStatusReceiptFailure(
          AccountDeletionStatusReceiptFailureCode.conflict,
        );
      }
      final currentOperationId = current.operationId;
      if (currentOperationId == operationId) {
        return current;
      }
      if (currentOperationId != null) {
        throw const AccountDeletionStatusReceiptFailure(
          AccountDeletionStatusReceiptFailureCode.conflict,
        );
      }
      final bound = current.withOperationId(operationId);
      await _writeAndVerifyLocked(bound);
      return bound;
    });
  }

  Future<bool> clearIfCurrent(AccountDeletionStatusReceipt expected) {
    return _serialized(() async {
      final current = await _readLocked();
      if (current == null) {
        return false;
      }
      // Clearing is a full-record CAS. In particular, an orphan-cleanup task
      // holding the pre-bind snapshot must not erase a receipt that has since
      // been bound to an operation.
      if (current != expected) {
        return false;
      }
      try {
        await _storage.delete();
      } catch (_) {
        throw const AccountDeletionStatusReceiptFailure(
          AccountDeletionStatusReceiptFailureCode.unavailable,
        );
      }
      if (await _readLocked() != null) {
        throw const AccountDeletionStatusReceiptFailure(
          AccountDeletionStatusReceiptFailureCode.verificationFailed,
        );
      }
      return true;
    });
  }

  Future<AccountDeletionStatusReceipt?> _readLocked() async {
    try {
      final stored = await _storage.read();
      return stored == null
          ? null
          : AccountDeletionStatusReceipt.fromStoredValue(stored);
    } on AccountDeletionStatusReceiptFailure {
      rethrow;
    } catch (_) {
      throw const AccountDeletionStatusReceiptFailure(
        AccountDeletionStatusReceiptFailureCode.unavailable,
      );
    }
  }

  Future<void> _writeAndVerifyLocked(
    AccountDeletionStatusReceipt receipt,
  ) async {
    try {
      await _storage.write(receipt._toStoredValue());
    } catch (_) {
      throw const AccountDeletionStatusReceiptFailure(
        AccountDeletionStatusReceiptFailureCode.unavailable,
      );
    }
    final persisted = await _readLocked();
    if (persisted != receipt) {
      throw const AccountDeletionStatusReceiptFailure(
        AccountDeletionStatusReceiptFailureCode.verificationFailed,
      );
    }
  }

  Future<T> _serialized<T>(Future<T> Function() action) {
    final predecessor = _tail;
    final release = Completer<void>();
    _tail = release.future;
    return () async {
      await predecessor;
      try {
        return await action();
      } finally {
        release.complete();
      }
    }();
  }
}

String _generateCapability() {
  final random = Random.secure();
  final bytes = List<int>.generate(
    AccountDeletionStatusReceipt.byteLength,
    (_) => random.nextInt(256),
    growable: false,
  );
  return base64Url.encode(bytes).replaceAll('=', '');
}

String _checkedIdentifier(String value) {
  if (value.isEmpty || value.length > 256 || value != value.trim()) {
    throw const FormatException();
  }
  return value;
}

String _checkedCapability(String value) {
  if (!AccountDeletionStatusReceipt.isCanonicalValue(value)) {
    throw const FormatException();
  }
  return value;
}

bool _hasExactKeys(Map<String, dynamic> value, Set<String> expected) {
  return value.length == expected.length &&
      value.keys.toSet().containsAll(expected);
}
