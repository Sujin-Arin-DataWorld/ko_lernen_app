import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/services/account/account_failure_reason.dart';
import 'package:ko_lernen_app/services/account/account_operation_client.dart';
import 'package:ko_lernen_app/services/account/cloud_backup_deletion.dart';

void main() {
  test('maps account operation failure codes to actionable reasons', () {
    expect(
      classifyAccountFailure(
        const AccountOperationFailure(
          AccountOperationFailureCode.appCheckRequired,
          retryable: true,
        ),
      ),
      AccountFailureReason.appCheck,
    );
    expect(
      classifyAccountFailure(
        const AccountOperationFailure(
          AccountOperationFailureCode.authenticationRequired,
          retryable: false,
        ),
      ),
      AccountFailureReason.unauthenticated,
    );
    expect(
      classifyAccountFailure(
        const AccountOperationFailure(
          AccountOperationFailureCode.recentAuthenticationRequired,
          retryable: false,
        ),
      ),
      AccountFailureReason.unauthenticated,
    );
    expect(
      classifyAccountFailure(
        const AccountOperationFailure(
          AccountOperationFailureCode.unavailable,
          retryable: true,
        ),
      ),
      AccountFailureReason.serverBusy,
    );
    expect(
      classifyAccountFailure(
        const AccountOperationFailure(
          AccountOperationFailureCode.rateLimited,
          retryable: true,
        ),
      ),
      AccountFailureReason.serverBusy,
    );
    expect(
      classifyAccountFailure(
        const AccountOperationFailure(
          AccountOperationFailureCode.invalidRequest,
          retryable: false,
        ),
      ),
      AccountFailureReason.unknown,
    );
  });

  test('maps Firebase functions exceptions by status code only', () {
    expect(
      classifyAccountFailure(
        FirebaseFunctionsException(
          message: 'secret token abc',
          code: 'failed-precondition',
        ),
      ),
      AccountFailureReason.appCheck,
    );
    expect(
      classifyAccountFailure(
        FirebaseFunctionsException(message: 'x', code: 'unauthenticated'),
      ),
      AccountFailureReason.unauthenticated,
    );
    expect(
      classifyAccountFailure(
        FirebaseFunctionsException(message: 'x', code: 'unavailable'),
      ),
      AccountFailureReason.serverBusy,
    );
    expect(
      classifyAccountFailure(
        FirebaseFunctionsException(message: 'x', code: 'internal'),
      ),
      AccountFailureReason.serverBusy,
    );
    expect(
      classifyAccountFailure(
        FirebaseFunctionsException(message: 'x', code: 'not-found'),
      ),
      AccountFailureReason.unknown,
    );
  });

  test('maps auth and platform failures', () {
    expect(
      classifyAccountFailure(
        FirebaseAuthException(code: 'network-request-failed'),
      ),
      AccountFailureReason.offline,
    );
    expect(
      classifyAccountFailure(
        FirebaseAuthException(code: 'app-check-token-invalid'),
      ),
      AccountFailureReason.appCheck,
    );
    expect(
      classifyAccountFailure(
        FirebaseAuthException(code: 'requires-recent-login'),
      ),
      AccountFailureReason.unauthenticated,
    );
    expect(
      classifyAccountFailure(FirebaseAuthException(code: 'too-many-requests')),
      AccountFailureReason.serverBusy,
    );
    expect(
      classifyAccountFailure(PlatformException(code: 'network_error')),
      AccountFailureReason.offline,
    );
    expect(
      classifyAccountFailure(TimeoutException('slow')),
      AccountFailureReason.offline,
    );
  });

  test('uses the reason carried by a cloud deletion remote exception', () {
    expect(
      classifyAccountFailure(
        const CloudBackupDeletionRemoteException(
          reason: AccountFailureReason.appCheck,
        ),
      ),
      AccountFailureReason.appCheck,
    );
    expect(
      classifyAccountFailure(const CloudBackupDeletionRemoteException()),
      AccountFailureReason.unknown,
    );
  });

  test('never derives a reason from arbitrary error text', () {
    // Unknown types fall through to `unknown` — the classifier must not read
    // toString()/message fields, matching the redaction contract.
    expect(
      classifyAccountFailure(StateError('uid=secret@example.com')),
      AccountFailureReason.unknown,
    );
  });
}
