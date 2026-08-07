import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/services/account/account_failure_diagnostics.dart';
import 'package:ko_lernen_app/services/account/account_operation_client.dart';

/// 민감정보가 섞일 수 있는 자리에 넣는 **합성** 값. 로그 라벨에 이 문자열들이
/// 절대 나타나면 안 된다.
const _secrets = <String>[
  'token-abc123',
  'uid-YSd21kCD',
  'jin@example.com',
  'https://firestore.example/v1/projects/secret',
];

void main() {
  group('AccountFailureDiagnostics.describe', () {
    test('keeps the account operation code and retryability', () {
      expect(
        AccountFailureDiagnostics.describe(
          const AccountOperationFailure(
            AccountOperationFailureCode.appCheckRequired,
            retryable: false,
          ),
        ),
        'accountOperation:appCheckRequired(retryable:false)',
      );
      expect(
        AccountFailureDiagnostics.describe(
          const AccountOperationFailure(
            AccountOperationFailureCode.unavailable,
            retryable: true,
          ),
        ),
        'accountOperation:unavailable(retryable:true)',
      );
    });

    test('keeps the Functions status code', () {
      expect(
        AccountFailureDiagnostics.describe(
          FirebaseFunctionsException(
            code: 'unauthenticated',
            message: 'ignored',
          ),
        ),
        'functions:unauthenticated',
      );
    });

    test('keeps the Auth error code', () {
      expect(
        AccountFailureDiagnostics.describe(
          FirebaseAuthException(code: 'requires-recent-login'),
        ),
        'auth:requires-recent-login',
      );
    });

    test('reduces an unknown error to its type name', () {
      // toString() 을 부르면 여기서 비밀이 새어 나간다.
      expect(
        AccountFailureDiagnostics.describe(_LeakyError()),
        'other:_LeakyError',
      );
    });

    test('maps timeout and platform failures without their payload', () {
      expect(
        AccountFailureDiagnostics.describe(TimeoutException('ignored')),
        'timeout',
      );
      expect(
        AccountFailureDiagnostics.describe(
          PlatformException(code: 'network_error', details: 'ignored'),
        ),
        'platform:network_error',
      );
    });

    test('null becomes an explicit marker rather than an empty string', () {
      expect(AccountFailureDiagnostics.describe(null), 'none');
    });
  });

  // 이 그룹이 보안 계약 본체다. 새 예외 타입을 describe 에 추가할 때는
  // 반드시 여기에도 케이스를 넣고, 코드 슬러그 외에는 아무것도 안 새는지 본다.
  group('AccountFailureDiagnostics redaction', () {
    void expectNoSecrets(String label) {
      for (final secret in _secrets) {
        expect(
          label,
          isNot(contains(secret)),
          reason: 'redaction leaked "$secret" into the log label "$label"',
        );
      }
    }

    test('Functions message and details never reach the label', () {
      expectNoSecrets(
        AccountFailureDiagnostics.describe(
          FirebaseFunctionsException(
            code: 'permission-denied',
            message: 'denied for uid-YSd21kCD with token-abc123',
            details: {'endpoint': _secrets.last, 'email': 'jin@example.com'},
          ),
        ),
      );
    });

    test('Auth message never reaches the label', () {
      expectNoSecrets(
        AccountFailureDiagnostics.describe(
          FirebaseAuthException(
            code: 'user-mismatch',
            message: 'jin@example.com does not match uid-YSd21kCD',
          ),
        ),
      );
    });

    test('PlatformException details never reach the label', () {
      expectNoSecrets(
        AccountFailureDiagnostics.describe(
          PlatformException(
            code: 'sign_in_failed',
            message: 'token-abc123',
            details: 'uid-YSd21kCD',
          ),
        ),
      );
    });

    test('an unknown error never reaches the label through toString', () {
      expectNoSecrets(AccountFailureDiagnostics.describe(_LeakyError()));
    });

    test('a FormatException never echoes the response body', () {
      expectNoSecrets(
        AccountFailureDiagnostics.describe(
          const FormatException('unexpected token-abc123 in body'),
        ),
      );
    });

    test('a hostile code field cannot break or bloat the log line', () {
      final label = AccountFailureDiagnostics.describe(
        FirebaseFunctionsException(
          code: 'internal\nuid-YSd21kCD ${'x' * 200}',
          message: 'ignored',
        ),
      );
      expect(label, isNot(contains('\n')));
      expect(label.length, lessThanOrEqualTo('functions:'.length + 48));
    });
  });

  group('AccountFailureDiagnostics.describeAll', () {
    test('joins every cause so no failure is silently dropped', () {
      expect(
        AccountFailureDiagnostics.describeAll([
          const AccountOperationFailure(
            AccountOperationFailureCode.authenticationRequired,
            retryable: false,
          ),
          TimeoutException('ignored'),
        ]),
        'accountOperation:authenticationRequired(retryable:false), timeout',
      );
    });

    test('an empty cause list is explicit', () {
      expect(AccountFailureDiagnostics.describeAll(const []), 'none');
    });
  });
}

class _LeakyError implements Exception {
  @override
  String toString() =>
      'LeakyError: token-abc123 uid-YSd21kCD jin@example.com ${_secrets.last}';
}
