import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../firebase_options.dart';

/// Google Sign-In finished but Firebase never received an ID token.
///
/// Android/iOS only mint a Firebase-usable ID token when the **web** OAuth
/// client is supplied as `serverClientId`. A missing token used to become a
/// null-credential `linkWithCredential` / reauth failure, so linking and
/// account deletion both looked like "the button does nothing".
class GoogleOAuthIdTokenMissing implements Exception {
  const GoogleOAuthIdTokenMissing();

  @override
  String toString() =>
      'Google Sign-In did not return an ID token for Firebase Auth.';
}

/// Consistent [GoogleSignIn] configuration for link / reauth / sign-out paths.
class GoogleOAuthClient {
  const GoogleOAuthClient._();

  /// Web OAuth client from `android/app/google-services.json` (`client_type` 3).
  static const webClientId =
      '573567222361-spcm503sda3g4qftb21lqbogehk4nic8.apps.googleusercontent.com';

  static const _googleusercontentSuffix = '.apps.googleusercontent.com';

  static String get iosClientId {
    final clientId = DefaultFirebaseOptions.ios.iosClientId?.trim();
    if (clientId == null || clientId.isEmpty) {
      throw const AccountGoogleOAuthConfigurationException();
    }
    return clientId;
  }

  /// iOS URL scheme required for the Google Sign-In redirect.
  static String get iosReversedClientId {
    final clientId = iosClientId;
    if (!clientId.endsWith(_googleusercontentSuffix)) {
      throw const AccountGoogleOAuthConfigurationException();
    }
    return 'com.googleusercontent.apps.${clientId.substring(0, clientId.length - _googleusercontentSuffix.length)}';
  }

  static bool get _usesIosClientId =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  static GoogleSignIn instance() {
    return GoogleSignIn(
      scopes: const <String>['email'],
      clientId: _usesIosClientId ? iosClientId : null,
      serverClientId: webClientId,
    );
  }

  static Future<GoogleSignInAccount?> signIn() => instance().signIn();

  /// Google Sign-In 6.x can return a cached account without opening native UI.
  /// Clear only this provider's SDK session, never Firebase or granted access,
  /// then fence the account before starting the explicit chooser.
  static Future<GoogleSignInAccount?> signInFresh({
    required void Function() assertCurrent,
    GoogleSignIn? client,
  }) async {
    final google = client ?? instance();
    assertCurrent();
    try {
      await google.signOut();
    } finally {
      assertCurrent();
    }
    try {
      return await google.signIn();
    } finally {
      assertCurrent();
    }
  }

  static Future<GoogleSignInAccount?> signInSilently({
    bool suppressErrors = true,
    bool reAuthenticate = false,
  }) {
    return instance().signInSilently(
      suppressErrors: suppressErrors,
      reAuthenticate: reAuthenticate,
    );
  }

  static Future<void> signOut() => instance().signOut();

  static AuthCredential credentialFromTokens({
    required String? idToken,
    String? accessToken,
  }) {
    final token = idToken?.trim();
    if (token == null || token.isEmpty) {
      throw const GoogleOAuthIdTokenMissing();
    }
    return GoogleAuthProvider.credential(
      accessToken: accessToken,
      idToken: token,
    );
  }

  static AuthCredential credentialFromAuthentication(
    GoogleSignInAuthentication authentication,
  ) {
    return credentialFromTokens(
      idToken: authentication.idToken,
      accessToken: authentication.accessToken,
    );
  }
}

class AccountGoogleOAuthConfigurationException implements Exception {
  const AccountGoogleOAuthConfigurationException();

  @override
  String toString() =>
      'The iOS Google OAuth client ID is missing or not a Google client.';
}
