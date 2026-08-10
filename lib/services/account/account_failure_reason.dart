import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show PlatformException;

import 'account_operation_client.dart';
import 'cloud_backup_deletion.dart';

/// Actionable cause of an account/cloud operation failure, safe for UI hints.
///
/// The variants are deliberately coarse: each maps to one localized hint line
/// the user can act on. Raw error text never crosses this boundary — the
/// classifier reads whitelisted code fields only (same redaction contract as
/// `AccountFailureDiagnostics`).
enum AccountFailureReason {
  appCheck,
  offline,
  unauthenticated,
  serverBusy,
  unknown,
}

/// Classifies [error] into an [AccountFailureReason] using code fields only.
AccountFailureReason classifyAccountFailure(Object? error) {
  if (error is CloudBackupDeletionRemoteException) {
    return error.reason;
  }
  if (error is AccountOperationFailure) {
    return switch (error.code) {
      AccountOperationFailureCode.appCheckRequired =>
        AccountFailureReason.appCheck,
      AccountOperationFailureCode.authenticationRequired ||
      AccountOperationFailureCode.recentAuthenticationRequired ||
      AccountOperationFailureCode.freshAnonymousTokenRequired =>
        AccountFailureReason.unauthenticated,
      AccountOperationFailureCode.unavailable ||
      AccountOperationFailureCode.rateLimited ||
      AccountOperationFailureCode.operationInProgress =>
        AccountFailureReason.serverBusy,
      _ => AccountFailureReason.unknown,
    };
  }
  if (error is FirebaseFunctionsException) {
    // App Check enforcement on the account callables rejects requests with
    // `failed-precondition` before any handler code runs.
    return switch (error.code) {
      'failed-precondition' => AccountFailureReason.appCheck,
      'unauthenticated' ||
      'permission-denied' => AccountFailureReason.unauthenticated,
      'unavailable' ||
      'internal' ||
      'deadline-exceeded' ||
      'resource-exhausted' => AccountFailureReason.serverBusy,
      _ => AccountFailureReason.unknown,
    };
  }
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'network-request-failed' => AccountFailureReason.offline,
      'app-check-token-invalid' ||
      'firebase-app-check-token-invalid' => AccountFailureReason.appCheck,
      'requires-recent-login' ||
      'user-token-expired' ||
      'invalid-user-token' => AccountFailureReason.unauthenticated,
      'too-many-requests' ||
      'internal-error' => AccountFailureReason.serverBusy,
      _ => AccountFailureReason.unknown,
    };
  }
  if (error is PlatformException) {
    return switch (error.code) {
      'network_error' => AccountFailureReason.offline,
      _ => AccountFailureReason.unknown,
    };
  }
  if (error is TimeoutException) {
    return AccountFailureReason.offline;
  }
  return AccountFailureReason.unknown;
}
