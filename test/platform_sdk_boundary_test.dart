import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('platform and SDK calls stay behind their app-owned boundaries', () {
    expect(_filesContaining('Permission.camera.request()'), <String>{
      'lib/screens/book_capture_screen.dart',
      'lib/services/word_image_service.dart',
    });
    expect(
      _filesContaining('NotificationService.requestPermission()'),
      <String>{'lib/screens/settings_screen.dart'},
    );
    expect(_filesContaining('_recorder.requestPermission()'), <String>{
      'lib/screens/pronunciation_studio_screen.dart',
    });
    expect(_filesContaining('Purchases.purchase('), isEmpty);
    expect(_filesContaining('Purchases.restorePurchases()'), isEmpty);
    expect(_filesContaining("pushNamed('/paywall')"), isEmpty);
    expect(_filesContaining('GoogleOAuthClient.signIn()'), <String>{
      'lib/services/auth_service.dart',
    });
    expect(_filesContaining('SignInWithApple.getAppleIDCredential'), <String>{
      'lib/services/account/apple_oauth_request.dart',
    });
  });
}

Set<String> _filesContaining(String token) => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'))
    .where((file) => file.readAsStringSync().contains(token))
    .map((file) => file.path.replaceAll('\\', '/'))
    .toSet();
