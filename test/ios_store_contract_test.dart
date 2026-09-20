import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/verify_ios_store_contract.dart';

const _validProject = '''
/* Begin PBXBuildFile section */
  INFO_STRINGS_BUILD /* InfoPlist.strings in Resources */ = {
    isa = PBXBuildFile;
    fileRef = INFO_STRINGS_GROUP /* InfoPlist.strings */;
  };
  PRIVACY_MANIFEST_BUILD /* PrivacyInfo.xcprivacy in Resources */ = {
    isa = PBXBuildFile;
    fileRef = PRIVACY_MANIFEST /* PrivacyInfo.xcprivacy */;
  };
/* End PBXBuildFile section */
/* Begin PBXFileReference section */
  DE_STRINGS /* de */ = {
    isa = PBXFileReference;
    name = de;
    path = de.lproj/InfoPlist.strings;
    sourceTree = "<group>";
  };
  EN_STRINGS /* en */ = {
    isa = PBXFileReference;
    name = en;
    path = en.lproj/InfoPlist.strings;
    sourceTree = "<group>";
  };
  PRIVACY_MANIFEST /* PrivacyInfo.xcprivacy */ = {
    isa = PBXFileReference;
    path = PrivacyInfo.xcprivacy;
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
      INFO_STRINGS_GROUP /* InfoPlist.strings */,
      PRIVACY_MANIFEST /* PrivacyInfo.xcprivacy */,
    );
    path = Runner;
    sourceTree = "<group>";
  };
/* End PBXGroup section */
/* Begin PBXProject section */
  PROJECT_OBJECT /* Project object */ = {
    isa = PBXProject;
    mainGroup = ROOT_GROUP;
    knownRegions = (
      en,
      de,
      Base,
    );
  };
/* End PBXProject section */
/* Begin PBXNativeTarget section */
  RUNNER_TARGET /* Runner */ = {
    isa = PBXNativeTarget;
    buildPhases = (
      RUNNER_RESOURCES /* Resources */,
    );
    name = Runner;
    buildSettings = {
      PRODUCT_BUNDLE_IDENTIFIER = com.sujinarin.koLernenApp;
      IPHONEOS_DEPLOYMENT_TARGET = 13.0;
      TARGETED_DEVICE_FAMILY = "1,2";
    };
  };
/* End PBXNativeTarget section */
/* Begin PBXResourcesBuildPhase section */
  RUNNER_RESOURCES /* Resources */ = {
    isa = PBXResourcesBuildPhase;
    files = (
      INFO_STRINGS_BUILD /* InfoPlist.strings in Resources */,
      PRIVACY_MANIFEST_BUILD /* PrivacyInfo.xcprivacy in Resources */,
    );
  };
/* End PBXResourcesBuildPhase section */
/* Begin PBXVariantGroup section */
  INFO_STRINGS_GROUP /* InfoPlist.strings */ = {
    isa = PBXVariantGroup;
    children = (
      DE_STRINGS /* de */,
      EN_STRINGS /* en */,
    );
    name = InfoPlist.strings;
    sourceTree = "<group>";
  };
/* End PBXVariantGroup section */
''';

const _validInfoPlist = '''
<plist><dict>
<key>UISupportedInterfaceOrientations~ipad</key>
<array>
  <string>UIInterfaceOrientationPortrait</string>
  <string>UIInterfaceOrientationPortraitUpsideDown</string>
  <string>UIInterfaceOrientationLandscapeLeft</string>
  <string>UIInterfaceOrientationLandscapeRight</string>
</array>
<key>NSCameraUsageDescription</key><string>Fallback camera text</string>
<key>NSPhotoLibraryUsageDescription</key><string>Fallback photo text</string>
</dict></plist>
''';

const _validPrivacyManifest = '''
<plist><dict>
<key>NSPrivacyAccessedAPITypes</key><array/>
<key>NSPrivacyCollectedDataTypes</key><array/>
</dict></plist>
''';

const _validAppIcon = '''
{"images":[
  {"size":"83.5x83.5","idiom":"ipad","scale":"2x"},
  {"size":"1024x1024","idiom":"ios-marketing","scale":"1x"}
]}
''';

const _validDeStrings = '''
"NSCameraUsageDescription" = "Hangul Sori verwendet die Kamera, um Lehrbuchseiten zu fotografieren und koreanische Wörter auf deinem Gerät zu erkennen.";
"NSPhotoLibraryUsageDescription" = "Hangul Sori ermöglicht dir, ein Foto einer Lehrbuchseite auszuwählen, um koreanische Wörter auf deinem Gerät zu erkennen.";
''';

const _validEnStrings = '''
"NSCameraUsageDescription" = "Hangul Sori uses the camera to photograph textbook pages and recognize Korean words on your device.";
"NSPhotoLibraryUsageDescription" = "Hangul Sori lets you select a textbook-page photo to recognize Korean words on your device.";
''';

IosStoreContractResult _inspect({
  String projectSource = _validProject,
  String infoPlistSource = _validInfoPlist,
  String privacyManifestSource = _validPrivacyManifest,
  String appIconSource = _validAppIcon,
  String deStringsSource = _validDeStrings,
  String enStringsSource = _validEnStrings,
}) {
  return inspectIosStoreContract(
    projectSource: projectSource,
    infoPlistSource: infoPlistSource,
    privacyManifestSource: privacyManifestSource,
    appIconSource: appIconSource,
    deStringsSource: deStringsSource,
    enStringsSource: enStringsSource,
  );
}

