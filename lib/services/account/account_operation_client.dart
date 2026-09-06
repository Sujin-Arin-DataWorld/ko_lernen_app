import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import 'account_deletion_status_receipt.dart';
import 'cloud_write_session.dart';

enum AccountOperationKind { replacement, deletion }

enum AccountOperationPhase {
  prepared,
  targetVerified,
  reconciling,
  sourceCleanupPending,
  deletionRequested,
  userTreeDeleting,
  authDeleted,
  appleRevocationPending,
  communityCleanupPending,
  processorCleanupPending,
  completed,
  blocked,
  cancelled,
}

enum AccountOperationBlockedReason {
  operationBlocked,
  durableAccountTransitionNotSupported,
  targetVerificationFailed,
  reconciliationFailed,
  sourceCleanupFailed,
}

enum AccountOperationFailureCode {
  authenticationRequired,
  recentAuthenticationRequired,
  freshAnonymousTokenRequired,
  appCheckRequired,
  permissionDenied,
  operationInProgress,
  operationNotFound,
  staleOperationVersion,
  rateLimited,
  invalidRequest,
  invalidResponse,
  unavailable,
  blocked,
  unknown,
}

@immutable
class AccountOperationFailure implements Exception {
  const AccountOperationFailure(this.code, {required this.retryable});

  final AccountOperationFailureCode code;
  final bool retryable;

  @override
  String toString() => 'Account operation failed (${code.name}).';
}

@immutable
class AccountOperationResult {
  const AccountOperationResult({
    required this.operationId,
    required this.kind,
    required this.phase,
    required this.version,
    required this.attemptCount,
    required this.retryable,
    this.blockedReason,
  });

  factory AccountOperationResult.fromJson(Map<String, Object?> json) {
    try {
      final operationId = _requiredString(json['operationId']);
      final kind = _kindFromWire(_requiredString(json['kind']));
      final phase = _phaseFromWire(_requiredString(json['phase']));
      final version = _nonNegativeInt(json['version']);
      final attemptCount = _nonNegativeInt(json['attemptCount']);
      final retryable = json['retryable'];
      if (retryable is! bool) {
        throw const FormatException();
      }
      final rawBlockedReason = json['blockedReason'];
      final blockedReason = rawBlockedReason == null
          ? null
          : _blockedReasonFromWire(_requiredString(rawBlockedReason));
      if (phase == AccountOperationPhase.blocked && blockedReason == null) {
        throw const FormatException();
      }
      if (phase != AccountOperationPhase.blocked && blockedReason != null) {
        throw const FormatException();
      }
      return AccountOperationResult(
        operationId: operationId,
        kind: kind,
        phase: phase,
        version: version,
        attemptCount: attemptCount,
        retryable: retryable,
        blockedReason: blockedReason,
      );
    } on AccountOperationFailure {
      rethrow;
    } catch (_) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.invalidResponse,
        retryable: false,
      );
    }
  }

  final String operationId;
  final AccountOperationKind kind;
  final AccountOperationPhase phase;
  final int version;
  final int attemptCount;
  final bool retryable;
  final AccountOperationBlockedReason? blockedReason;

  bool get isTerminal =>
      phase == AccountOperationPhase.completed ||
      phase == AccountOperationPhase.blocked ||
      phase == AccountOperationPhase.cancelled;

  Map<String, Object?> toJson() => {
    'operationId': operationId,
    'kind': kind.name,
    'phase': phase.name,
    'version': version,
    'attemptCount': attemptCount,
    'retryable': retryable,
    'blockedReason': _blockedReasonToWire(blockedReason),
  };
}

@immutable
class AccountDeletionRequest {
  const AccountDeletionRequest({
    required this.requestKey,
    required this.terminalStatusReceipt,
  });

  final String requestKey;
  final String terminalStatusReceipt;

  Map<String, Object?> toJson() => {
    'requestKey': _validated(requestKey),
    'terminalStatusReceipt': _validatedTerminalStatusReceipt(
      terminalStatusReceipt,
    ),
  };
}

