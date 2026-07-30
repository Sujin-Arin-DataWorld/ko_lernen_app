import 'package:flutter_test/flutter_test.dart';

import '../tool/verify_ios_firebase_config.dart';

void main() {
  test('release configuration rejects an absent iOS Firebase option', () {
    const fixtureWithoutIos = '''
class DefaultFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions();
}
''';

    final result = inspectIosFirebaseConfiguration(
      firebaseOptionsSource: fixtureWithoutIos,
      plistExists: true,
      projectSource: 'GoogleService-Info.plist',
    );

    expect(result.isValid, isFalse);
    expect(result.missing, contains('firebase_options iOS'));
  });
}
