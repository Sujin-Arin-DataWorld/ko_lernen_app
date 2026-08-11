import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('does not request a runtime orientation restriction', () {
    final mainSource = File('lib/main.dart').readAsStringSync();

    expect(mainSource, isNot(contains('setPreferredOrientations')));
    expect(mainSource, isNot(contains('kAppSupportedOrientations')));
  });

  test('release manifest leaves activities resizable in every orientation', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, isNot(contains('android:screenOrientation')));
    expect(manifest, isNot(contains('android:resizeableActivity="false"')));
    expect(manifest, isNot(contains('android:minAspectRatio')));
    expect(manifest, isNot(contains('android:maxAspectRatio')));
  });

  test('Android startup enables backward-compatible edge-to-edge', () {
    final activity = File(
      'android/app/src/main/kotlin/com/sujinarin/ko_lernen_app/MainActivity.kt',
    ).readAsStringSync();

    expect(
      activity,
      contains('WindowCompat.setDecorFitsSystemWindows(window, false)'),
    );

    final themeFiles = <String>[
      'android/app/src/main/res/values/styles.xml',
      'android/app/src/main/res/values-night/styles.xml',
      'android/app/src/main/res/values-v31/styles.xml',
      'android/app/src/main/res/values-night-v31/styles.xml',
    ];
    for (final path in themeFiles) {
      expect(
        File(path).readAsStringSync(),
        isNot(contains('windowOptOutEdgeToEdgeEnforcement')),
        reason: '$path must not opt out of Android edge-to-edge enforcement.',
      );
    }
  });

  test(
    'Flutter overlay styles do not request deprecated system bar colors',
    () {
      final dartSources = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      expect(
        dartSources.where((file) {
          final source = file.readAsStringSync();
          return source.contains('statusBarColor:') ||
              source.contains('systemNavigationBarColor:');
        }),
        isEmpty,
      );
    },
  );
}
