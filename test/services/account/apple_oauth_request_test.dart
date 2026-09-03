import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:ko_lernen_app/services/account/apple_oauth_configuration.dart';
import 'package:ko_lernen_app/services/account/apple_oauth_request.dart';
import 'package:ko_lernen_app/services/account/account_transition_coordinator.dart';

AuthorizationCredentialAppleID response({
  String? state = 'random-state',
  String? token = 'signed.id.token',
}) => AuthorizationCredentialAppleID(
  userIdentifier: null,
  givenName: null,
  familyName: null,
  email: null,
  authorizationCode: 'one-use-code',
  identityToken: token,
  state: state,
);

void main() {
  const configuration = AppleOAuthConfiguration(
    servicesId: 'com.example.web',
    redirectUrl: 'https://auth.example.com/callback',
  );

  test(
    'Android request binds nonce/state and configured Services ID at real SDK boundary',
    () async {
      final result = await requestAppleOAuthCredential(
        android: true,
        nonce: 'nonce-hash',
        state: 'random-state',
        includeFullName: false,
        configuration: configuration,
        request:
            ({required scopes, webAuthenticationOptions, nonce, state}) async {
              expect(nonce, 'nonce-hash');
              expect(state, 'random-state');
              expect(webAuthenticationOptions!.clientId, 'com.example.web');
              expect(scopes, [AppleIDAuthorizationScopes.email]);
              return response();
            },
      );
      expect(result.authorizationCode, 'one-use-code');
    },
  );
  test('native Apple does not require Android metadata', () async {
    await requestAppleOAuthCredential(
      android: false,
      nonce: 'hash',
      state: 'random-state',
      includeFullName: true,
      request:
          ({required scopes, webAuthenticationOptions, nonce, state}) async {
            expect(webAuthenticationOptions, isNull);
            expect(scopes, contains(AppleIDAuthorizationScopes.fullName));
            return response();
          },
    );
  });
  for (final result in [
    response(state: 'foreign-state'),
    response(state: null),
    response(token: ''),
  ]) {
    test('unbound Apple response is rejected', () async {
      await expectLater(
        requestAppleOAuthCredential(
          android: true,
          nonce: 'hash',
          state: 'random-state',
          includeFullName: false,
          configuration: configuration,
          request:
              ({
                required scopes,
                webAuthenticationOptions,
                nonce,
                state,
              }) async => result,
        ),
        throwsA(isA<AccountLinkSafetyFailure>()),
      );
    });
  }
  test('missing configuration never opens SDK', () async {
    await expectLater(
      requestAppleOAuthCredential(
        android: true,
        nonce: 'hash',
        state: 'random-state',
        includeFullName: false,
        request:
            ({required scopes, webAuthenticationOptions, nonce, state}) async {
              fail('must not open SDK');
            },
      ),
      throwsA(isA<AppleOAuthConfigurationMissing>()),
    );
  });
  test(
    'stalled browser result times out and late credentials stay unused',
    () async {
      final pending = Completer<AuthorizationCredentialAppleID>();
      await expectLater(
        requestAppleOAuthCredential(
          android: true,
          nonce: 'hash',
          state: 'random-state',
          includeFullName: false,
          configuration: configuration,
          timeout: Duration.zero,
          request:
              ({required scopes, webAuthenticationOptions, nonce, state}) =>
                  pending.future,
        ),
        throwsA(
          isA<SignInWithAppleAuthorizationException>().having(
            (e) => e.code,
            'code',
            AuthorizationErrorCode.canceled,
          ),
        ),
      );
      pending.complete(response());
    },
  );
}
