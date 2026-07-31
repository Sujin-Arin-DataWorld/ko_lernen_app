import 'package:flutter_test/flutter_test.dart';

import '../tool/verify_ios_firebase_config.dart';

const _firebaseOptionsWithLiveIos = '''
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions();
  static const FirebaseOptions ios = FirebaseOptions();
}
''';

const _firebaseOptionsWithoutIos = '''
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => android;
  static const FirebaseOptions android = FirebaseOptions();
}
''';

const _firebaseOptionsWithCommentOnlyIos = '''
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => android;
  static const FirebaseOptions android = FirebaseOptions();
  // static const FirebaseOptions ios = FirebaseOptions();
  /*
  case TargetPlatform.iOS:
    return ios;
  */
}
''';

const _firebaseOptionsWithDeadIos = '''
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS is not configured');
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions();
  static const FirebaseOptions ios = FirebaseOptions();
}
''';

const _firebaseOptionsWithDecoyIosString = r'''
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    const decoy = 'case TargetPlatform.iOS: return ios;';
    if (decoy.isEmpty) {
      throw StateError('unreachable');
    }
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions();
  static const FirebaseOptions ios = FirebaseOptions();
}
''';

const _firebaseOptionsWithUnreachableIosBranch = '''
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (false) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          return ios;
        default:
          return android;
      }
    }
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions();
  static const FirebaseOptions ios = FirebaseOptions();
}
''';

const _firebaseOptionsWithShadowedIos = '''
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    final FirebaseOptions ios = FirebaseOptions();
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions();
  static const FirebaseOptions ios = FirebaseOptions();
}
''';

const _firebaseOptionsWithPatternShadowedIos = '''
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    final (ios,) = (android,);
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions();
  static const FirebaseOptions ios = FirebaseOptions();
}
''';

const _validPlist = '''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
  <dict>
    <key>GOOGLE_APP_ID</key>
    <string>unit-test-app</string>
  </dict>
</plist>
''';

