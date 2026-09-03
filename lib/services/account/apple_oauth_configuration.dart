import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleOAuthConfigurationMissing implements Exception {
  const AppleOAuthConfigurationMissing();
}

/// Public, release-specific Apple console metadata. Never guess production IDs.
class AppleOAuthConfiguration {
  const AppleOAuthConfiguration({
    required this.servicesId,
    required this.redirectUrl,
  });

  static const fromEnvironment = AppleOAuthConfiguration(
    servicesId: String.fromEnvironment('APPLE_SERVICES_ID'),
    redirectUrl: String.fromEnvironment('APPLE_REDIRECT_URI'),
  );
  final String servicesId;
  final String redirectUrl;

  WebAuthenticationOptions requireWebOptions() {
    final uri = Uri.tryParse(redirectUrl);
    if (!RegExp(r'^[A-Za-z0-9]+(?:[.-][A-Za-z0-9]+)+$').hasMatch(servicesId) ||
        uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        !uri.host.contains('.') ||
        uri.host.endsWith('.localhost') ||
        RegExp(r'^[0-9.]+$').hasMatch(uri.host) ||
        uri.host.contains(':') ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment ||
        uri.hasQuery ||
        uri.hasPort ||
        uri.path.isEmpty ||
        redirectUrl.trim() != redirectUrl) {
      throw const AppleOAuthConfigurationMissing();
    }
    return WebAuthenticationOptions(clientId: servicesId, redirectUri: uri);
  }
}
