import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/apple_oauth_configuration.dart';

void main() {
  test('valid registered web metadata produces SDK options', () {
    final options = const AppleOAuthConfiguration(
      servicesId: 'com.example.apple.web',
      redirectUrl: 'https://auth.example.com/apple/callback',
    ).requireWebOptions();
    expect(options.clientId, 'com.example.apple.web');
    expect(
      options.redirectUri.toString(),
      'https://auth.example.com/apple/callback',
    );
  });
  for (final url in [
    '',
    'http://auth.example.com/callback',
    'https://localhost/cb',
    'https://127.0.0.1/cb',
    'https://example.com/cb#fragment',
    'https://user:pass@example.com/cb',
    'https://example.com/cb?next=other',
  ]) {
    test('rejects unsafe or missing callback $url', () {
      expect(
        () => AppleOAuthConfiguration(
          servicesId: 'com.example.web',
          redirectUrl: url,
        ).requireWebOptions(),
        throwsA(isA<AppleOAuthConfigurationMissing>()),
      );
    });
  }
  test('missing Services ID fails before SDK launch', () {
    expect(
      () => const AppleOAuthConfiguration(
        servicesId: '',
        redirectUrl: 'https://auth.example.com/cb',
      ).requireWebOptions(),
      throwsA(isA<AppleOAuthConfigurationMissing>()),
    );
  });
}