@immutable
class AccountDeletionStatusByReceiptRequest {
  const AccountDeletionStatusByReceiptRequest({
    required this.terminalStatusReceipt,
  });

  final String terminalStatusReceipt;

  Map<String, Object?> toJson() => {
    'terminalStatusReceipt': _validatedTerminalStatusReceipt(
      terminalStatusReceipt,
    ),
  };
}

@immutable
class AccountOperationStatusRequest {
  const AccountOperationStatusRequest({required this.operationId});

  final String operationId;

  Map<String, Object?> toJson() => {'operationId': _validated(operationId)};
}

enum AppleAuthorizationClientKind { native, web }

@immutable
class AppleRevocationCompletionRequest {
  const AppleRevocationCompletionRequest({
    required this.operationId,
    required this.expectedVersion,
    required this.authorizationCode,
    this.clientKind = AppleAuthorizationClientKind.native,
  });

  final String operationId;
  final int expectedVersion;
  final String authorizationCode;
  final AppleAuthorizationClientKind clientKind;

  Map<String, Object?> toJson() {
    if (expectedVersion < 0) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.invalidRequest,
        retryable: false,
      );
    }
    return {
      'operationId': _validated(operationId),
      'expectedVersion': expectedVersion,
      'authorizationCode': _validated(authorizationCode),
      'clientKind': clientKind.name,
    };
  }
}

abstract interface class AccountOperationGateway {
  Future<AccountOperationResult> requestAccountDeletion(
    AccountDeletionRequest request,
  );

  Future<AccountOperationResult> getAccountOperation(
    AccountOperationStatusRequest request,
  );

  Future<AccountOperationResult> getAccountDeletionStatusByReceipt(
    AccountDeletionStatusByReceiptRequest request,
  );

  Future<void> acknowledgeAccountDeletionStatusReceipt(
    AccountDeletionStatusByReceiptRequest request,
  );

  Future<AccountOperationResult> completeAppleRevocation(
    AppleRevocationCompletionRequest request,
  );
}

typedef AnonymousIdTokenRefresher =
    Future<void> Function({
      required String expectedUid,
      required bool forceRefresh,
    });
typedef AnonymousSourceIdentityReader =
    ({String? uid, bool isAnonymous}) Function();

abstract interface class AnonymousSourceAuthFreshness {
  Future<void> refresh(CloudWriteSession expectedSession);
  void assertCurrent(CloudWriteSession expectedSession);
}

/// Refreshes the primary anonymous Firebase ID token without retaining or
/// exposing the token value. Exact identity and session fences run on both
/// sides of the asynchronous refresh boundary.
class FirebaseAnonymousSourceAuthFreshness
    implements AnonymousSourceAuthFreshness {
  const FirebaseAnonymousSourceAuthFreshness({
    required this.sessions,
    required this.currentIdentity,
    required this.refreshIdToken,
  });

  final CloudWriteSessionController sessions;
  final AnonymousSourceIdentityReader currentIdentity;
  final AnonymousIdTokenRefresher refreshIdToken;

  @override
  Future<void> refresh(CloudWriteSession expectedSession) async {
    assertCurrent(expectedSession);
    try {
      await refreshIdToken(
        expectedUid: expectedSession.uid,
        forceRefresh: true,
      );
    } on AccountOperationFailure {
      rethrow;
    } catch (_) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.unavailable,
        retryable: true,
      );
    }
    assertCurrent(expectedSession);
  }

  @override
  void assertCurrent(CloudWriteSession expectedSession) {
    try {
      sessions.assertCurrent(expectedSession);
    } on StateError {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.blocked,
        retryable: false,
      );
    }
    final identity = currentIdentity();
    if (identity.uid != expectedSession.uid || !identity.isAnonymous) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.authenticationRequired,
        retryable: false,
      );
    }
  }
}

/// The only route for protected callables authenticated as the anonymous
/// primary source. Target-authenticated operations intentionally do not use it.
class FreshAnonymousAccountOperationGateway {
  const FreshAnonymousAccountOperationGateway({
    required this.gateway,
    required this.freshness,
  });

  final AccountOperationGateway gateway;
  final AnonymousSourceAuthFreshness freshness;