const _validProjectSource = '''
/* Begin PBXBuildFile section */
  PLIST_BUILD /* GoogleService-Info.plist in Resources */ = {
    isa = PBXBuildFile;
    fileRef = PLIST_REF /* GoogleService-Info.plist */;
  };
/* End PBXBuildFile section */
/* Begin PBXFileReference section */
  PLIST_REF /* GoogleService-Info.plist */ = {
    isa = PBXFileReference;
    lastKnownFileType = text.plist.xml;
    path = GoogleService-Info.plist;
    sourceTree = "<group>";
  };
/* End PBXFileReference section */
/* Begin PBXGroup section */
  ROOT_GROUP = {
    isa = PBXGroup;
    children = (
      RUNNER_GROUP /* Runner */,
    );
    sourceTree = "<group>";
  };
  RUNNER_GROUP /* Runner */ = {
    isa = PBXGroup;
    children = (
      PLIST_REF /* GoogleService-Info.plist */,
    );
    path = Runner;
    sourceTree = "<group>";
  };
/* End PBXGroup section */
/* Begin PBXProject section */
  PROJECT_OBJECT /* Project object */ = {
    isa = PBXProject;
    mainGroup = ROOT_GROUP;
  };
/* End PBXProject section */
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

const _commentOnlyPbxGraph = '''
/*
  PLIST_BUILD = {
    isa = PBXBuildFile;
    fileRef = PLIST_REF;
  };
  PLIST_REF = {
    isa = PBXFileReference;
    path = GoogleService-Info.plist;
    sourceTree = "<group>";
  };
  ROOT_GROUP = {
    isa = PBXGroup;
    children = (
      RUNNER_GROUP,
    );
    sourceTree = "<group>";
  };
  RUNNER_GROUP = {
    isa = PBXGroup;
    children = (
      PLIST_REF,
    );
    path = Runner;
    sourceTree = "<group>";
  };
  PROJECT_OBJECT = {
    isa = PBXProject;
    mainGroup = ROOT_GROUP;
  };
  RUNNER_TARGET = {
    isa = PBXNativeTarget;
    buildPhases = (
      RUNNER_RESOURCES,
    );
    name = Runner;
  };
  RUNNER_RESOURCES = {
    isa = PBXResourcesBuildPhase;
    files = (
      PLIST_BUILD,
    );
  };
*/
''';

String _projectWith({
  String buildFileReference = 'PLIST_REF',
  String fileReferencePath = 'GoogleService-Info.plist',
  bool memberOfRunnerGroup = true,
  bool memberOfRunnerResources = true,
  bool runnerGroupReachable = true,
}) {
  return _validProjectSource
      .replaceFirst(
        'fileRef = PLIST_REF /* GoogleService-Info.plist */;',
        'fileRef = $buildFileReference /* GoogleService-Info.plist */;',
      )
      .replaceFirst(
        'path = GoogleService-Info.plist;',
        'path = $fileReferencePath;',
      )
      .replaceFirst(
        '      PLIST_REF /* GoogleService-Info.plist */,\n',
        memberOfRunnerGroup
            ? '      PLIST_REF /* GoogleService-Info.plist */,\n'
            : '',
      )
      .replaceFirst(
        '      PLIST_BUILD /* GoogleService-Info.plist in Resources */,\n',
        memberOfRunnerResources
            ? '      PLIST_BUILD /* GoogleService-Info.plist in Resources */,\n'
            : '',
      )
      .replaceFirst(
        '      RUNNER_GROUP /* Runner */,\n',
        runnerGroupReachable ? '      RUNNER_GROUP /* Runner */,\n' : '',
      );
}

void main() {
  test(
    'release configuration accepts a complete live Runner configuration',
    () {
      final result = inspectIosFirebaseConfiguration(
        firebaseOptionsSource: _firebaseOptionsWithLiveIos,
        plistSource: _validPlist,
        projectSource: _validProjectSource,
      );

      expect(result.isValid, isTrue);
      expect(result.missing, isEmpty);
    },
  );

  test('release configuration rejects an absent iOS Firebase option', () {
    final result = inspectIosFirebaseConfiguration(
      firebaseOptionsSource: _firebaseOptionsWithoutIos,
      plistSource: _validPlist,
      projectSource: _validProjectSource,
    );

    expect(result.isValid, isFalse);
    expect(result.missing, <String>['firebase_options iOS']);
  });

  test('release configuration rejects comment-only iOS source text', () {
    final result = inspectIosFirebaseConfiguration(
      firebaseOptionsSource: _firebaseOptionsWithCommentOnlyIos,
      plistSource: _validPlist,
      projectSource: _validProjectSource,
    );

    expect(result.missing, contains('firebase_options iOS'));
  });

  test('release configuration rejects an iOS declaration that currentPlatform '
      'does not select', () {
    final result = inspectIosFirebaseConfiguration(
      firebaseOptionsSource: _firebaseOptionsWithDeadIos,
      plistSource: _validPlist,
      projectSource: _validProjectSource,
    );

    expect(result.missing, contains('firebase_options iOS'));
  });

  test('release configuration rejects an iOS decoy inside a string', () {
    final result = inspectIosFirebaseConfiguration(
      firebaseOptionsSource: _firebaseOptionsWithDecoyIosString,
      plistSource: _validPlist,
      projectSource: _validProjectSource,
    );

    expect(result.missing, contains('firebase_options iOS'));
  });

  test('release configuration rejects an unreachable nested iOS branch', () {
    final result = inspectIosFirebaseConfiguration(
      firebaseOptionsSource: _firebaseOptionsWithUnreachableIosBranch,
      plistSource: _validPlist,
      projectSource: _validProjectSource,
    );

    expect(result.missing, contains('firebase_options iOS'));
  });

  test('release configuration rejects an iOS return shadowed by a local', () {
    final result = inspectIosFirebaseConfiguration(
      firebaseOptionsSource: _firebaseOptionsWithShadowedIos,
      plistSource: _validPlist,
      projectSource: _validProjectSource,
    );

    expect(result.missing, <String>['firebase_options iOS']);
  });

  test('release configuration rejects an iOS return shadowed by a pattern', () {
    final result = inspectIosFirebaseConfiguration(
      firebaseOptionsSource: _firebaseOptionsWithPatternShadowedIos,
      plistSource: _validPlist,
      projectSource: _validProjectSource,
    );

    expect(result.missing, <String>['firebase_options iOS']);
  });

  test('release configuration rejects a missing local plist', () {
    final result = inspectIosFirebaseConfiguration(
      firebaseOptionsSource: _firebaseOptionsWithLiveIos,
      plistSource: null,
      projectSource: _validProjectSource,
    );

    expect(result.missing, <String>['ios/Runner/GoogleService-Info.plist']);
  });

  test('release configuration rejects an empty or malformed plist', () {
    for (final plistSource in <String>[
      '',
      '<plist><dict>',
      '<plist><dict/></plist>',
    ]) {
      final result = inspectIosFirebaseConfiguration(
        firebaseOptionsSource: _firebaseOptionsWithLiveIos,
        plistSource: plistSource,
        projectSource: _validProjectSource,
      );

      expect(
        result.missing,
        contains('parseable ios/Runner/GoogleService-Info.plist'),
        reason: 'plist fixture: $plistSource',
      );
    }
  });

  test('release configuration rejects a Runner resource build file pointing '
      'at a different fileRef', () {
    final result = inspectIosFirebaseConfiguration(
      firebaseOptionsSource: _firebaseOptionsWithLiveIos,
      plistSource: _validPlist,
      projectSource: _projectWith(buildFileReference: 'OTHER_REF'),
    );

    expect(result.missing, <String>[
      'Xcode Runner target membership for GoogleService-Info.plist',
    ]);
  });

  test(
    'release configuration rejects a plist fileRef with the wrong exact path',
    () {
      final result = inspectIosFirebaseConfiguration(
        firebaseOptionsSource: _firebaseOptionsWithLiveIos,
        plistSource: _validPlist,
        projectSource: _projectWith(fileReferencePath: 'Other.plist'),
      );

      expect(result.missing, <String>[
        'Xcode Runner target membership for GoogleService-Info.plist',
      ]);
    },
  );

  test(
    'release configuration rejects plist membership outside the Runner group',
    () {
      final result = inspectIosFirebaseConfiguration(
        firebaseOptionsSource: _firebaseOptionsWithLiveIos,
        plistSource: _validPlist,
        projectSource: _projectWith(memberOfRunnerGroup: false),
      );

      expect(result.missing, <String>[
        'Xcode Runner target membership for GoogleService-Info.plist',
      ]);
    },
  );

  test(
    'release configuration rejects membership in a detached fake Runner group',
    () {
      final result = inspectIosFirebaseConfiguration(
        firebaseOptionsSource: _firebaseOptionsWithLiveIos,
        plistSource: _validPlist,
        projectSource: _projectWith(runnerGroupReachable: false),
      );

      expect(result.missing, <String>[
        'Xcode Runner target membership for GoogleService-Info.plist',
      ]);
    },
  );

  test(
    'release configuration rejects an unreferenced plist build-file entry',
    () {
      final result = inspectIosFirebaseConfiguration(
        firebaseOptionsSource: _firebaseOptionsWithLiveIos,
        plistSource: _validPlist,
        projectSource: _projectWith(memberOfRunnerResources: false),
      );

      expect(result.missing, <String>[
        'Xcode Runner target membership for GoogleService-Info.plist',
      ]);
    },
  );

  test('release configuration rejects a PBX graph inside a block comment', () {
    final result = inspectIosFirebaseConfiguration(
      firebaseOptionsSource: _firebaseOptionsWithLiveIos,
      plistSource: _validPlist,
      projectSource: _commentOnlyPbxGraph,
    );

    expect(result.missing, <String>[
      'Xcode Runner target membership for GoogleService-Info.plist',
    ]);
  });
}
