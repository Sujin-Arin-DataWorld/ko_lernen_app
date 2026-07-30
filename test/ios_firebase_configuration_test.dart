import 'package:flutter_test/flutter_test.dart';

import '../tool/verify_ios_firebase_config.dart';

const _firebaseOptionsWithIos = '''
class DefaultFirebaseOptions {
  static const FirebaseOptions ios = FirebaseOptions();
}
''';

const _firebaseOptionsWithoutIos = '''
class DefaultFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions();
}
''';

const _validProjectSource = '''
/* Begin PBXBuildFile section */
  PLIST_BUILD /* GoogleService-Info.plist in Resources */ = {isa = PBXBuildFile; };
/* End PBXBuildFile section */
/* Begin PBXNativeTarget section */
  RUNNER_TARGET /* Runner */ = {
    isa = PBXNativeTarget;
    buildPhases = (
      RUNNER_RESOURCES /* Resources */,
    );
    name = Runner;
  };
/* End PBXNativeTarget section */
/* Begin PBXResourcesBuildPhase section */
  RUNNER_RESOURCES /* Resources */ = {
    isa = PBXResourcesBuildPhase;
    files = (
      PLIST_BUILD /* GoogleService-Info.plist in Resources */,
    );
  };
/* End PBXResourcesBuildPhase section */
''';

const _projectWithPlistOnlyInRunnerTests = '''
/* Begin PBXBuildFile section */
  PLIST_BUILD /* GoogleService-Info.plist in Resources */ = {isa = PBXBuildFile; };
/* End PBXBuildFile section */
/* Begin PBXNativeTarget section */
  RUNNER_TARGET /* Runner */ = {
    isa = PBXNativeTarget;
    buildPhases = (
      RUNNER_RESOURCES /* Resources */,
    );
    name = Runner;
  };
  TEST_TARGET /* RunnerTests */ = {
    isa = PBXNativeTarget;
    buildPhases = (
      TEST_RESOURCES /* Resources */,
    );
    name = RunnerTests;
  };
/* End PBXNativeTarget section */
/* Begin PBXResourcesBuildPhase section */
  RUNNER_RESOURCES /* Resources */ = {
    isa = PBXResourcesBuildPhase;
    files = (
    );
  };
  TEST_RESOURCES /* Resources */ = {
    isa = PBXResourcesBuildPhase;
    files = (
      PLIST_BUILD /* GoogleService-Info.plist in Resources */,
    );
  };
/* End PBXResourcesBuildPhase section */
''';

const _projectWithStalePlistBuildFile = '''
/* Begin PBXBuildFile section */
  PLIST_BUILD /* GoogleService-Info.plist in Resources */ = {isa = PBXBuildFile; };
/* End PBXBuildFile section */
/* Begin PBXNativeTarget section */
  RUNNER_TARGET /* Runner */ = {
    isa = PBXNativeTarget;
    buildPhases = (
      RUNNER_RESOURCES /* Resources */,
    );
    name = Runner;
  };
/* End PBXNativeTarget section */
/* Begin PBXResourcesBuildPhase section */
  RUNNER_RESOURCES /* Resources */ = {
    isa = PBXResourcesBuildPhase;
    files = (
    );
  };
/* End PBXResourcesBuildPhase section */
''';

void main() {
  test('release configuration accepts a complete Runner configuration', () {
    final result = inspectIosFirebaseConfiguration(
      firebaseOptionsSource: _firebaseOptionsWithIos,
      plistExists: true,
      projectSource: _validProjectSource,
    );

    expect(result.isValid, isTrue);
    expect(result.missing, isEmpty);
  });

  test('release configuration rejects an absent iOS Firebase option', () {
    final result = inspectIosFirebaseConfiguration(
      firebaseOptionsSource: _firebaseOptionsWithoutIos,
      plistExists: true,
      projectSource: _validProjectSource,
    );

    expect(result.isValid, isFalse);
    expect(result.missing, <String>['firebase_options iOS']);
  });

  test('release configuration rejects a missing local plist', () {
    final result = inspectIosFirebaseConfiguration(
      firebaseOptionsSource: _firebaseOptionsWithIos,
      plistExists: false,
      projectSource: _validProjectSource,
    );

    expect(result.isValid, isFalse);
    expect(result.missing, <String>['ios/Runner/GoogleService-Info.plist']);
  });

  test(
    'release configuration rejects plist membership only in RunnerTests',
    () {
      final result = inspectIosFirebaseConfiguration(
        firebaseOptionsSource: _firebaseOptionsWithIos,
        plistExists: true,
        projectSource: _projectWithPlistOnlyInRunnerTests,
      );

      expect(result.isValid, isFalse);
      expect(result.missing, <String>[
        'Xcode Runner target membership for GoogleService-Info.plist',
      ]);
    },
  );

  test(
    'release configuration rejects an unreferenced plist build-file entry',
    () {
      final result = inspectIosFirebaseConfiguration(
        firebaseOptionsSource: _firebaseOptionsWithIos,
        plistExists: true,
        projectSource: _projectWithStalePlistBuildFile,
      );

      expect(result.isValid, isFalse);
      expect(result.missing, <String>[
        'Xcode Runner target membership for GoogleService-Info.plist',
      ]);
    },
  );
}
