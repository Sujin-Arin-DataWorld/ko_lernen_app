import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/services/account/account_transition_coordinator.dart';

void main() {
  test(
    'attemptAnonymousCredentialLink forwards the credential into the conflict',
    () async {
      final credential = GoogleAuthProvider.credential(
        idToken: 'id-token',
        accessToken: 'access-token',
      );

      final result = await attemptAnonymousCredentialLink<String>(
        provider: AccountLinkProvider.google,
        sourceUid: 'anonymous-source',
        currentUid: () => 'anonymous-source',
        linkCredential: () async {
          throw FirebaseAuthException(code: 'credential-already-in-use');
        },
        credential: credential,
      );

      expect(result, isA<ExistingAccountLinkConflict>());
      expect(
        (result as ExistingAccountLinkConflict).credential,
        same(credential),
      );
    },
  );
}