void main() {
  test('accepts a complete local iOS and iPad static contract', () {
    final result = _inspect();

    expect(result.isValid, isTrue);
    expect(result.violations, isEmpty);
  });

  test('reports every missing native invariant', () {
    final result = _inspect(
      projectSource: _validProject
          .replaceAll('com.sujinarin.koLernenApp', 'example.invalid')
          .replaceAll('IPHONEOS_DEPLOYMENT_TARGET = 13.0;', '')
          .replaceAll('TARGETED_DEVICE_FAMILY = "1,2";', '')
          .replaceFirst('      de,\n', '')
          .replaceFirst(
            '      INFO_STRINGS_GROUP /* InfoPlist.strings */,\n',
            '',
          )
          .replaceFirst(
            '      INFO_STRINGS_BUILD /* InfoPlist.strings in Resources */,\n',
            '',
          )
          .replaceFirst(
            '      PRIVACY_MANIFEST /* PrivacyInfo.xcprivacy */,\n',
            '',
          )
          .replaceFirst(
            '      PRIVACY_MANIFEST_BUILD /* PrivacyInfo.xcprivacy in Resources */,\n',
            '',
          ),
      infoPlistSource: '<plist><dict/></plist>',
      privacyManifestSource: '',
      appIconSource: '{"images":[]}',
      deStringsSource: '',
      enStringsSource: '',
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      containsAll(<String>[
        'Runner bundle identifier is missing',
        'iOS 13.0 or later deployment target is missing',
        'iPad target family is missing',
        'iPad orientations are incomplete',
        'camera permission key is missing',
        'photo library permission key is missing',
        'German InfoPlist.strings content is incomplete',
        'English InfoPlist.strings content is incomplete',
        'InfoPlist.strings is not registered in the Runner group exactly once',
        'InfoPlist.strings is not registered in Runner Resources exactly once',
        'PrivacyInfo.xcprivacy content is incomplete',
        'PrivacyInfo.xcprivacy is not registered in the Runner group exactly once',
        'PrivacyInfo.xcprivacy is not registered in Runner Resources exactly once',
        'German is missing from Xcode knownRegions',
        '83.5x83.5 iPad icon is missing',
        '1024x1024 iOS marketing icon is missing',
      ]),
    );
  });

  test(
    'requires the complete InfoPlist.strings variant group and exact resource membership',
    () {
      final noEnglishVariant = _validProject.replaceFirst(
        '      EN_STRINGS /* en */,\n',
        '',
      );
      final duplicateResource = _validProject.replaceFirst(
        '      INFO_STRINGS_BUILD /* InfoPlist.strings in Resources */,\n',
        '      INFO_STRINGS_BUILD /* InfoPlist.strings in Resources */,\n'
            '      INFO_STRINGS_BUILD /* InfoPlist.strings in Resources */,\n',
      );

      expect(
        _inspect(projectSource: noEnglishVariant).violations,
        contains('InfoPlist.strings variant group is incomplete'),
      );
      expect(
        _inspect(projectSource: duplicateResource).violations,
        contains(
          'InfoPlist.strings is not registered in Runner Resources exactly once',
        ),
      );
    },
  );

  test('requires the privacy manifest source and exact resource membership', () {
    final duplicateResource = _validProject.replaceFirst(
      '      PRIVACY_MANIFEST_BUILD /* PrivacyInfo.xcprivacy in Resources */,\n',
      '      PRIVACY_MANIFEST_BUILD /* PrivacyInfo.xcprivacy in Resources */,\n'
          '      PRIVACY_MANIFEST_BUILD /* PrivacyInfo.xcprivacy in Resources */,\n',
    );

    expect(
      _inspect(privacyManifestSource: '').violations,
      contains('PrivacyInfo.xcprivacy content is incomplete'),
    );
    expect(
      _inspect(projectSource: duplicateResource).violations,
      contains(
        'PrivacyInfo.xcprivacy is not registered in Runner Resources exactly once',
      ),
    );
  });

  test('requires each localized permission statement', () {
    expect(
      _inspect(
        deStringsSource: _validDeStrings.replaceFirst(
          'NSPhotoLibraryUsageDescription',
          'OtherKey',
        ),
      ).violations,
      contains('German InfoPlist.strings content is incomplete'),
    );
    expect(
      _inspect(
        enStringsSource: _validEnStrings.replaceFirst(
          'recognize Korean words on your device.',
          'do something else.',
        ),
      ).violations,
      contains('English InfoPlist.strings content is incomplete'),
    );
  });

  test('reads malformed UTF-8 source as an empty static-contract input', () {
    final directory = Directory.systemTemp.createTempSync(
      'ios-store-contract-',
    );
    final file = File('${directory.path}${Platform.pathSeparator}invalid.txt');
    try {
      file.writeAsBytesSync(const <int>[0xff, 0xfe, 0xfd]);

      expect(readIosStoreSource(file.path), isEmpty);
    } finally {
      directory.deleteSync(recursive: true);
    }
  });
}