  Future<AccountOperationResult> requestAnonymousAccountDeletion({
    required CloudWriteSession expectedSession,
    required AccountDeletionRequest request,
  }) {
    return _invoke(
      expectedSession,
      () => gateway.requestAccountDeletion(request),
    );
  }

  Future<AccountOperationResult> _invoke(
    CloudWriteSession expectedSession,
    Future<AccountOperationResult> Function() operation,
  ) async {
    await freshness.refresh(expectedSession);
    freshness.assertCurrent(expectedSession);
    final result = await operation();
    freshness.assertCurrent(expectedSession);
    return result;
  }
}

@immutable
class AccountOperationTransportCall {
  const AccountOperationTransportCall({required this.name, required this.data});

  final String name;
  final Map<String, Object?> data;

  @override
  bool operator ==(Object other) {
    return other is AccountOperationTransportCall &&
        other.name == name &&
        mapEquals(other.data, data);
  }

  @override
  int get hashCode {
    final keys = data.keys.toList()..sort();
    return Object.hash(
      name,
      Object.hashAll(keys.map((key) => Object.hash(key, data[key]))),
    );
  }
}

abstract interface class AccountOperationTransport {
  Future<Object?> call(AccountOperationTransportCall call);
}

typedef FirebaseCallableInvoker =
    Future<Object?> Function({
      required String name,
      required Map<String, Object?> data,
      required HttpsCallableOptions options,
    });

@immutable
class AccountOperationTransportException implements Exception {
  const AccountOperationTransportException({
    required this.code,
    this.safeCode,
    this.unsafeMessage,
  });

  final String code;
  final String? safeCode;

  /// Retained only so adapters can be tested against accidental disclosure.
  /// It is never copied to [AccountOperationFailure] or rendered.
  final String? unsafeMessage;
}

class FirebaseFunctionsAccountOperationTransport
    implements AccountOperationTransport {
  FirebaseFunctionsAccountOperationTransport(this._invokeCallable);

  factory FirebaseFunctionsAccountOperationTransport.forRegion(String region) {
    return FirebaseFunctionsAccountOperationTransport.fromFunctions(
      FirebaseFunctions.instanceFor(region: region),
    );
  }

  factory FirebaseFunctionsAccountOperationTransport.fromFunctions(
    FirebaseFunctions functions,
  ) {
    return FirebaseFunctionsAccountOperationTransport(({
      required name,
      required data,
      required options,
    }) async {
      final result = await functions
          .httpsCallable(name, options: options)
          .call<Object?>(data);
      return result.data;
    });
  }

  final FirebaseCallableInvoker _invokeCallable;

  @override
  Future<Object?> call(AccountOperationTransportCall call) async {
    try {
      return await _invokeCallable(
        name: call.name,
        data: call.data,
        options: HttpsCallableOptions(limitedUseAppCheckToken: true),
      );
    } on FirebaseFunctionsException catch (error) {
      final details = error.details;
      final safeCode = details is Map && details['code'] is String
          ? details['code'] as String
          : null;
      throw AccountOperationTransportException(
        code: error.code,
        safeCode: safeCode,
      );
    } catch (_) {
      throw const AccountOperationTransportException(code: 'unknown');
    }
  }
}

typedef AccountOperationRetryDelay = Future<void> Function(Duration duration);
typedef AccountOperationTransportFactory =
    AccountOperationTransport Function(String region);

class AccountOperationClient implements AccountOperationGateway {
  AccountOperationClient({
    required this.transport,
    AccountOperationRetryDelay? retryDelay,
  }) : _retryDelay = retryDelay ?? Future<void>.delayed;

  factory AccountOperationClient.firebase({
    AccountOperationTransportFactory? transportForRegion,
  }) {
    final factory =
        transportForRegion ??
        FirebaseFunctionsAccountOperationTransport.forRegion;
    return AccountOperationClient(transport: factory(region));
  }

  static const region = 'europe-west3';
  static const _statusAttempts = 3;

  final AccountOperationTransport transport;
  final AccountOperationRetryDelay _retryDelay;

