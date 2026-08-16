import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('proofreading stays optional without raising the base Android SDK', () {
    final baseBuild = File('android/app/build.gradle.kts').readAsStringSync();
    final featureBuild = File(
      'android/proofreading_feature/build.gradle.kts',
    ).readAsStringSync();
    final featureManifest = File(
      'android/proofreading_feature/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(baseBuild, contains('minSdk = 24'));
    expect(
      baseBuild,
      contains('dynamicFeatures += setOf(":proofreading_feature")'),
    );
    expect(baseBuild, isNot(contains('genai-proofreading')));
    expect(featureBuild, contains('minSdk = 24'));
    expect(
      featureBuild,
      contains('com.google.mlkit:genai-proofreading:1.0.0-beta1'),
    );
    expect(featureManifest, contains('<dist:min-sdk dist:value="26" />'));
    expect(featureManifest, contains('<dist:fusing dist:include="false" />'));
  });

  test('the Play feature title is available in English and German', () {
    final defaultStrings = File(
      'android/app/src/main/res/values/strings.xml',
    ).readAsStringSync();
    final germanStrings = File(
      'android/app/src/main/res/values-de/strings.xml',
    ).readAsStringSync();

    expect(defaultStrings, contains('>Korean proofreading</string>'));
    expect(germanStrings, contains('>Koreanische Textkorrektur</string>'));
  });
}
