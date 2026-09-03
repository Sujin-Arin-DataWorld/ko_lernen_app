import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/services/account/account_transition_coordinator.dart';
import 'package:ko_lernen_app/services/account/account_ui_operations.dart';
import 'package:ko_lernen_app/services/account/cloud_backup_deletion.dart';
import 'package:ko_lernen_app/services/account/google_oauth_client.dart';
import 'package:ko_lernen_app/services/account/durable_provider_link.dart';
import 'package:ko_lernen_app/services/account/apple_oauth_configuration.dart';

void main() {
  test('durable collision is not anonymous replacement or generic failure', () {
    final result = mapAccountLinkException(
      const DurableProviderLinkCollision(),
    );
    expect(result, isNot(isA<AccountUiLinkConflict>()));
    expect(result, isNot(isA<AccountUiLinkFailed>()));
  });
  test(
    'missing Apple configuration is unavailable, not silent cancellation',
    () {
      final result = mapAccountLinkException(
        const AppleOAuthConfigurationMissing(),
      );
      expect(result, isNot(isA<AccountUiLinkCancelled>()));
      expect(result, isNot(isA<AccountUiLinkFailed>()));
    },
  );
  test('user-cancel platform codes stay cancelled, not failed', () {
    for (final code in <String>[
      'sign_in_canceled',
      'sign_in_cancelled',
      'canceled',
      'reauth-cancelled',
      'target-verification-cancelled',
    ]) {
      expect(isUserCancelledAuthCode(code), isTrue);
      expect(
        mapAccountLinkException(PlatformException(code: code)),
        isA<AccountUiLinkCancelled>(),
      );
    }
  });

  test('a missing Google ID token is a retryable server failure', () {
    expect(
      mapAccountLinkException(const GoogleOAuthIdTokenMissing()),
      isA<AccountUiLinkFailed>().having(
        (result) => result.reason,
        'reason',
        AccountUiLinkFailureReason.serverError,
      ),
    );
  });

  test('journal and identity fences stay blocked', () {
    expect(
      mapAccountLinkException(const DurableAccountTransitionNotSupported()),
      isA<AccountUiLinkBlocked>(),
    );
    expect(
      mapAccountLinkException(
        const CloudBackupDeletionIdentityChangeBlockedException(),
      ),
      isA<AccountUiLinkBlocked>(),
    );
  });

  test('Firebase unavailability stays distinct from cancel', () {
    expect(
      mapAccountLinkException(const AccountLinkUnavailable()),
      isA<AccountUiLinkUnavailable>(),
    );
  });

  test('existing-account collisions stay typed conflicts', () {
    expect(
      mapAccountLinkException(
        const ExistingAccountLinkConflict(AccountLinkProvider.google),
      ),
      isA<AccountUiLinkConflict>(),
    );
  });

  test('network Firebase codes stay offline', () {
    expect(
      mapAccountLinkException(
        FirebaseAuthException(code: 'network-request-failed'),
      ),
      isA<AccountUiLinkFailed>().having(
        (result) => result.reason,
        'reason',
        AccountUiLinkFailureReason.offline,
      ),
    );
  });
}