  @override
  Future<AccountOperationResult> requestAccountDeletion(
    AccountDeletionRequest request,
  ) {
    return _invoke(
      AccountOperationTransportCall(
        name: 'requestAccountDeletion',
        data: request.toJson(),
      ),
    );
  }

  @override
  Future<AccountOperationResult> getAccountOperation(
    AccountOperationStatusRequest request,
  ) {
    return _invokeIdempotentStatusRead(
      AccountOperationTransportCall(
        name: 'getAccountOperation',
        data: request.toJson(),
      ),
    );
  }

  @override
  Future<AccountOperationResult> getAccountDeletionStatusByReceipt(
    AccountDeletionStatusByReceiptRequest request,
  ) {
    return _invokeIdempotentStatusRead(
      AccountOperationTransportCall(
        name: 'getAccountDeletionStatusByReceipt',
        data: request.toJson(),
      ),
    );
  }

  @override
  Future<void> acknowledgeAccountDeletionStatusReceipt(
    AccountDeletionStatusByReceiptRequest request,
  ) {
    return _invokeIdempotentReceiptAcknowledgement(
      AccountOperationTransportCall(
        name: 'acknowledgeAccountDeletionStatusReceipt',
        data: request.toJson(),
      ),
    );
  }

  Future<void> _invokeIdempotentReceiptAcknowledgement(
    AccountOperationTransportCall call,
  ) async {
    for (var attempt = 0; attempt < _statusAttempts; attempt += 1) {
      try {
        final raw = await transport.call(call);
        if (raw is! Map || raw.length != 1 || raw['acknowledged'] != true) {
          throw const AccountOperationFailure(
            AccountOperationFailureCode.invalidResponse,
            retryable: false,
          );
        }
        return;
      } on AccountOperationFailure catch (failure) {
        final lastAttempt = attempt == _statusAttempts - 1;
        if (!failure.retryable || lastAttempt) rethrow;
        await _retryDelay(Duration(milliseconds: 200 << attempt));
      } on AccountOperationTransportException catch (error) {
        final failure = _mapTransportFailure(error);
        final lastAttempt = attempt == _statusAttempts - 1;
        if (!failure.retryable || lastAttempt) throw failure;
        await _retryDelay(Duration(milliseconds: 200 << attempt));
      } catch (_) {
        throw const AccountOperationFailure(
          AccountOperationFailureCode.unknown,
          retryable: false,
        );
      }
    }
  }

  Future<AccountOperationResult> _invokeIdempotentStatusRead(
    AccountOperationTransportCall call,
  ) async {
    for (var attempt = 0; attempt < _statusAttempts; attempt += 1) {
      try {
        return await _invoke(call);
      } on AccountOperationFailure catch (failure) {
        final lastAttempt = attempt == _statusAttempts - 1;
        if (!failure.retryable || lastAttempt) {
          rethrow;
        }
        await _retryDelay(Duration(milliseconds: 200 << attempt));
      }
    }
    throw const AccountOperationFailure(
      AccountOperationFailureCode.unavailable,
      retryable: true,
    );
  }

  @override
  Future<AccountOperationResult> completeAppleRevocation(
    AppleRevocationCompletionRequest request,
  ) {
    return _invoke(
      AccountOperationTransportCall(
        name: 'completeAppleRevocation',
        data: request.toJson(),
      ),
    );
  }

  Future<AccountOperationResult> _invoke(
    AccountOperationTransportCall call,
  ) async {
    try {
      final raw = await transport.call(call);
      if (raw is! Map) {
        throw const AccountOperationFailure(
          AccountOperationFailureCode.invalidResponse,
          retryable: false,
        );
      }
      return AccountOperationResult.fromJson(
        raw.map((key, value) => MapEntry(key.toString(), value)),
      );
    } on AccountOperationFailure {
      rethrow;
    } on AccountOperationTransportException catch (error) {
      throw _mapTransportFailure(error);
    } catch (_) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.unknown,
        retryable: false,
      );
    }
  }
}

