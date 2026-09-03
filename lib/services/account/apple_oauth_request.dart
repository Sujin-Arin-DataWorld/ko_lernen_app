import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'account_transition_coordinator.dart';
import 'apple_oauth_configuration.dart';

typedef AppleCredentialRequester =
    Future<AuthorizationCredentialAppleID> Function({
      required List<AppleIDAuthorizationScopes> scopes,
      WebAuthenticationOptions? webAuthenticationOptions,
      String? nonce,
      String? state,
    });

/// The SDK owns the browser/native UI; our boundary enforces one-use state and
/// a bounded wait. Firebase subsequently verifies the ID token and raw nonce.
Future<AuthorizationCredentialAppleID> requestAppleOAuthCredential({
  required bool android,
  required String nonce,
  required String state,
  required bool includeFullName,
  AppleOAuthConfiguration configuration =
      AppleOAuthConfiguration.fromEnvironment,
  AppleCredentialRequester request = SignInWithApple.getAppleIDCredential,
  Duration timeout = const Duration(minutes: 3),
}) async {
  final options = android ? configuration.requireWebOptions() : null;
  final result =
      await request(
        scopes: [
          AppleIDAuthorizationScopes.email,
          if (includeFullName) AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
        state: state,
        webAuthenticationOptions: options,
      ).timeout(
        timeout,
        onTimeout: () {
          throw const SignInWithAppleAuthorizationException(
            code: AuthorizationErrorCode.canceled,
            message: 'Apple authentication timed out.',
          );
        },
      );
  if (state.isEmpty ||
      result.state != state ||
      result.identityToken?.isNotEmpty != true) {
    throw const AccountLinkSafetyFailure();
  }
  return result;
}
