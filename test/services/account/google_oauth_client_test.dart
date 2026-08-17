import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/firebase_options.dart';
import 'package:ko_lernen_app/services/account/account_transition_coordinator.dart';
import 'package:ko_lernen_app/services/account/google_oauth_client.dart';
import 'package:ko_lernen_app/services/auth_service.dart';

void main() {
  test('web client ID matches the Android google-services OAuth web client', () {
    final document =
        jsonDecode(File('android/app/google-services.json').readAsStringSync())
            as Map<String, Object?>;
    final clients = document['client'] as List<Object?>;
    final oauthClients =
        ((clients.first as Map<String, Object?>)['oauth_client'] as List<Object?>)
            .cast<Map<String, Object?>>();
    final webClient = oauthClients.singleWhere(
      (client) => client['client_type'] == 3,
    );

    expect(webClient['client_id'], GoogleOAuthClient.webClientId);
  });

  test('iOS reversed client ID matches the committed Firebase iOS client', () {
    expect(
      GoogleOAuthClient.iosClientId,
      DefaultFirebaseOptions.ios.iosClientId,
    );
    expect(
      GoogleOAuthClient.iosReversedClientId,
      'com.googleusercontent.apps.573567222361-uphimptmn43da1snk4hc60rhgjd28ppq',
    );
  });

  test('Info.plist registers the iOS Google Sign-In URL scheme', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, contains(GoogleOAuthClient.iosReversedClientId));
    expect(plist, contains('CFBundleURLSchemes'));
  });

  test('refuses a Google credential without an ID token', () {
    expect(
      () => GoogleOAuthClient.credentialFromTokens(idToken: null),
      throwsA(isA<GoogleOAuthIdTokenMissing>()),
    );
    expect(
      () => GoogleOAuthClient.credentialFromTokens(idToken: '   '),
      throwsA(isA<GoogleOAuthIdTokenMissing>()),
    );
  });

  test('builds a Firebase Google credential only when an ID token exists', () {
    final credential = GoogleOAuthClient.credentialFromTokens(
      idToken: 'id-token',
      accessToken: 'access-token',
    );

    expect(credential.providerId, 'google.com');
  });

  test('a missing Firebase user is unavailable, not a blocked transition', () {
    expect(
      () => AuthService.ensureAnonymousLinkSession(
        hasUser: false,
        isAnonymous: false,
      ),
      throwsA(isA<AccountLinkUnavailable>()),
    );
  });

  test('a durable user cannot start another anonymous provider link', () {
    expect(
      () => AuthService.ensureAnonymousLinkSession(
        hasUser: true,
        isAnonymous: false,
      ),
      throwsA(isA<DurableAccountTransitionNotSupported>()),
    );
  });

  test('an anonymous session is admissible for provider linking', () {
    expect(
      () => AuthService.ensureAnonymousLinkSession(
        hasUser: true,
        isAnonymous: true,
      ),
      returnsNormally,
    );
  });
}