AccountOperationFailure _mapTransportFailure(
  AccountOperationTransportException error,
) {
  final code = switch (error.safeCode) {
    'recent-authentication-required' =>
      AccountOperationFailureCode.recentAuthenticationRequired,
    'fresh-anonymous-token-required' =>
      AccountOperationFailureCode.freshAnonymousTokenRequired,
    'app-check-required' => AccountOperationFailureCode.appCheckRequired,
    'operation-in-progress' => AccountOperationFailureCode.operationInProgress,
    'operation-not-found' => AccountOperationFailureCode.operationNotFound,
    'stale-operation-version' =>
      AccountOperationFailureCode.staleOperationVersion,
    'anonymous-rate-limit-exceeded' => AccountOperationFailureCode.rateLimited,
    'operation-blocked' => AccountOperationFailureCode.blocked,
    'invalid-operation' ||
    'request-key-required' ||
    'terminal-status-receipt-required' ||
    'terminal-status-receipt-invalid' ||
    'operation-id-required' ||
    'expected-version-required' ||
    'apple-authorization-code-required' =>
      AccountOperationFailureCode.invalidRequest,
    _ => switch (error.code) {
      'unauthenticated' => AccountOperationFailureCode.authenticationRequired,
      'permission-denied' => AccountOperationFailureCode.permissionDenied,
      'resource-exhausted' => AccountOperationFailureCode.rateLimited,
      'failed-precondition' => AccountOperationFailureCode.invalidRequest,
      'unavailable' ||
      'deadline-exceeded' ||
      'internal' => AccountOperationFailureCode.unavailable,
      _ => AccountOperationFailureCode.unknown,
    },
  };
  final retryable =
      code == AccountOperationFailureCode.unavailable ||
      code == AccountOperationFailureCode.rateLimited;
  return AccountOperationFailure(code, retryable: retryable);
}

String _requiredString(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException();
  }
  return value;
}

int _nonNegativeInt(Object? value) {
  if (value is! int || value < 0) {
    throw const FormatException();
  }
  return value;
}

String _validated(String value) {
  if (value.trim().isEmpty) {
    throw const AccountOperationFailure(
      AccountOperationFailureCode.invalidRequest,
      retryable: false,
    );
  }
  return value;
}

String _validatedTerminalStatusReceipt(String value) {
  if (!AccountDeletionStatusReceipt.isCanonicalValue(value)) {
    throw const AccountOperationFailure(
      AccountOperationFailureCode.invalidRequest,
      retryable: false,
    );
  }
  return value;
}

AccountOperationKind _kindFromWire(String value) {
  return switch (value) {
    'replacement' => AccountOperationKind.replacement,
    'deletion' => AccountOperationKind.deletion,
    _ => throw const FormatException(),
  };
}

AccountOperationPhase _phaseFromWire(String value) {
  for (final phase in AccountOperationPhase.values) {
    if (phase.name == value) {
      return phase;
    }
  }
  throw const FormatException();
}

AccountOperationBlockedReason _blockedReasonFromWire(String value) {
  return switch (value) {
    'operation-blocked' => AccountOperationBlockedReason.operationBlocked,
    'durable-account-transition-not-supported' =>
      AccountOperationBlockedReason.durableAccountTransitionNotSupported,
    'target-verification-failed' =>
      AccountOperationBlockedReason.targetVerificationFailed,
    'reconciliation-failed' =>
      AccountOperationBlockedReason.reconciliationFailed,
    'source-cleanup-failed' =>
      AccountOperationBlockedReason.sourceCleanupFailed,
    _ => throw const FormatException(),
  };
}

String? _blockedReasonToWire(AccountOperationBlockedReason? reason) {
  return switch (reason) {
    null => null,
    AccountOperationBlockedReason.operationBlocked => 'operation-blocked',
    AccountOperationBlockedReason.durableAccountTransitionNotSupported =>
      'durable-account-transition-not-supported',
    AccountOperationBlockedReason.targetVerificationFailed =>
      'target-verification-failed',
    AccountOperationBlockedReason.reconciliationFailed =>
      'reconciliation-failed',
    AccountOperationBlockedReason.sourceCleanupFailed =>
      'source-cleanup-failed',
  };
}
